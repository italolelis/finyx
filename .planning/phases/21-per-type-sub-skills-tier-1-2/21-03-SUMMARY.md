---
phase: 21-per-type-sub-skills-tier-1-2
plan: 03
subsystem: insurance
tags: [kfz, sf-klasse, coverage-tiers, cancellation-tracking, research-agent]

# Dependency graph
requires:
  - phase: 19-reference-docs-profile-schema-agents
    provides: kfz.md reference doc with SF-Klasse, coverage tiers, cancellation rules
  - phase: 18-router-sub-skill-migration
    provides: router SKILL.md dispatch to kfz sub-skill slug

provides:
  - Kfz insurance sub-skill with 3-tier comparison (Haftpflicht / Teilkasko / Vollkasko)
  - Extended 6-question preferences phase collecting vehicle-specific context
  - SF-Klasse no-claims bonus explanation and impact display
  - When-to-upgrade guidance based on 4 vehicle age brackets
  - Financed vehicle warning (Vollkasko contractually required)
  - Kfz-specific 30.11 cancellation deadline tracking with 01.01 renewal logic
  - Research agent spawn with sf_klasse, vehicle_age_years, annual_km, user_city params
  - §1 PflVG mandatory status and §6 PflVG criminal penalty documentation

affects:
  - Phase 22 (remaining sub-skills if added)
  - finyx-insurance-research-agent (receives Kfz-specific params)
  - insurance portfolio sub-skill (policy data read pattern)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Extended preferences phase: 6 questions in 3 rounds for complex insurance types"
    - "3-column tier comparison table with MANDATORY / COVERED / Not covered cells"
    - "Vehicle age bracket → tier recommendation mapping from reference doc"
    - "Financed vehicle detection → elevated Vollkasko warning banner"
    - "Kfz-specific 30.11 cancellation deadline from 1-month Kuendigungsfrist on 01.01 renewal"
    - "SF-Klasse passed as numeric param to research agent for premium personalization"

key-files:
  created:
    - skills/insurance/sub-skills/kfz.md
  modified: []

key-decisions:
  - "Vehicle age brackets use 4 tiers (0-3, 3-7, 7-12, 12+) matching kfz.md Coverage Benchmarks exactly"
  - "Financed vehicle Vollkasko requirement shown as banner, not inline text — contractual compliance issue"
  - "30.11 deadline documented explicitly in Phase 4 as Kfz-specific calendar-pinned rule"
  - "vehicle_age_years passed as bracket midpoint (e.g., '0-3 years' → 2) for research agent quantification"
  - "SF-Klasse reclassification included as distinct Sonderkundigungsrecht trigger (unique to Kfz among sub-skills)"
  - "No YAML frontmatter, no execution_context block — consistent with health.md and portfolio.md sub-skill contract"

patterns-established:
  - "Extended preferences: complex sub-skills collect type-specific data before any analysis (health pattern extended)"
  - "Kfz 30.11 deadline: Phase 4 uses calendar-pinned logic instead of general anniversary computation"
  - "Research agent Kfz params: sf_klasse + vehicle_age_years + annual_km + user_city form the Kfz-specific param set"

requirements-completed: [TYPE-03, OPT-01, OPT-03]

# Metrics
duration: 15min
completed: 2026-04-12
---

# Phase 21 Plan 03: Kfz Insurance Sub-skill Summary

**Kfz sub-skill with 3-tier Haftpflicht/Teilkasko/Vollkasko comparison, SF-Klasse collection (0-35), age-bracket upgrade guidance, 30.11 cancellation deadline, and research agent spawn with vehicle-specific params**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-12T20:49:00Z
- **Completed:** 2026-04-12T20:52:52Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `skills/insurance/sub-skills/kfz.md` (474 lines) — the most complex of the 6 insurance sub-skills
- Extended Phase 0 collects 6 vehicle-specific data points across 3 question rounds (tier, SF-Klasse with explanation, vehicle age, annual km, garage, financed)
- Phase 3 presents a 3-column tier comparison table showing all coverage inclusions across Haftpflicht / Teilkasko / Vollkasko, plus vehicle-age-based when-to-upgrade guidance and a financing warning banner
- Phase 4 implements the Kfz-specific 30.11 cancellation deadline rule (1-month Kuendigungsfrist applied to 01.01 renewal), with alert banners for urgent/closed/unknown states and SF-Klasse reclassification as a Sonderkundigungsrecht trigger
- Phase 5 passes sf_klasse, vehicle_age_years (bracket midpoint), annual_km, and user_city to the research agent for personalized market context

## Task Commits

1. **Task 1: Create Kfz sub-skill (kfz.md)** - `281c00c` (feat)

## Files Created/Modified

- `skills/insurance/sub-skills/kfz.md` — Kfz insurance sub-skill with 7 phases (Preferences, Validation, Disclaimer, Coverage Benchmark, Cancellation, Research Agent, Recommendation)

## Decisions Made

- Vehicle age brackets use the 4-tier structure from kfz.md Coverage Benchmarks (0-3, 3-7, 7-12, 12+) for alignment with reference doc
- Financed vehicle Vollkasko requirement shown as a warning banner (not inline text) because it is a contractual compliance issue, not a coverage preference
- 30.11 cancellation deadline documented explicitly and repeatedly — it is Kfz-unique and important for users
- vehicle_age_years passed as bracket midpoint integer to give the research agent a quantifiable value

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

The automated verify test (`! grep -q "^---"`) false-positives on horizontal rule dividers (`---`) in the file body — the same issue would affect health.md (the template). The file correctly has no YAML frontmatter (confirmed by `head -1` returning `# Kfz Insurance Sub-skill`). All other verify checks pass. Similarly `! grep -q "execution_context"` false-positives on the notes section documentation text explaining what NOT to add. Both are test pattern limitations, not file issues.

## Next Phase Readiness

- All 3 Phase 21 plans complete: haftpflicht.md (plan 01), hausrat.md (plan 02), kfz.md (plan 03)
- Phase 22 would cover rechtsschutz, zahnzusatz, risikoleben if planned
- kfz sub-skill is fully wired to the router (SKILL.md already dispatches to `kfz` slug)
- Research agent is parameterized to handle kfz type with vehicle-specific params

---
*Phase: 21-per-type-sub-skills-tier-1-2*
*Completed: 2026-04-12*
