---
phase: 02-tax-advisors
plan: "01"
subsystem: finyx-references
tags: [german-tax, investment-tax, reference-doc, profile-schema]
dependency_graph:
  requires: []
  provides:
    - finyx/references/germany/tax-investment.md
    - finyx/templates/profile.json (brokers[] schema)
  affects:
    - commands/finyx/tax.md (Plan 03 loads tax-investment.md via @path)
tech_stack:
  added: []
  patterns:
    - YAML frontmatter with tax_year for staleness detection (D-05)
    - Reference doc sourced from fin-tax skill (D-07)
    - brokers[] array in profile schema for per-broker tracking (D-09)
key_files:
  created:
    - finyx/references/germany/tax-investment.md
  modified:
    - finyx/templates/profile.json
decisions:
  - "Content sourced directly from ~/.claude/skills/fin-tax/SKILL.md per D-07 — no invented tax figures"
  - "801 EUR Sparerpauschbetrag mentioned only as historical context with explicit do-not-use warning"
  - "Steuerklassen I-VI written fresh (not in skill) with explicit note that they do not affect capital gains tax"
  - "Vorabpauschale 2026 Basiszins (3.20%) flagged for verification — BMF publishes annually"
metrics:
  duration: "~7 minutes"
  completed: "2026-04-06"
  tasks_completed: 2
  files_created: 1
  files_modified: 1
---

# Phase 02 Plan 01: German Investment Tax Reference and Profile Schema Summary

## One-liner

German investment tax reference doc (Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung, Steuerklassen) with tax_year YAML frontmatter, content sourced from fin-tax skill; profile schema extended with brokers[] for Freistellungsauftrag tracking.

## What Was Built

### Task 1 — `finyx/references/germany/tax-investment.md`

New reference document (293 lines) covering all 6 DETAX requirements:

| Section | Content | Requirement |
|---------|---------|-------------|
| Steuerklassen I–VI | Table of all 6 classes, recommendation logic, explicit note that class does NOT affect capital gains tax | DETAX-01 |
| Abgeltungssteuer | 26.375% effective rate, Günstigerprüfung rules, Anlage KAP filing triggers | DETAX-05 |
| Sparerpauschbetrag | 1,000/2,000 EUR (since 2023), Freistellungsauftrag strategy, cross-broker allocation example | DETAX-02 |
| Teilfreistellung | Complete rates table (equity 30%, mixed 15%, bond 0%, RE 60%, foreign RE 80%), explicit stocks-only exclusion note | DETAX-04 |
| Vorabpauschale | Formula, Basiszins 2025 (2.29%) and 2026 (3.20%), practical example, accumulating vs distributing ETF comparison | DETAX-03 |
| Anlage KAP line mapping | Lines 18–26 for foreign brokers, Line 19 calculation template | DETAX-05 (filing) |
| Tax calendar | All key dates (January Vorabpauschale, Dec 15 Verlustbescheinigung, year-end harvesting) | — |
| Common pitfalls | Pre-2018 rules superseded note, 801 EUR warning, ETF domicile preference | DETAX-06 (staleness) |

YAML frontmatter: `tax_year: 2025`, `country: germany`, `domain: investment-tax`, `last_updated: 2026-04-06`.

### Task 2 — `finyx/templates/profile.json`

Added `"brokers": []` to `countries.germany` object. All existing fields preserved exactly:
- `tax_class: null` — unchanged
- `church_tax: false` — unchanged
- `gross_income: 0` — unchanged
- `marginal_rate: 0` — unchanged
- `countries.brazil` — unchanged
- `investor.marginalRate` — unchanged (backward compat)

## Commits

| Hash | Task | Description |
|------|------|-------------|
| 02589d7 | Task 1 | feat(02-01): create German investment tax reference document |
| ea5d77d | Task 2 | feat(02-01): extend profile.json with brokers array under countries.germany |

## Deviations from Plan

None — plan executed exactly as written. Content sourced from `~/.claude/skills/fin-tax/SKILL.md` per D-07. Steuerklassen section written fresh as specified.

## Known Stubs

None. This plan creates reference documents and schema — no UI rendering or data sources are involved.

## Self-Check: PASSED

- [x] `finyx/references/germany/tax-investment.md` exists — verified
- [x] `tax_year: 2025` in frontmatter — verified
- [x] `country: germany` in frontmatter — verified
- [x] `Steuerklasse` present (4 occurrences) — verified
- [x] `26.375%` present — verified
- [x] `1,000 EUR` and `2,000 EUR` present — verified
- [x] Teilfreistellung rates 30%, 15%, 60%, 80% present — verified
- [x] Vorabpauschale with Basiszins 2.29% and 3.20% present — verified
- [x] `Basisertrag` formula present — verified
- [x] `Günstigerprüfung` present — verified
- [x] 801 EUR referenced only as historical context with explicit warning — verified
- [x] Explicit note: Teilfreistellung applies to funds only, not individual stocks — verified
- [x] `countries.germany.brokers` is `[]` — verified (node parse check)
- [x] All other profile.json fields preserved — verified
- [x] `finyx/references/germany/tax-rules.md` NOT modified — verified (git status clean for that file)
- [x] Commits 02589d7 and ea5d77d exist — verified
