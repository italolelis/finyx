# Phase 4: Pension Planning - Research

**Researched:** 2026-04-06
**Domain:** German and Brazilian private pension systems (Riester, Rürup, bAV, PGBL/VGBL) + cross-country retirement projection
**Confidence:** HIGH (DE rules), MEDIUM (BR rules), MEDIUM (cross-country projection mechanics)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Unified `/finyx:pension` command with country routing from profile. Same pattern as `/finyx:tax`.
- **D-02:** PENSION-06 cross-country projection is a late phase in the command, gated on `cross_border: true`.
- **D-03:** Country sections use `## DE` / `## BR` routing blocks inside the prompt.
- **D-04:** Inflation-adjusted timeline, not simple nominal sum. Real rates hardcoded as versioned constants in pension reference doc: DE 1.5% real, BR 2.0% real after IPCA.
- **D-05:** Real rates are user-overridable via profile fields (`expected_real_return_de`, `expected_real_return_br`).
- **D-06:** INSS expat status handled as user self-reported input (active contributor / suspended / totalization treaty eligible). Command does NOT compute INSS entitlements — it prompts user to declare their status.
- **D-07:** Fixed disclaimer on cross-country projection: "Cross-border pension entitlements require verification by a Brazilian social security lawyer (advogado previdenciário)."
- **D-08:** Profile schema extended with `de_rentenpunkte` (optional), `br_inss_status`, `target_retirement_age` for projection inputs.
- **D-09:** Runtime profile application — reference docs hold formulas, command instructs AI to substitute profile values (income, children, tax class, marginal rate) at runtime.
- **D-10:** Riester Zulagen calculation: Grundzulage €175 + Kinderzulage (€300 per child born after 2008, €185 before). Command substitutes from profile `children` array.
- **D-11:** Rürup Sonderausgabenabzug: percentage of Höchstbeitrag (2025: 100% of €27,566 single / €55,132 married). Command substitutes from profile income and tax class.
- **D-12:** PGBL 12% threshold: 12% of gross annual income is the max tax-deductible contribution. Command reads `countries.brazil.gross_income` from profile.

**CRITICAL DISCREPANCY ON D-11:** The Höchstbeitrag locked in D-11 (€27,566 / €55,132) does NOT match the verified 2025 statutory figure. See "Open Questions" section.

### Claude's Discretion

- Pension product comparison presentation format (table, narrative, or decision tree)
- Retirement projection visualization (timeline table, year-by-year breakdown, or summary)
- bAV explanation depth — employer-dependent, so guidance is necessarily generic

### Deferred Ideas (OUT OF SCOPE)

- INSS expat treatment resolution — needs dedicated legal research beyond advisory scope
- Insurance coverage analysis (INSUR-01, INSUR-02) — separate milestone, not Phase 4
- Automated pension contribution optimization — advisory only for now
- German statutory pension (gesetzliche Rente) detailed projection — requires Rentenpunkte history which most users don't have readily available
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PENSION-01 | User receives Riester vs Rürup vs bAV comparison based on employment status, tax bracket, and family | Eligibility rules, Zulagen mechanics, Sonderausgabenabzug, bAV §3 Nr. 63 EStG — all researched |
| PENSION-02 | User receives Riester Zulagen calculation (Grundzulage + Kinderzulage) based on their family data | Grundzulage €175, Kinderzulage €300/>2008 / €185/<2008, Mindestbeitrag 4% of prior-year income — verified |
| PENSION-03 | User receives Rürup Sonderausgabenabzug estimate based on income and marginal rate | 100% deductible in 2025; Höchstbeitrag amount flagged as discrepancy — needs resolution |
| PENSION-04 | User receives PGBL vs VGBL decision guide based on IR regime and 12% income threshold | Decision logic: declaracao completa + INSS/statutory contribution required for PGBL; verified |
| PENSION-05 | User receives progressive vs regressive IR regime explanation with time horizon examples | Regressive 35%→10% (>10yr), Progressive 0%–27.5% salary-equivalent — verified; Law 14.803/24 flexibility noted |
| PENSION-06 | User receives cross-country pension projection combining DE statutory + private + BR INSS | DE Rentenwert 2025: €40.79/point (post Jul 2025); INSS self-reported per D-06; real rate constants per D-04 |
</phase_requirements>

