# Phase 7: Specialist Agents - Research

**Researched:** 2026-04-06
**Domain:** Claude Code agent prompt authoring — Finyx specialist agents
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Output format is structured Markdown wrapped in named XML section tags. Tags: `<allocation_result>`, `<tax_score_result>`, `<projection_result>`. Tables and bullets inside the tags. Orchestrator references tags by name during synthesis.
- **D-02:** Completeness gate lives in the Phase 8 orchestrator only (INFRA-01). Agents assume their profile slice is valid — no per-agent validation logic.
- **D-03:** Field mapping per agent:
  - Allocation: `income`, `expenses`, `goals`
  - Tax-scoring: `countries`, `tax`, `investments`
  - Projection: `assets`, `liabilities`, `goals`
- **D-04:** Agent files: `agents/finyx-allocation-agent.md`, `agents/finyx-tax-scoring-agent.md`, `agents/finyx-projection-agent.md`
- **D-05:** Tool permissions: `Read, Grep, Glob` only. No Write, no WebSearch, no Bash.
- **D-06:** Task colors: allocation = yellow, tax-scoring = magenta, projection = blue.
- **D-07:** Hybrid allocation categories — agent infers from profile field names, presents to user for confirmation, persists mapping, uses stored mapping on subsequent runs. First-run flow: infer → present → confirm → persist.

### Claude's Discretion

- Internal structure of each agent prompt (sections, ordering)
- Exact Markdown table format within XML tags (as long as orchestrator can parse)
- How to persist confirmed allocation mapping (config.json vs profile.json)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ALLOC-01 | User can see income allocation breakdown (needs/wants/savings/investments/debt) vs country-adjusted benchmarks computed on net income | Benchmarks.md §2 adjusted 50/30/20 rule; scoring-rules.md ALLOC-01 DE + BR thresholds; D-07 categorization flow |
| ALLOC-02 | User can see emergency fund status flagged when savings < 3-6 months of expenses | Benchmarks.md §3 emergency fund threshold (6-month cross-border target); scoring-rules.md ALLOC-02 DE + BR gap formulas |
| TAX-01 | User can see Sparerpauschbetrag usage across all brokers with unused EUR amount highlighted | germany/tax-investment.md §3; scoring-rules.md TAX-01 thresholds and gap formula |
| TAX-02 | User can see per-country tax efficiency gaps (DE and BR scored separately) with EUR annual impact | scoring-rules.md entire document; TAX-01, TAX-03, TAX-04 dimensions; never combine DE + BR |
| TAX-03 | User can see Vorabpauschale readiness check for upcoming debit sufficiency | germany/tax-investment.md §5; scoring-rules.md TAX-03 formula; Basiszins 2025 = 2.29%, 2026 = 3.20% |
| PROJ-01 | User can see net worth snapshot (assets vs liabilities summary from profile data) | profile.json `assets`, `liabilities` fields; agent reads from `countries.*.brokers[].holdings` |
| PROJ-02 | User can see goal pace tracking ("at current rate, target X reached in Y months") | profile.json `goals` + `assets`/`liabilities`; savings rate computed from income/expenses slice |

</phase_requirements>

---

## Summary

Phase 7 creates three standalone Claude Code agent `.md` files — no commands, no installer changes. Each agent is a Markdown prompt file with YAML frontmatter (`name`, `description`, `tools`, `color`) and an XML-tagged body (`<role>`, `<execution_context>`, `<process>`, `<output_format>`). Agents are stateless: they read `.finyx/profile.json` and the Phase 6 reference docs, perform domain analysis, and return structured XML-wrapped Markdown.

The existing pattern is established by `agents/finyx-location-scout.md` (YAML frontmatter with tools list) and `agents/finyx-analyzer-agent.md` (role/process/output body structure). The finyx-location-scout is the stronger template — it uses XML section tags and has a `<return_format>` block, which maps directly to what Phase 8 needs.

