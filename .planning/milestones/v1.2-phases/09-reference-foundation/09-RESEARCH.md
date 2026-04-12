# Phase 9: Reference Foundation — Research

**Researched:** 2026-04-06
**Domain:** German health insurance reference document authoring (GKV/PKV statutory constants, formulas, risk model)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** 3-tier PKV risk model with ~15 binary condition flags. Bands: 0% (no flags), 10-25% (1-2 minor controlled conditions), 30-50%+ (3+ flags or any high-rejection flag).
- **D-02:** Include a rejection-risk callout list (mental health history, HIV, active cancer, recent cardiac events) marked as "high rejection probability" — advisory note, not a quantified tier.
- **D-03:** Binary flags only (yes/no per condition). No diagnosis details, no severity modifiers. GDPR Art. 9 compliant.
- **D-04:** Document the GKV-Spitzenverband average Zusatzbeitrag rate (2.75% for 2025 / 2.9% for 2026) plus the statutory range (2.18–4.4%). No static table of individual fund rates.
- **D-05:** Include a `fallback_rate` field and `source_url` pointing to the GKV-Spitzenverband publication. The Phase 10 research agent fetches live fund-specific rates via WebSearch.
- **D-06:** Single flat document, ~320 lines, 6 numbered top-level sections: (1) GKV, (2) PKV, (3) Familienversicherung, (4) Eligibility Thresholds & Risk Tiers, (5) §10 EStG Deduction, (6) Special Cases.
- **D-07:** Employer contribution cap formulas inline under GKV section (not a standalone section).
- **D-08:** Frontmatter: `tax_year: 2025`, `country: germany`, `domain: health-insurance`, `last_updated`, `source` — matches existing reference doc convention.

### Claude's Discretion

- Exact wording of risk tier descriptions and flag list
- Level of detail for Altersrückstellungen explanation
- Whether to include PKV premium example ranges by age bracket (acceptable if clearly labeled as indicative)
- Projection methodology details (conservative/base/optimistic growth rate assumptions)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-02 | Reference doc `germany/health-insurance.md` exists with 2026 constants and staleness detection | All constants verified from STACK.md (HIGH confidence). Frontmatter pattern from tax-investment.md. Staleness detection pattern from pension.md. |
</phase_requirements>

---

## Summary

Phase 9 produces a single Markdown reference document: `finyx/references/germany/health-insurance.md`. This is a pure content-authoring phase — no code, no commands, no agents. The document must encode all 2026 statutory GKV/PKV constants, formulas for four calculation paths, a 3-tier PKV risk model, and staleness detection metadata. Downstream phases (10, 11) will `@`-reference this doc via Claude Code's file-inclusion syntax.

The existing reference docs (`tax-investment.md`, `pension.md`) establish the exact authoring convention to follow: YAML frontmatter with `tax_year`/`country`/`domain`/`last_updated`/`source`, a staleness notice banner at the top, numbered sections, inline formulas in code blocks, and per-constant source citations. The health insurance doc must match this pattern precisely so Phase 10 agents can load it without any special handling.

All numerical constants for this document have been pre-researched in `.planning/research/STACK.md` with HIGH confidence. The primary authoring risk is constant drift (JAEG ≠ BBG is a classic confusion), scope creep into individual fund tables (explicitly forbidden by D-04), and omitting the `fallback_rate`/`source_url` fields the Phase 10 agent depends on.

**Primary recommendation:** Author the document in one pass following the existing pension.md structure as the closest analog, using STACK.md as the authoritative constant source, and verify every threshold against the JAEG vs BBG distinction before finalising.

---

## Standard Stack

This phase has no software stack — it is a Markdown document. The relevant "stack" is the document convention.

### Document Convention (from existing reference docs)

| Element | Pattern | Source |
|---------|---------|--------|
| Frontmatter | YAML with `tax_year`, `country`, `domain`, `last_updated`, `source` | `tax-investment.md` line 1–7, `pension.md` line 1–7 |
| Staleness notice | Blockquote banner after H1, before first section | Both reference docs |
| Section numbering | `## 1. [Name]`, `### 1.1 [Name]` | Both reference docs |
| Formulas | Fenced code block (no language tag or `python`) | `pension.md` formulas |
| Source citations | Inline after the claim, or footer `*Source: ...*` | Both reference docs |
| Installed path | `finyx/references/germany/` — `bin/install.js` copies recursively | CONTEXT.md |

### No External Dependencies

No npm packages, no APIs, no build tools. File creation only.

---

## Architecture Patterns

### Recommended Document Structure

```
finyx/references/germany/health-insurance.md
```

