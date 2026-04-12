# Technology Stack — Comprehensive German Insurance Advisor (v2.1)

**Project:** Finyx insurance skill expansion
**Researched:** 2026-04-12
**Scope:** 11 additional German insurance types on top of the existing PKV/GKV skill

> **Note:** v2.0 plugin architecture stack (plugin.json manifest, SKILL.md frontmatter, agent placement rules) is unchanged. This document focuses on what v2.1 adds to the insurance skill specifically.

---

## Constraint Reminder

Zero-runtime-dependency Claude Code plugin. "Stack additions" means:
- New reference `.md` files per insurance type (11 files)
- One new generic agent `.md` file
- Profile schema additions (JSON fields only)
- Prompt-level data extraction patterns (no Node.js code)
- No npm packages, no API clients, no build steps

---

## Data Sources Per Insurance Type

### Source Hierarchy (same rule as existing PKV agent, applies to all 11 types)

1. **Stiftung Warentest / Finanztip** — neutral, no commercial bias, rigorous methodology. Use first.
2. **Direct provider websites** — authoritative for pricing, terms, exclusions.
3. **Verivox / Tarifcheck** — acceptable secondary neutral aggregators for market ranges.
4. **Check24** — fallback only, never primary. Same commission-bias rule as existing PKV research agent.

### Per-Type Data Source Map

| Insurance Type | DE Name | Primary Search Targets | Key Benchmarks |
|----------------|---------|------------------------|----------------|
| Household contents | Hausratversicherung | finanztip.de/hausratversicherung, verivox.de/hausratversicherung | €650/m² standard sum; Unterversicherungsverzicht; Elementarschutz inclusion; €19–80/yr for 70m² |
| Private liability | Privathaftpflicht | test.de/Vergleich-Haftpflichtversicherung-4775777-0, finanztip.de | Min. €50M Deckungssumme; Schlüsselverlust; €6–15/month |
| Car insurance | Kfz-Versicherung | finanztip.de/kfz-versicherung, adac.de | SF-Klasse 0–50; Typklasse; Regionalklasse; Haftpflicht/Teilkasko/Vollkasko; €300–1,200/yr |
| Breakdown cover | Kfz-Schutzbrief | adac.de ADAC Schutzbrief product page | Pannenhilfe, Abschleppen, Auslandsschutz; ~€20–50/yr add-on or ADAC membership |
| Legal protection | Rechtsschutzversicherung | test.de/Rechtsschutzversicherung-im-Vergleich-4776988-0, finanztip.de | 84 packages / 31 insurers tested Oct 2025 (Stiftung Warentest); modules: Privat/Beruf/Verkehr/Miete |
| Dental supplement | Zahnzusatzversicherung | test.de, finanztip.de/zahnzusatzversicherung | Erstattungssatz 60–100%; Wartezeit 3–8 months statutory; Jahreshöchstleistung; KFO inclusion |
| Term life | Risikolebensversicherung | finanztip.de/risikolebensversicherung | Todesfallsumme = 3–5× gross income; from ~€3/month (age 25, €150k, 10yr); price spreads up to 3× between providers |
| Private pension | Private Rentenversicherung | finanztip.de, bafin.de/Verbraucher/Versicherungen | Klassisch/fondsgebunden/indexgebunden; intersects with pension skill — reference to finyx-pension |
| Travel insurance | Reiseversicherung | check24.de/reiseversicherung, finanztip.de/reiseruecktrittsversicherung | 300+ tariffs on Check24; modules: Rücktritt/Kranken/Gepäck/Haftpflicht; Jahrespolice vs. Einzelreise |
| Bicycle insurance | Fahrradversicherung | check24.de/fahrradversicherung, verivox.de | Diebstahlschutz scope; Neuwertersatz vs. Zeitwert; E-Bike rules; Selbstbeteiligung |
| Rental deposit | Mietkautionsversicherung | finanztip.de, eurokaution.de, mietkautionskonto.info | §551 BGB max 3 Monatskaltmieten; 4–6% annual premium (EuroKaution: 4.7%); providers: EuroKaution/R+V, Kautionsfrei |

