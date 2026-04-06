---
name: finyx:help
description: Show available FINYX commands and usage guide
---

<objective>
Display the complete FINYX command reference.

Output ONLY the reference content below. Do NOT add:
- Project-specific analysis
- File context
- Next-step suggestions beyond what's in the reference
</objective>

<execution_context>
@~/.claude/finyx/references/disclaimer.md
</execution_context>

<reference>
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX — Personal Finance Advisor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

FINYX analyzes real estate investments systematically. It provides structured
workflows, consistent methodology, and professional reporting.

## Workflow

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ PROFILE │───▶│  SCOUT  │───▶│ ANALYZE │───▶│ FILTER  │───▶│ COMPARE │───▶│ REPORT  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │              │
 Financial      Research       Calculate       Apply        Side-by-side    Advisor
  Profile       Location       Metrics       Criteria      Comparison      Briefing
     │
     ▼
┌─────────┐
│   TAX   │
└─────────┘
     │
Investment
Tax Advisor
     │
     ▼
┌─────────┐
│ INVEST  │
└─────────┘
     │
Portfolio
 Advisor
     │
     ▼
┌─────────┐
│ BROKER  │
└─────────┘
     │
  Broker
Comparison
     │
     v
+---------+
| PENSION |
+---------+
     │
 Retirement
 Planning
```

## Quick Start

```bash
# 1. Complete your financial profile (required first step)
/finyx:profile

# 1b. Get personalized investment tax guidance (optional, any time after profile)
/finyx:tax

# 1c. Get portfolio analysis and ETF recommendations (optional, any time after profile)
/finyx:invest

# 1d. Compare brokers and get a profile-based recommendation (optional, any time after profile)
/finyx:broker

# 1e. Get pension planning and retirement projection (optional, any time after profile)
/finyx:pension

# 2. Add property documents to properties/[location]/
#    (price lists, exposés, calculation docs)

# 3. Research the location
/finyx:scout kassel

# 4. Analyze units and calculate metrics
/finyx:analyze kassel

# 5. Apply criteria and create shortlist
/finyx:filter kassel

# 6. Compare shortlisted properties
/finyx:compare

# 7. Run stress tests (optional)
/finyx:stress-test

