---
phase: 16-bulk-migration
plan: "03"
subsystem: skills/pension
tags: [skill-conversion, pension, plugin-architecture, germany, brazil]
dependency_graph:
  requires: [skills/pension/references/disclaimer.md, skills/pension/references/germany/pension.md, skills/pension/references/brazil/pension.md]
  provides: [skills/pension/SKILL.md]
  affects: [plugin.json, finyx-pension skill trigger]
tech_stack:
  added: []
  patterns: [disable-model-invocation, CLAUDE_SKILL_DIR references, skill frontmatter]
key_files:
  created: []
  modified:
    - skills/pension/SKILL.md
decisions:
  - Task tool removed from allowed-tools — pension advisory done inline, no agent delegation needed
  - Retirement gap analysis note added (enhancement over source command)
metrics:
  duration: 3m
  completed: "2026-04-12T16:12:49Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 16 Plan 03: Pension Skill Conversion Summary

**One-liner:** Pension advisory skill covering Riester/Rürup/bAV (DE), PGBL/VGBL/INSS (BR), and cross-country retirement projection with gap analysis.

## What Was Built

`skills/pension/SKILL.md` — 660-line full pension advisory skill converted from `commands/finyx/pension.md`.

Key content:
- Phase 1: Profile validation and country detection
- Phase 2: Tax year staleness check
- Phase 3: German pension planning (employment assessment, Riester Zulagen, Rürup Höchstbeitrag, bAV Entgeltumwandlung, 3-vehicle comparison + recommendation)
- Phase 4: Brazilian pension planning (PGBL vs VGBL decision tree, progressive vs regressive regime, Law 14.803/24 deferral, INSS status collection)
- Phase 5: Cross-country retirement projection (for cross_border users)
- Phase 6: Legal disclaimer
- Phase 7: Save offer for collected pension data

## Deviations from Plan

### Auto-fixed Issues

None.

### Enhancements Applied

**Retirement gap analysis note added to `<notes>` section:**
- Found during: Task 1
- Enhancement: Added explicit guidance on detecting retirement gap (combined monthly income below threshold) and suggesting remediation steps
- Rationale: The plan listed "retirement gap analysis" in the description — the source command had no explicit gap detection logic; added it as a notes section pattern
- Files modified: skills/pension/SKILL.md

## Validation Results

| Check | Result |
|-------|--------|
| `disable-model-invocation: true` present | PASS |
| Zero `@~/.claude/` occurrences | PASS (0 found) |
| Line count > 300 | PASS (660 lines) |
| `name: finyx-pension` present | PASS |
| References resolve in skills/pension/references/ | PASS |
| Domain terms: pension, retirement, Riester/Rürup/INSS | PASS |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | f1c82cb | feat(16-03): convert pension command to pension SKILL.md |

## Known Stubs

None — skill content is fully wired.

## Self-Check: PASSED
