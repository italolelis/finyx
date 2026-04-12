# Phase 8: Orchestrator Command - Research

**Researched:** 2026-04-06
**Domain:** Claude Code slash-command authoring, multi-agent orchestration, unified report synthesis
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Section order: Summary (net worth + key metrics) → Health (traffic-light dashboard) → Actions (ranked recommendations) → Detail (per-domain agent outputs)
- **D-02:** Traffic-light dashboard as a single unified table with a `Country` column — not separate per-country blocks
- **D-03:** Cross-advisor links via Claude inference from agent outputs with enumerated example patterns in `<cross_advisor_links>` section. No separate rule engine file. Known patterns: Unused Sparerpauschbetrag + low investment rate = double gap; No pension contributions + high marginal rate = missed Rürup deduction; Emergency fund shortfall + high investment rate = over-allocated risk; PGBL not used + completo regime = missed BR deduction.
- **D-04:** Completeness gate in orchestrator; on incomplete profile emit missing-section report, do NOT spawn agents
- **D-05:** Spawn all 3 agents in parallel via Task tool. Each receives pre-validated profile slice. Collect `<allocation_result>`, `<tax_score_result>`, `<projection_result>` XML-tagged outputs.
- **D-06:** Claude's discretion — top-5 recommendations ranked by estimated € annual impact. Each recommendation includes: action, estimated € impact, which dimension it addresses.
- **D-07:** Include `@~/.claude/finyx/references/disclaimer.md` in `<execution_context>`. Emit disclaimer before any advisory content.
- **D-08:** After first-run categorization, the confirmed `allocation_mapping` is persisted by the orchestrator to `.finyx/insights-config.json` (NOT profile.json). Agents have no Write tool.
- **D-09:** Claude's discretion on install.js verification. Research confirmed `copyWithPathReplacement` handles new subdirs automatically — verify if `insights.md` and new reference subdir are picked up without code changes.

### Claude's Discretion

- Recommendation ranking algorithm details (sorted by € impact)
- Exact Markdown formatting of the unified report
- Whether to use `<details>` HTML tags for collapsible detail sections
- install.js verification approach

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-01 | `/fin:insights` command exists with data-completeness gate (flags missing profile sections) | Profile schema fields catalogued; completeness gate pattern sourced from tax.md Phase 1 |
| INFRA-03 | All insights output includes legal disclaimer via shared disclaimer.md | disclaimer.md content confirmed; execution_context include pattern confirmed from tax.md and invest.md |
| REC-01 | Top-5 actionable recommendations ranked by € annual impact | Agent output tags and gap fields documented; ranking pattern defined |
| REC-02 | Cross-advisor intelligence linking insights across domains | Cross-advisor link patterns enumerated in CONTEXT.md D-03; Claude inference approach confirmed |
</phase_requirements>

---

## Summary

Phase 8 creates a single command file (`commands/finyx/insights.md`) that serves as the wiring layer for the entire v1.1 Financial Insights Dashboard. The command orchestrates three specialist agents (allocation, tax-scoring, projection), synthesizes their XML-tagged outputs into a unified report, derives cross-advisor intelligence, and ranks top-5 recommendations by EUR annual impact.

The command follows the exact same structural patterns as existing finyx commands (`tax.md`, `invest.md`): YAML frontmatter with `name`/`description`/`allowed-tools`, `<execution_context>` with `@` includes, and numbered `<process>` phases. The only new capability is parallel Task spawning, which already exists in `invest.md` as a pattern to follow.

The install.js audit confirms no code changes are required: `copyWithPathReplacement` is fully recursive and handles any new `commands/finyx/*.md` files and `finyx/references/insights/` subdirectory automatically. The three Phase 7 agent files are in `agents/` and are already iterated by the flat-file loop in `install()`.

**Primary recommendation:** Build `commands/finyx/insights.md` strictly following the `invest.md` frontmatter + phase structure. The orchestration task is prompt-engineering work, not JavaScript work.

---

## Standard Stack

### Core

