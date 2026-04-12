---
name: finyx-realestate
description: Real estate investment analysis for Germany — location scouting (Erbpacht, transport), property analysis (yield, Kaufnebenkosten, AfA), filtering, shortlist comparison, stress testing, advisor briefing, and mortgage rate research
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
---

<objective>

Unified real estate investment skill covering the full workflow from location scouting through to advisor briefing generation. Routes to the correct workflow based on user intent.

**Workflows available:**
- **Scout** — Research a location: Erbpacht, transport, market conditions
- **Analyze** — Extract units from price lists, calculate yield, cashflow, tax benefits
- **Filter** — Apply investor criteria, create shortlist and exclusions file
- **Compare** — Side-by-side shortlist comparison with decision framework
- **Stress-test** — Run 4 risk scenarios (0% appreciation, rate hike, vacancy, combined worst-case)
- **Report** — Generate advisor briefing (Markdown, PDF, multi-language)
- **Rates** — Research current German mortgage rates and compare with developer rate

**Workflow sequence:**
Scout → Analyze → Filter → Compare → Stress-test → Report

Agents used:
- `finyx-location-scout` — spawned by Scout workflow
- `finyx-analyzer-agent` — spawned by Analyze workflow
- `finyx-reporter-agent` — spawned by Report workflow

All outputs are written to `.finyx/` in the user's project. All guidance appends the legal disclaimer from the loaded disclaimer.md reference.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
${CLAUDE_SKILL_DIR}/references/methodology.md
${CLAUDE_SKILL_DIR}/references/erbpacht-detection.md
${CLAUDE_SKILL_DIR}/references/transport-assessment.md
@.finyx/profile.json

</execution_context>

<routing>

## Workflow Routing

Determine which workflow to execute based on user input:

| User says | Execute |
|-----------|---------|
| "scout [location]" / "research [location]" | Scout workflow |
| "analyze [location]" / "extract [location]" | Analyze workflow |
| "filter [location]" / "shortlist [location]" | Filter workflow |
| "compare" / "side by side" | Compare workflow |
| "stress test" / "stress-test" / "scenarios" | Stress-test workflow |
| "report" / "briefing" / "report --pdf" / "report --lang pt" | Report workflow |
| "rates" / "mortgage rates" / "Zinsen" | Rates workflow |

If intent is ambiguous, ask: "Which real estate workflow would you like to run? (scout / analyze / filter / compare / stress-test / report / rates)"

</routing>

---

# WORKFLOW 1: SCOUT

<scout_objective>

Research a location for real estate investment, gathering critical data:
- Development details (name, developer, size)
- Erbpacht status (CRITICAL - auto-exclude if undisclosed)
- Public transport quality
- Parking necessity assessment
- Market conditions

**Creates:** `.finyx/research/locations/[location].md`

**After this workflow:** Run analyze [location] to calculate metrics.

</scout_objective>

<scout_process>

## Phase 1: Validation

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Parse location argument:**
Extract location name from user input (e.g., "kassel" from "scout kassel")

**Check location folder:**
```bash
[ -d "properties/$LOCATION" ] && echo "EXISTS" || echo "NOT_FOUND"
```

If NOT_FOUND, ask user:
- "Location folder 'properties/[location]' not found. Create it?"
- If yes: `mkdir -p "properties/$LOCATION"`

## Phase 2: Document Discovery

**Scan for existing documents:**
```bash
find "properties/$LOCATION" -type f \( -name "*.pdf" -o -name "*.xlsx" -o -name "*.xls" \) 2>/dev/null
```

Note what's available:
- Price lists (Kaufpreisliste, Preisliste)
- Exposés/brochures
- Calculation examples (Berechnung)
- Floor plans

## Phase 3: Development Research

**Search for development information:**

Web searches:
- "[location] Neubau [current year]"
- "[development name if found in docs] [location]"
- "[developer name if found] [location] project"

**Extract:**
- Development name
- Developer/builder name
- Project size (number of units)
- Address
- Expected completion date
- Project concept (car-free, sustainable, etc.)

## Phase 4: Erbpacht Detection (CRITICAL)

**This is the most important check. Erbpacht with undisclosed costs = EXCLUDE.**

### 4.1 Document Search

Search documents for Erbpacht indicators:
```bash
grep -ri "erbpacht\|erbbaurecht\|erbbauzins" "properties/$LOCATION/" 2>/dev/null
```

### 4.2 Price List Analysis

If Excel price list available, check:
- Grundstücksanteil (land share) percentage
- If land share < 15% → ERBPACHT SUSPECTED

### 4.3 Web Search

Search for Erbpacht mentions:
- "[development name] [location] Erbpacht"
- "[development name] Erbbaurecht"
- "[developer name] ground lease"

### 4.4 Determination

**ERBPACHT STATUS:**
- `✅ NO ERBPACHT DETECTED` - No evidence found, proceed
- `⚠️ ERBPACHT SUSPECTED` - Indicators found, needs verification
- `🚨 ERBPACHT CONFIRMED` - Confirmed, check if costs disclosed

**If CONFIRMED:**
- Search for Erbbauzins (annual ground rent) amount
- Check remaining lease term
- If costs NOT disclosed → **RECOMMEND EXCLUSION**

## Phase 5: Transport Research

**Research public transport quality:**

Web searches:
- "[location] public transport network"
- "[location] tram bus S-Bahn"
- "[development name] location transport"
- "[location] ÖPNV"

**Extract:**
- Nearest public transport stop and distance
- Available lines (tram, bus, S-Bahn)
- Time to city center
- Network quality assessment (EXCELLENT/GOOD/MODERATE/POOR)

## Phase 6: Parking Assessment

**Based on transport quality + development concept:**

**If EXCELLENT transport AND development mentions:**
- "autofrei" (car-free)
- "autoarm" (car-reduced)
- "reduced traffic"
- "walkable"
- Urban location

→ **Parking: VALUABLE BUT NOT ESSENTIAL**

**If MODERATE/POOR transport OR:**
- Suburban location
- Family-oriented development
- Limited public transport

→ **Parking: ESSENTIAL**

## Phase 7: Market Research

**Research local market conditions:**

Web searches:
- "[location] housing market [current year]"
- "[location] Wohnungsmarkt"
- "[location] rental demand"
- "[location] property prices development"

**Extract:**
- Housing deficit/surplus
- Price trend
- Rental demand level
- Major employers/universities nearby

## Phase 8: Write Research File

Create `.finyx/research/locations/[location].md`:

