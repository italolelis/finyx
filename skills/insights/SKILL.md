---
name: finyx-insights
description: Financial insights dashboard — portfolio scoring, asset allocation analysis, wealth projection, and cross-domain benchmarking for DE/BR investors with ranked top-5 recommendations. Use when the user asks about their financial health, overall finances, how they're doing financially, asset allocation, or wants a financial overview.
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
disable-model-invocation: true
---

<objective>

Generate a unified financial health report by orchestrating three specialist agents in parallel and synthesizing their outputs.

This skill:
1. Validates profile completeness — on incomplete profile, emits a report listing missing sections and stops without spawning agents
2. Emits the legal disclaimer BEFORE any advisory content
3. Spawns all three specialist agents in parallel: allocation analyst, tax efficiency scorer, projections analyst
4. Persists the confirmed allocation mapping to `.finyx/insights-config.json` on first run
5. Synthesizes a unified report with: Summary, Health Dashboard, Top-5 Recommendations, and Detail sections
6. Surfaces cross-advisor intelligence — patterns that span multiple domains (tax + allocation + projection)
7. Ranks all recommendations by estimated annual EUR impact

This skill writes ONLY to `.finyx/insights-config.json` (allocation mapping persistence) — it never modifies `.finyx/profile.json`.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
@.finyx/profile.json
<!-- Project-local fast-path. Authoritative profile path is resolved at runtime via scripts/resolve-profile.sh. See scripts/README.md. -->

</execution_context>

<process>

## Phase 1: Validation and Completeness Gate

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

**Read `$PROFILE_PATH`** (the @-include is a project-local fast-path; `$PROFILE_PATH` from the gate check is authoritative) and check required fields per agent.

**Check for existing allocation mapping:**
```bash
[ -f .finyx/insights-config.json ] && echo "INSIGHTS_CONFIG_EXISTS=true" || echo "INSIGHTS_CONFIG_EXISTS=false"
```

**Required fields — Allocation agent:**
- `investor.income.total` OR `countries.germany.gross_income` (at least one must be > 0)
- `investor.monthlyCommitments` (must be > 0)
- `investor.liquidAssets` (must be present, 0 is valid)

**Required fields — Tax scoring agent:**
- `countries.germany.gross_income > 0` OR (`identity.cross_border == true` AND `countries.brazil.gross_income > 0`)
- `countries.germany.tax_class` (required when Germany income > 0)
- `countries.brazil.ir_regime` (required only when `identity.cross_border == true` AND `countries.brazil.gross_income > 0`)

**Required fields — Projection agent:**
- `investor.liquidAssets` (must be present)
- `investor.monthlyCommitments` (must be > 0)
- `investor.income.total` OR `countries.germany.gross_income` (at least one must be > 0)

**Optional fields — Insurance integration:**
- `insurance.policies[]` — if array is non-empty, compute total monthly premium by summing `policies[].premium_monthly` across all entries. Include as "Insurance" needs line item with label "Insurance (X policies)" and monthly total. If array is empty or absent: skip silently (no error, no warning).
- **Gap action items:** Compare the `type` values present in `policies[]` against the essential types list (haftpflicht, hausrat, health). Any essential type NOT represented in policies[] is surfaced as a recommendation action item: "Missing: [type1], [type2]". This is a simple set-difference check — it does NOT require spawning the portfolio agent.

**Cross-border gate:** When checking Brazil fields, only require `countries.brazil.ir_regime` and `countries.brazil.gross_income` if BOTH `identity.cross_border == true` AND `countries.brazil.gross_income > 0`. Do NOT require Brazil fields if `identity.cross_border == false` or if Brazil income is zero or absent.

**If ANY required field is missing, null, or zero (beyond the cross-border gate above):**

Emit the completeness report and STOP — do NOT spawn agents:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSIGHTS: PROFILE INCOMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following profile sections must be completed before running /finyx:insights:

[ ] [field_name]: [description of what is missing and why it is required]
...

Run /finyx:profile to complete your profile.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