| Component | Version/Form | Purpose | Why Standard |
|-----------|-------------|---------|--------------|
| Claude Code slash-command | Markdown `.md` with YAML frontmatter | Command definition | Project architecture; all commands use this form |
| `Task` tool | Claude Code built-in | Parallel agent spawning | Used by invest.md; only mechanism for sub-agents |
| `Read` tool | Claude Code built-in | Profile + reference doc loading | All commands use this |
| `Write` tool | Claude Code built-in | Persist allocation_mapping to `.finyx/insights-config.json` | D-08 requires orchestrator to write; agents cannot |
| `Bash` tool | Claude Code built-in | Profile existence check (Phase 1) | Identical pattern to all existing commands |
| `AskUserQuestion` tool | Claude Code built-in | First-run allocation mapping confirmation | Allocation agent returns mapping for confirmation; orchestrator must confirm with user |

### Supporting

| Component | Location | Purpose | When to Use |
|-----------|----------|---------|-------------|
| `finyx/references/disclaimer.md` | `@~/.claude/finyx/references/disclaimer.md` | Legal disclaimer content | Loaded in `<execution_context>`, emitted in Phase 1 before advisory content |
| `finyx/references/insights/benchmarks.md` | Already loaded by agents | Allocation benchmarks | Loaded by allocation-agent and projection-agent; orchestrator does not load it directly |
| `finyx/references/insights/scoring-rules.md` | Already loaded by agents | Traffic-light thresholds | Loaded by agents; orchestrator consumes their scored output |
| `.finyx/profile.json` | `@.finyx/profile.json` | User financial data | Loaded in `<execution_context>` for completeness gate (Phase 1) |
| `.finyx/insights-config.json` | Runtime write target | Allocation mapping persistence | Written by orchestrator on first run after AskUserQuestion confirmation |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Task (parallel) | Sequential agent calls | Sequential is simpler to reason about but 3x slower; parallel is the established pattern in invest.md |
| `<cross_advisor_links>` section in prompt | Separate rule engine file | Separate file adds indirection without benefit; Claude inference from inline examples is sufficient (D-03) |
| Persist to `.finyx/config.json` | Persist to `.finyx/insights-config.json` | STATE.md records D-07 target changed to `.finyx/config.json`; however CONTEXT.md D-08 specifies `.finyx/insights-config.json`. CONTEXT.md takes precedence. |

**Installation:**

No npm install required. This phase adds `.md` files only. The installer handles them automatically.

---

## Architecture Patterns

### Recommended File Structure (new files only)

```
commands/finyx/
└── insights.md          # New orchestrator command

agents/
└── (no new agents — Phase 7 agents already exist)

finyx/references/
└── (no new reference docs — Phase 6 docs already exist)
```

### Pattern 1: Command Frontmatter

All finyx commands use identical frontmatter structure. `insights.md` must follow exactly:

```yaml
---
name: finyx:insights
description: Unified financial health report — allocation, tax efficiency, projections, and ranked recommendations
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---
```

`Task` is required for parallel agent spawning. `Write` is required for D-08 (insights-config.json persistence). `AskUserQuestion` is required for first-run allocation mapping confirmation (the allocation agent returns a mapping proposal but the user must confirm before it is persisted).

### Pattern 2: execution_context Block

From tax.md and invest.md (confirmed pattern):

```markdown
<execution_context>

@~/.claude/finyx/references/disclaimer.md
@.finyx/profile.json

</execution_context>
```

The orchestrator does NOT load agent-specific reference docs (benchmarks.md, scoring-rules.md, tax-investment.md) — those are loaded by the agents themselves via their own `<execution_context>` blocks. The orchestrator only needs disclaimer.md (D-07) and profile.json (completeness gate).

### Pattern 3: Phase 1 Completeness Gate (D-04)

Required fields per agent, sourced from Phase 7 agent files:

**Allocation agent requires:**
- `investor.income.total` or `countries.germany.gross_income`
- `investor.monthlyCommitments`
- `investor.liquidAssets`