---

## Summary

Phase 4 builds a single `/finyx:pension` command that mirrors the `/finyx:tax` architecture: same profile gate, same country-routing pattern, same `tax_year` frontmatter on reference docs, same disclaimer wiring. The primary new artifacts are two reference docs (`finyx/references/germany/pension.md` and `finyx/references/brazil/pension.md`) and a profile schema extension for pension-specific fields.

The German side (Riester, Rürup, bAV) is well-defined: Zulagen amounts are stable, §3 Nr. 63 EStG bAV limits are verified, Rürup deductibility is 100% since 2023. One discrepancy exists: D-11 hardcodes the Rürup Höchstbeitrag as €27,566 — the verified 2025 statutory figure is €29,344 (single). This must be resolved before the reference doc is written.

The Brazilian side (PGBL/VGBL, progressive vs regressive regime) is straightforward advisory logic driven by IR filing type and contribution horizon. Law 14.803/24 added meaningful flexibility: users can now defer the progressive/regressive choice to withdrawal time, which changes the advisory calculus.

The cross-country projection (PENSION-06) is the most architecturally novel piece. It requires the command to collect three inputs not currently in the profile (`de_rentenpunkte`, `br_inss_status`, `target_retirement_age`), then build an inflation-adjusted projection table using hardcoded real return constants. INSS entitlement computation is explicitly out of scope per D-06; the command only surfaces the status and provides a disclaimer.

**Primary recommendation:** Follow `/finyx:tax` as the direct structural template. The command and reference doc architecture is proven — implement pension as a parallel track, not a new pattern.

---

## Standard Stack

No new libraries or runtime dependencies. This phase is pure Markdown command + reference doc authoring within the established Finyx architecture.

| Asset | Purpose | Pattern Source |
|-------|---------|----------------|
| `commands/finyx/pension.md` | Main command prompt | Mirror of `tax.md` |
| `finyx/references/germany/pension.md` | DE pension formulas + limits | Mirror of `tax-investment.md` frontmatter pattern |
| `finyx/references/brazil/pension.md` | BR pension formulas + IR regime rules | Mirror of `brazil/tax-investment.md` pattern |
| `finyx/templates/profile.json` | Schema extension for pension fields | Add `pension` block per D-08 |
| `commands/finyx/help.md` | Register `/finyx:pension` in workflow diagram | Edit existing |

---

## Architecture Patterns

### Recommended File Structure

```
commands/finyx/
└── pension.md                       # NEW — unified command

finyx/references/
├── germany/
│   └── pension.md                   # NEW — DE pension reference doc
└── brazil/
    └── pension.md                   # NEW — BR pension reference doc

finyx/templates/
└── profile.json                     # EXTEND — add pension block
```

### Pattern 1: Country Routing (from `/finyx:tax`)

Identical to the tax command. Detect active countries from profile, run country sections conditionally, run cross-border section gated on `cross_border: true`.

```markdown
## Phase 1: Validation
[ -f .finyx/profile.json ] || { echo "ERROR: ..."; exit 1; }

## Phase 2: Staleness check (compare tax_year in pension.md frontmatter to date +%Y)

## Phase 3: German Pension (if Germany active)

## Phase 4: Brazilian Pension (if Brazil active)

## Phase 5: Cross-Country Projection (if cross_border == true)

## Phase 6: Disclaimer
```

### Pattern 2: Reference Doc Frontmatter

Identical to `tax-investment.md`:

