# Finyx

## What This Is

Finyx is an open-source personal finance advisor built as a collection of Claude Code slash-commands and specialist AI agents. It covers tax optimization (Germany + Brazil), investment portfolio management with live market data, broker comparison, pension planning (Riester/Rürup/bAV + PGBL/VGBL/INSS), and real estate investment analysis. Users interact through `/fin:*` commands while specialist agents handle domain-specific analysis backed by a shared financial profile.

## Core Value

A single AI-powered financial advisor that knows your full financial picture — tax situation, investments, insurance, pensions, and real estate — and gives integrated, country-aware advice rather than siloed recommendations.

## Requirements

### Validated

- ✓ Real estate investment analysis pipeline (scout, analyze, filter, compare, stress-test, report) — existing
- ✓ German tax rules for real estate (AfA, Grunderwerbsteuer, marginal rate calculations) — existing
- ✓ Investor profile with interactive questionnaire — existing
- ✓ Location research with transport/Erbpacht assessment — existing
- ✓ Multi-format report generation (Markdown, PDF, short/full) — existing
- ✓ npm distribution via `npx finyx-cc` with global/local install — v1.0
- ✓ User financial profile — structured interview (income, tax class, family, goals, risk, DE/BR) — v1.0
- ✓ German tax advisor — Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung — v1.0
- ✓ Brazilian tax advisor — IR filing, DARF calculation, come-cotas, FII exemptions — v1.0
- ✓ Investment advisor — portfolio analysis, risk profiling, ETF recommendations, rebalancing, market data — v1.0
- ✓ Broker comparison — DE + BR brokers with fee comparison and tax-reporting quality — v1.0
- ✓ Pension planning — Riester/Rürup/bAV (DE), PGBL/VGBL/INSS (BR), cross-country projection — v1.0
- ✓ Shared memory system — `.finyx/profile.json` accessible by all specialist agents — v1.0
- ✓ Multi-country reference doc architecture (germany/ + brazil/) — v1.0
- ✓ Legal disclaimer on all advisory outputs — v1.0
- ✓ Cross-border/expat detection with jurisdiction flags — v1.0
- ✓ Tax year metadata on all reference docs with staleness detection — v1.0

### Active

#### v1.1 — Financial Insights Dashboard
- [ ] `/fin:insights` command — unified financial health report from existing profile + advisor data
- [ ] Income allocation analysis (needs/wants/savings/investments/debt breakdown with benchmarks)
- [ ] Tax efficiency scoring (unused allowances, optimization gaps across DE + BR)
- [ ] Net worth snapshot with forward projection based on current savings/investment rate
- [ ] Goal pace tracking ("at current rate, target X reached in Y months")
- [ ] Top-N actionable recommendations ranked by financial impact
- [ ] Cross-advisor intelligence (pension gap affects tax, investment allocation affects risk)

### Out of Scope

- Insurance comparison (check24-style) — deferred to v2, high complexity and data sourcing challenges
- Automated trading/execution — legal liability, advisory only
- Tax return filing automation — too risky, advisor guides but user files
- Real-time portfolio sync with brokers — API complexity, defer to v2
- Mobile or web app — CLI-first, other interfaces later
- Countries beyond Germany and Brazil — expand after v1 validates multi-country pattern
- Financial product affiliate links — destroys advisory trust
- Budget tracking / expense categorization — different product, dilutes focus

## Current Milestone: v1.1 Financial Insights Dashboard

**Goal:** Generate actionable financial insights and recommendations by cross-referencing all existing advisor outputs and profile data.

**Target features:**
- `/fin:insights` command — unified financial health report
- Income allocation analysis with benchmarks
- Tax efficiency scoring across DE + BR
- Net worth snapshot with forward projection
- Goal pace tracking
- Ranked actionable recommendations
- Cross-advisor intelligence

## Context

Shipped v1.0 with ~19,600 LOC across 102 files. v1.1 Phase 8 complete — `/fin:insights` orchestrator command created, all 3 phases shipped.
Tech stack: Claude Code slash-commands (Markdown prompts), Node.js installer, zero runtime dependencies.
5 specialist commands: `/finyx:profile`, `/finyx:tax`, `/finyx:invest`, `/finyx:broker`, `/finyx:pension`.
3 legacy real estate agents preserved under finyx namespace.
Country support: Germany + Brazil with shared profile and per-country reference docs.
Distributed via npm as `finyx-cc`.

## Constraints

- **Tech stack**: Claude Code slash-command architecture — no application framework, all logic in Markdown prompts
- **Runtime**: Node.js >=16.7.0, npm distribution, zero runtime dependencies
- **Legal**: Advisory only — all recommendations include disclaimers, no automated execution
- **Data freshness**: Market data via live web search + APIs, tax rules in versioned reference docs updated per tax year
- **Country scope**: Germany + Brazil for v1, architecture must support adding countries without refactoring

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rename to Finyx | Broader scope beyond real estate needs a new brand | ✓ Good |
| Germany + Brazil v1 | User has direct experience in both markets | ✓ Good |
| CLI skills architecture | Proven pattern from IMMO, low friction, extensible | ✓ Good |
| Advisory only, no execution | Legal risk of automated trading/filing too high for open source | ✓ Good |
| APIs + web search for data | Finnhub (EU/US), brapi.dev (B3), Bundesbank SDMX (Basiszins) | ✓ Good |
| Insurance deferred to v2 | Data sourcing complexity, focus v1 on tax + investments | ✓ Good |
| Shared user profile | All agents read same `.finyx/profile.json` — integrated advice | ✓ Good |
| Hard cut rename (no coexistence) | Clean migration, simpler codebase | ✓ Good |
| Unconditional country doc loading | Minimal overhead, simplifies command gating logic | ✓ Good |
| VWCE as primary core ETF recommendation | Broadest diversification in single fund | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? Move to Out of Scope with reason
2. Requirements validated? Move to Validated with phase reference
3. New requirements emerged? Add to Active
4. Decisions to log? Add to Key Decisions
5. "What This Is" still accurate? Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-07 after Phase 8 completion — v1.1 milestone complete*