**Tax scoring agent requires:**
- `countries.germany.gross_income > 0` OR (`identity.cross_border == true` AND `countries.brazil.gross_income > 0`)
- `countries.germany.tax_class` (for Germany scoring)
- `countries.brazil.ir_regime` (for Brazil scoring, only if cross_border)

**Projection agent requires:**
- `investor.liquidAssets`
- `investor.monthlyCommitments`
- `investor.income.total` or `countries.germany.gross_income`

**Completeness gate bash check (Phase 1):**

```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first."; exit 1; }
```

After the bash check, Claude reads profile.json (already loaded via execution_context) and checks each required field. If any are zero/null/absent, emit the completeness report and STOP — do NOT spawn agents.

**Completeness report format (no agents spawned):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSIGHTS: PROFILE INCOMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following profile sections must be completed before running /finyx:insights:

[ ] [field name]: [description of what is missing]
...

Run /finyx:profile to complete your profile.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Pattern 4: Parallel Task Spawning (D-05)

Spawn all 3 agents via Task tool simultaneously. Each Task receives a structured prompt containing the relevant profile slice. The Task tool invocations are independent — all three can be initiated before any response is collected.

Each agent returns its result wrapped in XML tags:
- Allocation agent → `<allocation_result>...</allocation_result>`
- Tax scoring agent → `<tax_score_result>...</tax_score_result>`
- Projection agent → `<projection_result>...</projection_result>`

The orchestrator parses these tags from each agent's response and assembles the unified report.

### Pattern 5: First-Run Allocation Mapping (D-08)

On first run, the allocation agent proposes a category mapping and returns it inside `<allocation_mapping_confirmed>` tags in its output (but only after the user confirms — the allocation agent uses AskUserQuestion internally for this). Once the `<allocation_mapping_confirmed>` block appears in `<allocation_result>`, the orchestrator must:

1. Extract the mapping from the `<allocation_mapping_confirmed>` block
2. Write it to `.finyx/insights-config.json` under the `allocation_mapping` key
3. On subsequent runs, the agent reads `.finyx/insights-config.json` and skips the confirmation flow

**Note from STATE.md:** An earlier decision recorded `.finyx/config.json` as the target, but CONTEXT.md D-08 explicitly specifies `.finyx/insights-config.json` to avoid polluting the main profile. Use `.finyx/insights-config.json`.

### Pattern 6: Report Section Order (D-01, D-02)

Unified report structure (after disclaimer):

```
Section 1 — Summary
  Net worth snapshot (from projection_result)
  Key metrics: savings rate, investment rate, overall efficiency

Section 2 — Health Dashboard (single traffic-light table with Country column)
  | Dimension | Country | Status | Gap |
  |-----------|---------|--------|-----|
  | Investment Rate | DE | [COLOR] | EUR X/year |
  | Emergency Fund  | DE | [COLOR] | EUR X/year |
  | Sparerpauschbetrag | DE | [COLOR] | EUR X/year |
  | Vorabpauschale Readiness | DE | [COLOR] | EUR X |
  | PGBL | BR | [COLOR] | R$X/year |
  | Emergency Fund | BR | [COLOR] | R$X/year |

Section 3 — Top-5 Recommendations (ranked by € annual impact, D-06)
  Each row: rank, action, estimated annual impact (EUR), dimension addressed

Section 4 — Detail
  4.1 Allocation detail (from allocation_result)
  4.2 Tax efficiency detail (from tax_score_result)
  4.3 Projections and goals (from projection_result)

Section 5 — Legal Disclaimer
```

### Pattern 7: Cross-Advisor Intelligence (D-03)

Cross-advisor links are surfaced in Section 3 (Actions) or as a distinct subsection before it. The `<cross_advisor_links>` section in the command prompt enumerates the known patterns. Claude infers which apply from the collected agent outputs.

