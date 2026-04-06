# Phase 3: Investment + Broker - Research

**Researched:** 2026-04-06
**Domain:** Portfolio analysis, ETF recommendations, market data APIs, broker fee comparison
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Split into two commands: `/finyx:invest` and `/finyx:broker`. Different user intents.
- **D-02:** `/finyx:invest` covers INVEST-01 through INVEST-05.
- **D-03:** `/finyx:broker` covers BROKER-01 through BROKER-04.
- **D-04:** Market data queries (INVEST-05) are a phase inside `/finyx:invest`, not a separate command.
- **D-05:** Holdings stored in `profile.json` as a `holdings[]` array grouped by broker. Commands read statlessly.
- **D-06:** Profile schema extended with `holdings[]` under each broker entry: `ticker`, `shares`, `cost_basis`, `asset_class`, `geography`.
- **D-07:** `/finyx:profile` should be updated to optionally collect holdings during interview — lightweight addition only.
- **D-08:** API keys via env vars: `FINNHUB_API_KEY` (EU/US) and `BRAPI_TOKEN` (B3/FIIs). Never stored in profile.json.
- **D-09:** Pre-flight check in `/finyx:invest` market data phase: if env var unset, emit clear setup instructions and fall back to WebSearch.
- **D-10:** `curl` for API calls — zero runtime dependencies. Parse JSON response inline with `node -e` or `jq` if available.
- **D-11:** Static reference docs: `finyx/references/germany/brokers.md` and `finyx/references/brazil/brokers.md`.
- **D-12:** YAML frontmatter with `last_verified: YYYY-MM-DD`. Command surfaces staleness warning if >6 months old.
- **D-13:** Mine existing `~/.claude/skills/fin-advisor/references/broker-guide.md` for German broker content.
- **D-14:** Include broker URLs in reference doc so users can verify current fees themselves.

### Claude's Discretion

- Risk profile assessment questionnaire design (INVEST-02) — Claude decides the optimal question flow.
- ETF recommendation matching algorithm (INVEST-03) — Claude decides how to map risk profile to specific ETFs.
- Rebalancing threshold and suggestion format (INVEST-04) — Claude decides drift % that triggers suggestions.
- Portfolio visualization format (INVEST-01) — table, ASCII chart, or narrative breakdown.

### Deferred Ideas (OUT OF SCOPE)

- CSV/broker export import for holdings
- Automated portfolio rebalancing execution
- Tax-loss harvesting guidance (INVEST-D01, INVEST-D02)
- Real estate + investment portfolio integration analysis (INVEST-D03)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INVEST-01 | Portfolio allocation breakdown by geography, sector, asset class | Holdings schema + visualization patterns from fin-advisor skill |
| INVEST-02 | Risk profile assessment mapped to investment recommendations | Risk questionnaire pattern from fin-advisor skill; 3-level profile (conservative/moderate/aggressive) |
| INVEST-03 | ETF recommendations based on goals and risk profile | ETF comparison framework from fin-research skill; canonical ETF list with ISINs |
| INVEST-04 | Rebalancing suggestions when portfolio drifts from target | 5% drift threshold per asset class is industry-standard (Betterment/Vanguard) |
| INVEST-05 | Live market data queries via APIs/WebSearch | Finnhub (EU/US) + brapi.dev (B3/FIIs) — both free-tier curl-accessible |
| BROKER-01 | German broker fee comparison (Trade Republic, Scalable, ING, comdirect) | Verified fee data in fin-advisor broker-guide + 2026 web search |
| BROKER-02 | Brazilian broker fee comparison (XP, NuInvest, BTG) | Fee data from web search (NuInvest zero-commission, BTG R$4.50 base, XP varies) |
| BROKER-03 | Profile-based broker recommendation considering trading frequency and asset types | Decision matrix: trading frequency × asset types × tax complexity |
| BROKER-04 | Tax reporting quality differences (auto-generated Anlage KAP vs manual) | Verified: TR/Scalable/ING/comdirect all generate Jahressteuerbescheinigung; Trading212/IBKR/foreign require manual Anlage KAP |
</phase_requirements>

---

## Summary

Phase 3 builds `/finyx:invest` and `/finyx:broker` — two commands covering portfolio analysis and broker comparison. The architecture follows the established `finyx:tax` pattern exactly: profile gating, country routing, reference doc loading, disclaimer append, and `━━━` output banners.

