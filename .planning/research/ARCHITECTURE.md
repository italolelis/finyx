# Architecture Patterns: Finyx Plugin Migration

**Domain:** Claude Code plugin restructuring
**Researched:** 2026-04-12
**Confidence:** HIGH — verified against actual installed plugin manifests and official `plugin-dev` skill documentation

---

## Verified Plugin Directory Structure

Confirmed from `claude-plugins-official` marketplace plugins (`example-plugin`, `feature-dev`, `skill-creator`, `plugin-dev`):

```
finyx/
├── .claude-plugin/
│   └── plugin.json              # Manifest — only name required, version/author recommended
├── commands/                    # Slash commands: auto-discovered *.md files
├── agents/                      # Shared subagents: auto-discovered *.md files
├── skills/                      # Auto-discovered SKILL.md in each subdirectory
│   └── skill-name/
│       ├── SKILL.md             # Required — frontmatter + instructions
│       ├── references/          # Loaded by Claude as needed (domain docs)
│       ├── agents/              # Skill-scoped agents (also auto-discovered)
│       ├── scripts/             # Deterministic utilities
│       └── assets/              # Output templates, not loaded into context
├── bin/
│   └── install.js               # npm fallback (preserved)
└── package.json                 # npm distribution (preserved)
```

**Critical rules from official `plugin-structure` skill:**
- `commands/`, `agents/`, `skills/` MUST be at plugin root — not inside `.claude-plugin/`
- Only `SKILL.md` filename is recognised — not `README.md` or anything else
- `${CLAUDE_PLUGIN_ROOT}` must be used for all intra-plugin path references in hook/MCP JSON
- Custom `plugin.json` paths supplement defaults, not replace them

**Minimal `plugin.json`:**
```json
{
  "name": "finyx",
  "version": "2.0.0",
  "description": "AI-powered personal finance advisor for Germany and Brazil",
  "author": {
    "name": "Italo Vietro",
    "email": "italo@example.com"
  },
  "homepage": "https://github.com/italolelis/finyx",
  "repository": "https://github.com/italolelis/finyx",
  "license": "MIT",
  "keywords": ["finance", "tax", "germany", "brazil", "investment", "pension", "insurance"]
}
```

---

## Skill Boundaries

One skill per financial domain. Rationale: skills are individually installable and auto-trigger on domain context. Monolithic skill would trigger on everything or nothing.

| Skill Directory | Commands it Absorbs | Agents it Owns | References |
|-----------------|--------------------|--------------------|------------|
| `skills/finyx-profile/` | `profile.md` | none | none |
| `skills/finyx-tax/` | `tax.md` | `finyx-tax-scoring-agent.md` | `germany/tax-investment.md`, `germany/tax-rules.md`, `brazil/tax-investment.md` |
| `skills/finyx-invest/` | `invest.md`, `broker.md`, `rates.md` | none | `germany/brokers.md`, `brazil/brokers.md` |
| `skills/finyx-pension/` | `pension.md` | none | `germany/pension.md`, `brazil/pension.md` |
| `skills/finyx-insurance/` | `insurance.md` | `finyx-insurance-calc-agent.md`, `finyx-insurance-research-agent.md` | `germany/health-insurance.md` |
| `skills/finyx-realestate/` | `scout.md`, `analyze.md`, `filter.md`, `compare.md`, `stress-test.md`, `report.md`, `update.md` | `finyx-analyzer-agent.md`, `finyx-location-scout.md`, `finyx-reporter-agent.md` | `germany/` real estate refs, `erbpacht-detection.md`, `transport-assessment.md`, `methodology.md` |
| `skills/finyx-insights/` | `insights.md` | `finyx-allocation-agent.md`, `finyx-projection-agent.md` | `insights/benchmarks.md`, `insights/scoring-rules.md` |

The `finyx-tax-scoring-agent` serves double duty: spawned by `/finyx:tax` AND by `finyx-insights`. Resolution: keep it in plugin root `agents/`. The insights skill references it by naming convention — Claude Code auto-discovers agents in plugin root `agents/` directory.

