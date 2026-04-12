# Feature Landscape: Plugin Architecture Migration (v2.0)

**Domain:** Claude Code plugin system — migrating Finyx from npm to plugin distribution
**Researched:** 2026-04-12
**Milestone:** v2.0 — Plugin Architecture
**Confidence:** HIGH (sourced from official Claude Code docs, verified against live documentation)

---

## What the Plugin System Actually Unlocks

These are confirmed capabilities from official Claude Code documentation, not aspirational.

### Auto-Triggering (Skills fire on natural language)

Skills with a `description` field in SKILL.md frontmatter load automatically when Claude detects relevant context. The description is the trigger — Claude reads all skill descriptions (always in context, ~30–50 tokens per skill) and loads the full skill content when there's a match.

**What this means for Finyx:**
- User types "what should I do with my taxes this year?" → `finyx:tax` skill activates without `/finyx:tax`
- "Help me understand my pension options" → `finyx:pension` fires
- "I'm thinking about PKV" → `finyx:insurance` fires
- The description must be written for the model ("when should I invoke this?"), not for humans

**Trigger quality determines auto-trigger quality.** The description is capped at 250 characters in the skill listing (truncated beyond that). Front-load the exact phrases users will naturally say.

Good: `German and Brazilian investment tax guidance. Triggers on: capital gains, Abgeltungssteuer, DARF, Vorabpauschale, tax optimization questions, "what should I do with taxes"`

Bad: `The finyx tax advisor provides comprehensive tax analysis for German and Brazilian investors`

### Individual Skill Installation

Users install specific skills via `/plugin install finyx@marketplace`. But the plugin is the distribution unit — individual skill selection happens at plugin level. Within a plugin, all skills load. The granularity is: install the plugin, get all skills in it.

**What this means for Finyx:**
- The plugin is the installable unit, not individual skills
- Skills within the plugin are always co-installed
- To allow partial installation, Finyx would need to be multiple separate plugins (e.g., `finyx-tax` as a standalone plugin, `finyx-invest` as another)
- This is a design decision: one `finyx` plugin (all skills) vs. separate plugins per domain

**Recommendation:** Single `finyx` plugin. Individual skill installation adds distribution complexity with minimal user benefit given the skills are small and interdependent.

### Auto-Updates

Marketplace plugins auto-update by default. Official Anthropic marketplace has auto-update enabled. Community marketplaces default to off. Users are notified when updates are available, then run `/reload-plugins`.

**What this means for Finyx:**
- No more `npx finyx-cc` re-runs to get new tax rules
- Tax year reference doc updates (the highest-friction part of v1.x) auto-deploy
- Version bumps in `plugin.json` are required for updates to propagate (cache-based)

### Marketplace Discovery

Two official distribution paths:
1. **Anthropic official marketplace** (`claude-plugins-official`) — `claude.com/plugins`, submit via `claude.ai/settings/plugins/submit`
2. **GitHub-based marketplace** — any repo with `.claude-plugin/marketplace.json` can be a marketplace

**What this means for Finyx:**
- Submit to `claude.com/plugins` for maximum discovery
- Users find Finyx via `/plugin install finyx@claude-plugins-official`
- No npm knowledge required from users
- GitHub repo can be its own marketplace as fallback (`/plugin marketplace add italolelis/finyx`)

### Skill Invocation Control

Two fields control auto-trigger behavior:

- `disable-model-invocation: true` — skill only fires when user explicitly types `/finyx:command`. Claude never auto-triggers it. Correct for: `/finyx:profile` (destructive questionnaire), `/finyx:insights` (explicit report request)
- `user-invocable: false` — Claude can auto-trigger but it does not appear in `/` menu. Correct for: background knowledge skills (country reference docs)
- Default (no field) — Claude auto-triggers AND user can invoke with `/`

### Namespaced Skills

Plugin skills are namespaced: `finyx` plugin provides `/finyx:tax`, `/finyx:invest`, etc. This prevents conflicts with other installed plugins. The namespace comes from the `name` field in `plugin.json`.

### Subagent Integration

Agents in `agents/` directory of the plugin are auto-discovered. They appear in `/agents`, Claude can invoke them automatically, and they can be invoked manually. Plugin agents support `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation` frontmatter.

### Hooks (New Capability)

Plugins can bundle hooks in `hooks/hooks.json`. Hooks fire on lifecycle events: `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`, `UserPromptSubmit`, etc.

**What this means for Finyx:**
- `SessionStart` hook: detect stale tax reference docs (check `tax_year` metadata, warn if > 6 months old)
- `PostToolUse` hook: after `/finyx:profile` write, validate `profile.json` schema
- `UserPromptSubmit` hook: not recommended (adds latency to every prompt)