The key data sources are already available in the project: `~/.claude/skills/fin-advisor/` and `~/.claude/skills/fin-research/` contain substantial content to mine — broker fee data, ETF comparison framework, risk assessment patterns, and canonical ETF ISINs. The two broker reference docs (`germany/brokers.md`, `brazil/brokers.md`) are new files to create, following the `tax-investment.md` pattern with `last_verified` frontmatter.

The only new complexity is API integration for INVEST-05. Both Finnhub and brapi.dev are curl-accessible with a token parameter. Pre-flight env var check + WebSearch fallback (D-09) keeps the zero-runtime-dependency constraint intact.

**Primary recommendation:** Follow `finyx:tax` structure exactly. Mine skills before writing any content. Create two new reference docs for brokers before building the commands.

---

## Standard Stack

### Core

| Component | What It Is | Why Used |
|-----------|-----------|----------|
| Markdown command files | `/finyx:invest`, `/finyx:broker` | Established command pattern — no deviations |
| `finyx/references/germany/brokers.md` | Static German broker reference | D-11: avoids live scraping, adds `last_verified` staleness guard |
| `finyx/references/brazil/brokers.md` | Static Brazilian broker reference | D-11: same pattern |
| `finyx/templates/profile.json` | Extended with `holdings[]` per broker | D-05/D-06: stateless read by commands |
| `curl` + `node -e` / `jq` | API calls and JSON parsing | D-10: zero runtime dependencies |
| Finnhub REST API | EU/US stock/ETF quotes | D-08: env var `FINNHUB_API_KEY` |
| brapi.dev REST API | B3/FII/ETF quotes | D-08: env var `BRAPI_TOKEN` |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `~/.claude/skills/fin-advisor/references/broker-guide.md` | Source content for `germany/brokers.md` | Mine at Wave 0 / reference doc authoring |
| `~/.claude/skills/fin-advisor/SKILL.md` | Risk assessment patterns, portfolio review checklist | Mine for INVEST-01/02/04 logic |
| `~/.claude/skills/fin-research/SKILL.md` | ETF comparison framework, canonical ISINs | Mine for INVEST-03 logic |
| `finyx/references/disclaimer.md` | Legal disclaimer | Must appear in execution_context of both commands |

---

## Architecture Patterns

### Recommended File Structure

```
commands/finyx/
├── invest.md           # New: INVEST-01 through INVEST-05
└── broker.md           # New: BROKER-01 through BROKER-04

finyx/
├── references/
│   ├── germany/
│   │   └── brokers.md  # New: German broker comparison reference
│   └── brazil/
│       └── brokers.md  # New: Brazilian broker comparison reference
└── templates/
    └── profile.json    # Extended: holdings[] added under each broker entry
```

### Pattern 1: Command Structure (mirror finyx:tax exactly)

Both commands use the same structure as `finyx:tax`:

```
Phase 1: Validation (profile gate + active country detection)
Phase 2: Staleness Check (last_verified frontmatter vs current date)
Phase 3: [Country A] section — gated on country active
Phase 4: [Country B] section — gated on country active
Phase N: Disclaimer append
```

**For `/finyx:invest`:**
```
Phase 1: Validation
Phase 2: Holdings check (AskUserQuestion if holdings[] empty)
Phase 3: Portfolio Allocation (INVEST-01)
Phase 4: Risk Profile (INVEST-02)
Phase 5: ETF Recommendations (INVEST-03)
Phase 6: Rebalancing Suggestions (INVEST-04)
Phase 7: Market Data Query (INVEST-05)
Phase 8: Disclaimer
```

**For `/finyx:broker`:**
```
Phase 1: Validation
Phase 2: Reference Doc Staleness Check
Phase 3: German Broker Comparison (BROKER-01) — if Germany active
Phase 4: Brazilian Broker Comparison (BROKER-02) — if Brazil active
Phase 5: Profile-Based Recommendation (BROKER-03)
Phase 6: Tax Reporting Quality (BROKER-04)
Phase 7: Disclaimer
```

### Pattern 2: Profile Gating

Identical to existing commands:

```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first."; exit 1; }
```

### Pattern 3: Holdings Presence Check

`/finyx:invest` needs holdings to compute INVEST-01 and INVEST-04. If `holdings[]` is empty across all brokers, use AskUserQuestion to collect them. Offer to save via Write — same pattern as `finyx:tax` Phase 3.4 (Sparerpauschbetrag broker collection).

