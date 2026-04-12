---
name: finyx:pension
description: Pension advisor — German (Riester/Ruerup/bAV) and Brazilian (PGBL/VGBL) pension guidance with cross-country projection
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<objective>

Deliver personalized pension guidance based on the user's financial profile.

This command:
1. Reads `.finyx/profile.json` and detects which countries are active
2. Checks reference doc tax year against the current year and warns if stale
3. For Germany: compares Riester vs Ruerup vs bAV based on employment situation, calculates Riester Zulagen, estimates Ruerup tax saving, explains bAV Entgeltumwandlung benefits and tradeoffs
4. For Brazil: guides PGBL vs VGBL decision based on IR regime and 12% income threshold, explains progressive vs regressive regime with time horizon examples (including Law 14.803/24 deferral)
5. For cross-border users (`cross_border: true`): builds combined retirement projection merging DE statutory + private + BR INSS

Output is conversational advisory text — no files are written unless user consents to saving pension profile data. All guidance includes the legal disclaimer.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
${CLAUDE_SKILL_DIR}/references/germany/pension.md
${CLAUDE_SKILL_DIR}/references/brazil/pension.md
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
- `identity.family_status` — "single" or "married"
- `identity.children` — number of children (integer)
- `countries.germany.tax_class` — null means Germany not active
- `countries.germany.gross_income` — annual gross income in EUR
- `countries.germany.marginal_rate` — decimal percentage
- `countries.brazil.ir_regime` — null means Brazil not active
- `countries.brazil.gross_income` — annual gross income in BRL
- `pension.de_rentenpunkte` — accumulated Rentenpunkte (may be null)
- `pension.expected_real_return_de` — real return rate for DE private pension (default 1.5%)
- `pension.br_inss_status` — "active", "suspended", "totalization", or null
- `pension.expected_real_return_br` — real return rate for BR private pension (default 2.0%)
- `pension.target_retirement_age` — target retirement age (may be null)

**Determine active countries:**
- Germany active if: `countries.germany.tax_class != null`
- Brazil active if: `countries.brazil.ir_regime != null`
- Cross-border if: `identity.cross_border == true`

**If neither country is active:**
```
ERROR: No country pension data found in your profile.

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
 FINYX ► PENSION: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reference docs are from tax year 2025. Current year is [CURRENT_YEAR].
Pension limits, Zulagen, Höchstbeiträge, and Rentenwert may have changed.
Verify all guidance against official BMF / Receita Federal / Deutsche
Rentenversicherung sources before making any decisions based on this output.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 3: German Pension Planning

*Execute this phase only if Germany is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► PENSION: GERMAN PENSION PLANNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.1 Employment Status Assessment

Read `countries.germany.tax_class` and `identity.family_status` as proxies for employment status.

Tax classes I, II, III, IV, V indicate the user is an employee subject to mandatory GRV contributions — making them unmittelbar förderberechtigt for Riester.

Tax class VI is a secondary employment indicator — still employed, but use context to determine primary employment.

If the user's situation suggests self-employment is possible (e.g., no tax class set or user mentions freelancing), use AskUserQuestion:

```
Are you employed (paying mandatory gesetzliche Rentenversicherung contributions)
or self-employed?

This determines your Riester eligibility. Options:
1. Employed — paying mandatory GRV (standard employee)
2. Self-employed — freelancer, Freiberufler, or Gewerbetreibender
3. Civil servant (Beamte)
4. Mixed — employed part-time and self-employed
```

Riester eligibility:
- Employed / civil servant / Elternzeit / ALG recipient → unmittelbar förderberechtigt (directly eligible)
- Self-employed without mandatory GRV → NOT eligible (with narrow exceptions: Handwerker, Lehrer, Hebammen, Künstler with mandatory GRV)
- Spouse of eligible partner → mittelbar förderberechtigt (indirectly eligible) if partner already has Riester contract

### 3.2 Riester Zulagen Calculation

Read `identity.children` from profile.

If `children > 0`, use AskUserQuestion to collect birth years (required for pre/post-2008 Kinderzulage distinction):

```
You have [N] child(ren) in your profile. To calculate your Riester Kinderzulage
accurately, I need their birth years.

