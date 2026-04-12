---
name: finyx:report
description: Generate professional financial advisor briefing from analysis
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
  - WebSearch
---

<objective>

Generate a comprehensive financial advisor briefing document:
1. Load all analysis data (config, research, shortlists)
2. Fill briefing template with calculated data
3. Translate if language specified
4. Save to output folder

**Creates:** `.finyx/output/BRIEFING-[DATE].md`

**Usage:**
- `/finyx:report` — Full advisor briefing (Markdown)
- `/finyx:report --short` — 1-page executive summary
- `/finyx:report --pdf` — Generate PDF report
- `/finyx:report --short --pdf` — 1-page PDF summary
- `/finyx:report --lang pt` — Generate in Portuguese
- `/finyx:report --short --pdf --lang de` — Short PDF in German

</objective>

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
| [2]  | €XXX  | X.X%  | €XX     | +€XX    | -€XX     | €XXk        | XX% |
| [3]  | €XXX  | X.X%  | €XX     | +€XX    | -€XX     | €XXk        | XX% |
| [4]  | €XXX  | X.X%  | €XX     | +€XX    | -€XX     | €XXk        | XX% |
| [5]  | €XXX  | X.X%  | €XX     | +€XX    | -€XX     | €XXk        | XX% |

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

*Full analysis: Run `/finyx:report` for detailed briefing*
```

### Short Report Generation Logic

1. **Top 5 Selection:** Take top 5 from shortlist ranked by yield
2. **Recommendation:** Highest yield unit with parking preference satisfied (if required)
3. **Why Reasons:** Pull from:
   - Yield ranking ("Highest yield in shortlist")
   - Price efficiency ("Best €/m² ratio")
   - Cashflow ("Lowest Y5-10 deficit")
   - Size ("Optimal 50-75m² for rentability")
   - Risk ("Best stress test resilience")
4. **Trade-offs:** What the chosen unit lacks vs alternatives
5. **Alternative:** Second-best option with different characteristics (e.g., with parking if top pick lacks it)
6. **Risks:** Top 3 from stress test results
7. **Questions:** Derive from analysis gaps and optimization opportunities

</short_report>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
${CLAUDE_SKILL_DIR}/references/briefing.md
${CLAUDE_SKILL_DIR}/references/methodology.md
@.finyx/profile.json

</execution_context>

<process>

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

**From config.json:**
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

Read template from `~/.claude/finyx/templates/briefing.md`

## Phase 5: Fill Template

Replace all `{{PLACEHOLDER}}` variables with actual data.

**Key sections to fill:**

### Executive Summary
```
{{INVESTMENT_DESCRIPTION}} → "Investment in 2-bedroom apartment in [LOCATION], Germany..."
{{UNITS_TABLE}} → Shortlist comparison table
{{GROSS_INCOME}} → From config
{{MARGINAL_TAX_RATE}} → From config
{{LIQUID_ASSETS}} → From config
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
```
All fields from config.json
```

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

  /finyx:stress-test  For additional scenarios
```

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</process>

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
- Nebenkosten
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