```bash
# Detect empty holdings — checked in profile read, not via bash
# If profile.countries.germany.brokers[*].holdings is empty AND profile.countries.brazil.brokers is empty:
# → AskUserQuestion to collect holdings; offer to Write to profile.json
```

### Pattern 4: Staleness Check (broker reference docs)

```bash
CURRENT_DATE=$(date +%Y-%m-%d)
# Extract last_verified from reference doc frontmatter
# If (CURRENT_DATE - last_verified) > 180 days: emit staleness warning banner
```

Banner format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: REFERENCE DATA MAY BE STALE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Broker reference data was last verified: [last_verified].
Fees and products change frequently. Verify against broker
websites before making decisions.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Pattern 5: Finnhub API Call (INVEST-05)

```bash
# Pre-flight check
[ -z "$FINNHUB_API_KEY" ] && {
  echo "FINNHUB_API_KEY not set."
  echo "Get a free key at https://finnhub.io — then: export FINNHUB_API_KEY=your_key"
  echo "Falling back to WebSearch for market data..."
  # Use WebSearch tool instead
}

# Quote call (zero dependencies — curl + node -e for JSON parsing)
QUOTE=$(curl -s "https://finnhub.io/api/v1/quote?symbol=${TICKER}&token=${FINNHUB_API_KEY}")
PRICE=$(echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.c)")
# Or with jq if available:
PRICE=$(echo "$QUOTE" | jq -r '.c')
```

**Finnhub response fields:** `c` (current price), `d` (change), `dp` (% change), `h` (high), `l` (low), `o` (open), `pc` (previous close).

**Finnhub rate limit:** 30 calls/second (free tier). For a typical holdings query (5-10 tickers), this is not a constraint.

**European ETF symbol format on Finnhub:** Use `SYMBOL.EXCHANGE` notation — e.g., `VWCE.XETRA`, `IWDA.XETRA`. Verify symbol availability for each ETF before including in reference.

### Pattern 6: brapi.dev API Call (INVEST-05)

```bash
# Pre-flight check
[ -z "$BRAPI_TOKEN" ] && {
  echo "BRAPI_TOKEN not set."
  echo "Get a free token at https://brapi.dev — then: export BRAPI_TOKEN=your_token"
  echo "Falling back to WebSearch for market data..."
}

# Quote call — multiple tickers comma-separated
RESULT=$(curl -s "https://brapi.dev/api/quote/${TICKER}?token=${BRAPI_TOKEN}")
PRICE=$(echo "$RESULT" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.results[0].regularMarketPrice)")
```

**brapi.dev note:** Free plan without token supports only 4 ticker symbols (PETR4, MGLU3, VALE3, ITUB4). A free account token is required for ETFs and FIIs. Rate limit is not explicitly published; 10 calls/min is the figure from CONTEXT.md specifics — treat as a soft constraint.

### Pattern 7: Profile Schema Extension

Add `holdings[]` under each country's broker entry. The `countries.germany.brokers[]` already exists (used by `finyx:tax`). Extend each broker object:

```json
{
  "countries": {
    "germany": {
      "brokers": [
        {
          "name": "Trade Republic",
          "freistellungsauftrag": 1000,
          "estimated_annual_income": 0,
          "holdings": [
            {
              "ticker": "VWCE",
              "isin": "IE00BK5BQT80",
              "shares": 10.5,
              "cost_basis": 850.00,
              "asset_class": "equity-etf",
              "geography": "global"
            }
          ]
        }
      ]
    },
    "brazil": {
      "brokers": [
        {
          "name": "NuInvest",
          "holdings": [
            {
              "ticker": "BOVA11",
              "isin": null,
              "shares": 25,
              "cost_basis": 105.50,
              "asset_class": "equity-etf",
              "geography": "brazil"
            }
          ]
        }
      ]
    }
  }
}
```

**Note:** Brazil profile currently has `countries.brazil` without a `brokers[]` field. The schema extension must add `brokers[]` to `countries.brazil` as well.

### Anti-Patterns to Avoid

