# Phase 1: Foundation + Profile - Research

**Researched:** 2026-04-06
**Domain:** Claude Code slash-command architecture — package rename, namespace migration, profile interview design
**Confidence:** HIGH

## Summary

This phase is a rename/refactor plus new feature work. The rename scope is well-defined: `immo-cc` → `finyx`, `commands/immo/` → `commands/finyx/`, `immo/` → `finyx/`, `.immo/` → `.finyx/`. The codebase is small (~20 files) and the installer already handles path rewriting generically — adapting it is mechanical.

The new work is the `/fin:profile` command. It expands the existing `init.md` interview pattern to cover a broader financial picture (income, tax class, family, goals, risk tolerance) with conditional country-specific branches (Germany and Brazil). Cross-border detection is a derived boolean computed after group 1 (residency + nationality), not a standalone question. The profile writes to `.finyx/profile.json` as the single source of truth for all specialist agents.

The legal disclaimer (PROF-05) is the simplest requirement: a shared Markdown template injected via `<execution_context>` `@path` into every command that produces advisory output.

**Primary recommendation:** Treat this phase as two parallel workstreams — (A) mechanical rename of all immo references, and (B) net-new `/fin:profile` command built on the expanded `init.md` interview pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Hard cut — deprecate `immo-cc` on npm, publish `finyx` as new package. No coexistence period.
- **D-02:** Run `npm deprecate immo-cc "Renamed to finyx"` to signal the old package is dead.
- **D-03:** All commands move to `commands/finyx/` directory, namespace becomes `/finyx:*`.
- **D-04:** RE commands move to `/finyx:*` namespace alongside new finance commands. No separate `/immo:*` namespace retained.
- **D-05:** All existing RE functionality must work identically under the new namespace — no behavior changes, only path/name changes.
- **D-06:** Upfront linear interview — all profile questions asked before any specialist commands unlock.
- **D-07:** Interview structured in 3 tight groups: (1) Residency + nationality, (2) Income + tax class (conditional on country), (3) Goals + risk tolerance.
- **D-08:** Cross-border is a derived boolean, not a standalone question. Set after group 1 completes.
- **D-09:** Full merge — `.finyx/profile.json` absorbs `.immo/config.json`. Single source of truth from day one.
- **D-10:** All IMMO commands rewritten to read from `.finyx/profile.json` instead of `.immo/config.json`.
- **D-11:** Profile schema must preserve all existing IMMO fields (`investor.marginalRate`, `assumptions.*`, `strategy.*`, `criteria.*`) under a compatible structure.
- **D-12:** `.immo/` directory no longer created by new init — all output goes to `.finyx/`.

### Claude's Discretion
- Profile.json schema field naming and nesting — Claude decides the optimal structure as long as all IMMO fields are preserved and new financial fields are accommodated.
- Banner format and output styling — maintain existing `━━━` pattern but with FINYX branding.
- `bin/install.js` refactoring approach — whatever cleanly handles the new directory structure.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | Project renamed from immo-cc to finyx across package.json, commands, agents, docs | Runtime State Inventory identifies all 20+ files to update; install.js path rewriting already handles most automatically |
| FOUND-02 | Existing real estate capabilities preserved and accessible via new namespace | D-04/D-05: all 11 command files + 3 agents rename only, no logic changes |
| FOUND-03 | Shared memory system — global user profile accessible across all specialist agents | profile.json schema design + `<execution_context>` @path injection pattern already used by all commands |
| FOUND-04 | Multi-country reference doc architecture with `finyx/references/germany/` and `finyx/references/brazil/` structure | Move existing `immo/references/germany/` + create empty `finyx/references/brazil/` placeholder |
| FOUND-05 | Disclaimer template established as cross-cutting concern for all agent outputs | New `finyx/references/disclaimer.md` file + add @path include to every command's `<execution_context>` |
| PROF-01 | User can complete interactive financial interview covering income, tax class, family status, goals, and risk tolerance | `init.md` interview pattern is the direct model; expand to 3 groups per D-07 |
| PROF-02 | Profile supports Germany and Brazil as country contexts simultaneously | Conditional question branches in group 2; profile.json schema has `countries[]` array |
| PROF-03 | System detects cross-border/expat situations and flags jurisdiction implications | Derived boolean after group 1: `cross_border = (residence != nationality OR multiple_income_countries)` |
| PROF-04 | Profile stored as structured `.finyx/profile.json` accessible by all specialist agents | profile.json schema design; all renamed commands get `<execution_context>` @path include |
| PROF-05 | Legal disclaimer displayed on all advisory outputs | Shared `finyx/references/disclaimer.md` + per-command inclusion |
</phase_requirements>

