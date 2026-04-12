---
tax_year: 2025
country: brazil
domain: investment-tax
last_updated: 2026-04-06
source: Receita Federal, Lei 8.668/1993, Lei 15.270/2025
---

# Brazilian Investment Tax Reference

This document covers IR (Imposto de Renda) rules for individual investors in Brazil, including filing obligations by asset type, DARF calculation mechanics, come-cotas, and FII dividend exemption rules. All amounts in Brazilian Reais (BRL).

> **Staleness check:** This document applies to `tax_year: 2025`. If the current year differs, verify rates and rules against current Receita Federal guidance before acting.

---

## 1. IR Rates by Investment Type (BRTAX-01)

| Asset Type | Tax Rate | Exemption | Withholding | Notes |
|---|---|---|---|---|
| Stocks — normal operations | 15% on net gain | R$20,000/month in sales volume (see note) | Self-reported via DARF | Exemption is for normal ops ONLY — not day-trade |
| Stocks — day-trade | 20% on net gain | None | 1% at source (IRF-F); remainder via DARF | Day-trade NEVER benefits from R$20k exemption |
| FIIs — capital gains (sell) | 20% on net gain | None | Self-reported via DARF | Sell gains always taxable; dividends treated separately |
| FIIs — dividends | Exempt (base rule) | Full exemption under Law 8,668/1993 | N/A | See Section 4 for Law 15,270/2025 changes |
| CDB | Regressive table (see below) | None | Withheld at source by bank | No DARF required for CDB held to maturity |
| LCI / LCA | Exempt | Full exemption for individual investors | N/A | Must still declare under Rendimentos Isentos |
| Previdencia PGBL | Progressive or regressive regime | Contributions deductible up to 12% of gross income | Withheld at redemption | Tax applies to the full withdrawal amount (contributions + gains) |
| Previdencia VGBL | Regressive table on gains only | Contributions NOT deductible | Withheld at redemption | Better for users who already max 12% deduction or use declaracao simplificada |

### R$20,000/Month Exemption — Critical Rules

- Applies **only** to normal stock operations (operacoes comuns).
- Does **not** apply to day-trade operations under any circumstance.
- Calculated on **total sales volume** in the calendar month, not on gains. If total sales exceed R$20,000, the entire net gain is taxable (there is no partial exemption on the R$20k threshold itself).
- FII sell gains are **not** covered by this exemption — FII capital gains are always taxable at 20%.

### CDB Regressive Rate Table

| Holding Period | IR Rate |
|---|---|
| Up to 6 months | 22.5% |
| 6 to 12 months | 20% |
| 12 to 24 months | 17.5% |
| More than 24 months | 15% |

Tax is withheld at source by the issuing bank. No separate DARF is required.

### PGBL vs VGBL Decision Summary

| Factor | PGBL | VGBL |
|---|---|---|
| Contribution deductibility | Up to 12% of gross income (declaracao completa) | Not deductible |
| Tax base at redemption | Full amount (contributions + gains) | Gains only |
| Best for | Users with declaracao completa who haven't hit 12% limit | Users using declaracao simplificada, or already at 12% limit |
| Regime options | Progressive (tabela progressiva) or regressive | Regressive table (standard) |

---

## 2. DARF Calculation and Deadlines (BRTAX-02)

### What is DARF?

DARF (Documento de Arrecadacao de Receitas Federais) is the federal tax payment slip used to settle IR on investment gains that are not withheld at source. Investors are responsible for calculating and paying their own DARF monthly.

### Calculation Formula

```
Monthly gain = Total sales proceeds - Cost basis of sold positions

Tax due = Monthly gain x applicable rate (15% normal / 20% day-trade / 20% FII)

If normal stock operations AND total monthly sales volume <= R$20,000 -> Tax due = R$0 (exempt)
If normal stock operations AND total monthly sales volume > R$20,000 -> Full gain is taxable
```

