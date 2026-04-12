---
name: finyx:stress-test
description: Run stress test scenarios on shortlisted properties
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
---

<objective>

Run stress test scenarios on shortlisted properties:
1. Zero appreciation scenario (0% growth over 10 years)
2. Interest rate hike scenario (rates increase at refinancing)
3. Vacancy scenario (extended periods without rent)
4. Combined worst-case scenario

**Creates:** `.finyx/analysis/STRESS-TEST.md`

**After this command:** Run `/finyx:report` to include stress test results in advisor briefing.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
@.finyx/profile.json

</execution_context>

<process>

## Phase 1: Load Data

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Load profile:**
Read `.finyx/profile.json` for:
- Investor profile
- Current assumptions (interest rate, appreciation)

**Load shortlists:**
Read all `.finyx/analysis/*/SHORTLIST.md`

**Extract baseline projections for each shortlisted unit:**
- Total price
- Upfront costs
- Monthly cashflow Y1-4
- Monthly cashflow Y5-10
- Exit value (baseline)
- Profit (baseline)

## Phase 2: Scenario 1 - Zero Appreciation

**For each shortlisted unit, recalculate with 0% appreciation:**

```
Exit Value (0%) = Total Price (no growth)
Sale Costs = Exit Value × 7%
Remaining Loan = [same as baseline]
Net at Sale = Exit Value - Sale Costs - Remaining Loan

Total Cash Invested = [same as baseline]
Profit (0%) = Net at Sale - Total Cash Invested
ROE (0%) = Profit ÷ Total Cash Invested × 100
```

**Output table:**

| Unit | Baseline Profit | 0% Profit | Difference | Still Profitable? |
|------|-----------------|-----------|------------|-------------------|
| [UNIT] | €[BASE] | €[ZERO] | -€[DIFF] | YES/NO |

## Phase 3: Scenario 2 - Interest Rate Hike

**Assumptions:**
- Current rate: X.XX% (from config)
- Hike scenario: +2% at year 10 refinancing
- Calculate new monthly payment after refinancing

**For each unit:**

```
Current Monthly Payment = Total Price × (Interest + Tilgung) ÷ 12
Remaining Loan at Y10 = Total Price × (1 - 10 years Tilgung)

New Rate = Current Rate + 2%
New Monthly Payment = Remaining Loan × (New Rate + Tilgung) ÷ 12
Payment Increase = New Payment - Current Payment

New Monthly Cashflow = Current Rent - New Payment - Expenses
```

**Output table:**

| Unit | Current Payment | +2% Payment | Increase | New Cashflow |
|------|-----------------|-------------|----------|--------------|
| [UNIT] | €[CURRENT] | €[NEW] | +€[DIFF] | €[CASHFLOW] |

## Phase 4: Scenario 3 - Extended Vacancy

**Assumptions:**
- Scenario: 3 months vacancy every 2 years
- Impact: Loss of 12.5% of annual rent

**For each unit:**

```
Annual Rent Loss = Monthly Rent × 1.5 (avg per year)
Impact on Y1-4 Cashflow = Rent Loss - (Rent Loss × Tax Rate)
Impact on Y5-10 Cashflow = Rent Loss - (Rent Loss × Tax Rate)

10-Year Vacancy Cost = Annual Rent Loss × 10
```

**Output table:**

| Unit | Monthly Rent | Annual Loss | 10-Year Cost | Adjusted Profit |
|------|--------------|-------------|--------------|-----------------|
| [UNIT] | €[RENT] | €[LOSS] | €[TOTAL] | €[PROFIT] |

## Phase 5: Scenario 4 - Combined Worst Case

**Combine all stress factors:**
- 0% appreciation
- +2% interest rate hike at refinancing
- Vacancy losses

**For each unit:**

```
Exit Value = Purchase Price (no appreciation)
Vacancy Cost = 10-Year Vacancy Loss
Higher Payments Y10+ = Payment Increase × remaining months

Worst Case Profit = 0% Profit - Vacancy Cost
```

**Output table:**

| Unit | Baseline | 0% Apprec | + Vacancy | Worst Case | Status |
|------|----------|-----------|-----------|------------|--------|
| [UNIT] | €[BASE] | €[ZERO] | €[VAC] | €[WORST] | [STATUS] |

**Status indicators:**
- PROFITABLE: Still makes money
- BREAK-EVEN: Within ±€2,000
- LOSS: Loses money but <€10,000
- SIGNIFICANT LOSS: Loses >€10,000

## Phase 6: Risk Assessment

