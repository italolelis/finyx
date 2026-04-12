# Feature Landscape: Comprehensive Insurance Advisor (v2.1)

**Domain:** German insurance portfolio management — 11 insurance types
**Researched:** 2026-04-12
**Milestone:** v2.1 — Comprehensive Insurance Advisor
**Confidence:** MEDIUM — Clark/Stiftung Warentest/Finanztip directly verified; competitive feature depth via secondary sources

---

## Insurance Type Groupings by Complexity

### Tier 1 — Mandatory / Universal (everyone needs these)
| Type | Why Mandatory | Advisory Complexity |
|------|--------------|---------------------|
| Krankenversicherung (PKV/GKV) | Legal requirement | HIGH — already built in v1.2, do not rebuild |
| Kfz-Haftpflicht | Legal requirement for any vehicle | LOW — binary: car owner = must have |
| Privathaftpflicht | De facto mandatory (Finanztip: "everyone needs this, no exceptions") | LOW — simple, cheap, ~€5–8/mo, universal |

### Tier 2 — Situational Core (most people need, depends on life situation)
| Type | When Needed | Advisory Complexity |
|------|------------|---------------------|
| Hausrat | Renter or owner with belongings worth protecting | MEDIUM — coverage amount = €650–700/m² living space |
| Risiko-Leben | Family with dependents, or any mortgage | MEDIUM — sum insured rule = annual gross income × remaining working years |
| Rechtsschutz | Employed, renting, or car owner (can't afford €3–15k in legal fees) | MEDIUM — module selection: Privat/Berufs/Verkehr/Miete; bundled vs modular |
| Zahn (ZZV) | GKV user — GKV covers 60% base, ZZV bridges to 80–100% | MEDIUM — wartezeit (3–8 months), Leistungsprozentsatz, Festzuschüsse interaction |

### Tier 3 — Situational Optional (worthwhile in specific conditions)
| Type | When Worthwhile | Advisory Complexity |
|------|----------------|---------------------|
| Kfz-Vollkasko/Teilkasko | Car ≤5 years old or market value >€10–15k | LOW — depreciation rule: Teilkasko at 5–7y, drop Vollkasko at ~€6k value |
| Reiseversicherung (Auslandsreise-KV + Storno) | Travel outside EU; or trips >€1,000 pre-paid costs | LOW — rule-based triggers; PKV users: check if Auslandsschutz already included |
| Fahrradversicherung | Bike value >€800 AND not covered adequately by Hausrat | LOW — check Hausrat bike sublimit first; separate policy only if gap |
| Kfz-Schutzbrief | If Kfz-Vollkasko doesn't include it AND no ADAC membership | LOW — triple overlap check: Vollkasko, ADAC, standalone |

### Tier 4 — Rare / Highly Situational
| Type | When Worthwhile |
|------|----------------|
| Mietkaution (deposit guarantee) | Can't afford 3-month cash deposit, or wants to preserve liquidity for investment |

---

## Table Stakes

Features users expect from any insurance advisor. Missing any = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Portfolio overview — all policies with annual cost total | Users have no single view of what they spend on insurance | Low | Read from extended profile.json insurance section |
| Life situation input collection | Family, housing type, car owner Y/N, bike value — determines which types apply | Low | Short questionnaire (~8 questions) gating further analysis |
| Per-type necessity check | "Do I actually need this?" — Stiftung Warentest tier model | Low | Rule-based lookup: life situation → applicable types |
| Gap detection — missing essential types | Finanztip: missing Haftpflicht is crisis; missing Risiko-Leben with family = existential risk | Low | Diff user's known policies against Tier 1+2 checklist |
| Coverage amount adequacy check | Hausrat: m² formula (€650–700/m²); Haftpflicht: minimum €5M sum insured; Risiko-Leben: income × years | Medium | Per-type formula, not generic |
| Cost benchmark — is current premium reasonable? | Users don't know if €29/mo Haftpflicht is market rate or 3× too high | Medium | WebSearch for Stiftung Warentest test results + typical ranges per type |
| Provider + tariff research per type | Neutral sources (Stiftung Warentest, Finanztip) not affiliate links (Check24) | Medium | WebSearch agent spawned per type on request |
| Prioritized action list | Not a wall of findings — ranked by: risk exposure → € savings → convenience | Low | Sort: missing essentials first, then redundancies, then optimization |

## Differentiators

Features that set Finyx apart from Check24/Clark for this use case.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Over-insurance / redundancy detection | "You're paying for Fahrradversicherung AND Hausrat covers bike theft — cancel one" | Medium | Overlap matrix (see below) — cross-type rules |
| € risk exposure for gaps | Not just "you're missing Rechtsschutz" but "a single labor dispute costs €3–15k in legal fees" | Low | Static reference table: typical cost per event per missing type |
| Tax deductibility flag per type | PKV/GKV §10 EStG deductible; Risiko-Leben §10 EStG deductible; Haftpflicht not deductible | Low | Feeds insights skill's tax efficiency score |
| Integrated cross-advisor view | Insurance total cost visible in income allocation benchmark; PKV deduction in tax analysis | Low | Extend profile.json → insights picks it up automatically |
| Policy document parsing (PDF/text) | Extract: insurer, policy number, sum insured, annual premium, start/end date, coverage type | High | LLM extraction from uploaded docs; flag missing fields as [UNKNOWN] |
| Annual review trigger logic | "Your Kfz Vollkasko covers a 7-year-old car worth ~€5k — downgrade to Teilkasko, save ~€200/yr" | Medium | Rules: car age + vehicle type + coverage level |
| Mietkaution opportunity cost analysis | "€2,400 locked in deposit = 3.5% Tagesgeld = €84/yr opportunity cost vs €60/yr guarantee fee" | Low | Simple math; recommends guarantee for low-cost policies |

## Anti-Features

Explicitly do NOT build these.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Full cross-provider tariff comparison engine | Check24's core business; we'd be worse and inherently biased toward what WebSearch returns | Direct users to Check24/Verivox with explicit search URL and what to look for |
| Storing health data beyond session | GDPR Art. 9; existing pattern: session-only health flags for PKV | Apply same session-only pattern; never write health flags to profile.json |
| Automated contract switching or cancellation | Legal liability; advisory-only constraint; user trust | Provide draft Kündigungsschreiben template with instructions and Fristen reminders |
| Premium tracking via insurer APIs | No stable API ecosystem for German insurers; high maintenance | Manual input in profile.json + annual re-check prompt |
| Recommending products Stiftung Warentest explicitly calls unnecessary | Destroys advisory credibility (Handyversicherung, Brillenversicherung, Restschuldversicherung) | When user asks, explain why and redirect |
| Bundled combo-product recommendations (ARAG Recht+Heim) | Often more expensive; limits provider choice; masks individual type analysis | Analyze each type independently; note bundle exists as option user can research |
| Real-time premium quotes | Requires insurer API integrations that don't exist for most German providers | Use Stiftung Warentest test winner benchmarks as reference range |

---

## Coverage Overlap / Redundancy Matrix

These are the overlaps to actively detect and flag:

| Primary Policy | May Overlap With | What to Check |
|----------------|-----------------|---------------|
| Hausrat | Fahrradversicherung | Does user's Hausrat include Fahrraddiebstahl? What's the sublimit? Standalone only if gap exceeds value |
| Kfz-Vollkasko | Kfz-Schutzbrief | Many Vollkasko tariffs include Schutzbrief; check tariff details before recommending standalone |
| Kfz-Schutzbrief (standalone) | ADAC membership | ADAC basic membership includes breakdown service; Schutzbrief is then fully redundant |
| Rechtsschutz (Verkehrsrecht module) | Some Kfz tariffs | A small number of premium Kfz tariffs include basic traffic legal; verify tariff |
| Reiseversicherung (Auslandsreise-KV) | PKV tariff | Most PKV tariffs include Auslandsreiseschutz for 6–8 weeks; GKV provides only EU emergency coverage |
| Risiko-Leben | bAV Hinterbliebenenschutz | Company pension (bAV) may include survivor benefit; reduces required Risiko-Leben sum |
| Zahn (ZZV) | GKV Festzuschüsse | ZZV stacks on top of GKV, not redundant — but must calculate net benefit vs wartezeit cost |
| Haftpflicht | Hausrat (Mietsachschäden module) | Some Hausrat policies include Mietsachschäden; check if Haftpflicht is then needed separately |

---

## User Journey for Insurance Portfolio Optimization

Based on Clark, Finanztest, and Finanztip patterns — what a good advisory flow looks like:

1. **Inventory** — What does the user currently have? (manual input to profile.json or document upload)
2. **Life situation** — 8-question profile: family status, housing type (renter/owner), car owner, bike value, travel frequency, employment type
3. **Tier check** — Which of the 11 types are relevant given their situation?
4. **Gap analysis** — Which Tier 1/2 types are missing? What's the € risk exposure for each gap?
5. **Coverage adequacy** — For types they have: is the sum insured correct? (Hausrat m², Haftpflicht minimum, Risiko-Leben income×years)
6. **Redundancy scan** — Are they paying for overlapping coverage? Use overlap matrix above.
7. **Price benchmark** — Is their current premium in the reasonable range for their type? (WebSearch Stiftung Warentest / Finanztip benchmarks)
8. **Action list** — Ranked output: fix gaps first, remove redundancies second, optimize price third
9. **Provider research** — On request: neutral-source tariff research for specific type (not auto-triggered for all 11)

---

## Profile Schema Extension

New fields needed in `profile.json` under an `insurance` key:

```json
{
  "insurance": {
    "life_situation": {
      "family_status": "single|couple|family",
      "housing": "renter|owner",
      "car_owner": true,
      "bike_value_eur": 1200,
      "travel_days_per_year": 20,
      "employment": "employed|self_employed|civil_servant|student"
    },
    "policies": [
      {
        "type": "haftpflicht|hausrat|kfz_haftpflicht|kfz_kasko|rechtsschutz|zahn|risiko_leben|reise|fahrrad|kfz_schutzbrief|mietkaution",
        "provider": "HUK-Coburg",
        "annual_premium_eur": 89,
        "sum_insured_eur": 15000000,
        "start_date": "2022-01-01",
        "notes": "includes Fahrraddiebstahl bis €500"
      }
    ],
    "total_annual_cost_eur": 0
  }
}
```

---

## Feature Dependencies

```
Life situation inputs (family, housing, car, bike, travel)
  → Applicable type determination (Tier 1/2/3/4 per situation)
    → Gap detection (missing Tier 1/2 = urgent)
      → Coverage adequacy check (per type: m², income×years, minimum sum)
        → Redundancy scan (overlap matrix)
          → Cost benchmark (WebSearch: Stiftung Warentest ranges)
            → Prioritized action list
              → [Optional] Document parsing (improves accuracy of inputs)
              → [Optional] Provider research (WebSearch per type, on request)
                → Tax deductibility flags → feeds finyx:insights
```

---

## MVP for v2.1 — Build Order

**Phase 1 — Foundation (no WebSearch needed)**
1. Profile schema extension (insurance section + life_situation)
2. Life situation questionnaire (8 questions, writes to profile.json)
3. Portfolio overview — list policies from profile, total annual cost
4. Gap detection — rule-based, Tier 1/2 checklist vs known policies
5. Coverage adequacy formulas — Hausrat m², Haftpflicht minimum, Risiko-Leben calc
6. Redundancy detection — overlap matrix check

**Phase 2 — Enrichment (WebSearch)**
7. Cost benchmark per type — WebSearch Stiftung Warentest + Finanztip ranges
8. Provider research agent — per type, on explicit request
9. Tax deductibility reference doc — per type, feeds insights

**Phase 3 — Advanced (High complexity, defer)**
10. Policy document parsing — PDF/text upload, LLM extraction
11. Annual review trigger logic — car age, policy age rules

---

## Sources

- Clark features (official): https://www.clark.io/innovation/ — MEDIUM confidence
- Finanztip insurance taxonomy: https://www.finanztip.de/sinnvolle-versicherungen/ — HIGH confidence (independent consumer finance site)
- Stiftung Warentest insurance check tool: https://www.test.de/Versicherungen-Optimaler-Risikoschutz-1162242-0/ — HIGH confidence (institution)
- Getsafe/insurtechs overview: https://mytopinsuranceblogs.com/insurtech-companies-germany/ — LOW confidence (secondary)
- Hausrat coverage calculation (€650–700/m²): https://liveingermany.de/best-household-insurance-in-germany/ + https://feather-insurance.com/blog/best-contents-insurance-germany — MEDIUM confidence
- Insurance type overlap guidance: https://www.settle-in-berlin.com/insurance-in-germany/ + https://tarefe.de/en/blog/objects/haftpflicht-vs-hausrat-insurance-germany — MEDIUM confidence
- German insurance essentials taxonomy: https://allaboutberlin.com/guides/insurance + https://germanpedia.com/personal-liability-insurance-germany/ — MEDIUM confidence