### DARF Codes

| Code | Applies To |
|---|---|
| 6015 | Normal stock operations and FII capital gains |
| 3317 | Day-trade operations (stocks, options, futures) |

### Payment Deadlines

- **Due date:** Last business day of the calendar month **following** the month in which the gain was realized.
  - Example: Gains realized in March -> DARF due by the last business day of April.
- **Minimum DARF value:** R$10.00. If calculated tax is less than R$10, carry forward and add to the next month's obligation.

> **Monthly reminder:** Set a calendar reminder for the last business day of each month to check for unreported gains from the prior month.

### Late Payment Penalties

- **Daily interest:** 0.33% per day, capped at 20% of the principal.
- **Selic-based correction:** In addition to the 20% cap, Selic interest applies from the due date.
- **How to pay:** Via your banking app (boleto or Pix), the Receita Federal portal (receita.fazenda.gov.br), or the SICALC tool (available on the Receita Federal website) for calculation assistance.

---

## 3. Come-Cotas (BRTAX-03)

### What Is Come-Cotas?

Come-cotas is a mechanism by which the Receita Federal collects income tax in advance from open-end investment funds (fundos de investimento abertos). Rather than waiting for the investor to redeem shares, the fund itself withholds the tax twice a year by redeeming a portion of each investor's quotas (shares) — hence the name "come-cotas" (quota-eater).

### When Does It Happen?

- **Twice per year:** last business day of May and last business day of November.

### Applicable Rates

| Fund Classification | Come-Cotas Rate |
|---|---|
| Short-term funds (carteira de curto prazo) | 20% |
| Long-term funds (carteira de longo prazo) | 15% |

The fund administrator determines the fund's classification.

### Mechanism