**Generate risk summary for each unit:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RISK ASSESSMENT: [UNIT]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Baseline Profit:    €[PROFIT]
Worst Case:         €[WORST]
Risk Buffer:        €[BUFFER]

Key Vulnerabilities:
• [Appreciation sensitivity: HIGH/MEDIUM/LOW]
• [Interest rate sensitivity: HIGH/MEDIUM/LOW]
• [Vacancy sensitivity: HIGH/MEDIUM/LOW]

Resilience Score: [1-10]

Assessment: [DESCRIPTION]
```

**Resilience scoring:**
- 10: Profitable in worst case
- 7-9: Break-even or small loss in worst case
- 4-6: Moderate loss in worst case
- 1-3: Significant loss in worst case

## Phase 7: Write STRESS-TEST.md

Create `.finyx/analysis/STRESS-TEST.md`:

```markdown
# Stress Test Analysis

**Date:** [DATE]
**Units Tested:** [COUNT]

## Executive Summary

| Unit | Baseline | Worst Case | Resilience |
|------|----------|------------|------------|
| [UNIT] | €[BASE] | €[WORST] | [SCORE]/10 |

**Most Resilient:** [UNIT] - [REASON]
**Most Vulnerable:** [UNIT] - [REASON]

## Scenario 1: Zero Appreciation

Assumption: Property values remain flat for 10 years.

| Unit | Baseline Profit | 0% Profit | Difference | Verdict |
|------|-----------------|-----------|------------|---------|
[TABLE]

**Analysis:** [COMMENTARY]

## Scenario 2: Interest Rate Hike

Assumption: Rates increase by 2% at refinancing (Year 10).

| Unit | Current Payment | +2% Payment | Monthly Impact |
|------|-----------------|-------------|----------------|
[TABLE]

**Analysis:** [COMMENTARY]

## Scenario 3: Extended Vacancy

Assumption: 3 months vacancy every 2 years (12.5% annual loss).

| Unit | Annual Rent | Vacancy Loss | 10-Year Impact |
|------|-------------|--------------|----------------|
[TABLE]

**Analysis:** [COMMENTARY]

## Scenario 4: Combined Worst Case

All stress factors combined.

| Unit | Baseline | Worst Case | Status |
|------|----------|------------|--------|
[TABLE]

**Analysis:** [COMMENTARY]

## Individual Risk Profiles

### [UNIT_1]

[Full risk assessment]

### [UNIT_2]

[Full risk assessment]

## Recommendations

### If Risk Tolerance is LOW:
Choose: [UNIT] - [REASON]

### If Risk Tolerance is MEDIUM:
Choose: [UNIT] - [REASON]

### If Risk Tolerance is HIGH:
Choose: [UNIT] - [REASON]

## Mitigating Factors

Factors that reduce actual risk:

1. **Strong rental market:** [LOCATION] has [VACANCY_RATE]% vacancy
2. **Tax benefits:** Losses reduce tax burden
3. **Forced savings:** Tilgung builds equity regardless
4. **Inflation hedge:** Rents typically rise with inflation
5. **Liquidity buffer:** Investor has €[BUFFER] remaining after purchase
```

## Phase 8: Update STATE.md

```markdown
### Phase: STRESS-TESTED
### Last Action: Ran 4 stress scenarios on [N] units
### Stress Test: .finyx/analysis/STRESS-TEST.md
```

## Phase 9: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► STRESS TEST RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scenarios Tested:
  1. Zero Appreciation (0% growth)
  2. Interest Rate Hike (+2%)
  3. Extended Vacancy (12.5% loss)
  4. Combined Worst Case

Results Summary:

│ Unit       │ Baseline │ Worst Case │ Resilience │
├────────────┼──────────┼────────────┼────────────┤
│ [UNIT]     │ €[BASE]  │ €[WORST]   │ [SCORE]/10 │

Key Findings:
  Most Resilient: [UNIT] (still profitable in worst case)
  Most Vulnerable: [UNIT] (sensitive to [FACTOR])

Recommendation:
  [SUMMARY RECOMMENDATION]

✅ Saved: .finyx/analysis/STRESS-TEST.md

📋 Next:
   /finyx:report          Generate advisor briefing
   /finyx:report --lang pt  Generate in Portuguese
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</process>

<scenarios>

## Custom Scenarios

Users can request additional scenarios:

### `/finyx:stress-test --rent-drop 10`
Model 10% rent decrease scenario.

### `/finyx:stress-test --rate 5.5`
Model specific interest rate scenario.

### `/finyx:stress-test --vacancy 6`
Model 6 months vacancy per 2 years.

</scenarios>