Please list the birth year for each child (e.g., 2005, 2012, 2019).
```

**Calculate Zulagen:**
```
grundzulage = 175 EUR/year

for each child:
  if birth_year >= 2008: kinderzulage += 300 EUR
  if birth_year < 2008:  kinderzulage += 185 EUR

total_zulagen = grundzulage + kinderzulage
```

**Minimum own contribution for full Zulagen:**
```
own_contribution_required = max(0.04 × countries.germany.gross_income - total_zulagen, 60)
```

**Maximum eligible:**
```
max_eligible = 2,100 EUR/year (own contributions + Zulagen combined)
```

**Present a Zulagen summary:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RIESTER ZULAGEN CALCULATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Grundzulage:                          175 EUR/year
Kinderzulage ([N] children):          [kinderzulage] EUR/year
  ([breakdown per child if multiple children])
Total Zulagen:                        [total_zulagen] EUR/year

Minimum own contribution required:    [own_contribution_required] EUR/year
Maximum eligible (own + Zulagen):     2,100 EUR/year
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Günstigerprüfung note:**
> The Finanzamt automatically applies Günstigerprüfung: it calculates both the direct Zulagen benefit and the Sonderausgabenabzug benefit (deducting up to 2,100 EUR from taxable income), then gives you whichever is larger. You never need to request this — it is applied automatically when you file Anlage AV.

Offer to save children birth years to profile if user wants (via Write to `.finyx/profile.json`, adding `identity.children_birth_years` array).

### 3.3 Rürup (Basisrente) Sonderausgabenabzug Estimate

**Höchstbeitrag 2025 (verified statutory figure):**
- Single: 29,344 EUR
- Married (joint assessment): 58,688 EUR

Determine single/married from `identity.family_status`.

**GRV offset for employed users:**

Employed users' GRV contributions (employee + employer share) count toward the Höchstbeitrag. Estimate available Rürup space:

```bash
# Approximate GRV offset calculation
# BBG_West 2025 = 96,600 EUR
# GRV rate = 18.6% total (9.3% employee + 9.3% employer)
```

```
bbg_west = 96600
grv_rate = 0.186
approx_grv_total = min(countries.germany.gross_income, bbg_west) × grv_rate
remaining_ruerup_space = max(hoechstbeitrag - approx_grv_total, 0)
```

**Tax saving calculation:**
```
max_tax_saving = hoechstbeitrag × (countries.germany.marginal_rate / 100)
available_space_tax_saving = remaining_ruerup_space × (countries.germany.marginal_rate / 100)
```

**Present Rürup estimate:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RÜRUP (BASISRENTE) ESTIMATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Höchstbeitrag 2025 ([single/married]):  [hoechstbeitrag] EUR
Est. GRV offset (employed):             [approx_grv_total] EUR
Available Rürup space:                  [remaining_ruerup_space] EUR

Max possible tax saving (full Rürup):   [max_tax_saving] EUR
Tax saving on available space:          [available_space_tax_saving] EUR

Net cost after subsidy:
  contribution - (contribution × [marginal_rate]%) = effective outlay
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If user wants to calculate for a specific contribution amount, use AskUserQuestion:
```
How much are you considering contributing to a Rürup contract per year?
Enter an amount in EUR, or press Enter to see the maximum benefit only.
```

### 3.4 bAV (Betriebliche Altersversorgung) Guidance

Using limits from the loaded pension reference (Section 3):

**2025 limits:**
```
Tax-free limit:               7,728 EUR/year  (8% × BBG West 96,600)
Social-security-free limit:   3,864 EUR/year  (4% × BBG West 96,600)
Mandatory employer Zuschuss:  15% of redirected amount (§1a BetrAVG)
```

**Tax and SV saving formula:**
```
redirect_amount = user's Entgeltumwandlung per year
tax_saving = min(redirect_amount, 7728) × (marginal_rate / 100)
sv_saving  = min(redirect_amount, 3864) × 0.207
net_cost   = redirect_amount - tax_saving - sv_saving
```

Show a worked example using the user's `countries.germany.marginal_rate`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 bAV ENTGELTUMWANDLUNG — ILLUSTRATIVE EXAMPLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Redirected (example: 200 EUR/month = 2,400 EUR/year):

Tax saving (2,400 × [marginal_rate]%):     [tax_saving] EUR
SV saving (2,400 × 20.7%):                [sv_saving] EUR
Net cost (effective outlay):               [net_cost] EUR

PLUS: Employer mandatory 15% Zuschuss:    +[2400 × 0.15] EUR = [360] EUR added to your pension
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**ALWAYS include this GRV tradeoff note:**
> IMPORTANT: Entgeltumwandlung reduces your gross income. This means fewer Entgeltpunkte accumulate in your gesetzliche Rentenversicherung each year, lowering your future statutory pension. This tradeoff is significant for employees earning below 50,000 EUR gross. Evaluate whether the immediate tax+SV saving outweighs the long-term GRV reduction for your situation.

Generic framing: "Ask your HR department about available bAV vehicles (Direktversicherung, Pensionskasse, or Pensionsfonds) and whether your employer contributes more than the legal minimum 15%."

### 3.5 Riester vs Rürup vs bAV Comparison and Recommendation

Using the comparison matrix from the loaded reference doc (Section 4), display the full comparison:

| Criterion | Riester | Rürup | bAV |
|-----------|---------|-------|-----|
| Who it's for | Employees with mandatory GRV; parents | Everyone incl. self-employed | Employed only (via employer) |
| Self-employed eligible | Rarely | Yes — primary vehicle | No |
| Key benefit | Zulagen subsidies; strongest with children | Sonderausgabenabzug at full marginal rate | Tax + SV reduction via Entgeltumwandlung |
| Max annual | 2,100 EUR (own + Zulagen) | 29,344 EUR (2025) less GRV offset | 7,728 EUR income-tax-free |
| Child bonus | YES — Kinderzulage | No | No |
| Flexibility | Low — locked until retirement | Very low — no lump sum | Moderate — employer-dependent |

**Personalized recommendation** based on user profile:

- **Has children + employed:** Riester is likely best — Kinderzulagen provide direct state subsidies that outperform pure tax savings at lower income levels. Supplement with bAV if employer offers matching.
- **High earner + no children + employed:** bAV first (double efficiency: tax + SV saving), then Rürup for remaining Höchstbeitrag space. Riester provides minimal net benefit at high marginal rates without Kinderzulage.
- **Self-employed (no mandatory GRV):** Rürup is the primary vehicle — it is designed for your situation and provides full Sonderausgabenabzug.
- **Employed + employer offers bAV match:** Maximize bAV first (free money from employer), then evaluate Riester (with children) or Rürup.
- **Married spouse (mittelbar förderberechtigt):** Indirect Riester eligibility via employed partner — ensure partner has an active Riester contract, then open a contract with minimum 60 EUR/year to access Grundzulage.

## Phase 4: Brazilian Pension Planning

*Execute this phase only if Brazil is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► PENSION: BRAZILIAN PENSION PLANNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4.1 PGBL vs VGBL Decision

Read `countries.brazil.ir_regime` from profile.

**If `ir_regime == "completa"`:**

Check `pension.br_inss_status`. If null, use AskUserQuestion:
```
Do you have active INSS or statutory pension contributions in Brazil?
(Required to qualify for the PGBL deduction.)

