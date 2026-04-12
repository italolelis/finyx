# Research Summary — v2.0 Plugin Architecture

**Researched:** 2026-04-12
**Confidence:** HIGH (verified from actual installed plugins on disk)

## Executive Summary

Finyx v2.0 migrates from npm-only slash-command distribution to the Claude Code plugin system. The plugin format is minimal (`plugin.json` + `skills/` + `agents/`), the marketplace is live, and the migration is mostly structural — rewriting frontmatter and path references, not logic. The highest-risk step is replacing all `@~/.claude/finyx/references/` includes with `${CLAUDE_SKILL_DIR}/references/`.

## Key Findings

### Stack
- `plugin.json` requires only `name` — auto-discovery handles skills, agents, commands
- SKILL.md frontmatter: `name`, `description` (trigger text), `allowed-tools`, `disable-model-invocation`
- `${CLAUDE_SKILL_DIR}` replaces `@~/.claude/` for reference doc paths
- Agents at plugin root `agents/` (globally available) or per-skill `skills/<name>/agents/`
- Marketplace: `claude.ai/settings/plugins/submit` (official) or PR to `parloa/claudes-kitchen`
- Auto-updates enabled by default

### Features
- **Auto-triggering** via description field (but finance vocab over-triggers → use `disable-model-invocation: true`)
- **Progressive disclosure** — reference docs load on demand, not all at context start
- **SessionStart hooks** — can detect stale tax year docs proactively
- **Plugin is the install unit** — users get all skills at once, not individually

### Architecture
- Skill dir naming determines command syntax: `skills/tax/` → `/finyx:tax`
- Shared agents (tax-scoring used by both tax + insights) go to plugin root `agents/`
- Profile stays at `.finyx/profile.json` — add `~/.finyx/` as global fallback
- No `finyx-core` package needed — insights reads profile, not other skills' ref docs
- `bin/install.js` updated to target skills layout as npm fallback

### Top Pitfalls
1. **`@~/.claude/` paths silently break** — skills load from model training data with no error
2. **Finance vocab over-triggers** — set `disable-model-invocation: true` on all advisory skills
3. **Skill dir naming trap** — `finyx-tax/` → `/finyx:finyx-tax`; use `tax/` → `/finyx:tax`
4. **Profile path assumption** — `.finyx/profile.json` needs `~/.finyx/` global fallback
5. **Marketplace validator bugs** — `claude plugin validate` must pass zero warnings

## Suggested Phases (5)

1. **Plugin Foundation** — Create `plugin.json`, restructure dirs, update `bin/install.js`
2. **Profile Skill** — Convert `finyx-profile` as foundation (profile path strategy)
3. **Pilot Skill** — Convert `finyx-tax` to validate the pattern (path refs, frontmatter, agents)
4. **Bulk Migration** — Convert remaining 14 commands to skills in parallel
5. **Integration + Submission** — `finyx-insights` cross-skill wiring, marketplace submission, backward compat testing

---
*Research completed: 2026-04-12*
