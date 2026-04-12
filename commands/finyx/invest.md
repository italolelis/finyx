---
name: finyx:invest
description: Portfolio analysis — allocation breakdown, risk profiling, ETF recommendations, rebalancing, and live market data
allowed-tools:
  - Read
  - Bash
  - Write
  - WebFetch
  - AskUserQuestion
---

<objective>

Deliver a full portfolio health check and personalized investment advisory based on the user's financial profile.

This command:
1. Reads `.finyx/profile.json` and detects which countries are active (Germany / Brazil)
2. Checks for holdings in the profile — collects them interactively if empty (INVEST-01 data source)
3. Breaks down the portfolio by asset class, geography, and broker (INVEST-01)
4. Assesses the user's risk profile via a 5-question questionnaire if not already set (INVEST-02)
5. Recommends specific ETFs matched to the user's risk profile, with ISINs and TERs (INVEST-03)
6. Suggests rebalancing actions when any asset class has drifted 5+ percentage points from target (INVEST-04)
7. Queries live price data for a specific ticker via Finnhub (EU/US) or brapi.dev (B3/FIIs) with WebSearch fallback (INVEST-05)
8. Appends the full legal disclaimer

Output is conversational advisory text plus structured tables. No files are written unless the user consents to saving holdings or risk tolerance to profile.json.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
@.finyx/profile.json

</execution_context>

<process>

## Phase 1: Validation

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Read `.finyx/profile.json`** and extract:
- `identity.cross_border` — cross-border flag
- `identity.family_status` — "single" or "married"
- `countries.germany.tax_class` — null means Germany not active
- `countries.germany.brokers` — array of broker objects with optional holdings[]
- `countries.brazil.ir_regime` — null means Brazil not active
- `countries.brazil.brokers` — array of broker objects with optional holdings[]
- `goals.risk_tolerance` — null means risk questionnaire not yet completed
- `goals.investment_horizon` — years (0 = not set)
- `goals.primary_goals` — array of goal strings

**Determine active countries:**
- Germany active if: `countries.germany.tax_class != null`
- Brazil active if: `countries.brazil.ir_regime != null`
- Cross-border if: `identity.cross_border == true`

**If neither country is active:**
```
ERROR: No country data found in your profile.

Run /finyx:profile to complete the country-specific sections
(German tax class or Brazilian IR regime must be set).
```
Stop here.

## Phase 2: Holdings Check

**Collect all holdings from active countries:**
- Germany active: gather `countries.germany.brokers[*].holdings[]`
- Brazil active: gather `countries.brazil.brokers[*].holdings[]`
- Combine into a single working list of all holdings across all brokers

**If all holdings[] arrays are empty or absent across all active brokers:**

Use AskUserQuestion to collect holdings interactively:

```
To analyze your portfolio, I need to know what you currently hold.

For each holding I need:
  - Ticker symbol (e.g., VWCE, BOVA11, AAPL)
  - ISIN if available (e.g., IE00BK5BQT80) — optional for B3 assets
  - Number of shares/units
  - Average cost per share in local currency (EUR for German holdings, BRL for Brazilian)
  - Asset class: equity-etf / bond-etf / reit-etf / stock / fii / fixed-income
  - Geography: global / us / europe / emerging-markets / brazil / germany

Which broker holds your first position — and what is it?
```

Collect holdings one broker at a time. For each broker:
1. Ask broker name
2. If the broker name is not one of the reference-doc brokers (Trade Republic, Scalable Capital, ING, comdirect, NuInvest, XP Investimentos, BTG Pactual, Trading212, IBKR), note: "I don't have reference data for [broker]. For a full fee comparison including your broker, run /finyx:broker — it can research any broker live."
3. Ask for each holding (ticker, ISIN, shares, cost_basis, asset_class, geography)
4. Ask "Do you have another holding at this broker?" until done
5. Ask "Do you have another broker account?"

After collecting all holdings, offer to save to `.finyx/profile.json`:

```
Would you like me to save your holdings to your profile so you don't need
to re-enter them next time? I'll add them under the appropriate broker entries
in countries.germany.brokers[] or countries.brazil.brokers[].
```

If yes, update the relevant `brokers[].holdings[]` arrays in `.finyx/profile.json` via Write.

