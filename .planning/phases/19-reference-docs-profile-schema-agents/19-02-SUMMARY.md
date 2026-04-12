---
phase: 19-reference-docs-profile-schema-agents
plan: "02"
subsystem: insurance-references
tags: [insurance, reference-docs, germany, knowledge-base]
dependency_graph:
  requires:
    - skills/insurance/references/germany/health-insurance.md
    - skills/profile/references/profile.json
  provides:
    - skills/insurance/references/germany/haftpflicht.md
    - skills/insurance/references/germany/hausrat.md
    - skills/insurance/references/germany/kfz.md
    - skills/insurance/references/germany/rechtsschutz.md
    - skills/insurance/references/germany/zahnzusatz.md
    - skills/insurance/references/germany/risikoleben.md
    - skills/insurance/references/germany/reise.md
    - skills/insurance/references/germany/fahrrad.md
    - skills/insurance/references/germany/kfz-schutzbrief.md
    - skills/insurance/references/germany/mietkaution.md
  affects:
    - Phase 20 (agents consume these reference docs at spawn time)
    - Phase 21-22 (sub-skills load matching reference doc via insurance_type)
tech_stack:
  added: []
  patterns:
    - 8-section reference doc structure (Overview, Coverage Benchmarks, Legal Minimums, Common Coverage Components, Field Extraction Schema, Keyword Map, Cancellation Rules, Sources)
    - coverage_type annotation (sum_based vs service_based) on all docs
    - YAML frontmatter with tax_year, country, domain, last_updated, source
key_files:
  created:
    - skills/insurance/references/germany/haftpflicht.md
    - skills/insurance/references/germany/hausrat.md
    - skills/insurance/references/germany/kfz.md
    - skills/insurance/references/germany/rechtsschutz.md
    - skills/insurance/references/germany/zahnzusatz.md
    - skills/insurance/references/germany/risikoleben.md
    - skills/insurance/references/germany/reise.md
    - skills/insurance/references/germany/fahrrad.md
    - skills/insurance/references/germany/kfz-schutzbrief.md
    - skills/insurance/references/germany/mietkaution.md
  modified: []
decisions:
  - "kuendigungsfrist_months added to health-insurance.md Field Extraction Schema (it already had a compatible section after verification)"
  - "service_based coverage_type annotation used on rechtsschutz, reise, kfz-schutzbrief to align with research pitfall 5"
  - "kfz.md: coverage_amount set to null for Teilkasko/Vollkasko tiers, Haftpflicht Deckungssumme recorded as monetary sum"
  - "risikoleben.md: renewal_date field documents that this is Vertragsende (policy expiry), not annual renewal"
metrics:
  duration_minutes: 7
  completed_date: "2026-04-12"
  tasks_completed: 2
  tasks_total: 2
  files_created: 10
  files_modified: 0
---

# Phase 19 Plan 02: Per-Type Insurance Reference Docs Summary

**One-liner:** 10 German insurance reference docs with 8-section structure, quantified coverage benchmarks, and field extraction schemas aligned to profile.json insurance.policies[].

---

## What Was Built

10 new Markdown reference documents in `skills/insurance/references/germany/`, covering all major German insurance types except health (which already exists). Total reference docs in germany/: 11.

### Task 1: Tier 1-2 Reference Docs (6 files)

| File | Type | Key Benchmark |
|------|------|---------------|
| haftpflicht.md | Personal liability | Deckungssumme ≥ EUR 5M (pauschal) |
| hausrat.md | Household contents | ≥ EUR 650/m² Wohnflache with Unterversicherungsverzicht |
| kfz.md | Motor vehicle | Three tiers: Haftpflicht (mandatory §1 PflVG) / Teilkasko / Vollkasko |
| rechtsschutz.md | Legal expenses | service_based; Wartezeit 3 months; module-based coverage |
| zahnzusatz.md | Supplemental dental | ≥ 80% Zahnersatz reimbursement; Staffelung patterns documented |
| risikoleben.md | Term life | Versicherungssumme = 3–5× annual gross income if dependents |

### Task 2: Tier 3-4 Reference Docs (4 files)

| File | Type | Key Benchmark |
|------|------|---------------|
| reise.md | Travel insurance | service_based; per-trip duration cap flagged; Krankenrucktransport required |
| fahrrad.md | Bicycle insurance | Neuwertentschadigung (replacement cost) benchmark; e-bike Akkuschaden coverage |
| kfz-schutzbrief.md | Breakdown assistance | service_based; EU-wide coverage; ADAC/Kfz overlap warning |
| mietkaution.md | Rental deposit guarantee | sum_based; §551 BGB max 3× Nettokaltmiete; Regresspflicht documented |

---

## Each Doc Contains

1. **YAML frontmatter:** tax_year: 2025, country: germany, domain, last_updated, source
2. **Overview:** What it covers, who needs it, mandatory vs optional, coverage_type
3. **Coverage Benchmarks:** Quantified thresholds in table format
4. **Legal Minimums:** Statutory requirements (kfz Haftpflicht only has a true mandate)
5. **Common Coverage Components:** Included vs excluded in good vs poor policies
6. **Field Extraction Schema:** Table with German label, field name (matches profile.json), type, notes
7. **Keyword Map:** German → English terminology for document reader agent
8. **Cancellation Rules:** Kundigungsfrist and Sonderkundigungsrecht triggers
9. **Sources:** GDV, BaFin, Verbraucherzentrale, Stiftung Warentest, applicable §§

---

## Field Alignment with profile.json

All Field Extraction Schema tables use exact field names from `insurance.policies[]`:
- `provider`, `premium_monthly`, `premium_annual`, `coverage_amount`
- `start_date`, `renewal_date`, `kuendigungsfrist_months`
- `coverage_components`, `exclusions`

Service-based types (rechtsschutz, reise, kfz-schutzbrief) document `coverage_amount: null` explicitly and annotate `coverage_type: service_based`.

---

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| coverage_type annotation on every doc | Prevents portfolio agent from comparing sum-based and service-based coverage monetarily (pitfall 5) |
| kfz.md: one policy entry per contract | Research pitfall 3: three tiers captured in coverage_components, not three separate policy entries |
| risikoleben.md: renewal_date = Vertragsende | Fixed-term contract — documents that this is policy expiry, not annual renewal |
| health-insurance.md: Field Extraction Schema was already present | health-insurance.md already had a compatible schema section; no changes needed |

---

## Deviations from Plan

None — plan executed exactly as written.

---

## Known Stubs

None. All 10 reference docs contain substantive domain content. No placeholders or TODO markers.

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | ac4fb4f | feat(19-02): create Tier 1-2 insurance reference docs |
| Task 2 | b7085d2 | feat(19-02): create Tier 3-4 insurance reference docs |

---

## Self-Check: PASSED

All 10 created files verified to exist on disk. Both task commits (ac4fb4f, b7085d2) verified in git history.
