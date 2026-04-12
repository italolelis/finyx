# Phase 6: Reference Foundation - Research

**Researched:** 2026-04-06
**Domain:** Markdown reference doc authoring — country-aware financial benchmarks and scoring rules
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use net-after-mandatory income as the denominator for all allocation benchmarks. Germany: gross minus ~19.6% employee social contributions minus ~30-35% effective income tax ≈ 55-58% of gross. Brazil: gross minus INSS (7.5-14% capped) minus IRRF (22-27.5% effective) ≈ 70-75% of gross.
- **D-02:** Apply adjusted 50/30/20 rule to net-after-mandatory income, not gross.
- **D-03:** Emergency fund threshold: 6 months of expenses (cross-border complexity warrants this over 3 months).
- **D-04:** Investment rate targets as % of net-after-mandatory: DE 15% minimum / 20-25% aspirational. BR 10-15% minimum (FGTS/INSS partially substitute private savings).
- **D-05:** Traffic light (green/yellow/red) + € gap display per dimension. Each dimension shows a color indicator AND the absolute € amount of the gap. Example: "🟡 Sparerpauschbetrag: €263/year unused"
- **D-06:** Per-country scoring only — DE and BR are scored independently, never combined into a single metric.
- **D-07:** Scoring thresholds must be defined per country per dimension in `scoring-rules.md` (green = fully optimized, yellow = partial gap, red = significant gap).