**If holdings exist, proceed with the collected data.**

## Phase 3: Portfolio Allocation

*Requires at least one holding to be present.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > INVEST: PORTFOLIO ALLOCATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Calculate total portfolio value:**
- For each holding: position_value = shares × cost_basis
- Total = sum of all position values across all brokers
- Note: Using cost basis as value proxy (no live price data yet). Run Phase 7 for current prices.

**3.1 Breakdown by Asset Class:**

Sum position values grouped by `asset_class` field.

| Asset Class | Value | Allocation % |
|-------------|-------|-------------|
| equity-etf | [sum] | [%] |
| bond-etf | [sum] | [%] |
| reit-etf | [sum] | [%] |
| stock | [sum] | [%] |
| fii | [sum] | [%] |
| fixed-income | [sum] | [%] |
| **TOTAL** | **[total]** | **100%** |

Only show rows where the asset class is present.

**3.2 Breakdown by Geography:**

Sum position values grouped by `geography` field.

| Geography | Value | Allocation % |
|-----------|-------|-------------|
| global | [sum] | [%] |
| us | [sum] | [%] |
| europe | [sum] | [%] |
| emerging-markets | [sum] | [%] |
| brazil | [sum] | [%] |
| germany | [sum] | [%] |
| **TOTAL** | **[total]** | **100%** |

Only show rows where the geography is present.

**3.3 Breakdown by Broker:**

Sum position values grouped by broker name.

| Broker | Value | Allocation % |
|--------|-------|-------------|
| [name] | [sum] | [%] |
| **TOTAL** | **[total]** | **100%** |

**3.4 Portfolio Notes:**

- If any single asset class or geography exceeds 80%: flag as concentration risk
- If equity allocation is 0%: note the portfolio has no equity exposure
- If no geographic diversification (single geography >90%): note home-country bias

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 4: Risk Profile Assessment

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > INVEST: RISK PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Check if risk_tolerance is already set:**

If `goals.risk_tolerance` is set (not null and not empty string), use that value and display:

```
Risk profile from your profile: [risk_tolerance]
(To retake the assessment, clear goals.risk_tolerance in your profile.json)
```

Skip to target allocation table output.

**If risk_tolerance is not set, run the 5-question assessment via AskUserQuestion:**

Ask each question sequentially:

**Question 1 — Investment Horizon:**
```
1. What is your investment horizon?
   A) Less than 3 years
   B) 3 to 10 years
   C) More than 10 years
```

**Question 2 — Reaction to Drawdown:**
```
2. If your portfolio dropped 20% in one month, what would you do?
   A) Sell everything to stop further losses
   B) Hold and wait for recovery
   C) Buy more — a dip is an opportunity
```

**Question 3 — Primary Goal:**
```
3. What is your primary investment goal?
   A) Capital preservation — protect what I have
   B) Balanced growth — moderate returns with moderate risk
   C) Maximum growth — highest returns, comfortable with volatility
```

**Question 4 — Emergency Fund:**
```
4. Do you have an emergency fund covering at least 3 months of expenses?
   A) Yes
   B) No
```

**Question 5 — Income Stability:**
```
5. How would you describe your income stability?
   A) Stable (permanent employment, civil servant, regular salary)
   B) Variable (freelancer, commission-based, business owner)
   C) Retired or living off investments
```

**Mapping logic — determine risk profile:**

Conservative (if ANY of these apply):
- Q1: Less than 3 years
- Q2: Sell everything
- Q4: No emergency fund

Aggressive (ALL of these apply):
- Q1: More than 10 years
- Q2: Buy more
- Q3: Maximum growth
- Q4: Yes (has emergency fund)

Moderate: all other combinations

Display result:

```
Risk Profile Assessment Result: [CONSERVATIVE / MODERATE / AGGRESSIVE]

[Brief explanation tied to their answers — e.g., "Your short investment
horizon of under 3 years calls for capital preservation over growth."]
```

**Target allocation table by risk profile:**

Conservative:
| Asset Class | Target % |
|-------------|---------|
| Equity ETFs | 40% |
| Bond ETFs | 50% |
| Cash / Fixed-Income | 10% |