Options:
1. Yes — I contribute to INSS via employment (or voluntary contributions)
2. No — I have no current INSS contributions
```

If both conditions met (ir_regime == "completa" AND active INSS):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PGBL ELIGIBILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: PGBL eligible ✓

Maximum PGBL deduction (12% of gross income):
  0.12 × R$[gross_income] = R$[max_deductible] / year

Declaration code: 36 on DIRPF

Tax saving (indicative, at marginal IR rate):
  R$[max_deductible] × [marginal_rate]% = R$[tax_saving] / year

Note: At PGBL withdrawal, the FULL amount (principal + gains) is taxed.
This is the trade-off — the deduction is a deferral, not an exemption.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After maxing PGBL (12% threshold), any additional private pension contributions should go into VGBL (gains only taxed at withdrawal).

If ir_regime == "simplificada" OR no active INSS:

```
Decision: VGBL recommended.

Reason:
- Filing simplificada: the 20% standard deduction already exceeds the marginal
  benefit of PGBL, and you cannot supplement it with PGBL on top.
- No INSS: PGBL deduction requires active statutory pension contribution.

With VGBL: only accumulated GAINS are taxed at withdrawal — principal is
withdrawn tax-free. This makes VGBL a more efficient vehicle in your situation.
```

**PGBL vs VGBL decision tree (always display):**
```
Filing declaração completa AND has active INSS?
├── YES → PGBL (up to 12% of gross income), then VGBL for the rest
└── NO  → VGBL
          ├── Filing simplificada? → VGBL (PGBL deduction unavailable)
          └── No INSS? → VGBL (PGBL deduction requires INSS contribution)
