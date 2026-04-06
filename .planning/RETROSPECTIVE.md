# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-04-06
**Phases:** 5 | **Plans:** 13
**Timeline:** 65 days (2026-02-01 → 2026-04-06)

### What Was Built
- Full rebrand from immo-cc to finyx-cc with namespace migration
- Interactive financial profile with cross-border DE/BR detection
- German tax advisor (Abgeltungssteuer, Sparerpauschbetrag, Vorabpauschale, Teilfreistellung)
- Brazilian tax advisor (IR filing, DARF, come-cotas, FII exemptions, Law 15,270/2025)
- Investment advisor with portfolio analysis, risk profiling, ETF recs, live market data
- Broker comparison for DE + BR with tax-reporting quality differentiation
- Pension planning: Riester/Rürup/bAV (DE), PGBL/VGBL/INSS (BR), cross-country projection

### What Worked
- Slash-command architecture scaled cleanly from 1 domain (real estate) to 5 (tax, invest, broker, pension, profile)
- Shared profile.json pattern — write once, all agents read — eliminated repeated data collection
- Per-country reference doc structure (`germany/`, `brazil/`) proved extensible without refactoring commands
- Milestone audit caught real gaps (profile.md schema drift, missing disclaimer in update.md) that Phase 5 closed before shipping
- AskUserQuestion pattern for interactive data collection worked well across all commands

### What Was Inefficient
- SUMMARY.md one-liners were mostly empty — need to enforce writing them during plan completion
- Phase 1 took 4 plans (including gap closure) — initial rename scope was underestimated
- Some reference doc content duplicated between tax and investment contexts (e.g., Teilfreistellung appears in both)

### Patterns Established
- Profile gate: all advisory commands check `.finyx/profile.json` existence before proceeding
- Disclaimer injection: `disclaimer.md` in `execution_context` of every advisory command
- Country routing: `tax_class != null` → DE active, `ir_regime != null` → BR active
- Staleness detection: `tax_year` metadata in reference docs, `node -e` date arithmetic for cross-platform compat
- AskUserQuestion + Write offer: collect data interactively, offer to persist to profile

### Key Lessons
1. Milestone audits are worth the cost — they caught 3 real gaps that would have shipped broken
2. Reference docs are the knowledge layer; commands are the workflow layer — keep them separate
3. Cross-platform date handling in bash is painful — `node -e` is the right escape hatch
4. Hard-cut renames are cleaner than coexistence periods but need thorough path rewriting

### Cost Observations
- Model mix: primarily opus for execution, sonnet for research agents
- Notable: Phase 5 (gap closure) was small but high-value — 1 plan fixed 3 audit findings

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 5 | 13 | Established slash-command financial advisor pattern |

### Top Lessons (Verified Across Milestones)

1. Milestone audits catch real gaps — enforce before shipping
2. Shared profile pattern enables integrated cross-domain advice
