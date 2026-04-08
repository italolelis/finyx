---
phase: 09-reference-foundation
plan: 01
subsystem: infra
tags: [health-insurance, gkv, pkv, germany, reference-docs, staleness-detection]

# Dependency graph
requires: []
provides:
  - "finyx/references/germany/health-insurance.md — authoritative GKV/PKV reference with 2026 statutory constants"
  - "Staleness detection metadata (tax_year: 2025, valid_until) for Phase 10/11 commands"
  - "fallback_rate and source_url fields for Phase 10 research agent"
  - "3-tier PKV risk model with 15 binary health flags"
affects:
  - phase-10-specialist-agents
  - phase-11-orchestrator-command

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Reference doc convention: YAML frontmatter (tax_year/country/domain/last_updated/source) + staleness notice blockquote + numbered sections + inline formula blocks"
    - "fallback_rate + source_url pattern for live-fetchable data with offline fallback"
    - "Binary flag model for GDPR Art. 9 health data (yes/no only, no diagnosis details)"

key-files:
  created:
    - finyx/references/germany/health-insurance.md
  modified: []

key-decisions:
  - "tax_year: 2025 in frontmatter (not 2026) — matches existing doc convention; constants are 2026-effective values published under 2025 rules"
  - "fallback_rate 2.9% with source_url to GKV-Spitzenverband — Phase 10 agent fetches live rates, falls back to this"
  - "JAEG (€77,400 new switchers) and BBG (€69,750 contribution cap) in separate subsections — never conflated"
  - "Beamter section redirects to v1.3 BEAM-01 — no cost model built"
  - "Age-55 lock-in as WARNING blockquote — prominently marked, not a footnote"

patterns-established:
  - "Pattern: fallback_rate + source_url for live-fetchable reference data"
  - "Pattern: Beamter redirect with deferred version tag (e.g., v1.3 BEAM-01)"
  - "Pattern: WARNING blockquote for irreversible financial decisions with legal basis cited"

requirements-completed: [INFRA-02]

# Metrics
duration: 2min
completed: 2026-04-06
---

# Phase 9 Plan 01: Reference Foundation Summary

**German health insurance reference doc with 2026 GKV/PKV statutory constants, 3-tier risk model (15 binary flags), four calculation paths, and staleness detection — ready for Phase 10 agent @-reference**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-06T17:33:33Z
- **Completed:** 2026-04-06T17:36:20Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `finyx/references/germany/health-insurance.md` (371 lines) matching existing reference doc conventions
- Encoded all 2026 statutory constants: JAEG €77,400, BBG €69,750, base rate 14.6%, PV rates, employer caps (€508.59 KV / €104.63 PV)
- Defined 3-tier PKV risk model with 15 binary health flags (GDPR Art. 9 compliant, no diagnosis details)
- Documented four calculation paths: employee GKV, self-employed GKV, Familienversicherung, Beamter redirect
- Added `fallback_rate: 2.9%` and `source_url` fields for Phase 10 research agent consumption

## Task Commits

1. **Task 1: Create health-insurance.md reference document** - `81ed630` (feat)

**Plan metadata:** (to be added after final docs commit)

## Files Created/Modified

- `finyx/references/germany/health-insurance.md` — Authoritative GKV/PKV reference: 6 sections, 2026 constants, risk tier model, staleness detection frontmatter

## Decisions Made

- Used `tax_year: 2025` per D-08 and existing doc convention — constants are 2026-effective statutory values but the convention names the year the rules were published under
- Zusatzbeitrag section encodes `fallback_rate: 2.9%` and `source_url: https://www.gkv-spitzenverband.de` per D-05 — no individual fund rates embedded
- JAEG and BBG documented in separate subsection 4.1 with explicit cross-reference to section 1.2 — never conflated in any formula
- Age-55 lock-in formatted as blockquote WARNING (not plain text) with §6 Abs. 3a SGB V citation
- Employer contribution caps placed inline under section 1.5 per D-07

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

Minor: initial draft omitted explicit `14.6%` text — formulas used `0.146` but the verification check requires the percentage string. Fixed by adding the base rate description to section 1.3 before the Zusatzbeitrag table.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `finyx/references/germany/health-insurance.md` is ready for Phase 10 agents to `@`-reference in their `<execution_context>` blocks
- `fallback_rate` and `source_url` fields are parseable by Phase 10 research agent
- Staleness detection pattern in frontmatter matches Phase 11 command's tax_year comparison convention
- No blockers for Phase 10

---
*Phase: 09-reference-foundation*
*Completed: 2026-04-06*