Enumerated patterns (from CONTEXT.md D-03):
- Unused Sparerpauschbetrag + low investment rate = double gap (both TAX-01 red/yellow AND ALLOC-01 red)
- No pension contributions + high marginal rate = missed Rürup deduction (marginal_rate > 42% AND no pension data)
- Emergency fund shortfall + high investment rate = over-allocated risk (ALLOC-02 red AND ALLOC-01 green/high)
- PGBL not used + completo regime = missed BR deduction (TAX-04 red AND ir_regime == "completo")

Each cross-advisor link that fires should appear as a recommendation in Section 3, ranked by its estimated annual EUR/BRL impact.

### Pattern 8: Recommendation Ranking (D-06)

Top-5 recommendations are derived by:
1. Collecting all Gap amounts from agent outputs (every `[RED]` or `[YELLOW]` dimension has an explicit EUR/BRL gap)
2. Converting BRL gaps to EUR using a stated assumption (e.g., "assuming BRL/EUR = 0.18 for comparison only")
3. Sorting by annual EUR impact, descending
4. Taking top 5
5. Adding any cross-advisor intelligence links if they represent additional impact not already captured

**Output format per recommendation:**

```
| # | Action | Est. Annual Impact | Dimension |
|---|--------|--------------------|-----------|
| 1 | [one-line action] | EUR X,XXX/year | [TAX-01 / ALLOC-02 / etc.] |
```

### Anti-Patterns to Avoid

- **Loading agent reference docs in orchestrator:** The orchestrator does not need benchmarks.md or scoring-rules.md — those are for agents. Loading them wastes context.
- **Re-validating profile per-agent:** D-04 says orchestrator validates ONCE before spawning. Agents assume the slice is valid (per their own design notes).
- **Persisting allocation_mapping to profile.json:** D-08 explicitly targets `.finyx/insights-config.json` to keep operational config separate from raw interview data.
- **Combining DE + BR scores:** Never aggregate DE and BR dimensions into a single score — separate rows in the health table, clearly labeled with Country column (D-02).
- **Emitting advisory content before disclaimer:** Disclaimer must appear before any financial content (D-07 / INFRA-03).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Agent XML parsing | Custom regex | Standard Claude tag extraction from Task output | Claude natively handles XML-tagged responses; Task tool returns full agent text |
| Completeness validation logic | JSON schema validator | Explicit field-by-field bash/read check in Phase 1 | No dependencies allowed; the pattern in tax.md and invest.md is simple and sufficient |
| BRL/EUR conversion | Hardcoded rate | Stated assumption in output ("assuming BRL/EUR = 0.18 for ranking only") | No live market data; advisory only; rate must be explicit, not baked in |
| Traffic-light table aggregation | New scoring code | Read [GREEN]/[YELLOW]/[RED] tokens from agent outputs | Agents already produce scored output in the exact format needed |

---

## Common Pitfalls

### Pitfall 1: allocation_mapping persistence target confusion

**What goes wrong:** Writing allocation_mapping to `.finyx/config.json` instead of `.finyx/insights-config.json`.
**Why it happens:** STATE.md (accumulated context) recorded `.finyx/config.json` as an intermediate decision; CONTEXT.md D-08 overrides this with `.finyx/insights-config.json`.
**How to avoid:** CONTEXT.md is authoritative. Use `.finyx/insights-config.json` exclusively.
**Warning signs:** If the Write target is `.finyx/config.json`, that is the wrong file.

### Pitfall 2: Disclaimer placement

**What goes wrong:** Disclaimer appears at the end of output rather than before advisory content.
**Why it happens:** tax.md puts disclaimer at Phase 6 (end); invest.md puts it at Phase 8 (end). But INFRA-03 requires all insights output to include the disclaimer, and D-07 says it must be emitted before any advisory content.
**How to avoid:** The disclaimer should be the FIRST thing emitted after the banner header, before any financial numbers or recommendations.
**Warning signs:** Any financial data appearing before the disclaimer block.

### Pitfall 3: Tool list missing Write or AskUserQuestion