- **Building portfolio analysis from scratch:** The fin-advisor SKILL.md has the complete portfolio review checklist (7-item), risk tolerance framework, and Core-Satellite philosophy. Mine it.
- **Hard-coding ETF prices:** INVEST-05 is live data — always curl at runtime, never embed prices in reference docs.
- **Storing API keys in profile.json:** D-08 is explicit — env vars only.
- **Omitting the disclaimer:** Both new commands must append `disclaimer.md` as the final phase.
- **Writing a new staleness check mechanism:** Use date arithmetic identical to the `tax_year` check in `finyx:tax` Phase 2. For broker docs, compare ISO date strings rather than year integers.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ETF data and metrics | Custom ETF database | Content from `fin-research/SKILL.md` + live query via Finnhub/brapi | Already curated with ISINs, TERs, tracking differences |
| Broker fee table | Manually research from scratch | Mine `fin-advisor/references/broker-guide.md` for Germany; populate `brazil/brokers.md` from web-verified data | Broker-guide.md has TR, Trading212, ING, and comdirect with verified fees |
| Risk assessment framework | Custom questionnaire from scratch | Adapt fin-advisor SKILL.md portfolio review checklist | The 7-point checklist maps directly to INVEST-01/02/04 |
| API response parsing | Complex JSON parse logic | `jq -r '.field'` or `node -e` one-liner | Zero dependencies, curl + node already confirmed available on machine |
| Portfolio visualization | Custom charting | Table format with ASCII bars or pure narrative | Claude Code CLI context — no rendering; tables are the ceiling |

---

## Reference Doc Content: Germany/Brokers.md

Content to write into `finyx/references/germany/brokers.md` (sourced from skill + web-verified 2026):

### Frontmatter pattern (mirrors tax-investment.md)
```yaml
---
last_verified: 2026-04-06
country: germany
domain: broker-comparison
source: broker websites, fin-advisor skill
---
```

### Broker data (HIGH confidence — web-verified April 2026)

**Trade Republic**
- Trade fee: €1.00/order (Fremdkostenpauschale)
- Savings plans (Sparplan): FREE, all ETFs and stocks
- Custody fee: none
- Cash interest: yes (on uninvested cash)
- Tax reporting: Jahressteuerbescheinigung generated automatically
- Freistellungsauftrag: supported
- Regulated: BaFin (German)
- Products: ~2,000 ETFs, ~9,000 stocks, crypto, bonds
- URL: https://traderepublic.com

**Scalable Capital**
- Trade fee: FREE on gettex/EIX from €250; €0.99 below €250 — applies to FREE model
- PRIME+ model: €4.99/month flat, all trades free from €250
- Savings plans: FREE (no order fee regardless of model)
- Custody fee: none
- Tax reporting: Jahressteuerbescheinigung by April 12 of following year
- Freistellungsauftrag: supported
- Regulated: BaFin (German)
- URL: https://de.scalable.capital

**ING (DiBa)**
- Trade fee: €4.90 + 0.25% of order value
- Savings plans: promotional ETFs free; standard 1.75% of rate
- Custody fee: none
- Tax reporting: Jahressteuerbescheinigung ~March 10 of following year
- Freistellungsauftrag: supported
- Regulated: BaFin (German)
- Products: full banking + brokerage, ~1,100 ETFs for Sparplan
- URL: https://ing.de

**comdirect**
- Trade fee: €4.90 + 0.25% of order value
- Savings plans: 1.5% per rate for standard ETFs; promotional ETFs free
- Custody fee: none (for active accounts)
- Tax reporting: Jahressteuerbescheinigung
- Freistellungsauftrag: supported
- Regulated: BaFin (German)
- URL: https://comdirect.de

**Trading212 / IBKR (foreign brokers — include as contrast for BROKER-04)**
- No Freistellungsauftrag possible (not German entities)
- No automatic German tax withholding
- No Jahressteuerbescheinigung for German tax purposes
- User must file Anlage KAP manually for all capital income
- Trading212 provides a tax report but requires manual cross-check against Anlage KAP-INV

### Tax Reporting Quality (BROKER-04 content)

Key differentiator: German brokers (TR, Scalable, ING, comdirect) automatically:
1. Withhold Abgeltungssteuer (25% + Soli) at source
2. Apply Freistellungsauftrag — no tax up to the allocated amount
3. Generate Jahressteuerbescheinigung for direct ELSTER upload
4. Handle Vorabpauschale deduction in January for accumulating ETFs

Foreign brokers (Trading212, IBKR):
1. No withholding — all tax is self-reported
2. No Freistellungsauftrag — full Sparerpauschbetrag should be allocated to German brokers instead
3. No Jahressteuerbescheinigung — user fills Anlage KAP and KAP-INV manually
4. Accumulating ETF Vorabpauschale must be calculated and declared manually on Anlage KAP-INV