The critical implementation detail: profile.json as written by `/finyx:profile` does not contain explicit `income`, `expenses`, `assets`, `liabilities`, or `investments` sections — it stores data inside `investor.*`, `countries.*`, `goals`, `pension`. Each agent must map those fields explicitly. ALLOC agent must also handle the D-07 first-run categorization flow (infer → confirm → persist) which requires clarifying how persisted mappings are stored.

**Primary recommendation:** Model all three agents on the `finyx-location-scout.md` template (YAML frontmatter + XML section structure) rather than the `finyx-analyzer-agent.md` template (prose-only, no frontmatter).

---

## Standard Stack

No libraries. This phase produces Markdown files only.

### Core
| File | Type | Purpose |
|------|------|---------|
| `agents/finyx-allocation-agent.md` | Agent prompt | ALLOC-01, ALLOC-02 |
| `agents/finyx-tax-scoring-agent.md` | Agent prompt | TAX-01, TAX-02, TAX-03 |
| `agents/finyx-projection-agent.md` | Agent prompt | PROJ-01, PROJ-02 |

### Reference Docs Loaded at Runtime (via @path in `<execution_context>`)
| Reference | Used By | Purpose |
|-----------|---------|---------|
| `@~/.claude/finyx/references/insights/benchmarks.md` | allocation, tax-scoring | Net income denominators, 50/30/20 ranges, emergency fund target, investment rate targets |
| `@~/.claude/finyx/references/insights/scoring-rules.md` | allocation, tax-scoring | Traffic-light thresholds, gap formulas, confidence flags |
| `@~/.claude/finyx/references/germany/tax-investment.md` | tax-scoring | Sparerpauschbetrag §3, Vorabpauschale §5, Abgeltungssteuer rates |
| `@~/.claude/finyx/references/brazil/tax-investment.md` | tax-scoring | DARF §2, PGBL §1, IR rates §1 |
| `@~/.claude/finyx/references/disclaimer.md` | all three | Legal disclaimer appended to all output |

**Installation:** No install step. `bin/install.js` recursively copies the `agents/` directory — new files are picked up automatically.

---

## Architecture Patterns

### Recommended File Structure
```
agents/
├── finyx-allocation-agent.md      # new — Phase 7
├── finyx-tax-scoring-agent.md     # new — Phase 7
├── finyx-projection-agent.md      # new — Phase 7
├── finyx-analyzer-agent.md        # existing
├── finyx-location-scout.md        # existing — template to follow
└── finyx-reporter-agent.md        # existing
```

### Pattern 1: Agent YAML Frontmatter (from finyx-location-scout.md)

```yaml
---
name: finyx-allocation-agent
description: Analyzes income allocation vs benchmarks and emergency fund status. Spawned by /fin:insights.
tools: Read, Grep, Glob
color: yellow
---
```

**Rules:**
- `name` matches the filename stem
- `tools` is an explicit allowlist — never `*`
- `color` is locked by D-06: yellow / magenta / blue
- `description` names the spawning command

### Pattern 2: Agent Body XML Structure (from finyx-location-scout.md)

```markdown
<role>
[Who the agent is, what it does, who spawns it]
</role>

<execution_context>
@~/.claude/finyx/references/insights/benchmarks.md
@~/.claude/finyx/references/insights/scoring-rules.md
[additional refs as needed]
</execution_context>

<process>
## Phase 1: Read Profile
[numbered steps]
## Phase 2: Compute Metrics
[numbered steps with formulas]
## Phase 3: Apply Thresholds
[numbered steps]
</process>

<output_format>
[XML-wrapped output structure the orchestrator consumes]
</output_format>
```

### Pattern 3: Agent Output XML Wrapper (D-01)

Each agent wraps its entire result in a named XML tag:

```markdown
<allocation_result>
## Allocation Analysis

### Income Breakdown
| Category | Amount | % of Net | Benchmark | Status |
|----------|--------|----------|-----------|--------|
| Needs    | €X,XXX | 48%      | 40-55%    | [GREEN] |
...

### Emergency Fund
[YELLOW] Emergency Fund (DE): 4.2 months covered — target 6 months
  Gap: €7,800 to reach 6-month target
  How to close: Build €7,800 liquid savings in Tagesgeld

*Confidence: [HIGH CONFIDENCE]*
</allocation_result>
```