```markdown
# Location Research: [LOCATION]

**Researched:** [DATE]
**Status:** [ACTIVE | EXCLUDED]
**Exclusion Reason:** [if excluded]

---

## Development Overview

| Item | Details |
|------|---------|
| Name | [DEVELOPMENT_NAME] |
| Developer | [DEVELOPER] |
| Address | [ADDRESS] |
| Size | [NUM_UNITS] units |
| Completion | [DATE] |
| Concept | [CONCEPT] |

---

## Erbpacht Status

**Status:** [✅ NO ERBPACHT DETECTED | ⚠️ SUSPECTED | 🚨 CONFIRMED]

[Details and evidence]

**Evidence:**
- [Evidence 1]
- [Evidence 2]

**Action:** [PROCEED | VERIFY | EXCLUDE]

---

## Public Transport

| Item | Details |
|------|---------|
| Nearest Stop | [STOP_NAME] ([DISTANCE]) |
| Lines | [LINES] |
| City Center | [MINUTES] minutes |
| Network Quality | [EXCELLENT/GOOD/MODERATE/POOR] |

**Assessment:** [TRANSPORT_ASSESSMENT]

---

## Parking Necessity

**Verdict:** [ESSENTIAL | VALUABLE BUT NOT ESSENTIAL | OPTIONAL]

**Reasoning:**
[Reasoning based on transport + development concept]

---

## Market Conditions

| Metric | Value | Source |
|--------|-------|--------|
| Housing Deficit | [VALUE] | [SOURCE] |
| Price Trend | [TREND]%/year | [SOURCE] |
| Rental Demand | [HIGH/MODERATE/LOW] | [SOURCE] |

---

## Documents Found

| File | Type | Notes |
|------|------|-------|
[Document list from properties folder]

---

## Sources

[List of web sources with URLs]

---

## Recommendation

**Status:** [PROCEED | CAUTION | EXCLUDE]

[Recommendation text]
```

## Phase 9: Update STATE.md

Add location to STATE.md:
```markdown
| [location] | 🔍 SCOUTED | - | - | [STATUS] |
```

## Phase 10: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► SCOUT: [LOCATION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Development: [NAME]
   Developer: [DEVELOPER]
   Units: [COUNT]

⚠️ Erbpacht: [STATUS]
   [Details if relevant]

🚇 Transport: [QUALITY]
   Nearest: [STOP] ([DISTANCE])

🅿️ Parking: [VERDICT]

📊 Market: [SUMMARY]

✅ Research saved: .finyx/research/locations/[location].md

📋 Next:
   [CONTEXTUAL - either analyze or exclude recommendation]
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</scout_process>

<erbpacht_rules>

## Erbpacht Detection Rules

### Document Indicators (HIGH confidence)
- Explicit "Erbpacht" or "Erbbaurecht" mention
- "Erbbauzins" (ground rent) mentioned
- Ground lease terms or expiration dates

### Price List Indicators (MEDIUM confidence)
- Grundstücksanteil < 15% of purchase price
- Separate "Gebäudeanteil" at >85%
- No land value in breakdown

### Web Indicators (MEDIUM confidence)
- Developer known for Erbpacht
- Location on church/municipal land
- Historical Erbpacht district

### Action Matrix

| Detection | Costs Disclosed | Action |
|-----------|-----------------|--------|
| Not detected | N/A | PROCEED |
| Suspected | N/A | VERIFY before proceeding |
| Confirmed | Yes, reasonable | PROCEED with caution |
| Confirmed | Yes, high | Calculate impact, likely EXCLUDE |
| Confirmed | No | **EXCLUDE** |

</erbpacht_rules>

---

# WORKFLOW 2: ANALYZE

<analyze_objective>

Analyze all properties in a location folder:
1. Extract units from price lists (Excel/PDF)
2. Calculate metrics (yield, price/m², cashflow)
3. Apply investor's tax rate for after-tax projections
4. Rank by real metrics (not brochure IRR)

**Creates:**
- `.finyx/analysis/[location]/UNITS.md` — All extracted units
- `.finyx/analysis/[location]/RANKED.md` — Sorted by metrics

**After this workflow:** Run filter [location] to apply criteria and create shortlist.

</analyze_objective>

<analyze_process>

## Phase 1: Validation

**Check profile and location:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
[ -d "properties/$LOCATION" ] || echo "NO_LOCATION"
```

**Load investor profile:**
Read `.finyx/profile.json` to get:
- `investor.marginalRate` — For tax benefit calculations
- `investor.country` — For country-specific rules
- `criteria.*` — For later filtering
- `assumptions.*` — For projections

## Phase 2: Find Price Lists

**Search for price list files:**
```bash
find "properties/$LOCATION" -type f \( -name "*[Pp]reis*" -o -name "*[Kk]aufpreis*" -o -name "*[Pp]rice*" \) \( -name "*.xlsx" -o -name "*.xls" -o -name "*.pdf" \)
```

**If Excel file found:** Extract data programmatically
**If PDF only:** May need manual extraction or OCR

## Phase 3: Extract Units

### From Excel Price List

For each row in the price list, extract:

| Field | Source Column (typical) |
|-------|------------------------|
| Unit ID | WE, Einheit, Unit |
| Floor | Etage, OG, Floor |
| Size (m²) | Wohnfläche, m², Size |
| Rooms | Zimmer, Rooms |
| Price | Kaufpreis, Price |
| Parking | Stellplatz, TG, Parking |
| Rent | Kaltmiete, Miete, Rent |
| Kitchen included | EBK, Küche |

**Calculate derived fields:**

```
Price per m² = Total Price ÷ Size
Gross Yield = (Monthly Rent × 12) ÷ Total Price × 100
```

### Handle Missing Rent Data

If rent not in price list, estimate:
- Check if developer calculation docs have rent estimates
- Use local market rate (€/m²) from research
- Flag as ESTIMATED

## Phase 4: Calculate Metrics Per Unit

**For each unit, calculate:**

### 4.1 Basic Metrics

```
Total Price = Unit Price + Kitchen (if not included) + Parking (if separate)
Price per m² = Total Price ÷ Size
Monthly Rent = Given or Estimated
Annual Rent = Monthly Rent × 12
Gross Yield = Annual Rent ÷ Total Price × 100
```

### 4.2 Upfront Cash (Kaufnebenkosten)

```
Nebenkosten = Total Price × NK_RATE (from config, typically 8%)
Construction Interest = Total Price × 50% × Interest Rate × (Construction Months ÷ 12)
Total Upfront = Nebenkosten + Construction Interest
```

### 4.3 Monthly Cashflow (Before Tax)

```
INCOME:
+ Monthly Rent