```

### 4.2 Progressive vs Regressive IR Regime

**Regressive table (rate applied per contribution tranche by age):**

| Accumulation period per tranche | IR Rate |
|---------------------------------|---------|
| Up to 2 years | 35% |
| 2–4 years | 30% |
| 4–6 years | 25% |
| 6–8 years | 20% |
| 8–10 years | 15% |
| Above 10 years | **10%** |

> Important: rates apply per tranche — each contribution ages independently. Contributions made 11 years ago are taxed at 10% even if other recent contributions are taxed at 35%.

**Progressive table (rates apply to total annual withdrawal income):**

| Annual withdrawal income | IR Rate |
|--------------------------|---------|
| Up to R$24,511.92 (2025 exempt) | 0% |
| R$24,511.92 – R$33,919.80 | 7.5% |
| R$33,919.80 – R$45,012.60 | 15% |
| R$45,012.60 – R$55,976.16 | 22.5% |
| Above R$55,976.16 | 27.5% |

**Example scenarios:**

*Scenario 1 — Long horizon, large withdrawal:*
R$500,000 withdrawal after 12+ years accumulation:
- Regressive: 10% → R$50,000 tax
- Progressive: at this income level, effective rate could reach 20–27.5%
- **Winner: Regressive**

*Scenario 2 — Short/medium horizon, small annual withdrawal:*
R$50,000/year withdrawal with low other income:
- Progressive: R$25,488 × 0% + R$9,407 × 7.5% + R$11,093 × 15% ≈ R$2,369 tax (4.7% effective)
- Regressive after 4–6 years: 25% → R$12,500 tax
- **Winner: Progressive**

**CRITICAL — Law 14.803/24 deferral (always include):**
> Since Law 14.803/2024, the progressive vs regressive regime choice can be DEFERRED to the moment of withdrawal. You no longer need to commit at contract inception.
>
> **Recommendation:** Unless you have a clear long-horizon commitment (>10 years, where regressive 10% almost certainly wins), defer the decision. Deferring preserves optionality at zero cost.

**Regime decision guidance:**
| Scenario | Recommended regime |
|----------|--------------------|
| Long horizon (>10 years) + high withdrawal income | Regressive — 10% vs up to 27.5% |
| Short horizon (<4 years) | Progressive — low brackets may apply |
| Low expected withdrawal amount | Progressive — 0% band and lower brackets |
| Uncertain horizon | Defer (Law 14.803/24 now allows this) |

### 4.3 INSS Status Collection

If `pension.br_inss_status` is null, use AskUserQuestion:
```
What is your INSS (Brazilian social security) status?

