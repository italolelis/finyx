---
phase: 15-pilot-skill
plan: "01"
subsystem: skills/tax
tags: [skill-conversion, tax, advisory, portable-paths]
dependency_graph:
  requires: [Phase 13 skill scaffolding, Phase 14 profile skill]
  provides: [Working tax skill, Conversion checklist for Phase 16]
  affects: [skills/tax/SKILL.md, Phase 16 bulk migration]
tech_stack:
  added: []
  patterns: [disable-model-invocation advisory guard, CLAUDE_SKILL_DIR portable paths, cross-skill fallback notes]
key_files:
  created:
    - .planning/phases/15-pilot-skill/CONVERSION-CHECKLIST.md
  modified:
    - skills/tax/SKILL.md
decisions:
  - "PKV cross-skill reference handled via fallback note (Option B) — no duplication of health-insurance.md into tax skill"
  - "Task tool removed from allowed-tools — tax-scoring agent not invoked by SKILL.md directly"
metrics:
  duration: "~5 minutes"
  completed: "2026-04-12T16:00:00Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 15 Plan 01: Pilot Skill Conversion Summary

**One-liner:** Tax SKILL.md converted from stub to full 596-line advisory skill with disable-model-invocation, portable CLAUDE_SKILL_DIR paths, and a repeatable conversion checklist for Phase 16 bulk migration.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Convert tax command to full SKILL.md | 2b8acc6 | skills/tax/SKILL.md |
| 2 | Document conversion checklist for Phase 16 | 9d5143c | .planning/phases/15-pilot-skill/CONVERSION-CHECKLIST.md |

## What Was Built

**Task 1 — Tax SKILL.md conversion:**

Overwrote the Phase 13 stub (10 lines, placeholder content) with the full advisory skill derived from `commands/finyx/tax.md`. The converted file:
- Has correct frontmatter: `name: finyx-tax`, `disable-model-invocation: true`, `allowed-tools: [Read, Write, Bash, AskUserQuestion]`
- Trigger description is 153 chars, front-loaded with German and Brazilian tax domain terms
- Loads 3 reference docs via `${CLAUDE_SKILL_DIR}/references/` portable paths
- Contains all 6 process phases from source command (validation, staleness check, DE tax, BR tax, DBA, disclaimer)
- Zero `@~/.claude/` legacy paths
- PKV cross-skill dependency (health-insurance.md) handled with a fallback note per Option B

**Task 2 — Conversion checklist:**

Created `.planning/phases/15-pilot-skill/CONVERSION-CHECKLIST.md` as a Phase 16 executor reference. Covers: pre-flight verification, frontmatter rules, content migration steps, path verification, agent scoping, validation commands, and per-skill `disable-model-invocation` classification. Includes notes from both Phase 14 (profile) and Phase 15 (tax) pilots.

## Decisions Made

1. **PKV reference handling (Option B):** The source command referenced `health-insurance.md` from the insurance skill for Phase 3.6. Rather than duplicating the file into `skills/tax/references/germany/`, added a fallback note directing users to `/finyx:insurance` if the insurance skill is not installed. This keeps reference docs owned by their canonical skill.

2. **Task tool removed from allowed-tools:** The source command stub had `Task` in allowed-tools, but the tax SKILL.md content never spawns the tax-scoring agent — it does all advisory work inline. Removed `Task` to minimize unnecessary tool permissions.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The tax SKILL.md is fully wired — it loads real reference docs via `${CLAUDE_SKILL_DIR}/references/` paths that exist in `skills/tax/references/`. No placeholder content remains.

## Self-Check: PASSED

Files created/modified:
- `skills/tax/SKILL.md` — FOUND (596 lines)
- `.planning/phases/15-pilot-skill/CONVERSION-CHECKLIST.md` — FOUND (80 lines)

Commits:
- `2b8acc6` — FOUND (feat: convert tax command to full SKILL.md)
- `9d5143c` — FOUND (chore: add skill conversion checklist for Phase 16)

All 6 plan verification checks: PASS