EXPENSES:
- Mortgage Payment = Total Price × (Interest Rate + Tilgung Rate) ÷ 12
- Verwaltung = Size × €1.00
- Rücklage = Size × €0.60

Real Deficit = Rent - Mortgage - Verwaltung - Rücklage
```

### 4.4 Tax Benefit Calculation

**Years 1-4 (with Sonder-AfA):**
```
Building Portion = Total Price × 92%
Annual Deductions:
  + Interest = Total Price × Interest Rate
  + Verwaltung = Size × €1.00 × 12
  + Sonder-AfA = Building Portion × 5%
  + Regular AfA = Building Portion × 2%

Tax Loss = Annual Rent - Annual Deductions
Tax Benefit Y1-4 = |Tax Loss| × Marginal Rate
Monthly Benefit Y1-4 = Tax Benefit Y1-4 ÷ 12
```

**Years 5-10 (Regular AfA only):**
```
Annual Deductions:
  + Interest (declining, estimate 85% of Y1)
  + Verwaltung
  + Regular AfA = Building Portion × 2%

Tax Loss = Annual Rent - Annual Deductions
Tax Benefit Y5-10 = |Tax Loss| × Marginal Rate
Monthly Benefit Y5-10 = Tax Benefit Y5-10 ÷ 12
```

### 4.5 After-Tax Cashflow

```
Cashflow Y1-4 = Real Deficit + Monthly Benefit Y1-4
Cashflow Y5-10 = Real Deficit + Monthly Benefit Y5-10
```

### 4.6 Exit Projection (Year 10)

```
Exit Value = Total Price × (1 + Appreciation Rate)^10
Sale Costs = Exit Value × 7%
Remaining Loan = Total Price × (1 - 10 years of Tilgung)
Net at Sale = Exit Value - Sale Costs - Remaining Loan

Total Cash Invested = Upfront + (Negative Cashflow over 10 years)
Profit = Net at Sale - Total Cash Invested
ROE = Profit ÷ Total Cash Invested × 100
```

## Phase 5: Write UNITS.md

Create `.finyx/analysis/[location]/UNITS.md`:

```markdown
# Units Analysis: [LOCATION]

**Analyzed:** [DATE]
**Source:** [PRICE_LIST_FILE]
**Total Units:** [COUNT]

## Summary

| Metric | Min | Max | Avg |
|--------|-----|-----|-----|
| Price | €[MIN] | €[MAX] | €[AVG] |
| Size | [MIN]m² | [MAX]m² | [AVG]m² |
| Price/m² | €[MIN] | €[MAX] | €[AVG] |
| Yield | [MIN]% | [MAX]% | [AVG]% |

## All Units

| Unit | Floor | Size | Rooms | Price | €/m² | Rent | Yield | Parking |
|------|-------|------|-------|-------|------|------|-------|---------|
[TABLE OF ALL UNITS]

## Calculation Assumptions

| Parameter | Value | Source |
|-----------|-------|--------|
| Marginal Tax Rate | [RATE]% | Investor profile |
| Interest Rate | [RATE]% | [SOURCE] |
| Tilgung | [RATE]% | [SOURCE] |
| Nebenkosten | [RATE]% | [STATE] standard |
| Construction Period | [MONTHS] months | [SOURCE] |
| Appreciation | [RATE]%/year | Conservative |
| Verwaltung | €[RATE]/m²/month | Standard |
| Rücklage | €[RATE]/m²/month | Standard |
```

## Phase 6: Write RANKED.md

Create `.finyx/analysis/[location]/RANKED.md`:

```markdown
# Ranked Units: [LOCATION]

**Ranked:** [DATE]
**Criteria:** Gross yield (primary), Price/m² (secondary)

## Top 10 by Yield

| Rank | Unit | Price | Size | Yield | €/m² | Parking | Cashflow Y1-4 | Cashflow Y5-10 |
|------|------|-------|------|-------|------|---------|---------------|----------------|
[TOP 10 BY YIELD]

## Top 10 by Value (Price/m²)

| Rank | Unit | Price | Size | Yield | €/m² | Parking | Floor |
|------|------|-------|------|-------|------|---------|-------|
[TOP 10 BY PRICE/M²]

## Units with Parking Included

| Unit | Price | Size | Yield | €/m² | Floor | Cashflow Y1-4 |
|------|-------|------|-------|------|-------|---------------|
[PARKING UNITS]

## Detailed Analysis: Top 5

[For each of top 5 by yield, show full calculation breakdown]

### [UNIT_ID]

**Basic Info:**
- Floor: [FLOOR]
- Size: [SIZE] m²
- Rooms: [ROOMS]
- Parking: [YES/NO]

**Pricing:**
- Unit Price: €[PRICE]
- Kitchen: [INCLUDED / €X]
- Parking: [INCLUDED / €X / NOT INCLUDED]
- **Total: €[TOTAL]**
- Price/m²: €[PRICE_M2]

**Income:**
- Monthly Rent: €[RENT]
- Annual Rent: €[ANNUAL]
- **Gross Yield: [YIELD]%**

**Upfront Cash:**
- Nebenkosten ([RATE]%): €[NK]
- Construction Interest: €[CONST_INT]
- **Total Upfront: €[TOTAL_UPFRONT]**

**Monthly Cashflow:**
```
Rent:           +€[RENT]
Mortgage:       -€[MORTGAGE]
Verwaltung:     -€[VERWALTUNG]
Rücklage:       -€[RUCKLAGE]
─────────────────────────────
Real Deficit:   €[DEFICIT]/month

Tax Benefit Y1-4:  +€[BENEFIT_Y1_4]
After-Tax Y1-4:    €[CASHFLOW_Y1_4]/month ✓

Tax Benefit Y5-10: +€[BENEFIT_Y5_10]
After-Tax Y5-10:   €[CASHFLOW_Y5_10]/month
```

