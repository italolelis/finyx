# Phase 2: Tax Advisors - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-06
**Phase:** 02-tax-advisors
**Areas discussed:** Command structure, Reference doc strategy, Sparerpauschbetrag tracking, Cross-border tax interaction

---

## Command Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Split: /finyx:tax-de + /finyx:tax-br | Separate commands per country. Each prompt stays focused, reference docs map 1:1. Easy to add countries later. | |
| Unified: /finyx:tax with routing | Single entry point, auto-routes by profile country. Simpler UX but prompt grows with each country. | ✓ |

**User's choice:** Unified `/finyx:tax` with routing
**Notes:** User preferred single entry point despite research recommending split. Country routing auto-detected from profile.

---

## Reference Doc Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Split by domain | New germany/tax-investment.md and brazil/tax-investment.md alongside existing RE tax-rules.md. Clean separation. | ✓ |
| One file per country | Expand germany/tax-rules.md with investment tax content, create one brazil/tax-rules.md. | |

**User's choice:** Split by domain
**Notes:** Accepted recommended approach. tax_year YAML frontmatter on new files only.

---

## Sparerpauschbetrag Tracking

| Option | Description | Selected |
|--------|-------------|----------|
| On-the-fly from profile | Stateless — profile holds broker estimates, command calculates each run. Fits existing pattern. | ✓ |
| Persistent yearly state file | Store running totals in .finyx/tax-year/2025.json. Supports incremental updates. | |

**User's choice:** On-the-fly from profile
**Notes:** Accepted recommended approach. Keeps stateless command pattern.

---

## Cross-border Tax Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Surface basics in Phase 2 | Include DBA residency tiebreaker and withholding credit basics. Flag INSS/FII as out-of-scope. | ✓ |
| Defer to dedicated phase | No cross-border guidance until edge cases resolved. | |

**User's choice:** Surface basics in Phase 2
**Notes:** Accepted recommended approach. INSS expat and FII Law 15,270 explicitly deferred.

## Claude's Discretion

- /finyx:tax prompt structure and flow ordering
- Vorabpauschale calculation output format
- Brazilian DARF deadline reminder mechanism

## Deferred Ideas

- INSS expat treatment (Phase 4)
- FII Law 15,270/2025 edge cases
- Persistent tax-year tracking
- Tax-loss harvesting command
- Anlage KAP filing assistant