1. Active — I am currently contributing to INSS (via Brazilian employer or voluntary contributions from abroad)
2. Suspended — I am not currently contributing, but prior contributions remain on record
3. Totalization — I intend to use the Brazil-Germany bilateral agreement to combine contribution periods from both countries

Enter the number for your situation, or 'skip' if you prefer not to share this now.
```

**Explain what each status means for the projection:**
- **Active:** You may receive an independent BR pension benefit. Monthly estimate is self-reported. The DE-BR totalization agreement (in force since 2013) allows combining contribution periods if needed.
- **Suspended:** Your prior contributions are preserved and locked. The BR benefit will be available at Brazilian retirement age. Amount uncertain — provide a self-reported estimate or leave blank in the projection.
- **Totalization:** Combined contribution periods will be used to qualify for benefits in one or both countries. Each country pays proportionally to actual contributions. Amounts require legal verification.

Offer to save INSS status to profile (Write to `.finyx/profile.json` `pension.br_inss_status` field).

## Phase 5: Cross-Country Retirement Projection

*Execute this phase ONLY if `identity.cross_border == true`.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► PENSION: CROSS-COUNTRY RETIREMENT PROJECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5.1 Collect Missing Inputs

For each null pension field, use AskUserQuestion to collect:

**Retirement age** (if `pension.target_retirement_age` is null):
```
At what age do you plan to retire?
(e.g., 63, 65, 67 — used to calculate years until retirement for the projection)
```

**Current age** (if not derivable from profile):
```
What is your current age? (needed to calculate years to retirement)
```

**DE Rentenpunkte** (if `pension.de_rentenpunkte` is null):
```
How many Rentenpunkte (Entgeltpunkte) do you currently have?

