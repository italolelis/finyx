# Phase 2: Tax Advisors - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a unified `/finyx:tax` command that provides country-appropriate investment tax guidance for Germany and Brazil. The command auto-routes by country from the user's profile. Includes new investment-specific tax reference docs per country, Sparerpauschbetrag tracking (stateless from profile), Vorabpauschale calculation, Brazilian IR/DARF/come-cotas/FII guidance, and basic cross-border DBA guidance for dual-resident users.

</domain>

<decisions>
## Implementation Decisions

### Command Structure
- **D-01:** Unified `/finyx:tax` command with automatic country routing from `.finyx/profile.json`. Not split per country.
- **D-02:** Command detects countries from profile (`countries.germany`, `countries.brazil`) and loads country-specific reference docs + question flows accordingly.
- **D-03:** For cross-border users (both DE + BR), the command surfaces both country sections plus a DBA interaction section.

### Reference Doc Strategy
- **D-04:** Split by domain — new `finyx/references/germany/tax-investment.md` and `finyx/references/brazil/tax-investment.md`. Existing `germany/tax-rules.md` (RE-focused) stays untouched.
- **D-05:** Each new tax reference doc has `tax_year` in YAML frontmatter (e.g., `tax_year: 2025`). Commands surface a warning when doc year doesn't match current year.
- **D-06:** Don't retrofit `tax_year` to existing `germany/tax-rules.md` — only apply to new files.
- **D-07:** Content for `germany/tax-investment.md` should draw from the existing `fin-tax` skill at `~/.claude/skills/fin-tax/SKILL.md` — it has comprehensive Abgeltungssteuer, Vorabpauschale, Teilfreistellung, and Freistellungsauftrag content already written.

### Sparerpauschbetrag Tracking
- **D-08:** Stateless — calculated on-the-fly from profile data each run. No persistent tax-year state files.
- **D-09:** Profile schema extended with per-broker dividend/interest estimates under `countries.germany.brokers[]` (or similar). Command sums usage against 1,000/2,000 EUR allowance.
- **D-10:** Output is a report-style breakdown showing per-broker allocation and remaining allowance.

### Cross-border Tax Interaction
- **D-11:** Surface basic DBA guidance in Phase 2 — residency tiebreaker rules, withholding credit mechanics, double-dip prevention.
- **D-12:** Explicitly out-of-scope for Phase 2: INSS expat treatment, FII exemption under Law 15,270/2025 edge cases. Flag these with disclaimer in output.
- **D-13:** Cross-border section only appears when profile has `cross_border: true` (derived in Phase 1).

### Claude's Discretion
- `/finyx:tax` prompt structure and phase ordering — Claude decides the optimal flow as long as all requirements are covered and country routing works.
- Vorabpauschale calculation output format — table, narrative, or both.
- Brazilian DARF deadline reminder mechanism — inline in output or separate note.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Tax Content
- `finyx/references/germany/tax-rules.md` — German RE income tax brackets, depreciation rules (DO NOT modify — Phase 2 adds new file alongside)
- `~/.claude/skills/fin-tax/SKILL.md` — Comprehensive German investment tax reference (Abgeltungssteuer, Vorabpauschale, Teilfreistellung, Freistellungsauftrag). Mine for content when creating `germany/tax-investment.md`
- `~/.claude/skills/fin-tax/references/broker-guide.md` — Broker-specific tax handling guide (if exists)

### Profile & Command Patterns
- `finyx/templates/profile.json` — Current profile schema. Tax commands read country fields from here. Schema may need extension for broker dividend estimates.
- `commands/finyx/profile.md` — Profile interview command. Pattern to follow for tax command structure (frontmatter, execution_context, process phases).
- `commands/finyx/analyze.md` — Example of existing command with profile gating, disclaimer wiring, and reference doc loading.

### Project State
- `.planning/STATE.md` — Notes on unresolved items (INSS expat, Law 15,270/2025 FII, Vorabpauschale 2026 Basiszins)
- `finyx/references/disclaimer.md` — Legal disclaimer template (must be in execution_context)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `finyx/references/germany/tax-rules.md`: Income tax brackets, Soli, church tax formulas — reusable for marginal rate context in investment tax calculations
- `~/.claude/skills/fin-tax/SKILL.md`: Full Abgeltungssteuer/Vorabpauschale/Teilfreistellung tables — copy into new reference doc rather than recreating
- `finyx/references/disclaimer.md`: Legal disclaimer — already wired into all commands via `@path`
- `commands/finyx/profile.md`: AskUserQuestion interview pattern — reuse for any interactive tax input

### Established Patterns
- YAML frontmatter with `name`, `description`, `allowed-tools` for all commands
- `<execution_context>` blocks with `@path` references for knowledge injection
- `<process>` phases with numbered steps and bash code blocks
- Profile gating: `[ -f .finyx/profile.json ] || { echo "ERROR: ..."; exit 1; }`
- Disclaimer: `@~/.claude/finyx/references/disclaimer.md` in every advisory command's execution_context

### Integration Points
- `commands/finyx/help.md` — must be updated to list `/finyx:tax`
- `bin/install.js` — new reference docs need to be included in install paths
- `.finyx/profile.json` — may need schema extension for broker-level dividend estimates

</code_context>

<specifics>
## Specific Ideas

- Mine `~/.claude/skills/fin-tax/SKILL.md` for German investment tax reference content rather than researching from scratch — it's already comprehensive and verified.
- Basiszins 2025 (2.29%) and 2026 (3.20%) values are in the fin-tax skill — use them in reference docs.

</specifics>

<deferred>
## Deferred Ideas

- INSS expat treatment for Brazilians in Germany — needs dedicated research (noted in STATE.md for Phase 4)
- FII dividend exemption edge cases under Law 15,270/2025 — needs Receita Federal source confirmation
- Persistent tax-year tracking (`.finyx/tax-year/YYYY.json`) — reconsider if users request incremental mid-year updates
- Tax-loss harvesting optimization — potential future command
- Anlage KAP filing assistant — potential future command

</deferred>

---

*Phase: 02-tax-advisors*
*Context gathered: 2026-04-06*
