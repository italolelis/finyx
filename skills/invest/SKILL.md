---
name: finyx-invest
description: Investment portfolio advisor — ETF analysis, asset allocation, risk profiling, rebalancing, DCA vs lump sum, broker comparison (Germany + Brazil), tax-aware guidance, and live market data
allowed-tools:
  - Read
  - Bash
  - Write
  - WebFetch
  - WebSearch
  - AskUserQuestion
disable-model-invocation: true
---

<objective>

Deliver a full portfolio health check, personalized investment advisory, and broker comparison based on the user's financial profile.

This skill:
1. Reads `.finyx/profile.json` and detects which countries are active (Germany / Brazil)
2. Checks for holdings in the profile — collects them interactively if empty (INVEST-01 data source)
3. Breaks down the portfolio by asset class, geography, and broker (INVEST-01)
4. Assesses the user's risk profile via a 5-question questionnaire if not already set (INVEST-02)
5. Recommends specific ETFs matched to the user's risk profile, with ISINs and TERs (INVEST-03)
6. Suggests rebalancing actions when any asset class has drifted 5+ percentage points from target (INVEST-04)
7. Queries live price data for a specific ticker via Finnhub (EU/US) or brapi.dev (B3/FIIs) with WebFetch fallback (INVEST-05)
8. Compares brokers for Germany and Brazil with profile-based recommendation (BROKER)
9. Explains tax reporting quality differences between broker types
10. Appends the full legal disclaimer

Output is conversational advisory text plus structured tables. No files are written unless the user consents to saving holdings, risk tolerance, or broker preferences to profile.json.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
${CLAUDE_SKILL_DIR}/references/germany/brokers.md
${CLAUDE_SKILL_DIR}/references/brazil/brokers.md
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

**Determine mode from user invocation:**

The user may invoke this skill for:
- **Portfolio + Investment advisory** (default) — phases 2 through 8
- **Broker comparison** — phases 9 through 12
- **Both** — all phases

If the user says "broker" or "compare brokers" without portfolio context, skip to Phase 9.
Otherwise run the full investment advisory flow (phases 2–8) first, then ask if the user wants broker comparison.

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
2. If the broker name is not one of the reference-doc brokers (Trade Republic, Scalable Capital, ING, comdirect, NuInvest, XP Investimentos, BTG Pactual, Trading212, IBKR), note: "I don't have reference data for [broker]. For a full fee comparison including your broker, I can research it live in the Broker Comparison section."
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

**DCA vs Lump Sum guidance:**

When the user asks or has new funds to invest, provide:
- **DCA (Dollar-Cost Averaging):** Invest fixed amounts at regular intervals. Reduces timing risk but may underperform in rising markets. Best for: investors anxious about market entry timing, variable income earners, investment horizons under 5 years.
- **Lump Sum:** Invest the full amount immediately. Historically outperforms DCA ~67% of the time (Vanguard research) due to time-in-market advantage. Best for: received windfalls, patient investors, long horizons (>10 years), aggressive risk profiles.
- **Recommendation:** If the amount represents less than 10% of the existing portfolio, lump sum. If it represents a major new position (>20% of portfolio), consider 3–6 month DCA to reduce sequence-of-returns risk.

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
  echo "Falling back to WebFetch for market data on $TICKER..."
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
  echo "Falling back to WebFetch for market data on $TICKER..."
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

## Phase 8: Disclaimer (Investment Advisory)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 9: Broker Comparison Entry

*This phase runs when the user invokes broker comparison, or after Phase 8 if the user wants broker guidance.*

Ask via AskUserQuestion (if not already invoked in broker-only mode):
```
Would you like a broker comparison and recommendation based on your profile?
```

If yes (or if broker comparison was the original request), continue to Phase 10.
If no, end the session.

## Phase 10: Broker Reference Staleness Check

