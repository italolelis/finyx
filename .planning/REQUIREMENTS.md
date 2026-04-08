# Requirements: Finyx v1.2

**Defined:** 2026-04-08
**Core Value:** A single AI-powered financial advisor that knows your full financial picture and gives integrated, country-aware advice

## v1.2 Requirements

Requirements for the Health Insurance Advisor milestone. Each maps to roadmap phases.

### Eligibility & Cost Comparison

- [ ] **ELIG-01**: User can see eligibility check based on Versicherungspflichtgrenze (income vs JAEG threshold)
- [ ] **COST-01**: User can see exact GKV monthly cost (base rate + Zusatzbeitrag + Pflegeversicherung, employer share deducted)
- [ ] **COST-02**: User can see PKV cost estimate based on age and health risk tier from questionnaire
- [ ] **COST-03**: User can see family impact comparison (GKV Familienversicherung vs PKV per-person costs for partner + children)

### Advanced Analysis

- [ ] **ADV-01**: User can see 10/20/30-year cost projection with conservative/base/optimistic scenarios for PKV vs GKV
- [ ] **ADV-02**: User can see PKV provider research with current tariffs, Beitragsrückerstattung, and Selbstbeteiligung options
- [ ] **ADV-03**: User can see net PKV cost after tax deduction (Basisabsicherung §10 EStG, marginal rate from profile)

### Edge Cases & Integration

- [ ] **EDGE-01**: User can see expat considerations (Anwartschaft, EU portability, non-EU gaps)
- [ ] **EDGE-02**: User sees prominent age-55 lock-in warning (§6 Abs. 3a SGB V)
- [ ] **EDGE-03**: Insurance costs feed into `/finyx:insights` and `/finyx:tax` via profile schema extension

### Infrastructure

- [ ] **INFRA-01**: Health questionnaire collects binary health flags, session-only (never persisted), GDPR Art. 9 compliant
- [ ] **INFRA-02**: Reference doc `germany/health-insurance.md` exists with 2026 constants and staleness detection
- [ ] **INFRA-03**: All output includes legal disclaimer + recommendation to consult a Versicherungsberater
- [ ] **INFRA-04**: `/finyx:insurance` command exists with all features wired

## v1.3 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Beamte

- **BEAM-01**: Beamter/Beihilfe redirect with separate cost model (50-80% state subsidy)

### Brazil

- **BR-01**: Brazil plano de saúde / SUS advisory (structurally different system)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Binding quote generation | Advisory only — user must get real quotes from providers |
| Storing health diagnoses | GDPR Art. 9 — session-only binary flags only |
| Recommending specific "best" provider | Legal liability, tariff-specific, changes annually |
| Full insurance marketplace (check24-style) | Different product — focused on PKV vs GKV decision only |
| Dental/Zusatzversicherung comparison | Separate product category, defer to future |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ELIG-01 | Phase 11 | Pending |
| COST-01 | Phase 10 | Pending |
| COST-02 | Phase 10 | Pending |
| COST-03 | Phase 10 | Pending |
| ADV-01 | Phase 10 | Pending |
| ADV-02 | Phase 10 | Pending |
| ADV-03 | Phase 10 | Pending |
| EDGE-01 | Phase 11 | Pending |
| EDGE-02 | Phase 11 | Pending |
| EDGE-03 | Phase 12 | Pending |
| INFRA-01 | Phase 10 | Pending |
| INFRA-02 | Phase 9 | Pending |
| INFRA-03 | Phase 11 | Pending |
| INFRA-04 | Phase 11 | Pending |

**Coverage:**
- v1.2 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after roadmap creation*