**10-Year Projection:**
- Total Cash Invested: €[TOTAL_INVESTED]
- Exit Value (2%/yr): €[EXIT_VALUE]
- Net at Sale: €[NET_SALE]
- **Profit: €[PROFIT]**
- **ROE: [ROE]%**
```

## Phase 7: Update STATE.md

Update location status in STATE.md:
```markdown
| [location] | 📊 ANALYZED | [COUNT] | - | Active |
```

## Phase 8: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► ANALYZE: [LOCATION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Extracted [COUNT] units from [PRICE_LIST]

Yield Range:    [MIN]% - [MAX]%
Price Range:    €[MIN] - €[MAX]
Size Range:     [MIN]m² - [MAX]m²

Top 5 by Yield:
1. [UNIT] - [YIELD]% - €[PRICE] - [SIZE]m²
2. [UNIT] - [YIELD]% - €[PRICE] - [SIZE]m²
3. [UNIT] - [YIELD]% - €[PRICE] - [SIZE]m²
4. [UNIT] - [YIELD]% - €[PRICE] - [SIZE]m²
5. [UNIT] - [YIELD]% - €[PRICE] - [SIZE]m²

Units with Parking: [COUNT]

✅ Analysis saved:
   .finyx/analysis/[location]/UNITS.md
   .finyx/analysis/[location]/RANKED.md

📋 Next: filter [location] to apply criteria
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</analyze_process>

<analyze_notes>

## Excel Extraction Tips

When reading Excel price lists:
- Headers are often in row 1 or 2
- Look for merged cells in headers
- Unit IDs may have prefixes (WE, Whg, etc.)
- Prices may be formatted with currency symbols
- Some cells may have formulas

## Handling Edge Cases

- **No rent data:** Use market rate estimate, flag as estimated
- **Multiple buildings:** Analyze as separate locations or combine
- **Missing parking info:** Assume no parking unless stated
- **Kitchen unclear:** Check exposé or assume not included

</analyze_notes>

---

# WORKFLOW 3: FILTER

<filter_objective>

Apply investor's criteria to analyzed units and create a filtered shortlist:
1. Load criteria from config
2. Apply filters (yield, price, size, parking, floor)
3. Document exclusions with reasons
4. Create shortlist of qualifying units

**Creates:**
- `.finyx/analysis/[location]/SHORTLIST.md` — Qualifying units
- `.finyx/analysis/[location]/EXCLUSIONS.md` — Excluded units with reasons

**After this workflow:** Run compare to compare across locations.

</filter_objective>

<filter_process>

## Phase 1: Load Data

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Load profile:**
Read `.finyx/profile.json` for criteria:
- `criteria.minYield`
- `criteria.maxPrice`
- `criteria.minSize` / `criteria.maxSize`
- `criteria.bedrooms`
- `criteria.parkingRequired`
- `criteria.excludeGroundFloor`
- `criteria.excludeErbpacht`

**Load analyzed units:**
Read `.finyx/analysis/[location]/UNITS.md`

## Phase 2: Apply Filters

**For each unit, check against criteria:**

```
PASS/FAIL Criteria:
─────────────────────────────────────────
□ Yield ≥ [minYield]%
□ Price ≤ €[maxPrice]
□ Size between [minSize] - [maxSize] m²
□ Bedrooms in [bedrooms] list
□ If parkingRequired: has parking
□ If excludeGroundFloor: not ground floor
□ If excludeErbpacht: no Erbpacht detected
```

**Track exclusion reasons:**
- "Yield below minimum (X% < Y%)"
- "Price exceeds maximum (€X > €Y)"
- "Size outside range (Xm²)"
- "Wrong bedroom count"
- "No parking (required)"
- "Ground floor (excluded)"

## Phase 3: Rank Qualifying Units

**Sort qualifying units by:**
1. Gross yield (descending)
2. Price per m² (ascending)
3. Cashflow Y1-4 (descending)

## Phase 4: Write SHORTLIST.md

Create `.finyx/analysis/[location]/SHORTLIST.md`:

```markdown
# Shortlist: [LOCATION]

**Filtered:** [DATE]
**Total Units Analyzed:** [TOTAL]
**Units Qualifying:** [QUALIFYING]
**Units Excluded:** [EXCLUDED]

## Criteria Applied

| Criterion | Value | Units Excluded |
|-----------|-------|----------------|
| Min Yield | [X]% | [N] |
| Max Price | €[X] | [N] |
| Size Range | [X]-[Y] m² | [N] |
| Bedrooms | [X] | [N] |
| Parking Required | [YES/NO] | [N] |
| Exclude Ground Floor | [YES/NO] | [N] |

## Shortlisted Units

| Rank | Unit | Price | Size | Yield | €/m² | Parking | Floor | Y1-4 | Y5-10 | Profit |
|------|------|-------|------|-------|------|---------|-------|------|-------|--------|
[SHORTLIST TABLE]

## Top 3 Detailed

### 1. [UNIT_ID] — [HEADLINE]

[Full analysis breakdown - same format as RANKED.md top 5]

### 2. [UNIT_ID] — [HEADLINE]

[Full analysis breakdown]

### 3. [UNIT_ID] — [HEADLINE]

[Full analysis breakdown]

## Selection Notes

[Any observations about the shortlist - e.g., "All top units lack parking but location research indicates parking not essential"]
```

## Phase 5: Write EXCLUSIONS.md

Create `.finyx/analysis/[location]/EXCLUSIONS.md`:

```markdown
# Exclusions: [LOCATION]

**Date:** [DATE]
**Total Excluded:** [COUNT]

## By Reason

| Reason | Count | % of Total |
|--------|-------|------------|
| Yield below [X]% | [N] | [%] |
| Price above €[X] | [N] | [%] |
| Size out of range | [N] | [%] |
| No parking | [N] | [%] |
| Ground floor | [N] | [%] |

## Excluded Units

| Unit | Price | Yield | Reason |
|------|-------|-------|--------|
[EXCLUSION TABLE]

## Near Misses

Units that ALMOST qualified (within 10% of criteria):

| Unit | Price | Yield | Issue | How Close |
|------|-------|-------|-------|-----------|
[NEAR MISS TABLE]
```

## Phase 6: Update STATE.md

Update location status:
```markdown
| [location] | ✅ FILTERED | [TOTAL] | [SHORTLIST_COUNT] | Active |
```

## Phase 7: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► FILTER: [LOCATION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Criteria Applied:
  Min Yield:     [X]%
  Max Price:     €[X]
  Size Range:    [X]-[Y] m²
  Parking:       [Required/Preferred/Any]
  Ground Floor:  [Excluded/Allowed]

Results:
  Analyzed:      [TOTAL] units
  Excluded:      [EXCLUDED] units
  Shortlisted:   [QUALIFYING] units

Shortlist:
1. [UNIT] - €[PRICE] - [YIELD]% - [SIZE]m² [PARKING]
2. [UNIT] - €[PRICE] - [YIELD]% - [SIZE]m² [PARKING]
3. [UNIT] - €[PRICE] - [YIELD]% - [SIZE]m² [PARKING]

✅ Saved:
   .finyx/analysis/[location]/SHORTLIST.md
   .finyx/analysis/[location]/EXCLUSIONS.md

📋 Next:
   filter [other-location]  Filter another location
   compare                  Compare all shortlists
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</filter_process>

<filter_edge_cases>

## No Units Qualify

If zero units pass all criteria:

```
⚠️ No units in [LOCATION] meet all criteria.