### Pattern 4: Traffic-Light Format (from scoring-rules.md §Scoring Output Format)

Per the canonical template in `scoring-rules.md`:

```
[TRAFFIC_LIGHT] [DIMENSION_LABEL]: [STATUS_PHRASE]
  Gap: [EUR X or R$X] [per year / per month] [action verb]
  How to close: [one-line action]
```

Traffic light: `[GREEN]`, `[YELLOW]`, `[RED]`. Append confidence flag on separate line.

### Pattern 5: Profile Field Mapping Per Agent

Profile.json as written does not have explicit `income`, `expenses`, `assets`, `liabilities` sections. Agents must map:

**Allocation agent reads:**
- `investor.income.total` — gross income (Germany path)
- `countries.germany.gross_income` / `countries.brazil.gross_income` — per-country gross
- `countries.germany.marginal_rate` / `investor.marginalRate` — for net-after-mandatory calc
- `investor.liquidAssets` — emergency fund check
- `investor.monthlyCommitments` — monthly expenses proxy
- `goals.primary_goals` — goals context
- `investor.children`, `identity.family_status` — for social contributions calc

**Tax-scoring agent reads:**
- `countries.germany.tax_class`, `countries.germany.church_tax` — Abgeltungssteuer rate
- `countries.germany.brokers[].freistellungsauftrag` — Sparerpauschbetrag used (field may not yet exist)
- `countries.germany.brokers[].holdings` — fund values for Vorabpauschale
- `countries.brazil.ir_regime` — declaracao type (affects TAX-04 PGBL scoring)
- `countries.brazil.brokers[].darf_records` — DARF compliance check
- `identity.cross_border` — whether to score both countries

**Projection agent reads:**
- `investor.liquidAssets` — liquid asset component of net worth
- `countries.germany.brokers[].holdings` — investment portfolio value
- `countries.brazil.brokers[].holdings` — BRL portfolio value
- `investor.monthlyCommitments` — monthly outflows (debt obligations proxy)
- `goals.primary_goals`, `goals.investment_horizon` — goal definitions
- `pension.de_rentenpunkte`, `pension.br_inss_status` — pension snapshot

### Pattern 6: D-07 Allocation Categorization Flow

First-run:
1. Agent reads `investor.monthlyCommitments` and `goals.primary_goals` as initial signal
2. Agent infers category mapping from known Finyx category taxonomy (Needs/Wants/Savings/Investments/Debt)
3. Agent presents inferred mapping to user and asks for confirmation
4. Upon confirmation, agent instructs the orchestrating command to persist the mapping to `.finyx/config.json` under an `allocation_mapping` key

**Persist to `.finyx/config.json`** (not `profile.json`) — config.json is the right place for derived operational preferences; profile.json is the raw interview data. The allocation_mapping is a user preference, not a financial fact.

Subsequent runs: Agent reads `allocation_mapping` from `.finyx/config.json` if present; skips infer/confirm flow.

### Anti-Patterns to Avoid

- **No Bash tool in agents:** D-05 locks tools to Read, Grep, Glob. No shell commands.
- **No Write tool in agents:** Agents never write state (established project pattern). Writing confirmed allocation mapping must be delegated back to the Phase 8 orchestrator command — the agent can return the suggested mapping in its structured output, and the orchestrator writes it.
- **Never combine DE + BR scores:** Per STATE.md decision and scoring-rules.md. Score each country independently; never aggregate.
- **Never invent fields:** If a profile field required for a dimension is absent, output `[MEDIUM CONFIDENCE]` or `[LOW CONFIDENCE]` and state what field is missing. Do not assume a value.
- **No validation logic in agents (D-02):** If a required profile section is entirely absent, skip the dimension and output a clear data-gap note. The completeness gate lives in Phase 8.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Net-after-mandatory calc | Custom tax table logic | Use benchmarks.md §1 gross-to-net conversion formulas and reference to `marginal_rate` from profile |
| Traffic-light thresholds | Hardcoded if/else in prompt | Reference scoring-rules.md which has all thresholds per dimension per country |
| Gap formulas | Re-derive from scratch | Copy verbatim from scoring-rules.md gap formula blocks — they are already computed and doc-linked |
| Sparerpauschbetrag limit | Hardcode 1000/2000 | Reference germany/tax-investment.md §3 — sourced from EStG |
| Vorabpauschale formula | Re-derive | Reference scoring-rules.md TAX-03 formula block which uses germany/tax-investment.md §5 |

