# Finyx

An AI-powered personal finance advisor for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Tax optimization, investment portfolio analysis, pension planning, real estate investment analysis, and a unified financial insights dashboard — all through slash commands backed by specialist AI agents.

```
/finyx:profile     # Set up your financial profile
/finyx:tax         # Investment tax guidance (Germany + Brazil)
/finyx:invest      # Portfolio analysis, ETF recommendations, rebalancing
/finyx:broker      # Broker comparison with fee analysis
/finyx:pension     # Pension planning (Riester/Rürup/bAV + PGBL/VGBL)
/finyx:insights    # Unified financial health report with recommendations
```

## What it does

Finyx is a collection of Claude Code slash-commands and specialist AI agents that give integrated financial advice. Unlike siloed tools that only know one domain, Finyx knows your full financial picture — tax situation, investments, pensions, and real estate — and gives cross-domain recommendations.

**Key capabilities:**

- **Tax advisor** — German (Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung) and Brazilian (IR, DARF, come-cotas, FII exemptions) investment tax guidance
- **Investment advisor** — Portfolio analysis, risk profiling, ETF recommendations, rebalancing suggestions with live market data (Finnhub, brapi.dev)
- **Broker comparison** — DE + BR brokers with fee comparison and tax-reporting quality
- **Pension planning** — Riester/Rürup/bAV (Germany), PGBL/VGBL/INSS (Brazil), cross-country projection
- **Financial insights** — Unified health report with income allocation analysis, tax efficiency scoring, net worth snapshot, goal pace tracking, and ranked recommendations
- **Real estate analysis** — Location research, property analysis, comparison, stress testing, and advisor-ready reports
- **Cross-border support** — Built for expats with obligations in multiple jurisdictions (Germany + Brazil)

## Installation

Finyx is a Claude Code plugin. Install it with:

```bash
claude plugin add github:italolelis/finyx
```

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed on your machine.

## Quick start

```bash
# 1. Set up your financial profile
/finyx:profile

# 2. Get your financial health report
/finyx:insights

# 3. Dive into specific domains
/finyx:tax          # Tax optimization advice
/finyx:invest       # Portfolio recommendations
/finyx:pension      # Pension planning
/finyx:broker       # Broker comparison
```

## Commands

### Financial advisors

| Command | Description |
|---------|-------------|
| `/finyx:profile` | Interactive financial profile setup (income, tax, family, goals, risk tolerance) |
| `/finyx:tax` | Investment tax advisor — German and Brazilian tax guidance |
| `/finyx:invest` | Portfolio analysis, risk profiling, ETF recommendations, rebalancing |
| `/finyx:broker` | Broker comparison with fee analysis for DE + BR markets |
| `/finyx:pension` | Pension planning — Riester/Rürup/bAV (DE), PGBL/VGBL/INSS (BR) |
| `/finyx:insights` | Unified financial health report with ranked recommendations |

### Real estate analysis

| Command | Description |
|---------|-------------|
| `/finyx:scout [location]` | Research location (transport, market, Erbpacht) |
| `/finyx:analyze [location]` | Analyze properties — extract units, calculate metrics, rank |
| `/finyx:filter [location]` | Apply investment criteria and create shortlist |
| `/finyx:compare` | Side-by-side comparison of shortlisted properties |
| `/finyx:stress-test` | Run stress test scenarios on shortlisted properties |
| `/finyx:report` | Generate professional financial advisor briefing |
| `/finyx:rates` | Research current mortgage interest rates |

### Utility

| Command | Description |
|---------|-------------|
| `/finyx:status` | Show current analysis state and next actions |
| `/finyx:help` | Show command reference |
| `/finyx:update` | Update to latest version |

## How it works

Finyx is not an application — it's a set of Markdown prompt files that Claude Code interprets as slash commands via the plugin system. All "business logic" is encoded in structured prompts, not executable code.

```
finyx/
├── .claude-plugin/plugin.json      # Plugin manifest
├── skills/                         # Self-contained skill bundles
│   ├── profile/                    # /finyx:profile — financial profile management
│   │   ├── SKILL.md
│   │   ├── agents/
│   │   └── references/
│   ├── tax/                        # /finyx:tax — tax advisor
│   ├── invest/                     # /finyx:invest — investment advisor
│   ├── pension/                    # /finyx:pension — pension planning
│   ├── insurance/                  # /finyx:insurance — PKV/GKV advisor
│   ├── insights/                   # /finyx:insights — unified dashboard
│   ├── realestate/                 # /finyx:scout, analyze, filter, compare, ...
│   └── help/                       # /finyx:help — command reference
└── agents/                         # Shared specialist agents
    ├── finyx-allocation-agent.md
    ├── finyx-projection-agent.md
    └── ...
```

**Zero runtime dependencies.** Everything is Markdown consumed by Claude Code via the plugin system.

## Country support

| Country | Tax | Investment | Pension | Real Estate | Broker |
|---------|-----|-----------|---------|-------------|--------|
| Germany | Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung | ETF/stock analysis, live Finnhub data | Riester, Rürup, bAV | Full pipeline | Interactive Brokers, Trade Republic, Scalable, etc. |
| Brazil | IR, DARF, come-cotas, FII exemptions | B3 analysis, live brapi.dev data | PGBL, VGBL, INSS | Location research | XP, Rico, NuInvest, etc. |

Cross-border users get integrated advice across both jurisdictions with DBA residency tiebreaker and withholding credit mechanics.

## Financial insights dashboard

The `/finyx:insights` command synthesizes all your financial data into a single report:

- **Income allocation** — Needs/wants/savings/investments/debt breakdown vs country-adjusted benchmarks (net-after-mandatory income, not gross)
- **Tax efficiency** — Per-country traffic-light scoring with € gap amounts (Sparerpauschbetrag usage, Vorabpauschale readiness, PGBL optimization)
- **Net worth snapshot** — Assets vs liabilities from your profile
- **Goal tracking** — "At current rate, target X reached in Y months"
- **Top-5 recommendations** — Ranked by estimated € annual impact
- **Cross-advisor intelligence** — Detects links across domains (unused tax allowance + low investment = double gap)

## Migrating from v1.x

If you previously installed via `npx finyx-cc`, uninstall first:

```bash
npx finyx-cc --uninstall
```

Then install the plugin:

```bash
claude plugin add github:italolelis/finyx
```

## Legal disclaimer

Finyx provides financial information for educational and planning purposes only. This tool does not constitute financial, tax, legal, or investment advice. Always consult qualified professionals before making financial decisions.

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT — See [LICENSE](LICENSE) for details.

---

*Finyx: Your AI financial advisor that sees the full picture.*

Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Workflow powered by [GSD](https://github.com/glittercowboy/get-shit-done).
