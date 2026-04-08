# Roadmap: Finyx

## Milestones

- ✅ **v1.0 MVP** - Phases 1-5 (shipped 2026-04-06)
- ✅ **v1.1 Financial Insights Dashboard** - Phases 6-8 (shipped 2026-04-06)
- 🚧 **v1.2 Health Insurance Advisor** - Phases 9-12 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) - SHIPPED 2026-04-06</summary>

Phase 1: Rebrand & Foundation, Phase 2: User Financial Profile, Phase 3: Tax Advisory, Phase 4: Investment Advisor + Broker, Phase 5: Pension Planning. 37/37 requirements satisfied.

</details>

<details>
<summary>✅ v1.1 Financial Insights Dashboard (Phases 6-8) - SHIPPED 2026-04-06</summary>

Phase 6: Benchmarks & Scoring Reference Docs, Phase 7: Insight Specialist Agents, Phase 8: /fin:insights Command. All requirements satisfied.

</details>

### 🚧 v1.2 Health Insurance Advisor (In Progress)

**Milestone Goal:** Users can run `/finyx:insurance` to get a personalized PKV vs GKV comparison with cost projections, tax impact, family analysis, and expat guidance — integrated into the full financial picture.

## Phase Details

### Phase 9: Reference Foundation
**Goal**: The authoritative health insurance knowledge document exists with 2026 statutory constants, formulas, and four calculation paths
**Depends on**: Phase 8 (v1.1 complete)
**Requirements**: INFRA-02
**Success Criteria** (what must be TRUE):
  1. `germany/health-insurance.md` exists with 2026 constants (JAEG €77,400, BBG €62,100, base rate 14.6%, PV rates, employer caps)
  2. Document defines the four calculation paths: single employee, family employee, self-employed, Beamter redirect
  3. Document includes GKV cost formula, PKV risk-tier estimation approach, and long-term projection methodology
  4. Staleness detection metadata (tax_year, valid_until) present per project convention
**Plans:** 1 plan

Plans:
- [x] 09-01-PLAN.md — Create health-insurance.md reference document with all 2026 constants and formulas

### Phase 10: Specialist Agents
**Goal**: Two specialist agents exist — a deterministic calculation agent and a live-research agent — ready to be orchestrated by the insurance command
**Depends on**: Phase 9
**Requirements**: COST-01, COST-02, COST-03, ADV-01, ADV-02, ADV-03, INFRA-01
**Success Criteria** (what must be TRUE):
  1. `finyx-insurance-calc-agent.md` computes exact GKV monthly cost (base rate + Zusatzbeitrag + Pflegeversicherung with employer share deducted)
  2. Calc agent computes PKV estimate from age and health risk tier, including family per-person vs Familienversicherung comparison
  3. Calc agent produces 10/20/30-year projection with conservative/base/optimistic scenarios for PKV vs GKV
  4. Calc agent nets PKV cost against §10 EStG tax deduction using marginal rate from profile
  5. `finyx-insurance-research-agent.md` runs WebSearch for live PKV tariffs, Beitragsrückerstattung, and Selbstbeteiligung options
  6. Health questionnaire input is binary flags only, never persisted, GDPR Art. 9 compliant
**Plans:** 2/2 plans complete
**UI hint**: no

Plans:
- [x] 10-01-PLAN.md — Create deterministic insurance calc agent (GKV/PKV cost, family, projections, tax netting)
- [x] 10-02-PLAN.md — Create live PKV research agent (provider search, tariff comparison)

### Phase 11: Command + Integration
**Goal**: `/finyx:insurance` exists as a working end-to-end command — eligibility gate, health questionnaire, cost comparison, projections, expat guidance, age-55 warning, and legal disclaimers all wired
**Depends on**: Phase 10
**Requirements**: ELIG-01, EDGE-01, EDGE-02, INFRA-03, INFRA-04
**Success Criteria** (what must be TRUE):
  1. User running `/finyx:insurance` sees an eligibility check against Versicherungspflichtgrenze (JAEG threshold) before any cost analysis
  2. User sees prominent age-55 lock-in warning (§6 Abs. 3a SGB V) whenever PKV is a viable option
  3. User sees expat considerations (Anwartschaft, EU portability, non-EU gaps) when expat flag is set in profile
  4. All output includes legal disclaimer and recommendation to consult a Versicherungsberater
**Plans**: TBD

### Phase 12: Cross-Advisor Integration
**Goal**: Insurance costs flow into `/finyx:insights` and `/finyx:tax` so the full financial picture reflects health insurance decisions
**Depends on**: Phase 11
**Requirements**: EDGE-03
**Success Criteria** (what must be TRUE):
  1. `.finyx/profile.json` schema extended with an insurance section (type, monthly cost, employer share)
  2. `/finyx:insights` picks up insurance costs in net worth and allocation analysis when insurance section is populated
  3. `/finyx:tax` reflects PKV Basisabsicherung deduction when insurance type is PKV
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 9. Reference Foundation | v1.2 | 0/1 | Planning | - |
| 10. Specialist Agents | v1.2 | 2/2 | Complete   | 2026-04-08 |
| 11. Command + Integration | v1.2 | 0/TBD | Not started | - |
| 12. Cross-Advisor Integration | v1.2 | 0/TBD | Not started | - |