Closest matches:
[Show top 5 by fewest criteria failures]

Consider:
• Relaxing minYield from [X]% to [Y]%
• Increasing maxPrice from €[X] to €[Y]
• Adjusting size range
```

## Very Few Units Qualify

If <3 units qualify, suggest relaxing least important criteria.

## Manual Exclusions

If user has manually excluded units, respect those:
```
Additionally excluded by user:
• [UNIT] - "[REASON]"
```

</filter_edge_cases>

---

# WORKFLOW 4: COMPARE

<compare_objective>

Create comprehensive side-by-side comparison of all shortlisted properties:
- Gather shortlists from all analyzed locations
- Present unified comparison table
- Provide decision framework for each option
- Highlight trade-offs

**Output:** Display comparison and update `.finyx/STATE.md` with comparison status.

**After this workflow:** Run stress-test for scenarios, or report to generate advisor briefing.

</compare_objective>

<compare_process>

## Phase 1: Gather Shortlists

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Find all shortlist files:**
```bash
find .finyx/analysis -name "SHORTLIST.md" 2>/dev/null
```

**For each shortlist, extract:**
- Location name
- Shortlisted units with all metrics

**If no shortlists found:**
"No shortlists created yet. Run filter [location] first."

## Phase 2: Load Investor Profile

Read `.finyx/profile.json` for:
- Liquid assets (for buffer calculation)
- Criteria (for highlighting matches)
- Preferences (parking, floor, etc.)

## Phase 3: Build Comparison Table

**Display banner:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► COMPARE SHORTLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Main Comparison Table:**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           SHORTLIST COMPARISON                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│ Unit       │ Price    │ Upfront │ Size   │ Yield │ Parking │ Y1-4    │ Y5-10   │
├────────────┼──────────┼─────────┼────────┼───────┼─────────┼─────────┼─────────┤
│ kassel/0.18│ €272,403 │ €27,762 │ 47.8m² │ 3.16% │ ❌      │ +€175   │ -€351   │
│ kassel/4.1 │ €377,761 │ €38,503 │ 62.7m² │ 2.95% │ ✅      │ +€212   │ -€517   │
│ kassel/3.7 │ €401,535 │ €40,926 │ 73.8m² │ 3.20% │ ❌      │ +€262   │ -€514   │
└────────────┴──────────┴─────────┴────────┴───────┴─────────┴─────────┴─────────┘
```

**Extended Metrics Table:**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           10-YEAR PROJECTIONS                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│ Unit       │ Total Invested │ Exit Value │ Net at Sale │ Profit  │ ROE    │
├────────────┼────────────────┼────────────┼─────────────┼─────────┼────────┤
│ kassel/0.18│ €44,634        │ €332,015   │ €75,274     │ €30,640 │ 69%    │
│ kassel/4.1 │ €65,551        │ €460,468   │ €104,535    │ €38,984 │ 59%    │
│ kassel/3.7 │ €65,358        │ €489,471   │ €111,108    │ €45,750 │ 70%    │
└────────────┴────────────────┴────────────┴─────────────┴─────────┴────────┘
```

## Phase 4: Metric Winners

**Highlight best in each category:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WINNERS BY METRIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 Lowest Price:        [UNIT] (€[PRICE])
🏆 Lowest Upfront:      [UNIT] (€[UPFRONT])
🏆 Highest Yield:       [UNIT] ([YIELD]%)
🏆 Best €/m²:           [UNIT] (€[PRICE_M2])
🏆 Parking Included:    [UNIT]
🏆 Best Y1-4 Cashflow:  [UNIT] (+€[CASHFLOW]/mo)
🏆 Lowest Y5-10 Bleed:  [UNIT] (-€[CASHFLOW]/mo)
🏆 Highest Profit:      [UNIT] (€[PROFIT])
🏆 Highest ROE:         [UNIT] ([ROE]%)
🏆 Largest Unit:        [UNIT] ([SIZE]m²)
```

## Phase 5: Liquidity Impact

**Show remaining buffer after each option:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LIQUIDITY IMPACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Available Assets: €[LIQUID_ASSETS]

│ Unit       │ Upfront  │ Remaining │ Y5-10 Annual │ Buffer Years │
├────────────┼──────────┼───────────┼──────────────┼──────────────┤
│ [UNIT]     │ €[UP]    │ €[REM]    │ €[ANNUAL]    │ [YEARS] years│

✅ All options leave comfortable buffers.
```

## Phase 6: Decision Framework

**Present "Choose X if..." for each option:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 DECISION FRAMEWORK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────────┐
│ CHOOSE [UNIT] IF:                                   │
├─────────────────────────────────────────────────────┤
│ • [Condition 1]                                     │
│ • [Condition 2]                                     │
│                                                     │
│ TRADE-OFF: [What this unit lacks]                   │
└─────────────────────────────────────────────────────┘
```

## Phase 7: Parking Consideration

**If mixed parking options exist:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PARKING ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Based on location research:
[PARKING_VERDICT from scout] - [REASONING]
```

## Phase 8: Next Actions

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 stress-test    Run 0% appreciation & rate hike scenarios
📝 report         Generate advisor briefing
📝 report --lang pt  Generate in Portuguese

When ready to decide:
• Visit the development if possible
• Confirm financing with bank
• Consult your tax advisor
• Reserve your chosen unit
```

## Phase 9: Update STATE.md

