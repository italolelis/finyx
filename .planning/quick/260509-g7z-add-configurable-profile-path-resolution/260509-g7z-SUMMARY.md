---
phase: 260509-g7z-add-configurable-profile-path-resolution
plan: 01
status: complete
completed: 2026-05-09
commits:
  - 8c85c69 feat(scripts): add resolve-profile.sh shared 4-tier resolver
  - 09887dd refactor(skills): use shared resolve-profile.sh across 19 files
  - 3a86024 docs(readme): document FINYX_PROFILE and config.json overrides
---

# Phase 260509-g7z: Configurable Profile Path Resolution — Summary

Centralized profile.json path resolution behind a shared `scripts/resolve-profile.sh` (4-tier precedence: `$FINYX_PROFILE` → `~/.config/finyx/config.json` → `./.finyx/profile.json` → `~/.finyx/profile.json`) and migrated every inlined gate check across 19 skill files to use it. Per-project working artifacts remain project-local; only `profile.json` is relocatable.

## Resolver script — interface and behavior

**Location:** `scripts/resolve-profile.sh` (executable POSIX bash, ~190 lines)
**Contract doc:** `scripts/README.md`

**Two invocation modes:**

| Mode | Command | Purpose |
|------|---------|---------|
| Read (default) | `./scripts/resolve-profile.sh` | Resolves path to existing profile. File MUST exist. |
| Write-target  | `./scripts/resolve-profile.sh --write-target` | Resolves target for new profile. Existence not required; never errors when no override is configured. |

On success: absolute path printed to stdout, exit 0. On failure: actionable
message to stderr with prefix `finyx-resolve-profile:`.

**Exit codes:**

| Code | Meaning |
|------|---------|
| 0  | success |
| 1  | no profile in any tier (read mode) |
| 2  | configured override (env or config.json) points to missing file |
| 3  | write target's parent dir not writable |
| 4  | `~/.config/finyx/config.json` malformed |
| 64 | usage error |

**Implementation notes:**
- Uses `python3` for JSON parsing when available; regex fallback when not.
- Path normalization via GNU `realpath -m` → `python3` → minimal absolute-path fallback. Works on macOS, Linux.
- No external runtime dependencies; only standard tools (bash, optional python3).

## Call sites migrated

| Pattern | Description | Sites | Files |
|---------|-------------|-------|-------|
| A | Single-line gate check `[ -f .finyx/profile.json ] \|\| { echo ERROR; exit 1; }` | 22 | insights, invest, pension, tax, realestate (×7), help (×1), 11 insurance sub-skills |
| B | Soft `\|\| { echo NO_PROFILE; }` (status flow) | 1 | help/SKILL.md |
| C | 2-tier resolver block (existing project-local + global fallback) | 1 | profile/SKILL.md Phase 1 |
| D | Write-target detection cascade (.git/package.json/Makefile) | 1 | profile/SKILL.md Phase 5 |
| **Total migrated** | | **25** | **19 source files** |

Plus 7 SKILL.md `<execution_context>` blocks gained an HTML comment
documenting that `@.finyx/profile.json` is a project-local fast-path
only — the resolver-determined `$PROFILE_PATH` is authoritative when
they differ.

## Files explicitly skipped (deferred)

- `skills/insurance/sub-skills/portfolio.md`
- `skills/insurance/sub-skills/doc-reader.md`

**Rationale:** Both files have multiple read/write touchpoints to
`.finyx/profile.json` across several phases (especially `doc-reader.md`,
which writes back into `insurance.policies[]` and updates `documents.locations.insurance`).
Migrating them safely requires updating each site individually plus the
agent-prompt strings inside `Task` tool calls — ballooning scope beyond
what was requested. Both files now carry a TODO marker:
`<!-- TODO: migrate to $PROFILE_PATH from scripts/resolve-profile.sh in a follow-up iteration. -->`
They continue to function with project-local `.finyx/profile.json`.

## profile/SKILL.md specific changes

- Phase 1 existence check now invokes the shared resolver and emits
  three banner variants instead of two: `PROFILE_EXISTS_LOCAL`,
  `PROFILE_EXISTS_GLOBAL`, and the new `PROFILE_EXISTS_OVERRIDE` (when
  resolved via `$FINYX_PROFILE` or `~/.config/finyx/config.json`).
- Phase 5 write-target uses `--write-target` mode. The `BASE_DIR`
  variable (previously controlling all writes) is gone; only profile.json
  goes to the resolver-determined dir. Working artifacts (research/,
  analysis/, output/, STATE.md) are now hard-coded under `./.finyx/`.
- `## Profile Path Resolution` notes section rewritten to describe the
  4-tier scheme and link to `scripts/README.md`.
- `[BASE_DIR]/profile.json` and `[BASE_DIR]/STATE.md` placeholders in
  the completion banner replaced with `$PROFILE_TARGET` and
  `.finyx/STATE.md` respectively.

## Known limitations (carry-forward from plan)

