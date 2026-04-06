---
phase: 02-tax-advisors
plan: "02"
subsystem: finyx/references/brazil
tags: [brazil, tax, investment, IR, DARF, come-cotas, FII, reference-doc]
dependency_graph:
  requires: []
  provides: [finyx/references/brazil/tax-investment.md]
  affects: [commands/finyx/tax.md]
tech_stack:
  added: []
  patterns: [tax_year-frontmatter, @path-include, disclaimer-block]
key_files:
  created:
    - finyx/references/brazil/tax-investment.md
  modified: []
decisions:
  - "INSS deferred to Phase 4 (D-12): expat treatment too complex for Phase 2 scope"
  - "Law 15,270/2025 included with explicit Receita Federal uncertainty disclaimer per D-12"
  - "R$20k exemption scope restriction (normal ops only) called out as critical rule in dedicated subsection"
metrics:
  duration: 5min
  completed_date: "2026-04-06"
  tasks_completed: 1
  files_created: 1
  files_modified: 0
---

# Phase 02 Plan 02: Brazilian Investment Tax Reference Summary

**One-liner:** Brazilian investment tax reference doc covering IR rates by asset type, DARF calculation (codes 6015/3317), come-cotas mechanism, and FII dividend exemption (Law 8,668/1993 + Law 15,270/2025) with staleness-aware tax_year frontmatter.

---

## Tasks Completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Create Brazilian investment tax reference document | 67f7476 | finyx/references/brazil/tax-investment.md |

---

## What Was Built

`finyx/references/brazil/tax-investment.md` — a 207-line Markdown reference document with YAML frontmatter (`tax_year: 2025`, `country: brazil`, `domain: investment-tax`) covering:

1. **IR Rates by Investment Type** — table of all major asset classes with rates, exemptions, withholding treatment, and a dedicated subsection on the R$20k exemption scope restriction (normal operations only, never day-trade).
2. **DARF Calculation and Deadlines** — formula, DARF codes (6015 normal/FII, 3317 day-trade), payment deadline rule (last business day of following month), minimum R$10 threshold, and late penalty structure.
3. **Come-Cotas** — mechanism explanation, May/November schedule, rates by fund classification, share-redemption mechanic, annual reconciliation, and explicit exclusion list (FIIs, ETFs, direct CDBs).
4. **FII Dividend Exemption** — base rule (Law 8,668/1993, 50-quotaholder and 10%-holding conditions), capital gains treatment (always 20%, not exempt), Law 15,270/2025 "FII qualificado" changes with Receita Federal uncertainty disclaimer, and annual DIRPF declaration requirements.
5. **Cross-Border DE+BR Notes** — DBA credit mechanics, non-resident withholding, German declaration obligations.
6. **Important Notes** — consolidated reminders and explicit out-of-scope deferred items (INSS, FII edge cases).

---

## Deviations from Plan

None — plan executed exactly as written.

---

## Decisions Made

- **Law 15,270/2025 disclaimer:** Included per D-12. The "FII qualificado" category and its interaction with existing exemptions are documented with an explicit advisory that Receita Federal implementation guidance may still be pending. "Verify with a contador" phrasing meets the plan's acceptance criteria.
- **INSS scope:** INSS content is limited to a single bullet in the "Out of Scope" section explaining the deferral reason. No instructional INSS content present.
- **R$20k exemption emphasis:** Added a dedicated subsection ("R$20,000/Month Exemption — Critical Rules") beyond the table entry to ensure the day-trade exclusion is unambiguous — a common investor misunderstanding.

---

## Known Stubs

None. This is a static reference document — all sections contain substantive content. No placeholders or TODO markers.

---

## Self-Check: PASSED

- [x] `finyx/references/brazil/tax-investment.md` exists at correct path
- [x] `tax_year: 2025` in frontmatter
- [x] `country: brazil` in frontmatter
- [x] DARF codes 6015 and 3317 present
- [x] "come-cotas" with FII and ETF exclusions present
- [x] R$20k exemption documented with day-trade restriction
- [x] 22.5% CDB rate present
- [x] PGBL and VGBL with 12% threshold present
- [x] Law 15,270/2025 disclaimer with "contador" present
- [x] INSS not present as advisory content (only as deferred item note)
- [x] Commit 67f7476 exists in git log
