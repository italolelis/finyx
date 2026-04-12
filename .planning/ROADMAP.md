# Roadmap: Finyx

## Milestones

- ✅ **v1.0 MVP** - Phases 1-5 (shipped 2026-04-06)
- ✅ **v1.1 Financial Insights Dashboard** - Phases 6-8 (shipped 2026-04-06)
- ✅ **v1.2 Health Insurance Advisor** - Phases 9-12 (shipped 2026-04-09)
- ✅ **v2.0 Plugin Architecture** - Phases 13-17 (shipped 2026-04-12)
- 🚧 **v2.1 Comprehensive Insurance Advisor** - Phases 18-22 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) - SHIPPED 2026-04-06</summary>

Phases 1-5 delivered the MVP: financial profile, German + Brazilian tax advisor, investment advisor, broker comparison, pension planning.

</details>

<details>
<summary>✅ v1.1 Financial Insights Dashboard (Phases 6-8) - SHIPPED 2026-04-06</summary>

Phases 6-8 delivered the unified financial health report with allocation analysis, tax efficiency scoring, and goal pace tracking.

</details>

<details>
<summary>✅ v1.2 Health Insurance Advisor (Phases 9-12) - SHIPPED 2026-04-09</summary>

Phases 9-12 delivered PKV vs GKV decision advisor with health questionnaire, cost projections, family impact analysis, and insights integration.

</details>

<details>
<summary>✅ v2.0 Plugin Architecture (Phases 13-17) - SHIPPED 2026-04-12</summary>

Phases 13-17 delivered full plugin architecture migration: 8 self-contained skills, per-skill agents and reference docs, plugin distribution via `claude plugin add github:italolelis/finyx`.

</details>

### 🚧 v2.1 Comprehensive Insurance Advisor (In Progress)

**Milestone Goal:** Expand insurance skill to cover all major German insurance types with portfolio analysis, gap detection, market comparison, and PDF policy parsing.

## Phase Details

### Phase 18: Router + Sub-skill Migration
**Goal**: Insurance skill dispatches to per-type sub-skills via a router
**Depends on**: Phase 17 (v2.0 plugin architecture)
**Requirements**: ARCH-01
**Success Criteria** (what must be TRUE):
  1. `/finyx:insurance` routes to health sub-skill when user asks about health insurance
  2. Router SKILL.md dispatches to sub-skill prompts based on insurance type keyword
  3. Existing health insurance flow works identically after migration to sub-skill
**Plans**: 1 plan
Plans:
- [x] 18-01-PLAN.md — Router + health sub-skill extraction

### Phase 19: Reference Docs + Profile Schema + Agents
**Goal**: All supporting infrastructure (knowledge docs, data schema, specialist agents) is in place for per-type advisory
**Depends on**: Phase 18
**Requirements**: ARCH-02, ARCH-03, ARCH-04, ARCH-05, INFRA-01, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. 11 per-type reference docs exist under `references/germany/` each with coverage benchmarks, legal minimums, and field extraction schema
  2. Profile schema `insurance.policies[]` array accepts type, provider, premium, coverage, and doc_path fields
  3. Generic research agent can be parameterized with any insurance type and returns criteria-based comparison (never specific tariff names)
  4. Portfolio agent and document reader agent are defined and callable from orchestrating skills
  5. All advisory outputs include §34d GewO advisory-only disclaimer and use criteria-based language
**Plans**: 3 plans
Plans:
- [x] 19-01-PLAN.md — Infrastructure contracts (disclaimer, profile schema, SKILL.md keyword map, health-insurance.md update)
- [x] 19-02-PLAN.md — 10 per-type reference docs (coverage benchmarks, legal minimums, field extraction schemas)
- [x] 19-03-PLAN.md — 3 specialist agents (generic research, portfolio, document reader)

