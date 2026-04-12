# German Tax Rules for Real Estate Investment

## Marginal Tax Rate Calculation

### Income Tax Brackets (2024+)

| Taxable Income (Single) | Taxable Income (Married) | Base Rate |
|-------------------------|--------------------------|-----------|
| €0 - €11,604 | €0 - €23,208 | 0% |
| €11,605 - €17,005 | €23,209 - €34,010 | 14% - 24% (progressive) |
| €17,006 - €66,760 | €34,011 - €133,520 | 24% - 42% (progressive) |
| €66,761 - €277,825 | €133,521 - €555,650 | 42% |
| > €277,825 | > €555,650 | 45% |

### Solidarity Surcharge (Solidaritätszuschlag)

- **Rate:** 5.5% of income tax
- **Exemption threshold:** Most taxpayers with income < ~€100k (single) are exempt
- **For high earners:** Full 5.5% applies

### Church Tax (Kirchensteuer)

- **If member:** 8% (Bavaria, Baden-Württemberg) or 9% (other states) of income tax
- **If not member:** 0%

### Effective Marginal Rate Formula

```
For high earner (>€68,480 single, >€136,960 married):

baseRate = 42%
soli = baseRate × 5.5% = 2.31%
church = baseRate × 8% (if applicable) = 3.36%

WITHOUT church tax: 42% + 2.31% = 44.31%
WITH church tax: 42% + 2.31% + 3.36% = 47.67%
```

## Depreciation (AfA)

### Regular AfA

- **Rate:** 2% per year
- **Duration:** 50 years (buildings completed after 2023)
- **Basis:** Building cost (excluding land, ~92-94% of purchase price)

### Sonder-AfA §7b (Special Depreciation)

**Eligibility:**
- New construction (Neubau)
- Building permit application before January 1, 2027
- Living space < 4,000 m²
- Construction cost ≤ €5,200/m² (as of 2023 rules)

**Rates:**
- **5% per year** for first 4 years
- Runs PARALLEL to regular AfA
- Total depreciation years 1-4: 7% per year (5% + 2%)

**Building Portion Calculation:**
```
Total purchase price: €400,000
Land share estimate: 8%
Building portion: €400,000 × 92% = €368,000

Sonder-AfA (5%): €368,000 × 5% = €18,400/year
Regular AfA (2%): €368,000 × 2% = €7,360/year
Total years 1-4: €25,760/year deduction
```

## Deductible Expenses

### Fully Deductible

| Expense | Timing |
|---------|--------|
| Mortgage interest (Zinsen) | When paid |
| Property management (Verwaltung) | When paid |
| Maintenance and repairs | When paid |
| Insurance | When paid |
| Property tax (Grundsteuer) | When paid |
| Depreciation (AfA) | Annual claim |
| Travel for property inspection | When incurred |
| Legal/tax advisor fees | When paid |

### NOT Deductible

| Expense | Reason |
|---------|--------|
| Principal repayment (Tilgung) | Capital, not expense |
| Reserve fund contributions (Rücklage) | Not yet spent |
| Purchase price | Capitalized, depreciated |
| Acquisition costs (Nebenkosten) | Capitalized |

## Tax Benefit Calculation

### Annual Process

```
INCOME:
+ Rental income (Kaltmiete × 12)
─────────────────────────────────
= Gross rental income

DEDUCTIONS:
- Interest paid
- Verwaltung
- Sonder-AfA (if applicable)
- Regular AfA
- Other deductible expenses
─────────────────────────────────
= Total deductions

TAX RESULT:
Rental income - Deductions = Tax result

If NEGATIVE (loss):
Tax benefit = |Loss| × Marginal rate

If POSITIVE (profit):
Tax liability = Profit × Marginal rate
```

### Example: High Earner with Sonder-AfA

```
Investor: €224,000 gross income, married III/V, no church tax
Marginal rate: 44.31%

Property: €400,000, rent €1,000/month

Year 1 (with Sonder-AfA):
─────────────────────────
Rental income:      €12,000
Deductions:
  Interest:         -€14,000
  Verwaltung:       -€750
  Sonder-AfA:       -€18,400
  Regular AfA:      -€7,360
─────────────────────────
Tax loss:           -€28,510

Tax benefit: €28,510 × 44.31% = €12,633/year = €1,053/month

Year 5 (no Sonder-AfA):
─────────────────────────
Rental income:      €12,000
Deductions:
  Interest:         -€12,500 (declining)
  Verwaltung:       -€750
  Regular AfA:      -€7,360
─────────────────────────
Tax loss:           -€8,610

Tax benefit: €8,610 × 44.31% = €3,814/year = €318/month
```

## Spekulationsfrist (Speculation Period)

### Rule
- Private real estate sales are **tax-free after 10 years** of ownership
- Ownership period counts from notarized purchase contract date

### If Sold Before 10 Years
- Capital gain is taxed at personal income tax rate
- Gain = Sale price - Purchase price - Acquisition costs - Improvements
- Can be offset against losses from other sales

### Strategy Implication
- Standard FINYX strategy: Hold ≥10 years, sell tax-free
- Exit value projections assume tax-free sale

## Nebenkosten (Acquisition Costs)

### By State (Grunderwerbsteuer)

| State | Transfer Tax | Total NK (approx.) |
|-------|--------------|---------------------|
| Bavaria | 3.5% | 5.5% |
| Saxony | 5.5% | 7.5% |
| Baden-Württemberg | 5.0% | 7.0% |
| Hesse | 6.0% | 8.0% |
| Berlin | 6.0% | 8.0% |
| Brandenburg | 6.5% | 8.5% |
| NRW | 6.5% | 8.5% |
| Schleswig-Holstein | 6.5% | 8.5% |
| Thuringia | 6.5% | 8.5% |

### Components
- **Grunderwerbsteuer:** 3.5% - 6.5% (state-dependent)
- **Notar:** ~1.5%
- **Grundbuch:** ~0.5%
- **Broker (if any):** 3-6% (often buyer + seller split)

### Treatment
- NOT deductible as expense
- Added to purchase price for depreciation basis
- Paid upfront from equity (not financed)

## Refinancing Considerations

### At End of Fixed Rate Period

When 10-year fixed rate expires:
- Remaining balance needs refinancing
- New rate will be market rate at that time
- If rates higher: increased monthly payment
- If planning to sell: consider not refinancing

### Vorfälligkeitsentschädigung (Prepayment Penalty)

If selling before fixed period ends:
- Bank may charge penalty for lost interest
- Typically 1-2% of remaining balance
- Factor into early exit scenarios
