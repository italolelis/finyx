---
name: finyx:tax
description: Investment tax advisor — German and Brazilian tax guidance based on your financial profile
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<objective>

Deliver personalized investment tax guidance based on the user's financial profile.

This command:
1. Reads `.finyx/profile.json` and detects which countries are active
2. Checks reference doc tax year against the current year and warns if stale
3. For Germany: explains Steuerklasse recommendation, Abgeltungssteuer breakdown, Sparerpauschbetrag tracking, Vorabpauschale calculation, and Teilfreistellung rates
4. For Brazil: covers IR rates by asset type, DARF calculation with codes and deadlines, come-cotas mechanics, and FII dividend exemption rules
5. For cross-border users: surfaces DBA residency tiebreaker, withholding credit mechanics, and double-dip prevention

Output is conversational advisory text — no files are written. All guidance includes the legal disclaimer.

</objective>

<execution_context>

@~/.claude/finyx/references/disclaimer.md
@~/.claude/finyx/references/germany/tax-investment.md
@~/.claude/finyx/references/germany/health-insurance.md
@~/.claude/finyx/references/brazil/tax-investment.md
@.finyx/profile.json

</execution_context>

<process>

## Phase 1: Validation

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Read `.finyx/profile.json`** and extract:
- `identity.cross_border` — cross-border flag
- `identity.family_status` — "single" or "married" (determines Sparerpauschbetrag allowance)
- `countries.germany.tax_class` — null means Germany not active
- `countries.germany.church_tax` — boolean
- `countries.germany.marginal_rate` — decimal percentage
- `countries.germany.brokers` — array of broker objects
- `countries.brazil.ir_regime` — null means Brazil not active

**Determine active countries:**
- Germany active if: `countries.germany.tax_class != null`
- Brazil active if: `countries.brazil.ir_regime != null`
- Cross-border if: `identity.cross_border == true`

**If neither country is active:**
```
ERROR: No country tax data found in your profile.

Run /finyx:profile to complete the country-specific sections
(German tax class or Brazilian IR regime must be set).
```
Stop here.

## Phase 2: Tax Year Staleness Check

```bash
CURRENT_YEAR=$(date +%Y)
echo "Current year: $CURRENT_YEAR"
```

The loaded reference docs have `tax_year: 2025` in their frontmatter.

