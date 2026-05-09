---
name: finyx-help
description: Finyx help and status utility — list all available commands, check project status and workflow progress, and update Finyx to the latest version from npm. Use when the user asks what Finyx can do, needs help with commands, or wants to check status.
allowed-tools:
  - Read
  - Write
  - Bash
  - WebFetch
  - AskUserQuestion
---

<objective>

Provide comprehensive help, project status, and update functionality for Finyx:

1. **Help** — Display the complete Finyx command reference with workflow guide, command details, key concepts, and getting-started guide
2. **Status** — Show current project status including workflow phase, location analysis progress, shortlist summary, and recommended next action
3. **Update** — Check and apply Finyx plugin updates from npm, displaying the changelog

This skill handles all three utility operations. The active sub-command is determined by the invocation:
- `/finyx:help` → Show command reference
- `/finyx:status` → Show project status
- `/finyx:update` → Check for and apply updates

Output is reference/status text only. No advisory analysis is performed. No files are written except during update.

</objective>

<execution_context>

${CLAUDE_SKILL_DIR}/references/disclaimer.md
@.finyx/profile.json
<!-- Project-local fast-path. Authoritative profile path is resolved at runtime via scripts/resolve-profile.sh. See scripts/README.md. -->

</execution_context>

<process>

## Phase 1: Determine Sub-Command

Detect which sub-command was invoked:
- If invoked as `/finyx:help` → proceed to **Phase 2: Help Output**
- If invoked as `/finyx:status` → proceed to **Phase 3: Status**
- If invoked as `/finyx:update` → proceed to **Phase 4: Update**

---

## Phase 2: Help Output

Output ONLY the reference content below. Do NOT add:
- Project-specific analysis
- File context
- Next-step suggestions beyond what's in the reference

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX — Personal Finance Advisor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Finyx is a personal finance advisor built as Claude Code slash-commands. It analyzes
real estate investments, provides tax guidance, investment portfolio analysis, pension
planning, insurance comparison, and a unified financial health dashboard — all backed
by your financial profile.

### Workflow

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
     ▼
┌─────────┐
│ PENSION │
└─────────┘
     │
 Retirement
  Planning
     │
     ▼
┌──────────┐
│INSURANCE │
└──────────┘
     │
 PKV/GKV
 Advisor
     │
     ▼
┌─────────┐
│INSIGHTS │
└─────────┘
     │
 Financial
  Health
```

### Quick Start

```bash
# 1. Complete your financial profile (required first step)
/finyx:profile

# 2a. Get personalized investment tax guidance (any time after profile)
/finyx:tax

# 2b. Get portfolio analysis and ETF recommendations
/finyx:invest

# 2c. Compare brokers and get a profile-based recommendation
/finyx:broker

# 2d. Get pension planning and retirement projection
/finyx:pension

# 2e. Get PKV vs GKV insurance comparison
/finyx:insurance

# 2f. Get unified financial health dashboard
/finyx:insights

# 3. Add property documents to properties/[location]/
#    (price lists, exposés, calculation docs)

# 4. Research the location
/finyx:scout kassel

# 5. Analyze units and calculate metrics
/finyx:analyze kassel

# 6. Apply criteria and create shortlist
/finyx:filter kassel

# 7. Compare shortlisted properties
/finyx:compare

# 8. Run stress tests (optional)
/finyx:stress-test

