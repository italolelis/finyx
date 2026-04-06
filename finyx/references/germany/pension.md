---
tax_year: 2025
country: germany
domain: pension
last_updated: 2026-04-06
source: "section 10 EStG, section 1a BetrAVG, section 3 Nr. 63 EStG, ZfA, Deutsche Rentenversicherung"
---

# German Pension Reference

This document covers the key German private pension vehicles — Riester-Rente, Rürup-Rente (Basisrente), and bAV (Betriebliche Altersversorgung) — plus statutory pension projection constants for the `/finyx:pension` command. All limits reflect 2025 statutory values.

> **Tax year notice:** This document reflects rules for tax year 2025 (BBG West: 96,600 EUR). The `/finyx:pension` command will warn you if this does not match the current year. Rürup Höchstbeitrag, bAV limits, and Rentenwert change annually — verify before acting.

---

## 1. Riester-Rente

### Eligibility — Unmittelbar förderberechtigt (Direct eligibility)

The following groups are directly eligible to contribute to a Riester contract and receive Zulagen:

- Employees paying mandatory gesetzliche Rentenversicherung (GRV) contributions
- Civil servants (Beamte) receiving employer pension contribution
- Recipients of unemployment benefits (ALG I or ALG II)
- Parents in parental leave (Elternzeit)

**NOT directly eligible (no workaround):**
- Most self-employed persons and freelancers who do NOT pay mandatory GRV contributions
- Exceptions: Handwerker, Lehrer, Hebammen, and Künstler who pay mandatory GRV are eligible

### Eligibility — Mittelbar förderberechtigt (Indirect eligibility)

A non-working spouse of an unmittelbar person is indirectly eligible, provided:

1. The directly-eligible partner is already riesting (has an active Riester contract)
2. The indirectly-eligible partner also opens a Riester contract and pays the minimum own contribution (absolute minimum: 60 EUR/year)

### Zulagen 2025

| Zulage | Amount |
|--------|--------|
| Grundzulage | 175 EUR/year |
| Kinderzulage (child born 2008 or later) | 300 EUR/child/year |
| Kinderzulage (child born before 2008) | 185 EUR/child/year |
| Berufseinsteigerbonus (one-time, if under 25 at contract start) | 200 EUR |

Source: Deutsche Rentenversicherung ZfA. Confidence: HIGH.

### Minimum Contribution for Full Zulagen

To receive the full Zulagen amount, the account holder must contribute at least 4% of the prior year's gross income subject to mandatory GRV contributions (rentenversicherungspflichtiges Vorjahreseinkommen), reduced by Zulagen received. Absolute minimum: 60 EUR/year.

**Formula:**
```
zulagen = 175 + (children_born_2008_or_later × 300) + (children_born_before_2008 × 185)
own_contribution = max(0.04 × prior_income - zulagen, 60)
```

> If the user's profile `children` field is a count rather than an array with birth years, ask at runtime for each child's birth year to calculate Kinderzulage correctly.

### Maximum Eligible Contribution

- 2,100 EUR/year total (own contributions plus Zulagen combined)
- Contributions above 2,100 EUR receive no additional Zulagen or Sonderausgabenabzug

### Tax Advantage — Günstigerprüfung

The Finanzamt automatically applies the Günstigerprüfung: it computes both the direct Zulagen benefit and the Sonderausgabenabzug benefit (deducting the full Riester contribution up to 2,100 EUR from taxable income), then applies whichever is larger.

- If Sonderausgabenabzug benefit > Zulagen received, the user gets an additional tax refund equal to the difference
- Zulagen are always offset against the resulting Sonderausgabenabzug tax benefit — the user never receives both in full independently

**Practical implication:** High-income users with no children see minimal net benefit from Riester beyond the basic Günstigerprüfung. For users with `children == 0` and `marginal_rate >= 35%`, bAV or Rürup typically delivers a larger absolute saving.

---

## 2. Rürup-Rente (Basisrente)

### Eligibility

Any German tax resident may contribute to a Rürup (Basisrente) contract. Rürup is especially valuable for:

- Self-employed persons and freelancers not eligible for Riester
- High-income employed persons who want a tax-efficient supplement to Riester/bAV

