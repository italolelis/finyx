# Requirements: Finyx

**Defined:** 2026-04-06
**Core Value:** A single AI-powered financial advisor that knows your full financial picture and gives integrated, country-aware advice.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### User Financial Profile

- [x] **PROF-01**: User can complete interactive financial interview covering income, tax class, family status, goals, and risk tolerance
- [x] **PROF-02**: Profile supports Germany and Brazil as country contexts simultaneously
- [x] **PROF-03**: System detects cross-border/expat situations (e.g., living in DE, investing in BR) and flags jurisdiction implications
- [x] **PROF-04**: Profile stored as structured `.finyx/profile.json` accessible by all specialist agents
- [x] **PROF-05**: Legal disclaimer displayed on all advisory outputs

### German Tax Advisor

- [ ] **DETAX-01**: User receives explanation of German tax classes (Steuerklassen I-VI) with recommendation based on their profile
- [ ] **DETAX-02**: User can track Sparerpauschbetrag usage against the 1,000/2,000 EUR exemption
- [ ] **DETAX-03**: User receives Vorabpauschale calculation for their accumulating ETFs using current Basiszins
- [ ] **DETAX-04**: User receives Teilfreistellung rates by fund type (equity 30%, mixed 15%, real estate 60%)
- [ ] **DETAX-05**: User receives Abgeltungssteuer breakdown (25% + Soli + KiSt) contextualized to their marginal rate
- [ ] **DETAX-06**: All German tax reference docs include `tax_year` metadata for staleness detection

### Brazilian Tax Advisor

- [x] **BRTAX-01**: User receives IR filing guidance specific to their investment types (stocks, FIIs, CDB, LCI/LCA, previdencia)
- [x] **BRTAX-02**: User receives DARF calculation for monthly stock/FII gains with deadline reminders
- [x] **BRTAX-03**: User receives come-cotas explanation with timing impact on their fund holdings
- [x] **BRTAX-04**: User receives FII dividend tax exemption rules and declaration requirements
- [x] **BRTAX-05**: Brazilian tax reference docs reflect Law 15,270/2025 changes (effective 2026-01-01)
- [x] **BRTAX-06**: All Brazilian tax reference docs include `tax_year` metadata for staleness detection

### Investment Advisor

- [ ] **INVEST-01**: User can view portfolio allocation breakdown by geography, sector, and asset class
- [ ] **INVEST-02**: User completes risk profile assessment mapped to investment recommendations
- [ ] **INVEST-03**: User receives ETF recommendations based on their goals and risk profile
- [ ] **INVEST-04**: User receives rebalancing suggestions when portfolio drifts from target allocation
- [ ] **INVEST-05**: User can query market data for specific assets (price, basic metrics) via live APIs/web search

### Broker Comparison

- [ ] **BROKER-01**: User receives fee comparison for German brokers (Trade Republic, Scalable, ING, comdirect)
- [ ] **BROKER-02**: User receives fee comparison for Brazilian brokers (XP, NuInvest, BTG)
- [ ] **BROKER-03**: User receives profile-based broker recommendation considering their trading frequency, asset types, and tax complexity
- [ ] **BROKER-04**: User is informed about tax reporting quality differences (e.g., German brokers auto-generate Anlage KAP vs foreign brokers requiring manual calculation)

### Pension Planning

- [ ] **PENSION-01**: User receives Riester vs Rurup vs bAV comparison based on employment status, tax bracket, and family
- [ ] **PENSION-02**: User receives Riester Zulagen calculation (Grundzulage + Kinderzulage) based on their family data
- [ ] **PENSION-03**: User receives Rurup Sonderausgabenabzug estimate based on income and marginal rate
- [ ] **PENSION-04**: User receives PGBL vs VGBL decision guide based on IR regime and 12% income threshold
- [ ] **PENSION-05**: User receives progressive vs regressive IR regime explanation with time horizon examples
- [ ] **PENSION-06**: User receives cross-country pension projection combining DE statutory + private + BR INSS

### Foundation

