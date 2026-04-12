# Phase 7: Specialist Agents - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Create three specialist agent Markdown files (`finyx-allocation-agent.md`, `finyx-tax-scoring-agent.md`, `finyx-projection-agent.md`) in `agents/`. Each agent reads `.finyx/profile.json` and the Phase 6 reference docs, performs its domain analysis, and returns structured output wrapped in XML tags for the Phase 8 orchestrator to consume. No commands are built in this phase — only the agent prompt files.

</domain>

<decisions>
## Implementation Decisions

### Agent Output Format
- **D-01:** Structured Markdown wrapped in named XML section tags. Allocation agent uses `<allocation_result>`, tax-scoring uses `<tax_score_result>`, projection uses `<projection_result>`. Tables and bullets inside the tags. Orchestrator references tags by name during synthesis.

### Profile Data Mapping
- **D-02:** Completeness gate lives in the Phase 8 orchestrator only (INFRA-01). Agents assume their profile slice is valid — no per-agent validation logic.
- **D-03:** Field mapping per agent:
  - Allocation: `income`, `expenses`, `goals`
  - Tax-scoring: `countries`, `tax`, `investments`
  - Projection: `assets`, `liabilities`, `goals`

### Agent Naming & Tools
- **D-04:** Agent files: `agents/finyx-allocation-agent.md`, `agents/finyx-tax-scoring-agent.md`, `agents/finyx-projection-agent.md`
- **D-05:** Tool permissions: `Read, Grep, Glob` only. No Write, no WebSearch, no Bash. Profile-only data sourcing.
- **D-06:** Task colors: allocation = yellow, tax-scoring = magenta, projection = blue.

### Allocation Categories
- **D-07:** Hybrid approach: agent infers initial categorization from profile field names, suggests it to the user for confirmation. Once confirmed, the mapping is stored deterministically (in `.finyx/config.json` or profile). Subsequent runs use the stored mapping without re-prompting. First-run flow: infer → present → confirm → persist.

### Claude's Discretion
- Internal structure of each agent prompt (sections, instructions ordering)
- Exact Markdown table format within XML tags (as long as orchestrator can parse)
- How to persist confirmed allocation mapping (config.json vs profile.json)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Agent Pattern
- `agents/finyx-analyzer-agent.md` — Exemplar for agent prompt structure (role, input context, process sections, output format)
- `agents/finyx-location-scout.md` — Example with YAML frontmatter (name, description, tools, color)

### Phase 6 Reference Docs (Agent Inputs)
- `finyx/references/insights/benchmarks.md` — Net-after-mandatory income denominators, adjusted 50/30/20, emergency fund thresholds, investment rate targets
- `finyx/references/insights/scoring-rules.md` — Traffic-light thresholds per dimension per country, gap formulas, output format template

### Upstream Tax Docs (Referenced by scoring-rules.md)
- `finyx/references/germany/tax-investment.md` — Sparerpauschbetrag, Vorabpauschale, Teilfreistellung
- `finyx/references/brazil/tax-investment.md` — IR brackets, DARF, FII exemptions, come-cotas

### Profile Schema
- `finyx/templates/config.json` — Profile schema with sections: identity, income, expenses, assets, liabilities, investments, goals, tax, pension

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `finyx-analyzer-agent.md` — Role/Input/Process/Output structure to replicate
- `finyx-location-scout.md` — YAML frontmatter pattern with tools and color

### Established Patterns
- Agents are stateless — receive full context in Task prompt, return Markdown
- Agents never write state — commands handle persistence
- Agent files installed to `~/.claude/agents/` via `bin/install.js` (recursive copy handles new files automatically)

### Integration Points
- Phase 8 orchestrator will spawn these 3 agents via `Task` tool
- Agents reference `@~/.claude/finyx/references/insights/benchmarks.md` and `scoring-rules.md` in execution context
- Output tags consumed by orchestrator synthesis logic

</code_context>

<specifics>
## Specific Ideas

- Allocation categories should map to user's spreadsheet structure: Needs (rent, groceries, utilities, insurance, transport), Wants (dining, subscriptions, entertainment), Savings (bank accounts), Investments (brokers, ETFs, pension), Debt (loans, credit)
- Traffic light output should match the example from Phase 6: "🟡 Sparerpauschbetrag: €263/year unused"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-specialist-agents*
*Context gathered: 2026-04-07*
