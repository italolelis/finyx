# Phase 2: Tax Advisors - Research

**Researched:** 2026-04-06
**Domain:** Investment taxation — Germany (Abgeltungssteuer system) and Brazil (IR/DARF/come-cotas)
**Confidence:** HIGH (German side sourced from verified fin-tax skill + existing tax-rules.md; Brazilian side sourced from public Receita Federal rules + Law 15,270/2025 context)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Unified `/finyx:tax` command with automatic country routing from `.finyx/profile.json`. Not split per country.
- **D-02:** Command detects countries from profile (`countries.germany`, `countries.brazil`) and loads country-specific reference docs + question flows accordingly.
- **D-03:** For cross-border users (both DE + BR), the command surfaces both country sections plus a DBA interaction section.
- **D-04:** Split by domain — new `finyx/references/germany/tax-investment.md` and `finyx/references/brazil/tax-investment.md`. Existing `germany/tax-rules.md` (RE-focused) stays untouched.
- **D-05:** Each new tax reference doc has `tax_year` in YAML frontmatter (e.g., `tax_year: 2025`). Commands surface a warning when doc year doesn't match current year.
- **D-06:** Don't retrofit `tax_year` to existing `germany/tax-rules.md` — only apply to new files.
- **D-07:** Content for `germany/tax-investment.md` should draw from the existing `fin-tax` skill at `~/.claude/skills/fin-tax/SKILL.md` — it has comprehensive Abgeltungssteuer, Vorabpauschale, Teilfreistellung, and Freistellungsauftrag content already written.
- **D-08:** Sparerpauschbetrag tracking is stateless — calculated on-the-fly from profile data each run. No persistent tax-year state files.
- **D-09:** Profile schema extended with per-broker dividend/interest estimates under `countries.germany.brokers[]` (or similar). Command sums usage against 1,000/2,000 EUR allowance.
- **D-10:** Output is a report-style breakdown showing per-broker allocation and remaining allowance.
- **D-11:** Surface basic DBA guidance in Phase 2 — residency tiebreaker rules, withholding credit mechanics, double-dip prevention.
- **D-12:** Explicitly out-of-scope for Phase 2: INSS expat treatment, FII exemption under Law 15,270/2025 edge cases. Flag these with disclaimer in output.
- **D-13:** Cross-border section only appears when profile has `cross_border: true`.

### Claude's Discretion

- `/finyx:tax` prompt structure and phase ordering — Claude decides the optimal flow as long as all requirements are covered and country routing works.
- Vorabpauschale calculation output format — table, narrative, or both.
- Brazilian DARF deadline reminder mechanism — inline in output or separate note.

### Deferred Ideas (OUT OF SCOPE)

- INSS expat treatment for Brazilians in Germany
- FII dividend exemption edge cases under Law 15,270/2025
- Persistent tax-year tracking (`.finyx/tax-year/YYYY.json`)
- Tax-loss harvesting optimization command
- Anlage KAP filing assistant
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DETAX-01 | User receives explanation of German tax classes (Steuerklassen I-VI) with recommendation based on their profile | tax-rules.md has income brackets + marginal rates; profile already stores tax_class; command reads profile.countries.germany.tax_class |
| DETAX-02 | User can track Sparerpauschbetrag usage against the 1,000/2,000 EUR exemption | fin-tax SKILL.md has full Freistellungsauftrag strategy; requires profile schema extension for broker[] array (D-09) |
| DETAX-03 | User receives Vorabpauschale calculation for their accumulating ETFs using current Basiszins | fin-tax SKILL.md has formula + Basiszins 2025 (2.29%) and 2026 (3.20%) already verified |
| DETAX-04 | User receives Teilfreistellung rates by fund type | fin-tax SKILL.md has complete table: equity 30%, mixed 15%, RE 60%, foreign RE 80%, bonds 0% |
| DETAX-05 | User receives Abgeltungssteuer breakdown (25% + Soli + KiSt) contextualized to their marginal rate | fin-tax SKILL.md has full effective rates; Günstigerprüfung relevant when marginal rate < 26.375% |
| DETAX-06 | All German tax reference docs include tax_year metadata for staleness detection | YAML frontmatter pattern established in D-05; disclaimer.md already tells users to verify year |
| BRTAX-01 | User receives IR filing guidance specific to investment types (stocks, FIIs, CDB, LCI/LCA, previdencia) | Brazilian IR rules documented in research below; LCI/LCA exemption, CDB table rates, FII exemption rules |
| BRTAX-02 | User receives DARF calculation for monthly stock/FII gains with deadline reminders | Monthly apuration rules (last business day rule); DARF code 6015 for stocks, DARF code 3317 for day-trade |
| BRTAX-03 | User receives come-cotas explanation with timing impact on their fund holdings | Come-cotas applies to open-end funds (not ETFs/FIIs); May and November deduction mechanism |
| BRTAX-04 | User receives FII dividend tax exemption rules and declaration requirements | Law 8,668/1993 base exemption; Law 15,270/2025 changes effective 2026-01-01; needs disclaimer per D-12 |
| BRTAX-05 | Brazilian tax reference docs reflect Law 15,270/2025 changes (effective 2026-01-01) | Law changes FII dividend treatment for certain fund types; document what's confirmed vs what needs Receita Federal clarification |
| BRTAX-06 | All Brazilian tax reference docs include tax_year metadata for staleness detection | Same YAML frontmatter pattern as DETAX-06 |
</phase_requirements>