List each missing field with a human-readable description. For example:
- `investor.monthlyCommitments`: Monthly expense commitment amount — required for allocation and projection analysis
- `countries.germany.gross_income`: German gross annual income — required for tax scoring and allocation analysis
- `countries.germany.tax_class`: German Steuerklasse (I–VI) — required for tax dimension scoring

If the completeness check passes, proceed to Phase 2.

## Phase 2: Legal Disclaimer

Emit the main header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSIGHTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

IMMEDIATELY emit the full legal disclaimer from loaded `disclaimer.md` BEFORE any financial data or advisory content:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

The disclaimer must precede all financial content — allocation, tax, projections, and recommendations all appear after this block.

## Phase 3: Agent Spawning

Spawn ALL three agents in PARALLEL via the Task tool. Do not wait for one to complete before spawning the next — initiate all three simultaneously.

**Check insights-config.json for existing allocation mapping:**
If `.finyx/insights-config.json` exists and contains an `allocation_mapping` key, include the stored mapping in the allocation agent prompt so it skips the first-run AskUserQuestion confirmation flow.

**Task 1 — Allocation Agent:**
Spawn `finyx-allocation-agent` with this prompt structure:

```
You are the finyx-allocation-agent. Analyze the user's income allocation, savings rate, and emergency fund status.

Profile data is at `.finyx/profile.json`. Reference docs are at ${CLAUDE_SKILL_DIR}/references/insights/.

[If .finyx/insights-config.json exists with allocation_mapping:]
An existing allocation mapping is already confirmed and stored in `.finyx/insights-config.json` under the `allocation_mapping` key. Read it and use it directly — skip the Phase 2 first-run confirmation flow and do NOT use AskUserQuestion.

If `.finyx/profile.json` contains a non-empty `insurance.policies[]` array:
- Sum all `policies[].premium_monthly` values to compute total monthly insurance cost
- Include as a "needs" category line item labeled "Insurance ([N] policies — EUR [total]/month)" where N = count of policies and total = computed sum
- If any policy has premium_monthly of 0 or null, note "[DATA GAP: premium_monthly missing for [policy.id]]" inline
- Compare policies[].type values against essential types (haftpflicht, hausrat, health). For each essential type NOT in policies[]: add to recommendation: "Missing insurance: [type] — run /finyx:insurance for details"
- Do NOT reference insurance.type or insurance.monthly_cost — those fields do not exist in the schema
- If insurance.policies[] is absent or empty: skip — do not include any insurance line in allocation

Complete all phases of your process and return your output wrapped in <allocation_result> tags.
```

**Task 2 — Tax Scoring Agent:**
Spawn `finyx-tax-scoring-agent` with this prompt structure:

```
You are the finyx-tax-scoring-agent. Score the user's tax efficiency across Germany and Brazil.

Profile data is at `.finyx/profile.json`. Reference docs are at ${CLAUDE_SKILL_DIR}/references/.

Complete all phases of your process and return your output wrapped in <tax_score_result> tags.
```

**Task 3 — Projection Agent:**
Spawn `finyx-projection-agent` with this prompt structure:

```
You are the finyx-projection-agent. Compute a net worth snapshot, savings rate, and goal pace projections.

Profile data is at `.finyx/profile.json`. Reference docs are at ${CLAUDE_SKILL_DIR}/references/insights/.

Complete all phases of your process and return your output wrapped in <projection_result> tags.
```

Collect the three XML-tagged outputs:
- `<allocation_result>` from Task 1
- `<tax_score_result>` from Task 2
- `<projection_result>` from Task 3

Each output contains traffic-light scores, gap amounts in EUR/BRL, and "How to close" actions. Parse these for Phase 5.

## Phase 4: Allocation Mapping Persistence

After collecting agent outputs, check whether `<allocation_result>` contains an `<allocation_mapping_confirmed>` block.

