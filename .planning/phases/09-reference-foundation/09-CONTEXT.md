# Phase 9: Reference Foundation - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Create `finyx/references/germany/health-insurance.md` — a single reference document with 2026 statutory constants, GKV/PKV formulas, risk tier model, and calculation paths. No commands or agents built in this phase. Follows the existing 1-doc-per-domain-per-country convention.

</domain>

<decisions>
## Implementation Decisions

### PKV Risk Tier Model
- **D-01:** 3-tier model with ~15 binary condition flags. Bands: 0% (no flags), 10-25% (1-2 minor controlled conditions), 30-50%+ (3+ flags or any high-rejection flag).
- **D-02:** Include a rejection-risk callout list (mental health history, HIV, active cancer, recent cardiac events) marked as "high rejection probability" — advisory note, not a quantified tier.
- **D-03:** Binary flags only (yes/no per condition). No diagnosis details, no severity modifiers. GDPR Art. 9 compliant.

### GKV Zusatzbeitrag
- **D-04:** Document the GKV-Spitzenverband average rate (2.75% for 2025) plus the statutory range (2.18–4.4%). No static table of individual fund rates.
- **D-05:** Include a `fallback_rate` field and `source_url` pointing to the GKV-Spitzenverband publication. The Phase 10 research agent fetches live fund-specific rates via WebSearch.

### Doc Structure
- **D-06:** Single flat document, ~320 lines, 6 numbered top-level sections:
  1. GKV (with Pflegeversicherung as subsection 1.x)
  2. PKV (age-based estimation, Altersrückstellungen)
  3. Familienversicherung (GKV free coverage rules, PKV per-person costs)
  4. Eligibility Thresholds & Risk Tiers (JAEG, BBG, 3-tier risk model, binary flags)
  5. §10 EStG Deduction (Basisabsicherung cap: €1,900 employees / €2,800 self-employed)
  6. Special Cases (Beamter redirect note, expat Anwartschaft note, age-55 §6 Abs. 3a SGB V lock-in)
- **D-07:** Employer contribution cap formulas inline under GKV section (not a standalone section).
- **D-08:** Frontmatter: `tax_year: 2025`, `country: germany`, `domain: health-insurance`, `last_updated`, `source` — matches existing reference doc convention.

### Claude's Discretion
- Exact wording of risk tier descriptions and flag list
- Level of detail for Altersrückstellungen explanation
- Whether to include PKV premium example ranges by age bracket (acceptable if clearly labeled as indicative)
- Projection methodology details (conservative/base/optimistic growth rate assumptions)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Reference Doc Pattern
- `finyx/references/germany/tax-investment.md` — Exemplar: frontmatter format, staleness notice, numbered sections, source citations
- `finyx/references/germany/pension.md` — Exemplar: how to handle Beamter redirect inline, cross-cutting subsections

### Research
- `.planning/research/STACK.md` — GKV formula constants, PKV estimation approach, data sources
- `.planning/research/FEATURES.md` — 2026 thresholds (JAEG, BBG), feature table stakes
- `.planning/research/PITFALLS.md` — JAEG ≠ BBG confusion, family cost underestimation, age-55 lock-in

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Frontmatter convention: `tax_year`, `country`, `domain`, `last_updated`, `source`
- Staleness detection: commands warn when doc tax_year != current year
- `bin/install.js` recursive copy handles new files automatically

### Established Patterns
- Reference docs are pure Markdown, no executable logic
- Country-specific content in `finyx/references/germany/` subdirectory
- Commands load refs via `@~/.claude/finyx/references/` in `<execution_context>`

### Integration Points
- Phase 10 agents will `@`-reference this doc in their execution context
- Phase 11 command will also load it for eligibility gate logic

</code_context>

<specifics>
## Specific Ideas

- User has personal experience with the PKV/GKV system as an expat in Germany — the doc should cover the Anwartschaft scenario realistically
- The research found that 2026 saw 10-20% PKV increases due to Krankenhausreform — projection methodology should account for non-linear growth

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-reference-foundation*
*Context gathered: 2026-04-08*