**Key insight:** All scoring logic is encoded in the Phase 6 reference docs. The agents are conduits — they read profile data, apply the reference doc logic, and format output. Do not replicate formulas in the agent prompt itself; reference the doc sections explicitly.

---

## Common Pitfalls

### Pitfall 1: Profile Schema Has No "expenses" Field
**What goes wrong:** Agent references `profile.expenses` which does not exist — produces an empty or hallucinated result.
**Why it happens:** D-03 maps "Allocation: income/expenses/goals" but profile.json stores this data as `investor.monthlyCommitments` (single monthly total) not an itemized expenses object.
**How to avoid:** Agent must explicitly map `investor.monthlyCommitments` as the monthly expenses proxy. Note in the agent prompt that this is the expenses proxy field — do not reference a non-existent `expenses` section.
**Warning signs:** Agent outputs "0" or "N/A" for the Needs category when user has commitments.

### Pitfall 2: Sparerpauschbetrag — Freistellungsauftrag Field May Not Exist Yet
**What goes wrong:** Tax-scoring agent tries to read `countries.germany.brokers[].freistellungsauftrag` to compute used allowance, but this field is not in the current profile schema.
**Why it happens:** Profile template (`finyx/templates/profile.json`) shows broker objects as `[]` (empty array). No `freistellungsauftrag` field was defined in the profile phase.
**How to avoid:** Agent must handle missing Freistellungsauftrag data gracefully — default to `[MEDIUM CONFIDENCE]` with a note "Freistellungsauftrag amounts not recorded in profile — run /finyx:broker to add". The sum can be shown as "unknown" rather than 0.
**Warning signs:** Agent reports all Sparerpauschbetrag as unused when user likely has orders set.

### Pitfall 3: Vorabpauschale — Fund Values Require holdings[] Data
**What goes wrong:** TAX-03 check requires fund value on Jan 1 and the Basiszins, but holdings[] in profile only has `shares` and `cost_basis`, not current NAV.
**Why it happens:** Profile stores acquisition cost, not current market value. NAV requires a live lookup (WebSearch) which is forbidden (D-05).
**How to avoid:** Use `shares × cost_basis` as a conservative floor for fund value, flag as `[MEDIUM CONFIDENCE]`. State in agent prompt: "Use cost_basis × shares as fund value estimate — actual NAV may differ. Flag as MEDIUM CONFIDENCE."
**Warning signs:** Agent tries to use WebSearch or Bash to fetch prices — both are blocked.

### Pitfall 4: D-07 Persist Step — Agent Cannot Write
**What goes wrong:** D-07 says "persist confirmed allocation mapping" but agents have no Write tool (D-05). If the agent tries to write `.finyx/config.json` it will fail.
**Why it happens:** The persist step is inherently a write operation, but the write-state pattern is orchestrator-only.
**How to avoid:** Agent includes the confirmed mapping in its `<allocation_result>` output under a `<allocation_mapping_confirmed>` sub-tag. Phase 8 orchestrator reads this tag and writes it to `.finyx/config.json`. The agent prompt must clearly say "return the confirmed mapping in your output — the orchestrating command will persist it."
**Warning signs:** Agent hallucinates a Write call or leaves the mapping in an unstructured format that the orchestrator cannot parse.

### Pitfall 5: Brazil Scoring Conditional on ir_regime
**What goes wrong:** TAX-04 (PGBL scoring) is applied to all BR users, including those on `declaracao: simplificada` who cannot benefit from PGBL deductions.
**Why it happens:** Agents apply all scoring rules without checking the declaracao type.
**How to avoid:** Tax-scoring agent must gate TAX-04 on `countries.brazil.ir_regime == "completo"`. If simplificada, skip TAX-04 entirely and output "PGBL scoring not applicable (declaracao simplificada)."
**Warning signs:** User on simplificada sees a [RED] PGBL score — this is incorrect and potentially harmful advice.