```yaml
---
tax_year: 2025
country: germany
domain: pension
last_updated: 2026-04-06
source: §10 EStG, §1a BetrAVG, §3 Nr. 63 EStG, ZfA, Deutsche Rentenversicherung
---
```

### Pattern 3: Profile Schema Extension (D-08)

Add a `pension` top-level block to `profile.json`. Keeps pension fields isolated and easily skipped when null.

```json
"pension": {
  "de_rentenpunkte": null,
  "expected_real_return_de": 1.5,
  "br_inss_status": null,
  "expected_real_return_br": 2.0,
  "target_retirement_age": null
}
```

`br_inss_status` is a string enum: `"active"` / `"suspended"` / `"totalization"`.

### Pattern 4: AskUserQuestion for Missing Pension Fields

The pension fields won't exist in older profiles. The command must AskUserQuestion to collect `de_rentenpunkte`, `br_inss_status`, and `target_retirement_age` if null — then offer to save to profile via Write. Same pattern as how `/finyx:tax` collects broker data.

### Anti-Patterns to Avoid

- **Computing INSS entitlement:** Out of scope per D-06. Command asks status, shows disclaimer, stops there.
- **Nominal projection without real rate adjustment:** D-04 mandates inflation-adjusted figures. Raw sum of contributions is insufficient.
- **Hardcoding Rentenwert:** Use profile-collected `de_rentenpunkte` multiplied by current Rentenwert (€40.79/month as of Jul 2025). Flag as needing annual update in the reference doc.
- **Assuming PGBL eligibility without checking IR filing type:** PGBL deduction requires declaracao completa AND an active INSS/statutory pension contribution. Both conditions must be checked.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Inflation-adjusted projection | Custom formula engine | AI runtime calculation with hardcoded real rates from reference doc | No code runtime; AI does math with documented constants |
| INSS entitlement calculation | Custom BR social security calculator | Self-reported status + lawyer disclaimer (D-06) | Entitlement depends on contribution history, treaty terms, and legal interpretation — out of advisory scope |
| Riester product comparison | Product database or web scraping | Generic eligibility + Zulagen calculation; note "compare products at BundesFinanzministerium riester portal" | Product specifics are provider-dependent |
| Tax benefit optimization | Contribution optimizer | Guidance rules: "contribute at least 4% of prior income to get full Riester Grundzulage" | Advisory only, no automated execution |

**Key insight:** This phase is entirely prompt + reference doc work. The AI model does all calculation at runtime with values substituted from the profile. There is no code to write.

---

## German Pension Domain: Verified Facts

### Riester-Rente

**Eligibility (unmittelbar förderberechtigt):**
- Employees paying mandatory GRV (gesetzliche Rentenversicherung) contributions
- Civil servants (Beamte) receiving employer pension contribution
- Recipients of unemployment benefits (ALG I/II)
- Parents in parental leave (Elternzeit)

**NOT eligible for direct Riester (no workaround):**
- Most self-employed / freelancers NOT paying mandatory GRV
- Exception: Handwerker, Lehrer, Hebammen, Künstler — mandatory GRV contributors → eligible

**Mittelbar förderberechtigt (indirect eligibility):**
- Non-working spouse of an unmittelbar person who is also riesting
- Requires the directly-eligible partner to riester and pay minimum contribution (4% of prior-year income)

**Zulagen 2025 (D-10 — VERIFIED):**
| Zulage | Amount |
|--------|--------|
| Grundzulage | €175/year |
| Kinderzulage (born 2008 or later) | €300/child/year |
| Kinderzulage (born before 2008) | €185/child/year |
| Berufseinsteigerbonus (one-time, if under 25) | €200 |

**Minimum contribution for full Zulagen:**
- 4% of prior-year gross income (rentenversicherungspflichtiges Vorjahreseinkommen)
- Absolute minimum: €60/year
- Minimum is NET of Zulagen received: `own_contribution = max(0.04 × prior_income - zulagen, 60)`

