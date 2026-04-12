---
phase: 17-integration-distribution
plan: "01"
subsystem: cleanup
tags: [cleanup, migration, legacy-removal, skills]
dependency_graph:
  requires: []
  provides: [CLEAN-01, CLEAN-02]
  affects: [skills/realestate, skills/insights, skills/tax]
tech_stack:
  added: []
  patterns: []
key_files:
  created:
    - skills/realestate/references/briefing.md
  modified:
    - skills/realestate/agents/finyx-reporter-agent.md
    - skills/insights/references/insights/scoring-rules.md
    - skills/tax/references/brazil/tax-investment.md
  deleted:
    - commands/finyx/ (16 files)
    - agents/ (8 files)
    - finyx/ (22 files)
decisions:
  - "finyx/templates/location-research.md dropped — not referenced by any skill, dead content"
  - "scoring-rules.md source attributions updated to CLAUDE_SKILL_DIR paths (informational comments, not functional)"
  - "skills/help/SKILL.md ~/.claude/finyx/package.json reference left — runtime install path, not source dir"
metrics:
  duration: "8m"
  completed: "2026-04-12T16:27:53Z"
  tasks: 2
  files_changed: 50
requirements_satisfied: [CLEAN-01, CLEAN-02]
---

# Phase 17 Plan 01: Legacy Directory Cleanup Summary

**One-liner:** Deleted commands/finyx/, agents/, and finyx/ directories (46 files, 12,910 lines) after migrating missing briefing.md template to skills/realestate/references/.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Migrate briefing.md + verify all 14 reference files | 5802915 | skills/realestate/references/briefing.md |
| 2 | Remove legacy dirs + fix dangling path refs | b435705 | 48 files deleted, 3 skills updated |

## What Was Done

### Task 1: Migration verification and gap closure

All 14 `finyx/references/*` files were verified present in their target skills via content comparison:

- `disclaimer.md` — all 7 skills (insights, insurance, invest, pension, profile, realestate, tax)
- `methodology.md` → skills/realestate/references/
- `erbpacht-detection.md` → skills/realestate/references/
- `transport-assessment.md` → skills/realestate/references/
- `germany/tax-rules.md` → skills/tax, skills/realestate, skills/profile
- `germany/tax-investment.md` → skills/tax/references/germany/
- `germany/brokers.md` → skills/invest/references/germany/
- `germany/pension.md` → skills/pension/references/germany/
- `germany/health-insurance.md` → skills/insurance/references/germany/
- `brazil/tax-investment.md` → skills/tax/references/brazil/
- `brazil/brokers.md` → skills/invest/references/brazil/
- `brazil/pension.md` → skills/pension/references/brazil/
- `insights/benchmarks.md` → skills/insights/references/insights/
- `insights/scoring-rules.md` → skills/insights/references/insights/

Template migrations verified:
- `finyx/templates/profile.json` → skills/profile/references/profile.json (matched)
- `finyx/templates/state.md` → skills/profile/references/state.md (matched)
- `finyx/templates/briefing.md` → skills/realestate/references/briefing.md (GAP — copied, 594 lines)
- `finyx/templates/config.json` — legacy immo config, not needed by any skill, dropped
- `finyx/templates/location-research.md` — not referenced by any skill, dropped

### Task 2: Legacy directory removal

- `commands/finyx/` — 16 command .md files removed
- `agents/` — 8 agent .md files removed
- `finyx/` — 19 reference files + 5 templates removed

**Dangling references fixed (Rule 1 — Bug):**

1. `skills/realestate/agents/finyx-reporter-agent.md:17` — `~/.claude/finyx/templates/briefing.md` → `${CLAUDE_SKILL_DIR}/references/briefing.md`
2. `skills/tax/references/brazil/tax-investment.md:180` — `finyx/references/germany/tax-investment.md` → `skills/tax/references/germany/tax-investment.md`
3. `skills/insights/references/insights/scoring-rules.md` (4 occurrences) — `finyx/references/insights/benchmarks.md` → `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md`

**Not fixed (intentional):**
- `skills/help/SKILL.md:720` — `~/.claude/finyx/package.json` is a runtime install path, not a source repo reference. Correct.
- `skills/insights/SKILL.md:392-393` — `${CLAUDE_SKILL_DIR}/agents/finyx-*` uses skill-relative variable, files exist at `skills/insights/agents/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed dangling path references in 3 skill files**
- **Found during:** Task 2 verification grep
- **Issue:** finyx-reporter-agent.md referenced `~/.claude/finyx/templates/briefing.md` (deleted path); scoring-rules.md and tax-investment.md referenced `finyx/references/` paths
- **Fix:** Updated all 3 files to use skill-relative `${CLAUDE_SKILL_DIR}/` or repo-accurate paths
- **Files modified:** skills/realestate/agents/finyx-reporter-agent.md, skills/insights/references/insights/scoring-rules.md, skills/tax/references/brazil/tax-investment.md
- **Commit:** b435705 (included with Task 2)

## Known Stubs

None.

## Self-Check: PASSED