Update state to reflect comparison done:
```markdown
### Phase: COMPARED
### Last Action: Side-by-side comparison of [N] shortlisted units
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</compare_process>

---

# WORKFLOW 5: STRESS-TEST

<stress_objective>

Run stress test scenarios on shortlisted properties:
1. Zero appreciation scenario (0% growth over 10 years)
2. Interest rate hike scenario (rates increase at refinancing)
3. Vacancy scenario (extended periods without rent)
4. Combined worst-case scenario

**Creates:** `.finyx/analysis/STRESS-TEST.md`

**After this workflow:** Run report to include stress test results in advisor briefing.

</stress_objective>

<stress_process>

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

## Recommendations

### If Risk Tolerance is LOW:
Choose: [UNIT] - [REASON]

### If Risk Tolerance is MEDIUM:
Choose: [UNIT] - [REASON]

### If Risk Tolerance is HIGH:
Choose: [UNIT] - [REASON]

## Mitigating Factors

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
   report          Generate advisor briefing
   report --lang pt  Generate in Portuguese
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</stress_process>

<stress_scenarios>

## Custom Scenarios

Users can request additional scenarios:

### `stress-test --rent-drop 10`
Model 10% rent decrease scenario.

### `stress-test --rate 5.5`
Model specific interest rate scenario.

### `stress-test --vacancy 6`
Model 6 months vacancy per 2 years.

</stress_scenarios>

---

# WORKFLOW 6: REPORT

<report_objective>

Generate a comprehensive financial advisor briefing document:
1. Load all analysis data (config, research, shortlists)
2. Fill briefing template with calculated data
3. Translate if language specified
4. Save to output folder

**Creates:** `.finyx/output/BRIEFING-[DATE].md`

**Usage:**
- `report` — Full advisor briefing (Markdown)
- `report --short` — 1-page executive summary
- `report --pdf` — Generate PDF report
- `report --short --pdf` — 1-page PDF summary
- `report --lang pt` — Generate in Portuguese
- `report --short --pdf --lang de` — Short PDF in German

</report_objective>

<short_report>

## Short Report Format (--short flag)

When `--short` is specified, generate a **1-page executive summary** instead of the full briefing.

**Creates:** `.finyx/output/SUMMARY-[DATE].md`

### Template

```markdown
# Investment Summary: [LOCATION]

**Date:** [DATE] | **Investor:** [TAX_CLASS] | **Tax Rate:** [RATE]%

---

## Top 5 Options

| Unit | Price | Yield | Upfront | Y1-4/mo | Y5-10/mo | 10yr Profit | ROE |
|------|-------|-------|---------|---------|----------|-------------|-----|
| [1]  | €XXX  | X.X%  | €XX     | +€XX    | -€XX     | €XXk        | XX% |

**Winners:** Yield: [UNIT] | Lowest Price: [UNIT] | Best ROE: [UNIT] | Parking: [UNIT]

---

## Recommendation

**Top Pick:** [UNIT_ID] — €[PRICE] — [YIELD]% yield

### Why This Unit?

1. **[REASON 1]** — [Brief explanation]
2. **[REASON 2]** — [Brief explanation]
3. **[REASON 3]** — [Brief explanation]

### Trade-offs to Accept

- [Trade-off 1]
- [Trade-off 2]

### Alternative: [UNIT_ID]

Choose this if: [One sentence explaining when alternative is better]

---

## Key Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Negative cashflow Y5-10 | -€[X]/mo | Covered by buffer (€[X] available) |
| 0% appreciation | -€[X]k profit | Still break-even / modest loss |
| Rate hike at refinancing | +€[X]/mo | Can sell tax-free at Y10 |

---

## Questions for Your Advisor

1. **Interest Rate:** Developer offers [X]%. Can we get [Y]%? (Saves €[Z] over 10 years)
2. **Tax Optimization:** With [INCOME] income and [TAX_CLASS], is 100% financing optimal?
3. **Timing:** Construction completes [DATE]. Any tax implications for [YEAR]?
4. **Exit Strategy:** Sell at year 10 tax-free vs. hold longer — what's your view?
5. **Portfolio Fit:** How does this fit with existing investments/pension strategy?

---

## Next Steps

1. [ ] Discuss with advisor using this summary
2. [ ] Get financing quotes (target: [X]%)
3. [ ] Visit development if possible
4. [ ] Reserve unit within [X] days if proceeding

---