**Maximum contribution eligible for Zulagen:**
- €2,100/year (own contributions + Zulagen together)

**Tax advantage check (Sonderausgabenabzug vs Zulagen):**
Finanzamt automatically applies the Günstigerprüfung: whichever is larger — Zulagen or the Sonderausgabenabzug benefit — is used. The Zulagen are offset against any resulting tax benefit.

**Source:** Deutsche Rentenversicherung ZfA, Finanztip (verified 2025). Confidence: HIGH.

---

### Rürup-Rente (Basisrente)

**Eligibility:**
- Any German tax resident — especially valuable for self-employed not eligible for Riester
- Employees can also use Rürup but it duplicates bAV/Riester benefit; typically less optimal for employed

**Sonderausgabenabzug 2025:**
- Deductible percentage: **100%** (since 2023 — vorgezogene 100%, originally planned for 2025)
- Höchstbeitrag (Höchstbetrag zur Basisversorgung): **€29,344 single / €58,688 married**
- Legal basis: §10 Abs. 3 S. 1 EStG — 24.7% × BBG West (€118,800) = €29,344

**CRITICAL: D-11 DISCREPANCY**
D-11 states €27,566 / €55,132. The verified 2025 statutory figure is €29,344 / €58,688. The D-11 figure matches the 2024 value. Reference doc must use the correct 2025 figure. See Open Questions.

**Practical benefit formula:**
```
Tax saving = min(contribution, Höchstbeitrag) × marginal_rate
```

Note: GRV (gesetzliche Rentenversicherung) contributions also count toward the Höchstbeitrag. Employed users receive ~half the Rürup space because their employer's GRV share fills part of the limit.

**Source:** rentenfuchs.info (citing §10 Abs. 3 S. 1 EStG), gn-finanzpartner.de. Confidence: HIGH.

---

### bAV (Betriebliche Altersversorgung)

**Core mechanism:** Entgeltumwandlung — employee redirects gross salary into company pension, reducing social security and income tax base simultaneously.

**Tax-free limit 2025 (§3 Nr. 63 EStG):**
- **8% of BBG West** = 8% × €96,600 = **€7,728/year** (no income tax, no social security)
- Social security-free limit: 4% of BBG = €3,864/year
- Amounts above the 8% threshold are subject to income tax (but not Abgeltungssteuer)

**Mandatory employer contribution (§1a BetrAVG, since 2022):**
- Employer MUST add **15% of the employee's redirected amount** to any bAV via Direktversicherung / Pensionskasse / Pensionsfonds
- Applies when employee does Entgeltumwandlung and employer saves social security contributions as a result

**Advisory framing:**
bAV is employer-contract-dependent. The command cannot tell users what their employer offers. Guidance must be generic:
1. Ask your HR/employer about available bAV vehicles and employer contribution levels
2. Entgeltumwandlung up to 4% BBG is doubly efficient (no income tax + no social security)
3. Reduce gross income → reduces future GRV entitlement (tradeoff to mention)

**Source:** §3 Nr. 63 EStG (bavprofis.de, lohn-info.de), §1a BetrAVG. Confidence: HIGH.

---

### Riester vs Rürup vs bAV Comparison Matrix

| Criterion | Riester | Rürup | bAV |
|-----------|---------|-------|-----|
| Who it's for | Employees with mandatory GRV | Everyone incl. self-employed | Employed only (via employer) |
| Self-employed eligible | Rarely (see above) | Yes, primary vehicle | No |
| Key benefit | Zulagen subsidies; best if many children | Sonderausgabenabzug at marginal rate | Entgeltumwandlung — tax + SV reduction |
| Max annual | €2,100 (own + Zulagen) | €29,344 (2025) less GRV | €7,728 tax-free (8% BBG) |
| Flexibility | Low (locked until retirement, annuity mandatory) | Very low (no lump sum at retirement) | Moderate |
| Child bonus | YES (core advantage) | No | No |
| Sonderausgabenabzug | Yes (Günstigerprüfung) | Yes, explicit | No |