Exact 6-section layout per D-06:

```
---
[frontmatter]
---

# German Health Insurance Reference

> Tax year notice (staleness detection trigger)

---

## 1. GKV (Gesetzliche Krankenversicherung)
### 1.1 Contribution Formula
### 1.2 Beitragsbemessungsgrenze (BBG)
### 1.3 Zusatzbeitrag
### 1.4 Pflegeversicherung (PV)
### 1.5 Employer Contribution Caps (Arbeitgeberzuschuss)   ← D-07: inline here

## 2. PKV (Private Krankenversicherung)
### 2.1 Age-Based Premium Estimation
### 2.2 Altersrückstellungen
### 2.3 Beitragsrückerstattung
### 2.4 Selbstbeteiligung
### 2.5 Long-Term Projection Constants

## 3. Familienversicherung
### 3.1 GKV Free Coverage Rules
### 3.2 PKV Per-Person Costs

## 4. Eligibility Thresholds & Risk Tiers
### 4.1 JAEG and BBG Thresholds
### 4.2 3-Tier PKV Risk Model (binary flags)       ← D-01, D-02, D-03
### 4.3 Rejection-Risk Callout

## 5. §10 EStG Deduction (Basisabsicherung)
### 5.1 Employee Cap
### 5.2 Self-Employed Cap
### 5.3 ELStAM Electronic Reporting (2026 change)

## 6. Special Cases
### 6.1 Beamter Redirect (Beihilfe)
### 6.2 Expat Anwartschaft
### 6.3 Age-55 Lock-In Warning (§6 Abs. 3a SGB V)

---
*Source: ...*
```

### Pattern 1: Staleness Detection Frontmatter + Notice

Matches both existing reference docs exactly. The `tax_year` field is what Phase 10/11 commands compare against the current year to emit a warning.

```yaml
---
tax_year: 2025
country: germany
domain: health-insurance
last_updated: 2026-04-06
source: "GKV-Spitzenverband, §223 SGB V, §241 SGB V, §57 SGB XI, §6 SGB V, §10 EStG, BaFin"
---
```

Staleness notice banner (immediately after H1):

```markdown
> **Tax year notice:** This document reflects rules for tax year 2025 (JAEG €77,400, BBG €69,750/yr). The `/finyx:insurance` command will warn you if this does not match the current year. JAEG, BBG, Zusatzbeitrag average, and Pflegeversicherung rates change annually — verify before acting.
```

### Pattern 2: Inline Formula Block (from pension.md)

```markdown
### 1.1 Contribution Formula

**Employee (employed, GKV):**
```
monthly_gross_capped = min(gross_monthly_income, BBG_monthly)  # BBG monthly: €5,812.50
gkv_employee = monthly_gross_capped × (0.073 + zusatzbeitrag_half)
pv_employee  = monthly_gross_capped × pv_employee_rate          # 0.019 (with children) or 0.025 (childless 23+)
total_employee_monthly = gkv_employee + pv_employee
```
```

### Pattern 3: Zusatzbeitrag Fallback Fields (D-05)

This is the one pattern not found in existing docs — the Phase 10 agent needs it. Model after the Basiszins table in pension.md but add the two extra fields:

```markdown
### 1.3 Zusatzbeitrag

| Field | 2026 Value | Notes |
|-------|-----------|-------|
| GKV-Spitzenverband average | 2.9% | Half paid by employee, half by employer |
| Statutory range | 2.18%–4.4% | Fund-specific; fetched live by Phase 10 research agent |
| fallback_rate | 2.9% | Use if live fetch unavailable |
| source_url | https://www.gkv-spitzenverband.de | GKV-Spitzenverband official publication |
```

### Pattern 4: Beamter Inline Redirect (from pension.md §6 pattern)

pension.md handles cross-cutting cases with a short redirect note rather than a full subsection. Use the same pattern for Beamter:

```markdown
### 6.1 Beamter / Beihilfe Redirect

Civil servants (Beamte) are covered by the Beihilfe system: the state pays 50–80% of healthcare costs directly. Standard GKV/PKV cost models do NOT apply. When `employment.type == "beamter"`, the `/finyx:insurance` command must redirect to Beihilfe guidance rather than running the GKV/PKV comparison. Full Beamter model is deferred to v1.3 (BEAM-01).
```

### Anti-Patterns to Avoid

