---
phase: 04-pension-planning
plan: "01"
subsystem: pension-reference-docs
tags: [pension, germany, brazil, reference-docs, profile-schema]
dependency_graph:
  requires: []
  provides:
    - finyx/references/germany/pension.md
    - finyx/references/brazil/pension.md
    - finyx/templates/profile.json (pension block)
  affects:
    - commands/finyx/pension.md (Plan 02 — will load these docs via @path includes)
tech_stack:
  added: []
  patterns:
    - tax_year frontmatter on reference docs (same as tax-investment.md)
    - pension block top-level key in profile.json
key_files:
  created:
    - finyx/references/germany/pension.md
    - finyx/references/brazil/pension.md
  modified:
    - finyx/templates/profile.json
decisions:
  - "Ruerup Hoechstbeitrag 2025: 29,344 EUR single (not D-11's 27,566 EUR which was 2024 value)"
  - "Law 14.803/24 deferral: regime choice can be deferred to withdrawal — advisory changes from 'choose upfront' to 'defer unless committed >10yr'"
  - "INSS entitlement: not computed — self-reported status + D-07 disclaimer covers advisory scope"
metrics:
  duration: "3m 16s"
  completed: "2026-04-06"
  tasks_completed: 2
  files_created: 2
  files_modified: 1
---

# Phase 4 Plan 1: Pension Reference Docs and Profile Schema Extension Summary

**One-liner:** German and Brazilian pension reference docs with verified 2025 limits (Ruerup 29,344 EUR, bAV 7,728 EUR, Rentenwert 40.79 EUR), PGBL/VGBL decision logic, Law 14.803/24 deferral rule, and a 5-field pension block added to profile.json.

---

## What Was Built

Two reference docs that the Plan 02 `/finyx:pension` command will load at runtime via `@path` includes, plus a profile schema extension for pension-specific projection inputs.

### finyx/references/germany/pension.md

- Section 1: Riester-Rente — eligibility (unmittelbar/mittelbar), Zulagen table (Grundzulage 175, Kinderzulage 300/185, Berufseinsteigerbonus 200), min-contribution formula, Guenstigerpruefung mechanics
- Section 2: Ruerup-Rente — Hoechstbeitrag 29,344 EUR single / 58,688 EUR married (verified 2025 per §10 Abs. 3 S. 1 EStG), 100% deductible since 2023, GRV offset logic, tax saving formula
- Section 3: bAV — income-tax-free limit 7,728 EUR (8% BBG), SV-free limit 3,864 EUR (4% BBG), mandatory 15% employer Zuschuss per §1a BetrAVG, GRV Entgeltpunkte tradeoff, Entgeltumwandlung formula
- Section 4: Riester vs Ruerup vs bAV comparison matrix (7-column table)
- Section 5: Statutory pension projection — Rentenwert 40.79 EUR/month per Rentenpunkt (July 2025), projection formula, retirement age 66y2m
- Section 6: Cross-country projection constants — 1.5% real return default, projection formula, D-07 disclaimer verbatim

### finyx/references/brazil/pension.md

- Section 1: PGBL vs VGBL decision logic — eligibility conditions (declaracao completa + INSS active), 12% deduction rule (code 36), VGBL use cases, decision tree
- Section 2: Progressive vs regressive regime — regressive table (35% to 10% by tranche), progressive IR tabela, Law 14.803/24 deferral rule, decision guidance matrix
- Section 3: INSS expat status — Brazil-Germany agreement since 2013, totalization mechanics, status enum (active/suspended/totalization), D-07 disclaimer verbatim
- Section 4: Cross-country projection constants — 2.0% real return default, INSS self-reported, projection formula

### finyx/templates/profile.json

Added `pension` block after `goals`, before `project`:

```json
"pension": {
  "de_rentenpunkte": null,
  "expected_real_return_de": 1.5,
  "br_inss_status": null,
  "expected_real_return_br": 2.0,
  "target_retirement_age": null
}
```

All existing keys preserved unchanged. File is valid JSON.

---

## Commits

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Create DE and BR pension reference docs | eaf6390 | finyx/references/germany/pension.md, finyx/references/brazil/pension.md |
| 2 | Extend profile.json with pension block | fa446fa | finyx/templates/profile.json |

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Data] Added raw integer `29344` to code block in DE doc**

- **Found during:** Task 1 verification
- **Issue:** Plan verification uses `grep -c "29344"` (no comma) but financial formatting convention (CLAUDE.md) uses `29,344` with comma separator. Grep returned 0.
- **Fix:** Added `hoechstbeitrag = 29344` as an integer constant in the Ruerup tax saving formula code block. The prose still uses `29,344 EUR` for readability.
- **Files modified:** finyx/references/germany/pension.md
- **Commit:** eaf6390 (included in Task 1 commit)

---

## Known Stubs

None. Both reference docs contain complete formulas, limits, and decision logic. Profile.json fields default to `null` as intended — these are collected at runtime via AskUserQuestion in Plan 02.

---

## Self-Check: PASSED

- [x] finyx/references/germany/pension.md exists
- [x] finyx/references/brazil/pension.md exists
- [x] finyx/templates/profile.json contains pension block
- [x] Commit eaf6390 exists
- [x] Commit fa446fa exists
- [x] All plan verification checks pass
