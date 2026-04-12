# Finyx

## What This Is

Finyx is an open-source personal finance advisor built as a collection of Claude Code slash-commands and specialist AI agents. It covers tax optimization (Germany + Brazil), investment portfolio management with live market data, broker comparison, pension planning (Riester/Rürup/bAV + PGBL/VGBL/INSS), real estate investment analysis, and a unified financial insights dashboard. Users interact through `/fin:*` commands while specialist agents handle domain-specific analysis backed by a shared financial profile.

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

- ✓ `/fin:insights` command — unified financial health report from profile + advisor data — v1.1
- ✓ Income allocation analysis (needs/wants/savings/investments/debt vs country-adjusted benchmarks) — v1.1
- ✓ Tax efficiency scoring (Sparerpauschbetrag, Vorabpauschale, DARF, PGBL per country with € gaps) — v1.1
- ✓ Net worth snapshot (assets vs liabilities from profile data) — v1.1
- ✓ Goal pace tracking ("at current rate, target X reached in Y months") — v1.1
- ✓ Top-5 actionable recommendations ranked by € annual impact — v1.1
- ✓ Cross-advisor intelligence (pension ↔ tax ↔ investment links) — v1.1
- ✓ Country-aware benchmarks and traffic-light scoring reference docs — v1.1
- ✓ Data completeness gate before insights analysis — v1.1
- ✓ Emergency fund check (6-month threshold for cross-border users) — v1.1

- ✓ `/finyx:insurance` command — PKV vs GKV decision advisor with personalized cost projections — v1.2
- ✓ Health questionnaire (25 binary flags, session-only, GDPR Art. 9) for PKV risk surcharges — v1.2
- ✓ Accurate GKV vs PKV cost comparison (income-based vs age/health-based, employer share) — v1.2
- ✓ Family impact analysis (Familienversicherung vs PKV per-person costs) — v1.2
- ✓ Tax implications (PKV Basisabsicherung §10 EStG deduction, employer contribution limits) — v1.2
- ✓ PKV provider research agent with WebSearch for tariffs, Beitragsrückerstattung, Selbstbeteiligung — v1.2
- ✓ Expat considerations (Anwartschaft, Versicherungspflichtgrenze, EU portability) — v1.2
- ✓ Long-term cost projection (10/20/30-year scenarios, PKV age growth vs GKV income-tracking) — v1.2
- ✓ Cross-advisor insurance integration — insights allocation + tax PKV deduction — v1.2

- ✓ `.claude-plugin/plugin.json` manifest for plugin distribution — v2.0
- ✓ All 17 commands converted to 8 self-contained skills under `skills/` — v2.0
- ✓ Each skill bundles its own agents and reference docs — v2.0
- ✓ `finyx-profile` foundation skill with global fallback path — v2.0
- ✓ `finyx-insights` cross-skill integration layer — v2.0
- ✓ Legacy directories removed (commands/, agents/, finyx/) — v2.0
- ✓ Plugin installable via `claude plugin add github:italolelis/finyx` — v2.0
- ✓ All advisory skills have `disable-model-invocation: true` — v2.0

### Active

(Next milestone — define via `/gsd:new-milestone`)

### Out of Scope

- Full insurance marketplace comparison (check24-style across all insurance types) — PKV/GKV decision covered in v1.2, broader comparison deferred
- Automated trading/execution — legal liability, advisory only
- Tax return filing automation — too risky, advisor guides but user files
- Real-time portfolio sync with brokers — API complexity, defer to v2
- Mobile or web app — CLI-first, other interfaces later
- Countries beyond Germany and Brazil — expand after v1 validates multi-country pattern
- Financial product affiliate links — destroys advisory trust
- Budget tracking / expense categorization — different product, dilutes focus

## Context

Shipped v2.0 — full plugin architecture migration. 8 self-contained skills, ~7,000 lines of skill content.
Tech stack: Claude Code plugin system (skills + agents in Markdown prompts), zero runtime dependencies.
8 skills: profile, tax, invest (+ broker), pension, insurance, insights, realestate (7 workflows), help (+ status + update).
8 agents scoped to owning skills. All paths use portable `${CLAUDE_SKILL_DIR}/references/`.
Country support: Germany + Brazil with shared profile and per-country reference docs.
Distributed as Claude Code plugin via `claude plugin add github:italolelis/finyx`.

## Constraints

- **Tech stack**: Claude Code slash-command architecture — no application framework, all logic in Markdown prompts
- **Runtime**: Claude Code plugin system, zero runtime dependencies
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
| Insurance deferred to v2 | Data sourcing complexity, focus v1 on tax + investments | ✓ Shipped in v1.2 |
| Shared user profile | All agents read same `.finyx/profile.json` — integrated advice | ✓ Good |
| Hard cut rename (no coexistence) | Clean migration, simpler codebase | ✓ Good |
| Unconditional country doc loading | Minimal overhead, simplifies command gating logic | ✓ Good |
| VWCE as primary core ETF recommendation | Broadest diversification in single fund | ✓ Good |
| Net-after-mandatory income as benchmark denominator | Gross-based 50/30/20 is wrong for DE (~45% mandatory deductions) | ✓ Good |
| Traffic light + € gap display | Combines at-a-glance scan with actionable specifics | ✓ Good |
| Per-country scoring only (never combined) | Cross-jurisdiction combined scores are misleading | ✓ Good |
| Claude inference for cross-advisor links | Fits Markdown-prompt architecture, zero maintenance vs rule engine | ✓ Good |
| Profile-only data sourcing for insights | Agents read profile.json, never invoke other commands | ✓ Good |
| Health data session-only (GDPR Art. 9) | Health flags never persisted, only in Task prompt | ✓ Good |
| Two insurance agents (calc + research) | Deterministic calc separated from live web research | ✓ Good |
| 3-tier PKV risk model with binary flags | Balances accuracy with GDPR compliance and advisory scope | ✓ Good |
| Neutral source priority over Check24 | Avoids commercial bias in provider research | ✓ Good |

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
*Last updated: 2026-04-12 after v2.0 milestone*