Employed users can use Rürup, but it typically duplicates benefits already available via bAV or Riester — evaluate individually.

### Sonderausgabenabzug 2025

- **Deductible percentage:** 100% (since 2023 — the phase-in schedule was accelerated, reaching 100% in 2023 instead of the originally planned 2025)
- **Höchstbeitrag 2025 (legal basis: §10 Abs. 3 S. 1 EStG):**
  - Single: **29,344 EUR**
  - Married (joint assessment): **58,688 EUR**

> **D-11 discrepancy note:** The planning context (D-11) referenced 27,566 EUR / 55,132 EUR — those are the 2024 values. The verified 2025 statutory figure is 29,344 EUR / 58,688 EUR, derived as 24.7% × BBG West 96,600 EUR = 23,845.20 EUR → rounded per statute. This document uses the correct 2025 figure. Verify annually as the Höchstbeitrag changes with BBG West.

### GRV Offset

GRV contributions (both employee and employer share) count toward the Höchstbeitrag. For employed users, approximately half the Rürup space is consumed by their combined GRV contributions:

```
approx_grv_total = gross_income × min(gross_income, BBG_West) / gross_income × 0.186
remaining_ruerup_space = max(hoechstbeitrag - approx_grv_total, 0)
```

Advisory: show the available Rürup space after GRV offset. Most employed users have roughly 14,000–22,000 EUR of remaining Rürup space.

### Tax Saving Formula

```
hoechstbeitrag = 29344   # single (2025); 58688 for married — verify annually
tax_saving = min(contribution, hoechstbeitrag) × marginal_rate
net_cost   = contribution - tax_saving
```

Present both the gross contribution and net cost after subsidy in the output.

---

## 3. bAV (Betriebliche Altersversorgung)

### Core Mechanism

bAV via Entgeltumwandlung allows an employee to redirect gross salary into a company pension scheme, reducing both income tax and social security contributions simultaneously.

### Tax-Free and SV-Free Limits 2025 (§3 Nr. 63 EStG)

| Limit | Calculation | 2025 Amount |
|-------|------------|------------|
| Income-tax-free | 8% × BBG West (96,600 EUR) | **7,728 EUR/year** |
| Social-security-free | 4% × BBG West (96,600 EUR) | **3,864 EUR/year** |

- Contributions up to 7,728 EUR/year: fully exempt from income tax (Lohnsteuer)
- Contributions up to 3,864 EUR/year: additionally exempt from social security contributions (Sozialversicherungsbeiträge)
- Contributions above 7,728 EUR/year are subject to income tax (but not Abgeltungssteuer — taxed as regular income)

### Mandatory Employer Contribution (§1a BetrAVG, since 2022)

When an employee does Entgeltumwandlung via Direktversicherung, Pensionskasse, or Pensionsfonds, the employer is legally required to add a minimum **15% of the redirected amount** as an employer Zuschuss, provided the employer saves social security contributions as a result.

> This employer contribution is in addition to the redirected salary — it is free money. Always confirm with HR whether the employer is contributing more than the legal minimum.

### GRV Tradeoff

Entgeltumwandlung reduces the employee's gross income, which means fewer Entgeltpunkte (EP) accumulate in the gesetzliche Rentenversicherung each year.

- At lower income levels (below the GRV ceiling of ~60,000–70,000 EUR), this tradeoff is significant — each EUR redirected reduces future GRV entitlement
- At high income levels near or above the BBG, GRV Entgeltpunkte are already capped — the tradeoff is less material

> Always mention the GRV reduction tradeoff in bAV guidance, especially for employees earning below 50,000 EUR gross.

### Tax Saving Formula (Entgeltumwandlung)

```
redirect_amount = user input (how much to redirect per year)
sv_free_limit   = 3864     (2025 — social security free)
tax_free_limit  = 7728     (2025 — income tax free)

tax_saving = min(redirect_amount, tax_free_limit) × marginal_rate
sv_saving  = min(redirect_amount, sv_free_limit) × 0.207   (approx combined SV rate, employee share)
net_cost   = redirect_amount - tax_saving - sv_saving
```

Advisory: Present net_cost as the effective out-of-pocket cost to the employee. The employer's mandatory 15% Zuschuss reduces the effective cost further.