---

## Brazilian Pension Domain: Verified Facts

### PGBL vs VGBL Decision Logic

**PGBL eligibility conditions (BOTH must be true):**
1. Files declaracao completa (modelo completo) — NOT simplificada
2. Has active INSS or statutory pension contribution in the same year

**PGBL deduction rule (D-12 — VERIFIED):**
- Max deductible: 12% of taxable gross annual income
- Applied to: contributions made in calendar year, deducted in DIRPF filing
- Tax base at withdrawal: FULL amount (principal + gains)
- Declaration code: Payments/Donations code 36

**VGBL — when to use instead:**
- User uses declaracao simplificada
- User already maxed 12% PGBL limit
- User is investing purely for gains (not for current-year deduction)
- Tax base at withdrawal: GAINS ONLY

**Source:** Multiple verified sources (riconnect.rico, brasilprev, empiricus). Confidence: HIGH.

---

### Progressive vs Regressive IR Regime (PENSION-05)

**Law 14.803/24 change (IMPORTANT for advisory):**
Since 2024, the regime choice can be deferred to the moment of withdrawal or benefit receipt. Previously it had to be chosen at contract inception. This changes the advisory calculus significantly — users no longer need to guess at withdrawal time horizons upfront.

**Regressive table (by contribution age, not plan age):**
| Accumulation period per tranche | IR Rate |
|--------------------------------|---------|
| Up to 2 years | 35% |
| 2–4 years | 30% |
| 4–6 years | 25% |
| 6–8 years | 20% |
| 8–10 years | 15% |
| Above 10 years | **10%** |

Note: Rate applies per tranche, not per total balance. Older contributions get better rates regardless of when newer contributions were made.

**Progressive table:**
Applies standard IR salary table at withdrawal (0%, 7.5%, 15%, 22.5%, 27.5%). Effective rate depends on total annual withdrawal amount. Favorable for small withdrawals (early retirement, low income).

**Decision guidance:**
- Long horizon (>10 years) + high income → regressive likely wins (10% vs 27.5% top rate)
- Short horizon (<4 years) OR low expected withdrawal income → progressive may win
- Post Law 14.803/24: defer decision until closer to withdrawal; no penalty for waiting

**Source:** XP, investalk BB, crcsp.org.br. Confidence: MEDIUM (multiple sources agree, not official Receita Federal).

---

### INSS Expat Status (D-06 — Self-Reported)

**Brazil-Germany bilateral agreement:** In force since 2013. Totalization of contribution periods is supported — INSS periods + Deutsche Rentenversicherung periods are combined to meet minimum requirements in either system. Each country calculates and pays its proportional benefit independently.

**Minimum for DE benefit:** 5 years of contribution to Deutsche Rentenversicherung (Wartezeit 5 Jahre). Standard retirement age 2025: 66 years 2 months.

**INSS status options (D-06 enum):**
- `"active"` — still contributing to INSS (voluntary or through Brazilian employer)
- `"suspended"` — no current INSS contributions; prior contributions remain in account
- `"totalization"` — intends to use DE-BR agreement to combine contribution periods

**Advisory scope:** Do NOT compute INSS benefit entitlement. Prompt user to declare status, explain what each means for the projection (active = may receive BR benefit independently; suspended = benefit locked until claim; totalization = depends on total combined years), then append D-07 disclaimer.

**Source:** mixvale.com.br (citing DRV and INSS), ssa.gov. Confidence: MEDIUM (agreement confirmed, entitlement math out of scope).

---

### German Statutory Pension (Gesetzliche Rente) — Projection Inputs

**Rentenwert (current):** €40.79/month per Rentenpunkt (Entgeltpunkt) as of July 1, 2025 (increase: +3.74% from €39.32).

**Projection formula (simplified advisory use):**
```
Monthly statutory pension estimate = de_rentenpunkte × current_Rentenwert
```

