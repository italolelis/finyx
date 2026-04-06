---
phase: 03-investment-broker
plan: "01"
subsystem: broker-reference
tags: [broker, reference-docs, profile-schema, germany, brazil]
dependency_graph:
  requires: []
  provides:
    - finyx/references/germany/brokers.md
    - finyx/references/brazil/brokers.md
    - finyx/templates/profile.json (brokers[] + _holdings_schema)
  affects:
    - commands/finyx/broker.md (will load broker reference docs via @path)
    - commands/finyx/invest.md (will read holdings[] from profile.json)
tech_stack:
  added: []
  patterns:
    - last_verified frontmatter in reference docs (mirrors tax-investment.md)
    - _holdings_schema doc block in profile.json for holdings[] structure
key_files:
  created:
    - finyx/references/germany/brokers.md
    - finyx/references/brazil/brokers.md
  modified:
    - finyx/templates/profile.json
decisions:
  - "Germany doc covers 4 German brokers + 2 foreign brokers (Trading212, IBKR) for tax contrast (BROKER-04)"
  - "Brazil doc covers 3 brokers with explicit DARF self-reporting note (no auto-withholding in Brazil)"
  - "_holdings_schema added as top-level key (not a comment) because JSON has no comment syntax"
  - "Brazil brokers[] added to profile.json to fix Pitfall 1 from RESEARCH.md"
metrics:
  duration: "2min"
  completed: 2026-04-06
  tasks_completed: 2
  files_created: 2
  files_modified: 1
---

# Phase 3 Plan 1: Broker Reference Docs and Profile Schema Summary

**One-liner:** Static broker comparison docs for Germany (4 brokers + tax reporting quality) and Brazil (3 brokers + DARF note), plus profile.json extended with holdings[] schema.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create broker reference docs (Germany + Brazil) | e0702c7 | finyx/references/germany/brokers.md, finyx/references/brazil/brokers.md |
| 2 | Extend profile.json with holdings[] and Brazil brokers[] | f15ae66 | finyx/templates/profile.json |

---

## What Was Built

### finyx/references/germany/brokers.md

Fee and tax reporting comparison for the four main German brokers:
- Trade Republic (€1/order, free Sparplan, auto Jahressteuerbescheinigung)
- Scalable Capital (FREE model €0.99/<€250 / free ≥€250; PRIME+ €4.99/month flat)
- ING (€4.90 + 0.25%, promo-free Sparplan)
- comdirect (€4.90 + 0.25%, promo-free Sparplan)

Foreign broker contrast for BROKER-04 compliance coverage:
- Trading212 and IBKR: no Freistellungsauftrag, no Jahressteuerbescheinigung, manual Anlage KAP required

Tax Reporting Quality section documents the 4-point difference: withholding, Freistellungsauftrag, Jahressteuerbescheinigung, and Vorabpauschale handling.

### finyx/references/brazil/brokers.md

Fee comparison for three main B3 brokers:
- NuInvest: R$0 corretagem via app, mesa de operações 0.5% + R$25.21
- XP Investimentos: zero for some products / varies, broad renda fixa access
- BTG Pactual: R$4.50/order base, regressive tiered, strong fixed income desk

DARF self-reporting note: explicitly documents that no Brazilian broker auto-withholds DARF for renda variavel — all capital gains are investor's responsibility.

### finyx/templates/profile.json

Two changes, all existing fields preserved:
1. `countries.brazil.brokers: []` added — was missing (identified in RESEARCH.md as Pitfall 1)
2. `_holdings_schema` top-level key added — documents the holdings[] structure for each broker object (ticker, isin, shares, cost_basis, asset_class, geography)

---

## Deviations from Plan

None - plan executed exactly as written.

---

## Known Stubs

None. Both reference docs contain complete fee data. Profile schema has empty arrays (intended — populated at runtime by /finyx:profile).

---

## Self-Check: PASSED

- [x] finyx/references/germany/brokers.md exists with last_verified: 2026-04-06
- [x] finyx/references/brazil/brokers.md exists with last_verified: 2026-04-06
- [x] Commit e0702c7 exists
- [x] Commit f15ae66 exists
- [x] profile.json parses as valid JSON
- [x] countries.brazil.brokers is an array
- [x] countries.germany.brokers is an array (preserved)
- [x] _holdings_schema present
- [x] All pre-existing profile.json fields preserved (investor.marginalRate=0, goals.risk_tolerance=null, countries.brazil.ir_regime=null, countries.germany.tax_class=null)