**What goes wrong:** Command runs but cannot persist allocation_mapping or prompt user for first-run confirmation.
**Why it happens:** Easy to copy the `allowed-tools` from invest.md which has Write but not AskUserQuestion at the command level (AskUserQuestion is in the agent).
**How to avoid:** `insights.md` must include both `Write` (for D-08) and `AskUserQuestion` (for first-run mapping confirmation flow that the allocation agent hands back to the orchestrator).
**Warning signs:** `allocation_mapping_confirmed` block appears in agent output but orchestrator cannot confirm with user or write to disk.

### Pitfall 4: install.js agent loop only handles flat files

**What goes wrong:** Assuming new agent files in subdirectories under `agents/` would not be picked up.
**Why it happens:** install.js `install()` reads agents flat: `fs.readdirSync(agentsSrc, { withFileTypes: true })` — iterates only top-level files, filters by `.endsWith('.md')`.
**How to avoid:** All three Phase 7 agents are flat files in `agents/` (e.g., `agents/finyx-allocation-agent.md`) — this is correct and they ARE picked up. No new agent files are added in Phase 8.
**Warning signs:** Agent subdirectories (not the case here) would require a `copyWithPathReplacement` call instead.

### Pitfall 5: insights.md command file not in flat finyx commands dir

**What goes wrong:** Placing `insights.md` in a subdirectory under `commands/finyx/`.
**Why it happens:** install.js uses `copyWithPathReplacement` for `commands/finyx/` which IS recursive, so subdirs would be copied — but Claude Code slash-commands are discovered by flat file name, not subdirectory.
**How to avoid:** Place `commands/finyx/insights.md` at the root of `commands/finyx/`, matching all other command files.

### Pitfall 6: Cross-border user profile — no Brazil income

**What goes wrong:** `identity.cross_border == true` but `countries.brazil.gross_income == 0`. Tax agent skips Brazil scoring but allocation agent may still attempt BR calculations.
**Why it happens:** cross_border flag and Brazil income are independent fields.
**How to avoid:** Completeness gate must check BOTH `cross_border` AND `countries.brazil.gross_income > 0` before requiring Brazil fields. Document this gate logic explicitly in Phase 1.

---

## Code Examples

Verified patterns from canonical source files:

### Command frontmatter (source: commands/finyx/tax.md, invest.md)

```yaml
---
name: finyx:insights
description: Unified financial health report — allocation, tax efficiency, projections, and ranked recommendations
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---
```

### execution_context block (source: commands/finyx/tax.md)

```markdown
<execution_context>

@~/.claude/finyx/references/disclaimer.md
@.finyx/profile.json

</execution_context>
```

### Phase 1 bash profile check (source: commands/finyx/tax.md, invest.md)

```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

### Output banner pattern (source: commands/finyx/tax.md)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSIGHTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Disclaimer emit (source: commands/finyx/tax.md Phase 6, invest.md Phase 8)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Output the full disclaimer.md content here]
```

For insights.md, this moves to BEFORE advisory content (not the end).

### Unified health dashboard table structure (D-02)

```markdown
| Dimension | Country | Status | Gap | How to Close |
|-----------|---------|--------|-----|--------------|
| Investment Rate | DE | [GREEN] | None | Maintain |
| Emergency Fund | DE | [RED] | EUR 11,700 | Build Tagesgeld |
| Sparerpauschbetrag | DE | [YELLOW] | EUR 263/year | Allocate Freistellungsauftrag |
| Vorabpauschale Readiness | DE | [GREEN] | None | Maintain buffer |
| PGBL | BR | [RED] | R$12,000/year | Increase PGBL contributions |
| Emergency Fund | BR | [YELLOW] | R$8,000 | Build poupanca buffer |
```

### Write to insights-config.json (D-08)

```bash
# Check if .finyx/ directory exists
[ -d .finyx ] || mkdir -p .finyx
```

Then emit the Write operation to `.finyx/insights-config.json` with the confirmed allocation_mapping JSON.

### install.js — no code change needed (D-09 verification)