**Decision:** Real estate is a single skill (`finyx-realestate`) not six separate skills. The six commands form a pipeline (scout -> analyze -> filter -> compare -> stress-test -> report) that shares state in `.finyx/`. Splitting them would create a multi-install friction story for existing users.

---

## Commands vs Skills: Dual-Mode Pattern

The plugin system supports two layouts for user-invocable slash commands:
1. Legacy: `commands/finyx/tax.md` with full logic
2. New: `skills/finyx-tax/SKILL.md` with `allowed-tools` frontmatter (verified in `example-command` skill)

Both are functionally identical according to official docs. The migration path:

**Keep `commands/` as thin pass-through triggers.** This gives:
- Backward compat for users who know `/finyx:tax`
- Marketplace auto-triggering via skill description (no command needed)
- No duplicated logic

Thin command format (verified `example-command` pattern):
```markdown
---
name: finyx:tax
description: German and Brazilian investment tax advisor
allowed-tools: [Read, Bash, Write, Task, AskUserQuestion]
---

Invoke the finyx-tax skill to run a full tax advisory session.
```

The skill holds all logic. The command is optional but useful for discoverability.

---

## Agents: Per-Skill vs Top-Level

**Finding:** Both patterns are valid and auto-discovered.
- `agents/*.md` at plugin root: available globally across all skills/commands
- `skills/<name>/agents/*.md`: scoped to that skill's context

**Recommendation:** Skill-scoped agents (inside `skills/<name>/agents/`) except for `finyx-tax-scoring-agent` which is shared.

Shared agent resolution: place in plugin root `agents/`. The `finyx-insights` skill already reads `.finyx/profile.json` directly — it only needs the tax-scoring agent when running tax efficiency analysis. Since the agent is at plugin root, it is available to both `finyx-tax` and `finyx-insights` commands.

Revised agent placement:

```
agents/
└── finyx-tax-scoring-agent.md   # Shared: used by tax + insights

skills/finyx-insurance/agents/
├── finyx-insurance-calc-agent.md
└── finyx-insurance-research-agent.md

skills/finyx-realestate/agents/
├── finyx-analyzer-agent.md
├── finyx-location-scout.md
└── finyx-reporter-agent.md

skills/finyx-insights/agents/
├── finyx-allocation-agent.md
└── finyx-projection-agent.md
```

---

## Reference Doc Sharing

**Problem:** `germany/tax-rules.md` is needed by both `finyx-tax` and `finyx-insights`.

**Finding from official skill-development docs:** References in `skills/<name>/references/` are loaded by Claude "as needed" — they are not injected into context automatically. Claude reads them when the SKILL.md instructs it to. There is no deduplication mechanism at the plugin level.

**Recommendation: Duplicate shared reference docs, do not create a `finyx-core` skill.**

Rationale:
- The `finyx-insights` skill reads `.finyx/profile.json` and uses scoring logic from `insights/benchmarks.md` + `insights/scoring-rules.md`. It does NOT re-run tax calculations — it scores against already-profiled data. Therefore it does NOT need `germany/tax-rules.md` at all. The apparent sharing need dissolves on inspection.
- Exception: `disclaimer.md` is used by every skill. Copy it into each skill's references. It is small. Token cost of duplication is negligible vs the complexity of a shared layer.

Reference doc distribution:
```
skills/finyx-tax/references/
├── germany/tax-investment.md
├── germany/tax-rules.md
└── brazil/tax-investment.md

skills/finyx-invest/references/
├── germany/brokers.md
└── brazil/brokers.md

skills/finyx-pension/references/
├── germany/pension.md
└── brazil/pension.md

skills/finyx-insurance/references/
└── germany/health-insurance.md

skills/finyx-realestate/references/
├── germany/           (all real estate refs)
├── erbpacht-detection.md
├── transport-assessment.md
└── methodology.md

skills/finyx-insights/references/
├── insights/benchmarks.md
└── insights/scoring-rules.md
```