## Runtime State Inventory

This phase is a rename/refactor — explicit inventory required.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `.immo/config.json` in user project directories (written by `immo:init`, read by all commands) | Code migration only — new `/fin:profile` writes `.finyx/profile.json`; old `.immo/` dirs are user-owned and not in this repo. No data migration task needed for the package itself. |
| Live service config | npm package `immo-cc` on registry | Run `npm deprecate immo-cc "Renamed to finyx"` after publishing `finyx` package (D-02) |
| OS-registered state | None — Claude Code slash commands are discovered at invocation from `~/.claude/commands/`, no OS-level registration | None |
| Secrets/env vars | `CLAUDE_CONFIG_DIR` — used in `bin/install.js` to override install target. No rename needed; logic is generic. | None — env var name is install-infrastructure, not brand-coupled |
| Build artifacts | npm package `immo-cc` v0.1.7 on registry; no compiled binaries, no egg-info, no global npm install artifacts in repo | Publish new `finyx` package; run `npm deprecate` on old one |

**Nothing found in category:** OS-registered state and secrets/env vars — verified by code inspection of `bin/install.js` and all command files.

**Key insight:** Users who ran `npx immo-cc` have files installed in `~/.claude/commands/immo/` and `~/.claude/immo/`. Those are user-side artifacts. The new `finyx` package installs to `~/.claude/commands/finyx/` and `~/.claude/finyx/` — no collision, no migration burden on the package.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js | >=16.7.0 | Installer runtime | Already declared in package.json engines field |
| npm | current | Package distribution | Only distribution mechanism for Claude Code plugins |
| Markdown | — | All command and agent logic | Claude Code slash-command architecture; no alternatives |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| CommonJS (`require`) | Node built-in | install.js module system | Existing convention; no build step, must stay CJS |
| `fs`, `path`, `os` | Node built-in | File operations in installer | Already used; zero external deps policy |
| YAML frontmatter | Claude Code convention | Command metadata | Required by Claude Code slash-command parser |

### No New Dependencies

This phase adds zero new npm dependencies. All logic lives in Markdown prompt files. The installer has no runtime dependencies.

## Architecture Patterns

### Recommended Directory Structure After Rename

```
commands/finyx/          # All slash commands (was commands/immo/)
├── profile.md           # NEW — financial profile interview
├── scout.md             # RENAMED from immo:scout
├── analyze.md           # RENAMED from immo:analyze
├── compare.md           # RENAMED
├── filter.md            # RENAMED
├── rates.md             # RENAMED
├── stress-test.md       # RENAMED
├── status.md            # RENAMED
├── update.md            # RENAMED
├── report.md            # RENAMED
└── help.md              # RENAMED

finyx/                   # References and templates (was immo/)
├── references/
│   ├── disclaimer.md    # NEW — legal disclaimer template
│   ├── germany/
│   │   ├── tax-rules.md # MOVED from immo/references/germany/
│   │   └── ...
│   └── brazil/          # NEW — placeholder for Phase 2
│       └── .gitkeep
├── templates/
│   ├── profile.json     # NEW — profile schema template
│   ├── state.md         # MOVED + updated
│   ├── briefing.md      # MOVED
│   └── location-research.md # MOVED
└── VERSION

agents/
├── finyx-analyzer-agent.md    # RENAMED from immo-analyzer-agent.md
├── finyx-location-scout.md    # RENAMED from immo-location-scout.md
└── finyx-reporter-agent.md    # RENAMED from immo-reporter-agent.md

bin/
└── install.js           # UPDATED — finyx paths, new banner, updated help text
```

### Pattern 1: Command File Structure (Existing — Preserve Exactly)

**What:** YAML frontmatter + `<objective>` + `<execution_context>` + `<process>` + `<error_handling>`
**When to use:** Every command file without exception.

```markdown
---
name: finyx:profile
description: Complete financial profile interview to unlock all Finyx advisors
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<objective>
...
</objective>

<execution_context>
@~/.claude/finyx/references/disclaimer.md
@~/.claude/finyx/templates/profile.json
</execution_context>

<process>
## Phase 1: Setup Check
...
## Phase 2: Residency + Nationality
...
</process>
```

### Pattern 2: Cross-Border Detection (Derived Boolean)

**What:** After collecting residence country and nationality, compute `cross_border` flag programmatically in the profile JSON. No explicit question asked.

```json
{
  "identity": {
    "residence_country": "DE",
    "nationality": "BR",
    "has_income_in_multiple_countries": true,
    "cross_border": true
  }
}
```

