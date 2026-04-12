# Technology Stack: Claude Code Plugin Architecture

**Project:** Finyx v2.0 Plugin Migration
**Researched:** 2026-04-12
**Confidence:** HIGH — verified from actual installed plugins at `~/.claude/plugins/`

---

## Plugin System: Verified Ground Truth

All findings below were verified against:
- `/Users/italovietro/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/` — canonical reference
- `/Users/italovietro/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/` — authoritative dev guide
- `/Users/italovietro/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/` — installed Anthropic plugin
- `/Users/italovietro/.claude/skills/fin-advisor/`, `fin-tax/` — locally created skill prototypes

---

## Plugin Directory Structure

```
finyx/
├── .claude-plugin/
│   └── plugin.json              # Required manifest (MUST be in .claude-plugin/)
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md             # Required (must be named SKILL.md, not README.md)
│       ├── references/          # Docs loaded into context as needed
│       ├── scripts/             # Deterministic/reusable code
│       └── assets/              # Templates, icons, output files (not loaded into context)
├── commands/                    # Legacy slash commands (.md files) — still valid
├── agents/                      # Subagent definitions (.md files)
├── hooks/
│   └── hooks.json               # Event handlers (PreToolUse, PostToolUse, etc.)
├── .mcp.json                    # MCP server configuration (optional)
└── README.md
```

**Critical layout rules (verified from plugin-dev manifest-reference.md):**
- `plugin.json` MUST be inside `.claude-plugin/` — not at root, not named `.claude-plugin.json`
- `commands/`, `agents/`, `skills/`, `hooks/` MUST be at plugin root, NOT inside `.claude-plugin/`
- Each skill MUST be a subdirectory with `SKILL.md` inside it (not a flat `.md` file in `skills/`)
- Skills placed directly in `~/.claude/skills/<name>/SKILL.md` (outside any plugin) also work — this is how the fin-advisor, fin-tax prototypes are installed

---

## plugin.json Manifest Schema

**Location:** `.claude-plugin/plugin.json`

### Minimum viable (only required field)
```json
{
  "name": "finyx"
}
```

### Recommended for marketplace
```json
{
  "name": "finyx",
  "version": "2.0.0",
  "description": "AI-powered personal finance advisor for Germany and Brazil",
  "author": {
    "name": "Italo Vietro",
    "email": "italo@example.com",
    "url": "https://github.com/italolelis/finyx"
  },
  "homepage": "https://github.com/italolelis/finyx",
  "repository": "https://github.com/italolelis/finyx",
  "license": "MIT",
  "keywords": ["finance", "tax", "investing", "germany", "brazil", "pension", "insurance"]
}
```

### Full schema with all fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | YES | kebab-case, `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/` |
| `version` | string | no | semver `MAJOR.MINOR.PATCH`, default `"0.1.0"` |
| `description` | string | no | 50-200 chars for marketplace display |
| `author` | object or string | no | `{name, email?, url?}` or `"Name <email> (url)"` |
| `homepage` | string (URL) | no | Docs/landing page link |
| `repository` | string or object | no | Source URL; object: `{type, url, directory?}` |
| `license` | string | no | SPDX identifier (`"MIT"`, `"Apache-2.0"`) |
| `keywords` | string[] | no | 5-10 tags for marketplace discovery |
| `commands` | string or string[] | no | Additional command dirs, supplements `./commands` default |
| `agents` | string or string[] | no | Additional agent dirs, supplements `./agents` default |
| `hooks` | string or object | no | Path to hooks.json OR inline hooks config |
| `mcpServers` | string or object | no | Path to `.mcp.json` OR inline MCP config |

**Path rules for `commands`, `agents`, `hooks`, `mcpServers`:**
- Must be relative paths starting with `./`
- No `../` parent traversal
- Forward slashes only

**Auto-discovery defaults (no need to specify in manifest):**
- `./commands/` — slash commands
- `./agents/` — subagents
- `./skills/` — skills
- `./hooks/hooks.json` — hooks
- `./.mcp.json` — MCP servers

---

## SKILL.md Frontmatter

### Model-invoked skill (auto-triggered by context)

```yaml
---
name: finyx-tax
description: German and Brazilian investment tax guidance. Trigger this skill when the user asks
  about Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung, Anlage KAP,
  imposto de renda, DARF, come-cotas, Fundo Imobiliário (FII), or any question about how
  German or Brazilian taxes affect investments. Also trigger when the user mentions Steuererklarung,
  ELSTER, TaxFix, Receita Federal, or tax filing in either country.
version: 2.0.0
---
```

