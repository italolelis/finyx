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

---

---

# Architecture Extension: Comprehensive Insurance Skill (v2.1)

**Domain:** Expanding insurance skill from PKV/GKV to 11+ insurance types
**Researched:** 2026-04-12
**Confidence:** HIGH (based on existing codebase patterns + German insurance domain knowledge)

---

## Core Architectural Decision: Router Pattern in SKILL.md

The existing SKILL.md becomes a **router** — it identifies which insurance type(s) the user wants and delegates to per-type sub-flows via the Task tool. This is the only viable approach given:

- A single SKILL.md cannot hold 11 independent workflows. The current health-only SKILL.md is 605 lines for one type. 11 types would produce a 5,000+ line file that is unmaintainable and loads irrelevant reference docs on every invocation.
- Adding separate slash commands per type (`/finyx:insurance-liability`, `/finyx:insurance-car`, etc.) pollutes the command namespace and breaks the unified `insurance` UX.
- The router pattern (one entry point, delegates to sub-flows) is established precedent within Claude Code: the real estate skill routes between scout/analyze/filter/compare/stress-test/report based on user invocation.

**Do NOT use a mega-SKILL.md.** A single file for all 11 types wastes the context window loading all reference docs every run and makes per-type updates error-prone.

---

## Recommended Insurance Skill Structure (v2.1)

```
skills/insurance/
  SKILL.md                              ← Router: mode selection + dispatch only (~100 lines)
  agents/
    finyx-insurance-calc-agent.md       ← Existing (GKV/PKV cost calc, unchanged)
    finyx-insurance-research-agent.md   ← Existing, generalized to accept <insurance_type>
    finyx-insurance-doc-reader.md       ← NEW: reads user policy documents
    finyx-insurance-portfolio.md        ← NEW: cross-type portfolio overview + gap detection
  references/
    disclaimer.md                       ← Existing (shared across all types)
    germany/
      health-insurance.md               ← Existing
      liability-insurance.md            ← NEW: Haftpflichtversicherung
      household-insurance.md            ← NEW: Hausratversicherung
      car-insurance.md                  ← NEW: KFZ (Haftpflicht/Teilkasko/Vollkasko)
      legal-insurance.md                ← NEW: Rechtsschutzversicherung
      life-insurance.md                 ← NEW: Risikolebens- / Kapitallebensversicherung
      disability-insurance.md           ← NEW: Berufsunfähigkeitsversicherung (BU)
      dental-insurance.md               ← NEW: Zahnzusatzversicherung
      travel-insurance.md               ← NEW: Reiseversicherung (Kranken/Gepäck/Rücktritt)
      bicycle-insurance.md              ← NEW: Fahrradversicherung
      rental-deposit-insurance.md       ← NEW: Kautionsversicherung
      insurance-portfolio.md            ← NEW: Coverage gap matrix + over-insurance signals
  sub-skills/
    health.md                           ← EXTRACTED from current SKILL.md (~500 lines)
    liability.md                        ← NEW
    household.md                        ← NEW
    car.md                              ← NEW
    legal.md                            ← NEW
    life.md                             ← NEW
    disability.md                       ← NEW
    dental.md                           ← NEW
    travel.md                           ← NEW
    bicycle.md                          ← NEW
    rental-deposit.md                   ← NEW
    portfolio-overview.md               ← NEW (cross-type synthesis)
```

### What `sub-skills/` contains

These are NOT Claude Code skills (no `name:` YAML frontmatter). They are Markdown prompt fragments that SKILL.md reads via the `Read` tool and pastes inline into Task prompts. The router reads the selected sub-skill file and executes its instructions as the Task payload. This pattern keeps SKILL.md thin and makes each type's flow independently editable without touching the router.

---

## SKILL.md Router: Minimal Responsibility

The router does exactly four things:

1. **Validate profile** (same bash check as existing Phase 1)
2. **Mode selection via AskUserQuestion:**
   - "Review a specific insurance type" → show list of 11 types
   - "Scan my insurance documents" → invoke doc reader path
   - "Insurance portfolio overview" → invoke portfolio overview
3. **Load only the reference doc for the selected type** — not all docs
4. **Read the sub-skill prompt and execute it** — router has no type-specific logic

The entire existing PKV/GKV flow moves into `sub-skills/health.md`. The router shrinks from 605 lines to ~100 lines.

---

## Agent Decomposition

### Keep existing calc agent for health only

`finyx-insurance-calc-agent.md` handles PKV/GKV cost calculations. This requires specialized actuarial math (JAEG, §10 EStG netting, 30-year projections, risk tier classification). No other insurance type has equivalent computational complexity. Keep it as-is, health-specific.

### Generalize research agent across all types

The current `finyx-insurance-research-agent.md` is PKV-specific in its search queries. Generalize it to accept `<insurance_type>` and `<search_context>` blocks. The underlying capability — query Stiftung Warentest, Check24, Verivox, official provider sites; extract premium ranges, coverage limits, inclusions/exclusions — is identical for all types. The type-specific terms are passed in the Task prompt.

