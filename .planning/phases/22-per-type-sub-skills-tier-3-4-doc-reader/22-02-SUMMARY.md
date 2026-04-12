---
phase: 22-per-type-sub-skills-tier-3-4-doc-reader
plan: "02"
subsystem: insurance-sub-skills
tags: [insurance, kfz-schutzbrief, mietkaution, sub-skills, overlap-detection, regresspflicht]
dependency_graph:
  requires: [skills/insurance/sub-skills/haftpflicht.md, skills/insurance/references/germany/kfz-schutzbrief.md, skills/insurance/references/germany/mietkaution.md]
  provides: [skills/insurance/sub-skills/kfz-schutzbrief.md, skills/insurance/sub-skills/mietkaution.md]
  affects: [skills/insurance/SKILL.md router dispatch]
tech_stack:
  added: []
  patterns: [7-phase sub-skill structure, service-based coverage type, computed benchmark, dual-warning placement]
key_files:
  created:
    - skills/insurance/sub-skills/kfz-schutzbrief.md
    - skills/insurance/sub-skills/mietkaution.md
  modified: []
decisions:
  - "Kfz-Schutzbrief leads with overlap detection (Kfz policy then ADAC) before component benchmark"
  - "Missing Kfz policy entry is an info note not an error — user may not have recorded it"
  - "Mietkaution benchmark is computed (nettokaltmiete * 3) not a static threshold from reference doc"
  - "Regresspflicht warning placed in both Phase 3 and Phase 6 — dual placement intentional for severity"
  - "Tenancy-end cancellation warning in Phase 4 always shown when policy exists"
metrics:
  duration_minutes: 8
  completed_date: "2026-04-12"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 22 Plan 02: Kfz-Schutzbrief and Mietkaution Sub-skills Summary

**One-liner:** Kfz-Schutzbrief sub-skill with ADAC/Kfz overlap detection as primary value, and Mietkaution sub-skill with §551 BGB computed benchmark and mandatory dual-placement Regresspflicht warning.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Kfz-Schutzbrief sub-skill | 6fe86d0 | skills/insurance/sub-skills/kfz-schutzbrief.md |
| 2 | Mietkautionsversicherung sub-skill | 9324a6e | skills/insurance/sub-skills/mietkaution.md |

## What Was Built

### Kfz-Schutzbriefversicherung Sub-skill

7-phase advisory sub-skill for motor breakdown assistance. The defining feature is overlap detection in Phase 3:

1. **Kfz policy overlap check (first):** Reads `insurance.policies[]` for `type == "kfz"`, then checks `coverage_components` for substring matches of "Schutzbrief", "Pannenhilfe", "Abschleppen", "ADAC-Schutzbrief". Emits OVERLAP warning banner if found. If no Kfz policy in profile: info note (not error).
2. **ADAC membership check (second):** If `has_adac == "Yes"` from Phase 0, emits ADAC redundancy warning with note that ADAC covers any vehicle driven (not just owned).
3. **Service component benchmark table:** Pannenhilfe, geographic scope, Abschleppen, Mietwagen, 24/7 Hotline — PASS/FAIL/WARN/INFO per component.

Phase 6 leads with overlap synthesis. ADAC vs. standalone scope distinction always included.

Reads benchmarks from `${CLAUDE_SKILL_DIR}/references/germany/kfz-schutzbrief.md` at runtime. Spawns `finyx-insurance-research-agent` with `insurance_type: kfz-schutzbrief`.

### Mietkautionsversicherung Sub-skill

7-phase advisory sub-skill for rental deposit insurance.

**Computed benchmark:** Phase 0 collects `nettokaltmiete` (required text input). Phase 3 computes `recommended_deposit = nettokaltmiete * 3` from §551 BGB. If nettokaltmiete is null, benchmark comparison is skipped with an explanatory note.

**Regresspflicht (dual-placement, mandatory):** The insurer's right to recover from the tenant after paying the landlord is the most misunderstood aspect. Warning appears in Phase 3.2 (immediately after benchmark table) and again in Phase 6 recommendation. Both placements are unconditional.

**Landlord prerequisite:** Phase 0 collects acceptance status. Phase 6 addresses non-acceptance or "not yet discussed" as first decision point.

**Tenancy-end cancellation guard:** Phase 4 always emits a warning against cancelling the policy before tenancy ends without written landlord Freigabe.

Reads benchmarks from `${CLAUDE_SKILL_DIR}/references/germany/mietkaution.md` at runtime. Spawns `finyx-insurance-research-agent` with `insurance_type: mietkaution`.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both sub-skills are complete advisory prompts with all referenced data sources, phase logic, and agent spawn instructions wired.

## Self-Check: PASSED

- `skills/insurance/sub-skills/kfz-schutzbrief.md` — FOUND
- `skills/insurance/sub-skills/mietkaution.md` — FOUND
- Commit 6fe86d0 — FOUND
- Commit 9324a6e — FOUND