---

## Summary

Phase 2 builds a single `/finyx:tax` command that routes to German or Brazilian (or both) investment tax guidance based on the user's profile. The German side is well-covered: the existing `fin-tax` skill at `~/.claude/skills/fin-tax/SKILL.md` contains verified, comprehensive content on Abgeltungssteuer, Vorabpauschale, Teilfreistellung, and Freistellungsauftrag — this content should be lifted directly into `finyx/references/germany/tax-investment.md` rather than recreated. The Brazilian side requires new reference content; the core IR rules (DARF, come-cotas, FII exemption) are stable and well-documented, but Law 15,270/2025 (effective 2026-01-01) introduces FII changes that must be included with a staleness disclaimer.

The main structural work is: (1) create two new reference docs, (2) write the `/finyx:tax` command with country-routing logic, (3) extend profile.json schema with a `brokers[]` array for Sparerpauschbetrag tracking, and (4) update `commands/finyx/help.md` to list the new command. The fin-tax skill content means the German reference doc is essentially a copy-and-structure task, not a research task.

**Primary recommendation:** Create `germany/tax-investment.md` by structuring content from `~/.claude/skills/fin-tax/SKILL.md`. Create `brazil/tax-investment.md` fresh, covering the six BRTAX requirements with explicit Law 15,270/2025 annotations.

---

## Standard Stack

### Core

| Asset | Version/State | Purpose | Why Standard |
|-------|--------------|---------|--------------|
| `commands/finyx/tax.md` | New file | Slash command entry point | Follows established command pattern |
| `finyx/references/germany/tax-investment.md` | New file | German investment tax knowledge doc | Loaded via @path in execution_context |
| `finyx/references/brazil/tax-investment.md` | New file | Brazilian investment tax knowledge doc | Loaded via @path in execution_context |
| `finyx/references/disclaimer.md` | Existing | Legal disclaimer | Mandatory on all advisory commands |
| `finyx/templates/profile.json` | Schema extension | Adds brokers[] array | D-09 requires per-broker dividend tracking |

### Supporting

| Asset | State | Purpose | When to Use |
|-------|-------|---------|-------------|
| `commands/finyx/help.md` | Update | Add /finyx:tax to command table | Registration of new command |
| `bin/install.js` | No change needed | Brazil reference dir auto-included if path structure matches | Only if brazil/ dir is missing from copy paths |

### No External Dependencies

This phase adds zero runtime dependencies. All tax logic is in Markdown prompt files. No npm packages, no API calls in the reference docs themselves.

---

## Architecture Patterns

### File Structure for Phase 2

```
commands/finyx/
└── tax.md                        # New — unified tax advisor command

finyx/references/
├── germany/
│   ├── tax-rules.md              # UNTOUCHED (RE income tax, AfA, Spekulationsfrist)
│   └── tax-investment.md         # NEW — Abgeltungssteuer, Vorabpauschale, Teilfreistellung
└── brazil/
    └── tax-investment.md         # NEW — IR, DARF, come-cotas, FII exemption
```

