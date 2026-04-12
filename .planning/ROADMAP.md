# Roadmap: Finyx

## Milestones

- ✅ **v1.0 MVP** - Phases 1-5 (shipped 2026-04-06)
- ✅ **v1.1 Financial Insights Dashboard** - Phases 6-8 (shipped 2026-04-06)
- ✅ **v1.2 Health Insurance Advisor** - Phases 9-12 (shipped 2026-04-09)
- 🚧 **v2.0 Plugin Architecture** - Phases 13-17 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) - SHIPPED 2026-04-06</summary>

Phase 1: Rebrand & Foundation, Phase 2: User Financial Profile, Phase 3: Tax Advisory, Phase 4: Investment Advisor + Broker, Phase 5: Pension Planning. 37/37 requirements satisfied.

</details>

<details>
<summary>✅ v1.1 Financial Insights Dashboard (Phases 6-8) - SHIPPED 2026-04-06</summary>

Phase 6: Benchmarks & Scoring Reference Docs, Phase 7: Insight Specialist Agents, Phase 8: /fin:insights Command. All requirements satisfied.

</details>

<details>
<summary>✅ v1.2 Health Insurance Advisor (Phases 9-12) - SHIPPED 2026-04-09</summary>

Phase 9: Reference Foundation, Phase 10: Specialist Agents, Phase 11: Command + Integration, Phase 12: Cross-Advisor Integration. All requirements satisfied.

</details>

### 🚧 v2.0 Plugin Architecture (In Progress)

**Milestone Goal:** Finyx ships as a first-class Claude Code plugin — installable via `claude plugin install`, all commands converted to skills under `skills/`, all agents scoped to their owning skill, path references portable, and the plugin validator passes with zero warnings.

## Phase Details

### Phase 13: Plugin Foundation
**Goal**: The plugin skeleton exists — `plugin.json` manifest, restructured `skills/` directory layout, and portable path references — so the plugin can be recognized by Claude Code's plugin system
**Depends on**: Phase 12 (v1.2 complete)
**Requirements**: PLUG-01, PLUG-02, PLUG-03
**Success Criteria** (what must be TRUE):
  1. `.claude-plugin/plugin.json` exists with correct `name` field and passes `claude plugin validate` with zero warnings
  2. `skills/` directory exists with the correct naming convention (`skills/tax/` not `skills/finyx-tax/`) preserving `/finyx:*` command syntax
  3. No `@~/.claude/finyx/references/` path strings exist anywhere in the codebase — all replaced with `${CLAUDE_SKILL_DIR}/references/`
**Plans:** 2/2 plans complete
Plans:
- [x] 13-01-PLAN.md — Plugin manifest + skill directory skeleton with SKILL.md stubs + agent/reference redistribution
- [x] 13-02-PLAN.md — Path migration (@~/.claude/ to ${CLAUDE_SKILL_DIR}/) + end-to-end validation

### Phase 14: Profile Skill
**Goal**: `finyx-profile` is converted to a fully working skill that other skills can depend on, with profile path strategy (`.finyx/profile.json` + `~/.finyx/` global fallback) validated end-to-end
**Depends on**: Phase 13
**Requirements**: INTG-01
**Success Criteria** (what must be TRUE):
  1. `skills/profile/SKILL.md` exists with correct frontmatter and `disable-model-invocation: true`
  2. Running `/finyx:profile` from a project directory reads and writes `.finyx/profile.json` correctly
  3. Running `/finyx:profile` from a directory without `.finyx/` falls back to `~/.finyx/profile.json` without error
  4. Profile skill's agent is scoped under `skills/profile/agents/` — not at plugin root
**Plans:** 1/1 plans complete
Plans:
- [x] 14-01-PLAN.md — Convert profile command to skill with bundled references and path fallback strategy

### Phase 15: Pilot Skill
**Goal**: `finyx-tax` is converted as a pilot to validate the full skill conversion pattern — SKILL.md frontmatter, scoped agents, bundled reference docs, portable paths — before bulk migration
**Depends on**: Phase 14
**Requirements**: SKILL-01, SKILL-02, SKILL-03, SKILL-04, SKILL-05
**Success Criteria** (what must be TRUE):
  1. `skills/tax/SKILL.md` exists with `disable-model-invocation: true` and a front-loaded trigger description under 250 chars
  2. Tax skill agents exist under `skills/tax/agents/` — zero agents remain at project root for the tax domain
  3. Tax reference docs (germany/tax-rules.md, brazil/tax-rules.md) bundled under `skills/tax/references/` and loaded via `${CLAUDE_SKILL_DIR}/references/`
  4. Running `/finyx:tax` produces correct output with no broken path errors
  5. Conversion pattern documented (checklist or template) so bulk migration in Phase 16 can proceed without re-deriving it
**Plans:** 1/1 plans complete
Plans:
- [x] 15-01-PLAN.md — Convert tax command to full skill + document conversion checklist for Phase 16

### Phase 16: Bulk Migration
**Goal**: All remaining 15 commands (profile and tax already done) are converted to skills following the validated pattern — every skill self-contained, every agent scoped, no shared root-level agents remain
**Depends on**: Phase 15
**Requirements**: SKILL-01, SKILL-02, SKILL-03, SKILL-04, SKILL-05
**Success Criteria** (what must be TRUE):
  1. `skills/` directory contains a SKILL.md for every finyx command: invest, broker, pension, insurance, insights, scout, analyze, filter, compare, stress-test, report, init, and all remaining commands
  2. Every skill has `disable-model-invocation: true` in its frontmatter
  3. No agents exist at the project root `agents/` directory — all redistributed under their owning skill's `agents/` folder
  4. Every skill's reference docs are bundled under `skills/<name>/references/` with no `@~/.claude/` path references
**Plans:** 6/6 plans complete
Plans:
- [x] 16-01-PLAN.md — Convert invest + broker commands to invest skill
- [x] 16-02-PLAN.md — Convert 7 real estate commands to realestate skill
- [x] 16-03-PLAN.md — Convert pension command to pension skill
- [x] 16-04-PLAN.md — Convert insurance command to insurance skill
- [x] 16-05-PLAN.md — Convert insights command to insights skill
- [x] 16-06-PLAN.md — Convert help + status + update commands to help skill

### Phase 17: Integration + Distribution
**Goal**: Cross-skill wiring for `finyx-insights` works, the plugin installs cleanly via GitHub URL, legacy directories are removed, and `bin/install.js` is updated as npm fallback
**Depends on**: Phase 16
**Requirements**: INTG-02, INTG-03, CLEAN-01, CLEAN-02, CLEAN-03
**Success Criteria** (what must be TRUE):
  1. `claude plugin install <github-url>` installs Finyx and all `/finyx:*` commands are available with no errors
  2. `/finyx:insights` produces a complete cross-skill report after plugin install (reads profile, references tax + investment + insurance data)
  3. `commands/finyx/` directory no longer exists in the repository
  4. `agents/` root directory no longer exists in the repository
  5. `bin/install.js` updated to reflect skills layout as npm fallback, or removed with a documented rationale
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 13. Plugin Foundation | v2.0 | 2/2 | Complete    | 2026-04-12 |
| 14. Profile Skill | v2.0 | 1/1 | Complete    | 2026-04-12 |
| 15. Pilot Skill | v2.0 | 1/1 | Complete    | 2026-04-12 |
| 16. Bulk Migration | v2.0 | 6/6 | Complete   | 2026-04-12 |
| 17. Integration + Distribution | v2.0 | 0/? | Not started | - |
