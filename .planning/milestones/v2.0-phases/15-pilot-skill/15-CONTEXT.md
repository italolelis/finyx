# Phase 15: Pilot Skill - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Convert `commands/finyx/tax.md` into `skills/tax/SKILL.md` as the pilot to validate the full skill conversion pattern. Move tax-scoring agent into `skills/tax/agents/`, bundle tax reference docs under `skills/tax/references/`, verify portable paths work. Document the conversion checklist for Phase 16 bulk migration.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — infrastructure phase. Use ROADMAP phase goal, success criteria, and the profile skill conversion (Phase 14) as the established pattern. Key rules:
- `disable-model-invocation: true` (tax is an advisory skill)
- Trigger description under 250 chars, front-loaded for model detection
- Tax-scoring agent scoped under `skills/tax/agents/`
- Tax reference docs (germany/tax-investment.md, brazil/tax-investment.md) under `skills/tax/references/`
- All paths use `${CLAUDE_SKILL_DIR}/references/`
- Document a conversion checklist template for Phase 16

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `commands/finyx/tax.md` — existing tax command to convert
- `skills/tax/SKILL.md` — stub from Phase 13
- `skills/tax/agents/finyx-tax-scoring-agent.md` — already copied in Phase 13
- `skills/tax/references/` — already populated in Phase 13

### Established Pattern (from Phase 14)
- `skills/profile/SKILL.md` — 600 lines, successful conversion with portable paths
- Profile path fallback strategy validated

</code_context>

<specifics>
## Specific Ideas

The conversion checklist produced here will be the template for Phase 16's bulk migration of 15 remaining commands.

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>

---

*Phase: 15-pilot-skill*
*Context gathered: 2026-04-12 via autonomous mode*
