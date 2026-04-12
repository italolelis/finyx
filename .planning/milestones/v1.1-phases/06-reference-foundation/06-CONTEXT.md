# Phase 6: Reference Foundation - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Create two reference documents (`benchmarks.md` and `scoring-rules.md`) under `finyx/references/insights/` that specialist agents in Phase 7 will consume. These docs define country-aware allocation targets and tax efficiency scoring criteria. No commands or agents are built in this phase.

</domain>

<decisions>
## Implementation Decisions

### Benchmark Targets
- **D-01:** Use net-after-mandatory income as the denominator for all allocation benchmarks. Germany: gross minus ~19.6% employee social contributions minus ~30-35% effective income tax ≈ 55-58% of gross. Brazil: gross minus INSS (7.5-14% capped) minus IRRF (22-27.5% effective) ≈ 70-75% of gross.
- **D-02:** Apply adjusted 50/30/20 rule to net-after-mandatory income, not gross.
- **D-03:** Emergency fund threshold: 6 months of expenses (cross-border complexity warrants this over 3 months).
- **D-04:** Investment rate targets as % of net-after-mandatory: DE 15% minimum / 20-25% aspirational. BR 10-15% minimum (FGTS/INSS partially substitute private savings).

### Scoring Methodology
- **D-05:** Traffic light (green/yellow/red) + € gap display per dimension. Each dimension shows a color indicator AND the absolute € amount of the gap. Example: "🟡 Sparerpauschbetrag: €263/year unused"
- **D-06:** Per-country scoring only — DE and BR are scored independently, never combined into a single metric.
- **D-07:** Scoring thresholds must be defined per country per dimension in `scoring-rules.md` (green = fully optimized, yellow = partial gap, red = significant gap).

### Claude's Discretion
- Doc structure: whether to use a new `insights/` subdir or another org pattern under `finyx/references/`
- Vorabpauschale readiness thresholds: exact buffer percentages and how to handle missing current-year Basiszins
- Specific green/yellow/red threshold boundaries for each dimension (as long as they're reasonable and documented)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Reference Doc Pattern
- `finyx/references/germany/tax-investment.md` — Exemplar for frontmatter format (tax_year, country, domain, last_updated, source), staleness detection convention, and content structure
- `finyx/references/brazil/tax-investment.md` — Brazilian counterpart, same pattern
- `finyx/references/disclaimer.md` — Legal disclaimer template used by all commands

### Tax Rules (Scoring Inputs)
- `finyx/references/germany/tax-investment.md` — Sparerpauschbetrag (€1,000/€2,000), Vorabpauschale formula, Teilfreistellung rates
- `finyx/references/brazil/tax-investment.md` — IR brackets, DARF thresholds, FII exemption rules, come-cotas

### Research
- `.planning/research/FEATURES.md` — Feature priorities and anti-features
- `.planning/research/PITFALLS.md` — Pitfall #3 (cross-jurisdiction conflation), #4 (gross-income benchmarks)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Frontmatter convention: `tax_year`, `country`, `domain`, `last_updated`, `source` — reuse exact pattern
- Staleness detection: existing commands warn when doc tax_year doesn't match current year

### Established Patterns
- Reference docs are pure Markdown knowledge docs, no executable logic
- Country-specific content in subdirectories: `germany/`, `brazil/`
- Commands load refs via `@~/.claude/finyx/references/` in `<execution_context>` blocks

### Integration Points
- `bin/install.js` — must copy new `insights/` subdir (if used) to target
- Phase 7 agents will `@`-reference these docs in their execution context

</code_context>

<specifics>
## Specific Ideas

- User's spreadsheet uses category-based breakdown (Income, Investments, Savings, Debt, Needs, Wants) — the allocation benchmarks should map to similar categories
- Social contribution rates change annually — docs must carry tax_year metadata for staleness detection

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-reference-foundation*
*Context gathered: 2026-04-06*
