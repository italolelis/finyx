---
phase: 07-specialist-agents
plan: 03
subsystem: agents
tags: [finyx, projection, net-worth, goal-pace, claude-agent]

# Dependency graph
requires:
  - phase: 06-reference-foundation
    provides: benchmarks.md, scoring-rules.md, disclaimer.md — referenced in agent execution_context
provides:
  - agents/finyx-projection-agent.md — net worth snapshot and goal pace specialist agent prompt
affects: [08-orchestrator, fin-insights-command]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stateless agent with Read/Grep/Glob only tools (no Bash/Write/WebSearch)"
    - "Conservative/base range estimates — no single-point projections"
    - "EUR 1k rounding enforced at agent prompt level"
    - "DATA GAP notes for absent profile fields — no value fabrication"
    - "projection_result XML wrapper for orchestrator consumption"

key-files:
  created:
    - agents/finyx-projection-agent.md
  modified: []

key-decisions:
  - "Portfolio value: cost_basis x shares only — MEDIUM CONFIDENCE; no live price lookups"
  - "Liabilities: profile has none; monthlyCommitments used as obligations proxy with explicit note"
  - "BR portfolio kept in BRL, not auto-converted to EUR unless conversion rate is stated in profile"
  - "Savings rate denominator: net-after-mandatory using benchmarks.md Section 1 approximation"
  - "Return assumptions by risk tolerance: conservative=3%, moderate=5%, aggressive=7% real annual"
  - "Rentenpunkt value: EUR 39.32/month (2025 West Germany reference)"

patterns-established:
  - "Agent anti-patterns list embedded in agent prompt as explicit named section"
  - "Each Phase numbered with ## Phase N: heading for structured parsing"

requirements-completed: [PROJ-01, PROJ-02]

# Metrics
duration: 12min
completed: 2026-04-06
---

# Phase 07 Plan 03: Projection Agent Summary

**Projection specialist agent with net worth snapshot from cost-basis portfolio fields and conservative/base goal pace tracking in months, wrapped in `<projection_result>` XML tags**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-04-06T22:30:00Z
- **Completed:** 2026-04-06T22:42:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `agents/finyx-projection-agent.md` with YAML frontmatter (`name: finyx-projection-agent`, `tools: Read, Grep, Glob`, `color: blue`)
- Net worth snapshot (PROJ-01): sums liquidAssets + DE/BR broker holdings at cost basis, presents pension as monthly entitlement, notes absence of balance sheet liabilities
- Goal pace tracking (PROJ-02): computes conservative and base months-to-goal estimates per `goals.primary_goals[]`, with risk-tolerance-based return assumptions
- Pension pace section: projects Rentenpunkte at retirement using annual accrual from gross income ratio
- All EUR amounts rounded to EUR 1,000; explicit Assumptions section mandatory in every output

## Task Commits

1. **Task 1: Create projection agent prompt file** - `b8b18e4` (feat)

## Files Created/Modified

- `agents/finyx-projection-agent.md` — Full specialist agent prompt: role, execution_context, 5-phase process, output_format, anti-patterns

## Decisions Made

- Portfolio at cost basis only (no live NAV lookup permitted); labeled MEDIUM CONFIDENCE
- monthlyCommitments is not a balance sheet liability — explicit note required in every output
- BR portfolio kept in BRL with no auto-conversion unless user-provided rate exists in profile
- Return assumptions: 3%/5%/7% real annual for conservative/moderate/aggressive risk tolerance
- Average German gross salary reference (EUR 45,358/year, 2025) embedded for pension accrual calculation

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All three specialist agent prompt files are complete (plans 01, 02, 03 of phase 07)
- Phase 08 orchestrator can spawn `finyx-projection-agent` via Task tool using `color: blue`
- Orchestrator reads `<projection_result>` XML tags from agent return value
- No blockers

---
*Phase: 07-specialist-agents*
*Completed: 2026-04-06*