# 9. Generate advisor briefing
/finyx:report --lang pt
```

### Commands

#### Setup and Status

| Command | Description |
|---------|-------------|
| `/finyx:profile` | Complete financial profile — must run first |
| `/finyx:status` | Show current state and next action |
| `/finyx:update` | Update Finyx to the latest version |
| `/finyx:help` | This reference |

#### Tax Advisory

| Command | Description |
|---------|-------------|
| `/finyx:tax` | Investment tax advisor — German and Brazilian tax guidance |

#### Investment Advisory

| Command | Description |
|---------|-------------|
| `/finyx:invest` | Portfolio analysis, ETF recommendations, rebalancing, and live market data |
| `/finyx:broker` | Broker fee comparison and profile-based recommendation with live market discovery |

#### Pension Advisory

| Command | Description |
|---------|-------------|
| `/finyx:pension` | Pension advisor — Riester/Rürup/bAV (DE) and PGBL/VGBL (BR) guidance with cross-country projection |

#### Insurance Advisory

| Command | Description |
|---------|-------------|
| `/finyx:insurance` | PKV vs GKV decision advisor — cost projections, family impact, tax implications |

#### Financial Health

| Command | Description |
|---------|-------------|
| `/finyx:insights` | Unified financial health dashboard — income allocation, tax efficiency, net worth, goal tracking |

#### Research

| Command | Description |
|---------|-------------|
| `/finyx:scout [location]` | Research location viability (Erbpacht, transport, market) |
| `/finyx:rates` | Research current mortgage interest rates |

#### Analysis

| Command | Description |
|---------|-------------|
| `/finyx:analyze [location]` | Extract units, calculate metrics, rank by yield |
| `/finyx:filter [location]` | Apply criteria and create shortlist |
| `/finyx:compare` | Side-by-side comparison of all shortlisted units |
| `/finyx:stress-test` | Run stress scenarios (0% appreciation, rate hike, vacancy) |

#### Output

| Command | Description |
|---------|-------------|
| `/finyx:report` | Full advisor briefing (Markdown) |
| `/finyx:report --short` | 1-page executive summary |
| `/finyx:report --pdf` | Generate PDF report |
| `/finyx:report --short --pdf` | 1-page PDF summary |
| `/finyx:report --lang pt` | Generate in Portuguese |

### Command Details

#### `/finyx:profile`

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

#### `/finyx:tax`

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

#### `/finyx:invest`

Get portfolio analysis and ETF recommendations based on your financial profile.

**Covers:**
- Portfolio allocation by asset class, geography, and broker
- Risk profile assessment (Conservative / Moderate / Aggressive) based on your profile
- ETF recommendations with ISINs and TERs for your target allocation
- Rebalancing suggestions when drift exceeds 5 percentage points from target
- Live market data lookup (Finnhub for EU/US equities, brapi.dev for B3/FIIs)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

#### `/finyx:broker`

Compare broker fees and get a profile-based broker recommendation.

**Covers:**
- German broker fee comparison (live discovery + baseline reference data)
- Brazilian broker fee comparison (live discovery + baseline reference data)
- New broker detection via web search (discovers current market entrants)
- Profile-based recommendation considering trading frequency, investment strategy, and tax simplicity preference
- Tax reporting quality: German brokers (automatic Abgeltungssteuer withholding, Freistellungsauftrag, Jahressteuerbescheinigung) vs foreign brokers (manual Anlage KAP + Anlage KAP-INV)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

#### `/finyx:pension`

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

#### `/finyx:insurance`

Get personalized PKV vs GKV health insurance comparison.

**Covers:**
- GKV cost calculation (income-based, employer share, Zusatzbeitrag)
- PKV cost projection based on age, health, and selected tariff tier
- Family impact analysis (Familienversicherung cost-benefit vs PKV per-person)
- Tax implications (PKV Basisabsicherung §10 EStG deduction, employer contribution limits)
- Long-term projections (10/20/30-year scenarios, age-based PKV growth vs GKV income-tracking)
- PKV provider research (tariffs, Beitragsrückerstattung, Selbstbeteiligung, Anwartschaft)
- Expat considerations (Versicherungspflichtgrenze, EU portability, Anwartschaft coverage)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

#### `/finyx:insights`

Get a unified financial health dashboard across all advisor domains.

**Covers:**
- Income allocation analysis (needs/wants/savings/investments/debt vs country-adjusted benchmarks)
- Tax efficiency scoring (Sparerpauschbetrag, Vorabpauschale, DARF, PGBL per country with € gaps)
- Net worth snapshot (assets vs liabilities from profile data)
- Goal pace tracking ("at current rate, target X reached in Y months")
- Top-5 actionable recommendations ranked by € annual impact
- Cross-advisor intelligence (pension ↔ tax ↔ investment links)
- Emergency fund check (6-month threshold for cross-border users)

**Requires:** Completed financial profile (run `/finyx:profile` first)

---

#### `/finyx:scout [location]`

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

#### `/finyx:analyze [location]`

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

#### `/finyx:filter [location]`

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

#### `/finyx:compare`

Side-by-side comparison of all shortlisted properties.

**Displays:**
- Unified comparison table (price, yield, cashflow, profit)
- Winners by metric
- Liquidity impact
- Decision framework ("Choose X if...")

---

#### `/finyx:stress-test`

Run stress scenarios on shortlisted properties.

**Scenarios:**
1. **Zero appreciation** — Property values stay flat
2. **Rate hike** — +2% interest at refinancing
3. **Extended vacancy** — 3 months every 2 years
4. **Combined worst case** — All factors together

**Creates:** `.finyx/analysis/STRESS-TEST.md`

---

#### `/finyx:rates`

Research current mortgage interest rates in Germany.

**Sources:** Dr. Klein, Baufi24, Interhyp, Finanztip

**Outputs:**
- Current top rates by fixed period
- Comparison with developer rates
- Potential savings calculation

**Creates:** `.finyx/research/market/RATES-[date].md`

---

#### `/finyx:report [--short] [--pdf] [--lang XX]`

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

#### `/finyx:status`

Show current analysis state and recommended next action. See Phase 3 below for full output format.

---

#### `/finyx:update`

Update Finyx to the latest version from npm. See Phase 4 below for full update process.

---

### Key Concepts

#### Erbpacht (Ground Lease)

Ground lease where you own the building but lease the land. Finyx auto-detects
Erbpacht indicators and **excludes properties with undisclosed ground rent**.

**Why critical:** Hidden Erbbauzins (ground rent) can cost €1,000–5,000/year.

#### Sonder-AfA §7b

German special depreciation for new construction:
- **Years 1-4:** 5% special + 2% regular = 7% annual depreciation
- **Years 5-10:** 2% regular depreciation only

Finyx models both phases separately — the "good period" and the "bleeding period".

#### Spekulationsfrist

German 10-year holding period for tax-free capital gains. Finyx's default
strategy: buy → rent → sell tax-free at year 10.

#### Nebenkosten

German acquisition costs (~8% of purchase price):
- Grunderwerbsteuer (transfer tax): 3.5–6.5% by state
- Notary fees: ~1.5%
- Land registry: ~0.5%

### File Structure

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

### Supported Countries

| Country | Status | Key Features |
|---------|--------|--------------|
| Germany | **Full** | Sonder-AfA, Spekulationsfrist, Nebenkosten, Erbpacht detection, PKV/GKV, Abgeltungssteuer |
| Brazil | **Full** | IR filing, DARF, come-cotas, FII exemptions, PGBL/VGBL, INSS |

### Core Methodology

Finyx follows 10 mandatory rules for real estate analysis:

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

### Getting Help

| Resource | Description |
|----------|-------------|
| `/finyx:help` | This reference |
| `/finyx:status` | Current state and next action |
| `/finyx:update` | Update to latest version |
| [GitHub Issues](https://github.com/italolelis/immo/issues) | Bug reports and feature requests |

---

## Phase 3: Status

### Step 1: Check Project Exists

```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh" 2>/dev/null) || { echo "NO_PROFILE"; }
```

**If NO_PROFILE:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► NO PROFILE FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No Finyx financial profile found in current directory.

To start: /finyx:profile
```
Exit.