*Full analysis: Run `report` for detailed briefing*
```

### Short Report Generation Logic

1. **Top 5 Selection:** Take top 5 from shortlist ranked by yield
2. **Recommendation:** Highest yield unit with parking preference satisfied (if required)
3. **Why Reasons:** Pull from yield ranking, price efficiency, cashflow, size, risk
4. **Trade-offs:** What the chosen unit lacks vs alternatives
5. **Alternative:** Second-best option with different characteristics
6. **Risks:** Top 3 from stress test results
7. **Questions:** Derive from analysis gaps and optimization opportunities

</short_report>

<report_process>

## Phase 1: Load All Data

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Load investor profile:**
Read `.finyx/profile.json`

**Load location research:**
Read all `.finyx/research/locations/*.md`

**Load market research:**
Read `.finyx/research/market/RATES-*.md` (latest)

**Load shortlists:**
Read all `.finyx/analysis/*/SHORTLIST.md`

**Verify data completeness:**
- Config exists ✓
- At least one shortlist exists ✓
- Interest rate research exists (if not, fetch current rates)

## Phase 2: Compile Report Data

**From profile.json:**
- Investor profile (income, tax rate, assets)
- Investment criteria
- Assumptions

**From research:**
- Location details
- Erbpacht status
- Transport assessment
- Parking verdict
- Excluded locations with reasons

**From shortlists:**
- All shortlisted units
- Full metrics for each
- Comparison data

**Calculate:**
- Summary statistics
- Winner by each metric
- Liquidity impact

## Phase 3: Interest Rate Section

**If rate research exists:**
Use data from `.finyx/research/market/RATES-*.md`

**If no rate research:**
Perform quick web search for current rates:
- "Baufinanzierung Zinsen aktuell [year]"
- Extract top rate, typical range

**Compare with developer rate:**
Calculate difference and potential savings.

## Phase 4: Load Template

Read template from `${CLAUDE_SKILL_DIR}/references/briefing.md`

## Phase 5: Fill Template

Replace all `{{PLACEHOLDER}}` variables with actual data.

**Key sections to fill:**

### Executive Summary
```
{{INVESTMENT_DESCRIPTION}} → "Investment in 2-bedroom apartment in [LOCATION], Germany..."
{{UNITS_TABLE}} → Shortlist comparison table
{{GROSS_INCOME}} → From profile
{{MARGINAL_TAX_RATE}} → From profile
{{LIQUID_ASSETS}} → From profile
{{CASHFLOW_Y1_4}} → Range from shortlist
{{CASHFLOW_Y5_10}} → Range from shortlist
{{PROFIT_RANGE}} → Range from shortlist
{{MAIN_CONCERNS}} → Interest rate, negative cashflow, appreciation risk
```

### Priority Questions
```
{{DEVELOPER_RATE}} → From analysis assumptions
{{MARKET_RATE}} → From rate research
{{INTEREST_SAVINGS}} → Calculated savings
{{TAX_BENEFIT_RANGE}} → From shortlist calculations
{{REMAINING_LIQUIDITY}} → Assets - Upfront costs
{{ANNUAL_OUTLAY_Y5_10}} → From shortlist
```

### Investor Profile
All fields from profile.json

### Location Section
```
{{LOCATION}} → Location name
{{DEVELOPMENT_NAME}} → From research
{{DEVELOPMENT_TABLE}} → Details from research
{{TRANSPORT_TABLE}} → From research
{{PARKING_DESCRIPTION}} → From research
{{EXCLUSIONS_TABLE}} → Excluded locations with reasons
```

### Units Comparison
```
{{UNIT_HEADERS}} → Unit IDs
{{GENERAL_COMPARISON_TABLE}} → Full comparison
```

### Financing Section
```
{{INTEREST_RATE}} → From assumptions
{{MARKET_RATES_TABLE}} → From rate research
{{RATE_DIFFERENCE}} → Calculated
{{RATE_IMPACT_BY_UNIT}} → Savings per unit
```

### Cashflow Section
```
{{CASHFLOW_BY_UNIT}} → Detailed breakdown per unit
```

### Exit Analysis
```
{{EXIT_TABLE}} → 10-year projections
{{CASH_POSITION_BY_UNIT}} → Running totals
```

### Stress Tests
```
{{STRESS_0_APPRECIATION_TABLE}} → 0% scenario
{{STRESS_APPRECIATION_CONCLUSION}} → Analysis
{{STRESS_INTEREST_ANALYSIS}} → Rate hike impact
```

### Decision Framework
```
{{DECISION_FRAMEWORK_BY_UNIT}} → "Choose X if..." for each
{{PARKING_CONSIDERATION}} → From research
```

## Phase 6: Translation (if requested)

**If --lang specified:**

Translate the entire filled document to requested language:
- `pt` → Brazilian Portuguese
- `de` → German
- `es` → Spanish

**Translation notes:**
- Keep technical terms with German originals in parentheses
- Maintain table structure
- Preserve number formatting for target locale
- Keep emoji indicators

## Phase 7: Write Report

**Generate filename:**
`BRIEFING-[YYYY-MM-DD].md`

If file exists, append counter: `BRIEFING-[DATE]-2.md`

**Write to:**
`.finyx/output/BRIEFING-[DATE].md`

## Phase 8: PDF Generation (if --pdf specified)

**If `--pdf` flag is present:**

### Step 1: Check for PDF converter

Try converters in order of preference:

```bash
# Check for pandoc (best quality)
command -v pandoc >/dev/null 2>&1 && echo "PANDOC"

# Check for mdpdf
command -v mdpdf >/dev/null 2>&1 && echo "MDPDF"

# Check for md-to-pdf via npx
npx --yes md-to-pdf --version >/dev/null 2>&1 && echo "MD_TO_PDF"
```

### Step 2: Convert to PDF

**Using pandoc (preferred):**
```bash
pandoc "[MARKDOWN_FILE]" \
  -o "[PDF_FILE]" \
  --pdf-engine=xelatex \
  -V geometry:margin=2.5cm \
  -V fontsize=11pt \
  -V colorlinks=true \
  -V linkcolor=blue \
  --toc \
  --toc-depth=2
```

**If xelatex not available, try with default engine:**
```bash
pandoc "[MARKDOWN_FILE]" \
  -o "[PDF_FILE]" \
  -V geometry:margin=2.5cm \
  -V fontsize=11pt
```

**Using md-to-pdf (fallback):**
```bash
npx --yes md-to-pdf "[MARKDOWN_FILE]"
```

**Using mdpdf (alternative):**
```bash
mdpdf "[MARKDOWN_FILE]" "[PDF_FILE]"
```

### Step 3: Verify PDF created

```bash
[ -f "[PDF_FILE]" ] && echo "PDF created successfully"
```

### PDF Filenames

- Full report: `.finyx/output/BRIEFING-[DATE].pdf`
- Short report: `.finyx/output/SUMMARY-[DATE].pdf`

### If no converter available

Display:
```
⚠️ PDF generation requires a converter. Install one of:

Option 1 - Pandoc (recommended):
  brew install pandoc          # macOS
  apt install pandoc           # Ubuntu/Debian

  For best results, also install LaTeX:
  brew install --cask mactex   # macOS
  apt install texlive-xetex    # Ubuntu/Debian

Option 2 - md-to-pdf (Node.js):
  npm install -g md-to-pdf

Option 3 - mdpdf (Node.js):
  npm install -g mdpdf

Markdown report saved: [MARKDOWN_FILE]
Convert manually or install a converter and run again.
```

## Phase 9: Update STATE.md

```markdown
### Phase: REPORTED
### Last Action: Generated advisor briefing
### Report: .finyx/output/BRIEFING-[DATE].md
### PDF: .finyx/output/BRIEFING-[DATE].pdf (if generated)
```

## Phase 10: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► REPORT GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Markdown: .finyx/output/BRIEFING-[DATE].md
📄 PDF:      .finyx/output/BRIEFING-[DATE].pdf  (if --pdf)
🌐 Language: [LANGUAGE]

Contents:
  ✓ Executive Summary
  ✓ Priority Questions (10)
  ✓ Investor Profile
  ✓ Location Analysis
  ✓ [N] Units Compared
  ✓ Financing Analysis
  ✓ Interest Rate Comparison
  ✓ Cashflow Projections
  ✓ Tax Benefit Breakdown
  ✓ 10-Year Exit Analysis
  ✓ Risk Analysis
  ✓ Stress Tests
  ✓ Decision Framework
  ✓ Advisor Questions

📋 Next Steps:
  1. Review the report
  2. Share with your financial advisor
  3. Schedule consultation to discuss
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</report_process>

<language_support>

## Supported Languages

| Code | Language | Notes |
|------|----------|-------|
| en | English | Default |
| pt | Brazilian Portuguese | Investor's advisor language |
| de | German | For German advisors |
| es | Spanish | Basic support |

## Translation Guidelines

**Keep original German terms:**
- AfA (Absetzung für Abnutzung)
- Sonder-AfA
- Nebenkosten (Kaufnebenkosten)
- Spekulationsfrist
- Tilgung
- Kaltmiete

**Provide translation in parentheses on first use:**
- "Sonder-AfA (depreciação especial)"
- "Nebenkosten (custos de aquisição)"

**Number formatting by locale:**
- English: €272,403
- Portuguese: €272.403
- German: 272.403 €

</language_support>

---

# WORKFLOW 7: RATES

<rates_objective>

Research current mortgage interest rates in Germany:
1. Search for current market rates
2. Compare with developer-provided rates
3. Calculate potential savings
4. Provide negotiation recommendations

**Creates:** `.finyx/research/market/RATES-[DATE].md`

</rates_objective>

<rates_process>

## Phase 0: Pre-flight Check

```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

