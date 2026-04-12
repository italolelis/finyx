# Domain Pitfalls: Plugin Migration

**Domain:** Migrating Finyx (17 commands, 8 agents) from npm/standalone to Claude Code plugin system
**Researched:** 2026-04-12
**Confidence:** HIGH (official docs + verified issue reports + community post-mortems)

---

## Critical Pitfalls

### Pitfall 1: `@~/.claude/` Path References Break Completely in Plugin Context

**What goes wrong:**
Every Finyx command uses absolute `@~/.claude/finyx/references/...` includes in `<execution_context>` blocks. Inside a plugin skill, Claude Code resolves supporting files relative to `${CLAUDE_SKILL_DIR}`, not `~/.claude/`. The `@~/.claude/` paths resolve to nothing — skills silently lose all reference doc context and operate without tax rules, methodology, or disclaimer files.

**Why it happens:**
The npm installer physically copies files into `~/.claude/` and the commands encode that install-time path. The plugin system never touches `~/.claude/finyx/` — it provides `${CLAUDE_SKILL_DIR}` as the canonical self-referencing path.

**Consequences:**
Skills appear to work but give advice without loaded reference docs. Tax calculations run without `tax-investment.md`. Insurance comparisons run without `health-insurance.md`. No error is raised — the model just answers from training data with HIGH confidence.

**Prevention:**
Replace every `@~/.claude/finyx/references/...` include with `${CLAUDE_SKILL_DIR}/references/...` during migration. Each skill must carry its own copy of the reference docs it needs. Verify with a post-migration smoke test: ask a question that should cite a specific rule from a reference doc, confirm the cited rule is present in that skill's directory.

**Detection:**
After migration, run each skill and ask it to "quote the source rule you used." If it cannot cite a specific rule from a reference file, the include is broken.

---

### Pitfall 2: `profile.json` Relative Path Breaks for Standalone Skill Installs

**What goes wrong:**
All 17 commands resolve `.finyx/profile.json` as a relative path — meaning the file must exist in the user's current working directory. When skills are installed individually (e.g., only `finyx-tax` installed without `finyx-profile`), and when users run skills from directories that are not their financial project root, the profile check `[ -f .finyx/profile.json ]` fails with a confusing error, or worse — it succeeds against a different project's profile in an ancestor directory.

**Why it happens:**
The npm distribution assumes single-context install: all commands live under one roof and the user always runs from their financial project. Individual skill installation breaks this assumption.

**Consequences:**
Skill fails silently or uses wrong profile. `finyx-tax` installed standalone has no way to depend on `finyx-profile` being present. Users who install only `finyx-insurance` get a hard error on first run.

**Prevention:**
1. Document that `finyx-profile` is a prerequisite and list it as a `dependencies` entry in `plugin.json` if the spec supports it.
2. Add a fallback resolution path in each skill: check `./finyx/profile.json`, then `~/.finyx/profile.json` (global profile location).
3. Provide a clear user-facing error: "No profile found at `.finyx/profile.json`. Run `/finyx:profile` first, or check that you are in your Finyx project directory."
4. Consider making `~/.finyx/profile.json` the canonical location so it works regardless of working directory.

**Detection:**
Test each skill in isolation from a directory that does NOT contain `.finyx/profile.json`. The skill should fail with a clear actionable message, not a silent wrong-data scenario.

---

### Pitfall 3: Skill Description Over-Triggering — Finance Terms Are Too Common

**What goes wrong:**
Skill descriptions like "German and Brazilian investment tax guidance" or "portfolio analysis and ETF recommendations" contain terms (`tax`, `investment`, `portfolio`) that appear in general conversations. Claude auto-triggers `finyx-tax` when a user asks an unrelated question mentioning "tax situation" in passing, or triggers `finyx-invest` when discussing a hypothetical investment in a tech project context.

**Why it happens:**
Claude's auto-invocation uses description matching, not intent classification. Financial vocabulary is ubiquitous and high-frequency. With 8 skills all covering finance-adjacent language, the combined description surface area is enormous.

**Consequences:**
Users get unsolicited financial advice mid-conversation. Skills load full reference doc context (500+ tokens each) for unrelated tasks. Multiple skills trigger simultaneously on ambiguous prompts.