# 8. Generate advisor briefing
/finyx:report --lang pt
```

## Commands

### Setup & Status

| Command | Description |
|---------|-------------|
| `/finyx:profile` | Complete financial profile — must run first |
| `/finyx:status` | Show current state and next action |
| `/finyx:update` | Update FINYX to the latest version |
| `/finyx:help` | This reference |

### Tax Advisory

| Command | Description |
|---------|-------------|
| `/finyx:tax` | Investment tax advisor — German and Brazilian tax guidance |

### Investment Advisory

| Command | Description |
|---------|-------------|
| `/finyx:invest` | Portfolio analysis, ETF recommendations, rebalancing, and live market data |
| `/finyx:broker` | Broker fee comparison and profile-based recommendation for German and Brazilian brokers |

### Pension Advisory

| Command | Description |
|---------|-------------|
| `/finyx:pension` | Pension advisor — Riester/Ruerup/bAV (DE) and PGBL/VGBL (BR) guidance with cross-country projection |

### Research

| Command | Description |
|---------|-------------|
| `/finyx:scout [location]` | Research location viability (Erbpacht, transport, market) |
| `/finyx:rates` | Research current mortgage interest rates |

### Analysis

| Command | Description |
|---------|-------------|
| `/finyx:analyze [location]` | Extract units, calculate metrics, rank by yield |
| `/finyx:filter [location]` | Apply criteria and create shortlist |
| `/finyx:compare` | Side-by-side comparison of all shortlisted units |
| `/finyx:stress-test` | Run stress scenarios (0% appreciation, rate hike, vacancy) |

### Output

| Command | Description |
|---------|-------------|
| `/finyx:report` | Full advisor briefing (Markdown) |
| `/finyx:report --short` | 1-page executive summary |
| `/finyx:report --pdf` | Generate PDF report |
| `/finyx:report --short --pdf` | 1-page PDF summary |
| `/finyx:report --lang pt` | Generate in Portuguese |

## Command Details

### `/finyx:profile`

Complete a financial profile interview through interactive flow. This is the mandatory first step — no other Finyx command runs without a completed profile.

**Gathers:**
- Residence country and nationality (cross-border detection)
- German tax class, church tax, income, and marginal rate (if Germany relevant)
- Brazilian IR regime and income (if Brazil relevant)
- Family status, risk tolerance, investment horizon, goals
- Liquid assets and monthly commitments

**Creates:**
- `.finyx/profile.json` — Financial profile
- `.finyx/STATE.md` — Analysis state tracking
- `properties/` — Folder for property documents
- `FINYX.md` — Project summary

---

### `/finyx:tax`

Get personalized investment tax guidance based on your financial profile.

**Routes by country (auto-detected from profile):**
- Germany active → Steuerklasse, Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung
- Brazil active → IR rates by asset type, DARF calculation, come-cotas, FII dividend exemption
- Cross-border → Both country sections plus DBA (DE–BR double taxation agreement) guidance

**Covers:**
- Steuerklassen I–VI explanation and recommendation
- Abgeltungssteuer breakdown (25% + Soli) with Günstigerprüfung eligibility check
- Sparerpauschbetrag (1,000/2,000 EUR allowance) tracking across brokers
- Vorabpauschale calculation for accumulating ETFs using current Basiszins
- Teilfreistellung rates by fund type (equity 30%, mixed 15%, real estate 60–80%)
- Brazilian IR rates, DARF codes 6015/3317, monthly deadlines
- Come-cotas for open-end funds (not FIIs, not ETFs)
- FII dividend exemption (Law 8,668/1993 + Law 15,270/2025 update)
- DBA residency tiebreaker and withholding credit for cross-border users

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

### `/finyx:invest`

Get portfolio analysis and ETF recommendations based on your financial profile.

**Covers:**
- Portfolio allocation by asset class, geography, and broker
- Risk profile assessment (Conservative / Moderate / Aggressive) based on your profile
- ETF recommendations with ISINs and TERs for your target allocation
- Rebalancing suggestions when drift exceeds 5 percentage points from target
- Live market data lookup (Finnhub for EU/US equities, brapi.dev for B3/FIIs)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

### `/finyx:broker`

Compare broker fees and get a profile-based broker recommendation.

**Covers:**
- German broker fee comparison (Trade Republic, Scalable Capital FREE and PRIME+, ING, comdirect)
- Brazilian broker fee comparison (NuInvest, XP Investimentos, BTG Pactual)
- Profile-based recommendation considering trading frequency, investment strategy, and tax simplicity preference
- Tax reporting quality: German brokers (automatic Abgeltungssteuer withholding, Freistellungsauftrag, Jahressteuerbescheinigung) vs foreign brokers (manual Anlage KAP + Anlage KAP-INV)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

### `/finyx:pension`

Get personalized pension planning guidance based on your financial profile.

**Routes by country (auto-detected from profile):**
- Germany active → Riester vs Rürup vs bAV comparison, Zulagen calculation, Sonderausgabenabzug estimate
- Brazil active → PGBL vs VGBL decision guide, progressive vs regressive IR regime comparison
- Cross-border → Both country sections plus combined retirement projection

**Covers:**
- Riester eligibility and Zulagen calculation (Grundzulage + Kinderzulage)
- Rürup Sonderausgabenabzug estimate based on income and marginal rate
- bAV Entgeltumwandlung tax and social security savings (with GRV tradeoff note)
- PGBL 12% income threshold and declaração completa requirement
- Progressive vs regressive regime with Law 14.803/24 deferral option
- Cross-country retirement projection (DE statutory + private + BR INSS, inflation-adjusted)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

### `/finyx:scout [location]`

Research a location for investment viability.

**Investigates:**
- Development details (name, developer, units, completion)
- **Erbpacht status** — CRITICAL, auto-excludes if undisclosed
- Public transport quality
- Parking necessity assessment
- Market conditions (rental demand, price trends)

**Creates:** `.finyx/research/locations/[location].md`

**Example:** `/finyx:scout kassel`

---

### `/finyx:analyze [location]`

Analyze all properties in a location folder.

**Process:**
1. Extract units from price lists (Excel/PDF)
2. Calculate metrics (yield, price/m², upfront costs)
3. Model cashflow for Years 1-4 (with Sonder-AfA) and Years 5-10
4. Project 10-year exit value and ROE

**Creates:**
- `.finyx/analysis/[location]/UNITS.md` — All extracted units
- `.finyx/analysis/[location]/RANKED.md` — Sorted by metrics

**Example:** `/finyx:analyze kassel`

---

### `/finyx:filter [location]`

Apply investor's criteria to create shortlist.

**Filters:**
- Minimum yield
- Maximum price
- Size range
- Parking requirement
- Floor exclusions

**Creates:**
- `.finyx/analysis/[location]/SHORTLIST.md` — Qualifying units
- `.finyx/analysis/[location]/EXCLUSIONS.md` — Excluded with reasons

**Example:** `/finyx:filter kassel`

---

### `/finyx:compare`

Side-by-side comparison of all shortlisted properties.

**Displays:**
- Unified comparison table (price, yield, cashflow, profit)
- Winners by metric
- Liquidity impact
- Decision framework ("Choose X if...")

---

### `/finyx:stress-test`

Run stress scenarios on shortlisted properties.

**Scenarios:**
1. **Zero appreciation** — Property values stay flat
2. **Rate hike** — +2% interest at refinancing
3. **Extended vacancy** — 3 months every 2 years
4. **Combined worst case** — All factors together

**Creates:** `.finyx/analysis/STRESS-TEST.md`

---

### `/finyx:rates`

Research current mortgage interest rates in Germany.

**Sources:** Dr. Klein, Baufi24, Interhyp, Finanztip

**Outputs:**
- Current top rates by fixed period
- Comparison with developer rates
- Potential savings calculation

**Creates:** `.finyx/research/market/RATES-[date].md`

---

### `/finyx:report [--short] [--pdf] [--lang XX]`

Generate advisor briefing document.

**Full Report (default):**
- Executive summary, investor profile, location analysis
- Units comparison, cashflow projections, tax benefits
- 10-year exit analysis, stress tests, decision framework
- Creates: `.finyx/output/BRIEFING-[date].md`

**Short Report (`--short`):**
- 1-page executive summary
- Top 5 units comparison table
- Recommendation with reasoning
- Key risks and mitigations
- 5 questions for your advisor
- Creates: `.finyx/output/SUMMARY-[date].md`

**PDF Output (`--pdf`):**
- Converts report to PDF for sharing with advisors
- Requires: pandoc, md-to-pdf, or mdpdf installed
- Creates: `.finyx/output/BRIEFING-[date].pdf`

**Languages:** `en` (default), `pt` (Portuguese), `de` (German)

**Examples:**
- `/finyx:report` — Full briefing (Markdown)
- `/finyx:report --pdf` — Full briefing as PDF
- `/finyx:report --short --pdf` — 1-page PDF summary
- `/finyx:report --short --pdf --lang pt` — Portuguese PDF summary

---

### `/finyx:status`

Show current analysis state and recommended next action.

**Displays:**
- Current workflow phase
- Investor profile summary
- Locations and their status
- Shortlisted properties
- Next recommended action

## Key Concepts

### Erbpacht (Ground Lease)

Ground lease where you own the building but lease the land. FINYX auto-detects
Erbpacht indicators and **excludes properties with undisclosed ground rent**.

**Why critical:** Hidden Erbbauzins (ground rent) can cost €1,000-5,000/year.

### Sonder-AfA §7b

German special depreciation for new construction:
- **Years 1-4:** 5% special + 2% regular = 7% annual depreciation
- **Years 5-10:** 2% regular depreciation only

FINYX models both phases separately — the "good period" and the "bleeding period".

### Spekulationsfrist

German 10-year holding period for tax-free capital gains. FINYX's default
strategy: buy → rent → sell tax-free at year 10.

### Nebenkosten

German acquisition costs (~8% of purchase price):
- Grunderwerbsteuer (transfer tax): 3.5-6.5% by state
- Notary fees: ~1.5%
- Land registry: ~0.5%

## File Structure

```
project/
├── FINYX.md                    # Project summary
├── properties/
│   └── [location]/            # Property documents (price lists, exposés)
│
└── .finyx/
    ├── profile.json           # Financial profile and criteria (created by /finyx:profile)
    ├── STATE.md               # Workflow state tracking
    │
    ├── research/
    │   ├── market/
    │   │   └── RATES-*.md     # Interest rate research
    │   └── locations/
    │       └── [location].md  # Location research
    │
    ├── analysis/
    │   ├── [location]/
    │   │   ├── UNITS.md       # All extracted units
    │   │   ├── RANKED.md      # Sorted by metrics
    │   │   ├── SHORTLIST.md   # Qualifying units
    │   │   └── EXCLUSIONS.md  # Excluded with reasons
    │   └── STRESS-TEST.md     # Stress test results
    │
    └── output/
        └── BRIEFING-*.md      # Generated reports
