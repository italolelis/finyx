#!/usr/bin/env bash
# resolve-profile.sh — shared 4-tier resolver for Finyx profile.json path.
#
# Two invocation modes:
#   ./resolve-profile.sh                  read mode (default)  — resolves to an existing file
#   ./resolve-profile.sh --write-target   write-target mode    — resolves to a target path (file need not exist)
#
# Precedence (first match wins):
#   1. $FINYX_PROFILE env var
#   2. ~/.config/finyx/config.json  key  "profile_path"
#   3. ./.finyx/profile.json (project-local)
#   4. ~/.finyx/profile.json (global fallback)
#
# Exit codes:
#   0 = success
#   1 = no profile found across all tiers (read mode only)
#   2 = configured override (env var or config.json) points to missing file (read mode)
#   3 = write target's parent dir is not writable (write-target mode)
#   4 = config.json exists but is malformed JSON
#  64 = usage error
#
# All errors emit to stderr with prefix `finyx-resolve-profile:`.
set -euo pipefail

PROG="finyx-resolve-profile"
CONFIG_FILE="${HOME}/.config/finyx/config.json"

print_usage() {
  cat <<'EOF'
Usage: resolve-profile.sh [--write-target] [-h|--help]

Resolves the path to the Finyx profile.json using a 4-tier precedence chain:
  1. $FINYX_PROFILE env var
  2. ~/.config/finyx/config.json  key "profile_path"
  3. ./.finyx/profile.json
  4. ~/.finyx/profile.json

Modes:
  (default)        read mode — chosen tier's file MUST exist
  --write-target   write-target mode — chosen tier's parent dir must be writable;
                   file existence is not required

Exit codes:
  0  success                          (path printed to stdout)
  1  no profile found in any tier     (read mode)
  2  configured override missing      (read mode)
  3  parent dir not writable          (write-target mode)
  4  config.json malformed
  64 usage error

See scripts/README.md for details.
EOF
}

err() {
  printf '%s\n' "${PROG}: $*" >&2
}

