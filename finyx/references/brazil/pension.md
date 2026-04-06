---
tax_year: 2025
country: brazil
domain: pension
last_updated: 2026-04-06
source: "Receita Federal, Lei 11.053/2004, Lei 14.803/2024, INSS"
---

# Brazilian Pension Reference

This document covers PGBL vs VGBL decision logic, progressive vs regressive IR regime selection, and INSS expat status handling for the `/finyx:pension` command. All rules reflect 2025 Receita Federal guidance.

> **Staleness check:** This document applies to `tax_year: 2025`. If the current year differs, verify the PGBL 12% threshold, regime table rates, and INSS contribution rules against current Receita Federal guidance before acting.

---

## 1. PGBL vs VGBL Decision Logic

### Eligibility for PGBL Deduction

To qualify for the PGBL contribution deduction, **both** of the following conditions must be true:

1. **Files declaração completa (modelo completo)** — NOT declaração simplificada. The simplificada applies a flat 20% deduction that cannot be supplemented by PGBL.
2. **Has active INSS or statutory pension contribution** in the same calendar year (e.g., employee contributing to INSS via employment, or self-employed making voluntary INSS contributions).

### PGBL Deduction Rule

- Maximum deductible: **12% of taxable gross annual income**
- Command reads `countries.brazil.gross_income` from profile (D-12)
- Declaration code: Payments/Donations — **code 36** on DIRPF
- Tax base at withdrawal: **FULL amount** (principal + accumulated gains)

```
pgbl_max_deduction = 0.12 × countries.brazil.gross_income
```

### When to Use VGBL Instead

Use VGBL (not PGBL) when any of the following applies:

- User files declaração simplificada
- User has already maxed the 12% PGBL deduction limit with other PGBL contributions
- User is investing primarily for long-term gains rather than current-year IR deduction
- User has no active INSS or statutory pension contribution

**Tax base at VGBL withdrawal: GAINS ONLY** (not principal). This is the critical distinction from PGBL.

### Decision Tree

```
if ir_regime == "completa"
   AND has_inss_or_statutory_contribution == true
   AND 0.12 × gross_income > 0
then → PGBL (up to 12% of gross income), then VGBL for any additional private pension contributions
else → VGBL
```

---

## 2. Progressive vs Regressive IR Regime

### Regressive Table (by contribution age per tranche)

| Accumulation period per tranche | IR Rate |
|---------------------------------|---------|
| Up to 2 years | 35% |
| 2–4 years | 30% |
| 4–6 years | 25% |
| 6–8 years | 20% |
| 8–10 years | 15% |
| Above 10 years | **10%** |

> **Important:** The rate applies **per tranche**, not per total balance. Each contribution tranche ages independently. A contribution made 11 years ago is taxed at 10% even if other contributions were made only 2 years ago (which would be taxed at 35%).

### Progressive Table

Applies the standard IR tabela progressiva at the point of withdrawal:

| Annual income band at withdrawal | IR Rate |
|----------------------------------|---------|
| Up to R$24,511.92 (2025 exempt band) | 0% |
| R$24,511.92 – R$33,919.80 | 7.5% |
| R$33,919.80 – R$45,012.60 | 15% |
| R$45,012.60 – R$55,976.16 | 22.5% |
| Above R$55,976.16 | 27.5% |

The effective rate depends on the total annual withdrawal amount. Favorable for small withdrawals (early retirement, low income, or withdrawing only partial pension funds).

### Law 14.803/2024 — Regime Choice Deferral (CRITICAL)

Since Law 14.803/2024 (effective 2024), the progressive vs regressive regime choice can be **deferred to the moment of withdrawal or benefit receipt**. Previously the choice had to be made at contract inception.

**Advisory implication:** Users no longer need to commit upfront. Recommend deferring the decision until closer to retirement unless the user has a clear long-horizon commitment (>10 years, where regressive almost certainly wins).

### Decision Guidance

| Scenario | Recommended regime |
|----------|--------------------|
| Long horizon (>10 years) + high withdrawal income | Regressive — 10% vs up to 27.5% top rate |
| Short horizon (<4 years) | Progressive — may win if withdrawal income is low |
| Low expected withdrawal amount | Progressive — 0% band and lower brackets may apply |
| Uncertain horizon | Defer (Law 14.803/24 now allows this) |

---

## 3. INSS Expat Status (Cross-Country Projection)

### Brazil-Germany Bilateral Agreement

The Brazil-Germany social security totalization agreement has been in force **since 2013**. Key effects:

- Contribution periods in INSS (Brazil) and Deutsche Rentenversicherung (Germany) can be **combined (totalizados)** to meet minimum contribution requirements in either system
- Each country calculates and pays its proportional benefit independently — proportional to actual contributions made in that country
- Minimum for DE statutory pension: 5 years of contributions to Deutsche Rentenversicherung (Wartezeit 5 Jahre)

### INSS Status Enum (D-06)

Users self-report their INSS status using one of three values:

| Status | Meaning |
|--------|---------|
| `"active"` | User is currently contributing to INSS (via Brazilian employer, or voluntary contributions from abroad) |
| `"suspended"` | User is not currently contributing; prior contributions remain on record |
| `"totalization"` | User intends to use the DE-BR agreement to combine contribution periods |

> **Advisory scope (D-06):** The `/finyx:pension` command does NOT compute INSS benefit entitlement. It prompts the user to declare their status, explains what each status means for the projection, and appends the D-07 disclaimer. Entitlement computation depends on full contribution history and legal treaty interpretation — out of advisory scope.

### What Each Status Means for the Projection

- **active:** User may receive a BR-side pension benefit independently. Monthly estimate is self-reported.
- **suspended:** Prior contributions are preserved. The BR benefit is locked and will be available at Brazilian retirement age. Amount uncertain — user provides self-reported estimate or leaves blank.
- **totalization:** Combined contribution periods will be used to qualify for benefits in one or both countries. Each country pays proportionally. Amounts highly uncertain — require legal verification.

### D-07 Disclaimer (verbatim — always append to cross-country projections involving INSS)

> Cross-border pension entitlements require verification by a Brazilian social security lawyer (advogado previdenciário). This projection is an illustrative estimate only — actual benefits depend on contribution history, treaty application, and regulatory changes in both countries.

### Default Real Return Rate

- BR private pension projection: **2.0% real (inflation-adjusted, after IPCA) annual return** per D-04
- Overridable via profile field: `pension.expected_real_return_br`

---

## 4. Cross-Country Projection Constants (BR Side)

### Real Return Rate

```
default_real_return_br = 2.0   # percent, real (after IPCA), per D-04
user_override_field    = pension.expected_real_return_br
```

### INSS Monthly Benefit

INSS monthly benefit estimate is **self-reported by the user** — not computed by the command. Prompt the user at runtime:

```
"What is your estimated monthly INSS benefit at retirement (in BRL)?
If unsure, enter 0 and we will note it as unknown in the projection."
```

### Projection Formula

```
real_accumulated = current_value × (1 + real_rate / 100) ^ years_to_retirement
```

Where:
- `current_value` = current PGBL/VGBL balance (from profile holdings or user input)
- `real_rate` = `pension.expected_real_return_br` (default 2.0%)
- `years_to_retirement` = `pension.target_retirement_age - current_age`

---

*Source: Receita Federal (PGBL 12% deduction rule, declaração completa requirement), Lei 11.053/2004 (PGBL/VGBL legal framework), Lei 14.803/2024 (regime choice deferral), INSS / Ministério da Previdência Social (bilateral agreement). Multiple sources agree on regressive table rates; verify against current Receita Federal publications before acting.*