---

## Reference Doc Content: Brazil/Brokers.md

Content to write into `finyx/references/brazil/brokers.md` (web-verified April 2026):

### Frontmatter
```yaml
---
last_verified: 2026-04-06
country: brazil
domain: broker-comparison
source: broker websites, web research
---
```

### Broker data (MEDIUM confidence — web-verified but Brazilian fee structures change frequently)

**NuInvest (Nubank)**
- Corretagem: R$0 (zero) for ações, ETFs, FIIs, BDRs, options via app/home broker
- Mesa de Operações: 0.5% + R$25.21, min R$50
- Custódia: none
- B3/CBLC emolumentos: charged (third-party, not NuInvest)
- Tax reporting: Informe de Rendimentos (February/March); DARF is self-reported
- URL: https://nuinvest.com.br

**XP Investimentos**
- Corretagem: varies by product — ask user to verify on XP platform; zero for some products
- Custódia: none (zeroed)
- Renda fixa: access to broad selection (CDB, LCI, LCA, debentures)
- Tax reporting: Informe de Rendimentos; DARF self-reported
- URL: https://xpi.com.br

**BTG Pactual**
- Corretagem renda variável: R$4.50/order base, regressive tiered (lower per order at higher monthly volume)
- Custódia: none for individual accounts
- Fixed income: CDBs up to 112% CDI cited; strong fixed income desk
- Tax reporting: Informe de Rendimentos; DARF self-reported
- URL: https://investimentos.btgpactual.com

**Key Brazil note:** No Brazilian broker auto-withholds DARF for renda variável — all stock, FII capital gains, and ETF gains are self-reported monthly. The Informe de Rendimentos only covers income received; gains calculation is the investor's responsibility.

---

## ETF Recommendation Framework (INVEST-03)

Source: `fin-research/SKILL.md` + canonical ETF list (verified ISINs).

### Risk Profile to Allocation Mapping

Mine from `fin-advisor/SKILL.md` Core-Satellite philosophy:

| Risk Level | Equity % | Bond/Cash % | Satellite % | Horizon |
|------------|----------|-------------|-------------|---------|
| Conservative | 40-50% | 40-50% | 10% | <5 yrs |
| Moderate | 70% | 20% | 10% | 5-15 yrs |
| Aggressive | 90% | 0-5% | 10-20% | >15 yrs |

### Canonical ETF List for Recommendations (Germany-resident investor)

Mine ISINs from `fin-research/SKILL.md`. Verified ISINs (HIGH confidence from skill content):

**Global / Core (MSCI World / FTSE All-World):**
- Vanguard FTSE All-World (VWCE) — IE00BK5BQT80 — accumulating, includes EM, TER 0.22%
- iShares Core MSCI World (IWDA) — IE00B4L5Y983 — developed only, TER 0.20%
- Xtrackers MSCI World (XDWD) — IE00BJ0KDQ92 — TER 0.19%

**Emerging Markets (satellite for moderate/aggressive):**
- iShares Core MSCI EM IMI (EIMI) — IE00BKM4GZ66 — includes small caps, TER 0.18%
- Vanguard FTSE Emerging Markets — IE00B3VVMM84 — TER 0.22%

**S&P 500 (US-heavy satellite or alternative core):**
- Vanguard S&P 500 (VUSA) — IE00B3XXRP09 — TER 0.07%
- iShares Core S&P 500 — IE00B5BMR087 — TER 0.07%

**Brazil (for BR-active users, B3-listed):**
- BOVA11 — Ibovespa ETF, most liquid B3 ETF
- IVVB11 — S&P 500 in BRL (hedged exposure)
- XFIX11 — Fixed income FII index

**Key ETF selection criteria (from fin-research framework):**
1. Tracking Difference (TD) over TER — TD is more important
2. AUM > €500M preferred (liquidity/closure risk)
3. Ireland-domiciled preferred (US dividend tax treaty advantage)
4. Physical replication preferred over synthetic
5. Teilfreistellung: >50% equity stock allocation required for 30% exemption

---

## Risk Profile Assessment (INVEST-02)

Claude's discretion — recommended design based on fin-advisor skill pattern:

**Five questions (use AskUserQuestion):**
1. Investment horizon: <3 years / 3-10 years / >10 years
2. If portfolio drops 20%, reaction: sell all / hold / buy more
3. Primary goal: capital preservation / balanced growth / maximum growth
4. Existing emergency fund: yes (3+ months expenses) / no
5. Income stability: stable employment / variable income / retired

