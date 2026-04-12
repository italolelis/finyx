# Requirements: Finyx v2.1

**Defined:** 2026-04-12
**Core Value:** A single AI-powered financial advisor that knows your full financial picture and gives integrated, country-aware advice

## v2.1 Requirements

Requirements for the Comprehensive Insurance Advisor milestone.

### Portfolio Management

- [ ] **PORT-01**: User can see insurance portfolio overview (all policies, total monthly cost, tier classification)
- [ ] **PORT-02**: User can see coverage gap detection (missing mandatory/essential types based on life situation)
- [ ] **PORT-03**: User can see overlap/redundancy detection (duplicate coverage across policies)
- [ ] **PORT-04**: User can see coverage adequacy check per type (benchmarks: Hausrat >=€650/m², Haftpflicht >=€5M, etc.)

### Optimization

- [ ] **OPT-01**: User can see market comparison per insurance type via WebSearch (criteria-based, not product-specific per §34d GewO)
- [ ] **OPT-02**: User can have policy documents parsed from PDFs to extract provider, coverage, premium, terms
- [ ] **OPT-03**: User can see cancellation deadline tracking (Kündigungsfrist + Sonderkündigungsrecht windows)
- [ ] **OPT-04**: Insurance costs feed into `/finyx:insights` financial health report

### Architecture

- [ ] **ARCH-01**: Insurance skill uses router pattern dispatching to per-type sub-skill prompts
- [ ] **ARCH-02**: Generic research agent parameterized by insurance type
- [ ] **ARCH-03**: Portfolio agent for cross-type analysis (gaps, overlaps, total cost)
- [ ] **ARCH-04**: Document reader agent for PDF policy parsing
- [ ] **ARCH-05**: 11 per-type reference docs with coverage benchmarks, legal minimums, and field extraction schemas

### Insurance Types

- [ ] **TYPE-01**: Privathaftpflicht (personal liability)
- [ ] **TYPE-02**: Hausratversicherung (household contents)
- [ ] **TYPE-03**: Kfz-Versicherung (car: Haftpflicht + Teilkasko + Vollkasko)
- [ ] **TYPE-04**: Rechtsschutzversicherung (legal protection)
- [ ] **TYPE-05**: Zahnzusatzversicherung (dental supplement)
- [ ] **TYPE-06**: Risikolebensversicherung (term life)
- [ ] **TYPE-07**: Reiseversicherung (travel)
- [ ] **TYPE-08**: Fahrradversicherung (bicycle)
- [ ] **TYPE-09**: Kfz-Schutzbriefversicherung (roadside assistance)
- [ ] **TYPE-10**: Mietkautionsversicherung (rental deposit)

### Infrastructure

- [ ] **INFRA-01**: Profile schema extended with `insurance.policies[]` array
- [ ] **INFRA-02**: Legal disclaimer includes §34d GewO advisory-only notice
- [ ] **INFRA-03**: All output uses criteria-based recommendations, never specific product recommendations

## v2.2 Requirements

Deferred to future release.

- **BU-01**: Berufsunfähigkeitsversicherung (disability) — high complexity, own milestone
- **BR-01**: Brazil insurance types (plano de saúde, seguro auto, etc.)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automated policy switching | Requires Makler license (§34d GewO) |
| Broker/Makler services | Legal liability — advisory only |
| Storing health data | GDPR Art. 9 — session-only for health flags |
| Specific product recommendations | §34d GewO — recommend criteria, not competing tariffs |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PORT-01 | Phase 20 | Pending |
| PORT-02 | Phase 20 | Pending |
| PORT-03 | Phase 20 | Pending |
| PORT-04 | Phase 20 | Pending |
| OPT-01 | Phase 21 | Pending |
| OPT-02 | Phase 22 | Pending |
| OPT-03 | Phase 21 | Pending |
| OPT-04 | Phase 20 | Pending |
| ARCH-01 | Phase 18 | Pending |
| ARCH-02 | Phase 19 | Pending |
| ARCH-03 | Phase 19 | Pending |
| ARCH-04 | Phase 19 | Pending |
| ARCH-05 | Phase 19 | Pending |
| TYPE-01 | Phase 21 | Pending |
| TYPE-02 | Phase 21 | Pending |
| TYPE-03 | Phase 21 | Pending |
| TYPE-04 | Phase 21 | Pending |
| TYPE-05 | Phase 21 | Pending |
| TYPE-06 | Phase 21 | Pending |
| TYPE-07 | Phase 22 | Pending |
| TYPE-08 | Phase 22 | Pending |
| TYPE-09 | Phase 22 | Pending |
| TYPE-10 | Phase 22 | Pending |
| INFRA-01 | Phase 19 | Pending |
| INFRA-02 | Phase 19 | Pending |
| INFRA-03 | Phase 19 | Pending |

**Coverage:**
- v2.1 requirements: 26 total
- Mapped to phases: 26
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-12*
*Last updated: 2026-04-12 — traceability mapped after roadmap creation*