**Derivation rule:**
```
cross_border = (residence_country != nationality) OR has_income_in_multiple_countries
```

When `cross_border = true`, the interview inserts a context note: "We detected a cross-border situation. We'll gather information for both jurisdictions."

### Pattern 3: Conditional Country Branches in Interview

**What:** Group 2 (Income + Tax) shows country-specific questions based on what was collected in group 1.

```
If residence_country == "DE" OR income countries include "DE":
  → Ask German tax class, Kirchensteuer, gross income DE
If residence_country == "BR" OR income countries include "BR":
  → Ask IR regime (Simplificado/Completo), CPF, gross income BR
```

Both branches can run in the same interview for cross-border users.

### Pattern 4: profile.json Schema

The profile absorbs all existing `config.json` fields plus new financial fields. Existing IMMO field paths must be preserved for backward compatibility with renamed commands.

```json
{
  "$schema": "https://finyx.dev/schemas/profile.schema.json",
  "version": "1.0.0",
  "created": "ISO_DATE",
  "updated": "ISO_DATE",

  "identity": {
    "residence_country": "DE",
    "nationality": "BR",
    "has_income_in_multiple_countries": true,
    "cross_border": true,
    "family_status": "married",
    "children": 0
  },

  "countries": {
    "germany": {
      "tax_class": "III",
      "church_tax": false,
      "gross_income": 150000,
      "marginal_rate": 44.31
    },
    "brazil": {
      "ir_regime": "completo",
      "gross_income": 0,
      "cpf": null
    }
  },

  "goals": {
    "risk_tolerance": "moderate",
    "investment_horizon": 10,
    "primary_goals": ["real_estate", "etf_portfolio"]
  },

  "investor": {
    "marginalRate": 44.31,
    "liquidAssets": 100000,
    "monthlyCommitments": 500
  },

  "strategy": {
    "type": "neubau-rent-sell",
    "horizon": 10,
    "financing": { "ltv": 100, "fixedPeriod": 10 },
    "management": "professional",
    "exitPlan": "sell-tax-free"
  },

  "criteria": {
    "propertyType": "2-bedroom apartment",
    "bedrooms": [2],
    "minYield": 2.8,
    "maxPrice": 450000,
    "minSize": 45,
    "maxSize": 80,
    "parkingRequired": false,
    "parkingPreferred": true,
    "excludeErbpacht": true,
    "excludeGroundFloor": false,
    "topFloorPreferred": false,
    "newConstructionOnly": true
  },

  "assumptions": {
    "appreciation": 2.0,
    "rentIncrease": 0,
    "vacancy": 0,
    "verwaltungPerSqm": 1.0,
    "rucklagePerSqm": 0.6,
    "saleCosts": 7.0,
    "constructionPeriod": 18,
    "constructionDraw": 50
  }
}
```

**Key:** The `investor.*`, `strategy.*`, `criteria.*`, and `assumptions.*` top-level keys are identical to the existing config.json — renamed commands read these paths without change.

### Pattern 5: Disclaimer Template (PROF-05)

**What:** A standalone Markdown file injected into every command's `<execution_context>`.

```markdown
<!-- finyx/references/disclaimer.md -->
## Legal Disclaimer

Finyx provides financial information for educational and planning purposes only.
Nothing in this output constitutes financial, tax, legal, or investment advice.
Consult a qualified professional before making financial decisions.
Tax rules and regulations change frequently — verify current rules with official sources
or a licensed tax advisor in your jurisdiction.
```

Every command that produces advisory output adds:
```
@~/.claude/finyx/references/disclaimer.md
```
to its `<execution_context>` block, and instructs the agent to append the disclaimer to all outputs.

### Pattern 6: install.js Adaptation

The installer's `copyWithPathReplacement` function already rewrites `~/.claude/` → install target. The only change needed is the source directory mappings: `commands/immo` → `commands/finyx`, `immo/` → `finyx/`, and agent file prefix filter `immo-` → `finyx-`.

The VERSION file moves from `~/.claude/immo/VERSION` to `~/.claude/finyx/VERSION`.

### Anti-Patterns to Avoid