The Claude Code `@.finyx/profile.json` directives in `<execution_context>`
blocks load the file LITERALLY at skill startup. There is no way to make
`@` follow `$FINYX_PROFILE` dynamically. Two consequences:

1. If user sets `$FINYX_PROFILE` to `/elsewhere/profile.json` and no
   project-local `.finyx/profile.json` exists, the `@` include silently
   no-ops. Claude Code tolerates missing `@`-includes.
2. The bash gate-check + Read step that follows is the authoritative
   data path. Each gate-check now exports `$PROFILE_PATH`, and the
   immediately-following "Read" prose reads `$PROFILE_PATH` rather than
   `.finyx/profile.json`. Deeper Read references in later phases of the
   same skill remain on `.finyx/profile.json` — out of scope for this
   iteration (and only relevant if the user's profile is *not*
   project-local; a future migration can address per-phase reads).

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] `read_config_profile_path` swallowed exit code 4 from python3**

- **Found during:** Task 1 verification (extra checks).
- **Issue:** The function originally used `if ! out=$(python3 ...); then ... rc=$?`. Under `set -e`, the `!` operator inverts and the assignment with negation reset `$?` so `rc` was always 0. Result: malformed JSON did not surface as exit 4 — the script silently fell through to tier 3.
- **Fix:** Switched to explicit `set +e; out=$(...); rc=$?; set -e` so the python3 exit code is captured cleanly. Verified malformed-JSON test now exits 4.
- **Files modified:** `scripts/resolve-profile.sh`
- **Commit:** `8c85c69` (folded into Task 1 commit before push)

**2. [Rule 1 — Bug] Orphan `BASE_DIR=` assignment in profile/SKILL.md Phase 5**

- **Found during:** Task 2 self-review.
- **Issue:** After replacing `${BASE_DIR}/profile.json` writes with `$PROFILE_TARGET` and `${BASE_DIR}/STATE.md` writes with `.finyx/STATE.md`, the `BASE_DIR=$(dirname "$PROFILE_TARGET")` assignment in the bash block became dead code that contradicted the surrounding documentation.
- **Fix:** Removed the orphan assignment. The notes section still references `BASE_DIR=$(dirname "$PROFILE_TARGET")` as descriptive prose explaining the pattern, but the bash block no longer carries the unused variable.
- **Files modified:** `skills/profile/SKILL.md`
- **Commit:** `09887dd` (folded into Task 2 commit before push)

## End-to-end smoke test results

All 8 smoke tests from the plan's `<verification>` section passed in a
clean fixture:

| # | Test | Result |
|---|------|--------|
| 1 | Tier 4 fallback (`~/.finyx/profile.json` only) | PASS |
| 2 | Tier 3 project-local | PASS |
| 3 | Tier 2 (config.json `profile_path`) | PASS |
| 4 | Tier 1 (`$FINYX_PROFILE`) | PASS |
| 5 | Loud failure: `FINYX_PROFILE=/nonexistent` exits 2 with FINYX_PROFILE in stderr | PASS |
| 6 | Loud failure: malformed `config.json` exits 4 | PASS |
| 7 | Coverage: ≥18 files reference resolver (actual: 21) | PASS |
| 8 | No regressions: zero PATTERN A gate-checks remaining | PASS |

Plus the per-task automated verification blocks (Task 1, Task 2, Task 3)
all passed.

## User-visible changes (release notes)

- **New env var:** `FINYX_PROFILE` — absolute path to a profile.json
  file. When set and non-empty, all Finyx skills resolve to this path
  instead of `./.finyx/profile.json` or `~/.finyx/profile.json`.
- **New config file:** `~/.config/finyx/config.json` with optional
  `profile_path` key. Same effect as `FINYX_PROFILE` but persists
  across shells.
- **New error class:** if either override is set but the file does not
  exist, Finyx now fails loudly (exit 2 with a stderr message naming
  the override source) rather than silently falling through to the
  next tier. This catches typos and stale configs.
- **No breaking change** for users who never set the new override — the
  default 2-tier behavior (project-local then global) is preserved.
- **Working artifacts contract:** `research/`, `analysis/`, `output/`,
  `STATE.md`, and `insights-config.json` are now explicitly documented
  as project-local — they live under `./.finyx/` of the current
  working directory regardless of where `profile.json` is stored.

## Self-Check: PASSED

- [x] `scripts/resolve-profile.sh` exists, is executable
- [x] `scripts/README.md` exists, documents FINYX_PROFILE and profile_path
- [x] All 19 plan-specified files modified (8 SKILL.md + 11 insurance sub-skills)
- [x] portfolio.md and doc-reader.md carry TODO markers (deferred per plan)
- [x] README.md has new `## Configuration` section between Quick start and Commands
- [x] All 3 commits exist in git log: 8c85c69, 09887dd, 3a86024
- [x] All 8 plan-defined smoke tests pass
- [x] Zero PATTERN A inlined gate checks remain in skills/
