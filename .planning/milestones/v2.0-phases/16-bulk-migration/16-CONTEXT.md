# Phase 16: Bulk Migration - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Convert all remaining 15 commands to skills using the validated pattern from Phase 15 (CONVERSION-CHECKLIST.md). Skills to convert: invest (+ broker merge), pension, insurance, insights, realestate (scout+analyze+filter+compare+stress-test+report+rates), help (+ status + update). Every agent redistributed into owning skill. No root agents directory remains.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
Follow the CONVERSION-CHECKLIST.md from Phase 15 for each skill. Key rules:
- Advisory skills get `disable-model-invocation: true` (invest, pension, insurance, insights)
- Non-advisory skills allow auto-trigger (realestate, help)
- Trigger descriptions under 250 chars, front-loaded
- All paths use `${CLAUDE_SKILL_DIR}/references/`
- Agents scoped to owning skill under `skills/<name>/agents/`
- Reference docs bundled per skill under `skills/<name>/references/`
- invest skill absorbs broker command content
- realestate skill absorbs 7 commands (scout, analyze, filter, compare, stress-test, report, rates)
- help skill absorbs status + update commands

</decisions>

<code_context>
## Existing Code Insights

### Conversion Pattern
- `.planning/phases/15-pilot-skill/CONVERSION-CHECKLIST.md` — validated checklist
- `skills/tax/SKILL.md` — 596-line pilot (Phase 15)
- `skills/profile/SKILL.md` — 600-line foundation (Phase 14)

### Files to Convert
- `commands/finyx/invest.md` + `commands/finyx/broker.md` → `skills/invest/SKILL.md`
- `commands/finyx/pension.md` → `skills/pension/SKILL.md`
- `commands/finyx/insurance.md` → `skills/insurance/SKILL.md`
- `commands/finyx/insights.md` → `skills/insights/SKILL.md`
- `commands/finyx/scout.md` + analyze + filter + compare + stress-test + report + rates → `skills/realestate/SKILL.md`
- `commands/finyx/help.md` + status + update → `skills/help/SKILL.md`

</code_context>

<specifics>
## Specific Ideas

The realestate skill is the largest merge — 7 commands into 1 skill. The SKILL.md should act as a router/orchestrator referencing the individual workflow phases.

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>

---

*Phase: 16-bulk-migration*
*Context gathered: 2026-04-12 via autonomous mode*
