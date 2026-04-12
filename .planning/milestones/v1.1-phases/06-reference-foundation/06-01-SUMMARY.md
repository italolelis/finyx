---
phase: 06-reference-foundation
plan: 01
subsystem: infra
tags: [markdown, reference-docs, benchmarks, scoring, tax-efficiency, cross-border, germany, brazil]

# Dependency graph
requires:
  - phase: 05-profile-schema-sync
    provides: Finyx profile schema with country-specific fields (countries.germany, countries.brazil, fgts_contribution, declaracao)
provides:
  - "finyx/references/insights/benchmarks.md — net-after-mandatory income denominators for DE and BR, adjusted 50/30/20 ranges, 6-month emergency fund threshold, 35% debt-to-income threshold"
  - "finyx/references/insights/scoring-rules.md — traffic-light thresholds for 8 dimensions (4 DE, 4 BR), gap formulas, scoring output format for Phase 7 agent consumption"
affects:
  - "07-insights-command — specialist agents @-reference both docs in execution_context"
  - "All future phases adding country-aware allocation analysis"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "insights/ subdir under finyx/references/ for cross-country functional reference docs"
    - "net-after-mandatory denominator pattern for all allocation benchmarks"
    - "traffic-light + absolute gap display per dimension per country (D-05)"
    - "Source: reference pattern linking scoring thresholds back to tax rule docs without duplication"

key-files:
  created:
    - finyx/references/insights/benchmarks.md
    - finyx/references/insights/scoring-rules.md
  modified: []

key-decisions:
  - "FGTS counts toward BR investment rate minimum (mandatory employer 8%); INSS does not (social insurance)"
  - "Vorabpauschale fallback: use prior-year Basiszins with MEDIUM confidence flag when current-year not yet published"
  - "TAX-04 (PGBL) only scored for users with declaracao: completa; skip for declaracao: simplificada"
  - "insights/ subdir chosen over flat placement to separate functional reference docs from country-specific tax docs"

patterns-established:
  - "Pattern: Reference docs ONLY state thresholds and gap formulas — never restate underlying tax rule values; link via 'Source: germany/tax-investment.md Section N'"
  - "Pattern: DE and BR always in separate top-level sections (## Germany / ## Brazil) — never combined in shared tables"
  - "Pattern: All allocation benchmarks denominated in net-after-mandatory income, never gross"

requirements-completed: [INFRA-02]

# Metrics
duration: 8min
completed: 2026-04-06
---

# Phase 6 Plan 01: Reference Foundation Summary

**Country-aware allocation benchmarks (DE/BR net-after-mandatory) and traffic-light scoring rules for 8 dimensions with gap formulas and Phase 7 agent output format**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-06T21:44:57Z
- **Completed:** 2026-04-06T21:45:42Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- Created `finyx/references/insights/benchmarks.md` with DE/BR net-income denominators, adjusted 50/30/20 allocation ranges, 6-month emergency fund threshold, and 35% debt-to-income threshold — all denominated in net-after-mandatory income
- Created `finyx/references/insights/scoring-rules.md` with green/yellow/red thresholds for all 8 dimensions (TAX-01 Sparerpauschbetrag, TAX-03 Vorabpauschale, ALLOC-01/02 for DE; TAX-02 DARF, TAX-04 PGBL, ALLOC-01/02 for BR), gap formulas, and scoring output format template
- Both docs carry `tax_year: 2025` frontmatter for staleness detection; DE and BR content kept in separate top-level sections throughout

## Task Commits

1. **Task 1: Create benchmarks.md with income allocation benchmarks** - `84d9a85` (feat)
2. **Task 2: Create scoring-rules.md with traffic-light thresholds** - `64863fc` (feat)

## Files Created/Modified

- `finyx/references/insights/benchmarks.md` — Net-after-mandatory income denominators for DE (~55-58% of gross) and BR (~70-75% of gross), INSS 2025 progressive table, adjusted 50/30/20 rule with investment sub-targets, 6-month emergency fund, 35% debt-to-income ratio
- `finyx/references/insights/scoring-rules.md` — Traffic-light thresholds per dimension per country, gap formulas, Vorabpauschale fallback for missing Basiszins, PGBL applicability gating, scoring output format with confidence flags

## Decisions Made

- FGTS counts toward BR investment rate minimum (employer mandatory 8%); INSS excluded (social insurance, not savings)
- Vorabpauschale scoring uses prior-year Basiszins as fallback with MEDIUM confidence flag when BMF hasn't published current year yet (early January edge case)
- PGBL dimension (TAX-04) only applies to users with `declaracao: completa`; simplificada users skip it without penalty
- Dimension label changed from TAX-02 (PGBL) to TAX-04 to avoid collision with TAX-02 DARF; plan had duplicate TAX-02 label — corrected inline

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Duplicate TAX-02 dimension label in plan**
- **Found during:** Task 2
- **Issue:** Plan listed both DARF and PGBL as "TAX-02" — duplicate ID within Brazil dimensions
- **Fix:** DARF retained as TAX-02 (matches BRTAX-02 in brazil/tax-investment.md); PGBL relabeled TAX-04 (no existing TAX-04 defined)
- **Files modified:** finyx/references/insights/scoring-rules.md
- **Committed in:** 64863fc (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — duplicate dimension label)
**Impact on plan:** Necessary for correctness — duplicate IDs would cause ambiguity in Phase 7 agent output. No scope creep.

## Issues Encountered

None — pure Markdown authoring phase with no runtime dependencies or external services.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both reference docs ready for Phase 7 specialist agents to `@`-reference via `@~/.claude/finyx/references/insights/benchmarks.md` and `@~/.claude/finyx/references/insights/scoring-rules.md`
- No install.js changes needed — `copyWithPathReplacement` recursively copies `finyx/` including new `insights/` subdir
- Phase 7 can build the `/fin:insights` command and its specialist agents immediately

---
*Phase: 06-reference-foundation*
*Completed: 2026-04-06*
