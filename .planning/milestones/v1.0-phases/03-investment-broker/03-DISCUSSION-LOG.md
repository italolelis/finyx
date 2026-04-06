# Phase 3: Investment + Broker - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-06
**Phase:** 03-investment-broker
**Areas discussed:** Command structure, Portfolio input method, Market data approach, Broker knowledge source

---

## Command Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Unified /finyx:invest | One command covers all 9 requirements. Matches /finyx:tax pattern. | |
| Split: /finyx:invest + /finyx:broker | Two commands mapping to distinct user intents. Market data inside /finyx:invest. | ✓ |

**User's choice:** Split into /finyx:invest + /finyx:broker
**Notes:** Different user intents — portfolio analysis vs broker comparison. Market data stays in /finyx:invest.

---

## Portfolio Input Method

| Option | Description | Selected |
|--------|-------------|----------|
| Profile.json holdings array | Extend profile with holdings[] grouped by broker. Stateless read. | ✓ |
| Interactive input each run | AskUserQuestion for holdings. No persistence. | |

**User's choice:** Profile.json holdings array
**Notes:** Fits stateless pattern established in Phase 2.

---

## Market Data Approach

| Option | Description | Selected |
|--------|-------------|----------|
| API keys in env vars + WebSearch fallback | FINNHUB_API_KEY + BRAPI_TOKEN as env vars. Pre-flight check. Falls back to WebSearch. | ✓ |
| WebSearch only | No keys needed. Non-deterministic output. | |

**User's choice:** API keys in env vars with WebSearch fallback
**Notes:** Keys never in profile.json (secrets). Clear setup instructions on missing key.

---

## Broker Knowledge Source

| Option | Description | Selected |
|--------|-------------|----------|
| Static reference doc | Versioned Markdown with last_verified date. Mine from broker-guide.md. | ✓ |
| Live WebSearch each run | Always current but non-deterministic. | |

**User's choice:** Static reference doc
**Notes:** Advisory context makes staleness low-stakes. Include broker URLs for user verification.

## Claude's Discretion

- Risk profile assessment questionnaire design
- ETF recommendation matching algorithm
- Rebalancing threshold and suggestion format
- Portfolio visualization format

## Deferred Ideas

- CSV/broker export import for holdings
- Automated portfolio rebalancing execution
- Tax-loss harvesting guidance
- RE + investment portfolio integration
