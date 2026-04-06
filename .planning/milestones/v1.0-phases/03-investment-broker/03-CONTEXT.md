# Phase 3: Investment + Broker - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Build `/finyx:invest` (portfolio analysis, ETF recommendations, rebalancing, live market data) and `/finyx:broker` (broker fee comparison, profile-based recommendation). Two commands covering 9 requirements — INVEST-01 through INVEST-05 and BROKER-01 through BROKER-04.

</domain>

<decisions>
## Implementation Decisions

### Command Structure
- **D-01:** Split into two commands: `/finyx:invest` and `/finyx:broker`. Different user intents — "analyse my portfolio" vs "which broker should I use".
- **D-02:** `/finyx:invest` covers INVEST-01 through INVEST-05 (portfolio allocation, risk profiling, ETF recs, rebalancing, market data).
- **D-03:** `/finyx:broker` covers BROKER-01 through BROKER-04 (DE/BR fee comparison, profile-based recommendation, tax reporting quality).
- **D-04:** Market data queries (INVEST-05) are a phase inside `/finyx:invest`, not a separate command.

### Portfolio Input Method
- **D-05:** Holdings stored in `profile.json` as a `holdings[]` array grouped by broker. Commands read statlessly.
- **D-06:** Profile schema extended with `holdings[]` under each broker entry, each holding having `ticker`, `shares`, `cost_basis`, `asset_class`, `geography`.
- **D-07:** `/finyx:profile` should be updated to optionally collect holdings during the interview, but this is a lightweight addition — the primary input path is manual profile.json editing.

### Market Data Approach
- **D-08:** API keys via env vars: `FINNHUB_API_KEY` (EU/US) and `BRAPI_TOKEN` (B3/FIIs). Never stored in profile.json (secrets).
- **D-09:** Pre-flight check in `/finyx:invest` market data phase: if env var unset, emit clear setup instructions and fall back to WebSearch for best-effort results.
- **D-10:** `curl` for API calls — zero runtime dependencies. Parse JSON response inline with `node -e` or `jq` if available.

### Broker Knowledge Source
- **D-11:** Static reference docs: `finyx/references/germany/brokers.md` and `finyx/references/brazil/brokers.md`.
- **D-12:** YAML frontmatter with `last_verified: YYYY-MM-DD` date. Command surfaces staleness warning if >6 months old.
- **D-13:** Mine existing `~/.claude/skills/fin-advisor/references/broker-guide.md` for German broker content.
- **D-14:** Include broker URLs in reference doc so users can verify current fees themselves.

### Claude's Discretion
- Risk profile assessment questionnaire design (INVEST-02) — Claude decides the optimal question flow.
- ETF recommendation matching algorithm (INVEST-03) — Claude decides how to map risk profile to specific ETFs.
- Rebalancing threshold and suggestion format (INVEST-04) — Claude decides drift % that triggers suggestions.
- Portfolio visualization format (INVEST-01) — table, ASCII chart, or narrative breakdown.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Content to Mine
- `~/.claude/skills/fin-advisor/SKILL.md` — Portfolio strategy, risk assessment patterns, savings plan guidance
- `~/.claude/skills/fin-advisor/references/broker-guide.md` — German broker fee/feature comparison (if exists)
- `~/.claude/skills/fin-research/SKILL.md` — ETF comparison framework (TER, tracking difference, fund quality metrics)

### Profile & Command Patterns
- `finyx/templates/profile.json` — Current schema. Needs `holdings[]` extension.
- `commands/finyx/tax.md` — Unified command pattern with country routing. Reference for `/finyx:invest` structure.
- `commands/finyx/profile.md` — Interview pattern using AskUserQuestion.
- `commands/finyx/analyze.md` — Example of command with profile gating + disclaimer.

### Reference Doc Patterns
- `finyx/references/germany/tax-investment.md` — Phase 2 pattern: YAML frontmatter with `tax_year`, domain-specific content. Follow for `brokers.md`.
- `finyx/references/brazil/tax-investment.md` — Same pattern for Brazilian content.
- `finyx/references/disclaimer.md` — Must be in execution_context of both new commands.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `fin-advisor` skill: Portfolio strategy content, broker comparison data, risk assessment patterns
- `fin-research` skill: ETF comparison framework (TER, tracking difference, fund quality, tax efficiency)
- `finyx/templates/profile.json`: Profile schema — extend with `holdings[]`
- Phase 2 country routing pattern in `commands/finyx/tax.md`: Reuse for both commands

### Established Patterns
- YAML frontmatter with `name`, `description`, `allowed-tools` for all commands
- `<execution_context>` blocks with `@path` references
- Profile gating: `[ -f .finyx/profile.json ] || { echo "ERROR: ..."; exit 1; }`
- Disclaimer: `@~/.claude/finyx/references/disclaimer.md`
- Country detection from profile: `countries.germany` / `countries.brazil`
- `tax_year` / `last_verified` frontmatter for staleness detection

### Integration Points
- `commands/finyx/help.md` — must register `/finyx:invest` and `/finyx:broker`
- `bin/install.js` — new reference docs auto-included via recursive copy
- `finyx/templates/profile.json` — schema extension for `holdings[]`

</code_context>

<specifics>
## Specific Ideas

- Mine `fin-advisor` and `fin-research` skills for investment/broker content rather than writing from scratch.
- Finnhub free tier: 60 calls/min. brapi.dev free tier: 10 calls/min. Both return JSON.
- German brokers: Trade Republic, Scalable Capital, ING, comdirect. Brazilian: XP, NuInvest, BTG Pactual.
- Tax reporting quality is a key differentiator: German brokers auto-generate Anlage KAP; foreign brokers require manual calculation.

</specifics>

<deferred>
## Deferred Ideas

- CSV/broker export import for holdings — potential future enhancement if manual entry proves too tedious
- Automated portfolio rebalancing execution — advisory only for now
- Tax-loss harvesting guidance (INVEST-D01, INVEST-D02) — listed as differentiator, not Phase 3 requirement
- Real estate + investment portfolio integration analysis (INVEST-D03)

</deferred>

---

*Phase: 03-investment-broker*
*Context gathered: 2026-04-06*
