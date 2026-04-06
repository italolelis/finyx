# Phase 8: Orchestrator Command - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the `/fin:insights` slash-command (`commands/finyx/insights.md`) that orchestrates the three Phase 7 specialist agents, synthesizes their outputs into a unified financial health report, and updates `bin/install.js` to deploy the new command and agents. This is the final phase of v1.1 — it wires everything together.

</domain>

<decisions>
## Implementation Decisions

### Report Layout
- **D-01:** Section order: Summary (net worth + key metrics) → Health (traffic-light dashboard) → Actions (ranked recommendations) → Detail (per-domain agent outputs). Action-oriented, scan-friendly for CLI.
- **D-02:** Traffic-light dashboard as a single unified table with a `Country` column — not separate per-country blocks. Reduces vertical noise.

### Cross-Advisor Intelligence
- **D-03:** Claude inference from agent outputs with enumerated example patterns in a `<cross_advisor_links>` section of the command prompt. No separate rule engine file. Known patterns to enumerate:
  - Unused Sparerpauschbetrag + low investment rate = double gap
  - No pension contributions + high marginal rate = missed Rürup deduction
  - Emergency fund shortfall + high investment rate = over-allocated risk
  - PGBL not used + completo regime = missed BR deduction
  - Claude may also surface novel combinations beyond these examples.

### Completeness Gate (from Phase 7 D-02)
- **D-04:** Orchestrator validates profile completeness before spawning agents. On incomplete profile: emit a report listing missing sections, do NOT spawn agents. Required fields per agent defined in Phase 7 CONTEXT.md D-03.

### Agent Spawning
- **D-05:** Spawn all 3 agents in parallel via Task tool. Each receives its profile slice pre-validated. Collect `<allocation_result>`, `<tax_score_result>`, `<projection_result>` XML-tagged outputs.

### Recommendation Ranking
- **D-06:** Claude's discretion — derive top-5 recommendations from agent outputs, rank by estimated € annual impact. Each recommendation includes: action, estimated € impact, which dimension it addresses.

### Legal Disclaimer
- **D-07:** Include `@~/.claude/finyx/references/disclaimer.md` in `<execution_context>`. Emit disclaimer before any advisory content. Required by INFRA-03.

### D-07 Allocation Mapping Persistence
- **D-08:** After first-run categorization (D-07 from Phase 7), the confirmed mapping is persisted by the orchestrator (agents have no Write tool). Store in `.finyx/insights-config.json` to avoid polluting the main profile.

### install.js Update
- **D-09:** Claude's discretion on implementation. Research confirmed `copyWithPathReplacement` handles new subdirs automatically — verify if `insights.md` command file and `insights/` reference subdir are picked up without code changes.

### Claude's Discretion
- Recommendation ranking algorithm details (as long as sorted by € impact)
- Exact Markdown formatting of the unified report
- Whether to use `<details>` HTML tags for collapsible detail sections
- install.js verification approach

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Command Pattern
- `commands/finyx/tax.md` — Exemplar for command frontmatter (name, description, allowed-tools), execution_context, phase-based process, profile validation
- `commands/finyx/invest.md` — Example of Task-based agent spawning pattern
- `commands/finyx/profile.md` — Profile creation flow (understanding what fields exist)

### Phase 7 Agent Files (spawned by this command)
- `agents/finyx-allocation-agent.md` — Returns `<allocation_result>`, expects income/expenses/goals slice
- `agents/finyx-tax-scoring-agent.md` — Returns `<tax_score_result>`, expects countries/tax/investments slice
- `agents/finyx-projection-agent.md` — Returns `<projection_result>`, expects assets/liabilities/goals slice

### Phase 6 Reference Docs (loaded by agents)
- `finyx/references/insights/benchmarks.md` — Allocation benchmarks
- `finyx/references/insights/scoring-rules.md` — Scoring thresholds and output format

### Legal
- `finyx/references/disclaimer.md` — Must be included in execution_context

### Installer
- `bin/install.js` — Recursive copy logic, path rewriting

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `commands/finyx/tax.md` — Profile validation pattern (Phase 1: check .finyx/profile.json exists)
- `commands/finyx/invest.md` — Task tool agent spawning pattern
- All existing commands use same frontmatter structure

### Established Patterns
- Commands use `@~/.claude/finyx/references/` for execution_context includes
- Profile read via `@.finyx/profile.json` in execution_context
- Agent spawning via `Task` tool with structured prompt
- `bin/install.js` uses `copyWithPathReplacement` for recursive directory copy

### Integration Points
- New command file: `commands/finyx/insights.md`
- Installer must deploy: command file + 3 agent files + insights/ reference subdir
- Profile read from `.finyx/profile.json`

</code_context>

<specifics>
## Specific Ideas

- Report should feel like a financial advisor briefing — concise, action-oriented
- User's spreadsheet had a "WHERE IS MY MONEY GOING?" section with a bar chart — the allocation section should answer this same question
- Net worth snapshot should mirror the user's "Net Worth Tracker" sheet concept

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-orchestrator-command*
*Context gathered: 2026-04-07*