## Phase 1: Web Research

**Search for current rates:**

Queries:
- "Baufinanzierung Zinsen aktuell [current year]"
- "Hypothekenzinsen [current month] [current year]"
- "mortgage rates Germany [current year]"

**Target sources:**
- Dr. Klein (drklein.de)
- Baufi24 (baufi24.de)
- Interhyp (interhyp.de)
- Finanztip (finanztip.de)

## Phase 2: Extract Rate Data

**For each fixed period, extract:**

| Period | Top Rate | Typical Range |
|--------|----------|---------------|
| 5 years | X.XX% | X.XX% - X.XX% |
| 10 years | X.XX% | X.XX% - X.XX% |
| 15 years | X.XX% | X.XX% - X.XX% |
| 20 years | X.XX% | X.XX% - X.XX% |

**Note effective date of data.**

## Phase 3: Compare with Developer Rate

**Load developer rate from analysis:**
- Check `.finyx/analysis/*/RANKED.md` for assumed rate
- Or from profile assumptions

**Calculate difference:**
```
Developer rate:    X.XX%
Market top rate:   X.XX%
Difference:        X.XX%
```

## Phase 4: Calculate Savings

**For each shortlisted unit, calculate:**

```
Loan amount: €[PRICE]
10-year difference at 0.15% lower rate:

Monthly interest savings: Loan × 0.15% ÷ 12
Annual savings: Monthly × 12
10-year savings: Annual × 10 (simplified)
```

## Phase 5: Rate Forecast

**Search for forecasts:**
- "Zinsprognose [current year]"
- "mortgage rate forecast Germany"

**Extract:**
- Expected direction (up/down/stable)
- Expected range
- Key factors (ECB policy, inflation)

## Phase 6: Write Research File

Create `.finyx/research/market/RATES-[DATE].md`:

```markdown
# Interest Rate Research

**Date:** [DATE]
**Sources:** [LIST]

## Current Market Rates

| Fixed Period | Top Rate | Typical Range | Notes |
|--------------|----------|---------------|-------|
| 5 years | X.XX% | X.XX% - X.XX% | |
| 10 years | X.XX% | X.XX% - X.XX% | Most common |
| 15 years | X.XX% | X.XX% - X.XX% | |
| 20 years | X.XX% | X.XX% - X.XX% | |

**Effective date:** [DATE]

## Comparison with Developer Rate

| Metric | Developer | Market Top | Difference |
|--------|-----------|------------|------------|
| 10-year fixed | X.XX% | X.XX% | X.XX% |

**Assessment:** Developer rate is [ABOVE/AT/BELOW] current market.

## Savings Potential

**If investor achieves market top rate:**

| Unit | Loan | Monthly Savings | 10-Year Savings |
|------|------|-----------------|-----------------|
| [UNIT] | €[LOAN] | €[MONTHLY] | €[TOTAL] |

## Why Investor Should Get Better Rate

1. **High income:** €[INCOME]/year = excellent repayment capacity
2. **Strong assets:** €[ASSETS] liquid = low risk for bank
3. **Stable employment:** [IF KNOWN]
4. **No significant debts:** Good debt-to-income ratio

## Rate Forecast

**[TIMEFRAME] Outlook:**
- Direction: [UP/DOWN/STABLE]
- Expected range: X.XX% - X.XX%
- Key factors: [FACTORS]

**Source:** [SOURCE]

## Recommendation

### Target Rate: X.XX% - X.XX%

### Institutions to Quote

1. **Interhyp** - Broker, compares 500+ banks
2. **Dr. Klein** - Broker
3. **ING-DiBa** - Direct bank, often competitive
4. **Investor's main bank** - May offer loyalty discount

### Negotiation Tips

- Get quotes from 3+ sources before deciding
- Use competing offers as leverage
- Ask about special conditions for high income
- Consider shorter fixed period if rates expected to drop
- Factor in fees when comparing (some brokers charge)

## Sources

[List all sources with URLs and access dates]
```

## Phase 7: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INTEREST RATE RESEARCH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Current Market Rates (10-year fixed):
   Top rate:     X.XX%
   Typical:      X.XX% - X.XX%

📈 Developer Rate: X.XX%
   Difference:   X.XX% ABOVE market

💰 Potential Savings:
   [UNIT]: €X,XXX over 10 years

🎯 Target Rate: X.XX% - X.XX%

✅ Research saved: .finyx/research/market/RATES-[DATE].md

📋 Recommendation:
   Quote Interhyp, Dr. Klein, and your bank before accepting
   developer's rate. Your profile should qualify for top rates.
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</rates_process>

---

<error_handling>

## Common Errors

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No location folder:**
```
ERROR: Properties folder 'properties/[location]' not found.
Create it and add price list documents before running analyze.
```

**No shortlists for compare/stress-test/report:**
```
ERROR: No shortlists found.
Run filter [location] first to create shortlists.
```

**No price lists for analyze:**
```
ERROR: No price list files found in properties/[location].
Add Excel (.xlsx, .xls) or PDF price list files before analyzing.
```

</error_handling>

<notes>

## Workflow Sequence

The recommended sequence is:
1. scout [location] — research viability
2. analyze [location] — extract and calculate
3. filter [location] — apply criteria
4. compare — side-by-side
5. stress-test — risk scenarios
6. report — advisor briefing

Steps 4-6 are optional. You can generate a report after filtering without comparing or stress-testing.

## Multiple Locations

- Scout and analyze each location independently
- filter each location
- compare consolidates ALL shortlists from all locations
- report covers all analyzed locations

## Agents

This skill uses three specialist agents via the Task tool:
- `finyx-location-scout` — Web research for scout workflow
- `finyx-analyzer-agent` — Price list extraction and metric calculation
- `finyx-reporter-agent` — Report generation and formatting

</notes>