**Prevention:**
- Add `disable-model-invocation: true` to all Finyx skills. Finance advice is high-stakes; require explicit invocation via `/finyx:tax`, etc.
- If auto-triggering is desired for some skills, prefix descriptions with explicit intent markers: "Use ONLY when the user explicitly asks for Finyx financial analysis of their..." and add `paths` glob patterns to restrict auto-triggering to `*.finyx` or `.finyx/` file contexts.
- The official docs confirm: descriptions over 250 characters are truncated. Front-load the disambiguating qualifier in the first 60 characters.

**Detection:**
In a fresh session with all Finyx skills loaded, say "I'm thinking about the tax implications of this API design decision." Count how many Finyx skills trigger. Any trigger is a misfire.

---

### Pitfall 4: Agent Files Placed Inside `.claude-plugin/` Instead of Plugin Root

**What goes wrong:**
The official docs state: "Don't put `commands/`, `agents/`, `skills/`, or `hooks/` inside the `.claude-plugin/` directory. Only `plugin.json` goes inside `.claude-plugin/`." Migrators frequently put agent files under `.claude-plugin/agents/` by analogy with other config-bundle patterns. These agents silently fail to load.

**Why it happens:**
The `.claude-plugin/` directory name suggests it is the plugin config container, implying other plugin files belong there too. The actual convention is the opposite — only the manifest lives in `.claude-plugin/`.

**Consequences:**
Agents are not discoverable. Skills that delegate to `finyx-tax-scoring-agent` or `finyx-insurance-calc-agent` via `Task` tool get "agent not found" errors at runtime.

**Prevention:**
Correct structure:
```
finyx-plugin/
├── .claude-plugin/
│   └── plugin.json          # manifest ONLY
├── skills/
│   └── finyx-tax/
│       ├── SKILL.md
│       ├── agents/
│       │   └── finyx-tax-scoring-agent.md
│       └── references/
├── agents/                  # plugin-level agents
└── ...
```
Run `claude plugin validate` after every structural change during migration.

**Detection:**
`claude plugin validate` will not catch this (the directory is valid, just ignored). Test by running a skill that spawns an agent and verifying the agent actually executes.

---

## Moderate Pitfalls

### Pitfall 5: Marketplace Validator Schema Bugs Cause Silent Rejection