---

## Profile Access Convention

**Current state:** Finyx uses `.finyx/profile.json` (project-relative). The pre-existing `fin-advisor` skill uses `~/.claude/finance/profile.json` (home-relative).

**Decision: Keep `.finyx/profile.json` (project-relative) for Finyx.**

Rationale:
- All 17 existing commands and 8 agents already use `.finyx/profile.json`
- Project-relative path enables multiple financial projects in separate directories
- The `fin-advisor` and `fin-tax` skills are separate predecessor prototypes, not part of Finyx v1.x; their path convention is irrelevant
- Migrating path would break every existing user's install

How skills access it: All SKILL.md files instruct Claude to check `$(pwd)/.finyx/profile.json` at session start. The `finyx-profile` skill owns writes; all others are read-only. This is convention-enforced, not technically enforced (no plugin mechanism to declare access levels).

---

## Cross-Skill Integration: finyx-insights

**Problem:** `finyx-insights` synthesizes data from tax, invest, pension, and insurance domains.

**Current architecture (verified from source):** Insights agents read `.finyx/profile.json` directly — they do NOT invoke other commands or skills. The projection agent reads the profile and computes; the allocation agent reads it and scores. The tax-scoring agent reads both the profile and tax reference docs.

**Plugin-era pattern:** No change needed. The profile is the integration bus. `finyx-insights` does not need to detect co-installed skills — it always works from profile data. The `finyx-tax-scoring-agent` (at plugin root `agents/`) is available when the full plugin is installed.

**Standalone install scenario:** If a user installs only `finyx-insights` without `finyx-tax`, the tax-scoring agent is still available (it is at plugin root, shipped with the plugin). The issue only arises if individual skills are distributed as separate packages — which is not the v2.0 model.

**Recommendation:** Defer individual-skill-as-separate-package distribution. For v2.0, ship as one plugin with all skills. Individual installability is a v2.1+ concern.

---

## Backward Compatibility Strategy

Three user segments to preserve:

| Segment | Current Install | Post-Migration |
|---------|----------------|----------------|
| npm global users | `npx finyx-cc` -> files in `~/.claude/commands/finyx/` | Same `bin/install.js` still works; additionally works as plugin |
| npm local users | `npx finyx-cc --local` -> files in `.claude/` | Same |
| Plugin users (new) | `/plugin install finyx@marketplace` | Uses `skills/`, `commands/`, `agents/` layout |

`bin/install.js` must be updated to install into `skills/` and `agents/` at the new layout, not into the legacy `commands/finyx/` and flat `agents/` paths. This is a one-time installer update, not a user-facing change.

**Decision:** npm install remains for users without marketplace access. Keep `package.json`. Update `bin/install.js` to install into the new `skills/` layout. Maintain the `commands/` thin triggers so `/finyx:*` syntax still works for existing users.

---

## Migration Order

The sequence is dependency-driven: foundation first, cross-cutting integration last.

1. Create `.claude-plugin/plugin.json`
2. Create `skills/finyx-profile/` — profile management skill (no dependencies, enables all others)
3. Migrate `skills/finyx-tax/` — pilot skill (standalone, well-bounded, has own scoring agent)
4. Migrate `skills/finyx-invest/` and `skills/finyx-pension/` — simplest standalone skills
5. Migrate `skills/finyx-insurance/` — two agents, health insurance refs
6. Migrate `skills/finyx-realestate/` — largest, self-contained pipeline
7. Migrate `skills/finyx-insights/` — last, depends on all reference docs and shared agent
8. Add `commands/` thin triggers for all `/finyx:*` commands
9. Move `finyx-tax-scoring-agent` to plugin root `agents/`
10. Update `bin/install.js` to target new layout
11. Update README with dual install path (plugin + npm)
12. Submit to Anthropic plugin directory

