# Phase 10: Specialist Agents - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-08
**Phase:** 10-specialist-agents
**Areas discussed:** Calc agent output format, Research agent scope, Health questionnaire design, Agent naming & tools

---

## Calc Agent Output Format

| Option | Description | Selected |
|--------|-------------|----------|
| XML subsections | <insurance_calc_result> with 5 named subsections. Matches v1.1 pattern. | ✓ |
| Flat Markdown headers | Bold headers inside single tag. Fragile parsing. | |

**User's choice:** XML subsections

---

## Research Agent Scope

| Option | Description | Selected |
|--------|-------------|----------|
| 3 providers, neutral sources first | Direct provider + Stiftung Warentest/Finanztip primary. Check24 as fallback only. | ✓ |
| 5 providers | More comprehensive but heavier. | |

**User's choice:** 3 providers, avoid Check24 bias
**Notes:** User explicitly wants unbiased sources first. Check24 only when no other option.

---

## Health Questionnaire Design

| Option | Description | Selected |
|--------|-------------|----------|
| Inline flags in Task prompt | Full 15 binary flags passed as <health_flags> block. Session-only. | ✓ |
| Summary risk tier only | Just tier + count. Less granular. | |

**User's choice:** Inline flags in Task prompt

---

## Agent Naming & Tools

| Option | Description | Selected |
|--------|-------------|----------|
| green (research) + red (calc) | calc: Read/Grep/Glob (red), research: +WebSearch/WebFetch (green) | ✓ |

**User's choice:** green + red

## Deferred Ideas

None