### Pattern 1: Country-Routing in Slash Command

The command checks which countries are populated in the profile and loads reference docs accordingly. The logic follows the same conditional pattern already used in `profile.md` (Phase 3.1 vs 3.2 branches).

```markdown
## Phase 2: Country Detection

Read `.finyx/profile.json`.

Determine active countries:
- Germany active if: `countries.germany.tax_class != null`
- Brazil active if: `countries.brazil.ir_regime != null`
- Cross-border if: `identity.cross_border == true`
```

The `execution_context` block uses conditional @path loading — load both reference docs always (they are Markdown, minimal overhead), but the process phases gate output sections by country.

### Pattern 2: Reference Doc YAML Frontmatter

All new reference docs follow this header structure:

```yaml
---
tax_year: 2025
country: germany
domain: investment-tax
last_updated: 2026-01-15
source: BMF, Bundesbank
---
```

The command checks `tax_year` against the current year (extracted via bash `date +%Y`) and emits a staleness warning if they differ.

```bash
CURRENT_YEAR=$(date +%Y)
# Command compares against tax_year from loaded reference doc frontmatter
# Emit: "⚠ Reference doc is from {tax_year}, current year is {CURRENT_YEAR}. Verify rules before acting."
```

### Pattern 3: Sparerpauschbetrag Stateless Calculation (D-08, D-09, D-10)

Profile schema extension — add `brokers` array under `countries.germany`:

```json
"countries": {
  "germany": {
    "tax_class": "I",
    "church_tax": false,
    "gross_income": 85000,
    "marginal_rate": 44.31,
    "brokers": [
      { "name": "Trade Republic", "freistellungsauftrag": 600, "estimated_annual_income": 580 },
      { "name": "ING", "freistellungsauftrag": 300, "estimated_annual_income": 150 },
      { "name": "Trading212", "freistellungsauftrag": 100, "estimated_annual_income": 90 }
    ]
  }
}
```

Command computes at runtime:
```
allowance = (family_status == "married") ? 2000 : 1000
total_estimated = sum(broker.estimated_annual_income)
remaining = allowance - total_estimated
```

Output shows per-broker table plus remaining. No file written — pure computation from profile.

### Pattern 4: Vorabpauschale Calculation

The formula is verified in the fin-tax skill. Reference doc must include it; command walks the user through it interactively if they have accumulating ETF holdings.

```
Basisertrag = Fund value Jan 1 × Basiszins × 0.70
Vorabpauschale = min(Basisertrag, actual fund gain in year)
After Teilfreistellung (equity fund): Vorabpauschale × 0.70
Tax = after_teilfreistellung × 26.375%
```

Basiszins values to include in reference doc:
- 2025: 2.29% (confirmed in fin-tax skill)
- 2026: 3.20% (confirmed in fin-tax skill)

### Anti-Patterns to Avoid

- **Loading both country branches unconditionally in the process:** Gate output sections on active countries — a Germany-only user should not see Brazilian DARF instructions.
- **Recalculating Vorabpauschale in the command prompt body:** Put the formula in the reference doc, reference it from the command. Separates knowledge from execution.
- **Writing broker data to a sidecar file:** D-08 locks this as stateless. Don't create `.finyx/tax/sparerpauschbetrag.json`.
- **Modifying `germany/tax-rules.md`:** D-04 and D-06 are explicit — that file is RE-focused and not extended in Phase 2.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| German tax knowledge | Research from scratch | Content from `~/.claude/skills/fin-tax/SKILL.md` | Already verified, includes 2025/2026 Basiszins, Teilfreistellung tables, Freistellungsauftrag strategy |
| Disclaimer wiring | New disclaimer logic | `@~/.claude/finyx/references/disclaimer.md` in execution_context | Already established pattern — every advisory command uses it |
| Tax staleness signal | Custom date-check system | YAML `tax_year` frontmatter + one-line bash date comparison | D-05 decision; disclaimer.md already sets the expectation |
| Country routing logic | Complex flag system | Direct null-check on `countries.germany.tax_class` and `countries.brazil.ir_regime` | Profile already has these fields; null = country not active |

---

## German Investment Tax — Content Inventory

Content from `~/.claude/skills/fin-tax/SKILL.md` to migrate into `finyx/references/germany/tax-investment.md`:

| Topic | Status in Skill | Action |
|-------|----------------|--------|
| Abgeltungssteuer rate (25% + Soli) | Present, verified | Copy — effective rate 26.375% (no church), 27.995% (church 9%) |
| Sparerpauschbetrag (1,000/2,000 EUR) | Present | Copy |
| Teilfreistellung table | Present, complete | Copy — equity 30%, mixed 15%, bond 0%, RE 60%, foreign RE 80% |
| Vorabpauschale formula | Present, verified | Copy — includes Basiszins 2025 (2.29%) and 2026 (3.20%) |
| Freistellungsauftrag strategy | Present | Copy — cross-broker calculation example |
| Tax calendar (Jan Vorabpauschale, Dec harvest) | Present | Copy |
| Günstigerprüfung | Present | Copy — relevant when marginal rate < 26.375% |
| Steuerklassen I-VI explanation | NOT in skill | Write fresh — DETAX-01 requirement |
| Anlage KAP line mapping | Present | Copy — useful context for DETAX-05 |
| Tax-loss harvesting | Present | Note as v2 per deferred list; include brief mention only |

**Steuerklassen I-VI** is the only content that requires fresh writing. The rest is a structured copy from the skill.

Steuerklassen summary (source: German EStG / Finanzverwaltung, HIGH confidence):

| Class | Who | Impact |
|-------|-----|--------|
| I | Single, divorced, widowed (no child benefit) | Standard rate |
| II | Single parent with child benefit (Alleinerziehend) | Entlastungsbetrag ~€4,260/yr deduction |
| III | Married, higher earner (pair with V) | Much lower withholding — captures most of splitting benefit |
| IV | Married, equal earners | Each taxed individually, similar to I |
| IV with factor | Married, moderate income split | More accurate withholding than pure IV/IV |
| V | Married, lower earner (pair with III) | High withholding — filing required to correct |
| VI | Second job, no Freibetrag | Highest withholding, always requires filing |

**Investment tax implication of Steuerklassen:** Steuerklassen affect employment income withholding only. Capital gains (Abgeltungssteuer) are flat 25% regardless of class. However, class affects marginal rate calculation, which determines whether Günstigerprüfung applies (claim back if marginal rate < 25%).

---

## Brazilian Investment Tax — Content Inventory

Content for `finyx/references/brazil/tax-investment.md` — sourced from Receita Federal rules (MEDIUM-HIGH confidence for stable rules; MEDIUM for Law 15,270/2025 specifics):

### IR on Investment Income — Rates by Asset Type

| Asset | Tax Rate | Exemption | Notes |
|-------|----------|-----------|-------|
| Stocks (sell gain) | 15% | R$20k/month sell volume exempt | Day-trade: 20%, no exemption |
| FIIs (sell gain) | 20% | None on capital gains | Note: dividend exemption is separate |
| FII dividends | Exempt (base rule) | Law 8,668/1993 | Law 15,270/2025 modifies this — see below |
| CDB / LCI / LCA | Regressive table | LCI/LCA exempt if held ≥ 2yr (individual) | CDB rates: 22.5% (<6mo) → 15% (>24mo) |
| Previdência PGBL | Progressive or regressive | Choose regime at purchase | PGBL contributions deductible up to 12% of gross income |
| Previdência VGBL | Regressive table on gains only | VGBL contributions not deductible | Better for declaração completa users > 12% threshold |
| Fundos de Renda Fixa / Multimercado | Come-cotas (May + Nov) | None | Open-end funds, not FIIs or ETFs |

### Come-Cotas Mechanism (BRTAX-03)

Come-cotas is the advance tax collected twice yearly on open-end investment funds (fundos de investimento):
- **When:** Last business day of May and November
- **Rate:** Minimum rate for the fund's classification (short-term funds 20%, long-term 15%)
- **Mechanism:** The fund redeems shares (cotas) from each investor equal to the tax owed — investor sees fewer shares, not a cash deduction
- **Scope:** Applies to Fundos de Renda Fixa, Multimercado, and similar open-end CVM-regulated funds. Does NOT apply to: FIIs (Fundos de Investimento Imobiliário), ETFs, or CDBs held directly.
- **Annual reconciliation:** At redemption, come-cotas already paid is credited — you pay the difference only