### Step 2: Read State Files

Read:
- `$PROFILE_PATH` — Financial profile (resolved by gate check; @-include is a project-local fast-path only)
- `.finyx/STATE.md` — Current state

### Step 3: Scan Locations

```bash
ls -d properties/*/ 2>/dev/null | xargs -I {} basename {}
```

For each location, check:
- `.finyx/research/locations/[location].md` exists → SCOUTED
- `.finyx/analysis/[location]/UNITS.md` exists → ANALYZED
- `.finyx/analysis/[location]/SHORTLIST.md` exists → FILTERED

### Step 4: Display Status

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: [PROJECT_NAME]
Phase:   [CURRENT_PHASE]
Updated: [LAST_UPDATE]

───────────────────────────────────────────────────────
 INVESTOR PROFILE
───────────────────────────────────────────────────────

Income:       €[TOTAL]/year
Tax Rate:     [RATE]%
Available:    €[ASSETS]
Criteria:     ≥[YIELD]% yield, ≤€[PRICE], [SIZE]m²

───────────────────────────────────────────────────────
 LOCATIONS
───────────────────────────────────────────────────────

| Location | Status | Units | Shortlisted |
|----------|--------|-------|-------------|
| kassel   | ✅ FILTERED | 86 | 3 |
| munich   | 🔍 SCOUTED | - | - |
| taucha   | ❌ EXCLUDED | - | Quality |