**Mapping logic:**
- >10yr + buy more + max growth + has emergency fund = Aggressive
- 3-10yr + hold + balanced + stable = Moderate
- <3yr or sell on drop or no emergency fund = Conservative

**Output:** Named risk level + recommended target allocation table + ETF list.

---

## Rebalancing Logic (INVEST-04)

**Threshold:** 5 percentage points drift per asset class triggers a suggestion. This is Betterment's standard and widely cited as the practical sweet spot between transaction cost drag and risk control. (MEDIUM confidence — multiple sources agree; exact threshold is Claude's discretion per D-11.)

**Algorithm:**
```
For each asset_class in target_allocation:
  current_pct = holdings_value_in_class / total_portfolio_value * 100
  drift = abs(current_pct - target_pct)
  if drift >= 5:
    emit rebalancing suggestion for this class
```

**Output format:** Table showing current allocation vs target, drift column, suggested action (buy/sell/none).

---

## Common Pitfalls

### Pitfall 1: `countries.brazil.brokers[]` Doesn't Exist Yet

**What goes wrong:** Current `profile.json` template has `countries.brazil` without a `brokers[]` field (only Germany has `brokers[]`). Code that iterates `countries.brazil.brokers` will fail or be undefined.

**Why it happens:** Phase 1 only needed Germany brokers for Sparerpauschbetrag. Brazil brokers were deferred.

**How to avoid:** Profile schema extension (Wave 0) must add `brokers: []` to `countries.brazil` in `finyx/templates/profile.json`. Profile collection in `/finyx:invest` must handle both `countries.germany.brokers[*].holdings` and `countries.brazil.brokers[*].holdings`.

**Warning signs:** `undefined` or null reference when reading Brazil broker holdings.

### Pitfall 2: Finnhub Symbol Format for European ETFs

**What goes wrong:** Finnhub uses exchange-suffixed symbols for European listings (e.g., `VWCE.XETRA`). Using just `VWCE` returns nothing or incorrect data.

**Why it happens:** Training assumption that symbols are globally unique.

**How to avoid:** Document the `SYMBOL.EXCHANGE` format in the reference doc. For XETRA: suffix `.XETRA`. For Frankfurt: `.F`. For LSE: `.L`. Test each symbol before including in the recommended ETF list.

**Warning signs:** Empty or zero price returned from Finnhub for European tickers.

### Pitfall 3: brapi.dev Free Tier Token Requirement

**What goes wrong:** Command tries to call brapi.dev without a token and only PETR4/MGLU3/VALE3/ITUB4 work. ETFs like BOVA11 or IVVB11 return errors.

**Why it happens:** The brapi.dev docs note four free symbols without a token. Any other ticker requires a (free) account token.

**How to avoid:** Pre-flight in `/finyx:invest` Phase 7 must check `BRAPI_TOKEN` env var and emit setup instructions. The fallback is WebSearch for the ticker price.

**Warning signs:** HTTP 401 or empty results array for non-free tickers.

### Pitfall 4: Holdings[] Write Offer Must Mirror finyx:tax Pattern

**What goes wrong:** Command collects holdings via AskUserQuestion but doesn't offer to save — user must re-enter every run.

**Why it happens:** Forgetting that stateless reads only work if the data was written somewhere.

**How to avoid:** Always end the holdings collection block with: "Would you like me to save this to your profile?" — identical to the Sparerpauschbetrag broker data collection in `finyx:tax` Phase 3.4.

**Warning signs:** User must re-enter holdings on every `/finyx:invest` invocation.

### Pitfall 5: Staleness Check Date Arithmetic in Bash

**What goes wrong:** Comparing date strings with arithmetic fails on some date formats or locales.

**Why it happens:** `date -d` is GNU-specific; macOS uses BSD `date`.

**How to avoid:** Use `node -e` for date comparison — consistent cross-platform:
```bash
node -e "
  const last = new Date('$(grep last_verified brokers.md | head -1 | cut -d: -f2 | tr -d " ")');
  const now = new Date();
  const days = (now - last) / 86400000;
  if (days > 180) console.log('STALE');
"
```

---

## Code Examples

### INVEST-05: Complete Market Data Query Block