### DARF Calculation and Deadlines (BRTAX-02)

DARF (Documento de Arrecadação de Receitas Federais) is the monthly tax payment form for capital gains realized from stock and FII sales.

```
Monthly gain = Total sales proceeds - Cost basis of sold positions
Tax = Monthly gain × rate (15% stocks normal, 20% day-trade)
Exemption = If total stock sales in month ≤ R$20,000 → zero tax (only normal operations, not day-trade)
DARF = max(0, Tax - exemption)
```

**DARF codes:**
- 6015: Normal stock/FII capital gains (swing trade, long-term)
- 3317: Day-trade capital gains

**Deadline:** Last business day of the calendar month following the gain month.
- Example: Gains in March → DARF due by last business day of April
- Penalty for late payment: 0.33%/day up to 20%, plus Selic interest

**How to pay:** Via banco (app), Receita Federal website, or SICALC tool. Reference docs should direct users to SICALC for calculation and ReceitaNet for payment.

### FII Dividend Exemption — Law 8,668/1993 + Law 15,270/2025 (BRTAX-04, BRTAX-05)

**Base rule (Law 8,668/1993):** FII dividends (rendimentos distribuídos) are exempt from IR for individual investors, provided the FII:
- Has at least 50 investors (quotaholders)
- Investor holds ≤ 10% of total quotas

**Law 15,270/2025 changes (effective 2026-01-01):**
The law modifies the FII dividend exemption framework. Key confirmed changes:
- Introduces new categories of "qualified FIIs" (FII qualificado) with different tax treatment
- Non-qualified FIIs distributing dividends may face withholding at 15%
- The 50-quotaholders / 10%-holding conditions remain for base exemption

**Uncertainty flag (from STATE.md + D-12):** The exact interaction between Law 15,270/2025 and the existing exemption for individual investors in standard listed FIIs (like HGLG11, KNRI11) has not been fully confirmed by Receita Federal guidance as of research date. The reference doc must include an explicit disclaimer directing users to verify with a contador before the 2026 tax year.

### Cross-Border DE+BR DBA Guidance (D-11, D-03, D-13)

Germany-Brazil Double Taxation Agreement (Doppelbesteuerungsabkommen / Acordo para Evitar Dupla Tributação):

**Status:** Germany and Brazil have a DTA in force (signed 1975, relevant to investment income).

**Key principles for individual investors:**

| Scenario | Treatment |
|----------|-----------|
| Brazilian resident receiving German dividends | Brazil taxes; Germany withholds 15% max; credit available in Brazil |
| German resident receiving Brazilian FII distributions | Germany taxes; Brazilian exemption may not transfer; Progressionsvorbehalt may apply |
| Capital gains — stocks | Source country has primary right; residence country credits |
| Residency tiebreaker (dual resident) | Permanent home → habitual abode → nationality → mutual agreement (OECD model Art. 4) |

**Double-dip prevention:** If you are a German resident and Brazil withholds tax on investments, claim credit on Anlage AUS (foreign tax credit) in German filing. Do not claim the same income as fully exempt in both jurisdictions.

**What to include in output:** Brief residency tiebreaker explanation + statement to consult a cross-border tax advisor for the full DTA analysis. The Phase 2 scope is "surface basic guidance" (D-11), not a full DTA analysis.

---

## Common Pitfalls

### Pitfall 1: Teilfreistellung Applied to Individual Stocks
**What goes wrong:** User applies 30% Teilfreistellung to stock dividends, reducing taxable income incorrectly.
**Why it happens:** The 30% rate is associated with "equity" assets, but Teilfreistellung only applies to *fund* distributions and gains, not individual stocks.
**How to avoid:** Reference doc must state explicitly: "Teilfreistellung applies to funds (ETFs, investment funds) only — not to dividends or gains from individual stocks."
**Warning signs:** Calculated effective rate too low for individual stock dividends.

### Pitfall 2: Vorabpauschale Cash Surprise in January
**What goes wrong:** Accumulating ETF holder has no cash in broker account in January; broker sells shares to cover Vorabpauschale, triggering a taxable event.
**Why it happens:** Vorabpauschale is deducted from the Sparerpauschbetrag and charged by German brokers in January for the prior year. Users with only accumulating ETFs and no cash balance get caught.
**How to avoid:** Tax calendar section in reference doc; command output should remind users to keep a small cash buffer in German broker accounts.

