# Phase 9: Reference Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-08
**Phase:** 09-reference-foundation
**Areas discussed:** PKV risk tier model, GKV Zusatzbeitrag handling, Doc structure & scope

---

## PKV Risk Tier Model

| Option | Description | Selected |
|--------|-------------|----------|
| 3-tier + binary flags | Low/medium/high with ~15 flags. Maps to Risikozuschlag bands (0%, 10-25%, 30-50%+). | ✓ |
| 5-tier + severity | More granular but GDPR Art. 9 exposure. False precision. | |

**User's choice:** 3-tier + binary flags

---

## GKV Zusatzbeitrag Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Average + range only | 2.75% average + 2.18-4.4% range. Research agent fetches live rates. | ✓ |
| Static fund table | Major funds with rates. Goes stale annually. | |

**User's choice:** Average + range only

---

## Doc Structure & Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Single doc, 6 sections | GKV, PKV, Familienversicherung, Thresholds, §10 EStG, Special Cases. ~320 lines. | ✓ |
| Split: main + expat | Separate expat doc. Breaks 1-doc convention. | |

**User's choice:** Single doc, 6 sections

## Claude's Discretion

- Risk tier flag wording, Altersrückstellungen detail, PKV age examples, projection growth rates

## Deferred Ideas

None