### User-invoked skill (slash command `/finyx:tax`)

```yaml
---
name: finyx:tax
description: Analyze tax situation for Germany and Brazil, optimize for Abgeltungssteuer and IR
argument-hint: [--country de|br] [--year YYYY]
allowed-tools: [Read, WebSearch, AskUserQuestion]
model: sonnet
---
```

### All supported SKILL.md frontmatter fields

| Field | Required | Notes |
|-------|----------|-------|
| `name` | YES | Skill identifier; determines slash command name if user-invoked |
| `description` | YES | PRIMARY trigger mechanism — how Claude decides when to invoke |
| `version` | no | Semantic version string |
| `license` | no | License reference |
| `argument-hint` | no | Shown to user in `/help` for slash commands |
| `allowed-tools` | no | Pre-approved tools, reduces runtime permission prompts |
| `model` | no | Override model: `"haiku"`, `"sonnet"`, `"opus"` |
| `type` | no | Seen in real plugins: `"encoded_preference"`, `"capability_uplift"` (internal convention) |
| `evolution` | no | Claudes-kitchen convention only — eval tracking metadata |

**The `description` field is the trigger.** Claude reads name + description (~100 words, always in context). The SKILL.md body is loaded only when the skill triggers. Write descriptions as imperative trigger conditions with specific phrases users will say.

**Description writing pattern (from skill-creator):**
- Include specific trigger phrases in quotes
- Cover adjacent domains and edge cases
- Slightly "pushy" — "Also trigger when..." — Claude tends to undertrigger
- Third-person recommended: "This skill should be used when..."

---

## Agent Frontmatter (agents/*.md)

```yaml
---
name: finyx-tax-scoring-agent
description: Use this agent when detailed German Abgeltungssteuer or Brazilian IR calculations are needed.

<example>
Context: User has provided their portfolio with ETF holdings at foreign broker
user: "How much tax will I owe on my Trading212 dividends?"
assistant: "I'll use the finyx-tax-scoring-agent to calculate Anlage KAP line-by-line."
<commentary>
Requires detailed per-fund Teilfreistellung calculation and cross-broker offset analysis.
</commentary>
</example>

model: sonnet
color: blue
tools: ["Read", "Bash", "WebSearch"]
---
```

### Agent frontmatter fields

| Field | Required | Notes |
|-------|----------|-------|
| `name` | YES | kebab-case, 3-50 chars |
| `description` | YES | When to use + `<example>` blocks for reliable triggering |
| `model` | no | `"inherit"` (default), `"haiku"`, `"sonnet"`, `"opus"` |
| `color` | no | UI display color: `red`, `blue`, `green`, `yellow`, `purple`, `orange` |
| `tools` | no | Array of tool names the agent is allowed |

---

## Progressive Disclosure (3-Level Loading)

```
Level 1: name + description    -> Always in context (~100 words)
Level 2: SKILL.md body         -> Loaded when skill triggers (<500 lines ideal)
Level 3: references/, scripts/ -> Read explicitly when needed (unlimited)
```

Practical rule: Keep `SKILL.md` under 500 lines. Move detailed reference material (tax rules, country docs, methodology) to `references/` subdirectory. The skill body tells Claude *when* to read them, not their content.

---

## Plugin Installation and Updates

### Installation commands (verified from marketplace README)

```
/plugin install finyx@claude-plugins-official     # From official marketplace
/plugin install finyx@claudes-kitchen             # From community marketplace
/plugin install github:italolelis/finyx           # Direct from GitHub repo
/plugin marketplace add italolelis/finyx          # Add custom marketplace
```

### Marketplace registration

- **Official:** Submit via form at `https://clau.de/plugin-directory-submission`
  - Anthropic reviews for quality and security standards
  - Plugins must have disclaimers, no harmful content
- **Community (claudes-kitchen):** PR to `parloa/claudes-kitchen` GitHub repo
- **Self-hosted:** Clone/copy plugin directory to `~/.claude/plugins/marketplaces/<name>/`

### Auto-updates

Marketplace plugins auto-update by default (`autoUpdate: true` in `installed_plugins.json`). Users get new skills/commands without re-running any install command. This is the key advantage over `npx finyx-cc` which requires manual re-runs.

