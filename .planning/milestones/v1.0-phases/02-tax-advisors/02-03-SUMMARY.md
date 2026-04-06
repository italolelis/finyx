---
phase: 02-tax-advisors
plan: 03
subsystem: commands/finyx
tags: [tax, slash-command, germany, brazil, cross-border]
dependency_graph:
  requires: [02-01, 02-02]
  provides: [finyx:tax command, help.md registration]
  affects: [commands/finyx/help.md]
tech_stack:
  added: []
  patterns: [profile-gate, execution_context @path, country-routing, AskUserQuestion interactive collection]
key_files:
  created:
    - commands/finyx/tax.md
  modified:
    - commands/finyx/help.md
decisions:
  - "Load both country reference docs unconditionally in execution_context — minimal overhead, simplifies process logic"
  - "Sparerpauschbetrag broker data collection via AskUserQuestion with Write offer — stateless per D-08"
  - "Tax year staleness check hardcodes 2025 in bash comparison — clear, simple, works until docs are updated"
metrics:
  duration: 212s
  completed: "2026-04-06"
  tasks: 2
  files_changed: 2
---

# Phase 02 Plan 03: Create /finyx:tax Command Summary

**One-liner:** Unified `/finyx:tax` slash command with country routing for German Abgeltungssteuer/Sparerpauschbetrag/Vorabpauschale and Brazilian IR/DARF/FII guidance, plus DBA cross-border section for DE+BR users.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create /finyx:tax slash command | 991794a | commands/finyx/tax.md (new, 545 lines) |
| 2 | Register /finyx:tax in help.md | ca7f367 | commands/finyx/help.md (+42 lines) |

## What Was Built

### `commands/finyx/tax.md`

The unified investment tax advisor command covering:

**Phase 1: Validation** — profile gate + country detection from `countries.germany.tax_class` / `countries.brazil.ir_regime` / `identity.cross_border`

**Phase 2: Tax Year Staleness Check** — bash `date +%Y` vs reference doc `tax_year: 2025`; warns when mismatch

**Phase 3: German Investment Tax** (Germany-only or cross-border):
- 3.1 Steuerklasse: reads profile `tax_class`, explains class meaning, gives optimization recommendation (III/V vs IV/IV logic)
- 3.2 Abgeltungssteuer: 25% + Soli breakdown, church tax rate (8%/9%), Günstigerprüfung eligibility when marginal rate < 26.375%
- 3.3 Teilfreistellung: full fund type table (equity 30%, mixed 15%, RE 60%/80%, bonds 0%), clarifies it does NOT apply to individual stocks
- 3.4 Sparerpauschbetrag: 1,000/2,000 EUR based on family_status, reads brokers[] from profile, AskUserQuestion collection if empty, per-broker table output, §44a EStG warning if over-allocated
- 3.5 Vorabpauschale: interactive collection of ETF value, step-by-step formula with Basiszins 2025 (2.29%), Teilfreistellung application, January cash buffer reminder

**Phase 4: Brazilian Investment Tax** (Brazil-only or cross-border):
- 4.1 IR rates table: stocks/FII/CDB/LCI-LCA/previdência, R$20k/month exemption rules
- 4.2 DARF: monthly calculation formula, codes 6015/3317, last-business-day deadline, penalty rates
- 4.3 Come-cotas: mechanism explanation, May/November timing, explicit scope boundary (NOT FIIs, NOT ETFs)
- 4.4 FII dividend exemption: Law 8,668/1993 base rule, Law 15,270/2025 "FII qualificado" changes, mandatory D-12 disclaimer ("verify with a contador"), annual DIRPF declaration requirement

**Phase 5: Cross-Border DBA** (only when `identity.cross_border == true`):
- OECD Art. 4 tiebreaker (permanent home → habitual abode → nationality → mutual agreement)
- Withholding credit mechanics (DE resident claiming BR tax on Anlage AUS; BR resident crediting German withholding)
- Double-dip prevention rule
- Scope disclaimer: INSS expat treatment and Law 15,270/2025 FII edge cases explicitly out-of-scope (D-12)

**Phase 6: Disclaimer** — appends full `disclaimer.md` content

### `commands/finyx/help.md`

- Updated subtitle from "Real Estate Investment Analysis System" to "Personal Finance Advisor"
- Updated workflow diagram to show TAX as a branch available after PROFILE
- Added "Tax Advisory" section to the Commands table
- Added `/finyx:tax` quick start entry
- Added full `/finyx:tax` detail section after `/finyx:profile` with all covered topics

## Requirements Covered

| Requirement | Status |
|-------------|--------|
| DETAX-01 Steuerklassen I-VI | Covered — Phase 3.1 |
| DETAX-02 Sparerpauschbetrag tracking | Covered — Phase 3.4 |
| DETAX-03 Vorabpauschale calculation | Covered — Phase 3.5 |
| DETAX-04 Teilfreistellung rates | Covered — Phase 3.3 |
| DETAX-05 Abgeltungssteuer breakdown | Covered — Phase 3.2 |
| DETAX-06 tax_year staleness detection | Covered — Phase 2 |
| BRTAX-01 IR filing guidance | Covered — Phase 4.1 |
| BRTAX-02 DARF calculation + codes | Covered — Phase 4.2 |
| BRTAX-03 Come-cotas explanation | Covered — Phase 4.3 |
| BRTAX-04 FII dividend exemption | Covered — Phase 4.4 |
| BRTAX-05 Law 15,270/2025 coverage | Covered — Phase 4.4 |
| BRTAX-06 tax_year staleness (BR) | Covered — Phase 2 (same check covers both) |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The command is a prompt-based advisor — no data sources that could be empty/unconnected. The brokers[] array collection handles the empty-state case interactively via AskUserQuestion.

## Self-Check

Files exist:
- commands/finyx/tax.md: FOUND
- commands/finyx/help.md: FOUND (modified)

Commits:
- 991794a: FOUND
- ca7f367: FOUND
