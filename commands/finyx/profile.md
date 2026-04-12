---
name: finyx:profile
description: Complete financial profile interview to unlock all Finyx advisors
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<objective>

Complete a structured financial profile interview that creates `.finyx/profile.json` — the shared user context file read by all Finyx specialist commands.

**This is the mandatory first step.** No other Finyx command will run without a completed profile.

**Creates:**
- `.finyx/profile.json` — Financial profile with identity, tax, and goals data
- `.finyx/STATE.md` — Workflow state tracker
- `.finyx/research/market/`, `.finyx/research/locations/`, `.finyx/analysis/`, `.finyx/output/` — Directory structure
- `properties/` — Folder for property documents
- `FINYX.md` — Project summary file

**Interview groups:**
1. Residency + Nationality (cross-border detection)
2. Income + Tax (conditional on relevant countries)
3. Goals + Risk Tolerance

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
${CLAUDE_SKILL_DIR}/references/germany/tax-rules.md
${CLAUDE_SKILL_DIR}/references/profile.json
${CLAUDE_SKILL_DIR}/references/state.md

</execution_context>

<process>

## Phase 1: Setup Check

**Verify no existing profile:**
```bash
[ -f .finyx/profile.json ] && echo "PROFILE_EXISTS" || echo "OK"
```

If PROFILE_EXISTS:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > PROFILE ALREADY EXISTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

A financial profile already exists in this directory.

Use /finyx:status to see your current profile summary.
To start fresh, delete the .finyx/ folder and run /finyx:profile again.
```
Exit without making changes.

## Phase 2: Group 1 — Residency + Nationality

Display opening banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > FINANCIAL PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Welcome. This interview takes about 5 minutes.
Your answers are stored locally in .finyx/profile.json.

Group 1 of 3: Residency + Nationality
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use AskUserQuestion:
- header: "Residence Country"
- question: "Where do you currently live?"
- options: ["Germany", "Brazil", "Other"]

Store as `residence_country`.

Use AskUserQuestion:
- header: "Nationality"
- question: "What is your nationality?"
- options: ["German", "Brazilian", "Other"]

Store as `nationality`.

Ask inline: "Do you earn income in any other country besides your country of residence? If yes, list the countries (e.g., 'Germany, Brazil'). If no, type 'no'."

Store as `income_countries_raw`. Parse into array: `income_countries = [residence_country] + any additional countries named`.

### Cross-Border Detection

Compute `cross_border`:
```
cross_border = false

// Check 1: residence vs nationality mismatch
if residence_country != nationality_country:
  cross_border = true

// Check 2: income from multiple countries
if income_countries has more than one unique country:
  cross_border = true
```

If `cross_border = true`:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Cross-border situation detected
 Residence: [residence_country] | Nationality: [nationality]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
We will collect tax details for all relevant jurisdictions.
```

## Phase 3: Group 2 — Income + Tax

Display section header:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Group 2 of 3: Income + Tax
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Determine which country branches are relevant:
- Germany relevant if: `residence_country == "Germany"` OR `"Germany" in income_countries`
- Brazil relevant if: `residence_country == "Brazil"` OR `"Brazil" in income_countries`

### 3.1 Germany Branch (if Germany is relevant)

Use AskUserQuestion:
- header: "German Tax Class (Steuerklasse)"
- question: "Which German tax class applies to you?"
- options:
  - "I — Single, divorced, widowed without children"
  - "III/V — Married, you are the higher earner"
  - "IV/IV — Married, roughly equal earners"

Store mapped value: I → "I", III/V → "III", IV/IV → "IV"

Use AskUserQuestion:
- header: "Church Tax (Kirchensteuer)"
- question: "Do you pay church tax in Germany?"
- options: ["No", "Yes (8-9% surcharge on income tax)"]

Store as boolean `church_tax`.

Ask inline: "What is your annual gross income from Germany (in EUR)? Enter a number, e.g., 85000"

Store as `de_gross_income`.

**Calculate German marginal rate** using the loaded tax-rules reference:

