# Roadmap: Finyx

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-04-06) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Financial Insights Dashboard** — Phases 6-8 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) — SHIPPED 2026-04-06</summary>

- [x] Phase 1: Foundation + Profile (4/4 plans)
- [x] Phase 2: Tax Advisors (3/3 plans)
- [x] Phase 3: Investment + Broker (3/3 plans)
- [x] Phase 4: Pension Planning (2/2 plans)
- [x] Phase 5: Profile Schema Sync (1/1 plan)

</details>

### 🚧 v1.1 Financial Insights Dashboard (In Progress)

**Milestone Goal:** Generate actionable financial insights and recommendations by cross-referencing all existing advisor outputs and profile data via `/fin:insights`.

- [x] **Phase 6: Reference Foundation** — Country-aware benchmark and scoring reference docs that unblock all specialist agents (completed 2026-04-06)
- [x] **Phase 7: Specialist Agents** — Three parallel agents computing allocation analysis, tax efficiency scoring, and net worth projections (completed 2026-04-06)
- [x] **Phase 8: Orchestrator Command** — `/fin:insights` wires all agents, enforces completeness gate, synthesizes ranked recommendations with legal disclaimers (completed 2026-04-06)

## Phase Details

### Phase 6: Reference Foundation
**Goal**: Country-aware benchmark and scoring reference docs exist and are usable by specialist agents
**Depends on**: Phase 5
**Requirements**: INFRA-02
**Success Criteria** (what must be TRUE):
  1. `benchmarks.md` exists with income allocation benchmarks adjusted per country (DE net-income basis, BR gross-income basis)
  2. `scoring-rules.md` exists with per-country tax efficiency scoring criteria for DE (Sparerpauschbetrag, Vorabpauschale) and BR (IR/DARF thresholds)
  3. Both docs carry tax-year metadata matching the staleness-detection convention used by existing reference docs
**Plans:** 1/1 plans complete
Plans:
- [x] 06-01-PLAN.md — Country-aware benchmarks and scoring reference docs

### Phase 7: Specialist Agents
**Goal**: Three specialist agents can independently analyze allocation, tax efficiency, and projections from profile data and return structured outputs
**Depends on**: Phase 6
**Requirements**: ALLOC-01, ALLOC-02, TAX-01, TAX-02, TAX-03, PROJ-01, PROJ-02
**Success Criteria** (what must be TRUE):
  1. Allocation agent produces income breakdown (needs/wants/savings/investments/debt) vs country-adjusted benchmarks and flags emergency fund shortfall when savings < 3-6 months of expenses
  2. Tax-scoring agent produces per-country efficiency gaps in € for DE (Sparerpauschbetrag unused amount, Vorabpauschale readiness) and BR (IR optimization gaps), scored separately — never combined
  3. Projection agent produces net worth snapshot (assets vs liabilities) and goal pace indicator ("at current rate, target X reached in Y months")
  4. Each agent reads `.finyx/profile.json` directly and emits a structured output consumable by the orchestrator
**Plans:** 3/3 plans complete
Plans:
- [x] 07-01-PLAN.md — Allocation specialist agent (ALLOC-01, ALLOC-02)
- [x] 07-02-PLAN.md — Tax-scoring specialist agent (TAX-01, TAX-02, TAX-03)
- [x] 07-03-PLAN.md — Projection specialist agent (PROJ-01, PROJ-02)

### Phase 8: Orchestrator Command
**Goal**: `/fin:insights` delivers a unified financial health report with ranked recommendations, cross-advisor intelligence, and legal disclaimers
**Depends on**: Phase 7
**Requirements**: INFRA-01, INFRA-03, REC-01, REC-02
**Success Criteria** (what must be TRUE):
  1. Running `/fin:insights` on an incomplete profile emits a completeness gate report listing missing sections before any analysis runs
  2. Running `/fin:insights` on a complete profile produces a unified report with top-5 recommendations ranked by € annual impact
  3. The report surfaces at least one cross-advisor intelligence link (e.g., pension gap affecting tax allowance, investment allocation affecting risk exposure)
  4. All output includes the legal disclaimer via `disclaimer.md` — no advisory content is emitted without it
  5. `bin/install.js` deploys the new command and agents alongside existing ones
**Plans:** 1/1 plans complete
Plans:
- [x] 08-01-PLAN.md — Create /fin:insights orchestrator command and verify install.js deployment

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation + Profile | v1.0 | 4/4 | Complete | 2026-04-06 |
| 2. Tax Advisors | v1.0 | 3/3 | Complete | 2026-04-06 |
| 3. Investment + Broker | v1.0 | 3/3 | Complete | 2026-04-06 |
| 4. Pension Planning | v1.0 | 2/2 | Complete | 2026-04-06 |
| 5. Profile Schema Sync | v1.0 | 1/1 | Complete | 2026-04-06 |
| 6. Reference Foundation | v1.1 | 1/1 | Complete   | 2026-04-06 |
| 7. Specialist Agents | v1.1 | 3/3 | Complete   | 2026-04-06 |
| 8. Orchestrator Command | v1.1 | 1/1 | Complete   | 2026-04-06 |
