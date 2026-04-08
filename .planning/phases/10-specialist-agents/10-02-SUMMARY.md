---
phase: 10-specialist-agents
plan: 02
subsystem: agents
tags: [insurance, pkv, research-agent, websearch]
dependency_graph:
  requires:
    - finyx/references/germany/health-insurance.md
    - finyx/references/disclaimer.md
  provides:
    - agents/finyx-insurance-research-agent.md
  affects:
    - Phase 11 /finyx:insurance command (consumes this agent via Task tool)
tech_stack:
  added: []
  patterns:
    - WebSearch/WebFetch agent with neutral-source priority
    - Exactly-3-providers output constraint (D-03)
    - Confidence flags pattern from finyx-tax-scoring-agent.md
    - Stateless agent returning XML-tagged structured output
key_files:
  created:
    - agents/finyx-insurance-research-agent.md
  modified: []
decisions:
  - Neutral source hierarchy enforced in agent: Stiftung Warentest/Finanztip/krankenkasseninfo.de first, Check24 fallback only (D-02)
  - Exactly 3 providers in output regardless of search depth — prevents analysis paralysis (D-03)
  - Search queries anchored to age, employment_type, family_status only — no health data in queries (GDPR Art. 9)
  - Age-55 lock-in warning injected when user age >= 50 (references health-insurance.md Section 6.3)
metrics:
  duration_seconds: 94
  completed_date: "2026-04-08"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
requirements_satisfied:
  - ADV-02
---

# Phase 10 Plan 02: Insurance Research Agent Summary

**One-liner:** Live PKV research agent using WebSearch with Stiftung Warentest/Finanztip priority, top-3 provider comparison, and per-provider Beitragsrückerstattung/Selbstbeteiligung sections.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create finyx-insurance-research-agent.md | 603a32d | agents/finyx-insurance-research-agent.md |

## What Was Built

`agents/finyx-insurance-research-agent.md` (314 lines) — a stateless PKV provider research agent:

- **YAML frontmatter:** `name: finyx-insurance-research-agent`, `tools: Read, Grep, Glob, WebSearch, WebFetch`, `color: green`
- **Role section:** stateless design, source priority hierarchy (neutral aggregators first, Check24 fallback), confidence flag protocol
- **Execution context:** includes `health-insurance.md` and `disclaimer.md` via `@~/.claude/finyx/references/` paths
- **5-phase process:**
  1. Read input context (age, employment_type, family_status, children_count) from Task prompt
  2. WebSearch with 4 query groups: neutral aggregators → employment-type anchored → family-status anchored → direct provider fallback
  3. Extract tariff data per provider (premium, Beitragsrückerstattung, Selbstbeteiligung, premium trend, source date)
  4. Select top 3 providers by weighted criteria (premium competitiveness, no-claims bonus, deductible flexibility, stability, neutral endorsement)
  5. Format `<insurance_research_result>` with comparison table, recommendation, alternatives, per-provider detail sections, sources, confidence
- **Anti-patterns section:** explicit prohibitions on fabricating prices, using Check24 as primary, including health data in queries, writing files
- **Output format template:** full XML schema for `<insurance_research_result>`

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — agent is a complete prompt file with no data placeholders that block its goal. Live data comes from WebSearch at runtime.

## Self-Check: PASSED

- `agents/finyx-insurance-research-agent.md` exists and is 314 lines
- Commit `603a32d` verified in git log
- All 14 acceptance criteria passed (verified via grep checks)
