# Phase 1: Foundation + Profile - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Rename the project from immo-cc to finyx, migrate all commands to a unified `/finyx:*` namespace, merge `.immo/config.json` into `.finyx/profile.json` as single source of truth, and build an interactive financial profile interview that gates all specialist commands. Cross-border detection (Germany + Brazil) is a first-class requirement.

</domain>

<decisions>
## Implementation Decisions

### Rename Strategy
- **D-01:** Hard cut — deprecate `immo-cc` on npm, publish `finyx` as new package. No coexistence period.
- **D-02:** Run `npm deprecate immo-cc "Renamed to finyx"` to signal the old package is dead.
- **D-03:** All commands move to `commands/finyx/` directory, namespace becomes `/finyx:*`.

### Real Estate Preservation
- **D-04:** RE commands move to `/finyx:*` namespace alongside new finance commands (e.g., `/finyx:scout`, `/finyx:analyze`). No separate `/immo:*` namespace retained.
- **D-05:** All existing RE functionality must work identically under the new namespace — no behavior changes, only path/name changes.

### Profile Interview
- **D-06:** Upfront linear interview — all profile questions asked before any specialist commands unlock.
- **D-07:** Interview structured in 3 tight groups:
  1. **Residency + nationality** — cross-border detection derived automatically (`residence_country != nationality_country OR has_income_in_multiple_countries`)
  2. **Income + tax class** — conditional on detected country set (show DE-specific fields for Germany, BR-specific for Brazil)
  3. **Goals + risk tolerance** — investment horizon, risk appetite, financial goals
- **D-08:** Cross-border is a derived boolean, not a standalone question. Set after group 1 completes.

### Data Architecture
- **D-09:** Full merge — `.finyx/profile.json` absorbs `.immo/config.json`. Single source of truth from day one.
- **D-10:** All IMMO commands rewritten to read from `.finyx/profile.json` instead of `.immo/config.json`.
- **D-11:** Profile schema must preserve all existing IMMO fields (`investor.marginalRate`, `assumptions.*`, `strategy.*`, `criteria.*`) under a compatible structure.
- **D-12:** `.immo/` directory no longer created by new init — all output goes to `.finyx/`.

### Claude's Discretion
- Profile.json schema field naming and nesting — Claude decides the optimal structure as long as all IMMO fields are preserved and new financial fields are accommodated.
- Banner format and output styling — maintain existing `━━━` pattern but with FINYX branding.
- `bin/install.js` refactoring approach — whatever cleanly handles the new directory structure.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Architecture
- `bin/install.js` — Installer that copies commands/agents/references to ~/.claude/; must be rewritten for finyx paths
- `immo/templates/config.json` — Current investor profile schema; all fields must be preserved in new profile.json
- `commands/immo/init.md` — Current interview flow; pattern to follow for /finyx:profile

### Domain Knowledge
- `immo/references/methodology.md` — Core analysis rules (must be preserved)
- `immo/references/germany/tax-rules.md` — German real estate tax rules (move to finyx/references/germany/)

### Agent Definitions
- `agents/immo-analyzer-agent.md` — Must be renamed and updated to read .finyx/profile.json
- `agents/immo-location-scout.md` — Must be renamed and updated
- `agents/immo-reporter-agent.md` — Must be renamed and updated

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/install.js`: Path rewriting logic can be adapted for finyx paths — already handles global/local install + path substitution in .md files
- `commands/immo/init.md`: AskUserQuestion interview pattern — reuse for /finyx:profile with expanded question groups
- `immo/templates/config.json`: Schema structure — migrate fields into new profile.json schema
- `immo/references/germany/`: Country-specific reference doc pattern — extend to `finyx/references/germany/` and `finyx/references/brazil/`

### Established Patterns
- YAML frontmatter with `name`, `description`, `allowed-tools` for all commands
- `<execution_context>` blocks with `@path` references for knowledge injection
- `<process>` phases with numbered steps and bash code blocks
- Sub-agent spawning via `Task` tool with structured input/output
- `.immo/STATE.md` as progress tracker — becomes `.finyx/STATE.md`

### Integration Points
- `package.json` `bin` field → must point to updated install.js
- `package.json` `name` field → changes from `immo-cc` to `finyx`
- `.github/workflows/publish.yml` → may need npm package name update
- All `@~/.claude/immo/` references in command files → become `@~/.claude/finyx/`

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for the rename and restructure.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-foundation-profile*
*Context gathered: 2026-04-06*