### User Configuration at Install Time

`plugin.json` `userConfig` field prompts users for values when the plugin is enabled. Non-sensitive values go to `settings.json`, sensitive values to system keychain. Available as `${user_config.KEY}` in skill content and `CLAUDE_PLUGIN_OPTION_<KEY>` env vars.

**What this means for Finyx:**
- Prompt for `primary_country` (DE/BR/both) at install time — pre-populates profile context
- Prompt for `currency_display` preference
- Do NOT use for sensitive financial data — that stays in `.finyx/profile.json` (user-owned file)

---

## Table Stakes

Features a well-structured plugin must have. Missing any = the plugin fails quality bar for marketplace submission or creates poor UX.

| Feature | Why Required | Notes |
|---------|--------------|-------|
| `plugin.json` manifest with `name`, `version`, `description` | Required for marketplace submission and namespacing | `name` becomes the skill namespace prefix |
| `description` field in every SKILL.md | Without it, auto-triggering doesn't work; Claude can't decide when to load the skill | Front-loaded, ≤250 chars |
| `disable-model-invocation: true` on destructive skills | Profile questionnaire, insights report generation — wrong to auto-trigger | Apply to `/finyx:profile` and `/finyx:insights` |
| Legal disclaimer in all advisory skill output | Anthropic marketplace requirement and legal necessity | Already present in v1.x; must be preserved |
| `SKILL.md` under 500 lines | Documented performance threshold; longer skills eat context disproportionately | Split reference material into supporting files |
| Supporting files for reference docs | `references/germany/tax-rules.md` stays out of SKILL.md, loaded on demand | Reduces context cost until needed |
| `allowed-tools` scoped to what each skill actually uses | Principle of least privilege; required for responsible plugin | Already enforced in v1.x |
| `${CLAUDE_SKILL_DIR}` for referencing bundled files | Absolute paths break after installation; must use skill-relative variable | Replace all `~/.claude/finyx/references/` paths |
| README with installation instructions | Marketplace requires documentation | Dual-path: plugin + npm fallback |
| Semantic versioning in `plugin.json` | Required for auto-updates to propagate; cache is version-keyed | Bump version on every release |

---

## Differentiators

Features that make Finyx a great plugin, not just a ported npm package.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Skill descriptions tuned for natural language triggers | Users get tax/pension/investment advice without knowing the command names | Low | Rewrite descriptions from "what it does" to "when to fire" |
| `finyx-profile` foundation skill with `user-invocable: false` | Profile context loads silently for all sessions; other skills always have context | Low | Background knowledge skill: Claude knows profile structure without user action |
| `SessionStart` hook for tax doc staleness check | Warn users proactively when reference docs are from last tax year | Medium | Compare `tax_year` in reference frontmatter to current date |
| `context: fork` + `agent: Explore` for research skills | Insurance research agent, broker research — isolated execution, no conversation contamination | Low | Already spawning sub-agents via Task tool; `context: fork` is the plugin-native pattern |
| `effort: high` on tax and pension skills | Complex calculations benefit from extended reasoning; user gets better advice | Low | Single frontmatter field — high ROI for no extra work |
| `userConfig` for `primary_country` at install | First-run onboarding without needing `/finyx:profile` first | Low | Reduces time-to-value from install to first useful answer |
| `${CLAUDE_PLUGIN_DATA}` for persistent profile cache | Profile JSON survives plugin updates (unlike `${CLAUDE_PLUGIN_ROOT}`) | Low | Store `.finyx/profile.json` path in data dir, not plugin dir |
| `paths` frontmatter for context-aware skill loading | Tax skill only loads when working in finance-related directories | Low | `paths: ["**/*.finyx*", "**/.finyx/**"]` |
| Hooks for profile schema validation | After profile write, validate required fields exist and types are correct | Medium | `PostToolUse` hook on Write targeting `.finyx/profile.json` |

---

## Anti-Features

