# Phase 10: Specialist Agents - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Create two specialist agent Markdown files: `finyx-insurance-calc-agent.md` (deterministic cost calculation) and `finyx-insurance-research-agent.md` (live PKV provider research). Both agents read the Phase 9 reference doc and `.finyx/profile.json`. No commands built in this phase.

</domain>

<decisions>
## Implementation Decisions

### Calc Agent Output Format
- **D-01:** Output wrapped in `<insurance_calc_result>` with 5 named subsections:
  - `<gkv_breakdown>` — exact monthly cost (base + Zusatzbeitrag + PV, employer share deducted)
  - `<pkv_estimate>` — age/health-based estimate with risk surcharge from binary flags
  - `<family_impact>` — Familienversicherung (GKV free) vs PKV per-person costs for partner + children
  - `<projection_table>` — 10/20/30-year scenarios (conservative/base/optimistic)
  - `<tax_netting>` — PKV net cost after §10 EStG Basisabsicherung deduction

### Research Agent Scope
- **D-02:** Primary: search direct provider websites and neutral aggregator sources (Stiftung Warentest, Finanztip, krankenkasseninfo.de). Avoid Check24 bias — use Check24 only as fallback when other sources are sparse.
- **D-03:** Compare exactly 3 providers in output: top recommendation + 2 alternatives. More creates analysis paralysis.
- **D-04:** Search queries anchored to user's age, employment type, and family status. Fallback list of top-5 DE PKV providers by market share for direct lookups when generic queries are sparse.
- **D-05:** Output wrapped in `<insurance_research_result>` with provider comparison table + Beitragsrückerstattung and Selbstbeteiligung options per provider.

### Health Questionnaire Flow
- **D-06:** Orchestrator (Phase 11) collects 15 binary health flags via AskUserQuestion. Passes all flags inline in the Task prompt as `<health_flags>` structured block. Calc agent reads flags, computes risk tier, applies surcharge. Session-only — flags never written to any file.
- **D-07:** The 15 binary flags are defined in `germany/health-insurance.md` Section 4.2. Calc agent references that section for the tier calculation logic.

### Agent Naming & Tools
- **D-08:** `agents/finyx-insurance-calc-agent.md` — tools: Read, Grep, Glob. Color: red.
- **D-09:** `agents/finyx-insurance-research-agent.md` — tools: Read, Grep, Glob, WebSearch, WebFetch. Color: green.

### Claude's Discretion
- Internal agent prompt structure (role, input, process, output sections)
- Exact web search query templates for research agent
- How to present projection scenarios (tables vs bullet points within XML tags)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Agent Pattern
- `agents/finyx-tax-scoring-agent.md` — Exemplar: YAML frontmatter, role/input/process/output structure, XML output tags, confidence flags, anti-patterns
- `agents/finyx-allocation-agent.md` — Exemplar: how to handle profile field mapping and data-gap notes
- `agents/finyx-location-scout.md` — Exemplar: agent with WebSearch/WebFetch tools (for research agent)

### Phase 9 Reference Doc
- `finyx/references/germany/health-insurance.md` — 371 lines, 2026 constants, 3-tier risk model, 15 binary flags, 4 calculation paths, formulas

### Profile Schema
- `finyx/templates/config.json` — Profile structure (income, tax, family fields)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `finyx-tax-scoring-agent.md` — XML tag output pattern, confidence flags, data-gap handling
- `finyx-location-scout.md` — WebSearch + WebFetch usage pattern for research agent
- `finyx-allocation-agent.md` — Profile field mapping pattern

### Established Patterns
- Agents are stateless — receive context, return structured Markdown
- Agents never write files — orchestrator handles persistence
- YAML frontmatter: name, description, tools, color
- `@~/.claude/finyx/references/` for execution_context includes

### Integration Points
- Phase 11 command will spawn both agents via Task tool
- Calc agent receives `<health_flags>` inline in Task prompt
- Research agent receives age, employment type, family status in Task prompt

</code_context>

<specifics>
## Specific Ideas

- Research agent should search for "PKV Testsieger [year]" from Stiftung Warentest and Finanztip as primary neutral sources
- Calc agent projection should clearly label each scenario and show the crossover year where PKV becomes more expensive than GKV (if applicable)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-specialist-agents*
*Context gathered: 2026-04-08*