**Confidence on benchmarks:** MEDIUM — search-verified ranges from multiple neutral sources. Live quotes vary by individual parameters (age, location, vehicle, flat size, etc.).

---

## WebSearch Agent Pattern: Scalability Assessment

**Verdict: Scales. Use one generic agent, not 11 separate agents.**

### Why It Scales

The existing `finyx-insurance-research-agent.md` pattern (WebSearch + WebFetch, 3-provider output, confidence flags) works for any insurance type. The pattern is stateless and parameter-driven.

### Recommended Architecture

**Keep 3 agents total** (unchanged from v1.2):

| Agent | Role | Change in v2.1 |
|-------|------|----------------|
| `finyx-insurance-calc-agent.md` | Portfolio-level cost aggregation, gap scoring, coverage assessment | Extend to handle portfolio view across all types, not just PKV/GKV calc |
| `finyx-insurance-research-agent.md` | PKV/GKV health insurance research | No change |
| `finyx-insurance-type-research-agent.md` | **New** — generic research agent for all 11 property/liability/life/travel types | New file |

**One generic agent covers all 11 types** by receiving `insurance_type` as a Task prompt parameter and reading the type-specific reference doc from `${CLAUDE_SKILL_DIR}/references/germany/{type}.md`.

### What The Generic Agent Gets From Each Reference Doc

Each type-specific reference doc includes a `## Agent Query Templates` section that provides:
- 3–5 pre-built WebSearch query strings with `{current_year}` placeholders
- Primary neutral source URLs to WebFetch first
- Key fields to extract (provider name, premium, coverage scope, key terms)
- Data confidence heuristics for the type

This pattern is already proven — it mirrors how the PKV agent reads `health-insurance.md` Section 2.1 before searching.

---

## Policy Document Parsing (PDF Reading)

### Approach: Native Read Tool, No External OCR

Claude Code's `Read` tool reads text-layer PDFs natively. No external OCR library, no npm package, no build step required.

**Workflow:**
1. User places policy PDFs in `.finyx/insurance-docs/` (configurable path in profile)
2. `/finyx:insurance` command `Read`s each PDF
3. Claude extracts structured fields using the per-type extraction schema from the reference doc
4. Fields are compared against coverage benchmarks to flag gaps and over-insurance

### Universal Fields (All Policy Types)

| Field | German Term | Notes |
|-------|-------------|-------|
| Policy number | Versicherungsscheinnummer | Top of Deckblatt |
| Insurer name | Versicherungsgesellschaft | |
| Annual premium | Jahresprämie / Monatsbeitrag × 12 | Normalize to annual |
| Coverage start | Versicherungsbeginn | |
| Next renewal / end | Versicherungsende / nächste Hauptfälligkeit | |
| Cancellation deadline | Kündigungsfrist | Usually 3 months before Hauptfälligkeit |
| Deductible | Selbstbeteiligung / Selbstbehalt | |

### Type-Specific Extraction Fields

Each reference doc encodes a `## PDF Extraction Schema` section. Key fields per type:

**Hausratversicherung:** `Versicherungssumme`, `Unterversicherungsverzicht` (y/n), `Elementarschutz` (y/n), `covered_perils` (Einbruch, Leitungswasser, Feuer, Sturm/Hagel)

**Kfz-Versicherung:** `Deckungsart` (Haftpflicht/Teilkasko/Vollkasko), `SF-Klasse`, `Typklasse`, `SB_Teilkasko`, `SB_Vollkasko`, `Fahrerschutz` (y/n), `GAP-Deckung` (y/n)

**Privathaftpflicht:** `Deckungssumme`, `Schlüsselverlust` (y/n), `Gefälligkeitsschäden` (y/n), `Auslandsschutz` scope

