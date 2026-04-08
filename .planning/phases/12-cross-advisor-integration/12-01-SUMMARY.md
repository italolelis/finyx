---
phase: 12-cross-advisor-integration
plan: 01
subsystem: commands
tags: [insurance, PKV, GKV, tax-deduction, cross-advisor, profile-schema, finyx]

# Dependency graph
requires:
  - phase: 11-command-integration
    provides: /finyx:insurance command and agents
  - phase: 09-reference-foundation
    provides: health-insurance.md reference doc with §10 EStG deduction caps
provides:
  - Insurance section in finyx/templates/config.json profile schema
  - Insurance cost pickup in /finyx:insights allocation analysis (CAL-05 pattern)
  - PKV Basisabsicherung §10 EStG deduction section in /finyx:tax (Section 3.6)
affects: [finyx-allocation-agent, finyx-tax-scoring-agent, cross-advisor-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Conditional subsection pattern: execute only if profile field matches (insurance.type == PKV)"
    - "Silent skip pattern: optional profile sections skipped without error when absent/null"
    - "Cross-advisor pattern registry: CAL-01 through CAL-05 in insights command"

key-files:
  created: []
  modified:
    - finyx/templates/config.json
    - commands/finyx/insights.md
    - commands/finyx/tax.md

key-decisions:
  - "Insurance fields default to null in template — all four fields (type, monthly_cost, employer_share, provider) are optional"
  - "Silent skip semantics: both insights and tax commands skip insurance sections without warning when absent"
  - "CAL-05 trigger threshold: net PKV cost >€400/month AND savings rate <20% — conservative threshold to avoid false positives"

patterns-established:
  - "Optional profile section: document as optional in Phase 1, skip silently, never block report generation"
  - "Conditional tax subsection: numbered continuation (3.6) with explicit conditional guard at top"

requirements-completed: [EDGE-03]

# Metrics
duration: 5min
completed: 2026-04-08
---

# Phase 12 Plan 01: Cross-Advisor Insurance Integration Summary

**Insurance costs wired into /finyx:insights allocation and /finyx:tax PKV Basisabsicherung §10 EStG deduction via profile schema extension with four null-default fields**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-08T22:36:53Z
- **Completed:** 2026-04-08T22:42:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Profile template extended with insurance section (type, monthly_cost, employer_share, provider) placed between investor and strategy blocks
- /finyx:insights allocation agent now includes net insurance cost as "needs" line item when insurance section is populated, with CAL-05 cross-advisor pattern for PKV premium drag on savings rate
- /finyx:tax has new Section 3.6 showing PKV Basisabsicherung deduction calculation (§10 EStG) with employee/self-employed cap detection, conditional on insurance.type == PKV

## Task Commits

Each task was committed atomically:

1. **Task 1: Add insurance section to profile template** - `ed44dfa` (feat)
2. **Task 2: Add insurance cost pickup to /finyx:insights** - `a235c86` (feat)
3. **Task 3: Add PKV Basisabsicherung deduction to /finyx:tax** - `3471ad3` (feat)

## Files Created/Modified
- `finyx/templates/config.json` - Added insurance section with 4 null-default fields after investor block
- `commands/finyx/insights.md` - Optional fields gate, allocation agent insurance prompt, CAL-05 pattern
- `commands/finyx/tax.md` - health-insurance.md in execution_context, Section 3.6 PKV deduction

## Decisions Made
- Insurance fields all default to null — consistent with existing profile template convention
- Silent skip semantics applied in both commands — insurance absence never blocks report generation
- CAL-05 uses €400/month net cost threshold (not gross) to avoid flagging users with significant employer share

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- EDGE-03 fully satisfied: insurance data flows into both cross-advisor commands
- /finyx:insurance command (v1.2 main feature) can now reference profile.json insurance section when saving user data
- Profile template ready for users to populate after running /finyx:insurance

---
*Phase: 12-cross-advisor-integration*
*Completed: 2026-04-08*
