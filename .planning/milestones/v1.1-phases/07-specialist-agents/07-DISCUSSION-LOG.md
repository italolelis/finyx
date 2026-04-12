# Phase 7: Specialist Agents - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-07
**Phase:** 07-specialist-agents
**Areas discussed:** Agent output format, Profile data mapping, Agent naming & tools, Allocation categories

---

## Agent Output Format

| Option | Description | Selected |
|--------|-------------|----------|
| Structured Markdown + XML tags | Each agent wraps output in named XML tags. Matches existing pattern, human-readable. | ✓ |
| JSON code blocks | Machine-parseable but Claude occasionally malforms long JSON. | |

**User's choice:** Structured Markdown + XML tags
**Notes:** Orchestrator is a Claude Code slash-command — Claude reads the output, no JSON parser in the loop.

---

## Profile Data Mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Orchestrator gate only | Phase 8 validates profile before spawning agents. Single validation point. | ✓ |
| INCOMPLETE flags per agent | Each agent checks its own fields. More defensive but duplicates logic. | |

**User's choice:** Orchestrator gate only
**Notes:** INFRA-01 already requires a completeness gate in the orchestrator. No need to duplicate.

---

## Agent Naming & Tools

| Option | Description | Selected |
|--------|-------------|----------|
| finyx-[role]-agent.md, Read/Grep/Glob only | Matches analyzer-agent stem, minimal blast radius, profile-only sourcing. | ✓ |

**User's choice:** Looks good
**Notes:** Colors: yellow (allocation), magenta (tax-scoring), blue (projection).

---

## Allocation Categories

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcoded map in agent prompt | Deterministic, auditable, single update point. | |
| Infer from field names | LLM heuristics, zero maintenance but non-deterministic. | |
| Hybrid: infer → suggest → confirm → persist | Agent infers, user confirms, mapping stored for future runs. | ✓ |

**User's choice:** Hybrid — infer then make deterministic after user confirmation
**Notes:** User wants the tool to suggest categories from profile data, user confirms, then it's stored deterministically for subsequent runs.

## Claude's Discretion

- Agent prompt internal structure
- Exact table format within XML tags
- Persistence location for confirmed allocation mapping

## Deferred Ideas

None
