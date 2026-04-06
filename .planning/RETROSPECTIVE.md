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

## Milestone: v1.1 — Financial Insights Dashboard

**Shipped:** 2026-04-07
**Phases:** 3 | **Plans:** 5
**Timeline:** 1 day (2026-04-06 → 2026-04-07)

### What Was Built
- Country-aware allocation benchmarks and traffic-light scoring rules (8 dimensions, DE + BR)
- Allocation agent: income breakdown vs net-after-mandatory benchmarks, emergency fund check, hybrid categorization flow
- Tax-scoring agent: Sparerpauschbetrag, Vorabpauschale readiness, PGBL optimization with per-country € gaps
- Projection agent: net worth snapshot from cost-basis portfolio fields, goal pace tracking
- `/fin:insights` orchestrator: completeness gate, 3 parallel agents, cross-advisor intelligence, ranked recommendations

### What Worked
- Phase 6 reference docs as a foundation phase unblocked all 3 agents cleanly — no circular dependencies
- Parallel agent execution in Phase 7 (3 agents in 1 wave) maximized throughput
- Prior phase decisions carried forward effectively — no re-asking of settled questions in Phases 7-8
- Profile-only data sourcing kept agents simple — no WebSearch or Bash needed
- Traffic-light + € gap format gives both scan-ability and actionability

### What Was Inefficient
- Skipped milestone audit — all 12 requirements passed but formal verification would have caught any edge cases
- Research phase for Phase 6 (reference docs) may have been overkill — the scope was clear from discuss-phase

### Patterns Established
- Insights agent pattern: YAML frontmatter + XML output tags + profile-slice input
- Scoring reference docs: separate from tax docs, cite upstream by section number
- Cross-advisor intelligence via Claude inference with enumerated examples (not hardcoded rules)
- Allocation mapping persistence: `.finyx/insights-config.json` (not profile.json)

### Key Lessons
1. Reference docs as a separate phase pays off — they become reusable across agents
2. Agents with Read-only tools are simpler to reason about and test
3. Claude inference + examples is the right pattern for cross-domain detection in a prompt-only architecture
4. 1-day milestones are viable for well-scoped feature additions built on existing infrastructure

### Cost Observations
- Model mix: opus for planning, sonnet for research/execution/verification
- 3 phases, 5 plans — compact milestone with high feature density
- Parallel execution in Phase 7 saved significant wall-clock time

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 5 | 13 | Established slash-command financial advisor pattern |
| v1.1 | 3 | 5 | Added insights dashboard with parallel agent architecture |

### Top Lessons (Verified Across Milestones)

1. Milestone audits catch real gaps — enforce before shipping
2. Shared profile pattern enables integrated cross-domain advice
3. Reference docs as foundation phases unblock downstream work cleanly
4. Parallel agent execution maximizes throughput for independent tasks
