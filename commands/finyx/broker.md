---
name: finyx:broker
description: Broker comparison — fee analysis and profile-based recommendation using live market discovery and reference baseline data
allowed-tools:
  - Read
  - Bash
  - Write
  - WebFetch
  - WebSearch
  - AskUserQuestion
---

<objective>

Deliver a profile-based broker recommendation with fee comparisons and tax reporting quality differences.

This command:
1. Reads `.finyx/profile.json` and detects which countries are active
2. Checks reference doc staleness (warns if older than 6 months — reference docs are baselines, not exhaustive lists)
3. Checks which brokers the user already uses (from profile) and displays them
4. For Germany: loads baseline reference data then performs live WebSearch to discover current brokers; merges into unified comparison
5. For Brazil: loads baseline reference data then performs live WebSearch to discover current brokers; merges into unified comparison
6. Collects trading frequency, strategy, and tax simplicity preference via AskUserQuestion
7. Scores all discovered brokers dynamically against user answers using criteria-based weighting
8. Offers to save preferred broker(s) back to profile
9. Explains tax reporting quality differences between German and foreign brokers

Output is conversational advisory text — all guidance includes the legal disclaimer.

</objective>

<execution_context>

@~/.claude/finyx/references/disclaimer.md
@~/.claude/finyx/references/germany/brokers.md
@~/.claude/finyx/references/brazil/brokers.md
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
- `countries.germany.brokers` — array of broker objects already in profile
- `countries.brazil.ir_regime` — null means Brazil not active
- `countries.brazil.brokers` — array of broker objects already in profile

**Determine active countries:**
- Germany active if: `countries.germany.tax_class != null`
- Brazil active if: `countries.brazil.ir_regime != null`

**If neither country is active:**
```
ERROR: No country data found in your profile.

Run /finyx:profile to complete the country-specific sections
(German tax class or Brazilian IR regime must be set).
```
Stop here.

## Phase 2: Reference Doc Staleness Check

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
 FINYX ► BROKER: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Broker reference data was last verified on [LAST_VERIFIED_DATE].
Broker fees and product offerings change frequently.
Verify all fee details against the broker websites listed
in this output before making any decisions.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Continue regardless — reference docs are a useful baseline even when flagged stale. Live discovery in Phase 3 and Phase 4 supplements the baseline with current data.

## Phase 2.5: Profile Broker Check

Read `countries.germany.brokers[]` and `countries.brazil.brokers[]` from profile.json.

If the user already has broker entries in their profile, display them:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: YOUR EXISTING BROKERS
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

If the user has no broker entries in profile, proceed directly to Phase 3 and/or Phase 4.

## Phase 3: German Broker Discovery

*Execute this phase only if Germany is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: GERMAN BROKERS
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

**Note:** All German-regulated brokers support Freistellungsauftrag and generate Jahressteuerbescheinigung automatically — see Phase 6 for tax reporting details.

## Phase 4: Brazilian Broker Discovery

*Execute this phase only if Brazil is active.*

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: BRAZILIAN BROKERS
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

## Phase 5: Profile-Based Recommendation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: RECOMMENDATION FOR YOUR PROFILE
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

**Dynamic scoring — apply to ALL brokers discovered in Phase 3 and/or Phase 4:**

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

## Phase 5.5: Record Broker Preference

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

If no, skip and continue.

## Phase 6: Tax Reporting Quality

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► BROKER: TAX REPORTING
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

## Phase 7: Disclaimer

Append the full legal disclaimer from the loaded `disclaimer.md` reference at the end of all advisory output:

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

</error_handling>

<notes>

## Broker Fees Change Frequently

Broker fees are verified at a point in time (see `last_verified` in the reference docs). The staleness check in Phase 2 warns automatically if the reference data is more than 6 months old. Reference docs are a useful baseline even when stale — live WebSearch in Phase 3 and Phase 4 discovers brokers and fee updates beyond the baseline. Always verify current fees on the broker's website before opening an account.

## Recommendation Is Criteria-Based, Not Hardcoded

The recommendation in Phase 5 scores all discovered brokers dynamically against the user's answers to the three questions. It does not map scenarios to specific broker names. New brokers found via WebSearch are scored on equal footing with baseline reference brokers — if a new market entrant offers better fee structure for the user's profile, it will rank accordingly.

## Country Routing

- Germany-only user: sees Phase 3 (DE discovery) + Phase 5 (recommendation) + Phase 6 (DE tax reporting only)
- Brazil-only user: sees Phase 4 (BR discovery) + Phase 5 (recommendation) + Phase 6 (BR tax note only)
- Cross-border user: sees Phase 3 + Phase 4 + Phase 5 + Phase 6 (both sections)

## Reference Data Staleness

The staleness check uses `node -e` for cross-platform date arithmetic (avoids GNU `date -d` vs macOS `date -j` incompatibility). The threshold is 180 days (approximately 6 months).

## Profile Broker Write

Phase 5.5 only appends to `countries.[country].brokers[]`. It never removes or overwrites existing entries. Existing holdings data inside broker objects is preserved.

</notes>