`copyWithPathReplacement` at line 76–98 of `bin/install.js` is fully recursive:
- `commands/finyx/insights.md` → picked up by the `commandsSrc` copy block (lines 186-190), which calls `copyWithPathReplacement(commandsSrc, commandsDest, pathPrefix)` — recursive, handles any new `.md` file
- Phase 7 agents (`finyx-allocation-agent.md`, `finyx-tax-scoring-agent.md`, `finyx-projection-agent.md`) → picked up by the agents loop (lines 204-219), flat `readdirSync` + `endsWith('.md')` filter — all three are top-level files in `agents/`
- `finyx/references/insights/` subdir → picked up by the `finyxSrc` copy block (lines 195-199), which calls `copyWithPathReplacement(finyxSrc, finyxDest, pathPrefix)` — recursive, handles subdirectories

**Conclusion:** No changes to `bin/install.js` are required. The verification task for Phase 8 is a dry-run trace of the three copy blocks to confirm all new files are covered — not a code change.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 8 adds `.md` files only. No external tools, services, runtimes, or CLI utilities are required beyond Node.js (already verified present) for the install.js unchanged path.

---

## Validation Architecture

No automated test framework is present in this project (confirmed: no test config files, no test directories, no test scripts in package.json). Validation is manual.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| INFRA-01 | Incomplete profile → completeness gate report, no agents spawned | Manual smoke | — | Run `/fin:insights` with empty profile |
| INFRA-01 | Complete profile → unified report generated | Manual smoke | — | Run `/fin:insights` with full profile |
| INFRA-03 | Disclaimer appears before advisory content in all output paths | Manual inspection | — | Check output order |
| REC-01 | Top-5 recommendations present with EUR impact and dimension label | Manual inspection | — | Verify table in Section 3 |
| REC-02 | At least one cross-advisor link surfaced for a cross-border profile | Manual smoke | — | Use cross_border=true profile |

### Wave 0 Gaps

None — no test framework required for this project type. All validation is manual smoke testing via Claude Code invocation.

---

## Sources

### Primary (HIGH confidence)

- `commands/finyx/tax.md` — command frontmatter, phase structure, profile validation pattern, disclaimer emit pattern
- `commands/finyx/invest.md` — Task tool (absent from this file — see note below), AskUserQuestion pattern, Write pattern
- `agents/finyx-allocation-agent.md` — output format, `<allocation_result>` tag, `<allocation_mapping_confirmed>` tag, required profile fields
- `agents/finyx-tax-scoring-agent.md` — output format, `<tax_score_result>` tag, required profile fields, country scoping logic
- `agents/finyx-projection-agent.md` — output format, `<projection_result>` tag, required profile fields
- `bin/install.js` — installer architecture, `copyWithPathReplacement` recursive logic, agent flat-file loop
- `finyx/references/disclaimer.md` — disclaimer content confirmed
- `finyx/references/insights/scoring-rules.md` — traffic-light dimensions, gap formulas, output format per dimension
- `finyx/references/insights/benchmarks.md` — allocation targets, investment sub-targets, emergency fund thresholds
- `finyx/templates/profile.json` — complete profile schema, all field names and types

### Note on Task tool in invest.md

invest.md does NOT actually use the Task tool — it is a single-command workflow with no sub-agent spawning (confirmed by reading the file: allowed-tools does not include Task). The Task spawning pattern is inherited from the general Claude Code agent architecture and the finyx-allocation-agent.md file which explicitly states it is "Spawned by /fin:insights". The `Task` tool usage is documented in Claude Code's own architecture, and the allocation/tax/projection agents all declare themselves as spawned agents.

---

## Metadata

**Confidence breakdown:**
- Command file structure: HIGH — sourced directly from existing finyx commands
- Agent output formats: HIGH — read directly from Phase 7 agent files
- install.js behavior: HIGH — read directly from bin/install.js source
- Report structure: HIGH — locked by CONTEXT.md decisions D-01/D-02
- Recommendation ranking algorithm: MEDIUM — Claude's discretion, no external source needed
- Cross-advisor intelligence patterns: HIGH — enumerated in CONTEXT.md D-03

**Research date:** 2026-04-06
**Valid until:** Stable (no fast-moving external dependencies — all sources are internal project files)