Generalized research agent accepts:
```
<insurance_type>liability</insurance_type>
<search_context>
type: Haftpflichtversicherung
profile: married, 1 child, Germany
focus: coverage_limit, premium_range, key_exclusions
neutral_sources: Stiftung Warentest, Verbraucherzentrale, BaFin
</search_context>
```

The agent must never bias toward specific providers. Source priority: Stiftung Warentest > Verbraucherzentrale > BaFin > aggregator sites (Check24, Verivox) for price ranges only. Provider mentions in output are always presented as a representative sample, not a ranked list.

### Two new agents for v2.1

**`finyx-insurance-doc-reader.md`** — reads user-provided policy documents from `.finyx/insurance/documents/`. Uses Claude's native `Read` tool to load PDF/text files. Extracts structured policy data and returns normalized JSON. No external OCR dependency — Claude's multimodal PDF reading handles this natively.

**`finyx-insurance-portfolio.md`** — takes normalized policy objects (from doc reader or manual profile data) and performs cross-type gap analysis, cost rollup, and overlap detection. Outputs a portfolio summary consumable by `/finyx:insights`.

**Agent roster for v2.1:**

| Agent | Scope | Type |
|-------|-------|------|
| `finyx-insurance-calc-agent` | GKV/PKV cost calculations only | Existing, unchanged |
| `finyx-insurance-research-agent` | Web research for any insurance type | Existing, generalized |
| `finyx-insurance-doc-reader` | Reads + extracts from user policy documents | New |
| `finyx-insurance-portfolio` | Cross-type portfolio analysis, gap detection | New |

No per-type research agents. No per-type calc agents (only health needs one).

---

## Document Reader Agent

Document folder convention (configurable, default shown):
```
.finyx/
  insurance/
    documents/
      haftpflicht-huk24-2024.pdf
      hausrat-allianz-2023.pdf
      kfz-huk24-2024.pdf
```

