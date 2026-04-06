# Phase 4: Pension Planning - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a unified `/finyx:pension` command that provides country-appropriate pension guidance for Germany (Riester/Rürup/bAV comparison with Zulagen and Sonderausgabenabzug calculations) and Brazil (PGBL/VGBL with IR regime comparison), plus a cross-country retirement projection for dual-resident users combining DE statutory + private + BR INSS.

</domain>

<decisions>
## Implementation Decisions

### Command Structure
- **D-01:** Unified `/finyx:pension` command with country routing from profile. Same pattern as `/finyx:tax`.
- **D-02:** PENSION-06 cross-country projection is a late phase in the command, gated on `cross_border: true`.
- **D-03:** Country sections use `## DE` / `## BR` routing blocks inside the prompt.

### Cross-country Projection Scope
- **D-04:** Inflation-adjusted timeline, not simple nominal sum. Real rates hardcoded as versioned constants in pension reference doc: DE 1.5% real, BR 2.0% real after IPCA.
- **D-05:** Real rates are user-overridable via profile fields (`expected_real_return_de`, `expected_real_return_br`).
- **D-06:** INSS expat status handled as user self-reported input (active contributor / suspended / totalization treaty eligible). Command does NOT compute INSS entitlements — it prompts user to declare their status.
- **D-07:** Fixed disclaimer on cross-country projection: "Cross-border pension entitlements require verification by a Brazilian social security lawyer (advogado previdenciário)."
- **D-08:** Profile schema extended with `de_rentenpunkte` (optional), `br_inss_status`, `target_retirement_age` for projection inputs.

### Calculation Approach
- **D-09:** Runtime profile application — reference docs hold formulas, command instructs AI to substitute profile values (income, children, tax class, marginal rate) at runtime.
- **D-10:** Riester Zulagen calculation: Grundzulage €175 + Kinderzulage (€300 per child born after 2008, €185 before). Command substitutes from profile `children` array.
- **D-11:** Rürup Sonderausgabenabzug: percentage of Höchstbeitrag (2025: 100% of €27,566 single / €55,132 married). Command substitutes from profile income and tax class.
- **D-12:** PGBL 12% threshold: 12% of gross annual income is the max tax-deductible contribution. Command reads `countries.brazil.gross_income` from profile.

### Claude's Discretion
- Pension product comparison presentation format (table, narrative, or decision tree).
- Retirement projection visualization (timeline table, year-by-year breakdown, or summary).
- bAV explanation depth — employer-dependent, so guidance is necessarily generic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Command Patterns
- `commands/finyx/tax.md` — Unified command pattern with country routing. Direct model for `/finyx:pension`.
- `commands/finyx/invest.md` — Recent Phase 3 command. Reference for profile reading and calculation patterns.
- `commands/finyx/profile.md` — Profile interview. May need extension for pension fields.

### Existing Tax Content (Adjacent)
- `finyx/references/germany/tax-investment.md` — German tax reference doc pattern. Follow for pension reference doc structure.
- `finyx/references/brazil/tax-investment.md` — Brazilian tax reference doc pattern.

### Profile & State
- `finyx/templates/profile.json` — Current schema. Needs extension for pension fields (Rentenpunkte, INSS status, retirement age).
- `.planning/STATE.md` — Notes: "INSS expat treatment unresolved" — handled by D-06 (self-reported status + disclaimer).
- `finyx/references/disclaimer.md` — Must be in execution_context.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 2 country routing pattern in `/finyx:tax` — direct reuse for `/finyx:pension`
- Phase 2 `tax_year` frontmatter pattern — reuse for pension reference docs
- Profile gating and disclaimer wiring — established in all Phase 1-3 commands

### Established Patterns
- YAML frontmatter with `name`, `description`, `allowed-tools`
- `<execution_context>` with `@path` references
- Profile gating: `[ -f .finyx/profile.json ]`
- Disclaimer: `@~/.claude/finyx/references/disclaimer.md`
- Runtime calculation: reference doc formulas + command-driven profile substitution

### Integration Points
- `commands/finyx/help.md` — must register `/finyx:pension`
- `finyx/templates/profile.json` — schema extension for pension fields
- New reference docs: `finyx/references/germany/pension.md` and `finyx/references/brazil/pension.md`

</code_context>

<specifics>
## Specific Ideas

- Riester eligibility depends on employment status (unmittelbar förderberechtigt vs mittelbar) — profile already has employment data from Phase 1.
- bAV guidance should be generic since it's employer-dependent — note that employer contribution and Entgeltumwandlung terms vary.
- PGBL vs VGBL decision is almost entirely driven by IR filing type (completa vs simplificada) and whether the 12% threshold is reached.
- Progressive vs regressive IR regime for VGBL/PGBL: regressive favors >10yr hold, progressive favors short-term or lower-income.

</specifics>

<deferred>
## Deferred Ideas

- INSS expat treatment resolution — needs dedicated legal research beyond advisory scope
- Insurance coverage analysis (INSUR-01, INSUR-02) — separate milestone, not Phase 4
- Automated pension contribution optimization — advisory only for now
- German statutory pension (gesetzliche Rente) detailed projection — requires Rentenpunkte history which most users don't have readily available

</deferred>

---

*Phase: 04-pension-planning*
*Context gathered: 2026-04-06*