Moderate:
| Asset Class | Target % |
|-------------|---------|
| Equity ETFs | 70% |
| Bond ETFs | 20% |
| Satellite (REITs/EM) | 10% |

Aggressive:
| Asset Class | Target % |
|-------------|---------|
| Equity ETFs | 90% |
| Satellite (EM/Sector) | 10% |

**Offer to save risk_tolerance to profile:**
```
Would you like me to save your risk profile (Conservative / Moderate / Aggressive)
to your profile.json? This way future commands can use it without re-running the questionnaire.
```

If yes, update `goals.risk_tolerance` in `.finyx/profile.json` via Write.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 5: ETF Recommendations

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > INVEST: ETF RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Recommend ETFs based on the risk profile from Phase 4 (Conservative / Moderate / Aggressive).

**ETF selection criteria applied:**
- Tracking Difference over TER as primary quality metric
- AUM >500M EUR preferred (liquidity, fund continuity)
- Ireland-domiciled preferred (US dividend withholding tax treaty)
- Physical replication preferred (transparency, no counterparty risk)
- For Germany: accumulating variants preferred (defers distribution tax, more efficient)

### 5.1 Conservative Portfolio Recommendations

**Core equity allocation (40%):**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| Vanguard FTSE All-World Acc (VWCE) | IE00BK5BQT80 | 0.22% | 4,000+ stocks global, accumulating, Ireland-domiciled, 30% Teilfreistellung eligible |
| iShares Core MSCI World (IWDA) | IE00B4L5Y983 | 0.20% | 1,400+ developed market stocks, accumulating, Ireland-domiciled, 30% Teilfreistellung eligible |

**Core bond allocation (50%):**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| iShares Core Global Aggregate Bond (AGGG) | IE00B3F81409 | 0.10% | Global investment-grade bonds, currency-hedged variant available |
| Vanguard Global Aggregate Bond (VAGF) | IE00BG47KB92 | 0.10% | Broad global bond exposure, accumulating |

**Cash/Fixed-Income (10%):** Hold in high-yield savings account or short-term bond ETF per local market conditions.

**Germany-specific notes:**
- VWCE and IWDA qualify as Aktienfonds (>50% equity) → 30% Teilfreistellung applies
- Bond ETFs typically qualify as 0% Teilfreistellung — full Abgeltungssteuer rate applies
- Accumulating ETFs incur Vorabpauschale in January — maintain a cash buffer at your broker

**Brazil-specific notes (if Brazil active):**

| ETF | B3 Ticker | Key Notes |
|-----|-----------|-----------|
| iShares Ibovespa (BOVA11) | BOVA11 | Brazil equity index, most liquid B3 ETF, IR 15% on capital gains |
| iShares S&P 500 (IVVB11) | IVVB11 | US equity exposure via B3, hedged to BRL |
| iShares Fixed Income (XFIX11) | XFIX11 | Brazilian government bonds, conservative allocation |

### 5.2 Moderate Portfolio Recommendations

**Core equity allocation (70%):**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| Vanguard FTSE All-World Acc (VWCE) | IE00BK5BQT80 | 0.22% | Primary core holding — global market in one fund |
| iShares Core MSCI World (IWDA) | IE00B4L5Y983 | 0.20% | Alternative core — developed markets only (no EM) |

**Bond allocation (20%):**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| iShares Core Global Aggregate Bond (AGGG) | IE00B3F81409 | 0.10% | Diversification, dampens volatility |

**Satellite allocation (10%):**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| iShares Core MSCI EM IMI (EIMI) | IE00BKM4GZ66 | 0.18% | Emerging markets tilt for additional growth potential |
| iShares Core MSCI Europe (IMAE) | IE00B4K48X80 | 0.12% | European equity satellite if underweight Europe |

**Germany-specific notes:**
- VWCE includes EM — using VWCE as core makes a separate EM ETF optional (reduces overlap)
- EIMI qualifies as Aktienfonds (>50% equity) → 30% Teilfreistellung eligible
- Recommend VWCE as the single-fund core for simplicity; add EIMI only if EM tilt is intentional

**Brazil-specific notes (if Brazil active):**