For each broker reference doc loaded (`germany/brokers.md` and `brazil/brokers.md`), extract `last_verified` from the YAML frontmatter and check if it is more than 6 months old:

```bash
node -e "
  const last = new Date('LAST_VERIFIED_DATE');
  const now = new Date();
  const days = (now - last) / 86400000;
  if (days > 180) console.log('STALE');
  else console.log('OK');
"
```

If the document is STALE, emit this warning banner before any broker comparison output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > BROKER: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Broker reference data was last verified on [LAST_VERIFIED_DATE].
Broker fees and product offerings change frequently.
Verify all fee details against the broker websites listed
in this output before making any decisions.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Continue regardless — reference docs are a useful baseline even when flagged stale. Live discovery in Phase 11 supplements the baseline with current data.

**Profile broker check:**

Read `countries.germany.brokers[]` and `countries.brazil.brokers[]` from profile.json.

If the user already has broker entries in their profile, display them:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > BROKER: YOUR EXISTING BROKERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You already have these brokers in your profile:
- [broker_name] ([country])
```

Then use AskUserQuestion to ask:
```
Would you like to:
1. Compare your existing broker(s) against current market options
2. Explore new options only
3. Both — full comparison including your existing broker(s)
```

If the user has no broker entries in profile, proceed directly to Phase 11.

## Phase 11: Broker Discovery

### 11.1 German Broker Discovery

*Execute this section only if Germany is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > BROKER: GERMAN BROKERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Step 1: Load baseline data**

Use `germany/brokers.md` as the baseline broker set. These are verified reference entries.

**Step 2: Live WebSearch discovery**

Perform these two WebSearch queries to find current market entrants and updated offerings:
- `"best German brokers 2026 ETF Sparplan comparison"`
- `"neue Neobroker Deutschland 2026 BaFin"`

Merge the search results with the baseline data. Include ANY broker found via search that is:
- BaFin-regulated, OR
- Accessible to German residents (e.g., Revolut, moomoo, Smartbroker+, Finanzen.net Zero, Freedom24, etc.)

Do NOT limit the comparison to only the brokers listed in the reference doc.

**Step 3: Present unified comparison table**

Build a table from the merged baseline + web-discovered data:

| Broker | Trade Fee | Sparplan Fee | Custody | Regulated By |
|--------|-----------|--------------|---------|--------------|
| [all discovered brokers, one row each] |

For each broker discovered, also list key differentiators as bullet points with URL.

Add this note after the table:
```
Reference baseline from [last_verified date in germany/brokers.md]. Live search performed [today's date].
Always verify current fees on the broker's website before opening an account.
```

**Note:** All German-regulated brokers support Freistellungsauftrag and generate Jahressteuerbescheinigung automatically — see Phase 12 for tax reporting details.

### 11.2 Brazilian Broker Discovery

*Execute this section only if Brazil is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > BROKER: BRAZILIAN BROKERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Step 1: Load baseline data**

Use `brazil/brokers.md` as the baseline broker set.

**Step 2: Live WebSearch discovery**

Perform these two WebSearch queries:
- `"melhores corretoras Brasil 2026 ações ETF"`
- `"corretoras taxa zero Brasil 2026"`

Merge search results with the baseline. Include any broker accessible to Brazilian residents and CVM-regulated.

Do NOT limit the comparison to only the brokers listed in the reference doc.

**Step 3: Present unified comparison table**

| Broker | Corretagem (App) | Custódia | Strengths |
|--------|-----------------|----------|-----------|
| [all discovered brokers, one row each] |

Add this note after the table:
```
Reference baseline from [last_verified date in brazil/brokers.md]. Live search performed [today's date].
Always verify current fees on the broker's website before opening an account.
```

**Important note:** B3/CBLC emolumentos (exchange fees) are charged separately by B3 for all renda variável trades — these are NOT set by the broker and apply uniformly regardless of which broker you use.

**DARF reminder:** No Brazilian broker auto-withholds DARF for renda variável capital gains. You are fully responsible for calculating and paying DARF by the last business day of the following month.

## Phase 12: Profile-Based Broker Recommendation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > BROKER: RECOMMENDATION FOR YOUR PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use AskUserQuestion to collect the following (if not already inferable from profile):

**Question 1 — Trading frequency:**
```
How often do you trade?
1. Rarely (1–2 orders per month) — buy-and-hold or Sparplan
2. Regularly (weekly) — moderate active trading
3. Actively (daily or multiple times per week) — frequent trading
```

**Question 2 — Primary strategy:**
```
What is your primary investment approach?
1. ETF savings plan (Sparplan) — automated periodic purchases
2. Buy-and-hold — occasional purchases, long holding periods
3. Active trading — frequent buys and sells based on market moves
```

**Question 3 — Tax simplicity preference:**
```
How important is automatic tax handling to you?
1. Very important — I want my broker to handle withholding and reporting automatically
2. Nice-to-have — I prefer auto-handling but can manage it myself if needed
3. Not important — I am comfortable handling tax reporting manually
```

**Dynamic scoring — apply to ALL brokers discovered in Phase 11:**

For each broker, score it against the three answers using these criteria weights:

*Trading frequency (Q1) → fee structure fit:*
- Rarely → favor: zero or near-zero per-trade fee, free Sparplan; penalize: flat monthly fee
- Regularly → favor: competitive per-trade fee or moderate monthly flat; penalize: high per-trade fee
- Actively → favor: flat monthly rate (pays off at volume); penalize: per-trade fee above €2

*Primary strategy (Q2) → product/feature fit:*
- Sparplan → favor: free Sparplan execution, wide ETF Sparplan selection; penalize: no Sparplan support
- Buy-and-hold → favor: low per-trade cost, no custody fee; penalize: high inactivity or custody fees
- Active trading → favor: wide exchange access, professional tools; penalize: single-exchange brokers

*Tax simplicity (Q3) → compliance fit (Germany only):*
- Very important → favor: German-regulated broker (auto Abgeltungssteuer, Freistellungsauftrag, Jahressteuerbescheinigung); penalize: foreign broker (manual Anlage KAP)
- Nice-to-have → neutral on German vs foreign; note foreign broker overhead
- Not important → neutral; include foreign broker options without penalty

Rank all brokers by total score. Present top 2–3:

```
Recommended broker: [name]

Why this fits your profile:
- [Reason tied to Q1 — trading frequency and fee structure]
- [Reason tied to Q2 — strategy and product fit]
- [Reason tied to Q3 — tax handling preference]

Choose [broker] if:
- [Condition 1]
- [Condition 2]

Avoid [broker] if:
- [Condition 1]
- [Condition 2]
```

**Record broker preference:**

After the recommendation, ask via AskUserQuestion:

```
Would you like me to save your preferred broker(s) to your profile?
This helps other Finyx commands (like /finyx:invest) know where your accounts are.
```

If yes:
- Ask which broker(s) to save
- Update `countries.[country].brokers[]` in `.finyx/profile.json` via Write
- Only ADD new entries — do not overwrite or remove existing broker data in the array
- Each new entry uses the structure: `{ "name": "[broker_name]", "holdings": [] }`

## Phase 13: Tax Reporting Quality

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX > BROKER: TAX REPORTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### German tax reporting quality — German vs foreign broker

*Show this section only if Germany is active.*

| Tax Obligation | German Broker | Foreign Broker (non-German entity) |
|----------------|---------------|-------------------------------------|
| Abgeltungssteuer withholding | Automatic (26.375% at source) | None — investor self-reports |
| Freistellungsauftrag | Supported — Sparerpauschbetrag assigned | Not possible — non-German entity |
| Jahressteuerbescheinigung | Generated automatically | Not available |
| Vorabpauschale handling | Auto-deducted in January for accumulating ETFs | Investor calculates and declares manually on Anlage KAP-INV |

**Key recommendation:**
> If tax simplicity matters, use a German broker as your primary. If you also use a foreign broker, allocate your full Sparerpauschbetrag (Freistellungsauftrag) to your German broker(s) — you cannot assign it to foreign brokers.

**Foreign broker compliance overhead:**
Using a foreign broker as your sole German broker means you must:
1. Track all capital gains and dividends manually throughout the year
2. File Anlage KAP and Anlage KAP-INV every year regardless of gain level
3. Calculate Vorabpauschale manually for any accumulating ETFs held at the foreign broker
4. Verify no double-taxation with any foreign withholding credits

### Brazilian tax reporting quality

*Show this section only if Brazil is active.*

> All Brazilian brokers require self-reported DARF for renda variável capital gains. Unlike the German system, no Brazilian broker auto-withholds tax on stock, FII, or ETF capital gains.

Tax obligations are identical regardless of which Brazilian broker you use:
- **DARF (renda variável):** self-calculated and self-paid monthly — code 6015 for stocks/FIIs, code 3317 for day-trade
- **Informe de Rendimentos:** provided by all brokers in February/March — covers dividends and income received, NOT capital gains
- **Annual DIRPF:** you declare bens e direitos, rendimentos isentos (FII dividends), and rendimentos tributáveis (renda fixa interest)

There is no tax-handling quality difference between Brazilian brokers — your compliance obligations are the same regardless of which one you choose.

## Phase 14: Disclaimer (Broker Advisory)

Append the full legal disclaimer from the loaded `disclaimer.md` reference at the end of all broker advisory output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

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

This skill reads holdings and risk tolerance from profile.json each run. No portfolio state files are created in `.finyx/`. All calculations are computed fresh on each invocation.

## Broker Fees Change Frequently

Broker fees are verified at a point in time (see `last_verified` in the reference docs). The staleness check in Phase 10 warns automatically if the reference data is more than 6 months old. Reference docs are a useful baseline even when stale — live WebSearch in Phase 11 discovers brokers and fee updates beyond the baseline. Always verify current fees on the broker's website before opening an account.

## Broker Recommendation Is Criteria-Based, Not Hardcoded

The recommendation in Phase 12 scores all discovered brokers dynamically against the user's answers to the three questions. It does not map scenarios to specific broker names. New brokers found via WebSearch are scored on equal footing with baseline reference brokers — if a new market entrant offers better fee structure for the user's profile, it will rank accordingly.

## Country Routing for Broker Comparison

- Germany-only user: sees Phase 11.1 (DE discovery) + Phase 12 (recommendation) + Phase 13 (DE tax reporting only)
- Brazil-only user: sees Phase 11.2 (BR discovery) + Phase 12 (recommendation) + Phase 13 (BR tax note only)
- Cross-border user: sees Phase 11.1 + Phase 11.2 + Phase 12 + Phase 13 (both sections)

## Reference Data Staleness

The staleness check uses `node -e` for cross-platform date arithmetic (avoids GNU `date -d` vs macOS `date -j` incompatibility). The threshold is 180 days (approximately 6 months).

## Profile Broker Write

Phase 12 only appends to `countries.[country].brokers[]`. It never removes or overwrites existing entries. Existing holdings data inside broker objects is preserved.

## Advisory Only

All recommendations are advisory. ETF TERs, fund sizes, broker fees, and availability change over time. Verify against current sources (justETF.com, brapi.dev, broker websites) before investing. See the full disclaimer.

## Cross-Skill References

- Tax implications of investments (Abgeltungssteuer, Vorabpauschale, DARF) are covered here with sufficient depth for portfolio decisions. For detailed tax calculations including Sparerpauschbetrag optimization, run `/finyx:tax`.
- Insurance-related portfolio impacts (e.g., PKV vs GKV effect on disposable income for investments) are not covered here — run `/finyx:insurance` for insurance advisory.

</notes>