───────────────────────────────────────────────────────
 SHORTLIST
───────────────────────────────────────────────────────

1. kassel/0.18 - €272k - 3.16% - 47.8m²
2. kassel/4.1  - €377k - 2.95% - 62.7m² - Parking ✅
3. kassel/3.7  - €401k - 3.20% - 73.8m²

───────────────────────────────────────────────────────
 NEXT ACTION
───────────────────────────────────────────────────────

[CONTEXTUAL RECOMMENDATION]

Examples:
- "Run /finyx:scout munich to research Munich location"
- "Run /finyx:analyze kassel to calculate metrics"
- "Run /finyx:compare to compare shortlisted units"
- "Run /finyx:report to generate advisor briefing"
```

### Step 5: Determine Next Action

Logic:
1. If no locations in properties/ → "Add property folders to properties/"
2. If locations exist but none scouted → "/finyx:scout [first-location]"
3. If scouted but not analyzed → "/finyx:analyze [location]"
4. If analyzed but not filtered → "/finyx:filter [location]"
5. If multiple locations filtered → "/finyx:compare"
6. If compared but no report → "/finyx:report"
7. If report exists → "Ready to decide. Review report or /finyx:stress-test"

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all output.

---

## Phase 4: Update

### Step 0: Check Profile Exists

```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

### Step 1: Check Current Version

```bash
CURRENT=$(npm list -g finyx-cc --depth=0 2>/dev/null | grep finyx-cc | sed 's/.*@//')
echo "Current version: ${CURRENT:-not installed globally}"
```

Also check local installation:
```bash
[ -f ~/.claude/finyx/package.json ] && cat ~/.claude/finyx/package.json | grep '"version"'
```

### Step 2: Check Latest Version

```bash
LATEST=$(npm view finyx-cc version)
echo "Latest version: $LATEST"
```

### Step 3: Compare Versions

If current equals latest:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► ALREADY UP TO DATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're running the latest version: v[VERSION]
```

If update available, continue to Step 4.

### Step 4: Fetch Changelog

Fetch release notes from GitHub:
```
https://api.github.com/repos/italolelis/immo/releases/latest
```

Extract and display:
- Version
- Release date
- Release notes/body

### Step 5: Update

Run the installer to update:
```bash
npx finyx-cc@latest
```

### Step 6: Confirm Update

```bash
NEW_VERSION=$(npm list -g finyx-cc --depth=0 2>/dev/null | grep finyx-cc | sed 's/.*@//')
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► UPDATED SUCCESSFULLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated: v[OLD] → v[NEW]

What's New in v[NEW]:
─────────────────────────────────────────────────────
[CHANGELOG CONTENT]
─────────────────────────────────────────────────────

Run /finyx:help to see available commands.
```

### Step 7: Disclaimer

Append the legal disclaimer from the loaded disclaimer.md reference at the end of this output.

</process>

<error_handling>

### Status errors

- **No profile found:** Display NO_PROFILE banner and exit (see Phase 3 Step 1)

### Update errors

- **npm not found:** "Please install Node.js and npm first."
- **Network error:** "Could not reach npm registry. Check your internet connection."
- **Permission denied:** "Try running with sudo or fix npm permissions."
- **No profile found:** "No financial profile found. Run /finyx:profile first."

</error_handling>