**If `<allocation_mapping_confirmed>` is present (first-run scenario):**
1. Extract the mapping JSON from inside the `<allocation_mapping_confirmed>` block
2. Ensure the `.finyx/` directory exists:
```bash
[ -d .finyx ] || mkdir -p .finyx
```
3. Write the confirmed mapping to `.finyx/insights-config.json` using the Write tool:
```json
{
  "allocation_mapping": {
    "needs": [...],
    "wants": [...],
    "savings": [...],
    "investments": [...],
    "debt": [...]
  }
}
```

**If no `<allocation_mapping_confirmed>` block is present:** The mapping was already persisted on a prior run. Skip — do NOT modify `.finyx/insights-config.json`.

**IMPORTANT:** Never write allocation_mapping to `.finyx/profile.json`. The target is exclusively `.finyx/insights-config.json`.

## Phase 5: Report Synthesis

Assemble the unified report from the three agent outputs. Follow the section order exactly: Summary → Health Dashboard → Recommendations → Detail.

### Section 1 — Summary

Extract from `<projection_result>`:
- Net worth snapshot: total assets, monthly obligations, estimated net worth (conservative/base ranges)
- Savings rate: current % vs target

Extract from `<allocation_result>`:
- Income allocation overview: current split across needs/wants/savings/investments/debt

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Estimated Net Worth:** EUR XX,000–EUR XX,000
**Savings Rate:** XX% of net-after-mandatory income (target: 20–25%)
**Monthly Obligations:** EUR X,XXX/month
**Allocation Overview:** XX% Needs | XX% Wants | XX% Savings+Investments | XX% Debt
```

### Section 2 — Health Dashboard

Emit a SINGLE unified traffic-light table with a Country column. Do NOT use separate per-country blocks. Populate directly from agent output traffic-light tokens ([GREEN], [YELLOW], [RED]).

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 HEALTH DASHBOARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Dimension | Country | Status | Gap | How to Close |
|-----------|---------|--------|-----|--------------|
| Investment Rate | DE | [COLOR] | EUR X,XXX/year | [one-line action] |
| Emergency Fund | DE | [COLOR] | EUR X,XXX | [one-line action] |
| Sparerpauschbetrag | DE | [COLOR] | EUR X/year | [one-line action] |
| Vorabpauschale Readiness | DE | [COLOR] | EUR X | [one-line action] |
| PGBL Optimization | BR | [COLOR] | R$X/year | [one-line action] |
| Emergency Fund | BR | [COLOR] | R$X | [one-line action] |
```

Read the Status, Gap, and How to Close values directly from the `<allocation_result>` and `<tax_score_result>` agent outputs. Do NOT re-derive them. If a dimension is not applicable for the user (e.g., Brazil scoring not applicable), omit that row or mark it "N/A — [reason]".

### Section 3 — Top-5 Recommendations

<cross_advisor_links>
Before ranking recommendations, scan the collected agent outputs for these cross-advisor patterns. Each pattern that fires adds an additional recommendation (or augments an existing one) with a cross-domain note.

**Pattern CAL-01: Double Gap — Unused Sparerpauschbetrag + Low Investment Rate**
- Trigger: TAX-01 is [YELLOW] or [RED] AND ALLOC-01 investment rate is [RED]
- Insight: The user is both under-investing and failing to shield available investment income from tax. Fixing the investment rate gap would generate income that the still-unused allowance could protect.
- Recommendation: "Increase monthly ETF contribution to both raise investment rate and utilize unused Freistellungsauftrag — double compounding benefit"
- Estimated impact: EUR gap from TAX-01 + portion of ALLOC-01 investment rate gap

**Pattern CAL-02: Missed Rürup Deduction — High Marginal Rate + No Pension**
- Trigger: `countries.germany.marginal_rate > 42` AND no pension contribution evidence in profile
- Insight: At marginal rates above 42%, Rürup contributions are among the most tax-efficient savings vehicles available in Germany.
- Recommendation: "Start Rürup pension contributions — at your marginal rate, each EUR 1,000 contributed saves EUR X in income tax this year"
- Estimated impact: EUR 0.42–0.48 per EUR 1 contributed (marginal rate × contribution amount)