- **Keeping `/immo:*` namespace as alias:** D-04 is explicit — no dual namespace. Don't add backward-compat shims.
- **Asking "are you cross-border?" directly:** D-08 — derive it, don't ask it.
- **Separate profile.json for financial data:** D-09 — single file, full merge.
- **Writing to `.immo/` in any new code:** D-12 — all output goes to `.finyx/`.
- **Touching behavior of RE commands:** D-05 — rename only, zero logic changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Path rewriting at install time | Custom string replacement | Extend existing `copyWithPathReplacement` in install.js | Already handles global/local install + `~/.claude/` substitution |
| Knowledge injection into commands | Custom context loading | `@path` directives in `<execution_context>` | Claude Code's native file inclusion; used throughout existing codebase |
| Multi-step interview flow | Custom state machine | `AskUserQuestion` tool with sequential calls | Already the pattern in `init.md`; Claude maintains conversation state |
| Legal disclaimer per output | Per-command copy-paste | Shared `finyx/references/disclaimer.md` + @path include | Single source of truth; update once, all commands get it |

**Key insight:** This codebase has no runtime application — all "logic" is prompt engineering in Markdown. Don't import Node.js libraries or build custom tooling for problems that `AskUserQuestion` + `@path` already solve.

## Common Pitfalls

### Pitfall 1: Breaking @path References During Rename

**What goes wrong:** A command file has `@~/.claude/immo/references/germany/tax-rules.md` after rename; the installed path is now `~/.claude/finyx/references/germany/tax-rules.md`. The `@path` silently fails — Claude gets no context.

**Why it happens:** The installer rewrites `~/.claude/` → install target, but only for `.md` files. If any reference uses a hardcoded path variant or the source files aren't updated, the rewrite chain breaks.

**How to avoid:** After renaming all source files, grep for remaining `immo` strings in `commands/finyx/` and `finyx/` before considering the rename done. Every `@~/.claude/immo/` must become `@~/.claude/finyx/`.

**Warning signs:** Commands that use reference docs (`analyze`, `scout`, `report`) silently ignore methodology or tax rules.

### Pitfall 2: Agent File Discovery by Prefix

**What goes wrong:** `install.js` uninstall logic filters agents by `file.startsWith('immo-')`. After rename, old immo agents remain installed if uninstall runs against a new-name package.

**Why it happens:** The uninstall function in install.js at line 145 hardcodes `immo-` prefix.

**How to avoid:** Update uninstall logic to filter `finyx-` prefix. Also update the install block that copies agents (currently copies all `.md` from `agents/` — fine, but the filter is in uninstall).

**Warning signs:** `npm uninstall -g finyx` leaves `immo-*` agent files in `~/.claude/agents/`.

### Pitfall 3: YAML Frontmatter `name` Field Not Updated

**What goes wrong:** File moved to `commands/finyx/scout.md` but YAML `name:` still says `immo:scout`. Claude Code registers the command under the old name.

**Why it happens:** File rename and content rename are separate operations. Easy to forget the `name:` field inside the file.

**How to avoid:** After all file renames, verify `name:` field in every `.md` frontmatter matches the new `finyx:` namespace.

**Warning signs:** Running `/finyx:scout` gives "command not found" or `/immo:scout` still works unexpectedly.

### Pitfall 4: profile.json Missing IMMO Fields Breaks RE Commands

**What goes wrong:** `/finyx:analyze` reads `.finyx/profile.json` expecting `investor.marginalRate` but the field was nested differently in the new schema.

**Why it happens:** Schema redesign that doesn't preserve backward-compatible field paths for existing commands.

**How to avoid:** Keep `investor.*`, `strategy.*`, `criteria.*`, `assumptions.*` as top-level keys in profile.json. New financial fields go under new top-level keys (`identity`, `countries`, `goals`). Don't restructure existing paths — renamed commands read them verbatim.

**Warning signs:** Tax calculations in analyze output return 0 or undefined.

### Pitfall 5: package.json `bin` Field Not Updated

**What goes wrong:** `bin: { "immo-cc": "bin/install.js" }` — users run `npx finyx-cc` but get "command not found" because the bin name is still `immo-cc`.

**Why it happens:** `package.json` has two rename targets: `name` field AND `bin` field.

**How to avoid:** Update both `name` (package identity) and `bin` key (CLI entrypoint name). Verify with `npx finyx-cc --help` locally before publishing.

### Pitfall 6: Interview Gating Without Profile Existence Check

**What goes wrong:** D-06 says all profile questions must be answered before specialist commands unlock. If renamed commands don't check for `.finyx/profile.json` existence, users skip the interview and get broken analysis.

**Why it happens:** Existing `init.md` checks for `.immo/config.json`. After rename to profile.json, the path in all command pre-flight checks must update.

**How to avoid:** Every renamed command's Phase 1 (Setup Check) must check `[ -f .finyx/profile.json ]` not `[ -f .immo/config.json ]`. Gate message should direct to `/fin:profile`.