| ETF | B3 Ticker | Key Notes |
|-----|-----------|-----------|
| iShares Ibovespa (BOVA11) | BOVA11 | Core Brazil equity holding |
| iShares S&P 500 (IVVB11) | IVVB11 | US exposure satellite from B3 |

### 5.3 Aggressive Portfolio Recommendations

**Core equity allocation (90%):**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| Vanguard FTSE All-World Acc (VWCE) | IE00BK5BQT80 | 0.22% | Global core — broadest diversification |
| iShares Core MSCI World (IWDA) | IE00B4L5Y983 | 0.20% | Alternative: developed markets only, slightly lower cost |

**Satellite allocation (10%) — pick based on conviction:**

| ETF | ISIN | TER | Key Notes |
|-----|------|-----|-----------|
| iShares Core MSCI EM IMI (EIMI) | IE00BKM4GZ66 | 0.18% | EM tilt for higher growth potential |
| iShares MSCI World Small Cap (WSML) | IE00BF4RFH31 | 0.35% | Small-cap satellite for size premium |
| iShares Core MSCI Europe (IMAE) | IE00B4K48X80 | 0.12% | Europe tilt if you believe in value rotation |

**Germany-specific notes:**
- All recommended ETFs are Ireland-domiciled and qualify for 30% Teilfreistellung (>50% equity)
- Aggressive allocation means higher Vorabpauschale impact — ensure broker cash buffer is adequate
- Consider tax-loss harvesting in December if any position is underwater (no German wash-sale rule)

**Brazil-specific notes (if Brazil active):**

| ETF | B3 Ticker | Key Notes |
|-----|-----------|-----------|
| iShares Ibovespa (BOVA11) | BOVA11 | Brazil equity core |
| iShares S&P 500 (IVVB11) | IVVB11 | US equity satellite |
| Small Cap FII basket | — | FII dividends exempt under Law 8,668/1993 baseline — check Law 15,270/2025 status |

**Important note on ETF availability:**
ETF availability varies by broker. Verify that your broker offers the recommended ISIN before acting. If a specific ETF is not available on your platform, search for an equivalent ETF using justETF.com (filter by index and domicile) or your broker's own ETF screener. Do not interpret any recommendation here as implying a specific broker carries that ETF. TERs can also change — always verify on the fund provider's website or justETF.com before investing.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 6: Rebalancing Suggestions

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > INVEST: REBALANCING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Compare the current allocation from Phase 3 against the target allocation from Phase 4.

**Drift threshold: 5 percentage points per asset class (industry-standard — Betterment/Vanguard approach)**

For each asset class in the target allocation:
- Calculate: drift = current% − target%
- If abs(drift) >= 5: emit a rebalancing suggestion
- Action: if drift > 0 → "TRIM" (overweight); if drift < 0 → "ADD" (underweight)
- If abs(drift) < 5: "HOLD"

**Output rebalancing table:**

| Asset Class | Current % | Target % | Drift | Action |
|-------------|----------|---------|-------|--------|
| equity-etf | [c%] | [t%] | [d%] | ADD / TRIM / HOLD |
| bond-etf | [c%] | [t%] | [d%] | ADD / TRIM / HOLD |
| ... | ... | ... | ... | ... |

**If no holdings exist:** State "No holdings found — add your positions to see rebalancing guidance."

**If no drift >= 5pp across any asset class:**
```
Portfolio is within tolerance (5pp drift threshold) across all asset classes.
No rebalancing action needed at this time.
```

**Rebalancing method guidance:**
- Prefer directing new contributions to underweight classes (avoids triggering taxable events)
- Only sell overweight positions if contribution-based rebalancing is not feasible within 6-12 months
- Germany: selling triggers Abgeltungssteuer — prefer rebalancing via new contributions
- Brazil: selling stocks above R$20k/month triggers DARF — plan timing accordingly

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 7: Market Data Query

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > INVEST: MARKET DATA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Ask the user via AskUserQuestion:**
```
Would you like to look up live market data for a specific ticker?
(Enter a ticker symbol like VWCE, BOVA11, AAPL — or type "no" to skip)
```

If user answers "no" or skips, continue to Phase 8.

**If user provides a ticker:**

```bash
TICKER="[user-provided ticker, uppercased]"
```

**Determine which API to use:**

