# Phase 4: Pension Planning - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-06
**Phase:** 04-pension-planning
**Areas discussed:** Command structure, Cross-country projection scope, Calculation complexity

---

## Command Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Unified /finyx:pension | One command with country routing. PENSION-06 stays coherent. | ✓ |
| Split /finyx:pension-de + /finyx:pension-br | Separate per country. PENSION-06 becomes orphaned. | |

**User's choice:** Unified /finyx:pension
**Notes:** Pension is one intent regardless of country. Matches /finyx:tax pattern.

---

## Cross-country Projection Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Inflation-adjusted timeline | Real rates in reference doc (DE 1.5%, BR 2.0%), user-overridable. INSS self-reported. | ✓ |
| Simple nominal sum | Sum payouts. Quick but misleading. | |

**User's choice:** Inflation-adjusted timeline
**Notes:** INSS expat handled as self-reported status with lawyer disclaimer.

---

## Calculation Complexity

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime profile application | Reference docs hold formulas. Command substitutes profile values. | ✓ |
| Static formulas only | AI figures out substitution. Higher arithmetic drift risk. | |

**User's choice:** Runtime profile application
**Notes:** Same pattern as Phase 2 tax calculations.

## Claude's Discretion

- Pension comparison presentation format
- Retirement projection visualization
- bAV explanation depth

## Deferred Ideas

- INSS expat treatment legal research
- Insurance coverage analysis (INSUR-01/02)
- Automated pension contribution optimization
- Detailed gesetzliche Rente projection