- **Confusion of JAEG and BBG:** JAEG (€77,400) is the threshold to OPT INTO PKV. BBG (€69,750) is the GKV CONTRIBUTION CAP. They are different numbers. Never conflate them in formulas or text.
- **Including individual fund Zusatzbeitrag table:** D-04 explicitly forbids this. Only the average + range + fallback_rate fields.
- **Standalone employer cap section:** D-07 requires employer cap formulas under section 1 (GKV), not a separate section.
- **Inventing a `tax_year: 2026` frontmatter:** D-08 specifies `tax_year: 2025`. The document reflects 2025/2026 statutory values published in 2025 for enforcement in 2026 — the convention matches existing docs.
- **Soft-encoding Beamter cost model:** BEAM-01 is deferred. The Beamter section must redirect, not calculate.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Individual fund Zusatzbeitrag data | Static rate table (50+ funds) | `fallback_rate` + `source_url` per D-05; live fetch in Phase 10 |
| PKV actuarial pricing | Sterbetafeln computation | Age-bracket indicative ranges from STACK.md |
| Beamter cost model | Beihilfe calculation formulas | Redirect note only; full model deferred to v1.3 |
| GKV provider comparison | Statutory benefit comparison table | Statutory benefits are identical by law; comparison adds noise |

---

## All 2026 Constants to Encode

All values from STACK.md, confidence HIGH. Reproduced here for planner use.

### GKV Constants

| Constant | 2026 Value | Legal Basis |
|----------|-----------|-------------|
| Allgemeiner Beitragssatz (base KV rate) | 14.6% | §241 SGB V |
| Employee share (KV) | 7.3% | |
| Employer share (KV) | 7.3% | |
| Average Zusatzbeitrag (GKV-Spitzenverband) | 2.9% | D-04 |
| Zusatzbeitrag range | 2.18%–4.4% | D-04 |
| BBG monthly | €5,812.50 | Sozialversicherungsrechengrößen-VO |
| BBG annual | €69,750 | |
| JAEG (new switchers, employed) | €77,400 gross/year | §6 SGB V |
| JAEG (existing PKV holders threshold) | €69,750 | §6 SGB V |

### Pflegeversicherung Constants

| Constant | 2026 Value | Notes |
|----------|-----------|-------|
| PV employee rate (with children) | 1.9% | |
| PV employer rate | 1.7% | |
| PV total (with children) | 3.6% | |
| PV childless surcharge (23+) | +0.6% (employee only) | Total 4.2% |
| PV reduction per child (2nd+, under 25) | −0.25% per child | Min 2.4% at 5+ children |

### Employer Contribution Caps (PKV employees) — D-07

| Component | 2026 Monthly Cap |
|-----------|-----------------|
| Private Krankenversicherung | €508.59 |
| Private Pflegeversicherung (non-Saxony) | €104.63 |
| Private Pflegeversicherung (Saxony) | €75.56 |
| Combined cap (non-Saxony) | €613.22 |

### PKV Age-Bracket Indicative Ranges (label as indicative)

| Age at Entry | Monthly PKV (single, healthy, comprehensive) |
|-------------|----------------------------------------------|
| 25 | €250–350 |
| 30 | €350–500 |
| 35 | €450–650 |
| 40 | €550–800 |
| 45 | €700–1,000 |
| 50 | €900–1,200+ |

### Projection Growth Rate Constants

| Parameter | Conservative | Base | Optimistic | Notes |
|-----------|-------------|------|-----------|-------|
| PKV annual premium growth | 5% | 6% | 3% | Encode in doc; 2026 actual was 7-12% — non-linear flag required |
| GKV BBG growth (income proxy) | 2% | 3% | 4% | Historical avg |
| GKV rate growth (income-tracked) | Per BBG formula | | | |

Per CONTEXT.md specifics: 2026 saw 10-20% PKV increases due to Krankenhausreform. Projection section must note that historical 4-8% average understates current cycle, and conservative scenario uses 5% while noting recent elevated trend.

### §10 EStG Deduction Caps

| Employment Status | Annual Cap |
|------------------|-----------|
| Employees | €1,900 |
| Self-employed | €2,800 |
| Basisabsicherung portion of PKV premium | Typically 70–90% of gross premium |

---

## Common Pitfalls

### Pitfall 1: JAEG ≠ BBG Confusion
**What goes wrong:** €77,400 (JAEG) is used in GKV contribution formulas where €69,750 (BBG) should be, or vice versa. Results in incorrect contribution caps.
**Why it happens:** Both are annual income thresholds near each other; the distinction is not obvious from names alone.
**How to avoid:** Separate subsections for JAEG (eligibility gate) and BBG (contribution cap). Cross-reference in the staleness notice. State both values explicitly under section 4.1.
**Warning signs:** A single "threshold" value appears in both the eligibility gate and contribution cap formula.