```
Base tax rate calculation:
- Single (class I): top bracket if income > 68,480 EUR → baseRate = 42%
  Sub-bracket 57,919 - 68,480 EUR → progressive zone ~42%
  Sub-bracket 17,006 - 57,918 EUR → progressive zone ~24%-42%
  Below 10,908 EUR → 0% (Grundfreibetrag)
- Married (class III, splitting): thresholds doubled
  top bracket if income > 136,960 EUR (half of 277,826 household)

Soli surcharge: if baseRate > 0, add 5.5% of income tax
Church tax: if church_tax, add 8% of income tax (Bavaria/Baden-Wuerttemberg) or 9% elsewhere

Simple marginal rate estimate:
  if single and income > 68,480: marginalRate = 42 + (42 * 0.055) = 44.31%
  if single and income 17,006-68,480: marginalRate ≈ 32 + (32 * 0.055) = ~33.76%
  if married (III) and income > 136,960: marginalRate = 42 + (42 * 0.055) = 44.31%
  if married (IV) use single thresholds
  if church_tax: add baseRate * 0.09 (use 9% as default)
```

Display calculated rate:
```
Estimated marginal tax rate: [RATE]%
(Based on [TAX_CLASS], €[INCOME]/year gross income)
```

Ask inline: "Does this look correct? Enter 'yes' to accept, or enter your actual marginal tax rate (e.g., '44.31')."

If user enters a number, use that value instead. Store as `de_marginal_rate`.

### 3.2 Brazil Branch (if Brazil is relevant)

Use AskUserQuestion:
- header: "Brazilian Income Tax Regime (IR)"
- question: "Which income tax regime do you use for your Brazilian tax return?"
- options:
  - "Simplificado — 20% standard deduction (easier, good for most)"
  - "Completo — Itemized deductions (better if high deductible expenses)"

Store mapped value: Simplificado → "simplificado", Completo → "completo"

Ask inline: "What is your annual gross income from Brazil in BRL? (If none, type 0)"

Store as `br_gross_income`.

Ask inline: "What is your CPF number? (Optional — for reference only, not shared externally. Type 'skip' to leave blank)"

Store as `br_cpf` (empty string if skip).

## Phase 4: Group 3 — Goals + Risk Tolerance

Display section header:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Group 3 of 3: Goals + Risk Tolerance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use AskUserQuestion:
- header: "Family Status"
- question: "What is your family status?"
- options: ["Single", "Married", "Registered Partnership", "Divorced/Separated"]

Store as `family_status`.

Ask inline: "How many children do you have? (Enter 0 if none)"

Store as `children` (integer).

Use AskUserQuestion:
- header: "Risk Tolerance"
- question: "How would you describe your risk tolerance for investments?"
- options:
  - "Conservative — Preserve capital, accept lower returns, minimal volatility"
  - "Moderate — Balanced growth and safety, accept some volatility"
  - "Aggressive — Maximum growth, accept significant volatility"

Store mapped value: Conservative → "conservative", Moderate → "moderate", Aggressive → "aggressive"

Use AskUserQuestion:
- header: "Investment Horizon"
- question: "What is your primary investment time horizon?"
- options:
  - "Short-term (1-3 years)"
  - "Medium-term (3-10 years)"
  - "Long-term (10+ years)"

Store mapped integer: Short-term → 2, Medium-term → 7, Long-term → 15

Ask inline: "What are your primary financial goals? List them (e.g., 'real estate investment, ETF portfolio, retirement savings, tax optimization')"

Store as `primary_goals` array (split by comma).

Use AskUserQuestion:
- header: "Liquid Assets"
- question: "What range best describes your total liquid assets currently available for investment?"
- options:
  - "Under 25,000 EUR"
  - "25,000 - 100,000 EUR"
  - "100,000 - 500,000 EUR"
  - "Over 500,000 EUR"

Ask inline: "What is your exact liquid asset amount available for investment (EUR)? Enter a number."

Store as `liquid_assets` (integer).

Ask inline: "What are your total fixed monthly financial commitments (rent, existing loans, insurance, etc.) in EUR? Enter a number."

Store as `monthly_commitments` (integer).

## Phase 5: Create Project Files

**Create directory structure:**
```bash
mkdir -p .finyx/research/market
mkdir -p .finyx/research/locations
mkdir -p .finyx/analysis
mkdir -p .finyx/output
mkdir -p properties
```