Step 3 (finyx-tax) is the structural pilot: if the SKILL.md layout, references loading, and agent spawning work for tax, the same pattern applies to all subsequent skills.

---

## Anti-Patterns to Avoid

### Monolithic SKILL.md with all domain logic
All 17 commands worth of logic in one SKILL.md triggers on everything or nothing. Skills must be domain-bounded.

### Hardcoded paths in hook/MCP JSON
Use `${CLAUDE_PLUGIN_ROOT}` exclusively. The plugin installs in different locations for marketplace vs npm users.

### Shared finyx-core skill for reference docs
Adds a dependency layer with no real benefit. The apparent sharing need (tax-rules.md in tax + insights) dissolves because insights only needs scoring logic, not tax calculation rules.

### Putting `commands/`, `agents/`, `skills/` inside `.claude-plugin/`
These MUST be at plugin root. The `.claude-plugin/` directory contains only `plugin.json`.

### Migrating profile path from `.finyx/` to `~/.claude/`
Breaks all existing users. The `fin-advisor` skill's `~/.claude/finance/profile.json` path is from a separate prototype system, not the Finyx v1.x convention.

---

## Final Directory Structure

```
finyx/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── finyx/                   # Thin triggers for /finyx:* syntax (17 files)
│       ├── tax.md
│       ├── invest.md
│       ├── broker.md
│       ├── pension.md
│       ├── insurance.md
│       ├── profile.md
│       ├── insights.md
│       ├── scout.md
│       ├── analyze.md
│       ├── filter.md
│       ├── compare.md
│       ├── stress-test.md
│       ├── report.md
│       ├── update.md
│       ├── rates.md
│       ├── status.md
│       └── help.md
├── agents/
│   └── finyx-tax-scoring-agent.md   # Shared: used by finyx-tax + finyx-insights
├── skills/
│   ├── finyx-profile/
│   │   └── SKILL.md
│   ├── finyx-tax/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── germany/tax-investment.md
│   │       ├── germany/tax-rules.md
│   │       └── brazil/tax-investment.md
│   ├── finyx-invest/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── germany/brokers.md
│   │       └── brazil/brokers.md
│   ├── finyx-pension/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── germany/pension.md
│   │       └── brazil/pension.md
│   ├── finyx-insurance/
│   │   ├── SKILL.md
│   │   ├── agents/
│   │   │   ├── finyx-insurance-calc-agent.md
│   │   │   └── finyx-insurance-research-agent.md
│   │   └── references/
│   │       └── germany/health-insurance.md
│   ├── finyx-realestate/
│   │   ├── SKILL.md
│   │   ├── agents/
│   │   │   ├── finyx-analyzer-agent.md
│   │   │   ├── finyx-location-scout.md
│   │   │   └── finyx-reporter-agent.md
│   │   └── references/
│   │       ├── germany/           (real estate refs)
│   │       ├── erbpacht-detection.md
│   │       ├── transport-assessment.md
│   │       └── methodology.md
│   └── finyx-insights/
│       ├── SKILL.md
│       ├── agents/
│       │   ├── finyx-allocation-agent.md
│       │   └── finyx-projection-agent.md
│       └── references/
│           ├── insights/benchmarks.md
│           └── insights/scoring-rules.md
├── bin/
│   └── install.js               # Updated for new layout, preserved for npm users
└── package.json
```

---

## Sources

- Verified against `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/SKILL.md` (Anthropic official) — HIGH confidence
- Verified against `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/skill-development/SKILL.md` (Anthropic official) — HIGH confidence
- Verified against actual installed plugin directory trees: `feature-dev`, `skill-creator`, `example-plugin`, `typescript-services` — HIGH confidence
- Cross-referenced against existing Finyx source: `commands/finyx/`, `agents/`, `finyx/references/` — HIGH confidence
- Existing `fin-advisor`, `fin-tax` skills at `~/.claude/skills/` verified for SKILL.md format and references structure — HIGH confidence