### Pitfall 2: Family Cost Underestimation
**What goes wrong:** PKV family cost analysis omits per-child premiums (€150–200/month each) or assumes partner PKV cost is comparable to GKV Familienversicherung (which is free for non-working partners).
**Why it happens:** GKV's zero-marginal-cost Familienversicherung is not made explicit enough, so the comparison looks close when it should show a large GKV advantage for families.
**How to avoid:** Section 3 must explicitly state "non-working partner in GKV: €0 additional cost" and show the PKV per-person cost (€300–600/month) side by side.
**Warning signs:** Family comparison table shows similar total costs for GKV and PKV with 2 children and non-working partner.

### Pitfall 3: Age-55 Lock-In Buried or Missing
**What goes wrong:** §6 Abs. 3a SGB V warning appears only in fine print or is absent entirely. Users 50+ make PKV decisions without understanding the near-irreversibility.
**Why it happens:** It is a legal edge case that feels like a footnote.
**How to avoid:** Section 6.3 must be prominently marked as a WARNING block, not a plain text note. Phase 10/11 commands should check user age against this trigger.
**Warning signs:** Age-55 rule appears as a parenthetical in a sentence rather than a named, titled subsection.

### Pitfall 4: Zusatzbeitrag Data Staleness Presented as Live
**What goes wrong:** A specific fund's rate (e.g., "TK charges 1.7%") is embedded in the reference doc and becomes stale mid-year when the fund adjusts it.
**Why it happens:** Temptation to be more helpful by giving fund-specific examples.
**How to avoid:** D-04 explicitly forbids individual fund rates. Only average + range + fallback_rate. Live rates fetched by Phase 10 agent.
**Warning signs:** Any row in the Zusatzbeitrag table contains a fund name (TK, AOK, Barmer, etc.).

### Pitfall 5: Non-Linear PKV Growth Not Flagged
**What goes wrong:** Projection methodology implies a constant annual growth rate (e.g., 5%) without acknowledging that 2026 saw 10-20% increases due to Krankenhausreform. User applies the model in an elevated-cost year and underestimates PKV cost growth.
**Why it happens:** Simple compound growth formula is cleaner to document.
**How to avoid:** Add a note in the projection constants that the conservative 5% assumption understates recent cycles; flag that projections should be revisited if actual increases exceed 8% in any given year.

### Pitfall 6: Frontmatter `tax_year: 2026` Instead of `2025`
**What goes wrong:** Using 2026 as the frontmatter tax year while existing docs use 2025 (the year whose rules are documented). This breaks the staleness detection convention used by commands.
**Why it happens:** The document encodes 2026-effective statutory values, so 2026 seems correct.
**How to avoid:** Follow D-08 exactly: `tax_year: 2025`. Existing pattern in tax-investment.md and pension.md uses the year of the rules, not the publication year.

---

## Code Examples

### GKV Cost Formula (full, four paths)

```
# Path 1: Employee (GKV)
monthly_gross_capped = min(gross_monthly_income, 5812.50)
gkv_employee = monthly_gross_capped × (0.073 + zusatzbeitrag / 2)
pv_employee  = monthly_gross_capped × pv_rate_employee   # 0.019 with children; 0.025 childless 23+
total_gkv_cost_to_employee = gkv_employee + pv_employee

# Path 2: Self-Employed (GKV freiwillig)
# Pays both employee AND employer share (no Arbeitgeberzuschuss)
gkv_self_employed = monthly_gross_capped × (0.146 + zusatzbeitrag)
pv_self_employed  = monthly_gross_capped × pv_rate_full   # full rate (employee + employer combined)
total_gkv_self_employed = gkv_self_employed + pv_self_employed

# Path 3: Family (GKV Familienversicherung)
# Non-working partner + children: €0 additional premium
# Conditions: partner income < €603/month; children without income limit
total_family_gkv = total_gkv_cost_to_employee   # no multiplier

# Path 4: Beamter
# → REDIRECT to section 6.1 (Beihilfe system; standard formula does not apply)
```

### Employer PKV Subsidy Formula

```
# Employer pays the lower of:
# (a) half of actual PKV+PV premium, or
# (b) the employer GKV-equivalent cap (€508.59 KV + €104.63 PV non-Saxony)

employer_subsidy = min(
  (pkv_monthly + ppv_monthly) / 2,
  508.59 + 104.63   # non-Saxony cap
)

# Net PKV cost to employee:
net_pkv_employee = pkv_monthly + ppv_monthly - employer_subsidy
```

### PKV Risk Tier Adjustment