Profile field `de_rentenpunkte` is optional (deferred per CONTEXT.md). Command uses it if provided; otherwise shows placeholder note.

**Important caveat for reference doc:** Rentenwert changes annually (July 1). Flag as requiring yearly update.

**Source:** Bundesregierung.de, Deutsche Rentenversicherung press release 2025. Confidence: HIGH.

---

## Cross-Country Projection (PENSION-06)

### Required Inputs (from profile + AskUserQuestion)

| Input | Profile Field | Default |
|-------|--------------|---------|
| DE statutory pension (Rentenpunkte) | `pension.de_rentenpunkte` | null — show placeholder |
| DE private pension monthly estimate | AskUserQuestion at runtime | null |
| BR INSS status | `pension.br_inss_status` | null — AskUserQuestion |
| BR INSS monthly benefit estimate | AskUserQuestion (self-reported) | null |
| Target retirement age | `pension.target_retirement_age` | AskUserQuestion |
| Years to retirement | derived from `identity.age` if present | AskUserQuestion fallback |
| DE real return | `pension.expected_real_return_de` | 1.5% |
| BR real return | `pension.expected_real_return_br` | 2.0% |

### Projection Logic (AI executes at runtime)

```
Real accumulated value = current_value × (1 + real_rate)^years_to_retirement

Total monthly retirement income (real terms) =
  DE_statutory_monthly (from Rentenpunkte × Rentenwert)
  + DE_private_monthly (user-provided estimate, inflation-adjusted)
  + BR_INSS_monthly (user self-reported estimate)
  + BR_private_monthly (PGBL/VGBL balance / annuity factor, if user provides)
```

The command does NOT calculate INSS entitlement. It takes user's self-reported monthly estimate.

### Mandatory D-07 Disclaimer (verbatim)

> Cross-border pension entitlements require verification by a Brazilian social security lawyer (advogado previdenciário). This projection is an illustrative estimate only — actual benefits depend on contribution history, treaty application, and regulatory changes in both countries.

---

## Common Pitfalls

### Pitfall 1: Wrong Rürup Höchstbeitrag (D-11 Discrepancy)

**What goes wrong:** Using D-11's €27,566 figure instead of the verified 2025 figure of €29,344.
**Why it happens:** D-11 appears to reference the 2024 Höchstbeitrag. BBG West increased from €90,600 to €96,600 in 2025, which changes the computed limit.
**How to avoid:** Use €29,344 (single) / €58,688 (married) in the reference doc. Flag for annual update.
**Warning signs:** If BBG West changes, the Rürup limit changes proportionally.

### Pitfall 2: Assuming Riester Suits Employed Users Universally

**What goes wrong:** Recommending Riester for any employed user without checking family status and income level.
**Why it happens:** Riester Zulagen are relatively small for high-income users with no children.
**How to avoid:** Calculate actual Zulagen benefit vs Sonderausgabenabzug benefit and compare to bAV Entgeltumwandlung savings. For high earners without children, bAV typically wins.
**Warning signs:** user has `children == 0` and `marginal_rate >= 35%` → Rürup or bAV likely better.

### Pitfall 3: PGBL Without Confirming IR Filing Type

**What goes wrong:** Recommending PGBL to a user who files declaracao simplificada.
**Why it happens:** The simplificada gives a flat 20% deduction — PGBL deduction is only additive for declaracao completa filers.
**How to avoid:** Check `countries.brazil.ir_regime` from profile before making PGBL recommendation.

### Pitfall 4: Ignoring Law 14.803/24 on Regime Choice Deferral

**What goes wrong:** Telling users they must choose progressive vs regressive at inception.
**Why it happens:** Pre-2024 rule required upfront choice.
**How to avoid:** Reference doc must note this law. Advise users they can now defer the decision to withdrawal time.

### Pitfall 5: bAV Social Security Tradeoff Not Mentioned

