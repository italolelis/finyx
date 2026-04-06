---
phase: 03-investment-broker
plan: "03"
subsystem: finyx-commands
tags: [broker-comparison, investment-advisory, help-registration]
dependency_graph:
  requires: [03-01]
  provides: [commands/finyx/broker.md, commands/finyx/help.md]
  affects: [finyx/references/germany/brokers.md, finyx/references/brazil/brokers.md]
tech_stack:
  added: []
  patterns: [profile-gate, staleness-check, decision-matrix, AskUserQuestion]
key_files:
  created:
    - commands/finyx/broker.md
  modified:
    - commands/finyx/help.md
decisions:
  - "No Write tool in broker.md — pure advisory output, no file creation needed"
  - "staleness check threshold set to 180 days (6 months) matching reference doc guidance"
  - "node -e used for cross-platform date arithmetic (avoids GNU vs macOS date flag incompatibility)"
  - "Country routing: each phase gated by active country detection from profile"
metrics:
  duration: "145s"
  completed: "2026-04-06"
  tasks: 2
  files: 2
---

# Phase 03 Plan 03: Broker Command and Help Registration Summary

**One-liner:** `/finyx:broker` with 7-phase broker comparison (DE + BR fees, profile-based recommendation, tax reporting quality) plus help.md updated with both Phase 3 commands.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create /finyx:broker slash command | 3f6831a | commands/finyx/broker.md (created, 320 lines) |
| 2 | Register /finyx:invest and /finyx:broker in help.md | 879b578 | commands/finyx/help.md (modified, +58 lines) |

## What Was Built

### commands/finyx/broker.md

A 7-phase slash command implementing BROKER-01 through BROKER-04:

- **Phase 1 (Validation):** Profile gate via `.finyx/profile.json`; detects Germany active (`tax_class != null`) and Brazil active (`ir_regime != null`)
- **Phase 2 (Staleness Check):** Extracts `last_verified` from both broker reference doc frontmatters; uses `node -e` for cross-platform 180-day date arithmetic; emits warning banner if stale, continues regardless
- **Phase 3 (German Brokers — BROKER-01):** Fee comparison table for Trade Republic, Scalable Capital FREE/PRIME+, ING, comdirect with URLs and key differentiators
- **Phase 4 (Brazilian Brokers — BROKER-02):** Corretagem comparison for NuInvest, XP, BTG Pactual with URLs; notes B3 emolumentos charged separately; DARF self-reporting reminder
- **Phase 5 (Recommendation — BROKER-03):** AskUserQuestion for trading frequency, investment strategy, and tax simplicity preference; separate decision matrices for Germany and Brazil active users; structured output with "choose if" / "avoid if" conditions
- **Phase 6 (Tax Reporting — BROKER-04):** Table comparing German broker (auto-withhold, Freistellungsauftrag, Jahressteuerbescheinigung, auto-Vorabpauschale) vs foreign broker (manual Anlage KAP + KAP-INV); Brazil note that all BR brokers have identical DARF obligations
- **Phase 7 (Disclaimer):** Full disclaimer.md appended via reference

### commands/finyx/help.md

Three additions following the pattern established in Phase 2 (02-03-SUMMARY.md):
1. Workflow diagram extended with INVEST and BROKER nodes below TAX branch
2. Quick start entries for `/finyx:invest` and `/finyx:broker` added after `/finyx:tax`
3. "Investment Advisory" commands table section added with both commands
4. Detail sections for both commands added after the `/finyx:tax` detail section

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| No Write tool in broker.md | Pure advisory output — no files need to be created; mirrors the read-only nature of the broker comparison |
| 180-day staleness threshold | Matches the guidance in broker reference docs ("6 months old" warning); sufficient for broker fee data which changes seasonally |
| `node -e` for date arithmetic | Cross-platform requirement — `date -d` (GNU) vs `date -j` (macOS) incompatibility; `node` is always available in the runtime environment |
| Country-gated phases | Each comparison phase is gated by active country detection; prevents showing irrelevant DE content to Brazil-only users and vice versa |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no hardcoded empty values, placeholder text, or unconnected data sources.

## Self-Check: PASSED

- `commands/finyx/broker.md` exists: confirmed (320 lines, 7 phases)
- `commands/finyx/help.md` updated: confirmed (`finyx:invest` and `finyx:broker` present)
- Commit 3f6831a exists: confirmed
- Commit 879b578 exists: confirmed