```
# 3-tier model per D-01
# Count applicable binary flags from questionnaire

flag_count = sum(binary_health_flags)   # each flag: 0 or 1

if flag_count == 0:
    risk_tier = "Tier 0"
    surcharge = "0%"
elif flag_count <= 2 and no_high_rejection_flag:
    risk_tier = "Tier 1"
    surcharge = "10–25%"
else:  # 3+ flags OR any high-rejection flag
    risk_tier = "Tier 2"
    surcharge = "30–50%+"

# Apply to age-bracket base premium:
pkv_estimated = pkv_base_bracket × (1 + surcharge_midpoint)
```

### §10 EStG Tax Benefit Calculation

```
# Basisabsicherung deductibility
basisabsicherung_portion = pkv_monthly × 0.85   # conservative estimate (70–90% range)
annual_deductible = min(basisabsicherung_portion × 12, cap)
  # cap: €1,900 employees, €2,800 self-employed

annual_tax_benefit = annual_deductible × marginal_rate
net_pkv_monthly = pkv_monthly - (annual_tax_benefit / 12)
```

---

## State of the Art

| Old Understanding | Current State | Impact on This Phase |
|-------------------|---------------|---------------------|
| PKV average annual increase ~3-4% | 2026 actual: 7-12% due to Krankenhausreform | Projection section must note non-linear risk, not just historical average |
| GKV Zusatzbeitrag average ~2.5-2.75% (2025) | 2026: ~2.9% average per GKV-Spitzenverband | Use 2.9% in formulas; D-04 specifies this value |
| ELStAM: Basisabsicherung self-reported | 2026: insurers transmit data to BZSt electronically | Note in §10 EStG section that employees no longer need to self-report |
| BBG (2025): €59,850/yr | 2026: €69,750/yr | Use 2026 BBG in all formulas — significant increase |

---

## Open Questions

1. **Pflegeversicherung exact rates**
   - What we know: 3.6% with children (employee+employer), 4.2% childless 23+, −0.25% per additional child (2nd+), minimum 2.4% at 5+ children.
   - What's unclear: Whether the 1.7%/1.9% employee/employer split is correct for 2026 or whether the 2025 reform changed the split. STACK.md states these values as HIGH confidence from GKV-Spitzenverband.
   - Recommendation: Use STACK.md values. Phase 10 verification step can cross-check against official GKV-Spitzenverband publication via source_url.

2. **JAEG for existing PKV holders**
   - What we know: New switchers face €77,400 JAEG; existing PKV holders have a different threshold (€69,750 = BBG). This is an important distinction for users currently in GKV who earned above threshold historically.
   - What's unclear: Whether the existing-holder threshold is technically a separate JAEG or simply the BBG used as a reference. FEATURES.md confirms the distinction.
   - Recommendation: Document both values with a clear note explaining the two-threshold structure. Section 4.1 should make this explicit.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — pure Markdown document authoring phase, no tools, CLIs, services, or runtimes required beyond the file Write tool).

---

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — All 2026 GKV/PKV constants, employer cap formulas, age-bracket ranges, projection constants, Pflegeversicherung rates. Researched 2026-04-06 with source URLs per constant.
- `.planning/research/FEATURES.md` — JAEG/BBG distinction, Familienversicherung formulas, terminology glossary. Researched 2026-04-06.
- `finyx/references/germany/tax-investment.md` — Authoritative frontmatter format, staleness notice pattern, section structure.
- `finyx/references/germany/pension.md` — Inline redirect pattern (Beamter), formula code block pattern, source citation footer pattern.
- `.planning/phases/09-reference-foundation/09-CONTEXT.md` — All locked decisions (D-01 through D-08).

### Secondary (MEDIUM confidence)
- `.planning/research/PITFALLS.md` — Projection precision, staleness synthesis risks; adapted to health insurance domain.

---

## Metadata

**Confidence breakdown:**
- 2026 statutory constants: HIGH — from STACK.md with cited official sources (GKV-Spitzenverband, §SGB V, BaFin)
- Document structure/pattern: HIGH — directly observed in existing reference docs
- PKV age-bracket ranges: MEDIUM — indicative benchmarks from broker aggregator sources; labeled as such in doc
- Projection growth rate assumptions: MEDIUM — historical averages with noted 2026 deviation
- Risk tier flag list (exact flags): LOW — exact list is Claude's discretion per D-01; planner should specify ~15 flags

**Research date:** 2026-04-06
**Valid until:** 2026-12-31 (statutory constants set annually via Sozialversicherungsrechengrößen-VO; next update expected Jan 2027)