If `CURRENT_YEAR != 2025` (i.e., the reference docs' tax year), output this warning before any advisory content:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► TAX: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reference docs are from tax year 2025. Current year is [CURRENT_YEAR].
Tax rules, rates, and thresholds may have changed.
Verify all guidance against official BMF / Receita Federal sources
before making any decisions based on this output.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 3: German Investment Tax

*Execute this phase only if Germany is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► TAX: GERMAN INVESTMENT TAX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.1 Steuerklasse

Read `countries.germany.tax_class` from profile.

Using the Steuerklassen table from the loaded reference doc, show:
- What the user's current class means (who it applies to, key characteristics)
- Whether it is the optimal choice for their situation

Recommendation logic (from reference doc Section 1):
- Class I: standard for single, divorced, widowed — generally optimal
- Class II: requires active filing with Finanzamt if user is a single parent with custody
- Classes III/V pair: if married and income gap is > 3:1, this pair minimizes monthly withholding
- Classes IV/IV: if married, similar incomes — symmetric and avoids large year-end adjustments
- IV with factor method: if married with moderate income gap — recommend over pure IV/IV to reduce year-end settlement
- Class VI: secondary employment — cannot be changed

**Important note to always include:**
> Steuerklasse affects employment income withholding only — it does NOT affect how your investment income is taxed. Capital gains are taxed at the flat Abgeltungssteuer rate regardless of your class. However, your marginal rate (affected by class and income level) determines whether you qualify for the Günstigerprüfung.

If user is married, add: "Consider whether Class III/V (if large income gap) or IV/IV or IV with factor (if similar incomes) better fits your situation. The choice affects your monthly payslip and year-end tax settlement but not your investment income tax."

### 3.2 Abgeltungssteuer Breakdown

Using reference doc Section 2, show the full flat tax calculation for this user:

```
Flat rate:                    25.000%
Solidaritätszuschlag:          1.375%  (5.5% of 25%)
Effective rate (no KiSt):     26.375%
```

If `countries.germany.church_tax == true`:
```
+ Church tax (state rate):    +1.444% or +1.620%  (8% or 9% of 25%)
Effective rate (with KiSt):   27.819% or 27.995%
```
Note: Show the applicable rate based on user's state if known from profile; otherwise show both variants.

**Günstigerprüfung check:**
Compare user's `countries.germany.marginal_rate` against 26.375%.

If `marginal_rate < 26.375`:
```
Your marginal rate ([marginal_rate]%) is BELOW the flat investment tax rate (26.375%).
You are eligible for Günstigerprüfung (Anlage KAP).

File Anlage KAP with Günstigerprüfung checked, and the Finanzamt will
recalculate your capital income at your lower [marginal_rate]% marginal rate
and refund the difference. Relevant for students, part-time workers,
low-income years, and early retirement.
```

If `marginal_rate >= 26.375`:
```
Your marginal rate ([marginal_rate]%) exceeds the flat rate (26.375%).
Günstigerprüfung would not help you — your capital gains are already taxed
at a lower effective rate than your income tax rate.
```

### 3.3 Teilfreistellung (Partial Fund Exemption)

Using reference doc Section 4, show the full fund type table:

| Fund Type | Stock Allocation | Exemption | Effective Rate* |
|-----------|-----------------|-----------|-----------------|
| Equity funds (Aktienfonds) | >50% stocks | 30% | ~18.46% |
| Mixed funds (Mischfonds) | 25–50% stocks | 15% | ~22.42% |
| Bond/other funds | <25% stocks | 0% | 26.375% |
| Real estate funds — DE (>50% DE property) | — | 60% | ~10.55% |
| Real estate funds — Foreign (>50% non-DE) | — | 80% | ~5.28% |

*Effective rates without church tax.

Key reminders:
- Teilfreistellung applies to distributions, capital gains on sale, AND Vorabpauschale — all taxable fund events
- Teilfreistellung does NOT apply to individual stock dividends or stock gains — only to ETF/fund income
- Most globally-diversified MSCI World ETFs qualify as Aktienfonds (30% exemption)

Ask the user: "What types of funds do you currently hold?" and apply the correct Teilfreistellung rate to their scenario if they share specifics.

### 3.4 Sparerpauschbetrag Tracking

**Determine allowance:**
- If `identity.family_status == "married"`: allowance = 2,000 EUR
- Otherwise: allowance = 1,000 EUR

**Read brokers data:**
Read `countries.germany.brokers` from profile.

**If brokers array is empty or not set:**
Use AskUserQuestion to collect broker data:

```
To track your Sparerpauschbetrag (annual tax-free investment income allowance),
I need to know about your German broker accounts.

For each broker, I need:
1. Broker name (e.g., Trade Republic, ING, Scalable)
2. Freistellungsauftrag allocated to this broker (in EUR)
3. Estimated annual capital income from this broker (dividends + interest + capital gains, in EUR)

How many German broker accounts do you have?
```

Collect data for each broker. Offer to save to `.finyx/profile.json` via Write:
```
Would you like me to save this broker information to your profile so you
don't need to re-enter it next time?
```

If yes, update the `countries.germany.brokers` array in `.finyx/profile.json`.

**Calculate and output Sparerpauschbetrag report:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SPARERPAUSCHBETRAG REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Annual allowance ([family_status]):    [1,000 or 2,000] EUR

Broker Freistellungsauftrag:

| Broker | Freistellungsauftrag | Est. Annual Income |
|--------|---------------------|-------------------|
| [name] | [amount] EUR        | [amount] EUR      |
| ...    | ...                 | ...               |
| TOTAL  | [sum] EUR           | [sum] EUR         |

Allowance remaining (est.): [allowance - sum(estimated_annual_income)] EUR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Warnings (check both conditions):**

If `sum(freistellungsauftrag) > allowance`:
```
WARNING: Your total Freistellungsauftrag ([sum] EUR) EXCEEDS your annual
allowance ([allowance] EUR). This violates §44a EStG and may trigger a
Finanzamt query. Reduce your allocations across brokers immediately.
Total must not exceed [allowance] EUR.
```

If `sum(estimated_annual_income) > allowance`:
```
NOTICE: Your estimated annual investment income ([sum] EUR) may exceed your
allowance ([allowance] EUR). Income above the threshold will be taxed at
the full Abgeltungssteuer rate. Review your expected income per broker
and allocate Freistellungsauftrag accordingly.
```

**Strategy tips:**
- Allocate the largest Freistellungsauftrag to the broker where you expect the most capital income
- Accumulating ETFs consume allowance via Vorabpauschale in January — factor this in
- Savings account interest counts against the allowance — don't forget it
- Check mid-year via broker dashboards and reallocate if one broker uses more than expected

### 3.5 Vorabpauschale

Using reference doc Section 5, walk through the calculation.

**Ask the user:**
```
Do you hold any accumulating (thesaurierend) ETFs in Germany?
If yes, what was the approximate total value of your accumulating ETF holdings
on January 1 of the current tax year?
```

If user provides ETF value, compute and show:

```
Vorabpauschale Calculation (2025 tax year)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ETF value on Jan 1, 2025:          [user_value] EUR
Basiszins 2025:                    2.29%
Basisertrag:  [user_value] × 2.29% × 0.70 = [basisertrag] EUR

Actual ETF gain in 2025:
  (You can check your broker dashboard for the year-end fund value
   and subtract the Jan 1 value)

Vorabpauschale = min(Basisertrag, actual gain)
              = min([basisertrag], [gain_if_known]) = [vorabpauschale] EUR

For an equity ETF (30% Teilfreistellung):
  Taxable: [vorabpauschale] × 0.70 = [taxable] EUR
  Tax due: [taxable] × 26.375% = [tax_due] EUR
```

If user does not hold accumulating ETFs, briefly explain the concept and confirm they do not need to worry about it.

**Key practical notes to always include:**
- The broker automatically deducts Vorabpauschale tax in January for the prior year
- Keep a cash buffer in your broker account — if insufficient cash, the broker may sell fund units
- The taxed Vorabpauschale increases your cost basis and will not be double-taxed at sale
- For accumulating ETFs at a foreign broker (Trading212, IBKR): the broker does NOT withhold — declare manually on Anlage KAP-INV

**Basiszins reference:**
| Tax year | Basiszins | Tax deducted |
|----------|-----------|--------------|
| 2025 | 2.29% | January 2026 |
| 2026 | 3.20% | January 2027 |

> Note: Verify 2026 Basiszins against current BMF publication before filing.

### 3.6 PKV Basisabsicherung Deduction (§10 EStG)

*Execute this subsection only if `insurance.type == "PKV"` in `.finyx/profile.json`. If insurance section is absent, null, or type is not "PKV": skip entirely.*

Using health-insurance.md Section 5 (loaded via `@~/.claude/finyx/references/germany/health-insurance.md`), show the PKV tax deduction calculation:

**Read from profile:**
- `insurance.monthly_cost` — total PKV monthly premium
- `insurance.employer_share` — employer contribution (0 if self-employed)
- `countries.germany.marginal_rate` — marginal tax rate

**Determine cap:**
- If employer_share > 0: employee cap = €1,900/year
- If employer_share == 0: self-employed cap = €2,800/year

**Calculate and display:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PKV BASISABSICHERUNG DEDUCTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PKV monthly premium:                [monthly_cost] EUR
Employer share:                     [employer_share] EUR
Net monthly cost:                   [monthly_cost - employer_share] EUR

Basisabsicherung estimate (85%):    [net × 0.85] EUR/month
Annual deductible:                  min([basis × 12], [cap]) = [annual_deductible] EUR
Deduction cap ([employee/self-employed]):  [1,900 or 2,800] EUR

Tax benefit at [marginal_rate]%:    [annual_deductible × marginal_rate] EUR/year
Monthly tax saving:                 [tax_benefit / 12] EUR/month
Effective net PKV cost:             [monthly_cost - employer_share - (tax_benefit/12)] EUR/month
```

**Key notes to include:**
- The Basisabsicherung portion (typically 80–90% of premium) covers only basic health coverage — not Zusatzleistungen, Krankentagegeld, or Zahnzusatz
- The §10 EStG cap of €1,900/€2,800 is usually reached quickly for PKV premiums above €200/month
- From 2026, insurers transmit Basisabsicherung data via ELStAM for employees — self-employed still file via Anlage Vorsorgeaufwand
- This deduction is separate from investment tax — it reduces total taxable income, indirectly benefiting all income types

**Cross-reference:**
> For full PKV vs GKV cost comparison and long-term projections, run `/finyx:insurance`.

## Phase 4: Brazilian Investment Tax

*Execute this phase only if Brazil is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► TAX: BRAZILIAN INVESTMENT TAX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4.1 IR Filing Guidance by Asset Type

Using reference doc Section 1, present the tax treatment for each investment type.

Show the full rate table from the reference doc:

| Asset Type | Tax Rate | Exemption | Withholding |
|-----------|---------|-----------|-------------|
| Stocks — normal | 15% on net gain | R$20k/month sales volume | Self-reported via DARF |
| Stocks — day-trade | 20% on net gain | None | 1% IRF-F + DARF for remainder |
| FIIs — capital gains | 20% on net gain | None | Self-reported via DARF |
| FIIs — dividends | Exempt (base rule) | Full exemption (Law 8,668/1993) | N/A — see Section 4.4 |
| CDB | Regressive table | None | Withheld at source by bank |
| LCI / LCA | Exempt | Full exemption | Must declare under Rendimentos Isentos |
| Previdência PGBL | Progressive or regressive | Contributions deductible up to 12% of gross income | Withheld at redemption |
| Previdência VGBL | Regressive on gains only | Contributions NOT deductible | Withheld at redemption |

**CDB regressive rate table:**
| Holding Period | IR Rate |
|---|---|
| Up to 6 months | 22.5% |
| 6 to 12 months | 20% |
| 12 to 24 months | 17.5% |
| More than 24 months | 15% |

**R$20k exemption — critical rules:**
- Applies ONLY to normal stock operations (not day-trade, not FIIs)
- Calculated on total SALES VOLUME per month, not on gains
- If sales volume exceeds R$20k, the ENTIRE net gain is taxable — no partial exemption on the threshold

Focus on asset types the user mentions or that are relevant given their profile context.

### 4.2 DARF Calculation

Using reference doc Section 2, walk through the monthly calculation:

```
Monthly DARF Calculation
━━━━━━━━━━━━━━━━━━━━━━━━

Monthly gain = Total sales proceeds − Cost basis of sold positions

Normal stocks (monthly sales ≤ R$20,000):   Tax = R$0 (exempt)
Normal stocks (monthly sales > R$20,000):   Tax = Monthly gain × 15%
Day-trade operations:                        Tax = Monthly gain × 20%
FII capital gains:                           Tax = Monthly gain × 20%
```

**DARF codes:**
| Code | Applies To |
|------|-----------|
| 6015 | Normal stock operations + FII capital gains |
| 3317 | Day-trade (stocks, options, futures) |

**Payment deadline:**
Last business day of the calendar month FOLLOWING the month of the gain.
Example: Gains in March → DARF due by last business day of April.

Minimum DARF value: R$10. If calculated tax < R$10, carry forward to next month.

**Late payment penalties:**
- Daily interest: 0.33% per day, capped at 20% of principal
- Plus Selic-based correction from the due date

> Set a monthly reminder for the last business day of each month to check for unreported gains from the prior month. DARF is fully self-reported — Receita Federal sends no reminders.

### 4.3 Come-Cotas

Using reference doc Section 3, explain the mechanism:

**What it is:** Come-cotas is a twice-yearly tax pre-collection mechanism for open-end investment funds. The fund redeems a portion of each investor's quotas to cover accrued IR — hence "come-cotas" (quota-eater).

**When it happens:** Last business day of May and last business day of November.

**Rates:**
| Fund Classification | Come-Cotas Rate |
|---|---|
| Short-term funds | 20% |
| Long-term funds | 15% |

**How it works:**
1. Fund calculates IR accrued on gains since last come-cotas (or purchase date)
2. Equivalent number of quotas (at current NAV) are redeemed to cover the tax
3. Investor sees fewer quotas on statement — no cash deducted from account
4. At final redemption, come-cotas already paid is credited against total tax owed

**CRITICAL SCOPE DISTINCTION — always include:**
> Come-cotas applies ONLY to open-end CVM-regulated funds (Fundos de Renda Fixa, Fundos Multimercado, etc.).
>
> Come-cotas does NOT apply to:
> - FIIs (closed-end real estate funds) — governed by different rules
> - ETFs listed on B3 — follow the normal sale-gain regime
> - CDBs, LCIs, LCAs held directly (not through a fund wrapper)

### 4.4 FII Dividend Exemption

Using reference doc Section 4, show both the base rule and the Law 15,270/2025 changes:

**Base rule — Law 8,668/1993:**
FII dividends distributed to individual investors are EXEMPT from IR, provided:
1. The FII has at least 50 quotaholders
2. The individual investor holds 10% or less of total quotas (and is entitled to ≤10% of income)

Most B3-listed FIIs with retail participation satisfy both conditions.

**FII capital gains (selling quotas) are NOT exempt:**
FII gains are taxed at 20% via DARF code 6015. The R$20k/month sales volume exemption does NOT apply to FII capital gains.

**Law 15,270/2025 changes (effective 2026-01-01):**
- Introduces "FII qualificado" (qualified FII) category
- FIIs that do not qualify may face 15% withholding on dividend distributions, even if previously exempt
- 50-quotaholder and 10%-holding conditions from Law 8,668/1993 remain baseline conditions for any exemption
- Exact "FII qualificado" criteria defined in Law 15,270/2025 and subsequent CVM/Receita Federal regulation

**Mandatory D-12 disclaimer:**
> The interaction between Law 15,270/2025 and the standard listed FII exemption has not been fully confirmed by Receita Federal guidance as of early 2026. The law became effective 2026-01-01, but implementation regulations may still be pending. Verify with a contador before acting on FII dividend treatment for the 2026 tax year. This advisory does not constitute tax advice.

**Annual declaration requirement:**
FII dividends MUST be declared in your annual DIRPF filing even when exempt:
- Declaration category: Rendimentos Isentos e Nao Tributaveis
- Your FII custodian broker provides an Informe de Rendimentos in February/March
- Failure to declare exempt income is a filing error

## Phase 5: Cross-Border DBA Guidance

*Execute this phase only if `identity.cross_border == true`.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► TAX: CROSS-BORDER (DE–BR) TAX INTERACTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5.1 Residency Tiebreaker (OECD Art. 4)

When you have connections to both Germany and Brazil, the tax treaty (DBA) determines which country has primary taxing rights over your income. The tiebreaker rules apply in this order:

1. **Permanent home:** Where do you have a permanent home available? If only one country — that country wins.
2. **Habitual abode:** Where do you spend more time? If Germany → German resident for treaty purposes.
3. **Nationality:** If habitual abode is tied — nationality determines residence.
4. **Mutual agreement:** If all else is tied — the tax authorities of both countries negotiate.

In practice: if you live and work primarily in Germany, you are a German tax resident under the DBA, even if you retain Brazilian nationality and assets.

### 5.2 Withholding Credit Mechanics

**German resident with Brazilian investment income:**
- Brazil withholds tax at source (standard: 15% for non-residents)
- Report all Brazilian capital income on Anlage KAP and Anlage AUS in your German tax return
- German Abgeltungssteuer (26.375%) applies, with the Brazilian withholding credited as a deduction
- Effective additional German tax = 26.375% − 15% = ~11.375% (before Teilfreistellung adjustments)

**Brazilian resident with German investment income:**
- German brokers withhold Abgeltungssteuer at 26.375%
- Report German income in your Brazilian DIRPF annual filing
- Credit the German withholding against Brazilian IR obligation on the same income
- FIIs with Brazilian-side income are not affected by German withholding

### 5.3 Double-Dip Prevention

Do NOT claim the same income as fully exempt in both jurisdictions. The DBA prevents double taxation — it does not allow double exemption.

Common mistake: treating FII dividends as exempt in Brazil AND not declaring them in Germany. If you are a German resident, FII income must be declared on Anlage KAP (it is exempt from Brazilian IR, but you still owe German tax on it after applying the DBA credit mechanism).

### 5.4 Scope Disclaimer

> This is basic DBA guidance covering residency tiebreaker and withholding credit mechanics. For complete cross-border tax analysis — especially for year-of-move scenarios, split-year assessments, or assets in multiple asset classes — consult a Steuerberater with international tax experience or a contador with DBA expertise.
>
> Out of scope for this version (D-12): INSS expat treatment for Brazilians in Germany, and FII exemption edge cases under Law 15,270/2025.

## Phase 6: Disclaimer

Append the full legal disclaimer from the loaded `disclaimer.md` reference at the end of all advisory output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No country data in profile:**
```
ERROR: No country tax data found in your profile.
Your profile exists but neither Germany (tax_class) nor Brazil (ir_regime) is configured.
Run /finyx:profile to complete the country-specific sections.
```

**Empty brokers array (Germany active):**
Handled interactively in Phase 3.4 — use AskUserQuestion to collect broker data,
offer to save to profile.json via Write.

</error_handling>

<notes>

## Conversational Output

This command outputs advisory text only — it does not create files (unless the user consents to saving broker data to profile.json in Phase 3.4).

## Stateless Calculations

Sparerpauschbetrag and Vorabpauschale calculations are stateless — computed fresh from profile data each run (D-08). No `.finyx/tax/` sidecar files are created.

## Country Routing

- Germany-only user: sees Phase 3 only (no Phase 4 or 5)
- Brazil-only user: sees Phase 4 only (no Phase 3 or 5)
- Cross-border user: sees Phase 3 + Phase 4 + Phase 5

## Tax-Loss Harvesting

Germany has no wash sale rule — detailed guidance is a planned v2 feature. Mention briefly in Phase 3 (December calendar note) but do not build out a full workflow.

## Reference Doc Year

Both reference docs are stamped `tax_year: 2025`. The staleness check in Phase 2 uses `date +%Y` and compares against 2025. In 2026 and beyond, the warning will fire automatically until the docs are updated.

</notes>