You can find this on your annual Renteninformation from Deutsche Rentenversicherung.
Enter a number (e.g., 12.5) or 'skip' if unknown — we will note it as unknown in the projection.
```

**DE private pension monthly estimate** (Riester/Rürup/bAV):
```
Do you have any private pension plans in Germany (Riester, Rürup, bAV)?
If yes, what is your estimated monthly payout at retirement in EUR?
Enter an amount, or 'skip' if none / unknown.
```

**BR INSS monthly benefit** (if `pension.br_inss_status` is not null and not "suspended"):
```
What is your estimated monthly INSS benefit at retirement (in BRL)?
If unsure, enter 0 and we will note it as unknown.
```

**BR private pension balance** (PGBL/VGBL):
```
Do you have PGBL or VGBL plans in Brazil?
If yes, what is the current accumulated balance in BRL?
Enter an amount, or 'skip' if none / unknown.
```

Offer to save all collected pension fields to `.finyx/profile.json` pension block in a single Write operation.

### 5.2 Build Projection Table

**Calculate years to retirement:**
```bash
CURRENT_YEAR=$(date +%Y)
```
```
years_to_retirement = pension.target_retirement_age - current_age
```

**Real return rates (use profile values, or defaults):**
```
real_rate_de = pension.expected_real_return_de  (default: 1.5%)
real_rate_br = pension.expected_real_return_br  (default: 2.0%)
```

**Statutory pension:**
```
de_statutory_monthly = de_rentenpunkte × 40.79  EUR/month
(Rentenwert 2025: 40.79 EUR per Entgeltpunkt — verify annually)
```

**Private pension projection (inflation-adjusted):**
```
de_private_monthly = user-stated estimate (already in today's real terms if stated as current estimate)
br_private_accumulated = current_balance × (1 + real_rate_br / 100) ^ years_to_retirement
br_private_monthly = br_private_accumulated / annuity_factor
  (annuity_factor ≈ 240 months = 20-year payout as a default — note it is approximate)
```

**Present projection table:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CROSS-COUNTRY RETIREMENT PROJECTION
 (real terms, [CURRENT_YEAR] EUR/BRL — inflation-adjusted)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target retirement age:  [target_retirement_age]
Years to retirement:    [years_to_retirement]

GERMANY
  Statutory pension (GRV):     [de_rentenpunkte] EP × 40.79 = [de_statutory_monthly] EUR/month
  Private pension (est.):      [de_private_monthly] EUR/month  (self-reported)
  DE subtotal:                 [de_subtotal] EUR/month

BRAZIL
  INSS benefit (est.):         [br_inss_monthly] BRL/month  (self-reported)
  Private pension (est.):      [br_private_monthly] BRL/month  (projected at [real_rate_br]% real)
  BR subtotal:                 [br_subtotal] BRL/month

COMBINED (approximate, converted at current EUR/BRL)
  [de_subtotal] EUR/month + [br_subtotal] BRL/month
  ≈ [combined_eur] EUR/month  (indicative — exchange rate fluctuation not modeled)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Note: EUR/BRL conversion is approximate. Exchange rates over a multi-decade horizon
are unpredictable. Treat combined figure as illustrative order-of-magnitude only.
```

If any field is unknown/skipped, mark it as `[unknown]` in the projection and note the impact on the total.

### 5.3 D-07 Disclaimer (MANDATORY — include verbatim)

> Cross-border pension entitlements require verification by a Brazilian social security lawyer (advogado previdenciário). This projection is an illustrative estimate only — actual benefits depend on contribution history, treaty application, and regulatory changes in both countries.

## Phase 6: Disclaimer

Append the full legal disclaimer from the loaded `disclaimer.md` reference at the end of all advisory output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

## Phase 7: Save Offer

If any pension fields were collected via AskUserQuestion during this session (children birth years, INSS status, Rentenpunkte, retirement age, return rates), offer to save all of them to `.finyx/profile.json` pension block in a single Write operation:

```
I collected the following pension information during this session:
[list each field collected with its value]

Would you like me to save this to your profile so you don't need to re-enter it next time?
(Yes / No)
```

If yes, perform a single Write to `.finyx/profile.json` updating the relevant fields.

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No country data in profile:**
```
ERROR: No country pension data found in your profile.
Your profile exists but neither Germany (tax_class) nor Brazil (ir_regime) is configured.
Run /finyx:profile to complete the country-specific sections.
```

**Pension fields null:**
Handled interactively in process phases via AskUserQuestion — these are not errors. Missing pension data is collected at runtime and offered for profile save in Phase 7.

</error_handling>

<notes>

## Conversational Output

This command outputs advisory text only — it does not create files unless the user consents to saving collected pension data to `.finyx/profile.json` in Phase 7.

## Country Routing

- Germany-only user: sees Phase 3 only (no Phase 4 or 5)
- Brazil-only user: sees Phase 4 only (no Phase 3 or 5)
- Cross-border user (cross_border == true): sees Phase 3 + Phase 4 + Phase 5

## Children Birth Years

Collected at runtime via AskUserQuestion if `identity.children > 0`. Not stored in the profile schema by default (to avoid breaking existing profiles), but offered for save as `identity.children_birth_years` array in Phase 7.

## Rürup Höchstbeitrag

Uses the verified 2025 statutory figure: 29,344 EUR single / 58,688 EUR married. This is the correct 2025 value — do NOT use 27,566 EUR which was the 2024 figure.

## INSS Entitlement

INSS benefit entitlement is NOT computed by this command (per D-06). Only self-reported status and monthly benefit estimate are collected. The D-07 disclaimer is mandatory in all cross-country projection outputs.

## Law 14.803/24

The Brazilian progressive vs regressive regime choice deferral under Law 14.803/2024 is a key advisory point. Always recommend deferring unless the user has a clear commitment to >10 year horizon (where regressive at 10% almost certainly wins vs progressive top rate of 27.5%).

## Rentenwert

The statutory pension calculation uses Rentenwert 2025: 40.79 EUR/month per Entgeltpunkt. This changes annually on July 1. The staleness check in Phase 2 will fire if the reference doc `tax_year` does not match the current year.

</notes>