**What goes wrong:**
The `claude plugin validate` command has a documented bug (GitHub issue #38480, active March 2026): including `description` in `marketplace.json` causes a hard error ("Unrecognized key"), while omitting it produces a warning. Anthropic's own official `claude-plugins-official` marketplace fails its own validator. Additionally, `git-subdir` source type is not in the schema enum, causing any plugin using it to block the entire marketplace (issue #36651 — one invalid entry fails all 86+ plugins).

**Prevention:**
- Run `claude plugin validate` and treat warnings as errors — do not submit with any warnings.
- For `marketplace.json`, omit top-level `description` (use `metadata.description` instead).
- Use `"source": "git"` not `"source": "git-subdir"` for subdirectory references.
- Use full HTTPS URLs (not `owner/repo` shorthand) in all source references.
- Cross-reference against a plugin that is already successfully listed in `claude-plugins-official` before submitting.

---

### Pitfall 6: Reference Doc Duplication Across Skills Creates Staleness Drift

**What goes wrong:**
`finyx/references/germany/tax-investment.md` is currently shared by `finyx-tax`, `finyx-insights`, and `finyx-pension` skills. In the plugin structure, each skill bundles its own copy. When a new tax year requires updating the doc, developers update `finyx-tax/references/germany/tax-investment.md` but forget `finyx-pension/references/germany/tax-investment.md`. The skills silently diverge.

**Why it happens:**
Plugin architecture forces per-skill isolation, but reference docs contain cross-cutting domain knowledge. There is no native deduplication mechanism.

**Consequences:**
`finyx-pension` gives advice based on last year's Sparerpauschbetrag while `finyx-tax` uses the updated figure.

**Prevention:**
- Keep shared reference docs in a `finyx-core` layer that skills reference via `${CLAUDE_SKILL_DIR}/../../references/shared/` (if directory traversal is permitted), OR
- Maintain a single source of truth in the repo and use a build step (a simple `bin/sync-refs.js`) that copies shared docs into each skill's `references/` directory before plugin packaging.
- Add a `tax_year` frontmatter field to every reference doc. Skills validate this at runtime: if `tax_year` < current year, emit a staleness warning in the output.

---

### Pitfall 7: Skill Name Namespace Collision — `/finyx:tax` vs Plugin Namespace `/finyx:finyx-tax`

**What goes wrong:**
Plugin skills are automatically namespaced as `/plugin-name:skill-name`. If `plugin.json` names the plugin `finyx` and the skill directory is `finyx-tax`, the invocation becomes `/finyx:finyx-tax` — clunky and inconsistent with v1 muscle memory (`/finyx:tax`). If the skill directory is instead named `tax`, the command is `/finyx:tax` — correct, but the plugin-level agents directory must use unambiguous names to avoid shadowing.

**Prevention:**
Name skill directories after the command suffix only: `tax/`, `invest/`, `insurance/`, not `finyx-tax/`. This produces `/finyx:tax`, `/finyx:invest`, etc. — preserving all existing user muscle memory.

Verify each skill name: `ls skills/` should read `tax invest insurance broker pension profile insights realestate`.

---

### Pitfall 8: `context: fork` Skills Lose Conversation History — Breaking Profile-Dependent Flows

**What goes wrong:**
Adding `context: fork` to skills that need `.finyx/profile.json` data is tempting (isolation, clean state). But forked subagents do not have access to conversation history. Any profile data passed conversationally ("my marginal tax rate is 42%") is invisible to the forked skill.

**Why it happens:**
`context: fork` is designed for self-contained tasks. Finance skills are stateful — they need profile context that may have been established earlier in the session.

**Consequences:**
Forked `finyx-tax` skill asks the user for their tax rate even though they provided it two turns ago. Profile pre-flight checks that rely on conversational context fail.

**Prevention:**
Do NOT use `context: fork` for any skill that reads from `.finyx/profile.json` or depends on session-established context. Use inline execution (default) for all Finyx advisory skills. Reserve `context: fork` only for pure-research tasks (e.g., a web-search-only provider research sub-task).

---

### Pitfall 9: Skill Content Survives Compaction With Only First 5,000 Tokens

**What goes wrong:**
When context fills and auto-compaction runs, each invoked skill is re-attached with a cap of 5,000 tokens. Skills longer than this are silently truncated. `finyx-insurance/SKILL.md` is already large — it includes the 25-flag questionnaire logic, 3-tier risk model, and PKV/GKV comparison methodology. If it exceeds 5,000 tokens, the tail of the skill (e.g., the cross-advisor integration section) silently disappears mid-session.

**Prevention:**
- Keep each `SKILL.md` under 500 lines (per official guidance) and under 4,000 tokens.
- Move detailed reference content to supporting files (`references/pkv-methodology.md`) and reference them from `SKILL.md` with explicit load instructions.
- Test long sessions: run the full insurance skill flow for 10+ turns and verify behavior is consistent in the final turns.

---

## Minor Pitfalls

### Pitfall 10: `bin/install.js` Backward Compatibility — npm Users Get Orphaned

**What goes wrong:**
Users who installed via `npx finyx-cc` have files at `~/.claude/commands/finyx/` and `~/.claude/agents/`. After migrating to the plugin, they install `/plugin install finyx`. Both versions coexist silently. The npm-installed commands take precedence over the plugin-namespaced skills (standalone > plugin for same-name items). Users keep using the old `/finyx:tax` command path, which does not benefit from plugin updates.

**Prevention:**
Update `bin/install.js` to detect plugin installation and warn: "A plugin version of Finyx is installed. Your npm-installed commands may shadow it. Run `npx finyx-cc --uninstall` to migrate cleanly."

Document the migration path explicitly in README: uninstall npm version first, then install plugin.

---

### Pitfall 11: `allowed-tools` Must Be Exhaustive Per Skill — Not Inherited

**What goes wrong:**
In the command architecture, `allowed-tools` in frontmatter is an allowlist and works at the command level. In the plugin skill system, each skill's `allowed-tools` grants pre-approved tools for that skill only. Skills that spawn agents via `Task` need `Task` in their `allowed-tools`. Forgetting `Task` in a skill that delegates to `finyx-tax-scoring-agent` causes a permission prompt every invocation.

**Prevention:**
Audit every skill that uses sub-agents and verify `Task` is in its `allowed-tools`. Finyx skills that need it: `finyx-insights` (spawns 3 agents), `finyx-insurance` (spawns calc + research agents), `finyx-tax` (spawns tax-scoring agent).

---

### Pitfall 12: `user-invocable: false` vs `disable-model-invocation: true` Confusion

**What goes wrong:**
These two flags sound similar but control different things:
- `disable-model-invocation: true` — removes skill from Claude's context entirely; Claude cannot auto-trigger it
- `user-invocable: false` — hides from `/` menu; Claude CAN still auto-trigger it

Using `user-invocable: false` thinking it prevents auto-triggering (the actual goal for high-stakes finance skills) while Claude continues to auto-invoke the skill.

**Prevention:**
For all Finyx advisory skills where auto-trigger is unwanted: use `disable-model-invocation: true`, not `user-invocable: false`. These skills should remain user-invocable (they need `/finyx:tax` to work), so never set `user-invocable: false`.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Plugin manifest creation | `description` field in `marketplace.json` causes validator rejection | Omit top-level description; use `metadata.description` |
| Skill directory naming | Double-prefixed names like `/finyx:finyx-tax` | Name directories `tax/`, `invest/`, not `finyx-tax/` |
| `finyx-profile` skill (foundation) | profile.json relative path breaks outside project dir | Add `~/.finyx/profile.json` fallback resolution |
| `finyx-tax` pilot conversion | `@~/.claude/` includes silently break | Replace all absolute `@` paths with `${CLAUDE_SKILL_DIR}/references/...` |
| Agent redistribution | Agents placed inside `.claude-plugin/` | All agents at plugin root or inside skill `agents/` subdirectory |
| `finyx-insights` (last, cross-cutting) | Reference doc drift across 3+ skills using same tax docs | Build step to sync shared docs before packaging |
| Auto-trigger behavior | Finance terms over-trigger on unrelated queries | Set `disable-model-invocation: true` on all advisory skills |
| Backward compatibility | npm-installed commands shadow plugin skills | Update installer to detect and warn; document migration path |
| Marketplace submission | Single invalid entry blocks all plugins | `claude plugin validate` with zero warnings before submit |
| Long-session use | Skills truncated to 5k tokens after compaction | Keep SKILL.md under 500 lines; move detail to supporting files |

---

## Testing Approach

### Local Pre-Submission Checklist

1. **Structural validation:** `claude plugin validate` — zero warnings, zero errors.
2. **Path resolution test:** In each skill, include a sentence that should be quoted from a reference doc. Verify Claude cites a rule from the bundled file, not from training data.
3. **Profile isolation test:** Run each skill from a directory without `.finyx/profile.json`. Verify a clear, actionable error message appears.
4. **Auto-trigger test:** With all skills loaded, start a fresh session. Mention finance terms in a non-Finyx context. Verify no skills auto-trigger.
5. **Namespace test:** Verify all commands invoke as `/finyx:tax`, `/finyx:invest` etc. — not `/finyx:finyx-tax`.
6. **Agent delegation test:** Run skills that spawn agents (`insights`, `insurance`, `tax`). Verify agents load and execute without permission prompts for pre-approved tools.
7. **Compaction test:** Run `finyx-insurance` through the full 25-question flow + comparison output (~10+ turns). Verify behavior in final turns matches behavior in early turns.
8. **Backward compat test:** Install both npm and plugin versions. Verify the correct version wins and the installer warns about the conflict.

### Local Plugin Loading

```bash
# Test plugin during development without installing
claude --plugin-dir ./finyx-plugin

# Reload without restarting (after editing skills)
/reload-plugins
```

---

## Sources

- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — frontmatter reference, invocation control, compaction behavior (HIGH confidence)
- [Claude Code Plugins docs](https://code.claude.com/docs/en/plugins) — structure, migration steps, submission (HIGH confidence)
- [GitHub issue #38480](https://github.com/anthropics/claude-code/issues/38480) — description field validator bug (HIGH confidence, verified against official repo)
- [GitHub issue #36651](https://github.com/anthropics/claude-code/issues/36651) — all-or-nothing marketplace schema rejection (HIGH confidence, verified against official repo)
- [Scott Spence: Skills don't auto-activate](https://scottspence.com/posts/claude-code-skills-dont-auto-activate) — 50/50 activation rate with passive descriptions (MEDIUM confidence, community)
- [Scott Spence: Reliable activation techniques](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably) — forced eval hook, 84% success rate (MEDIUM confidence, community)
- [MindStudio: Common skill mistakes](https://www.mindstudio.ai/blog/claude-code-skills-common-mistakes-guide) — monolithic files, context bloat (MEDIUM confidence, community)