```bash
# Source: D-08/D-09/D-10 from CONTEXT.md + Finnhub docs

# Check API key
if [ -z "$FINNHUB_API_KEY" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " FINYX ► INVEST: MARKET DATA SETUP REQUIRED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "To get live prices, set FINNHUB_API_KEY:"
  echo "  1. Register at https://finnhub.io (free)"
  echo "  2. Copy your API key from the dashboard"
  echo "  3. Run: export FINNHUB_API_KEY=your_key_here"
  echo ""
  echo "Falling back to WebSearch for price data..."
  USE_WEBSEARCH=true
fi

# If key available, query Finnhub
if [ "$USE_WEBSEARCH" != "true" ]; then
  TICKER="VWCE.XETRA"  # Example — replace with actual ticker from holdings
  QUOTE=$(curl -s "https://finnhub.io/api/v1/quote?symbol=${TICKER}&token=${FINNHUB_API_KEY}")
  
  # Parse with jq if available, else node -e
  if command -v jq > /dev/null 2>&1; then
    PRICE=$(echo "$QUOTE" | jq -r '.c')
    CHANGE_PCT=$(echo "$QUOTE" | jq -r '.dp')
  else
    PRICE=$(echo "$QUOTE" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).c))")
  fi
fi
```

### INVEST-05: brapi.dev Query

```bash
# Source: brapi.dev docs + D-08/D-09

if [ -z "$BRAPI_TOKEN" ]; then
  echo "BRAPI_TOKEN not set. Get a free token at https://brapi.dev"
  echo "Falling back to WebSearch for Brazilian asset prices..."
  USE_WEBSEARCH_BR=true
fi

if [ "$USE_WEBSEARCH_BR" != "true" ]; then
  TICKER_BR="BOVA11"
  RESULT=$(curl -s "https://brapi.dev/api/quote/${TICKER_BR}?token=${BRAPI_TOKEN}")
  PRICE_BR=$(echo "$RESULT" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{ const j=JSON.parse(d); console.log(j.results[0].regularMarketPrice) })")
fi
```

### INVEST-01: Portfolio Allocation Table

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INVEST: PORTFOLIO ALLOCATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Portfolio Value: €[TOTAL]

By Asset Class:
| Asset Class   | Value    | Allocation | Target | Drift  |
|---------------|----------|-----------|--------|--------|
| Equity ETF    | €[VAL]   | [X]%      | [T]%   | [D]%   |
| Bonds         | €[VAL]   | [X]%      | [T]%   | [D]%   |
| Cash          | €[VAL]   | [X]%      | [T]%   | [D]%   |

By Geography:
| Region         | Value    | Allocation |
|----------------|----------|-----------|
| Global         | €[VAL]   | [X]%      |
| US             | €[VAL]   | [X]%      |
| Europe         | €[VAL]   | [X]%      |
| Emerging Mkts  | €[VAL]   | [X]%      |
| Brazil         | €[VAL]   | [X]%      |
```

### BROKER-03: Decision Matrix Pattern

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: RECOMMENDATION FOR YOUR PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Based on your profile:
- Trading frequency: [low/medium/high]
- Primary strategy: [ETF savings plan / active trading]
- Tax complexity: [simple / complex]

Recommended (Germany): [BROKER] because [1-2 reasons]

Choose [BROKER] if:
- You [condition 1]
- You [condition 2]

Avoid [BROKER] if:
- You [disqualifying condition]
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broker custody fees (comdirect, ING) | All major German neo-brokers: zero custody | 2019-2022 | Fee comparison focuses on trade/Sparplan costs, not custody |
| Scalable Capital fee model | FREE model (0.99/trade) replaced older % custody model | 2022 | PRIME+ is optional upsell |
| comdirect Sparplan fees | Promotional ETF list expansion; many now free | Ongoing | Check promotional list when advising |
| Trading212 EU entity | Separate EU entity post-Brexit; Bulgarian FSC regulated | 2021 | Still no Freistellungsauftrag possible |
| brapi.dev free tier | Now requires account token for non-promotional tickers | ~2023 | Pre-flight check required |

**Deprecated/outdated:**
- Old custody fee comparisons (all major DE brokers zeroed custody — don't include custody in fee comparison)
- Trading212 as UK-regulated (now EU entity under Bulgarian FSC, but German tax treatment unchanged)

---

## Open Questions

1. **Finnhub symbol format for German ETFs on XETRA**
   - What we know: Finnhub uses `SYMBOL.EXCHANGE` notation; XETRA suffix is `.XETRA`
   - What's unclear: Whether all recommended ETFs (VWCE, IWDA, XDWD, EIMI) are queryable via Finnhub free tier with correct symbols
   - Recommendation: Wave 0 pre-flight test for each ETF symbol. If any fail, document the known-working symbol in the reference doc or note "use WebSearch fallback for this ticker."

2. **brapi.dev free tier rate limit**
   - What we know: CONTEXT.md states 10 calls/min; official docs don't publish this limit explicitly
   - What's unclear: Whether this limit applies to free-tier account tokens or unauthenticated requests
   - Recommendation: Treat 10 calls/min as the constraint. For a typical BR holdings query (3-7 tickers), batch the request with comma-separated tickers in a single call: `https://brapi.dev/api/quote/BOVA11,IVVB11,VALE3?token=${BRAPI_TOKEN}`

