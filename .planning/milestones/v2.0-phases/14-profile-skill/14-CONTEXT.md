# Phase 14: Profile Skill - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Convert `commands/finyx/profile.md` into a fully working skill at `skills/profile/SKILL.md`. Implement profile path strategy: `.finyx/profile.json` in current directory (primary) + `~/.finyx/profile.json` as global fallback. Validate end-to-end.

</domain>

<decisions>
## Implementation Decisions

### Profile Path Strategy
- Primary: `.finyx/profile.json` in current working directory
- Fallback: `~/.finyx/profile.json` in user home (for when no project dir exists)
- Profile skill creates the dir if needed on first run

### Skill Structure
- Move `commands/finyx/profile.md` content into `skills/profile/SKILL.md`
- Update frontmatter to skill format (name, description, allowed-tools)
- Profile is NOT an advisory skill — allow auto-trigger (`disable-model-invocation` NOT set)
- Agent scoping: any profile-related agents go under `skills/profile/agents/`

### Claude's Discretion
All implementation choices are at Claude's discretion — infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `commands/finyx/profile.md` — existing profile command to convert
- `skills/profile/SKILL.md` — stub already exists from Phase 13

### Established Patterns
- Phase 13 created the skill stub with correct frontmatter
- `${CLAUDE_SKILL_DIR}/references/` path convention established

### Integration Points
- All other skills check for profile.json existence
- Profile path must work from both project dirs and home dir

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Refer to ROADMAP phase description and success criteria.

</specifics>

<deferred>
## Deferred Ideas

None — discuss phase skipped.

</deferred>

---

*Phase: 14-profile-skill*
*Context gathered: 2026-04-12 via autonomous mode*
