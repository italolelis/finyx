# Roadmap: Finyx

## Overview

Finyx evolves the IMMO real estate tool into a comprehensive multi-country financial advisor. The build order follows hard dependencies: the shared profile gates every specialist command, tax advisors validate the multi-country agent pattern, investment advisory adds live market data, and pension planning — the most profile-dependent domain — closes the v1 feature set.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation + Profile** - Rename to Finyx, establish shared memory, and build the financial profile that gates all specialist commands
- [x] **Phase 2: Tax Advisors** - German and Brazilian tax advisory covering capital gains, fund taxation, and compliance obligations (completed 2026-04-06)
- [x] **Phase 3: Investment + Broker** - Portfolio analysis, ETF recommendations, live market data, and broker comparison for DE/EU/BR (completed 2026-04-06)
- [x] **Phase 4: Pension Planning** - German (Riester/Rürup/bAV) and Brazilian (PGBL/VGBL/INSS) pension analysis with cross-country projection (completed 2026-04-06)

## Phase Details

### Phase 1: Foundation + Profile
**Goal**: Users can install and run Finyx as a distinct brand, complete a financial profile that captures their full situation including cross-border context, and have that profile available to all specialist commands
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, PROF-01, PROF-02, PROF-03, PROF-04, PROF-05
**Success Criteria** (what must be TRUE):
  1. User installs via `npx finyx-cc` and all existing real estate commands work under the new namespace
  2. User runs `/fin:profile` and completes an interview that captures income, tax class, family status, goals, risk tolerance, and country context (Germany and/or Brazil simultaneously)
  3. System flags cross-border/expat situations and surfaces jurisdiction implications during the interview
  4. Profile is written to `.finyx/profile.json` and all specialist agents can read it as their shared context source
  5. Every advisory output includes a legal disclaimer automatically sourced from the shared disclaimer template
**Plans:** 4 plans (3 executed + 1 gap closure)

Plans:
- [x] 01-01-PLAN.md — Rename project from immo-cc to finyx-cc (directories, files, references, installer)
- [x] 01-02-PLAN.md — Create profile.json schema template and legal disclaimer template
- [x] 01-03-PLAN.md — Build /finyx:profile interview command and wire disclaimer + gating into all commands
- [x] 01-04-PLAN.md — Gap closure: add disclaimer to help.md, fix agent profile path references

### Phase 2: Tax Advisors
**Goal**: Users receive country-appropriate tax guidance — Abgeltungssteuer mechanics and Sparerpauschbetrag tracking for Germany; IR obligations, DARF calculation, and FII exemption rules for Brazil — with all reference docs stamped with tax year metadata
**Depends on**: Phase 1
**Requirements**: DETAX-01, DETAX-02, DETAX-03, DETAX-04, DETAX-05, DETAX-06, BRTAX-01, BRTAX-02, BRTAX-03, BRTAX-04, BRTAX-05, BRTAX-06
**Success Criteria** (what must be TRUE):
  1. German user receives Steuerklasse explanation and recommendation, plus Abgeltungssteuer breakdown (25% + Soli + KiSt) contextualised to their marginal rate with Teilfreistellung rates by fund type
  2. German user can track their Sparerpauschbetrag usage against the €1,000/€2,000 exemption and receives Vorabpauschale calculation for their accumulating ETFs
  3. Brazilian user receives IR filing guidance for their investment types and a DARF calculation with monthly deadline reminder
  4. Brazilian user receives come-cotas explanation with liquidity timing and FII dividend exemption rules reflecting Law 15,270/2025
  5. All tax reference docs expose `tax_year` metadata and the system warns when a doc year does not match the current year
**Plans:** 3/3 plans complete

Plans:
- [x] 02-01-PLAN.md — German investment tax reference doc + profile schema extension (brokers[])
- [x] 02-02-PLAN.md — Brazilian investment tax reference doc
- [x] 02-03-PLAN.md — /finyx:tax command + help.md registration

### Phase 3: Investment + Broker
**Goal**: Users can analyse their portfolio allocation, receive ETF recommendations matched to their risk profile, query live market data for specific assets, and get a profile-based broker recommendation across German, EU, and Brazilian brokers
**Depends on**: Phase 2
**Requirements**: INVEST-01, INVEST-02, INVEST-03, INVEST-04, INVEST-05, BROKER-01, BROKER-02, BROKER-03, BROKER-04
**Success Criteria** (what must be TRUE):
  1. User can view their portfolio broken down by geography, sector, and asset class, and receive rebalancing suggestions when allocation drifts from target
  2. User completes a risk profile assessment and receives ETF recommendations matched to their stated goals
  3. User can query live price and basic metrics for a specific stock or ETF via Finnhub (EU/US) or brapi.dev (B3/FIIs)
  4. User receives fee comparison for relevant German and Brazilian brokers and a profile-based recommendation that notes tax reporting quality differences (e.g., Anlage KAP auto-generation vs manual calculation)
**Plans:** 3/3 plans complete

Plans:
- [x] 03-01-PLAN.md — Broker reference docs (DE + BR) and profile.json holdings[] extension
- [x] 03-02-PLAN.md — /finyx:invest command (portfolio analysis, risk profiling, ETF recs, rebalancing, market data)
- [x] 03-03-PLAN.md — /finyx:broker command + help.md registration

### Phase 4: Pension Planning
**Goal**: Users receive a Germany/Brazil pension comparison grounded in their employment status, income, tax bracket, and family situation, culminating in a combined cross-country retirement projection
**Depends on**: Phase 3
**Requirements**: PENSION-01, PENSION-02, PENSION-03, PENSION-04, PENSION-05, PENSION-06
**Success Criteria** (what must be TRUE):
  1. German user receives a Riester vs Rürup vs bAV comparison with a Zulagen calculation (Grundzulage + Kinderzulage) and a Rürup Sonderausgabenabzug estimate based on their income and marginal rate
  2. Brazilian user receives a PGBL vs VGBL decision guide based on their IR regime and 12% income threshold, plus a progressive vs regressive regime comparison with time horizon examples
  3. User with obligations in both countries receives a combined cross-country pension projection merging German statutory + private + Brazilian INSS
**Plans:** 2/2 plans complete

Plans:
- [x] 04-01-PLAN.md — DE + BR pension reference docs and profile.json pension block extension
- [x] 04-02-PLAN.md — /finyx:pension command + help.md registration

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation + Profile | 4/4 | Complete |  |
| 2. Tax Advisors | 3/3 | Complete   | 2026-04-06 |
| 3. Investment + Broker | 3/3 | Complete   | 2026-04-06 |
| 4. Pension Planning | 2/2 | Complete   | 2026-04-06 |