- [x] **FOUND-01**: Project renamed from immo-cc to finyx across package.json, commands, agents, docs
- [x] **FOUND-02**: Existing real estate capabilities preserved and accessible via `/fin:immo:*` or equivalent namespace
- [x] **FOUND-03**: Shared memory system — global user profile accessible across all specialist agents
- [x] **FOUND-04**: Multi-country reference doc architecture with `finyx/references/germany/` and `finyx/references/brazil/` structure
- [x] **FOUND-05**: Disclaimer template established as cross-cutting concern for all agent outputs

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Tax Differentiators

- **DETAX-D01**: Sparerpauschbetrag optimization across multiple brokers (Freistellungsauftrag distribution)
- **DETAX-D02**: Vorabpauschale pre-calculation for upcoming year (run before Jan 2)
- **BRTAX-D01**: Isenção R$20k/month stock sell planning
- **BRTAX-D02**: Cross-country DE+BR tax interaction guidance
- **BRTAX-D03**: DARF end-to-end monthly workflow (calculate → confirm → remind)

### Investment Differentiators

- **INVEST-D01**: Tax-loss harvesting guidance (Germany)
- **INVEST-D02**: Tax-loss harvesting guidance (Brazil)
- **INVEST-D03**: Real estate + investment portfolio integration analysis

### Insurance

- **INSUR-01**: Insurance coverage analysis and recommendations (check24-style)
- **INSUR-02**: Profile-based insurance gap identification

### Advanced

- **ADV-01**: PFOF ban impact analysis (June 2026)
- **ADV-02**: Broker migration guide (tax and reporting consequences)
- **ADV-03**: Pension gap estimate with projection model

## Out of Scope

| Feature | Reason |
|---------|--------|
| Tax return filing automation | Legal liability — advisory only, guide users to ELSTER/Receita Federal |
| Automated trade execution | Securities law in DE and BR; advisory-only constraint |
| Real-time portfolio sync via broker APIs | OAuth complexity, API instability; user inputs holdings manually |
| Budget tracking / expense categorization | Different product (YNAB, etc.); dilutes focus |
| Push notifications / alerting | Requires backend infrastructure; CLI tool, not a service |
| Countries beyond Germany and Brazil | Architecture supports it, but v1 scope is clear; community can add |
| Financial product affiliate links | Destroys advisory trust |
| Chat history persistence | Claude Code handles context natively |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROF-01 | Phase 1 | Complete |
| PROF-02 | Phase 1 | Complete |
| PROF-03 | Phase 1 | Complete |
| PROF-04 | Phase 1 | Complete |
| PROF-05 | Phase 1 | Complete |
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Complete |
| FOUND-04 | Phase 1 | Complete |
| FOUND-05 | Phase 1 | Complete |
| DETAX-01 | Phase 2 | Pending |
| DETAX-02 | Phase 2 | Pending |
| DETAX-03 | Phase 2 | Pending |
| DETAX-04 | Phase 2 | Pending |
| DETAX-05 | Phase 2 | Pending |
| DETAX-06 | Phase 2 | Pending |
| BRTAX-01 | Phase 2 | Complete |
| BRTAX-02 | Phase 2 | Complete |
| BRTAX-03 | Phase 2 | Complete |
| BRTAX-04 | Phase 2 | Complete |
| BRTAX-05 | Phase 2 | Complete |
| BRTAX-06 | Phase 2 | Complete |
| INVEST-01 | Phase 3 | Pending |
| INVEST-02 | Phase 3 | Pending |
| INVEST-03 | Phase 3 | Pending |
| INVEST-04 | Phase 3 | Pending |
| INVEST-05 | Phase 3 | Pending |
| BROKER-01 | Phase 3 | Pending |
| BROKER-02 | Phase 3 | Pending |
| BROKER-03 | Phase 3 | Pending |
| BROKER-04 | Phase 3 | Pending |
| PENSION-01 | Phase 4 | Pending |
| PENSION-02 | Phase 4 | Pending |
| PENSION-03 | Phase 4 | Pending |
| PENSION-04 | Phase 4 | Pending |
| PENSION-05 | Phase 4 | Pending |
| PENSION-06 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 37 total
- Mapped to phases: 37
- Unmapped: 0

---
*Requirements defined: 2026-04-06*
*Last updated: 2026-04-06 after roadmap creation*