### Plugin install state

Tracked at `~/.claude/plugins/installed_plugins.json`:
```json
{
  "version": 2,
  "plugins": {
    "finyx@claude-plugins-official": [{
      "scope": "user",
      "installPath": "~/.claude/plugins/cache/claude-plugins-official/finyx/2.0.0",
      "version": "2.0.0",
      "installedAt": "...",
      "lastUpdated": "...",
      "gitCommitSha": "..."
    }]
  }
}
```

Scope can be `"user"` (global) or project-scoped.

---

## Proposed Finyx Plugin Structure

```
finyx/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── finyx-profile/
│   │   ├── SKILL.md             # Profile management — foundation skill
│   │   └── references/
│   │       └── profile-schema.md
│   ├── finyx-tax/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── germany/tax-investment.md
│   │       └── brazil/tax-investment.md
│   ├── finyx-invest/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── etf-methodology.md
│   ├── finyx-insurance/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── germany/health-insurance.md
│   ├── finyx-pension/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── germany/pension.md
│   │       └── brazil/pension.md
│   ├── finyx-broker/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── broker-comparison.md
│   ├── finyx-insights/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── benchmarks.md
│   └── finyx-realestate/
│       ├── SKILL.md
│       └── references/
│           ├── methodology.md
│           └── germany/tax-rules.md
├── agents/
│   ├── finyx-tax-scoring-agent.md
│   ├── finyx-allocation-agent.md
│   ├── finyx-projection-agent.md
│   ├── finyx-insurance-calc-agent.md
│   ├── finyx-insurance-research-agent.md
│   ├── finyx-analyzer-agent.md
│   ├── finyx-location-scout.md
│   └── finyx-reporter-agent.md
├── commands/
│   └── (optional thin /finyx:* triggers — skills with argument-hint cover this)
├── bin/install.js               # Legacy npm fallback, keep working
└── package.json                 # npm distribution preserved
```

---

## Key Design Decisions

### Agents in plugin root `agents/` vs skill-local agents

The plugin system supports both. No evidence from real installed plugins (skill-creator, feature-dev) that skill-scoped agent subdirectories are auto-discovered. All real-world examples put agents at the plugin root `agents/` directory. **Recommendation:** Put all Finyx agents at root `agents/`, not inside skill subdirectories.

### Shared profile access

Skills have no formal dependency declaration. Each skill must independently handle profile loading via instructions in SKILL.md ("Read `.finyx/profile.json` at session start"). Convention-based, not enforced by the plugin system.

### Reference doc deduplication

Tax rules used by both `finyx-tax` and `finyx-insights`: duplicate in each skill's `references/`. No shared library mechanism in the plugin system. Since they're Markdown files loaded on demand, duplication is acceptable — keep per-skill copies.

### commands/ vs skills/ for slash commands

`commands/*.md` is now officially documented as "legacy" by Anthropic. Both load identically. For new slash commands in Finyx v2.0, use `skills/<name>/SKILL.md` with `argument-hint` and `allowed-tools` frontmatter. The `/finyx:*` naming works from skill `name` field using colon namespace.

### npm + plugin dual distribution

Fully supported simultaneously. Keep `bin/install.js` and `package.json`. Add `.claude-plugin/plugin.json`. Users who installed via npm continue to work. Plugin system users get auto-updates. No migration script needed — they coexist.

---

## Sources

All findings are HIGH confidence — verified from files on disk:

- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/` — Canonical example (Anthropic)
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/references/manifest-reference.md` — Complete manifest reference
- `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/SKILL.md` — Skill anatomy documentation
- `~/.claude/plugins/marketplaces/claude-plugins-official/README.md` — Marketplace install commands, submission URL (`https://clau.de/plugin-directory-submission`)
- `~/.claude/skills/fin-advisor/SKILL.md`, `fin-tax/SKILL.md` — Locally installed skill prototypes
- `~/.claude/plugins/cache/claudes-kitchen/workflows/0cbdc25041ed/skills/github-recipe/SKILL.md` — Real-world skill with extended frontmatter fields
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev/agents/code-reviewer.md` — Agent frontmatter reference
- `~/.claude/plugins/installed_plugins.json` — Install state schema
- `~/.claude/plugins/known_marketplaces.json` — Marketplace source schema