**Rechtsschutzversicherung:** covered modules (Privat/Beruf/Verkehr/Miete), `Wartezeit` (months), `Streitwertlimit`, `Selbstbeteiligung`

**Risikolebensversicherung:** `Todesfallsumme`, `Laufzeit`, `Beitragsbefreiung_bei_BU` (y/n), `fallende_Versicherungssumme` (y/n)

**Zahnzusatzversicherung:** `Erstattungssatz` (%), `Jahreshöchstleistung`, `Wartezeit`, `KFO_included` (y/n)

**Mietkautionsversicherung:** `Kautionsbetrag`, `Jahresprämie`, `Bürgschaftsnehmerin` (landlord name)

### PDF Parsing Limitations

- Scanned PDFs (image-only) will fail — Claude reads text-layer only. Command must warn: "If your PDF was scanned without a text layer, extraction will be incomplete."
- Heavily stylized insurer layouts degrade extraction quality. Flag partial results as `[PARTIAL EXTRACTION]`.
- Do NOT attempt to extract health data from any document — GDPR Art. 9 restriction applies system-wide.
- Budget ~30s per PDF for extraction. For large policy booklets (AVB/Bedingungen), read only the Deckblatt/Versicherungsschein page, not the full terms.

---

## Profile Schema Extension

Add an `insurance` block to `profile.json`. This is the only schema change needed for v2.1.

```json
"insurance": {
  "health": {
    "type": "GKV|PKV|unknown",
    "provider": null,
    "monthly_premium": null
  },
  "policies": [
    {
      "type": "hausrat|haftpflicht|kfz|kfz-schutzbrief|rechtsschutz|zahnzusatz|risikoleben|rente-privat|reise|fahrrad|mietkaution",
      "provider": null,
      "annual_premium": null,
      "coverage_start": null,
      "next_cancellation_deadline": null,
      "doc_path": null,
      "notes": null
    }
  ],
  "docs_folder": ".finyx/insurance-docs"
}
```

`doc_path` enables the command to `Read` the policy PDF. `docs_folder` is the default scan location.

---

## Reference Docs Required (11 New Files)

Location: `skills/insurance/references/germany/`

Each file follows the existing `health-insurance.md` pattern: YAML frontmatter (`tax_year`, `last_updated`, `source`), then sections for market data, legal minimums, PDF extraction schema, agent query templates, and coverage traps.

| File | Primary Legal/Data Source | Key Content |
|------|--------------------------|-------------|
| `hausrat.md` | GDV, VVG §§81ff, finanztip.de | 650 EUR/m² benchmark, Unterversicherung math, Elementarschutz inclusion check |
| `haftpflicht.md` | §823 BGB, Stiftung Warentest 400+ tariff data | Deckungssumme minimum (50M EUR), module types, Schlüsselverlust, Mietsachschäden |
| `kfz.md` | PflVG (Pflichtversicherungsgesetz), adac.de, finanztip.de | SF-Klasse table 0–35+, Typklasse/Regionalklasse, Deckungsarten, Kasko decision logic |
| `kfz-schutzbrief.md` | ADAC product pages | ADAC vs. insurer comparison, Pannenhilfe abroad, Mietwagen inclusion |
| `rechtsschutz.md` | GDV, test.de Oct 2025 benchmark | Module definitions, 3-month Wartezeit rule, Streitwertlimits, Selbstbeteiligung |
| `zahnzusatz.md` | GKV dental coverage gaps (§55 SGB V), finanztip.de | Erstattungssatz tiers, statutory Wartezeit, Jahreshöchstleistung table, KFO inclusion |
| `risikoleben.md` | finanztip.de Summer 2025 analysis | 3–5× gross income benchmark, level vs. annuitized sum, premium table by age/coverage |
| `rente-privat.md` | BaFin consumer guidance, §10a EStG | Product type decision (klassisch vs fondsgebunden), intersection with finyx-pension skill, BaFin warnings on Rentengarantiezeit |
| `reise.md` | GDV, finanztip.de | Module breakdown, Jahrespolice threshold (2+ trips/yr), EU travel vs. worldwide, Stornoversicherung scope |
| `fahrrad.md` | finanztip.de | Diebstahlschutz scope, E-Bike rules (Versicherungspflicht for speed pedelecs), Neuwertersatz vs. Zeitwert |
| `mietkaution.md` | §551 BGB, eurokaution.de, mietkautionskonto.info | 3 Monatskaltmieten cap (statutory), 4–6% annual premium benchmark, key providers (EuroKaution/R+V, Kautionsfrei), Kündigung rules |