Check if ticker matches B3 pattern — B3 tickers are typically 4 uppercase letters + 1-2 digits (e.g., BOVA11, PETR4, VALE3, IVVB11):

```bash
if echo "$TICKER" | grep -qE '^[A-Z]{3,4}[0-9]{1,2}(F)?$'; then
  MARKET="brazil"
else
  MARKET="international"
fi
```

### 7.1 International / European Ticker (Finnhub)

**European ETF symbol format:** Append `.XETRA` suffix for ETFs traded on Frankfurt XETRA exchange (e.g., VWCE → VWCE.XETRA, EIMI → EIMI.XETRA). For US-listed tickers, use the ticker as-is (e.g., AAPL, MSFT).

**Pre-flight API key check:**
```bash
if [ -z "$FINNHUB_API_KEY" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " FINNHUB_API_KEY not set — cannot query live data"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Get a free API key at: https://finnhub.io"
  echo "Then set it in your shell: export FINNHUB_API_KEY=your_key"
  echo "Free tier: 30 calls/second, no credit card required."
  echo ""
  echo "Falling back to WebSearch for market data on $TICKER..."
  # Use WebFetch to search for current price information
fi
```

If `FINNHUB_API_KEY` is set:
```bash
# For European ETFs, append .XETRA
TICKER_QUERY="${TICKER}"
# If ticker looks like a European ETF (e.g., VWCE, EIMI, IWDA, AGGG), append .XETRA
# User can also manually specify VWCE.XETRA directly

QUOTE=$(curl -s "https://finnhub.io/api/v1/quote?symbol=${TICKER_QUERY}&token=${FINNHUB_API_KEY}")

# Parse with jq if available, otherwise use node
PRICE=$(echo "$QUOTE" | jq -r '.c' 2>/dev/null || echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.c)")
CHANGE=$(echo "$QUOTE" | jq -r '.d' 2>/dev/null || echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.d)")
CHANGE_PCT=$(echo "$QUOTE" | jq -r '.dp' 2>/dev/null || echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.dp)")
DAY_HIGH=$(echo "$QUOTE" | jq -r '.h' 2>/dev/null || echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.h)")
DAY_LOW=$(echo "$QUOTE" | jq -r '.l' 2>/dev/null || echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.l)")
PREV_CLOSE=$(echo "$QUOTE" | jq -r '.pc' 2>/dev/null || echo "$QUOTE" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.pc)")
```

**Output price table:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 [TICKER_QUERY] — Live Quote (Finnhub)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Price:    [price]
Change:           [change] ([change_pct]%)
Day High:         [day_high]
Day Low:          [day_low]
Previous Close:   [prev_close]

Source: Finnhub.io — data may be delayed 15 minutes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If the Finnhub response has `c: 0` or is empty, the symbol may not be found on Finnhub. Suggest:
- For European ETFs: try appending `.XETRA` (e.g., type `VWCE.XETRA`)
- For US ETFs: use the ticker as-is without exchange suffix
- Use WebFetch to search for current pricing as fallback

### 7.2 Brazilian Ticker (brapi.dev)

**Pre-flight API token check:**
```bash
if [ -z "$BRAPI_TOKEN" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " BRAPI_TOKEN not set — cannot query live B3 data"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Get a free token at: https://brapi.dev"
  echo "Then set it in your shell: export BRAPI_TOKEN=your_token"
  echo "Free plan: supports ETFs and FIIs with account registration."
  echo ""
  echo "Falling back to WebSearch for market data on $TICKER..."
  # Use WebFetch to search for current B3 price information
fi
```

If `BRAPI_TOKEN` is set:
```bash
RESULT=$(curl -s "https://brapi.dev/api/quote/${TICKER}?token=${BRAPI_TOKEN}")

PRICE=$(echo "$RESULT" | jq -r '.results[0].regularMarketPrice' 2>/dev/null || echo "$RESULT" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.results[0].regularMarketPrice)")
CHANGE=$(echo "$RESULT" | jq -r '.results[0].regularMarketChange' 2>/dev/null || echo "$RESULT" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.results[0].regularMarketChange)")
CHANGE_PCT=$(echo "$RESULT" | jq -r '.results[0].regularMarketChangePercent' 2>/dev/null || echo "$RESULT" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.results[0].regularMarketChangePercent)")
DAY_HIGH=$(echo "$RESULT" | jq -r '.results[0].regularMarketDayHigh' 2>/dev/null || echo "$RESULT" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.results[0].regularMarketDayHigh)")
DAY_LOW=$(echo "$RESULT" | jq -r '.results[0].regularMarketDayLow' 2>/dev/null || echo "$RESULT" | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8'); const j=JSON.parse(d); console.log(j.results[0].regularMarketDayLow)")
```