**What goes wrong:** Recommending maximum Entgeltumwandlung without mentioning reduced GRV entitlement.
**Why it happens:** Lower gross income → lower GRV Entgeltpunkte accumulation per year.
**How to avoid:** Always note the GRV reduction tradeoff in bAV guidance, especially for lower-income employees where GRV replacement rate matters more.

---

## Code Examples

### Profile Extension (pattern from profile.json)

```json
"pension": {
  "de_rentenpunkte": null,
  "expected_real_return_de": 1.5,
  "br_inss_status": null,
  "expected_real_return_br": 2.0,
  "target_retirement_age": null
}
```

### Riester Minimum Own Contribution Calculation

```
prior_year_income = countries.germany.gross_income (proxy if no separate field)
zulagen = 175 + (children_born_after_2008 × 300) + (children_born_before_2008 × 185)
required_total = 0.04 × prior_year_income
own_contribution = max(required_total - zulagen, 60)
```

Note: The command asks the user the birth years of their children if the profile `children` field is a count, not an array with birth years. Children birth year data is needed for correct Kinderzulage.

### Rürup Benefit Estimate

```
taxable_income = countries.germany.gross_income
contribution = user_input (how much they plan to contribute)
höchstbeitrag = 29344  (single) or 58688 (married) — verify annually
gRV_employer_share = estimate_from_income(taxable_income)  # rough: ~7.3% of income up to BBG/2
remaining_rürup_space = höchstbeitrag - gRV_employer_share - gRV_employee_share
deductible = min(contribution, remaining_rürup_space)
tax_saving = deductible × marginal_rate
```

Advisory: show the tax saving in EUR and the net cost after subsidy.

### bAV Entgeltumwandlung Tax Saving

```
redirect_amount = user_input (how much to redirect)
sv_free_limit = 0.04 × 96600 = 3864  (2025, social security free)
tax_free_limit = 0.08 × 96600 = 7728  (2025, income tax free)
tax_saving = min(redirect_amount, tax_free_limit) × marginal_rate
sv_saving = min(redirect_amount, sv_free_limit) × 0.207  # approx combined SV rate
net_cost = redirect_amount - tax_saving - sv_saving
```

### Command staleness check pattern (from tax.md)

```bash
CURRENT_YEAR=$(date +%Y)
echo "Current year: $CURRENT_YEAR"
```
Compare against `tax_year: 2025` in frontmatter. Emit same banner as `/finyx:tax` if mismatch.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-----------------|--------------|--------|
| Rürup 92% deductible | 100% deductible | 2023 (vorgezogen) | Simplifies benefit calculation — no partial percentage |
| Regime choice at inception (PGBL/VGBL) | Deferred choice allowed at withdrawal | Law 14.803/24 (2024) | Advisory changes: no longer urgent upfront decision |
| Sparerpauschbetrag €801 | €1,000 (single) | 2023 | Prior articles/tools still show old limit |
| BBG West €90,600 | €96,600 | 2025 | Rürup Höchstbeitrag, bAV limits all changed |

---

## Environment Availability

Step 2.6: SKIPPED — Phase 4 is pure Markdown command and reference doc authoring. No external tools, CLIs, APIs, or databases are required.

---

## Validation Architecture

> No test framework detected in this project (Markdown-only, zero runtime code). nyquist_validation not explicitly set in config.

The Finyx project has no automated test infrastructure — it is a collection of Claude Code slash commands. Validation is manual-only: install the command via `npx finyx-cc@latest` (or `bin/install.js`) and invoke `/finyx:pension` in a Claude Code session.

### Phase Requirements → Validation Map

