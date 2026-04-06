---
phase: 03-investment-broker
plan: "02"
subsystem: investment-command
tags: [investment, portfolio, etf, risk-profile, rebalancing, market-data, finnhub, brapi]
dependency_graph:
  requires:
    - 03-01 (broker reference docs, profile.json holdings schema extension)
    - finyx/references/disclaimer.md
    - finyx/templates/profile.json
  provides:
    - commands/finyx/invest.md (/finyx:invest slash command)
  affects:
    - User portfolio analysis workflow (INVEST-01 through INVEST-05)
tech_stack:
  added: []
  patterns:
    - Profile gate pattern (identical to finyx:tax)
    - AskUserQuestion interactive holdings collection with Write offer
    - Finnhub REST API via curl + node -e / jq JSON parsing
    - brapi.dev REST API via curl + node -e / jq JSON parsing
    - WebFetch fallback when API keys not set
    - 5pp drift threshold rebalancing (Betterment/Vanguard standard)
    - Risk questionnaire → Conservative/Moderate/Aggressive mapping
key_files:
  created:
    - commands/finyx/invest.md
  modified: []
decisions:
  - AskUserQuestion used for both holdings collection and risk questionnaire — stateless, no sidecar files
  - Cost basis used as value proxy in Phase 3 (live prices require Phase 7 API call)
  - WebFetch added to allowed-tools (not in tax.md) — required for INVEST-05 fallback per D-09
  - VWCE as primary core recommendation across all risk profiles — broadest diversification, single fund simplicity
  - .XETRA suffix documented for European ETFs on Finnhub — critical for symbol resolution (Pitfall 2 from RESEARCH.md)
metrics:
  duration: "5m 9s"
  completed: "2026-04-06T18:04:30Z"
  tasks_completed: 1
  files_created: 1
  files_modified: 0
  lines_written: 718
---

# Phase 3 Plan 02: Investment Command Summary

**One-liner:** `/finyx:invest` command with 8-phase portfolio advisory: allocation breakdown, 5-question risk profiling, ETF recommendations with ISINs, 5pp-threshold rebalancing, and live market data via Finnhub/brapi.dev with WebFetch fallback.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create /finyx:invest slash command | 8aa6dc2 | commands/finyx/invest.md |

## What Was Built

`commands/finyx/invest.md` — a 718-line slash command following the `finyx:tax` structure exactly.

**Phase structure:**
1. **Validation** — profile gate, active country detection (identical to finyx:tax)
2. **Holdings Check** — detects empty holdings, collects via AskUserQuestion, offers Write to profile.json
3. **Portfolio Allocation** — breakdown by asset class, geography, and broker using cost basis as value proxy
4. **Risk Profile Assessment** — 5-question questionnaire maps to Conservative/Moderate/Aggressive with target allocation tables
5. **ETF Recommendations** — canonical ETF list with ISINs and TERs per risk profile; German tax notes (Teilfreistellung, Vorabpauschale); Brazilian ETFs (BOVA11, IVVB11, XFIX11)
6. **Rebalancing Suggestions** — 5pp drift threshold per asset class, contribution-first rebalancing guidance
7. **Market Data Query** — Finnhub for EU/US (with .XETRA suffix for European ETFs), brapi.dev for B3/FIIs, WebFetch fallback when keys unset
8. **Disclaimer** — full disclaimer.md append via execution_context

## ETF Canonical List Embedded

**Global core:** VWCE (IE00BK5BQT80, 0.22%), IWDA (IE00B4L5Y983, 0.20%)
**Bonds:** AGGG (IE00B3F81409, 0.10%), VAGF (IE00BG47KB92, 0.10%)
**Emerging markets:** EIMI (IE00BKM4GZ66, 0.18%)
**Small cap satellite:** WSML (IE00BF4RFH31, 0.35%)
**Brazil (B3):** BOVA11, IVVB11, XFIX11

## Requirements Fulfilled

- INVEST-01: Portfolio allocation by asset class, geography, broker — Phase 3
- INVEST-02: Risk profile assessment with questionnaire and target allocation — Phase 4
- INVEST-03: ETF recommendations with ISINs/TERs matched to risk profile — Phase 5
- INVEST-04: Rebalancing suggestions with 5pp drift threshold — Phase 6
- INVEST-05: Live market data via Finnhub/brapi.dev with WebFetch fallback — Phase 7

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All phases have complete logic. Holdings collection and risk questionnaire both have full AskUserQuestion flows. Market data API calls have complete curl commands with both jq and node -e fallback parsers.

## Self-Check: PASSED

- commands/finyx/invest.md exists: FOUND
- Commit 8aa6dc2 exists: FOUND
- File has 718 lines (min_lines: 300): PASSED
- All 15 acceptance criteria verified via grep: PASSED