**Output price table:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 [TICKER] — Live Quote (brapi.dev / B3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Price (BRL):   R$ [price]
Change:                R$ [change] ([change_pct]%)
Day High:              R$ [day_high]
Day Low:               R$ [day_low]

Source: brapi.dev — B3 market data, may be delayed 15 minutes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If brapi.dev returns an error or empty results, suggest checking the B3 ticker format and using WebFetch as fallback.

### 7.3 WebFetch Fallback

When API keys are not set, use WebFetch to retrieve current price information:

```
WebFetch query: "current price [TICKER] stock ETF today"
```

Present the price information found via web search, noting the source and that it may not be real-time.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 8: Disclaimer

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No country data in profile:**
```
ERROR: No country data found in your profile.
Your profile exists but neither Germany (tax_class) nor Brazil (ir_regime) is configured.
Run /finyx:profile to complete the country-specific sections.
```

**No holdings and user declines to enter them:**
```
No holdings data available. Portfolio analysis (Phases 3 and 6) will be skipped.
Risk profiling (Phase 4) and ETF recommendations (Phase 5) will still run.
```

**Finnhub API returns c: 0 or empty:**
```
Symbol [TICKER] returned no data from Finnhub.

For European ETFs traded on XETRA: try [TICKER].XETRA
For US stocks/ETFs: use the ticker as-is (e.g., AAPL, VOO)
For other exchanges: check https://finnhub.io/docs/api/supported-exchanges
```

**brapi.dev returns error:**
```
brapi.dev could not find [TICKER] on B3.

Verify the B3 ticker format — B3 tickers are 4 letters + 1-2 digits (e.g., BOVA11, PETR4).
Full B3 ticker list: https://brapi.dev/docs
```

</error_handling>

<notes>

## Holdings Data Source

Holdings are read from `.finyx/profile.json` under `countries.[country].brokers[].holdings[]`. To update holdings:
- Edit `.finyx/profile.json` directly, or
- Re-run `/finyx:invest` — if holdings are present, it reads them; if empty, it prompts interactively

## API Keys

Market data (Phase 7) requires:
- `FINNHUB_API_KEY` — for EU/US stocks and ETFs. Free key at https://finnhub.io
- `BRAPI_TOKEN` — for B3 stocks, FIIs, and ETFs. Free token at https://brapi.dev

Neither key is stored in `profile.json`. Set them in your shell profile (`~/.zshrc`, `~/.bashrc`):
```bash
export FINNHUB_API_KEY=your_key_here
export BRAPI_TOKEN=your_token_here
```

## European ETF Symbol Format

Finnhub requires the exchange suffix for European ETFs. Common formats:
- XETRA (Frankfurt): VWCE.XETRA, EIMI.XETRA, IWDA.XETRA, AGGG.XETRA
- London Stock Exchange: VWCE.L, IWDA.L

## Risk Assessment Re-Run

To retake the risk questionnaire, clear `goals.risk_tolerance` in your profile.json (set it to `null`), then re-run `/finyx:invest`.

## Cost Basis as Value Proxy

Portfolio allocation percentages in Phase 3 use cost basis (purchase price × shares) as a value proxy, since live prices require the Phase 7 API call. The allocation percentages will differ from current market-value percentages if positions have appreciated or declined significantly.

## Stateless Operation

This command reads holdings and risk tolerance from profile.json each run. No portfolio state files are created in `.finyx/`. All calculations are computed fresh on each invocation.

## Advisory Only

All recommendations are advisory. ETF TERs, fund sizes, and broker availability change over time. Verify against current sources (justETF.com, brapi.dev) before investing. See the full disclaimer in Phase 8.

</notes>
