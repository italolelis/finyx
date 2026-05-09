# scripts/

Shared helper scripts used by Finyx skills.

## resolve-profile.sh

Resolves the path to the user's `profile.json` using a 4-tier precedence chain.

### Purpose

Before this script existed, every skill inlined its own existence check
(`[ -f .finyx/profile.json ] || ...`) hard-coding the project-local path.
Users who wanted their financial profile to live outside the current
working directory had no choice but to symlink. This resolver centralizes
the path-resolution logic and adds two override mechanisms — an
environment variable and a user-level config file — while keeping
per-project working artifacts (research, analysis, output, STATE.md)
project-local.

### Invocation modes

| Mode | Command | Purpose |
|------|---------|---------|
| Read (default) | `./scripts/resolve-profile.sh` | Resolves path to an EXISTING profile. File MUST exist. |
| Write-target  | `./scripts/resolve-profile.sh --write-target` | Resolves a target path for a NEW profile. File need not exist. |
| Help          | `./scripts/resolve-profile.sh --help` | Prints usage and exits. |

On success, the resolver prints the absolute path to **stdout** and exits 0.
On failure, an actionable message is emitted to **stderr** with prefix
`finyx-resolve-profile:` and the script exits with a documented non-zero code.

### Precedence (first match wins)

| # | Source | Notes |
|---|--------|-------|
| 1 | `$FINYX_PROFILE` env var | Highest priority. Read mode: file MUST exist. |
| 2 | `~/.config/finyx/config.json` `profile_path` key | User-level default. Read mode: file MUST exist. |
| 3 | `./.finyx/profile.json` | Project-local profile in current working directory. |
| 4 | `~/.finyx/profile.json` | Global fallback. |

If tier 1 or tier 2 is **set but the target file does not exist**, the
resolver fails loudly (exit 2) rather than silently falling through to
tier 3 or 4. This prevents the common bug where a user thinks they have
configured an override but has actually mistyped the path.

In `--write-target` mode tier 3 is taken when the CWD looks like a project
(any of `.finyx/`, `.git`, `package.json`, `Makefile` is present).
Otherwise tier 4 (`~/.finyx/profile.json`) is selected as final fallback —
write-target mode never errors with exit 1.

### Exit codes

| Code | Meaning |
|------|---------|
| 0  | success — resolved path printed to stdout |
| 1  | no profile found in any tier (read mode only) |
| 2  | configured override (env or config.json) points to missing file (read mode) |
| 3  | write target's parent dir is not writable (write-target mode) |
| 4  | `~/.config/finyx/config.json` exists but is malformed JSON |
| 64 | usage error |

### Example: `~/.config/finyx/config.json`

```json
{ "profile_path": "/Users/me/Documents/finances/profile.json" }
```

The `profile_path` value may be an absolute path, a `~`-rooted path, or a
plain absolute path. Relative paths are resolved against the current
working directory at invocation time, which is generally **not** what you
want — prefer absolute paths.

### Per-project working artifacts stay project-local

Only `profile.json` is relocatable. Per-project working artifacts (the
files Finyx writes during a research or analysis run) continue to live
under `./.finyx/` of the current working directory regardless of where
`profile.json` is stored:

| Path | Purpose |
|------|---------|
| `./.finyx/insights-config.json` | Allocation mapping persisted by `/finyx:insights` |
| `./.finyx/research/`            | Location and market research output |
| `./.finyx/analysis/`            | Per-location analysis (UNITS, RANKED, SHORTLIST) |
| `./.finyx/output/`              | Generated briefings |
| `./.finyx/STATE.md`             | Per-project workflow state |

This separation lets you keep one financial profile across multiple
investment projects (each with its own `.finyx/` working directory)
without needing to copy or symlink the profile.

### How skills consume this

Canonical invocation used by every skill's gate check:

```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

Soft variant for `/finyx:status` (Pattern B in the migration plan) — when
the absence of a profile is informational rather than fatal:

```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh" 2>/dev/null) || { echo "NO_PROFILE"; }
```

Write-target invocation used by `/finyx:profile` Phase 5 when creating a
new profile:

```bash
PROFILE_TARGET=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh" --write-target) || exit $?
BASE_DIR="$(dirname "$PROFILE_TARGET")"
```

### Implementation notes

- POSIX bash, `set -euo pipefail`, no external runtime dependencies.
- Uses `python3` for JSON parsing when available; falls back to a
  regex-based extractor that handles only the top-level `profile_path`
  string key. Never attempts to fully parse JSON in shell.
- Uses `realpath -m` (GNU) when available, then `python3` for path
  normalization, then a minimal absolute-path fallback. Works on macOS,
  Linux, and any POSIX shell environment.
- All variable expansions are quoted; `[ -n "${VAR-}" ]` is used to be
  safe under `set -u`.
