# Phase 12: Cross-Advisor Integration - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `.finyx/profile.json` template with an insurance section and update `/finyx:insights` and `/finyx:tax` commands to reflect insurance costs when the section is populated. No new commands or agents — modifications to 3 existing files.

</domain>

<decisions>
## Implementation Decisions

### Profile Schema
- **D-01:** New `insurance` section in profile template with fields: `type` (GKV/PKV/none), `monthly_cost` (number), `employer_share` (number), `provider` (string, optional). Placed at the same level as existing `tax`, `pension`, `investments` sections.

### Insights Integration
- **D-02:** Insurance costs appear in the allocation breakdown (needs category). If PKV: flag higher cost vs GKV equivalent as a recommendation opportunity. If insurance section is absent/empty: skip silently (existing completeness gate pattern).

### Tax Integration
- **D-03:** When `insurance.type === "PKV"`: `/finyx:tax` includes Basisabsicherung deduction calculation using §10 EStG caps from health-insurance.md Section 5. When GKV or absent: skip insurance tax section.

### Claude's Discretion
- Exact placement of insurance section in profile template JSON
- How to word the insights recommendation when PKV cost exceeds GKV equivalent
- Whether to show insurance as a separate line in the allocation table or merge into "needs"

</decisions>

<canonical_refs>
## Canonical References

### Files to Modify
- `finyx/templates/config.json` — Profile schema template (add insurance section)
- `commands/finyx/insights.md` — Add insurance cost pickup in allocation analysis
- `commands/finyx/tax.md` — Add PKV Basisabsicherung deduction section

### Reference Docs
- `finyx/references/germany/health-insurance.md` — Section 5: §10 EStG deduction caps
- `finyx/references/disclaimer.md` — Already in both commands' execution_context

### Phase 10 Agents (context only — not modified)
- `agents/finyx-allocation-agent.md` — May need awareness of insurance field in profile
- `agents/finyx-tax-scoring-agent.md` — May need PKV deduction dimension

</canonical_refs>

<code_context>
## Existing Code Insights

### Integration Points
- `finyx/templates/config.json` — add insurance block alongside existing sections
- `commands/finyx/insights.md` — allocation agent already reads profile; insurance cost becomes a "needs" line item
- `commands/finyx/tax.md` — already has German tax sections; add PKV deduction as conditional section

### Established Patterns
- Profile sections: `investor`, `strategy`, `criteria`, `assumptions` (real estate), plus `identity`, `income`, `tax`, `investments`, `goals`, `pension` (financial)
- Commands check for section existence before using it (graceful degradation)

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond the success criteria — this is mechanical wiring.

</specifics>

<deferred>
## Deferred Ideas

None — discussion skipped (phase is straightforward)

</deferred>

---

*Phase: 12-cross-advisor-integration*
*Context gathered: 2026-04-08*