### Pitfall 3: Freistellungsauftrag Sum Exceeds Allowance
**What goes wrong:** User sets Freistellungsauftrag at multiple brokers totaling > 1,000 EUR — technically illegal (§44a EStG), triggers Finanzamt query.
**Why it happens:** Users set it and forget; income grows; total submitted exceeds the statutory limit.
**How to avoid:** D-10 output shows per-broker allocation and total; command should flag if `sum(freistellungsauftrag) > allowance`.

### Pitfall 4: FII Dividend Exemption Misapplied Post-2026
**What goes wrong:** User assumes all FII dividends are exempt in 2026 tax year, based on pre-Law 15,270/2025 knowledge.
**Why it happens:** Law change not propagated to user mental model; reference docs may lag.
**How to avoid:** BRTAX-05 requirement exists specifically for this. tax_year frontmatter + staleness warning covers ongoing detection. Reference doc must note the change explicitly with a disclaimer for edge cases.

### Pitfall 5: DARF Missed — R$20k Exemption Misapplied to Day-Trade
**What goes wrong:** User sells > R$20k in day-trade, believes the R$20k exemption applies, files no DARF.
**Why it happens:** The R$20k/month exemption applies only to normal stock operations (operações comuns), not day-trade.
**How to avoid:** Reference doc must distinguish the two explicitly. DARF code is also different (6015 vs 3317).

### Pitfall 6: Come-Cotas Confused with FII Dividends
**What goes wrong:** User tells the command they hold FIIs and asks about come-cotas — actually come-cotas does not apply to FIIs.
**Why it happens:** Both are recurring automatic deductions and users conflate them.
**How to avoid:** Reference doc and command output must state scope: "come-cotas applies to open-end CVM funds (fundos de investimento), not to FIIs or ETFs."

---

## Profile Schema Extension

The profile.json template requires one addition for DETAX-02 (D-09):

**Current `countries.germany` shape:**
```json
"germany": {
  "tax_class": null,
  "church_tax": false,
  "gross_income": 0,
  "marginal_rate": 0
}
```

**Extended shape (add `brokers` array):**
```json
"germany": {
  "tax_class": null,
  "church_tax": false,
  "gross_income": 0,
  "marginal_rate": 0,
  "brokers": []
}
```

**Broker entry shape:**
```json
{
  "name": "Trade Republic",
  "freistellungsauftrag": 600,
  "estimated_annual_income": 450
}
```

Fields:
- `name`: Free text broker name
- `freistellungsauftrag`: EUR amount allocated to this broker via Freistellungsauftrag
- `estimated_annual_income`: EUR amount of estimated annual capital income at this broker (dividends + interest + Vorabpauschale estimate)

The `estimated_annual_income` is user-provided (not calculated) — users enter what they expect for the year. The command sums both arrays independently: one sum for Freistellungsauftrag total (alert if > 1,000/2,000), one for estimated usage.

The `/finyx:tax` command may ask the user to provide broker data via inline questions if `brokers` array is empty — and optionally write back to profile.json.

---

## Integration Points — Files to Create or Update

| File | Action | Requirement Driven By |
|------|--------|-----------------------|
| `finyx/references/germany/tax-investment.md` | Create new | DETAX-01 through DETAX-06 |
| `finyx/references/brazil/tax-investment.md` | Create new | BRTAX-01 through BRTAX-06 |
| `commands/finyx/tax.md` | Create new | All 12 requirements |
| `finyx/templates/profile.json` | Extend `countries.germany.brokers` | DETAX-02 (D-09) |
| `commands/finyx/help.md` | Add `/finyx:tax` row to commands table | Discoverability |
| `bin/install.js` | Check if `brazil/` dir is included in copy paths | BRTAX reference docs need to install |

**bin/install.js note:** The installer uses `copyWithPathReplacement` to copy `finyx/references/` recursively. Since `brazil/` is a new subdirectory under `finyx/references/`, it will be included automatically if the copy is recursive (which it is). No change needed unless there is an explicit allowlist — verified by reading the installer logic before implementing.

---

## Code Examples

### Command Frontmatter Pattern (verified from analyze.md)