**Pattern CAL-03: Over-Allocated Risk — Emergency Fund Shortfall + High Investment Rate**
- Trigger: ALLOC-02 Emergency Fund is [RED] AND investment allocation is [GREEN] or above target
- Insight: Investing above target while emergency fund is critically low creates sequence-of-returns risk — a sudden expense forces selling investments at potentially adverse prices.
- Recommendation: "Pause investment over-allocation temporarily and redirect to Tagesgeld until emergency fund reaches 3-month minimum"
- Estimated impact: Risk reduction — no direct EUR impact, but avoids forced sale loss (model as EUR X,XXX portfolio protection)

**Pattern CAL-04: Missed PGBL Deduction — PGBL Not Used + Completo Regime**
- Trigger: TAX-04 is [RED] AND `countries.brazil.ir_regime == "completo"`
- Insight: PGBL contributions up to 12% of gross Brazilian income are fully deductible under declaração completa — every R$1 contributed at a marginal rate of 27.5% saves R$0.275 in tax.
- Recommendation: "Start PGBL contributions to utilize the 12% gross income deduction — reduce annual BR income tax by R$X"
- Estimated impact: `pgbl_gap_brl × brazil_marginal_rate` (convert to EUR using stated BRL/EUR assumption)

**Pattern CAL-05: High Insurance Cost — PKV Premium Drag on Savings Rate**
- Trigger: A `health` type policy exists in `insurance.policies[]` with `premium_monthly > 400` AND savings rate is below 20%
- Insight: High PKV premiums reduce disposable income available for savings and investments. The user may benefit from reviewing PKV tariff optimization (Tarifwechsel §204 VVG) or considering GKV return if still eligible.
- Recommendation: "Review PKV tariff options via /finyx:insurance — Tarifwechsel within same insurer can reduce premiums without losing Altersrückstellungen"
- Estimated impact: Potential monthly saving from tariff optimization (varies, typically €50–200/month = €600–2,400/year)

**Additional cross-advisor patterns:** Claude may identify and surface novel cross-advisor links beyond these four examples if strong signal is present in the agent outputs. Any additional patterns must include: trigger condition, insight, one-line recommendation, estimated EUR/BRL impact.
</cross_advisor_links>

**Ranking process:**
1. Collect ALL gap amounts from `<allocation_result>` and `<tax_score_result>`: every [RED] and [YELLOW] dimension has an explicit EUR/BRL annual gap amount
2. For BRL gaps, convert to EUR using this stated assumption: "assuming BRL/EUR = 0.18 for comparison ranking only — not a live rate"
3. Add any cross-advisor intelligence gaps from the patterns above (if triggered)
4. Sort all candidates by estimated annual EUR impact descending
5. Take the top 5 — include cross-advisor items if they rank in the top 5

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 TOP-5 RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Action | Est. Annual Impact | Dimension |
|---|--------|--------------------|-----------|
| 1 | [one-line action] | EUR X,XXX/year | [TAX-01 / ALLOC-02 / CAL-01 / etc.] |
| 2 | [one-line action] | EUR X,XXX/year | [dimension code] |
| 3 | [one-line action] | EUR X,XXX/year | [dimension code] |
| 4 | [one-line action] | EUR X,XXX/year | [dimension code] |
| 5 | [one-line action] | EUR X,XXX/year | [dimension code] |

