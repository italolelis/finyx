# Phase 11: Command + Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-08
**Phase:** 11-command-integration
**Areas discussed:** Report layout & flow, Questionnaire UX, Expat detection logic

---

## Report Layout & Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Gate-first | Eligibility → warnings → questionnaire → agents → comparison → actions → disclaimer | ✓ |
| Inline-contextual | Warnings inline with comparison rows | |

**User's choice:** Gate-first

---

## Health Questionnaire UX

| Option | Description | Selected |
|--------|-------------|----------|
| Single multiSelect + category prefixes | All 15 flags, one round-trip, [CV]/[MET]/[MSK]/[MH] prefixes | ✓ |
| 3-4 grouped prompts | One per category, more round-trips | |

**User's choice:** Single multiSelect with prefixes

---

## Expat Detection

| Option | Description | Selected |
|--------|-------------|----------|
| Profile flags + ask inline if unclear | Check cross_border/countries first, ask user if missing | ✓ |
| Profile flags only, skip if absent | Silent skip when data missing | |

**User's choice:** Ask inline if unclear — accuracy preferred over speed

## Deferred Ideas

None
