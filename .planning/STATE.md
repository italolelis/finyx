---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: Comprehensive Insurance Advisor
status: executing
stopped_at: Completed 22-01-PLAN.md
last_updated: "2026-04-12T21:19:13.079Z"
last_activity: 2026-04-12
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 12
  completed_plans: 11
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-12)

**Core value:** A single AI-powered financial advisor that knows your full financial picture and gives integrated, country-aware advice
**Current focus:** Phase 22 — per-type-sub-skills-tier-3-4-doc-reader

## Current Position

Phase: 22 (per-type-sub-skills-tier-3-4-doc-reader) — EXECUTING
Plan: 3 of 3
Status: Ready to execute
Last activity: 2026-04-12

```
Progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/5 phases)
```

## Accumulated Context

### Decisions

All prior decisions logged in PROJECT.md Key Decisions table.

v2.1 key context:

- Plugin auto-update is native (claude plugin update finyx) — no update skill needed
- Insurance skill must be generic, not biased to any specific user's providers
- User has 12 insurance types as reference for coverage scope
- Health insurance (Krankenversicherung/PKV/GKV) already covered in v1.2 — must migrate to sub-skill in Phase 18
- Router must come first: all per-type sub-skills depend on ARCH-01
- Reference docs + agents must precede type sub-skills (Phase 19 before 21/22)
- Phase 21 and 22 can only start after Phase 19 (not after each other — they are parallel-capable but sequenced by instruction)
- §34d GewO: all outputs recommend criteria, never specific competing tariffs
- Kfz is most complex type: SF-Klasse, Typklasse, Regionalklasse, three coverage levels
- Stiftung Warentest/Finanztip as primary sources; Check24/Verivox as fallback only
- BU (Berufsunfähigkeit) deferred to v2.2 — own milestone due to complexity
- [Phase 18-router-sub-skill-migration]: Router SKILL.md is a pure dispatcher (~96 lines) with zero health-specific logic; all advisory content lives in sub-skill files
- [Phase 18-router-sub-skill-migration]: Sub-skill files are plain Markdown (no YAML frontmatter, no execution_context block) loaded by Read tool at dispatch time
- [Phase 19-01]: Use short slugs (hausrat, haftpflicht, kfz) as type enum for insurance.policies — matches reference doc filenames and enables direct path construction in agents
- [Phase 19-reference-docs-profile-schema-agents]: coverage_type annotation on every reference doc prevents portfolio agent from comparing sum-based and service-based coverage monetarily
- [Phase 19-reference-docs-profile-schema-agents]: kfz.md: one policy entry per Kfz contract; three coverage tiers captured in coverage_components field, not separate entries
- [Phase 19]: Health type retains existing PKV 3-provider comparison; all other types use criteria-only output per §34d GewO
- [Phase 19]: Portfolio agent loads all 11 reference docs unconditionally in execution_context
- [Phase 20]: insurance.monthly_cost prohibition text in allocation agent prompt is intentional — single occurrence tells agent not to use defunct field
- [Phase 20-portfolio-analysis]: Sub-skill writes to profile.json only in Phase 0 empty-portfolio entry; all other output is conversational
- [Phase 20-portfolio-analysis]: Portfolio sub-skill spawns single agent (not parallel) — portfolio agent consolidates all analysis internally
- [Phase 21-per-type-sub-skills-tier-1-2]: Kfz sub-skill: vehicle age brackets use 4-tier structure from kfz.md (0-3, 3-7, 7-12, 12+) for alignment with reference doc
- [Phase 21-per-type-sub-skills-tier-1-2]: Kfz sub-skill: 30.11 cancellation deadline is calendar-pinned (1-month Kuendigungsfrist on 01.01 renewal) — documented explicitly as Kfz-unique rule
- [Phase 21-02]: Staffelung warning unconditional in Zahnzusatz — shown even without immediate dental needs as structural purchase risk
- [Phase 21-02]: Risikoleben renewal_date = policy END DATE (Vertragsende) — displayed as 'Policy expires', never 'Next renewal'
- [Phase 21-02]: Gesundheitsprüfung warning placed in 3 locations in Risikoleben (disclaimer, cancellation, recommendation) — intentional due to severity of cancel-before-approval mistake
- [Phase 21-per-type-sub-skills-tier-1-2]: Rechtsschutz coverage_amount is null — Phase 3 uses module-based PASS/MISSING/N/A, never monetary benchmark
- [Phase 21-per-type-sub-skills-tier-1-2]: Hausrat living_area_sqm uses 3-source priority: Phase 0 user input > profile field lookup > UNKNOWN (never skips benchmark phase)
- [Phase 22]: Kfz-Schutzbrief leads with overlap detection (Kfz policy then ADAC) before component benchmark
- [Phase 22]: Mietkaution Regresspflicht warning placed in Phase 3 and Phase 6 (dual placement) — intentional for severity

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-04-12T21:19:13.076Z
Stopped at: Completed 22-01-PLAN.md
Resume file: None