## Code Examples

### install.js — Rename Source Directory Mappings

```javascript
// BEFORE
const commandsDest = path.join(targetDir, 'commands', 'immo');
const immoDest = path.join(targetDir, 'immo');

// AFTER
const commandsDest = path.join(targetDir, 'commands', 'finyx');
const finyxDest = path.join(targetDir, 'finyx');

// VERSION file location
const versionDest = path.join(targetDir, 'finyx', 'VERSION');
```

### install.js — Agent Prefix in Uninstall

```javascript
// BEFORE
if (file.startsWith('immo-') && file.endsWith('.md')) {

// AFTER
if (file.startsWith('finyx-') && file.endsWith('.md')) {
```

### Pre-flight Check in All Renamed Commands (Phase 1)

```bash
# BEFORE
[ -f .immo/config.json ] && echo "ERROR: Project already initialized..." && exit 1

# AFTER — for profile command
[ -f .finyx/profile.json ] && echo "ERROR: Profile already exists. Use /finyx:status" && exit 1

# AFTER — for all other commands (gate check)
[ -f .finyx/profile.json ] || echo "ERROR: No profile found. Run /fin:profile first" && exit 1
```

### Cross-Border Detection Logic (in /fin:profile command)

```
After group 1 collects residence_country, nationality, income_countries:

cross_border = false
if residence_country != nationality:
  cross_border = true
if income_countries has more than one country:
  cross_border = true

If cross_border == true:
  Display: "Cross-border situation detected. We'll collect details for both DE and BR."
```

### Disclaimer Injection in Agent Output

```markdown
<!-- In finyx-analyzer-agent.md output section -->
## Legal Disclaimer

{content of finyx/references/disclaimer.md appended here}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-country profile (`investor.country = "Germany"`) | Multi-country `countries{}` object with per-jurisdiction fields | Phase 1 | Enables Brazil support in Phase 2 without schema migration |
| `.immo/config.json` | `.finyx/profile.json` | Phase 1 | Unified source of truth for all specialist agents |
| `immo:*` namespace | `finyx:*` namespace | Phase 1 | All existing RE commands accessible under new brand |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | bin/install.js | ✓ (system) | >=16.7.0 declared | — |
| npm | Package publish | ✓ (system) | current | — |
| Claude Code | Command execution | ✓ (implicit — user has it) | any | — |

No blocking missing dependencies. `npm deprecate` for `immo-cc` requires npm registry credentials — this is a one-time manual step after publish, not a build blocker.

## Open Questions

1. **npm package name: `finyx` or `finyx-cc`?**
   - What we know: Existing package is `immo-cc`; REQUIREMENTS.md mentions `npx finyx-cc`
   - What's unclear: Final package name decision — `finyx` vs `finyx-cc` affects `package.json` `name` field and `bin` key
   - Recommendation: Use `finyx-cc` for consistency with `immo-cc` naming pattern. The `bin` key becomes `finyx-cc`.

2. **Command name: `/finyx:profile` or `/fin:profile`?**
   - What we know: REQUIREMENTS.md uses `/fin:*` (e.g., `npx finyx-cc`) but CONTEXT.md says namespace becomes `/finyx:*`
   - What's unclear: Short alias (`fin`) vs full name (`finyx`) for the command namespace
   - Recommendation: Use `/finyx:*` as the canonical namespace per D-03. The phase success criteria also references `/fin:profile` — treat as shorthand in docs only, not a separate alias.

3. **Should `/fin:profile` also replace `/finyx:init`?**
   - What we know: `init.md` did both project setup AND investor profile; D-06/D-07 define profile as a separate upfront interview
   - What's unclear: Whether `finyx:init` still exists for project directory setup or if `finyx:profile` subsumes it
   - Recommendation: `finyx:profile` handles all profile gathering. Separate `finyx:init` is not needed — profile creation is the initialization step.

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `bin/install.js`, `commands/immo/init.md`, `immo/templates/config.json`, `package.json`, `.github/workflows/publish.yml`, all 11 command files, 3 agent files
- `01-CONTEXT.md` — locked decisions D-01 through D-12

### Secondary (MEDIUM confidence)
- Claude Code slash-command architecture patterns — verified against existing working codebase conventions

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all patterns verified from existing working code
- Architecture: HIGH — patterns directly observable in existing codebase
- Pitfalls: HIGH — derived from direct code inspection of exact files that need changing

**Research date:** 2026-04-06
**Valid until:** 2026-07-06 (stable domain — Claude Code slash-command architecture is not fast-moving)