# Resolve a possibly-relative path to an absolute path. Does NOT require existence.
abs_path() {
  local p="$1"
  # Expand leading ~ to $HOME
  case "$p" in
    "~"|"~/"*) p="${HOME}${p#\~}" ;;
  esac
  if command -v realpath >/dev/null 2>&1; then
    # GNU realpath supports -m (no-existence-required). BSD realpath does not.
    if realpath -m / >/dev/null 2>&1; then
      realpath -m -- "$p"
      return 0
    fi
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os,sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))' "$p"
    return 0
  fi
  case "$p" in
    /*) printf '%s\n' "$p" ;;
    *)  printf '%s\n' "$(pwd)/$p" ;;
  esac
}

# Read top-level string key "profile_path" from a JSON file.
# Returns the value (or empty string) on stdout. Exits 4 on malformed JSON.
read_config_profile_path() {
  local cfg="$1"
  if command -v python3 >/dev/null 2>&1; then
    local out rc
    set +e
    out=$(python3 - "$cfg" <<'PY' 2>/dev/null
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
except json.JSONDecodeError:
    sys.exit(4)
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(4)
v = data.get("profile_path", "")
if v is None:
    v = ""
print(v if isinstance(v, str) else "")
PY
)
    rc=$?
    set -e
    if [ "$rc" -eq 4 ]; then
      err "ERROR: ${CONFIG_FILE} is not valid JSON. Fix or remove the file."
      exit 4
    fi
    if [ "$rc" -ne 0 ]; then
      # Other failure modes treated as "no key set"
      printf ''
      return 0
    fi
    printf '%s' "$out"
    return 0
  fi
  # Fallback: regex extraction. Limited to simple "profile_path": "value" forms.
  # Validate JSON well-formedness in the most basic way: must contain at least one { and one }.
  if ! grep -q '{' "$cfg" || ! grep -q '}' "$cfg"; then
    err "ERROR: ${CONFIG_FILE} is not valid JSON. Fix or remove the file."
    exit 4
  fi
  # Extract value of "profile_path" key (top-level string).
  local val
  val=$(sed -n 's/.*"profile_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -n1)
  printf '%s' "${val:-}"
}

# Check if a parent directory is writable; create it if needed (write-target mode helper).
parent_dir_writable() {
  local target="$1"
  local parent
  parent=$(dirname -- "$target")
  if [ -d "$parent" ] && [ -w "$parent" ]; then
    return 0
  fi
  if [ ! -d "$parent" ]; then
    # Try to create it
    if mkdir -p -- "$parent" 2>/dev/null && [ -w "$parent" ]; then
      return 0
    fi
  fi
  return 1
}

# Detect whether CWD is "in a project" — used by write-target mode tier 3.
in_project_dir() {
  [ -d .finyx ] || [ -d .git ] || [ -f .git ] || [ -f package.json ] || [ -f Makefile ]
}

# Argument parsing
MODE="read"
case "${1:-}" in
  "") ;;
  --write-target) MODE="write" ;;
  -h|--help) print_usage; exit 0 ;;
  *) err "ERROR: unknown argument '$1'"; print_usage >&2; exit 64 ;;
esac

if [ "$#" -gt 1 ]; then
  err "ERROR: too many arguments"
  print_usage >&2
  exit 64
fi

# ── Tier 1: $FINYX_PROFILE env var ────────────────────────────────────────────
if [ -n "${FINYX_PROFILE-}" ]; then
  T1_PATH=$(abs_path "$FINYX_PROFILE")
  if [ "$MODE" = "read" ]; then
    if [ ! -f "$T1_PATH" ]; then
      err "ERROR: FINYX_PROFILE points to '${FINYX_PROFILE}' but file does not exist."
      err "       Either create the file, unset FINYX_PROFILE, or fix the path."
      exit 2
    fi
    printf '%s\n' "$T1_PATH"
    exit 0
  else
    if ! parent_dir_writable "$T1_PATH"; then
      err "ERROR: FINYX_PROFILE='${FINYX_PROFILE}' parent dir is not writable."
      exit 3
    fi
    printf '%s\n' "$T1_PATH"
    exit 0
  fi
fi

# ── Tier 2: ~/.config/finyx/config.json with key "profile_path" ───────────────
T2_VALUE=""
if [ -f "$CONFIG_FILE" ]; then
  T2_VALUE=$(read_config_profile_path "$CONFIG_FILE")
fi
if [ -n "$T2_VALUE" ]; then
  T2_PATH=$(abs_path "$T2_VALUE")
  if [ "$MODE" = "read" ]; then
    if [ ! -f "$T2_PATH" ]; then
      err "ERROR: ${CONFIG_FILE} 'profile_path' points to '${T2_VALUE}' but file does not exist."
      err "       Fix ${CONFIG_FILE} or remove the profile_path key."
      exit 2
    fi
    printf '%s\n' "$T2_PATH"
    exit 0
  else
    if ! parent_dir_writable "$T2_PATH"; then
      err "ERROR: ${CONFIG_FILE} 'profile_path'='${T2_VALUE}' parent dir is not writable."
      exit 3
    fi
    printf '%s\n' "$T2_PATH"
    exit 0
  fi
fi

# ── Tier 3: ./.finyx/profile.json (project-local) ─────────────────────────────
T3_PATH="$(pwd)/.finyx/profile.json"
if [ "$MODE" = "read" ]; then
  if [ -f "$T3_PATH" ]; then
    printf '%s\n' "$T3_PATH"
    exit 0
  fi
else
  # Write-target tier 3: choose project-local when we are clearly inside a project.
  if in_project_dir; then
    printf '%s\n' "$T3_PATH"
    exit 0
  fi
fi

# ── Tier 4: ~/.finyx/profile.json (global fallback) ───────────────────────────
T4_PATH="${HOME}/.finyx/profile.json"
if [ "$MODE" = "read" ]; then
  if [ -f "$T4_PATH" ]; then
    printf '%s\n' "$T4_PATH"
    exit 0
  fi
  # All tiers exhausted — emit 4-tier diagnostic.
  err "ERROR: No financial profile found."
  err "  Checked (in precedence order):"
  err "    1. \$FINYX_PROFILE env var          [not set]"
  if [ -f "$CONFIG_FILE" ]; then
    err "    2. ${CONFIG_FILE}     [present, no profile_path key]"
  else
    err "    2. ${CONFIG_FILE}     [not present]"
  fi
  if [ -e .finyx ]; then
    err "    3. ./.finyx/profile.json           [.finyx/ exists, no profile.json]"
  else
    err "    3. ./.finyx/profile.json           [not present]"
  fi
  err "    4. ${T4_PATH}     [not present]"
  err "  Run /finyx:profile to create a profile."
  exit 1
else
  # Write-target final fallback — always picks ~/.finyx/profile.json.
  if ! parent_dir_writable "$T4_PATH"; then
    err "ERROR: cannot create parent dir for '${T4_PATH}'."
    exit 3
  fi
  printf '%s\n' "$T4_PATH"
  exit 0
fi