Features to explicitly NOT build in the migration.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Multiple separate plugins (finyx-tax, finyx-invest, etc.) | The plugin is the install unit; splitting adds distribution complexity, cross-skill integration breaks, `finyx-insights` can't orchestrate | Single `finyx` plugin, skills are internal structure |
| Skill names without namespace prefix | Plugin skills are auto-namespaced by plugin `name`; adding manual prefix causes double-namespacing (`finyx:finyx-tax`) | Let the plugin manifest handle namespacing; skill dirs use plain names (`tax/`, `invest/`) |
| Migrating CLAUDE.md content into skills | CLAUDE.md content is for persistent facts; skills are for procedures. Putting project conventions in a skill means they only load on demand | Keep CLAUDE.md for always-needed context; skills for invocable procedures |
| `context: fork` on reference/knowledge skills | Forked context loses conversation history; advisory skills need user's financial context to give relevant advice | Only use `context: fork` for isolated research tasks (broker research, insurance provider lookup) |
| Storing sensitive financial data in plugin files | Plugin files are in `~/.claude/plugins/cache/` — cache directory, not user-owned. Profile data must stay in user's project directory | Keep `.finyx/profile.json` in the user's project, reference via standard paths |
| Hooks on `UserPromptSubmit` for financial context injection | Fires on EVERY message; severe latency and context pollution | Use skill descriptions for auto-loading; CLAUDE.md for persistent context |
| Removing npm fallback (`bin/install.js`) immediately | Existing users on npm need migration path; marketplace submission takes time | Keep both; npm installer can detect plugin system and offer migration |
| Auto-triggering `/finyx:insights` | Insights report is expensive and long; wrong to fire on ambiguous prompts | `disable-model-invocation: true` — explicit user intent required |

---

## What Makes a Great Skill vs a Mediocre One

Based on official documentation and real financial skill patterns (finance_skills, financial-analyst SKILL.md).

### Great skill characteristics

**Specific, opinionated description:**
- Bad: `Provides tax analysis for German and Brazilian investors`
- Good: `German investment tax guidance. Use when asked about: Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, capital gains tax, DARF, come-cotas, FII tax exemptions, or "optimize my taxes"`

**Progressive disclosure via supporting files:**
- SKILL.md < 500 lines with overview + section pointers
- `references/germany/tax-rules.md` as supporting file loaded on demand
- `references/brazil/tax-rules.md` as supporting file
- Claude reads the overview; deep reference loads only when needed

**Correct invocation control:**
- Advisory skills: default (auto-trigger enabled) — users benefit from skills activating without knowing command names
- Destructive/long workflows: `disable-model-invocation: true` — user explicitly types the command
- Background knowledge: `user-invocable: false` — Claude loads silently, not in `/` menu

**Tool pre-approval scoped tightly:**
- `allowed-tools: Read Bash(cat *) WebSearch` not `allowed-tools: *`
- Already enforced in v1.x; preserve in migration

**Effort level set explicitly:**
- Tax skill: `effort: high` (complex calculations, extended reasoning worthwhile)
- Profile skill: `effort: medium` (conversational questionnaire)
- Quick lookups: `effort: low`

**5-phase workflow structure** (validated by financial-analyst SKILL.md pattern):
1. Scoping (what does the user actually want?)
2. Data validation (does profile.json have required fields?)
3. Analysis (the actual computation/advice)
4. Output (structured, country-aware, with € amounts)
5. Next actions (actionable items, cross-advisor links)

### Mediocre skill characteristics

- Description is a title, not a trigger
- All logic crammed in SKILL.md (hits context limits, slow to load)
- No `disable-model-invocation` on side-effecting skills
- Generic `allowed-tools: *`
- No supporting files — reference material always in context
- Single-phase "do everything" instruction

---

## Skill Structure for Finyx

Based on what the plugin system enables, the correct structure for each skill:

```
skills/
├── tax/
│   ├── SKILL.md                    # ≤500 lines, auto-trigger enabled, effort: high
│   ├── references/
│   │   ├── germany/
│   │   │   └── tax-investment.md   # loaded on demand
│   │   └── brazil/
│   │       └── tax-investment.md
│   └── examples/
│       └── tax-output-example.md
├── invest/
│   ├── SKILL.md                    # auto-trigger enabled
│   └── references/
│       ├── germany/etf-universe.md
│       └── brazil/b3-funds.md
├── insurance/
│   ├── SKILL.md                    # auto-trigger enabled
│   ├── agents/
│   │   ├── finyx-insurance-calc-agent.md
│   │   └── finyx-insurance-research-agent.md
│   └── references/
│       └── germany/health-insurance.md
├── pension/
│   ├── SKILL.md                    # auto-trigger enabled, effort: high
│   └── references/
│       ├── germany/pension-types.md
│       └── brazil/pension-types.md
├── broker/
│   ├── SKILL.md                    # auto-trigger enabled
│   └── references/
│       ├── germany/brokers.md
│       └── brazil/brokers.md
├── profile/
│   ├── SKILL.md                    # disable-model-invocation: true (destructive questionnaire)
│   └── profile-schema.md
├── insights/
│   ├── SKILL.md                    # disable-model-invocation: true (long report)
│   ├── agents/
│   │   ├── finyx-allocation-agent.md
│   │   ├── finyx-tax-scoring-agent.md
│   │   └── finyx-projection-agent.md
│   └── references/
│       └── insights/benchmarks.md
└── realestate/
    ├── SKILL.md                    # auto-trigger enabled
    └── references/
        └── germany/tax-rules.md
```