### Phase 20: Portfolio Analysis
**Goal**: Users can see their full insurance portfolio with cost summary, gaps, overlaps, and adequacy assessment
**Depends on**: Phase 19
**Requirements**: PORT-01, PORT-02, PORT-03, PORT-04, OPT-04
**Success Criteria** (what must be TRUE):
  1. User sees all entered policies in a tier-classified overview with total monthly cost
  2. User sees which mandatory/essential insurance types are missing given their life situation
  3. User sees any duplicate coverage detected across policies (e.g., Fahrrad covered by both Hausrat and standalone)
  4. User sees per-type adequacy assessment against benchmarks (e.g., Hausrat sum below €650/m² threshold flagged)
  5. Insurance total cost appears in `/finyx:insights` financial health report allocation section
**Plans**: 2 plans
Plans:
- [x] 20-01-PLAN.md — Portfolio sub-skill + router wiring
- [x] 20-02-PLAN.md — Insights insurance integration (policies[] schema)

### Phase 21: Per-Type Sub-skills (Tier 1-2)
**Goal**: Users can get detailed analysis and market comparison for the six high-priority insurance types
**Depends on**: Phase 19
**Requirements**: TYPE-01, TYPE-02, TYPE-03, TYPE-04, TYPE-05, TYPE-06, OPT-01, OPT-03
**Success Criteria** (what must be TRUE):
  1. User can request analysis for Privathaftpflicht, Hausrat, Kfz, Rechtsschutz, Zahnzusatz, and Risikoleben individually
  2. Each sub-skill shows current coverage vs benchmark and criteria-based market comparison (Stiftung Warentest/Finanztip sourced)
  3. Kfz analysis covers all three coverage levels (Haftpflicht, Teilkasko, Vollkasko) including SF-Klasse impact
  4. User sees cancellation deadlines (Kündigungsfrist) and any open Sonderkündigungsrecht windows for each policy
**Plans**: 3 plans
Plans:
- [x] 21-01-PLAN.md — Haftpflicht, Hausrat, Rechtsschutz sub-skills (sum-based + module-based types)
- [x] 21-02-PLAN.md — Zahnzusatz, Risikoleben sub-skills (Staffelung + income-based benchmark types)
- [x] 21-03-PLAN.md — Kfz sub-skill (3-tier comparison, SF-Klasse, extended vehicle questions)
**UI hint**: no

### Phase 22: Per-Type Sub-skills (Tier 3-4) + Doc Reader
**Goal**: Users can get analysis for situational/niche insurance types and have existing policy PDFs parsed automatically
**Depends on**: Phase 21
**Requirements**: TYPE-07, TYPE-08, TYPE-09, TYPE-10, OPT-02
**Success Criteria** (what must be TRUE):
  1. User can request analysis for Reiseversicherung, Fahrradversicherung, Kfz-Schutzbrief, and Mietkautionsversicherung
  2. User can point the skill at a PDF policy document and receive extracted provider, coverage, premium, and key terms
  3. Extracted PDF data populates the `insurance.policies[]` profile schema fields for use in portfolio analysis
**Plans**: 3 plans
Plans:
- [x] 22-01-PLAN.md — Reise + Fahrrad sub-skills + profile schema documents.locations extension
- [x] 22-02-PLAN.md — Kfz-Schutzbrief + Mietkaution sub-skills (overlap detection + computed benchmark)
- [ ] 22-03-PLAN.md — Doc-reader sub-skill + router keyword update

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-5. MVP | v1.0 | 13/13 | Complete | 2026-04-06 |
| 6-8. Insights | v1.1 | 5/5 | Complete | 2026-04-06 |
| 9-12. Health Insurance | v1.2 | 5/5 | Complete | 2026-04-09 |
| 13-17. Plugin Architecture | v2.0 | 13/13 | Complete | 2026-04-12 |
| 18. Router + Sub-skill Migration | v2.1 | 1/1 | Complete    | 2026-04-12 |
| 19. Reference Docs + Profile Schema + Agents | v2.1 | 3/3 | Complete    | 2026-04-12 |
| 20. Portfolio Analysis | v2.1 | 2/2 | Complete    | 2026-04-12 |
| 21. Per-Type Sub-skills (Tier 1-2) | v2.1 | 3/3 | Complete    | 2026-04-12 |
| 22. Per-Type Sub-skills (Tier 3-4) + Doc Reader | v2.1 | 2/3 | In Progress|  |
