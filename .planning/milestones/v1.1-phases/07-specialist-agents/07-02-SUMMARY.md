---
phase: 07-specialist-agents
plan: 02
subsystem: agents
tags: [finyx, tax-scoring, germany, brazil, specialist-agent, sparerpauschbetrag, vorabpauschale, pgbl, traffic-light]

# Dependency graph
requires:
  - phase: 06-reference-foundation
    provides: scoring-rules.md with TAX-01/TAX-03/TAX-04 thresholds and germany/brazil tax-investment.md reference docs
provides:
  - agents/finyx-tax-scoring-agent.md — tax efficiency scoring specialist agent for /fin:insights orchestrator
affects:
  - 08-insights-command — orchestrator spawns this agent via Task tool and consumes <tax_score_result> XML output

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Agent prompt structure: YAML frontmatter (name, description, tools, color) + XML body sections (role, execution_context, process, output_format)"
    - "Per-country tax scoring: Germany and Brazil scored independently, never combined"
    - "Graceful missing-field handling: absent freistellungsauftrag outputs MEDIUM CONFIDENCE fallback"
    - "Conservative fund value floor: cost_basis x shares with MEDIUM CONFIDENCE flag — no WebSearch for NAV"
    - "PGBL gate pattern: ir_regime check before scoring; simplificada skips TAX-04 entirely"

key-files:
  created:
    - agents/finyx-tax-scoring-agent.md
  modified: []

key-decisions:
  - "Agent uses tools: Read, Grep, Glob only — no Write, Bash, or WebSearch, matching D-05"
  - "Output wrapped in <tax_score_result> XML tags per D-01 for orchestrator consumption"
  - "Germany and Brazil scored in completely separate sections — never aggregated (per project decision)"
  - "freistellungsauftrag absence handled gracefully with MEDIUM CONFIDENCE (not an error)"
  - "Fund NAV estimated as cost_basis x shares as conservative floor; MEDIUM CONFIDENCE flagged"

patterns-established:
  - "Tax agent pattern: phase-per-dimension structure (Phase 1 data read, Phase 2 TAX-01, Phase 3 TAX-03, Phase 4 TAX-04, Phase 5 summary, Phase 6 format)"
  - "Anti-pattern block: explicit list of forbidden behaviors embedded in process section"
  - "Confidence flagging: HIGH/MEDIUM/LOW CONFIDENCE appended per dimension based on data completeness"

requirements-completed: [TAX-01, TAX-02, TAX-03]

# Metrics
duration: 15min
completed: 2026-04-06
---

# Phase 07 Plan 02: Tax-Scoring Specialist Agent Summary

**Magenta-colored tax efficiency agent scoring Sparerpauschbetrag (TAX-01), Vorabpauschale readiness (TAX-03), and PGBL optimization (TAX-04) per country with EUR/BRL gap amounts, wrapped in `<tax_score_result>` XML tags**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-06T22:27:27Z
- **Completed:** 2026-04-06T22:42:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `agents/finyx-tax-scoring-agent.md` with YAML frontmatter (name, tools, color) and full XML body
- TAX-01 Sparerpauschbetrag scoring with EUR 1,000/2,000 limits, freistellungsauftrag summation across brokers, graceful handling of missing field with MEDIUM CONFIDENCE fallback
- TAX-03 Vorabpauschale readiness check using fund value floor (cost_basis x shares), Teilfreistellung by asset class (equity-etf 30%, bond-etf 0%, reit-etf 60%), cash buffer check
- TAX-04 PGBL scoring gated on `ir_regime == "completo"` — simplificada users receive N/A output with explanation
- TAX-02 per-country summaries explicitly separated; explicit "NEVER combine DE + BR" rule embedded in both process and anti-pattern block
- traffic-light output format (GREEN/YELLOW/RED) with Gap and How-to-close lines per scoring-rules.md template

## Task Commits

1. **Task 1: Create tax-scoring agent prompt file** - `3d4c191` (feat)

**Plan metadata:** (docs commit pending)

## Files Created/Modified

- `agents/finyx-tax-scoring-agent.md` — Tax efficiency scoring specialist agent; reads profile.json and tax reference docs; produces traffic-light scores per country; output in `<tax_score_result>` tags

## Decisions Made

- Embedded anti-pattern block with explicit forbidden behaviors (no Bash/Write/WebSearch, no cross-country aggregation, no hardcoded rates) — reduces agent hallucination risk
- Used `execution_context` `@path` includes for all four reference docs (scoring-rules.md, germany/tax-investment.md, brazil/tax-investment.md, disclaimer.md)
- Church tax handling: uses 27.995% as conservative estimate when church tax state is unknown

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `agents/finyx-tax-scoring-agent.md` exists and is ready to be spawned by the Phase 8 `/fin:insights` orchestrator via `Task` tool
- Phase 8 orchestrator must pass the profile path and consume `<tax_score_result>` XML tags
- No blockers

---
*Phase: 07-specialist-agents*
*Completed: 2026-04-06*
