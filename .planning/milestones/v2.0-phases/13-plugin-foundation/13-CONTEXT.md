# Phase 13: Plugin Foundation - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the plugin skeleton: `.claude-plugin/plugin.json` manifest, restructure all commands into `skills/<name>/SKILL.md` format (directory structure only — content conversion is Phase 14-16), and replace all `@~/.claude/` path references with `${CLAUDE_SKILL_DIR}/`. This phase creates the scaffolding; subsequent phases fill the skills with converted content.

</domain>

<decisions>
## Implementation Decisions

### Skill Grouping
- **D-01:** Group 17 commands into 7-8 domain skills:
  - `skills/profile/` — profile management (was: profile.md)
  - `skills/tax/` — tax advisor DE + BR (was: tax.md)
  - `skills/invest/` — portfolio + broker + market data (was: invest.md, broker.md)
  - `skills/pension/` — pension planning (was: pension.md)
  - `skills/insurance/` — PKV vs GKV (was: insurance.md)
  - `skills/insights/` — unified dashboard (was: insights.md)
  - `skills/realestate/` — scout, analyze, filter, compare, stress-test, report, rates (was: 7 separate commands)
  - `skills/help/` — help + status + update (was: help.md, status.md, update.md)
- **D-02:** All skills, no commands layer. Profile is a skill like everything else. `/finyx:*` syntax comes from skill naming in a plugin named `finyx`.

### plugin.json Metadata
- **D-03:** Full metadata: name (`finyx`), version, description, author (`Italo Vietro`), homepage (GitHub), repository, license (MIT), keywords for discoverability.

### Path Migration
- **D-04:** All `@~/.claude/finyx/references/` → `${CLAUDE_SKILL_DIR}/references/` across every file.
- **D-05:** Skill dir naming: `skills/tax/` not `skills/finyx-tax/` — preserves `/finyx:tax` syntax.

### Agent Scoping
- **D-06:** Every agent belongs to its owning skill under `skills/<name>/agents/`. No root `agents/` directory. If an agent is used by multiple skills (e.g., tax-scoring used by both tax and insights), it lives in the primary skill and the secondary skill references it by path.

### Frontmatter
- **D-07:** `disable-model-invocation: true` on all advisory skills (tax, invest, pension, insurance, insights). Profile and help may allow auto-trigger.

### Claude's Discretion
- Exact plugin.json keywords
- Whether to create empty SKILL.md stubs in this phase or just the directory structure
- How to handle the `invest` + `broker` merge (single SKILL.md or sub-skills)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plugin System Documentation
- `~/.claude/plugins/cache/claude-plugins-official/plugin-dev/` — Official plugin development skill
- `~/.claude/plugins/cache/claude-plugins-official/skill-creator/` — Example of skill with bundled agents
- `.planning/research/STACK.md` — Complete plugin.json schema and SKILL.md frontmatter fields

### Current Codebase (to restructure)
- `commands/finyx/*.md` — 17 command files to redistribute into skills
- `agents/*.md` — 8 agents to redistribute into skill directories
- `finyx/references/` — Reference docs to bundle per skill
- `bin/install.js` — npm installer (to update or remove)

</canonical_refs>

<specifics>
## Specific Ideas

- The `invest` + `broker` merge into a single skill makes sense since broker comparison is a sub-feature of investment advisory
- Real estate grouping (7 commands → 1 skill) is the biggest consolidation — the skill SKILL.md becomes an orchestrator
- `help` + `status` + `update` are utility commands that could be a single `help` skill

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-plugin-foundation*
*Context gathered: 2026-04-12*