### Pitfall 6: Cross-Border Check Before Scoring Brazil
**What goes wrong:** Agent always attempts to score both DE and BR dimensions even when user has no Brazil income.
**Why it happens:** Template-style agent prompts don't conditionally omit sections.
**How to avoid:** Gate Brazil scoring on `identity.cross_border == true` OR `"Brazil" in identity.income_countries`. If Brazil is not in scope, explicitly output "Brazil: not applicable (no Brazil income in profile)."

---

## Code Examples

Verified patterns from canonical project files:

### Agent YAML Frontmatter (from finyx-location-scout.md)
```yaml
---
name: finyx-allocation-agent
description: Analyzes income allocation vs country benchmarks and emergency fund status. Spawned by /fin:insights.
tools: Read, Grep, Glob
color: yellow
---
```

### execution_context Block (pattern from finyx-location-scout.md)
```markdown
<execution_context>
@~/.claude/finyx/references/insights/benchmarks.md
@~/.claude/finyx/references/insights/scoring-rules.md
@~/.claude/finyx/references/disclaimer.md
</execution_context>
```

### Output Tag Pattern (D-01, from CONTEXT.md)
```markdown
<allocation_result>

## Allocation Analysis — [residence_country]

### Income Breakdown
| Category | Monthly | % of Net-After-Mandatory | Benchmark | Status |
|----------|---------|--------------------------|-----------|--------|
| Needs    | €X,XXX  | 47%                      | 40-55%    | [GREEN] |
| Wants    | €XXX    | 18%                      | 15-25%    | [GREEN] |
| Savings + Investments | €X,XXX | 28% | 20-30% | [GREEN] |
| Debt     | €XXX    | 7%                       | 0-15%     | [GREEN] |

### Emergency Fund
[GREEN] Emergency Fund (DE): 8.4 months covered — above 6-month target
  Gap: None
  How to close: N/A — maintain current buffer

*Confidence: [HIGH CONFIDENCE]*

</allocation_result>
```

### Traffic-Light Dimension Block (from scoring-rules.md §Scoring Output Format)
```
[YELLOW] Sparerpauschbetrag: EUR 263/year unused
  Gap: EUR 263 in unrealized tax savings (EUR 263 x 26.375% = EUR 69/year tax cost)
  How to close: Allocate EUR 263 additional Freistellungsauftrag to an active broker
```

### Allocation Mapping Persist Tag (D-07, for orchestrator consumption)
```markdown
<allocation_mapping_confirmed>
needs: [rent, utilities, groceries, insurance, transport]
wants: [dining, subscriptions, entertainment, travel]
savings: [savings_accounts, tagesgeld]
investments: [broker_accounts, etfs, pension]
debt: [mortgage, personal_loans]
</allocation_mapping_confirmed>
```

---

## Profile Schema: Actual Available Fields

The profile.json written by `/finyx:profile` contains these relevant fields. Agents must map to these — not to hypothetical sections:

```
identity.residence_country          → country gate for DE/BR scoring
identity.cross_border               → whether to score both jurisdictions
identity.family_status              → married/single for Sparerpauschbetrag limit
identity.children                   → Pflegeversicherung surcharge
countries.germany.tax_class         → I / III / IV
countries.germany.church_tax        → boolean → affects Abgeltungssteuer rate
countries.germany.gross_income      → EUR
countries.germany.marginal_rate     → effective marginal rate
countries.germany.brokers[]         → array; each may have holdings[]
countries.brazil.ir_regime          → "simplificado" | "completo" → gates TAX-04
countries.brazil.gross_income       → BRL
countries.brazil.brokers[]          → array; each may have holdings[]
goals.risk_tolerance
goals.investment_horizon
goals.primary_goals[]
pension.de_rentenpunkte
pension.br_inss_status
pension.target_retirement_age
investor.liquidAssets               → EUR — emergency fund + liquid assets
investor.monthlyCommitments         → EUR — proxy for monthly expenses
investor.marginalRate               → marginal rate (mirrors countries.germany.marginal_rate)
```

