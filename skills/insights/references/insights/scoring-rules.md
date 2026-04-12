---
tax_year: 2025
country: cross-border
domain: insights-scoring
last_updated: 2026-04-06
source: See germany/tax-investment.md and brazil/tax-investment.md for underlying tax rules
---

# Tax Efficiency and Allocation Scoring Rules

> **Tax year notice:** This document reflects scoring thresholds for tax year 2025.
> Verify underlying tax rules against official sources before using for a different tax year.

---

This document defines traffic-light (green/yellow/red) thresholds per dimension per country (D-05, D-06, D-07). It does **not** restate tax rule values — it references `germany/tax-investment.md` and `brazil/tax-investment.md` for underlying figures. Each dimension produces a color indicator AND an absolute euro/real gap amount for Phase 7 agent consumption.

Germany and Brazil are scored independently. Never combine DE and BR into a single metric or shared threshold table (D-06).

---

## Germany Dimensions

### TAX-01: Sparerpauschbetrag Usage

**Source:** `germany/tax-investment.md` Section 3 — EUR 1,000 (single) / EUR 2,000 (married/joint assessment)

**Thresholds:**

| Status | Single | Married | Condition |
|---|---|---|---|
| Green | Unused < EUR 100 | Unused < EUR 200 | >= 90% of allowance utilized |
| Yellow | Unused EUR 100-500 | Unused EUR 200-1,000 | 50-89% utilized |
| Red | Unused > EUR 500 | Unused > EUR 1,000 | < 50% utilized |

**Gap formula:**
```
unused_allowance = limit - sum_of_freistellungsauftrag_across_all_brokers
tax_cost_of_gap  = unused_allowance x 26.375%
                   (or 27.819% with church tax 8% / 27.995% with church tax 9%)
```

**Gap display:** "EUR X/year unused — EUR Y/year in foregone tax savings"

> **Note on church tax:** Church tax rates (8% or 9%) apply to Abgeltungssteuer for registered church members. Source: `germany/tax-investment.md` Section 2.

---

### TAX-03: Vorabpauschale Readiness

**Source:** `germany/tax-investment.md` Section 5 — formula: Fund value x Basiszins x 0.70

**Thresholds:**

| Status | Condition |
|---|---|
| Green | Cash buffer in broker account >= 110% of estimated Vorabpauschale tax due in January |
| Yellow | Cash buffer 80-109% of estimated Vorabpauschale tax due |
| Red | Cash buffer < 80% of estimated Vorabpauschale tax due (risk of forced unit sale) |

**Gap formula:**
```
basisertrag        = fund_value_jan1 x basiszins x 0.70
vorabpauschale     = min(basisertrag, actual_fund_gain_in_year)
tax_due_january    = vorabpauschale x (1 - teilfreistellung_rate) x 26.375%
required_buffer    = tax_due_january x 1.10  (110% for Green threshold)
gap                = max(0, required_buffer - current_cash_in_broker)
```

For equity ETFs, Teilfreistellung rate = 0.30 (30% exempt). Source: `germany/tax-investment.md` Section 4.

**Fallback when current-year Basiszins is unavailable:** Use the prior-year Basiszins value and label the estimate as "ESTIMATED — verify current Basiszins from BMF (published early January)". Flag confidence as MEDIUM. The BMF and Deutsche Bundesbank publish the annual Basiszins in early January; if insights is run before publication, the prior-year value is the best available approximation.

---

### ALLOC-01: Investment Rate (DE)

**Source:** `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md` Section 2 — investment sub-targets for Germany

**Thresholds:**

| Status | Condition |
|---|---|
| Green | Investment rate >= 20% of net-after-mandatory income |
| Yellow | Investment rate 15-19% (meets minimum per D-04, below aspirational) |
| Red | Investment rate < 15% of net-after-mandatory income |

**Gap formula:**
```
investment_rate = (annual_investment_contributions / net_after_mandatory_income) x 100
gap_to_aspirational = max(0, 0.20 x net_after_mandatory - annual_investment_contributions)
gap_to_minimum      = max(0, 0.15 x net_after_mandatory - annual_investment_contributions)
```

---

### ALLOC-02: Emergency Fund (DE)

**Source:** `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md` Section 3 — 6-month threshold

**Thresholds:**

| Status | Condition |
|---|---|
| Green | Liquid savings >= 6 months of total monthly expenses |
| Yellow | Liquid savings 3-5 months (adequate but below cross-border target per D-03) |
| Red | Liquid savings < 3 months |

**Liquid assets for DE:** Cash (Girokonto), Tagesgeld, Festgeld with <= 30-day notice period. Investment portfolios and pension accounts do not count.

**Gap formula:**
```
gap_months = max(0, 6 - (liquid_savings / monthly_expenses))
gap_eur    = gap_months x monthly_expenses
```

---

## Brazil Dimensions

### TAX-02: DARF Compliance

**Source:** `brazil/tax-investment.md` Section 2 — DARF calculation, deadlines, and penalties

**Thresholds:**

| Status | Condition |
|---|---|
| Green | All months with taxable investment gains had DARF filed and paid on time |
| Yellow | DARF obligations are present but payment status is unknown (no data recorded in profile) |
| Red | Known gap month — taxable gain recorded, no DARF payment confirmed |