| Req ID | Behavior | Test Type | Manual Verification |
|--------|----------|-----------|---------------------|
| PENSION-01 | Riester/Rürup/bAV comparison rendered | Manual | Run `/finyx:pension` with DE profile, verify 3-product comparison |
| PENSION-02 | Riester Zulagen calculation correct | Manual | Profile with 2 children (one >2008, one <2008); verify €175 + €300 + €185 = €660 |
| PENSION-03 | Rürup estimate uses correct Höchstbeitrag | Manual | High-income user; verify €29,344 limit applied |
| PENSION-04 | PGBL/VGBL recommendation driven by IR regime | Manual | Run with `ir_regime: "completa"` then `"simplificada"`; verify different guidance |
| PENSION-05 | Progressive/regressive examples with time horizons | Manual | Verify regressive table rates listed; Law 14.803/24 deferral noted |
| PENSION-06 | Cross-country projection gated on `cross_border: true` | Manual | Run with cross_border false (no projection); run with true (projection appears) |

---

## Open Questions

1. **D-11 Höchstbeitrag Discrepancy**
   - What we know: D-11 says €27,566 / €55,132; verified 2025 statutory is €29,344 / €58,688
   - What's unclear: Whether D-11 was written with 2024 figures, or whether there is a different interpretation of "Höchstbeitrag" being used
   - Recommendation: Use the verified 2025 statutory figure (€29,344 / €58,688) in the reference doc. Note the discrepancy in the PLAN task description so the user can confirm.

2. **Children Birth Year in Profile**
   - What we know: `profile.json` stores `identity.children` as a count (integer), not an array with birth years
   - What's unclear: Whether the Kinderzulage distinction (pre/post 2008) requires profile schema change
   - Recommendation: Add `identity.children_birth_years` array to profile schema, OR use AskUserQuestion to collect birth years at runtime if the count is > 0. AskUserQuestion is lower-friction (no schema change required for existing profiles).

3. **INSS Active Contribution by Brazilians in Germany**
   - What we know: Voluntary INSS contributions are possible from abroad; Brazil-Germany agreement in force since 2013
   - What's unclear: Exact procedure for voluntary INSS contributions from Germany; contribution rates for voluntary contributors
   - Recommendation: Per D-06, do not resolve this. Self-reported status + disclaimer covers advisory scope.

---

## Sources

### Primary (HIGH confidence)
- Deutsche Rentenversicherung (bundesregierung.de Rentenanpassung 2025) — Rentenwert €40.79, +3.74%
- §10 Abs. 3 S. 1 EStG via rentenfuchs.info — Rürup Höchstbeitrag 2025: €29,344 / €58,688
- §3 Nr. 63 EStG via bavprofis.de / lohn-info.de — bAV steuerfreier Betrag 8% BBG = €7,728 (2025)
- §1a BetrAVG via bernhard-assekuranz.com — mandatory 15% employer Zuschuss

### Secondary (MEDIUM confidence)
- riconnect.rico.com.vc + brasilprev.com.br — PGBL 12% deduction rule, declaracao completa requirement
- XP investimentos (conteudos.xpi.com.br) + investalk BB — Regressive table rates verified
- crcsp.org.br — Law 14.803/24 regime choice deferral
- mixvale.com.br — Brazil-Germany bilateral agreement since 2013
- Deutsche Rentenversicherung ZfA (riester.deutsche-rentenversicherung.de) — Riester Grundzulage €175 confirmed
- Finanztip.de — Riester eligibility rules (unmittelbar / mittelbar)

### Tertiary (LOW confidence)
- D-11 Rürup figures (€27,566) — inconsistent with verified 2025 statutory; likely 2024 values

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; established Finyx Markdown architecture
- German pension rules: HIGH — verified against statutory sources (EStG, BetrAVG, BBG 2025)
- Brazilian pension rules: MEDIUM — multiple consistent sources, but not primary Receita Federal
- Cross-country projection: MEDIUM — agreement confirmed, entitlement computation deferred by design
- D-11 figures: LOW — verified discrepancy, needs user confirmation

**Research date:** 2026-04-06
**Valid until:** 2026-12-31 (pension limits change annually; Rürup Höchstbeitrag and bAV limits tied to BBG)