### Claude's Discretion
- Doc structure: whether to use a new `insights/` subdir or another org pattern under `finyx/references/`
- Vorabpauschale readiness thresholds: exact buffer percentages and how to handle missing current-year Basiszins
- Specific green/yellow/red threshold boundaries for each dimension (as long as they're reasonable and documented)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-02 | Reference docs for country-aware benchmarks and scoring rules exist | Directly fulfilled by creating `benchmarks.md` and `scoring-rules.md` with proper frontmatter, verified tax data, and per-country thresholds |
</phase_requirements>

---

## Summary

Phase 6 produces two pure Markdown knowledge documents — `benchmarks.md` and `scoring-rules.md` — that Phase 7 agents will consume via `@` includes in their `<execution_context>` blocks. No commands, agents, or executable code are built. The deliverables are reference docs, authored to exactly the same pattern as the existing `finyx/references/germany/tax-investment.md` and `finyx/references/brazil/tax-investment.md`.

The key authoring challenge is producing accurate, verified numbers for: (a) net-income denominators per country, (b) allocation benchmark ranges adjusted to net-after-mandatory, and (c) per-dimension traffic-light thresholds grounded in the tax rules already captured in the existing reference docs. All benchmark and scoring values must derive from the figures already locked in the existing DE/BR tax-investment docs — no new tax research is needed.

The `install.js` `copyWithPathReplacement` function recursively copies the entire `finyx/` directory tree. Any new subdirectory placed under `finyx/references/` will be picked up automatically on reinstall with no changes to `bin/install.js`.

**Primary recommendation:** Place both docs in `finyx/references/insights/` — this creates a clear separation between tax/broker/pension reference docs and insight-specific reference docs, matches the CONTEXT.md discretion guidance, and requires zero install.js changes.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown | — | Doc format | Project convention — all reference docs are pure Markdown |
| YAML frontmatter | — | Metadata/staleness detection | Used by all existing reference docs; staleness check in commands reads `tax_year` field |

### Supporting

No npm libraries needed. This phase produces static Markdown files only.

**Installation:** None required — pure file authoring phase.

---

## Architecture Patterns

### Recommended Project Structure

```
finyx/references/
├── germany/
│   ├── tax-investment.md    # existing
│   ├── tax-rules.md         # existing
│   ├── brokers.md           # existing
│   └── pension.md           # existing
├── brazil/
│   ├── tax-investment.md    # existing
│   ├── brokers.md           # existing
│   └── pension.md           # existing
├── insights/                # NEW — Phase 6 creates this subdir
│   ├── benchmarks.md        # NEW — income allocation benchmarks
│   └── scoring-rules.md     # NEW — traffic-light scoring thresholds
├── disclaimer.md            # existing
├── methodology.md           # existing
├── erbpacht-detection.md    # existing
└── transport-assessment.md  # existing
```

**Why `insights/` subdir over flat placement:** The existing subdirs (`germany/`, `brazil/`) organize by country. `insights/` organizes by function — docs that drive the insights command. This preserves discoverability and mirrors how Phase 7 agents will reference them: `@~/.claude/finyx/references/insights/benchmarks.md`.

### Pattern 1: Frontmatter Convention

Every reference doc uses this exact frontmatter block — verified against both existing reference docs:

```yaml
---
tax_year: 2025
country: germany           # or "brazil" or "cross-border"
domain: insights-benchmarks  # or "insights-scoring"
last_updated: 2026-04-06
source: [list of authoritative sources]
---
```

**Key:** `tax_year` is what the staleness detection logic reads. The existing commands warn when `doc.tax_year != currentYear`. New docs must use this exact field name.

### Pattern 2: Staleness Warning Block

Every existing reference doc opens with a staleness notice immediately after the title. New docs must follow the same pattern:

```markdown
> **Tax year notice:** This document reflects benchmarks and rules calibrated for tax year 2025.
> Verify social contribution rates and tax brackets against official sources before using for
> a different tax year.
```

### Pattern 3: Country-Scoped Sections

Cross-country docs (like `benchmarks.md` which covers both DE and BR) should mirror the per-country section structure already used in `finyx/references/brazil/tax-investment.md` Section 5 (Cross-Border Notes):

```markdown
## Germany — [Section Name]
[DE content]

## Brazil — [Section Name]
[BR content]
```

Never mix DE and BR content in the same table row or formula.

### Pattern 4: `@` Include Reference in Agent Context

Phase 7 agents will load the new docs with:
```
@~/.claude/finyx/references/insights/benchmarks.md
@~/.claude/finyx/references/insights/scoring-rules.md
```

The `install.js` path-rewriting regex (`~/\.claude\/` → resolved path prefix) handles local vs global installs automatically — no special treatment needed in the new docs, UNLESS they reference other files via `@`. If cross-references are needed (e.g., scoring-rules.md referencing tax-investment.md), use the `@~/.claude/finyx/references/` prefix exactly as the existing docs do.

### Anti-Patterns to Avoid

- **Duplicating tax rules in the new docs:** scoring-rules.md must STATE scoring thresholds, not re-explain the underlying German/Brazilian tax rules. It references `tax-investment.md` for the rule detail.
- **Combining DE and BR into a single benchmark row:** Violates D-06 and Pitfall #3 (cross-jurisdiction conflation). Always separate rows/sections per country.
- **Using gross income as denominator:** Violates D-01 and Pitfall #4. All allocation benchmarks must be framed in terms of net-after-mandatory income.
- **Omitting source citations:** Existing docs always cite the authoritative source (BMF, Receita Federal, EStG, InvStG). New docs must cite sources for all rates and thresholds.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Net income calculation logic | Inline formulas in each agent | `benchmarks.md` Section: Net Income Denominator | Single source; agents cite the doc, don't recompute |
| Traffic-light thresholds | Hardcoded in agent prompts | `scoring-rules.md` | Thresholds will drift if defined per-agent; one doc = one change point |
| Tax rule detail (Sparerpauschbetrag amount, DARF threshold) | Re-stated in scoring-rules.md | `@` reference to `germany/tax-investment.md` or `brazil/tax-investment.md` | Rules already verified and dated; duplication creates silent drift |

**Key insight:** These reference docs are the canonical, versioned single source of truth. Phase 7 agents must consume them, not duplicate their content.

---

## Content Specification

### benchmarks.md — Required Sections

**Purpose:** Define what "good" looks like for income allocation, per country, on a net-after-mandatory basis. Phase 7 uses this to compute green/yellow/red for ALLOC-01 and ALLOC-02.

#### Section 1: Net Income Denominator

Defines the calculation basis for all benchmarks. Key verified figures from CONTEXT.md D-01:

| Country | Gross-to-Net Conversion | Effective Net % of Gross |
|---------|------------------------|--------------------------|
| Germany | Gross − employee social contributions (~19.6%) − income tax (~30-35% effective for typical earner) | ~55-58% of gross |
| Brazil | Gross − INSS (7.5-14% capped) − IRRF (22-27.5% effective) | ~70-75% of gross |

**Note on DE social contributions breakdown (verified from `germany/tax-investment.md` context):**
- Krankenversicherung (KV): ~7.3% employee share (plus ~1.6% Zusatzbeitrag avg)
- Rentenversicherung (RV): 9.3% employee share
- Arbeitslosenversicherung (AV): 1.3%
- Pflegeversicherung (PV): ~1.7% (childless add 0.35%)
- Total employee social: ~19.6% (varies slightly by state and KV Zusatzbeitrag)

**Note on BR INSS (2025 table):**
- 7.5% on income up to R$1,518/month
- 9% on R$1,518–R$2,594.38
- 12% on R$2,594.38–R$3,856.94
- 14% on R$3,856.94–R$7,786.02
- Capped at R$7,786.02 (progressive table, not flat rate)

#### Section 2: Adjusted 50/30/20 Rule

Applied to net-after-mandatory income (D-02). Recommended ranges as % of net-after-mandatory:

| Category | DE Range | BR Range | Notes |
|----------|----------|----------|-------|
| Needs (housing, utilities, food, insurance) | 40-55% | 45-60% | DE: Mietpreise in major cities are high relative to net; adjust per location |
| Wants (discretionary, travel, leisure) | 15-25% | 15-25% | Standard; both countries similar |
| Savings + investments | 20-30% | 15-25% | Includes voluntary savings + investment contributions |
| Debt repayment | 0-15% | 0-15% | Separate from "needs" for clarity |

**Investment sub-targets within savings+investments (D-04):**
- DE: Minimum 15% of net-after-mandatory; aspirational 20-25%
- BR: Minimum 10-15% of net-after-mandatory (FGTS/INSS partially substitute private savings — see note)

#### Section 3: Emergency Fund Threshold

- Target: 6 months of total expenses (D-03)
- Rationale for 6 months (vs 3): Cross-border employment/tax complexity, higher switching costs, dual-jurisdiction administrative overhead
- Liquid assets only (cash, Tagesgeld, overnight/instant-access savings accounts) — not investment portfolios

#### Section 4: Debt-to-Income Ratio

- Healthy threshold: ≤ 35% of net-after-mandatory income in recurring debt obligations
- Includes: mortgage payments, consumer credit, car finance, student loans
- Excludes: mandatory social contributions (already netted in denominator)

---

### scoring-rules.md — Required Sections

**Purpose:** Define traffic-light thresholds per dimension per country. Phase 7 uses this to produce the green/yellow/red + € gap display (D-05, D-06, D-07).

#### Germany Dimensions

**TAX-01: Sparerpauschbetrag Usage**
- Source: `germany/tax-investment.md` Section 3 — €1,000 (single) / €2,000 (married)
- Green: ≥ 90% utilized (unused < €100 / €200)
- Yellow: 50-89% utilized (unused €100-€500 / €200-€1,000)
- Red: < 50% utilized (unused > €500 / €1,000)
- Gap display: "Sparerpauschbetrag: €X unused" — where tax saved = unused × 26.375%

**TAX-03: Vorabpauschale Readiness**
- Source: `germany/tax-investment.md` Section 5 — formula: Fund value × Basiszins × 0.70
- Green: Cash buffer ≥ 110% of estimated Vorabpauschale tax due in January
- Yellow: Cash buffer 80-109% of estimated Vorabpauschale
- Red: Cash buffer < 80% (risk of forced unit sale)
- Fallback when current-year Basiszins unavailable: use prior-year Basiszins with a "ESTIMATED — verify current Basiszins from BMF" label; flag confidence as MEDIUM

**ALLOC-01: Investment Rate (DE)**
- Green: Investment rate ≥ 20% of net-after-mandatory
- Yellow: 15-19% (meets minimum, below aspirational)
- Red: < 15% of net-after-mandatory

**ALLOC-02: Emergency Fund (DE)**
- Green: Liquid savings ≥ 6 months expenses
- Yellow: 3-5 months (adequate but below cross-border target)
- Red: < 3 months

#### Brazil Dimensions

**TAX-02: DARF Compliance**
- Source: `brazil/tax-investment.md` Section 2
- Green: All months with taxable gains had DARF filed and paid on time
- Yellow: DARF obligations present but status unknown (no data in profile)
- Red: Known gap month (taxable gain recorded, no payment confirmed) — flag with penalty estimate

**TAX-02: PGBL Deduction Utilization**
- Source: `brazil/tax-investment.md` Section 1 (PGBL/VGBL rules)
- Applies only to users with `declaracao: completa`
- Green: PGBL contribution ≥ 12% of gross income (maximum deductible limit)
- Yellow: PGBL contribution 6-11% of gross
- Red: < 6% contribution or no PGBL (and no documented reason such as VGBL preference)

**ALLOC-01: Investment Rate (BR)**
- Green: Investment rate ≥ 15% of net-after-mandatory
- Yellow: 10-14% (meets minimum)
- Red: < 10% of net-after-mandatory
- Note: FGTS contributions count toward the total — read from profile `countries.brazil.fgts_contribution`

**ALLOC-02: Emergency Fund (BR)**
- Same thresholds as DE: Green ≥ 6 months, Yellow 3-5 months, Red < 3 months
- Liquid assets for BR: poupança, conta corrente, CDB de liquidez diária, LCI/LCA with daily liquidity

#### Scoring Output Format (for Agent Consumption)

Each dimension result MUST follow this structure so Phase 7 agents produce consistent output:

```
[TRAFFIC_LIGHT] [DIMENSION_LABEL]: [STATUS_PHRASE]
  Gap: [€X or R$X] [per year / per month] [action verb]
  How to close: [one-line action]
```

Example (from D-05 in CONTEXT.md):
```
🟡 Sparerpauschbetrag: €263/year unused
  Gap: €263 in unrealized tax savings (€263 × 26.375% = €69/year tax cost)
  How to close: Allocate €263 additional Freistellungsauftrag to an active broker
```

---

## Common Pitfalls

### Pitfall 1: Gross Income as Denominator
**What goes wrong:** Benchmarks reference `gross_income` from profile directly, producing "savings rate too low" when it's actually adequate on a net basis.
**Why it happens:** `profile.json` stores `gross_income`; it is the readily available field.
**How to avoid:** `benchmarks.md` Section 1 must explicitly define the net-income calculation formula with exact fields from `profile.json`. Phase 7 agents compute net first, then apply benchmarks.
**Warning signs:** Any benchmark percentage that "feels too demanding" for a high-income DE user is likely gross-based.

### Pitfall 2: Cross-Country Threshold Conflation
**What goes wrong:** A single threshold table covers both DE and BR, or a scoring agent applies DE thresholds to BR data.
**Why it happens:** Symmetry looks clean.
**How to avoid:** `scoring-rules.md` must have a clearly labelled `## Germany` section and `## Brazil` section with no shared threshold tables. D-06 is an absolute constraint.

### Pitfall 3: Vorabpauschale Buffer — Missing Basiszins
**What goes wrong:** The Basiszins for the current year is not yet published when the user runs insights (BMF publishes in early January). The scoring logic fails or uses a stale value.
**How to avoid:** `scoring-rules.md` must include an explicit fallback: "if current-year Basiszins is unavailable, use prior-year value and flag the estimate as MEDIUM confidence." This is the discretion area from CONTEXT.md.

### Pitfall 4: Tax Rules Duplicated in Scoring Docs
**What goes wrong:** `scoring-rules.md` restates the Sparerpauschbetrag amount (€1,000) or the DARF rate (15%) instead of `@`-referencing the source doc.
**Why it happens:** Self-contained docs feel cleaner.
**How to avoid:** `scoring-rules.md` must ONLY state thresholds and gap formulas. It must include a reference like "Source: `germany/tax-investment.md` Section 3" for every rule it applies. The PITFALLS.md "Technical Debt Patterns" table explicitly states "duplicate tax logic in insights prompt instead of @ including reference docs — NEVER."

### Pitfall 5: Omitting `tax_year` Frontmatter
**What goes wrong:** Staleness detection silently fails; outdated benchmarks are used in future tax years without warning.
**How to avoid:** Both docs must carry `tax_year: 2025` in frontmatter. Social contribution rates (INSS table, KV Zusatzbeitrag) change annually — the staleness check will surface the need to update.

---

## Code Examples

### Frontmatter — benchmarks.md

```yaml
---
tax_year: 2025
country: cross-border
domain: insights-benchmarks
last_updated: 2026-04-06
source: BMF (Sozialabgaben 2025), Receita Federal (INSS tabela 2025), EStG, GKV-Spitzenverband
---
```

### Frontmatter — scoring-rules.md

```yaml
---
tax_year: 2025
country: cross-border
domain: insights-scoring
last_updated: 2026-04-06
source: See germany/tax-investment.md and brazil/tax-investment.md for underlying tax rules
---
```

### Agent @-Reference Pattern (Phase 7 usage)

```markdown
<execution_context>
@~/.claude/finyx/references/insights/benchmarks.md
@~/.claude/finyx/references/insights/scoring-rules.md
@~/.claude/finyx/references/germany/tax-investment.md
@~/.claude/finyx/references/brazil/tax-investment.md
@~/.claude/finyx/references/disclaimer.md
</execution_context>
```

### Traffic Light Gap Formula — Sparerpauschbetrag Example

```
Unused allowance = limit - sum_of_freistellungsauftrag_across_all_brokers
Tax saved if closed = unused × 26.375%    (or 27.819% / 27.995% with church tax)
Status:
  Green  → unused < €100 (single) / €200 (married)
  Yellow → unused €100-€500 / €200-€1,000
  Red    → unused > €500 / €1,000
```

### Traffic Light Gap Formula — Investment Rate Example

```
investment_rate = (annual_investment_contributions / net_after_mandatory_income) × 100
DE targets:
  Green  → investment_rate >= 20%
  Yellow → 15% <= investment_rate < 20%
  Red    → investment_rate < 15%
BR targets:
  Green  → investment_rate >= 15%  (including FGTS)
  Yellow → 10% <= investment_rate < 15%
  Red    → investment_rate < 10%
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| 50/30/20 on gross income | 50/30/20 on net-after-mandatory income | Accurate for DE/BR users; gross-based approach is US-centric and misleading at 45%+ mandatory deduction rates |
| Single emergency fund threshold (3 months) | 6 months for cross-border users | Correct per D-03; cross-border administrative complexity justifies higher buffer |
| Generic "invest 20%" guidance | Per-country tiered targets tied to net income | DE 15%/20-25%; BR 10-15% accounting for FGTS |

---

## Open Questions

1. **INSS progressive table 2025 exact values**
   - What we know: Progressive table structure (7.5%/9%/12%/14%) with cap at ~R$7,786
   - What's unclear: Exact bracket boundaries may have been updated for 2025 (annual adjustment)
   - Recommendation: The content author should verify the 2025 INSS table against current Receita Federal guidance before publishing `benchmarks.md`. The brackets noted above are from the CONTEXT.md research — flag with a source citation and "verify annually" note.

2. **KV Zusatzbeitrag variation**
   - What we know: Average KV Zusatzbeitrag is approximately 1.6% for 2025
   - What's unclear: Each Krankenkasse sets its own rate; some are higher/lower
   - Recommendation: `benchmarks.md` should use the GKV-Spitzenverband average (1.6%) with a note that individual rates vary by ~0.4-0.8 percentage points. This is sufficient for net-income estimation purposes.

3. **FGTS counting toward BR investment rate**
   - What we know: D-04 states "FGTS/INSS partially substitute private savings" for BR
   - What's unclear: Whether to count only employer FGTS (8%) or also voluntary FGTS or FGTS profit sharing (FGTS aniversário rule)
   - Recommendation: Count mandatory employer FGTS (8% of salary) toward the BR investment rate minimum, with a note. Do not count INSS (it is social insurance, not savings). Voluntary FGTS extras are optional — do not assume.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely Markdown file authoring with no external dependencies, CLI tools, databases, or runtime requirements.

---

## Sources

### Primary (HIGH confidence)
- `finyx/references/germany/tax-investment.md` — Verified DE frontmatter pattern, Sparerpauschbetrag €1,000/€2,000 (since 2023), Vorabpauschale formula, Abgeltungssteuer 26.375%, tax calendar
- `finyx/references/brazil/tax-investment.md` — Verified BR frontmatter pattern, DARF rules, PGBL 12% deduction limit, come-cotas mechanics, FII exemption conditions
- `.planning/phases/06-reference-foundation/06-CONTEXT.md` — Locked decisions D-01 through D-07
- `bin/install.js` `copyWithPathReplacement` — Verified recursive directory copy; new `insights/` subdir requires no install.js changes

### Secondary (MEDIUM confidence)
- `.planning/research/PITFALLS.md` — Pitfall #3 (cross-jurisdiction conflation), Pitfall #4 (gross-income benchmarks) — inform anti-patterns and section structure
- `.planning/research/FEATURES.md` — Country-aware benchmarks feature specification; confirms 50/30/20 adjusted for DE net income; confirms data sourcing from `profile.json`

### Tertiary (LOW confidence — verify before publishing)
- INSS 2025 progressive bracket boundaries (noted in research as approximate; should be confirmed against Receita Federal 2025 tabela before authoring `benchmarks.md`)
- KV Zusatzbeitrag average for 2025 (varies by insurer; GKV-Spitzenverband publishes annually)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — pure Markdown authoring, pattern directly observed in existing docs
- Architecture: HIGH — `insights/` subdir + recursive copy confirmed in `install.js`; frontmatter fields verified against two existing reference docs
- Content values (DE): HIGH — Sparerpauschbetrag, Vorabpauschale, Abgeltungssteuer all verified in `germany/tax-investment.md`
- Content values (BR): MEDIUM — DARF, PGBL rules verified in `brazil/tax-investment.md`; INSS table brackets require independent verification for 2025
- Pitfalls: HIGH — sourced directly from `PITFALLS.md` and project CONTEXT.md locked decisions

**Research date:** 2026-04-06
**Valid until:** 2026-12-31 (stable tax year; revalidate when 2026 tax year docs are needed)