The agent reads each file using the `Read` tool (Claude's native PDF reading), extracts structured fields, and returns a normalized policy object per document:

```json
{
  "type": "liability",
  "provider": "HUK24",
  "policy_number": "...",
  "annual_premium": 89.00,
  "monthly_premium": 7.42,
  "coverage_limit": 10000000,
  "deductible": 0,
  "start_date": "2024-01-01",
  "renewal_date": "2024-12-31",
  "key_inclusions": ["personal", "bicycle", "animals"],
  "key_exclusions": ["intentional damage"],
  "source": "document",
  "source_file": "haftpflicht-huk24-2024.pdf",
  "confidence": "high"
}
```

**Anti-hallucination rule (mandatory):** If a field cannot be clearly read from the document, output `"NOT_FOUND"` for that field — never infer or estimate from "typical" policy values. Coverage amounts and premiums must come from the document text.

The doc reader agent does NOT write to `.finyx/profile.json` directly. It returns JSON output. The router confirms with the user before writing to profile.

---

## Profile Schema Extension

Add an `insurance` block to `.finyx/profile.json`. Populated by the doc reader (automated) or via `/finyx:profile` (manual).

```json
"insurance": {
  "document_folder": ".finyx/insurance/documents",
  "last_portfolio_scan": null,
  "policies": [
    {
      "type": "health",
      "subtype": "pkv",
      "provider": "AXA",
      "monthly_premium": 420.00,
      "coverage_summary": "Komfort tariff, Selbstbeteiligung €600/yr",
      "last_reviewed": "2026-04-01",
      "source": "manual"
    },
    {
      "type": "liability",
      "provider": "HUK24",
      "monthly_premium": 7.42,
      "coverage_limit": 10000000,
      "last_reviewed": "2026-04-01",
      "source": "document",
      "source_file": "haftpflicht-huk24-2024.pdf"
    }
  ]
}
```

**Schema decisions:**
- `type` is the canonical key: `health`, `liability`, `household`, `car`, `legal`, `life`, `disability`, `dental`, `travel`, `bicycle`, `rental-deposit`
- `subtype` is optional — used for `health` (pkv/gkv), `car` (vollkasko/teilkasko/haftpflicht)
- `monthly_premium` is always monthly EUR — normalize at extraction time (annual / 12)
- `source` is `"manual"` or `"document"` — audit trail for anti-hallucination verification
- `coverage_summary` is free text — surfaced as-is, not parsed further
- Health flags (from Phase 3 questionnaire) are NEVER stored here — GDPR Art. 9 constraint is unchanged

**Integration with `/finyx:insights`:** The insights skill reads `insurance.policies[]` and sums `monthly_premium` across all policies to produce the insurance line item in the allocation analysis. No change to the insights skill is needed — it already reads `profile.json` holistically.

---

## Reference Doc Standard (per type)

One doc per insurance type. Not grouped. Content standard:

1. Legal basis (which statute governs — e.g., §1 PflVG for KFZ)
2. Coverage mechanics (what's covered, what's not — canonical, provider-neutral)
3. Market structure (approximate premium ranges, what differentiates tariffs)
4. Mandatory vs. optional status for the target profile
5. Tax implications (BU premiums as Sonderausgaben, Risikoleben as Vorsorgeaufwendungen, etc.)
6. Key decisions (Selbstbeteiligung tradeoffs, coverage limit recommendations)

What reference docs do NOT contain: provider-specific prices, application URLs, current promotional rates. Those come from the research agent's live WebSearch, keeping reference docs stable between invocations and free of commercial bias.

---

## Data Flow

```
User: /finyx:insurance
          |
          v
    SKILL.md (Router)
    - Validate profile
    - AskUserQuestion: mode
          |
    +-----------+-----------+
    |           |           |
 type        scan        portfolio
 select     documents    overview
    |           |           |
    v           v           v
Read           Read       Read
sub-skills/    .finyx/    all profile
<type>.md      insurance/  insurance[]
    |          documents/  |
    v               |      v
Spawn              v    Spawn
research      Spawn     portfolio
agent         doc-reader  agent
(generalized) agent       |
    |               |     v
    v               v   Gap matrix
Output:        Normalized  Total cost
type advisory  policy JSON  Overlaps
               |           Gaps
               v           Recommendations
        User confirmation
        Write to profile.json
```

---

## Portfolio Overview Sub-Skill

Triggers when: user selects "portfolio overview", or after any type-specific analysis as an optional cross-sell.

Requires: at least one entry in `profile.json insurance.policies[]` (from doc reader or manual).

Output sections:
1. Total monthly insurance spend (sum of all `monthly_premium` values)
2. Coverage gap matrix — which types the user has vs. recommended for their profile
3. Over-insurance signals — duplicate coverage (e.g., bicycle covered in both Hausrat and a standalone bicycle policy)
4. Optimization flags — policies where market research agent detects current premium is above market rate by >15%
5. Insights integration line — single number for `/finyx:insights` allocation: "insurance: €XXX/mo (N policies)"

The portfolio agent runs the gap matrix against a profile-aware baseline. For a married-with-child, high-income German resident: Haftpflicht and health are mandatory; KFZ is mandatory if car owned; Hausrat is highly recommended; BU is strongly recommended for high earners; Rechtsschutz is useful; the rest are situational.

---

## Scalability

| Concern | Current (1 type) | v2.1 (11 types) | Future (Brazil) |
|---------|-----------------|-----------------|-----------------|
| SKILL.md size | 605 lines | ~100 lines (router) | No change |
| Reference docs | 1 doc | 11 docs | Add `brazil/` subdirectory |
| Agent count | 2 agents | 4 agents | No new agents |
| Profile schema | No insurance block | `insurance[]` array | Same schema, EUR amounts |
| Context per invocation | 2 docs always loaded | 1 doc per selected type | Same (router gates loading) |

Adding a new insurance type (e.g., pet insurance, cyber insurance) in the future requires:
1. One new reference doc in `references/germany/`
2. One new `sub-skills/<type>.md` prompt
3. One new entry in the router's AskUserQuestion list

No agent changes. No profile schema changes. No SKILL.md structural changes.

---

## Anti-Patterns to Avoid

### Mega-SKILL.md with all 11 type flows inline
Results in 5,000+ line file. Every update to one type risks breaking others. All reference docs load on every invocation regardless of which type the user selected.

### Per-type research agents (11 separate agents)
Identical web search pattern duplicated 11 times. Generalize the existing research agent with `<insurance_type>` parameter.

### Writing health flags to the insurance portfolio schema
The `insurance.policies[]` block in profile.json stores only premium/coverage/provider data. Health questionnaire flags (GDPR Art. 9) are never persisted anywhere.

### Hardcoding provider names in reference docs
Reference docs are provider-neutral. The research agent's live WebSearch surfaces current providers. This keeps the advisory unbiased as the market changes and avoids commercial appearance.

### Per-type slash commands (/finyx:insurance-liability, etc.)
Pollutes command namespace. The router handles type selection via AskUserQuestion within the single `/finyx:insurance` entry point.

### Doc reader agent writing directly to profile.json
The doc reader returns JSON output. The router confirms with the user before writing. This prevents silent profile corruption from misread documents.

---

## Sources

- Existing codebase: `skills/insurance/SKILL.md` — current PKV/GKV implementation, 605 lines (HIGH confidence)
- Existing codebase: `.planning/PROJECT.md` — v2.1 requirements (HIGH confidence)
- German insurance type taxonomy: settle-in-berlin.com/insurance-in-germany/, allaboutberlin.com/guides/insurance (MEDIUM confidence — consumer guides, accurate for scope)
- AI multi-agent insurance patterns: dialonce.ai/en/blog-ai/trends/multi-agent-ai-system-insurance (LOW confidence — descriptive, not prescriptive for this use case)
- AI insurance document extraction: datagrid.com/blog/ai-agents-automate-insurance-policy-comparison-document-control-managers (MEDIUM confidence — commercial context, extraction field patterns are applicable)