**Fields NOT present in profile.json** (must handle gracefully):
- `expenses` object — use `investor.monthlyCommitments` as proxy
- `assets` / `liabilities` object — assets are `investor.liquidAssets` + holdings; liabilities are `investor.monthlyCommitments × horizon` or absent
- `freistellungsauftrag` per broker — may be absent; default to MEDIUM CONFIDENCE

---

## Environment Availability

Step 2.6: SKIPPED — phase is Markdown file creation only, no external tool dependencies.

---

## Open Questions

1. **Freistellungsauftrag field in profile**
   - What we know: `countries.germany.brokers[]` schema has no `freistellungsauftrag` field in current template.
   - What's unclear: Was this field added by any broker-related command (e.g., `/finyx:broker`)? Or should TAX-01 always be MEDIUM CONFIDENCE due to missing data?
   - Recommendation: Tax-scoring agent should note "Add Freistellungsauftrag amounts via `/finyx:broker`" and output MEDIUM CONFIDENCE. Plan can include a profile schema note but not a schema change (out of scope for this phase).

2. **Allocation mapping persistence target**
   - What we know: D-07 says persist to `.finyx/config.json` or `profile.json`; CONTEXT.md says "Claude's discretion."
   - Recommendation: Persist to `.finyx/config.json` under `allocation_mapping` key. Config.json is for derived operational preferences; profile.json is raw interview data.

3. **Net worth assets/liabilities — profile schema gap**
   - What we know: PROJ-01 requires "assets vs liabilities summary from profile data" but profile has no explicit assets or liabilities sections.
   - What's unclear: Does "assets" mean `liquidAssets` only, or `liquidAssets + portfolio value from holdings`?
   - Recommendation: Projection agent should sum `investor.liquidAssets` + all `holdings[].shares × cost_basis` across all brokers as total assets, and treat `investor.monthlyCommitments` as a monthly obligation proxy for liabilities (not a balance sheet liability). Make assumptions explicit in the output.

---

## Sources

### Primary (HIGH confidence)
- `agents/finyx-location-scout.md` — canonical agent frontmatter + XML section structure
- `agents/finyx-analyzer-agent.md` — canonical agent process/output body
- `finyx/references/insights/benchmarks.md` — allocation benchmarks, net income denominators, emergency fund threshold
- `finyx/references/insights/scoring-rules.md` — traffic-light thresholds, gap formulas, output format template
- `finyx/references/germany/tax-investment.md` — Sparerpauschbetrag §3, Vorabpauschale §5, Abgeltungssteuer rates §2
- `finyx/references/brazil/tax-investment.md` — DARF §2, PGBL §1, FII exemption §4
- `finyx/templates/profile.json` — actual profile schema written by /finyx:profile
- `commands/finyx/profile.md` — profile interview fields, confirms what profile.json contains at runtime
- `.planning/phases/07-specialist-agents/07-CONTEXT.md` — all locked decisions
- `.planning/REQUIREMENTS.md` — ALLOC-01/02, TAX-01/02/03, PROJ-01/02 definitions
- `.planning/STATE.md` — accumulated v1.1 decisions (per-country scoring, projection precision)

### Secondary (MEDIUM confidence)
- `.planning/config.json` — `nyquist_validation: false` confirmed, `commit_docs: true`

---

## Metadata

**Confidence breakdown:**
- Agent file structure: HIGH — based on existing finyx-location-scout.md pattern, directly verifiable
- Profile field mapping: HIGH — based on profile.md process + templates/profile.json
- Scoring logic: HIGH — based on Phase 6 reference docs already committed
- Pitfalls (D-07 persist, missing schema fields): MEDIUM — inferred from schema inspection, no execution to verify

**Research date:** 2026-04-06
**Valid until:** Until profile.json schema changes or Phase 6 reference docs are updated
