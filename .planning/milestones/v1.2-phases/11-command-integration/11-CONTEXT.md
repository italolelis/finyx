# Phase 11: Command + Integration - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the `/finyx:insurance` slash-command (`commands/finyx/insurance.md`) that orchestrates the eligibility gate, health questionnaire, both Phase 10 agents, and presents a unified PKV vs GKV comparison with warnings and disclaimers. Also verify `bin/install.js` handles the new command and agents.

</domain>

<decisions>
## Implementation Decisions

### Report Flow
- **D-01:** Gate-first flow: Phase 1 (eligibility check vs JAEG) → Phase 2 (age-55 warning + expat detection) → Phase 3 (health questionnaire) → Phase 4 (parallel agent spawn) → Phase 5 (comparison synthesis) → Phase 6 (actions/recommendations) → Phase 7 (disclaimer). Fail fast — don't collect questionnaire if user is ineligible for PKV.
- **D-02:** If income < JAEG: emit "GKV is mandatory" message with current GKV cost estimate only. Do NOT spawn agents or collect health questionnaire.
- **D-03:** Age-55 warning as a prominent WARNING banner before questionnaire, not inline in comparison.

### Health Questionnaire UX
- **D-04:** Single AskUserQuestion multiSelect with all 15 binary flags. Labels prefixed with category codes: `[CV]` cardiovascular, `[MET]` metabolic, `[MSK]` musculoskeletal, `[MH]` mental health, `[OTH]` other. One round-trip.
- **D-05:** Flags passed inline to calc agent as `<health_flags>` block in Task prompt (from Phase 10 D-06). Session-only, never persisted.

### Expat Detection
- **D-06:** Check `identity.cross_border === true || identity.countries.length > 1` first. If both signals absent, ask the user inline ("Are you or have you been a resident outside Germany?"). If user confirms expat: show Anwartschaft guidance. If denies: skip.
- **D-07:** Expat section shows Anwartschaft, EU portability, and non-EU gap guidance from health-insurance.md Section 6.

### Agent Spawning
- **D-08:** Spawn calc agent and research agent in parallel via Task tool. Calc agent receives profile slice + health_flags. Research agent receives age, employment type, family status.
- **D-09:** Collect `<insurance_calc_result>` and `<insurance_research_result>`, synthesize into unified comparison.

### Disclaimer
- **D-10:** Disclaimer emitted BEFORE any advisory content (Phase 7 banner, matches insights.md pattern). Include explicit recommendation to consult a Versicherungsberater or Versicherungsmakler.

### install.js
- **D-11:** Claude's discretion — verify recursive copy handles new command file and agents. Research confirmed no code changes needed.

### Claude's Discretion
- Exact comparison table format in the synthesis phase
- How to present the 3 PKV providers alongside the calc agent's estimates
- Whether to use a recommendation summary or just present the data

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Command Pattern
- `commands/finyx/insights.md` — Exemplar: parallel Task spawning, XML tag collection, disclaimer-first, completeness gate
- `commands/finyx/tax.md` — Exemplar: profile validation Phase 1, country-gated processing

### Phase 10 Agents (spawned by this command)
- `agents/finyx-insurance-calc-agent.md` — Returns `<insurance_calc_result>` with 5 subsections
- `agents/finyx-insurance-research-agent.md` — Returns `<insurance_research_result>` with 3-provider comparison

### Phase 9 Reference Doc
- `finyx/references/germany/health-insurance.md` — 371 lines, loaded by agents via @path

### Legal
- `finyx/references/disclaimer.md` — Must be in execution_context

### Installer
- `bin/install.js` — Recursive copy, no changes expected

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `commands/finyx/insights.md` — Parallel Task spawning pattern, XML output synthesis
- `commands/finyx/tax.md` — Profile validation, AskUserQuestion for interactive input
- `commands/finyx/profile.md` — Interactive questionnaire pattern

### Established Patterns
- Commands use `@~/.claude/finyx/references/` for execution_context
- Profile read via `@.finyx/profile.json`
- Agent spawning via Task tool with structured prompts
- `bin/install.js` recursive copy handles new files

### Integration Points
- New command: `commands/finyx/insurance.md`
- Reads `.finyx/profile.json` for income, age, family, identity
- Spawns both insurance agents via Task

</code_context>

<specifics>
## Specific Ideas

- The comparison should feel like talking to a Versicherungsberater — clear recommendation with reasoning, not just a data dump
- Age-55 warning should be emphatic — this is a life-altering, irreversible decision

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-command-integration*
*Context gathered: 2026-04-08*
