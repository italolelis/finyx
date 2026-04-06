# Phase 1: Foundation + Profile - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-06
**Phase:** 01-foundation-profile
**Areas discussed:** Rename strategy, Profile interview, Data architecture, RE preservation

---

## Rename Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Hard cut (Recommended) | Deprecate immo-cc, publish finyx, /finyx:* namespace, clean break | ✓ |
| Soft coexist | Keep immo-cc alive with deprecation warning, publish finyx alongside | |

**User's choice:** Hard cut
**Notes:** Early stage, no external dependents. Clean break preferred.

---

## Profile Interview

| Option | Description | Selected |
|--------|-------------|----------|
| Upfront linear (Recommended) | 3 groups: residency→income/tax→goals. Cross-border derived from group 1. | ✓ |
| Progressive discovery | Minimal upfront, commands ask for missing data as needed | |

**User's choice:** Upfront linear
**Notes:** Cross-border detection is load-bearing — must happen before any commands run.

---

## Data Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Separate (Recommended) | .finyx/profile.json for new domains, .immo/ stays untouched | |
| Merge now | .finyx/profile.json absorbs .immo/config.json, rewrite all IMMO command paths | ✓ |

**User's choice:** Merge now (against recommendation)
**Notes:** User prefers single source of truth from day one despite higher effort. All IMMO commands will read from .finyx/profile.json.

---

## RE Preservation

| Option | Description | Selected |
|--------|-------------|----------|
| Keep /immo:* as-is | Real estate stays at /immo:scout etc. Two namespaces. | |
| Move to /finyx:* | RE commands become /finyx:scout, /finyx:analyze alongside new finance commands | ✓ |

**User's choice:** Move to /finyx:*
**Notes:** Unified namespace. All commands under /finyx:*.

---

## Claude's Discretion

- Profile.json schema field naming and nesting
- Banner format and output styling (maintain pattern, update branding)
- bin/install.js refactoring approach

## Deferred Ideas

None — discussion stayed within phase scope.
