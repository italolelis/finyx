---
phase: 16-bulk-migration
plan: "01"
subsystem: skills/invest
tags: [skill-migration, investment, broker, etf, rebalancing, dca]
dependency_graph:
  requires: [skills/invest/references/disclaimer.md, skills/invest/references/germany/brokers.md, skills/invest/references/brazil/brokers.md]
  provides: [skills/invest/SKILL.md]
  affects: []
tech_stack:
  added: []
  patterns: [disable-model-invocation, CLAUDE_SKILL_DIR paths, skill-phase-structure]
key_files:
  created: []
  modified:
    - skills/invest/SKILL.md
decisions:
  - Task tool removed from invest SKILL.md allowed-tools — broker advisory handled inline, no agent delegation needed
  - DCA vs lump sum guidance added to rebalancing phase (content enhancement over source command)
  - Broker comparison merged as phases 9-14 (not a separate section) to preserve single-skill cohesion
metrics:
  duration: "5m"
  completed_date: "2026-04-12"
  tasks_completed: 2
  files_modified: 1
---

# Phase 16 Plan 01: Invest + Broker Skill Conversion Summary

Investment + broker advisory merged into single 1065-line SKILL.md with portable paths, advisory disable flag, and full domain coverage.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Convert invest + broker commands to invest SKILL.md | f0359c2 | skills/invest/SKILL.md |
| 2 | Validate invest skill completeness | (no file changes) | — |

## What Was Built

`skills/invest/SKILL.md` replaces the 11-line stub with a complete 1065-line skill combining:

- **invest.md** (8 phases): validation, holdings collection, portfolio allocation, risk profiling, ETF recommendations, rebalancing + DCA guidance, market data query, disclaimer
- **broker.md** (7 phases): staleness check, profile broker display, German broker discovery, Brazilian broker discovery, profile-based recommendation, tax reporting quality, disclaimer

The merge strategy was: invest advisory flow (phases 1-8) runs first, broker comparison (phases 9-14) runs on request or as a continuation. Mode detection in Phase 1 routes broker-only invocations directly to Phase 9.

**Enhancements over source:**
- Added DCA vs lump sum guidance in Phase 6 (rebalancing) — was absent from source commands
- Mode detection logic at Phase 1 supports "broker only" invocations
- Cross-skill fallback notes added (tax for Abgeltungssteuer detail, insurance for PKV impact)

## Validation Results

- `disable-model-invocation: true`: PASS
- `@~/.claude/` occurrences: 0
- Line count: 1065 (> 400 minimum)
- `name: finyx-invest`: PASS
- ETF, broker, allocation, rebalancing terms: all PASS
- All `${CLAUDE_SKILL_DIR}/references/` paths resolve to existing files: PASS

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Content Enhancement (not a deviation)

DCA vs lump sum content added to Phase 6 (rebalancing). This is domain content that naturally belongs in the investment advisor and was absent from both source commands. Added per Rule 2 (missing critical functionality for a portfolio advisor).

## Known Stubs

None — all content is wired. `${CLAUDE_SKILL_DIR}/references/` paths all resolve to files verified to exist.

## Self-Check: PASSED

- `skills/invest/SKILL.md` exists: FOUND
- Commit f0359c2 exists: FOUND
- All reference paths resolve: FOUND