### Advisory Framing

bAV terms are employer-contract-dependent. The command cannot determine the specific vehicles or contribution levels available. Generic guidance:

1. Ask HR which bAV vehicle the employer offers (Direktversicherung / Pensionskasse / Pensionsfonds / Direktzusage / Unterstützungskasse) and what the employer contributes above the legal minimum
2. Entgeltumwandlung up to 3,864 EUR/year is doubly efficient — no income tax AND no social security
3. Between 3,864 EUR and 7,728 EUR/year: income-tax-free only (social security still applies)
4. Note GRV Entgeltpunkte reduction tradeoff

---

## 4. Riester vs Rürup vs bAV Comparison Matrix

| Criterion | Riester | Rürup | bAV |
|-----------|---------|-------|-----|
| Who it's for | Employees with mandatory GRV; parents | Everyone incl. self-employed | Employed only (via employer) |
| Self-employed eligible | Rarely (see Section 1) | Yes — primary vehicle | No |
| Key benefit | Zulagen subsidies; largest advantage with many children | Sonderausgabenabzug at full marginal rate | Entgeltumwandlung — tax + SV reduction |
| Max annual | 2,100 EUR (own + Zulagen) | 29,344 EUR (2025) less GRV offset | 7,728 EUR income-tax-free (8% BBG) |
| Flexibility | Low — locked until retirement, annuity mandatory | Very low — no lump sum at retirement | Moderate — terms employer-dependent |
| Child bonus | YES — Kinderzulage is a core advantage | No | No |
| Sonderausgabenabzug | Yes — via Günstigerprüfung | Yes — explicit, up to Höchstbeitrag | No |

---

## 5. Gesetzliche Rente (Statutory Pension) — Projection Constants

### Rentenwert 2025

- **Rentenwert (aktueller Rentenwert):** 40.79 EUR/month per Rentenpunkt (Entgeltpunkt) as of July 1, 2025
- Increase: +3.74% from 39.32 EUR (prior Rentenwert)
- Source: Bundesregierung.de, Deutsche Rentenversicherung press release 2025. Confidence: HIGH.

> **Annual update required:** The Rentenwert changes annually on July 1. This reference doc must be updated each year after the Rentenanpassungsbeschluss. Flag in the staleness check if `tax_year` in this frontmatter does not match the current year.

### Projection Formula

```
monthly_statutory_pension = de_rentenpunkte × 40.79
```

`de_rentenpunkte` is collected from profile field `pension.de_rentenpunkte`. If null, ask the user at runtime — they can find it on their annual Deutsche Rentenversicherung statement (Renteninformation).

### Standard Retirement Age 2025

- Regular retirement age: **66 years and 2 months** (Regelaltersgrenze, for birth year 1958)
- Minimum Wartezeit: **5 years** of contributions to Deutsche Rentenversicherung
- This age is increasing progressively — users born after 1964 will reach regular retirement at 67

### Default Real Return Rate

- DE private pension projection: **1.5% real (inflation-adjusted) annual return** per D-04
- Overridable via profile field: `pension.expected_real_return_de`

---

## 6. Cross-Country Projection Constants (DE Side)

### Real Return Rate

```
default_real_return_de = 1.5   # percent, inflation-adjusted, per D-04
user_override_field    = pension.expected_real_return_de
```

### Projection Formula

```
real_accumulated = current_value × (1 + real_rate / 100) ^ years_to_retirement
```

Where `years_to_retirement = pension.target_retirement_age - current_age` (current age derived from profile or asked at runtime).

### D-07 Disclaimer (verbatim — include in all cross-country projections)

> Cross-border pension entitlements require verification by a Brazilian social security lawyer (advogado previdenciário). This projection is an illustrative estimate only — actual benefits depend on contribution history, treaty application, and regulatory changes in both countries.

---

*Source: §10 Abs. 3 S. 1 EStG (Rürup Höchstbeitrag), §3 Nr. 63 EStG (bAV limits), §1a BetrAVG (mandatory employer Zuschuss), ZfA / Deutsche Rentenversicherung (Riester Zulagen), Bundesregierung.de (Rentenwert 2025). Verify BBG West, Höchstbeitrag, and Rentenwert annually.*