*BRL gaps converted to EUR at BRL/EUR = 0.18 for ranking only. Not a live exchange rate.*
```

If fewer than 5 distinct gaps exist, list all that do exist.

### Section 4 — Detail

Render the full agent outputs in subsections. These are the complete, untruncated outputs from each agent — do NOT summarize.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 DETAIL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**4.1 Allocation Analysis**

Render the complete content from `<allocation_result>` here (excluding the outer XML tags).

If the allocation agent returned any `[DATA GAP]` notes, surface them inline with a `[DATA GAP]` label.

**4.2 Tax Efficiency**

Render the complete content from `<tax_score_result>` here (excluding the outer XML tags).

If the tax scoring agent returned any `[DATA GAP]` notes, surface them inline with a `[DATA GAP]` label.

**4.3 Projections and Goals**

Render the complete content from `<projection_result>` here (excluding the outer XML tags).

If the projection agent returned any `[DATA GAP]` notes, surface them inline with a `[DATA GAP]` label.

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**Profile incomplete:**
Handled in Phase 1 completeness gate. A report listing each missing field is emitted, and no agents are spawned. The user is directed to run `/finyx:profile` to complete the missing sections.

**Agent returns data gap notes:**
Data gap notes from agents (e.g., `[DATA GAP: field_name]`) are surfaced inline in the corresponding Section 4 subsection with a `[DATA GAP]` label. They do not block report generation — the report is produced with whatever data is available, and gaps are documented.

**Agent fails to return expected XML tags:**
If a Task response does not contain the expected XML-tagged output, note the failure inline in Section 4 with: "Agent output not received — [agent name] did not return expected <[tag]> block. Re-run /finyx:insights to retry."

</error_handling>

<notes>

## Write Targets

This skill writes ONLY to `.finyx/insights-config.json` (allocation mapping persistence on first run). It never modifies `.finyx/profile.json`.

## Agent Statefulness

All three specialist agents are stateless — they read profile data and reference docs, then return structured output. The orchestrating skill (`/finyx:insights`) handles all Write operations.

## Country Scoring

Germany and Brazil dimensions are NEVER combined into a single score. They appear as separate rows in the Health Dashboard table with distinct Country column values. This is absolute.

## Disclaimer Placement

The legal disclaimer is emitted in Phase 2, BEFORE any financial data or advisory content. This differs from `/finyx:tax` and `/finyx:invest` which append the disclaimer at the end. `/finyx:insights` must emit it first.

## BRL/EUR Conversion

BRL/EUR conversion (0.18) is a stated assumption used ONLY for ranking recommendations by EUR impact. It is never used for net worth calculations or goal projections — those remain in native currency (EUR or BRL). The assumption must be stated wherever conversion is applied.

## Allocation Mapping Persistence

On first run, the allocation agent returns a confirmed mapping inside `<allocation_mapping_confirmed>` tags (after confirming with the user via AskUserQuestion). The orchestrator writes this to `.finyx/insights-config.json`. On subsequent runs, the orchestrator passes the stored mapping to the allocation agent, which skips the confirmation flow.

## Reference Doc Loading

The orchestrator does NOT load `benchmarks.md` or `scoring-rules.md` — those are agent-level concerns. The orchestrator loads only `disclaimer.md` and `profile.json` in its execution_context. This keeps the orchestrator context lean and avoids redundant doc loading.

## Agent Paths

Both specialist agents are scoped under this skill:
- `${CLAUDE_SKILL_DIR}/agents/finyx-allocation-agent.md` — income allocation analysis, emergency fund, savings rate benchmarking
- `${CLAUDE_SKILL_DIR}/agents/finyx-projection-agent.md` — net worth snapshot, goal pace, wealth projection

The tax scoring agent (`finyx-tax-scoring-agent`) is shared across skills and lives in the root agents directory.

## Cross-Skill Data Dependencies

Insights reads data produced by other skills via the shared `.finyx/profile.json`. Key dependencies:
- **Tax skill data:** `countries.germany.marginal_rate`, `countries.germany.tax_class`, broker data — used for tax scoring dimension
- **Insurance skill data:** `insurance.policies[]` array — sum of `premium_monthly` used for allocation; `type` field used for gap detection and CAL-05 pattern
- **Pension skill data:** pension contribution fields — used for CAL-02 cross-advisor pattern detection
- **Fallback behavior:** If any cross-skill field is absent or null, the skill skips that dimension silently (no error). Cross-skill integration is additive, not blocking.

## Benchmark and Scoring References

Agent-level reference docs are loaded by agents, not by this orchestrating skill:
- `${CLAUDE_SKILL_DIR}/references/insights/benchmarks.md` — country-adjusted income allocation benchmarks
- `${CLAUDE_SKILL_DIR}/references/insights/scoring-rules.md` — traffic-light scoring rules for each dimension

</notes>