**Write `.finyx/profile.json`** using all interview answers:

```json
{
  "$schema": "https://finyx.dev/schemas/profile.schema.json",
  "version": "1.0.0",
  "created": "[ISO_DATE]",
  "updated": "[ISO_DATE]",

  "_holdings_schema": {
    "description": "Each broker in countries.{country}.brokers[] can contain a holdings[] array",
    "holding_fields": {
      "ticker": "Exchange ticker symbol (e.g., VWCE, BOVA11)",
      "isin": "ISIN if available (e.g., IE00BK5BQT80), null for B3 assets",
      "shares": "Number of shares/units held (decimal)",
      "cost_basis": "Average cost per share in local currency",
      "asset_class": "One of: equity-etf, bond-etf, reit-etf, stock, fii, fixed-income",
      "geography": "One of: global, us, europe, emerging-markets, brazil, germany"
    }
  },

  "identity": {
    "residence_country": "[residence_country]",
    "nationality": "[nationality]",
    "income_countries": [income_countries],
    "has_income_in_multiple_countries": [boolean],
    "cross_border": [cross_border],
    "family_status": "[family_status]",
    "children": [children]
  },

  "countries": {
    "germany": {
      "tax_class": "[de_tax_class or null]",
      "church_tax": [de_church_tax or false],
      "gross_income": [de_gross_income or 0],
      "marginal_rate": [de_marginal_rate or 0],
      "brokers": []
    },
    "brazil": {
      "ir_regime": "[br_ir_regime or null]",
      "gross_income": [br_gross_income or 0],
      "cpf": "[br_cpf or null]",
      "brokers": []
    }
  },

  "goals": {
    "risk_tolerance": "[risk_tolerance]",
    "investment_horizon": [investment_horizon_years],
    "primary_goals": [primary_goals_array]
  },

  "pension": {
    "de_rentenpunkte": null,
    "expected_real_return_de": 1.5,
    "br_inss_status": null,
    "expected_real_return_br": 2.0,
    "target_retirement_age": null
  },

  "project": {
    "name": "[current directory name]",
    "propertiesFolder": "properties",
    "outputFolder": ".finyx/output",
    "language": "en"
  },

  "investor": {
    "country": "[residence_country]",
    "taxClass": "[de_tax_class or empty string]",
    "churchTax": [de_church_tax or false],
    "children": [children],
    "income": {
      "primary": [de_gross_income or 0],
      "spouse": 0,
      "total": [de_gross_income or 0]
    },
    "marginalRate": [de_marginal_rate or 0],
    "liquidAssets": [liquid_assets],
    "monthlyCommitments": [monthly_commitments]
  },

  "strategy": {
    "type": "neubau-rent-sell",
    "horizon": [investment_horizon_years],
    "financing": {
      "ltv": 100,
      "fixedPeriod": 10
    },
    "management": "professional",
    "exitPlan": "sell-tax-free"
  },

  "criteria": {
    "propertyType": "2-bedroom apartment",
    "bedrooms": [2],
    "minYield": 2.8,
    "maxPrice": 450000,
    "minSize": 45,
    "maxSize": 80,
    "parkingRequired": false,
    "parkingPreferred": true,
    "excludeErbpacht": true,
    "excludeGroundFloor": false,
    "topFloorPreferred": false,
    "newConstructionOnly": true
  },

  "assumptions": {
    "appreciation": 2.0,
    "rentIncrease": 0,
    "vacancy": 0,
    "verwaltungPerSqm": 1.0,
    "rucklagePerSqm": 0.6,
    "saleCosts": 7.0,
    "constructionPeriod": 18,
    "constructionDraw": 50
  }
}
```

**Populate only the countries that are relevant** — if Germany is not in scope, set all germany fields to null/0/false. Same for Brazil.

**Write `.finyx/STATE.md`** using the state template, updated for Finyx:

```markdown
# FINYX Project State

**Project:** [directory name]
**Created:** [DATE]
**Status:** PROFILE COMPLETE

## Workflow

| Step | Status | Date |
|------|--------|------|
| Profile | ✅ COMPLETE | [DATE] |
| Scout | ⏳ PENDING | - |
| Analyze | ⏳ PENDING | - |
| Filter | ⏳ PENDING | - |
| Compare | ⏳ PENDING | - |
| Report | ⏳ PENDING | - |

## Locations

| Location | Status | Units | Shortlisted | Notes |
|----------|--------|-------|-------------|-------|
| (none yet) | - | - | - | Add via /finyx:scout |

## Notes

Profile created [DATE]. Run `/finyx:scout [location]` to begin real estate research.
```