```markdown
---
name: finyx:tax
description: Tax advisor — German and Brazilian investment tax guidance based on your profile
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---
```

### Execution Context Pattern

```markdown
<execution_context>

@~/.claude/finyx/references/disclaimer.md
@~/.claude/finyx/references/germany/tax-investment.md
@~/.claude/finyx/references/brazil/tax-investment.md

</execution_context>
```

Note: Load both reference docs always. The process phases gate which sections appear in output based on detected active countries.

### Profile Gate (verified from analyze.md)

```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first."; exit 1; }
```

### Tax Year Staleness Check

```bash
CURRENT_YEAR=$(date +%Y)
# Reference doc tax_year is loaded into context via @path
# Command prompt evaluates: if tax_year != CURRENT_YEAR, emit warning
```

### Sparerpauschbetrag Report Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > TAX: SPARERPAUSCHBETRAG TRACKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Annual allowance:    1,000 EUR (single)

Broker Allocations:
  Trade Republic     Freistellungsauftrag: 600 EUR   Est. income: 580 EUR
  ING                Freistellungsauftrag: 300 EUR   Est. income: 150 EUR
  Trading212         Freistellungsauftrag: 100 EUR   Est. income:  90 EUR

Total Freistellungsauftrag submitted:  1,000 EUR  ✓ (at limit)
Total estimated income:                  820 EUR
Remaining estimated buffer:              180 EUR

⚠ Vorabpauschale not yet included — add estimated Vorabpauschale
  to your broker income estimates in profile.json.
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Vorabpauschale not applicable (pre-2018) | Vorabpauschale annual pre-tax on accum. ETFs | 2018 InvStG reform | All accumulating ETF holders need to account for Jan charge |
| Fünftelregelung applied by employer at payroll | Fünftelregelung assessed by Finanzamt only | January 2025 | Employer withholding may be higher; refund comes via tax return |
| FII dividends fully exempt (Law 8,668/1993) | Partial modification for non-qualified FIIs | Law 15,270/2025, effective 2026-01-01 | Document with staleness disclaimer; verify with Receita Federal |
| Sparerpauschbetrag 801 EUR (single) | 1,000 EUR (single), 2,000 EUR (married) | 2023 (Jahressteuergesetz 2022) | Updated values already in fin-tax skill |

**Deprecated/outdated:**
- 801 EUR Sparerpauschbetrag: Replaced by 1,000 EUR as of tax year 2023. Do not use 801 EUR.
- Pre-2018 ETF taxation (transparent/intransparent fund distinction): Replaced entirely by InvStG 2018. The Teilfreistellung + Vorabpauschale system supersedes all pre-reform ETF tax rules.

---

## Open Questions

1. **Law 15,270/2025 FII edge cases**
   - What we know: Law effective 2026-01-01; introduces "qualified FII" distinction; non-qualified FIIs may face 15% withholding on distributions
   - What's unclear: Exactly which listed FIIs qualify under the new regime; Receita Federal has not published IN (Instrução Normativa) with full implementation guidance as of research date
   - Recommendation: Document the base rule and the change in the reference doc; include explicit disclaimer directing users to verify with a contador before the 2026 tax year; this is precisely what D-12 defers

2. **Vorabpauschale 2026 Basiszins confirmation**
   - What we know: fin-tax skill states 3.20% for 2026 (Vorabpauschale calculated January 2027)
   - What's unclear: This was projected as of skill creation; BMF publishes official rate annually; 3.20% should be verified against current BMF publication
   - Recommendation: Include 3.20% in reference doc with a note "verify against current BMF publication at bundesbank.de/basiszins before January"

3. **Brazil `brokers` analog for Sparerpauschbetrag**
   - What we know: BRTAX requirements do not include a broker-level tracking analog; Brazilian IR is self-assessed via DARF
   - What's unclear: Whether to extend `countries.brazil` schema with investment holdings for DARF calculation assistance
   - Recommendation: Keep Brazil schema minimal for Phase 2 (`ir_regime` and `gross_income` are sufficient); Phase 3 (investment advisor) is the right place for portfolio holdings schema

---

## Environment Availability

Step 2.6: SKIPPED — Phase 2 is purely Markdown file creation (slash command + reference docs). No external tools, APIs, databases, or CLIs are required. All content is static knowledge encoded in Markdown.