**Red status action:** Flag with penalty estimate using the late payment rate from `brazil/tax-investment.md` Section 2 (0.33%/day up to 20% cap + Selic correction).

> **Data limitation:** DARF compliance can only be determined if the user's profile contains gain/loss data per month. If `countries.brazil.darf_records` is absent or empty, default to Yellow (unknown) — never assume Green.

---

### TAX-04: PGBL Deduction Utilization

**Source:** `brazil/tax-investment.md` Section 1 — PGBL/VGBL rules and 12% deduction limit

**Applies only to users with `declaracao: completa` in their Brazil profile.** Users on `declaracao: simplificada` do not benefit from PGBL deductions — do not score this dimension for them.

**Thresholds:**

| Status | Condition |
|---|---|
| Green | PGBL contribution >= 12% of gross income (maximum deductible limit under declaracao completa) |
| Yellow | PGBL contribution 6-11% of gross income |
| Red | PGBL contribution < 6% of gross income, or no PGBL with no documented reason |

**Documented exception:** If the user profile records a VGBL preference (e.g., already at the 12% limit, or using declaracao simplificada), treat as Green with a note explaining the exemption. Do not penalize an informed VGBL choice.

**Gap formula:**
```
pgbl_gap_pct  = max(0, 0.12 - (pgbl_contribution / gross_income))
pgbl_gap_brl  = pgbl_gap_pct x gross_income
tax_savings   = pgbl_gap_brl x marginal_ir_rate  (varies by income bracket)
```

---

### ALLOC-01: Investment Rate (BR)

**Source:** `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md` Section 2 — investment sub-targets for Brazil

**Thresholds:**

| Status | Condition |
|---|---|
| Green | Investment rate >= 15% of net-after-mandatory income (including FGTS) |
| Yellow | Investment rate 10-14% (meets minimum) |
| Red | Investment rate < 10% of net-after-mandatory income |

**FGTS counting rule:** Mandatory employer FGTS (8% of gross salary) counts toward the BR investment rate total. Read from `profile.countries.brazil.fgts_contribution`. Do not count INSS toward the investment rate — INSS is social insurance, not personal savings.

**Gap formula:**
```
investment_rate = ((annual_investments + annual_fgts) / net_after_mandatory) x 100
gap_to_minimum  = max(0, 0.10 x net_after_mandatory - (annual_investments + annual_fgts))
```

---

### ALLOC-02: Emergency Fund (BR)

**Source:** `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md` Section 3 — 6-month threshold

**Thresholds:** Same structure as DE ALLOC-02.

| Status | Condition |
|---|---|
| Green | Liquid savings >= 6 months of total monthly expenses |
| Yellow | Liquid savings 3-5 months |
| Red | Liquid savings < 3 months |

**Liquid assets for BR:** Poupanca, conta corrente, CDB de liquidez diaria, LCI/LCA with daily liquidity. Investment portfolios, FIIs, and pension funds (PGBL/VGBL) do not count.

**Gap formula:**
```
gap_months = max(0, 6 - (liquid_savings_brl / monthly_expenses_brl))
gap_brl    = gap_months x monthly_expenses_brl
```

---

## Scoring Output Format

Per D-05. Each dimension result MUST follow this template for Phase 7 agent consumption:

```
[TRAFFIC_LIGHT] [DIMENSION_LABEL]: [STATUS_PHRASE]
  Gap: [EUR X or R$X] [per year / per month] [action verb]
  How to close: [one-line action]
```

**Traffic light symbols:**
- Green: use `[GREEN]` or the green circle indicator
- Yellow: use `[YELLOW]` or the yellow circle indicator
- Red: use `[RED]` or the red circle indicator

**Example — Sparerpauschbetrag (Yellow):**
```
[YELLOW] Sparerpauschbetrag: EUR 263/year unused
  Gap: EUR 263 in unrealized tax savings (EUR 263 x 26.375% = EUR 69/year tax cost)
  How to close: Allocate EUR 263 additional Freistellungsauftrag to an active broker
```

**Example — Emergency Fund (Red):**
```
[RED] Emergency Fund (DE): 2.1 months covered — target 6 months
  Gap: EUR 11,700 to reach 6-month target (EUR 3,900/month x 3.9 months)
  How to close: Build EUR 11,700 liquid savings buffer in Tagesgeld before increasing investments
```

**Example — Investment Rate (Green):**
```
[GREEN] Investment Rate (DE): 22% of net-after-mandatory income — above aspirational target
  Gap: None
  How to close: N/A — maintain current rate
```

### Confidence Flags

Append a confidence flag when data quality is uncertain:

| Flag | When to use |
|---|---|
| `[HIGH CONFIDENCE]` | All required profile fields present and current-year data available |
| `[MEDIUM CONFIDENCE]` | Missing some data or using prior-year estimates (e.g., prior-year Basiszins) |
| `[LOW CONFIDENCE]` | Key data absent — score is best-effort estimate only |

---

*Sources for scoring threshold values in this document: `germany/tax-investment.md` (Sparerpauschbetrag limits, Vorabpauschale formula, Abgeltungssteuer rates, Teilfreistellung rates), `brazil/tax-investment.md` (DARF rules, PGBL 12% limit, IR progressive table), `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md` (allocation targets, emergency fund threshold).*
