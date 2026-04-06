---
phase: 04-pension-planning
plan: 02
subsystem: commands/finyx
tags: [pension, riester, ruerup, bav, pgbl, vgbl, cross-border, cli]
dependency_graph:
  requires:
    - 04-01  # finyx/references/germany/pension.md, finyx/references/brazil/pension.md, finyx/templates/profile.json pension block
  provides:
    - commands/finyx/pension.md
    - commands/finyx/help.md (updated)
  affects:
    - commands/finyx/help.md (workflow diagram, quick start, command tables)
tech_stack:
  added: []
  patterns:
    - "Country routing via profile field presence (tax_class != null = DE active, ir_regime != null = BR active)"
    - "Cross-border gating via identity.cross_border flag"
    - "AskUserQuestion for runtime data collection (children birth years, INSS status, retirement age)"
    - "Phase 7 batch save offer — single Write after session collects all missing data"
key_files:
  created:
    - commands/finyx/pension.md
  modified:
    - commands/finyx/help.md
decisions:
  - "Riester Zulagen collected at runtime via AskUserQuestion — children birth years not pre-stored in profile to avoid schema breaks"
  - "Ruerup Hoechstbeitrag uses 2025 verified figure 29344 EUR single (not D-11's 2024 value of 27566)"
  - "INSS entitlement not computed — self-reported status + D-07 disclaimer only (per D-06)"
  - "Phase 5 cross-country projection gated strictly on cross_border == true (not just on both countries being active)"
metrics:
  duration: 374s
  completed_date: "2026-04-06"
  tasks_completed: 2
  files_changed: 2
---

# Phase 04 Plan 02: /finyx:pension Command Summary

**One-liner:** Unified pension command with 7-phase country-routed guidance covering Riester/Rürup/bAV (DE), PGBL/VGBL with Law 14.803/24 deferral (BR), and inflation-adjusted cross-country retirement projection gated on cross_border flag.

## What Was Built

### Task 1: /finyx:pension command (`commands/finyx/pension.md`)

7-phase command mirroring the `tax.md` architecture exactly:

- **Phase 1:** Profile validation (bash check + country detection)
- **Phase 2:** Staleness check comparing `tax_year: 2025` to current year
- **Phase 3:** German pension — Riester Zulagen (with AskUserQuestion for children birth years), Rürup Sonderausgabenabzug estimate with GRV offset, bAV Entgeltumwandlung guidance with mandatory GRV tradeoff note, Riester vs Rürup vs bAV comparison matrix with personalized recommendation
- **Phase 4:** Brazilian pension — PGBL vs VGBL decision tree (gated on ir_regime + INSS status), progressive vs regressive regime tables with Law 14.803/24 deferral advisory, INSS status collection
- **Phase 5:** Cross-country projection (gated on `cross_border == true`) — collects missing inputs via AskUserQuestion, builds inflation-adjusted projection table with D-07 disclaimer verbatim
- **Phase 6:** Legal disclaimer from disclaimer.md
- **Phase 7:** Batch save offer for all session-collected pension data

### Task 2: help.md registration (`commands/finyx/help.md`)

Four additions:
1. PENSION node in workflow diagram (after BROKER)
2. Quick Start step 1e for `/finyx:pension`
3. "### Pension Advisory" table with command entry
4. Detailed `/finyx:pension` command description section

## Decisions Made

| Decision | Reason |
|----------|--------|
| Children birth years collected at runtime, not pre-stored | Profile schema stability — existing profiles have `children` as a count; adding `children_birth_years` only on consent avoids breaking changes |
| 29,344 EUR Rürup Höchstbeitrag (2025) | Verified statutory figure — D-11 referenced 27,566 which was the 2024 value |
| INSS entitlement not computed | Per D-06: contribution history and treaty interpretation are out of advisory scope; self-reported status + D-07 disclaimer sufficient |
| Phase 5 gated on cross_border flag, not just both-countries-active | Explicit cross-border intent required — a user with DE and BR profiles who is not cross-border doesn't need a combined projection |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all sections are fully implemented with real formula logic, tables, and AskUserQuestion flows. No placeholder or hardcoded empty values.

## Requirements Satisfied

- PENSION-01: German pension vehicles (Riester/Rürup/bAV) — Phase 3 covers all three with comparison matrix
- PENSION-02: Riester Zulagen calculation with Grundzulage and Kinderzulage — Phase 3.2
- PENSION-03: Rürup Sonderausgabenabzug estimate with income and marginal rate — Phase 3.3
- PENSION-04: PGBL vs VGBL decision guide driven by IR regime and 12% threshold — Phase 4.1
- PENSION-05: Progressive vs regressive regime with Law 14.803/24 deferral — Phase 4.2
- PENSION-06: Cross-border projection gated on cross_border flag — Phase 5

## Self-Check: PASSED