**Write `FINYX.md`** project summary:

```markdown
# FINYX Project

**Created:** [DATE]
**Investor Country:** [residence_country]
**Tax Rate:** [marginal_rate]%

## Quick Reference

Run `/finyx:help` for all commands.
Run `/finyx:status` to see current state.

## Workflow

1. `/finyx:scout [location]` — Research a location
2. `/finyx:analyze [location]` — Calculate metrics
3. `/finyx:filter [location]` — Apply criteria
4. `/finyx:compare` — Side-by-side comparison
5. `/finyx:report` — Generate advisor briefing
```

## Phase 6: Completion

Display summary banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > PROFILE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Profile Summary:
  Residence:       [residence_country]
  Nationality:     [nationality]
  Cross-border:    [YES / NO]
  Family Status:   [family_status]
  Children:        [children]

  [if Germany relevant:]
  DE Tax Class:    [tax_class]
  DE Gross Income: €[amount]/year
  DE Marginal Rate: [rate]%
  Church Tax:      [YES / NO]

  [if Brazil relevant:]
  BR IR Regime:    [regime]
  BR Gross Income: R$[amount]/year

  Risk Tolerance:  [risk_tolerance]
  Horizon:         [horizon] years
  Liquid Assets:   €[liquid_assets]
  Commitments:     €[monthly_commitments]/month

Files created:
  .finyx/profile.json
  .finyx/STATE.md
  FINYX.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Real estate analysis:
  1. Add property documents to properties/[location]/
  2. Run /finyx:scout [location] to research the location
  3. Run /finyx:analyze [location] to calculate metrics
  4. Run /finyx:filter [location] to apply your criteria
  5. Run /finyx:compare to compare shortlisted options
  6. Run /finyx:report to generate advisor briefing

Financial advisors (ready to use):
  /finyx:tax     — Tax optimization advisor
  /finyx:invest  — Investment portfolio advisor
  /finyx:broker  — Broker comparison advisor
  /finyx:pension — Pension planning advisor

Run /finyx:help for all available commands.
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of this output.

</process>

<error_handling>

## Profile Already Exists

If `.finyx/profile.json` exists, display the error message in Phase 1 and exit cleanly. Do not overwrite.

## Invalid Income Entry

If user enters non-numeric income value, prompt again:
"Please enter a number (e.g., 85000 for €85,000/year)."

## Country Not Fully Supported

If user selects "Other" for residence country:
"Note: Only Germany and Brazil have full tax integration in Finyx v1. Your profile will be created with limited tax data. You can still use the real estate commands — you will need to enter your marginal tax rate manually."

Then ask inline for their marginal tax rate and store in `investor.marginalRate`.

## Marginal Rate Clarification

If user is unsure of their marginal tax rate, explain briefly:
"Your marginal tax rate is the tax rate you pay on each additional euro of income. For Germany, this is income tax + Soli surcharge + optional church tax. A rough estimate for high earners (>68,480 EUR) is ~44%. Check your last tax return (Einkommenssteuerbescheid) for the exact figure."

</error_handling>

<notes>

## Cross-Border Logic

`cross_border` is derived automatically — the user does not select it. Detection rules:
1. Residence country differs from nationality country (expat situation)
2. Income is earned in more than one country

Example: German national living in Germany with Brazilian rental income → cross_border = true

## Backward Compatibility

The `investor.*` section mirrors IMMO's original `config.json` structure. All existing RE commands that read `investor.marginalRate` will work without modification.

## Profile Update

The profile command only creates — it does not update. To update individual fields in a future release, a `/finyx:update-profile` command will be added. For now, delete `.finyx/` and re-run `/finyx:profile`.

## Tax Rate Calculation

The marginal rate calculation is an estimate. Users should always confirm with their actual Einkommenssteuerbescheid. The profile stores the user-confirmed rate, not the estimate.

</notes>