```

## Supported Countries

| Country | Status | Key Features |
|---------|--------|--------------|
| Germany | **Full** | Sonder-AfA, Spekulationsfrist, Nebenkosten, Erbpacht detection |
| Portugal | Planned | Golden Visa, NHR regime |
| Spain | Planned | — |
| Netherlands | Planned | — |

## Core Methodology

FINYX follows 10 mandatory rules:

1. **Independent Calculation** — Never trust developer marketing numbers
2. **Erbpacht First** — Always verify ground lease status
3. **Correct Tax Rate** — Use investor's actual marginal rate
4. **Two-Phase Cashflow** — Show Y1-4 and Y5-10 separately
5. **All Costs Included** — Nebenkosten, construction interest, management
6. **Conservative Assumptions** — 2% appreciation, 0% rent increase
7. **Stress Testing** — 0% appreciation, rate hikes, vacancy
8. **Parking Research** — Assess transport for each location
9. **Interest Rate Verification** — Compare to market rates
10. **Decision Framework** — Present trade-offs, let investor decide

## Updating FINYX

```bash
/finyx:update
```

Or manually:
```bash
npx finyx-cc@latest
```

## Getting Help

| Resource | Description |
|----------|-------------|
| `/finyx:help` | This reference |
| `/finyx:status` | Current state and next action |
| [GitHub Issues](https://github.com/italolelis/immo/issues) | Bug reports and feature requests |

</reference>
