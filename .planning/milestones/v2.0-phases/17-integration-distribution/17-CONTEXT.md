# Phase 17: Integration + Distribution - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Final phase: verify cross-skill wiring for finyx-insights, test plugin installation via GitHub URL, remove legacy `commands/finyx/` and `agents/` root directories, update/remove `bin/install.js`. Clean break from npm-only to plugin distribution.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — infrastructure cleanup phase. Key tasks:
1. Verify `skills/insights/SKILL.md` correctly orchestrates across other skills' profile data
2. Remove `commands/finyx/` directory (all content now in skills/)
3. Remove `agents/` root directory (all agents now scoped in skills/*/agents/)
4. Update `bin/install.js` to reflect new skills/ layout OR remove it with rationale
5. Update README.md installation instructions for plugin install
6. Verify `claude plugin validate` passes (or equivalent validation)

### Cleanup from Phase 16 Gap
- Root `agents/` directory must be removed — duplicates already scoped into skills/*/agents/

</decisions>

<code_context>
## Existing Code Insights

All skills are now populated:
- skills/profile/ (600 lines), skills/tax/ (596), skills/invest/ (1065), skills/realestate/ (2177), skills/pension/ (660), skills/insurance/ (604), skills/insights/ (411), skills/help/ (803)
- .claude-plugin/plugin.json manifest exists
- Zero legacy @~/.claude/ paths in skills/

### Legacy to Remove
- `commands/finyx/*.md` — 17 command files (content now in skills/)
- `agents/*.md` — 8 agent files (now in skills/*/agents/)
- Possibly `finyx/references/` — content redistributed into skills/*/references/
- Possibly `finyx/templates/` — check if still needed
- `bin/install.js` — npm installer (evaluate if still needed)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — final cleanup and distribution phase.

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>

---

*Phase: 17-integration-distribution*
*Context gathered: 2026-04-12 via autonomous mode*