---

## Validation Architecture

No automated test framework is configured or applicable for this project. All "logic" is in Markdown prompt files interpreted by Claude Code at runtime.

**Validation approach for this phase:** Manual smoke testing by running `/finyx:tax` after implementation:

| Req ID | Behavior | Test Type | How to Verify |
|--------|----------|-----------|---------------|
| DETAX-01 | Tax class explanation output | Manual smoke | Run `/finyx:tax` with Germany-only profile; verify Steuerklassen I-VI section appears |
| DETAX-02 | Sparerpauschbetrag tracking | Manual smoke | Profile with brokers[] populated; verify per-broker table and remaining allowance |
| DETAX-03 | Vorabpauschale calculation | Manual smoke | Provide ETF holding value; verify formula applied with correct Basiszins |
| DETAX-04 | Teilfreistellung rates | Manual smoke | Verify correct rates shown by fund type in output |
| DETAX-05 | Abgeltungssteuer contextualized | Manual smoke | Verify 26.375% effective rate shown; Günstigerprüfung note present for low-income case |
| DETAX-06 | tax_year in German reference doc | File check | Read `germany/tax-investment.md` frontmatter; confirm tax_year field present |
| BRTAX-01 | IR guidance by investment type | Manual smoke | Run `/finyx:tax` with Brazil-only profile; verify CDB/FII/stock guidance present |
| BRTAX-02 | DARF calculation | Manual smoke | Provide monthly gain; verify DARF amount and deadline shown |
| BRTAX-03 | Come-cotas explanation | Manual smoke | Verify scope clarification (open-end funds only, not FIIs) present |
| BRTAX-04 | FII dividend exemption rules | Manual smoke | Verify base rule + Law 15,270/2025 note + disclaimer present |
| BRTAX-05 | Law 15,270/2025 reflected | File check | Read `brazil/tax-investment.md`; confirm law change documented |
| BRTAX-06 | tax_year in Brazilian reference doc | File check | Read `brazil/tax-investment.md` frontmatter; confirm tax_year field present |

---

## Sources

### Primary (HIGH confidence)
- `~/.claude/skills/fin-tax/SKILL.md` — Comprehensive German investment tax: Abgeltungssteuer, Vorabpauschale, Teilfreistellung, Freistellungsauftrag, Basiszins 2025/2026. This is the canonical source for German content.
- `finyx/references/germany/tax-rules.md` — German RE tax brackets and marginal rate formulas; reusable for DETAX-01 context
- `commands/finyx/profile.md` + `commands/finyx/analyze.md` — Verified command patterns (frontmatter, execution_context, profile gate, disclaimer wiring)

### Secondary (MEDIUM confidence)
- Brazilian IR rules (CDB rates, DARF codes, come-cotas mechanism): Stable Receita Federal rules unchanged for multiple years; verified against multiple public sources
- DTA Germany-Brazil: Treaty in force since 1975; standard OECD model Art. 4 tiebreaker applies; residency + credit mechanism well-established
- Law 15,270/2025: Confirmed effective date 2026-01-01; base structural changes confirmed; implementation detail (which FIIs qualify) pending Receita Federal IN

### Tertiary (LOW confidence — flagged)
- Basiszins 2026 at 3.20%: From fin-tax skill, projected; verify against current BMF/Bundesbank publication before shipping reference doc
- Law 15,270/2025 FII edge cases: Single-source, Receita Federal guidance not yet published; documented with disclaimer per D-12

---

## Metadata

**Confidence breakdown:**
- German investment tax content: HIGH — sourced entirely from verified fin-tax skill
- German Steuerklassen content: HIGH — stable EStG rules
- Brazilian IR/DARF/come-cotas: MEDIUM-HIGH — stable rules, multiple sources consistent
- Law 15,270/2025 FII changes: MEDIUM — effective date confirmed, implementation details pending
- DBA DE-BR basics: MEDIUM — treaty confirmed, residency tiebreaker standard; full analysis is out of scope anyway (D-11 is "basic guidance" only)

**Research date:** 2026-04-06
**Valid until:** German tax content stable through 2026 tax year. Brazil content: re-verify Law 15,270/2025 implementation details when Receita Federal publishes implementation IN (expected Q1 2026).