---

## Gap Analysis Logic (No New Agent Needed)

The portfolio gap analysis (coverage gaps, over-insurance detection, total cost) runs in the orchestrating `/finyx:insurance` command, not a separate agent. Logic:

1. Read `profile.json` insurance block — what policies exist
2. Read each `doc_path` PDF if present — extract coverage fields
3. Compare extracted coverage against benchmarks in each type's reference doc
4. Flag: missing mandatory types (Kfz Haftpflicht for car owners is legally required), underinsured (Hausrat sum < 650/m² × flat size), potentially redundant (Reise Haftpflicht vs. existing Privathaftpflicht with travel scope)
5. Aggregate total annual insurance spend from all policy premiums

This is deterministic prompt logic — no new agent, no new tooling.

---

## Scalability Summary

| Dimension | v1.2 State | v2.1 Change | Verdict |
|-----------|------------|-------------|---------|
| Reference docs | 1 (health-insurance.md) | +11 type docs | Linear growth, manageable |
| Agents | 2 | +1 generic type-research agent | Flat — one agent covers all 11 types |
| Profile schema | No insurance block | Add `insurance.policies[]` array | Single backward-compatible addition |
| PDF parsing | Not implemented | Native `Read` tool, no OCR | No new tooling needed |
| WebSearch pattern | PKV-specific | Parameterized by type | Same pattern, different inputs |
| Command complexity | 1 workflow (PKV/GKV) | +type dispatch phase | Still one command file |
| Annual maintenance | 1 doc per tax year | 12 docs per tax year | ~12× more maintenance burden — mitigated by annual batch update pattern |

---

## Sources

- Stiftung Warentest Rechtsschutz (Oct 2025, 84 packages, 31 insurers): https://www.test.de/Rechtsschutzversicherung-im-Vergleich-4776988-0/
- Stiftung Warentest Haftpflicht (400+ tariffs): https://www.test.de/Vergleich-Haftpflichtversicherung-4775777-0/
- Finanztip Risikolebensversicherung (Summer 2025 analysis): https://www.finanztip.de/risikolebensversicherung/
- Finanztip Hausratversicherung: https://www.finanztip.de/hausratversicherung/
- EuroKaution Mietkautionsversicherung (4.7% benchmark): https://www.eurokaution.de/mietkautionsversicherung/
- Mietkautionskonto.info benchmark (4.5–5%): https://mietkautionskonto.info/mietkautionsbuergschaft/
- ADAC Kfz SF-Klassen (Verivox 2026): https://www.verivox.de/kfz-versicherung/schadenfreiheitsklasse/
- Check24 Reiseversicherung (300+ tariffs): https://www.check24.de/reiseversicherung/
- GDV Hausrat 650 EUR/m² standard: corroborated by Allianz, Verivox, Finanztip
- Franke und Bornberg PHV rating 2025: https://www.franke-bornberg.de/fb-news/pressemitteilungen/private-haftpflichtversicherung-rating-2025
- §551 BGB (Mietkaution cap): German Civil Code — authoritative
- §6 SGB V (PKV eligibility), §10 EStG (deduction): existing health-insurance.md references preserved
