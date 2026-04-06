# Milestones

## v1.1 Financial Insights Dashboard (Shipped: 2026-04-06)

**Phases completed:** 3 phases, 5 plans, 7 tasks

**Key accomplishments:**

- Country-aware allocation benchmarks (DE/BR net-after-mandatory) and traffic-light scoring rules for 8 dimensions with gap formulas and Phase 7 agent output format
- Stateless allocation analyst agent with net-income computation, 50/30/20 benchmark comparison, emergency fund check, and D-07 first-run categorization flow using profile.json fields
- Magenta-colored tax efficiency agent scoring Sparerpauschbetrag (TAX-01), Vorabpauschale readiness (TAX-03), and PGBL optimization (TAX-04) per country with EUR/BRL gap amounts, wrapped in `<tax_score_result>` XML tags
- Projection specialist agent with net worth snapshot from cost-basis portfolio fields and conservative/base goal pace tracking in months, wrapped in `<projection_result>` XML tags
- `/fin:insights` orchestrator command wiring 3 parallel specialist agents into a unified financial health report with completeness gating, cross-advisor intelligence, and EUR-ranked recommendations

---

## v1.0 MVP (Shipped: 2026-04-06)

**Phases completed:** 5 phases, 13 plans
**Timeline:** 65 days (2026-02-01 → 2026-04-06)
**Files:** 102 changed, +19,639 / -761 lines

**Key accomplishments:**

- Rebranded immo-cc → finyx-cc with full namespace migration (commands, agents, installer, references)
- Built interactive financial profile with cross-border detection (DE/BR), shared context for all agents
- German + Brazilian tax advisory (`/finyx:tax`) — Abgeltungssteuer, Sparerpauschbetrag, IR/DARF, come-cotas
- Investment advisor (`/finyx:invest`) — portfolio analysis, risk profiling, ETF recs, live market data (Finnhub/brapi)
- Broker comparison (`/finyx:broker`) for DE + BR markets with tax-reporting quality differentiation
- Pension planning (`/finyx:pension`) — Riester/Rürup/bAV (DE), PGBL/VGBL/INSS (BR), cross-country projection

**Audit:** 37/37 requirements satisfied, 5/5 phases passed, 30/30 integration checks, 4/4 E2E flows

---