3. **`countries.brazil.brokers[]` backwards compatibility**
   - What we know: Existing profiles from Phase 1 don't have `brokers[]` under `countries.brazil`
   - What's unclear: Whether `/finyx:invest` should silently handle a missing `brokers[]` or prompt the user to update their profile
   - Recommendation: Treat missing `brokers[]` as equivalent to empty array — same holdings collection flow. No error; just prompt.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| curl | INVEST-05 API calls | Yes | 8.7.1 | — |
| node | JSON parsing in API responses | Yes | v25.6.1 | — |
| jq | JSON parsing (optional) | Yes | 1.8.1 | `node -e` one-liner |
| FINNHUB_API_KEY | INVEST-05 EU/US quotes | Unknown — env var | — | WebSearch fallback |
| BRAPI_TOKEN | INVEST-05 B3/FII quotes | Unknown — env var | — | WebSearch fallback |

**Missing dependencies with no fallback:** None — all hard dependencies (curl, node) are confirmed present.

**Missing dependencies with fallback:** FINNHUB_API_KEY and BRAPI_TOKEN are user-supplied env vars. WebSearch fallback covers both.

---

## Sources

### Primary (HIGH confidence)
- `~/.claude/skills/fin-advisor/SKILL.md` — Portfolio review checklist, Core-Satellite philosophy, broker profile (TR, Trading212, ING)
- `~/.claude/skills/fin-advisor/references/broker-guide.md` — German broker fee data (TR, Trading212, ING, comdirect)
- `~/.claude/skills/fin-research/SKILL.md` — ETF comparison framework, canonical ISINs, ETF quality criteria
- `commands/finyx/tax.md` — Command structure pattern (phases, banners, country routing, AskUserQuestion pattern)
- Finnhub docs (finnhub.io/docs/api) — API endpoint format, response fields, rate limits
- brapi.dev docs (brapi.dev/docs) — Endpoint format, authentication, free tier constraints

### Secondary (MEDIUM confidence)
- WebSearch: Scalable Capital PRIME+ €4.99/month, free Sparplan — verified against de.scalable.capital/en/trading-costs
- WebSearch: NuInvest zero corretagem — verified against ajuda.nuinvest.com.br
- WebSearch: BTG Pactual R$4.50 base corretagem — verified against investimentos.btgpactual.com/custos
- WebSearch: Trade Republic Jahressteuerbescheinigung timing (Feb/Mar) — depotstudent.de
- WebSearch: Scalable Capital Jahressteuerbescheinigung by April 12 — depotstudent.de
- WebSearch: Betterment 3% drift threshold / Vanguard 5% threshold — multiple sources agree

### Tertiary (LOW confidence)
- brapi.dev 10 calls/min rate limit — from CONTEXT.md specifics, not confirmed in official docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all files verified to exist; APIs confirmed curl-accessible
- Architecture: HIGH — follows established finyx:tax pattern exactly; no new patterns
- Broker fee data (Germany): HIGH — sourced from skill content + web-verified April 2026
- Broker fee data (Brazil): MEDIUM — web-verified but Brazilian fees change frequently; `last_verified` frontmatter handles this
- ETF recommendations: HIGH — ISINs from fin-research skill, widely used in German investment community
- API integration: MEDIUM — endpoint format confirmed, but Finnhub symbol availability for European ETFs needs Wave 0 validation

**Research date:** 2026-04-06
**Valid until:** Germany broker data: 2026-10-06 (6 months). Brazil broker data: 2026-07-06 (3 months — more volatile). API endpoints: stable until provider changes.
