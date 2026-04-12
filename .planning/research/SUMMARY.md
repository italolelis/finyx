# Research Summary — v2.1 Comprehensive Insurance Advisor

**Researched:** 2026-04-12
**Confidence:** MEDIUM-HIGH

## Executive Summary

Finyx v2.1 expands the insurance skill from health-only to all major German insurance types. Router pattern in SKILL.md dispatches to per-type sub-skill prompts. One generic research agent (parameterized by type) + one new portfolio agent + one new doc-reader agent. 11 per-type reference docs. Legal constraint: recommend criteria, not specific products (§34d GewO).

## Key Findings

### Stack
- One generic research agent parameterized by `<insurance_type>` — no proliferation
- Claude's native `Read` tool handles text-layer PDFs — no OCR dependency
- 11 per-type reference docs needed (coverage benchmarks, legal minimums, field extraction schemas)
- Profile schema: `insurance.policies[]` array with type/provider/premium/coverage/doc_path
- Check24/Verivox as quote-retrieval fallback only — lead with Stiftung Warentest/Finanztip

### Features
**Table stakes:** Portfolio overview, coverage gap detection, coverage adequacy check, cost benchmarks
**Differentiators:** Overlap/redundancy detection (Fahrrad↔Hausrat, Schutzbrief↔Vollkasko↔ADAC), Sonderkündigungsrecht deadline tracking, tier-based advisory urgency
**Anti-features:** Specific product recommendations (legal risk), automated switching, storing health data

**Tier system:**
- Tier 1 (mandatory): Krankenversicherung, Privathaftpflicht, Kfz-Haftpflicht
- Tier 2 (essential): Hausrat, Risiko-Leben, BU, Rechtsschutz, Zahnzusatz
- Tier 3 (situational): Reise, Fahrrad, Kfz-Vollkasko, Schutzbrief
- Tier 4 (niche): Mietkaution

### Architecture
- Router pattern: SKILL.md (~100 lines dispatch) → sub-skills/ per type
- 3 agents total: generic research + portfolio + doc-reader
- Existing PKV calc agent stays health-specific
- Reference docs: one per type under `references/germany/`

### Top Pitfalls
1. **§34d GewO legal boundary** — recommend criteria, not specific competing tariffs
2. **Kfz complexity** — SF-Klasse, Typklasse, Regionalklasse, three coverage types
3. **Sonderkündigungsrecht windows** — 1-month window after premium increase
4. **German number format traps** — "1.250,00 €" = €1,250 not €1.25
5. **Check24/Verivox miss ~30-40% of market** — not neutral tools
6. **BU abstrakte Verweisung** — non-negotiable quality filter

## Suggested Phases (5)

1. **Router + Sub-skill Migration** — Convert health flow to sub-skill, build router SKILL.md
2. **Reference Docs + Profile Schema** — 11 per-type reference docs + insurance.policies[] schema
3. **Portfolio Agent + Gap Detection** — Portfolio overview, gap/overlap detection, tier-based advisory
4. **Per-Type Sub-skills (Tier 1-2)** — Haftpflicht, Hausrat, Kfz, Rechtsschutz, Zahn, Risiko-Leben
5. **Per-Type Sub-skills (Tier 3-4) + Doc Reader** — Reise, Fahrrad, Schutzbrief, Mietkaution + PDF parsing agent

---
*Research completed: 2026-04-12*