1. The fund calculates the IR accrued on gains since the last come-cotas event (or since the investor's purchase date).
2. The equivalent number of quotas (valued at that day's NAV) is redeemed to cover the tax.
3. The investor sees fewer quotas on their statement — no cash is deducted from their account.
4. At final redemption, the come-cotas already paid is credited. The investor pays only the **difference** between total tax owed at redemption and what was already collected via come-cotas.

### Scope: What Come-Cotas Applies To

Come-cotas applies to: Fundos de Renda Fixa, Fundos Multimercado, and similar CVM-regulated open-end funds.

**Come-cotas does NOT apply to:**
- FIIs (Fundos de Investimento Imobiliario) — FIIs are closed-end and governed by different rules.
- ETFs (Exchange-Traded Funds) listed on B3 — ETFs follow the normal sale-gain regime.
- CDBs, LCIs, LCAs held directly (not through a fund wrapper).

> **Key distinction:** Come-cotas and FII dividend exemption are completely separate mechanisms. Do not confuse them — come-cotas eats your fund quotas; FII dividends are exempt cash distributions (subject to conditions in Section 4).

---

## 4. FII Dividend Exemption (BRTAX-04 / BRTAX-05)

### Base Rule — Law 8,668/1993

FII dividends (rendimentos distribuidos) distributed to individual investors are **exempt from IR**, provided both conditions are met:

1. **Minimum quotaholders:** The FII has at least **50 quotaholders**.
2. **Holding limit:** The individual investor holds **10% or less** of the total quotas, and their quotas do not entitle them to more than 10% of the fund's income.

Most B3-listed FIIs with significant retail participation satisfy the 50-quotaholder requirement. Individual retail investors rarely approach the 10% threshold.

### Capital Gains on FII Sales

FII capital gains (the profit from selling quotas at a price higher than the acquisition cost) are **not** exempt. They are taxed at **20%** and must be reported and paid via DARF (code 6015) by the last business day of the month following the sale. The R$20k/month sales volume exemption does **not** apply to FII capital gains.

### Law 15,270/2025 Changes (Effective 2026-01-01)

Law 15,270/2025 introduces a new "FII qualificado" (qualified FII) category and alters dividend treatment for certain fund types:

- FIIs that do not qualify under the new "FII qualificado" criteria may face a **15% withholding** on dividend distributions, even if they previously distributed exempt dividends.
- The 50-quotaholder and 10%-holding conditions from Law 8,668/1993 remain the baseline conditions for any exemption.
- The exact qualification criteria for "FII qualificado" status are defined in Law 15,270/2025 and subsequent CVM/Receita Federal regulation.

> **Disclaimer (D-12):** The exact interaction between Law 15,270/2025 and the existing exemption for standard listed FIIs has not been fully confirmed by Receita Federal guidance as of the date of this document (2026-04-06). The law is effective from 2026-01-01, but implementation regulations may still be pending. Verify with a contador before acting on FII dividend treatment for the 2026 tax year. This advisory does not constitute tax advice — see the legal disclaimer.

### Annual IR Declaration Requirements

FII dividends must be declared in your annual IR filing even when exempt from taxation:

- **Declaration category:** Rendimentos Isentos e Nao Tributaveis (Exempt and Non-Taxable Income)
- Failure to declare exempt income is a filing error and may trigger a notification from Receita Federal.
- Your FII distributor or custodian broker provides an Informe de Rendimentos report (typically in February/March) listing all dividends received in the prior calendar year.

---

## 5. Cross-Border Notes for DE+BR Investors (D-11)

> This section applies when `cross_border: true` in your Finyx profile.

- **DBA (Double Taxation Agreement):** Brazil and Germany have a tax treaty that prevents double taxation. In general, investment income sourced in Brazil is taxed in Brazil first; Germany applies a credit for Brazilian tax already paid against any German tax obligation on the same income.
- **Brazilian withholding on investment income for non-residents:** 15% standard withholding rate applies to most investment income paid to non-resident investors (e.g., dividends, interest, capital gains). Specific rates may vary by income type.
- **German residents with Brazilian investments:** Must declare all foreign income on their German IR return (Anlage KAP for capital income, Anlage AUS for foreign income). German Abgeltungssteuer applies, with DBA credit reducing the German tax due.
- **Full DBA interaction detail** — including residency tiebreaker rules and withholding credit mechanics — is surfaced by the `/finyx:tax` command when cross-border mode is active. See `skills/tax/references/germany/tax-investment.md` for the German-side treatment.

---

## 6. Important Notes

### Always Remember

- **R$20k exemption: normal operations ONLY.** Day-trade gains are always fully taxable regardless of monthly volume.
- **Come-cotas vs FII dividends:** These are different mechanisms for different products. Come-cotas applies to open-end funds; FII dividends are a separate cash distribution from a closed-end real estate vehicle.
- **PGBL vs VGBL decision:** The right product depends on your IR regime and whether you have remaining room under the 12% gross income deduction limit.
- **All FII dividends must be declared annually.** Exempt income still appears in the annual DIRPF filing under Rendimentos Isentos e Nao Tributaveis.
- **DARF is self-reported.** No automatic reminders from Receita Federal. Missing a payment accrues penalties from the first day past the deadline.

### Out of Scope (Deferred — D-12)

The following topics are explicitly out of scope for this document and will be addressed in future phases:

- INSS (social security) contribution rules for Brazilians working in Germany — complex expat treatment, deferred to Phase 4 pension planning.
- FII exemption edge cases under Law 15,270/2025 beyond the base guidance above — pending Receita Federal clarification.

---

## Legal Disclaimer

${CLAUDE_SKILL_DIR}/references/disclaimer.md

Tax rules, rates, and laws change frequently. This document applies to `tax_year: 2025`. Verify all rules against current Receita Federal guidance, particularly for Law 15,270/2025 which became effective 2026-01-01 and may have subsequent regulatory implementation guidance. Consult a contador before making decisions that depend on FII dividend exemption treatment under the new law.