---

## Feature Dependencies

```
plugin.json (name: "finyx")
    → all skills namespaced as finyx:*
    → userConfig.primary_country prompts at install

finyx:profile skill (disable-model-invocation: true)
    → writes .finyx/profile.json
    → all other skills depend on profile.json existing

finyx:tax skill (auto-trigger)
    → reads profile.json (income, tax class, investment portfolio)
    → loads references/germany/tax-rules.md or brazil/tax-rules.md on demand
    → output feeds finyx:insights

finyx:invest skill (auto-trigger)
    → reads profile.json (risk profile, portfolio, broker)
    → calls WebSearch for live market data
    → output feeds finyx:insights

finyx:insurance skill (auto-trigger)
    → reads profile.json
    → spawns calc agent + research agent (context: fork)
    → output feeds finyx:insights + finyx:tax (PKV deduction)

finyx:pension skill (auto-trigger, effort: high)
    → reads profile.json
    → cross-references tax headroom from finyx:tax output
    → output feeds finyx:insights

finyx:insights skill (disable-model-invocation: true)
    → reads profile.json
    → spawns allocation, tax-scoring, projection agents
    → synthesizes all domain outputs into unified report
    → does NOT invoke other skills (profile-only data source)

SessionStart hook
    → checks tax_year metadata in reference docs
    → warns if stale (> 6 months from current date)
```

---

## Plugin.json Manifest — Required Fields

Confirmed from official docs (`plugins-reference`). Only `name` is required; all others recommended for marketplace submission.

```json
{
  "name": "finyx",
  "version": "2.0.0",
  "description": "AI-powered personal finance advisor for Germany and Brazil — tax, investments, insurance, pension, real estate",
  "author": {
    "name": "italolelis",
    "url": "https://github.com/italolelis/finyx"
  },
  "homepage": "https://github.com/italolelis/finyx",
  "repository": "https://github.com/italolelis/finyx",
  "license": "MIT",
  "keywords": ["finance", "tax", "germany", "brazil", "investment", "pension", "insurance"],
  "userConfig": {
    "primary_country": {
      "description": "Your primary tax residence (DE, BR, or BOTH)",
      "sensitive": false
    }
  }
}
```

---

## Migration Delta from v1.x to v2.0

What changes and what stays:

| v1.x (npm) | v2.0 (plugin) |
|------------|----------------|
| `commands/finyx/*.md` | `skills/<name>/SKILL.md` (same logic, new location) |
| `agents/*.md` at repo root | `skills/<domain>/agents/*.md` (co-located) |
| `finyx/references/*.md` | `skills/<domain>/references/*.md` (per-skill, loaded on demand) |
| `@~/.claude/finyx/references/` path includes | `${CLAUDE_SKILL_DIR}/references/` path includes |
| `name: finyx:[verb]` in frontmatter | `name` field optional (derived from dir name); plugin adds `finyx:` namespace |
| `allowed-tools` in commands | `allowed-tools` in SKILL.md frontmatter (identical syntax) |
| No auto-trigger | `description` field enables auto-trigger |
| No invocation control | `disable-model-invocation: true` for profile + insights |
| `bin/install.js` required | Optional (fallback only); plugin system handles distribution |
| `package.json` npm manifest | `plugin.json` plugin manifest (both coexist) |
| No hooks | `hooks/hooks.json` for SessionStart staleness check |

---

## Sources

- Claude Code Skills documentation: https://code.claude.com/docs/en/skills (HIGH confidence — official docs)
- Claude Code Plugins documentation: https://code.claude.com/docs/en/plugins (HIGH confidence — official docs)
- Claude Code Plugin Discovery: https://code.claude.com/docs/en/discover-plugins (HIGH confidence — official docs)
- Claude Code Plugins Reference: https://code.claude.com/docs/en/plugins-reference (HIGH confidence — official docs)
- Financial analyst SKILL.md pattern: https://github.com/alirezarezvani/claude-skills/blob/main/finance/financial-analyst/SKILL.md (MEDIUM confidence — community source)
- Skills best practices 2026: https://dev.to/raxxostudios/best-claude-code-skills-plugins-2026-guide-4ak4 (MEDIUM confidence — community source, consistent with official docs)
- Finance skills repo: https://github.com/JoelLewis/finance_skills (MEDIUM confidence — community source)
