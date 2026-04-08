---
phase: 11-command-integration
plan: 01
subsystem: commands/finyx
tags: [insurance, health-insurance, pkv, gkv, slash-command, orchestration]
dependency_graph:
  requires:
    - agents/finyx-insurance-calc-agent.md
    - agents/finyx-insurance-research-agent.md
    - finyx/references/germany/health-insurance.md
    - finyx/references/disclaimer.md
  provides:
    - commands/finyx/insurance.md
  affects:
    - bin/install.js (no changes needed — recursive copy handles new file)
tech_stack:
  added: []
  patterns:
    - Parallel Task spawning (both agents spawned simultaneously)
    - Disclaimer-first pattern (Phase 5 before Phase 6+7, matching insights.md)
    - AskUserQuestion multiSelect for GDPR-compliant health questionnaire
    - JAEG threshold read from reference doc at runtime (not hardcoded)
key_files:
  created:
    - commands/finyx/insurance.md
  modified: []
decisions:
  - Disclaimer emitted in Phase 5 BEFORE comparison (Phase 6) and recommendation (Phase 7) — matches insights.md pattern per D-10
  - JAEG threshold read from health-insurance.md Section 4.1 at runtime — not hardcoded
  - Self-employed JAEG exemption handled inline (bypass income gate per Section 4.2)
  - GKV-mandatory fast path: below-JAEG income → calc agent (GKV only) → display → STOP
  - bin/install.js recursive copy requires no changes — confirmed RECURSIVE_COPY=true
metrics:
  duration: "3 minutes"
  completed: "2026-04-08T22:24:51Z"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
---

# Phase 11 Plan 01: Command Integration Summary

**One-liner:** `/finyx:insurance` slash command — 7-phase PKV vs GKV orchestrator with JAEG eligibility gate, §6 Abs. 3a age-55 warning, expat detection, GDPR-compliant health questionnaire, parallel agent spawning, and disclaimer-first synthesis.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create /finyx:insurance command file | 9d17fad | commands/finyx/insurance.md |
| 2 | Verify installer handles new command and agents | verified-no-change | bin/install.js (no changes needed) |

## What Was Built

`commands/finyx/insurance.md` — a complete 476-line slash command with 7 phases:

**Phase 1: Validation and Eligibility Gate (ELIG-01)**
- Profile existence check and German tax data verification
- Tax year staleness check vs `health-insurance.md` frontmatter
- JAEG threshold read from Section 4.1 at runtime (not hardcoded)
- Beamter redirect to Section 6.1
- Self-employed JAEG exemption (bypass income gate per Section 4.2)
- Below-JAEG fast path: calc agent (GKV only) → display → STOP per D-02

**Phase 2: Warnings and Expat Detection (EDGE-01, EDGE-02)**
- Age-55 lock-in warning banner with §6 Abs. 3a SGB V legal basis for users age >= 50
- Expat detection via `identity.cross_border` or `identity.income_countries` or inline AskUserQuestion

**Phase 3: Health Questionnaire**
- Single AskUserQuestion multiSelect with 15 binary flags
- Category prefixes: [CV], [MET], [MSK], [MH], [OTH]
- GDPR Art. 9 compliant — flags never written to any file

**Phase 4: Agent Spawning (D-08, D-09)**
- Both calc and research agents spawned in PARALLEL via Task tool
- Health flags mapped from questionnaire selections to agent field names inline in Task prompt
- Research agent receives age, employment_type, family_status, children_count (no health data)

**Phase 5: Legal Disclaimer (INFRA-03, D-10)**
- Full disclaimer.md content emitted BEFORE any advisory content
- Insurance-specific addendum with Versicherungsberater recommendation
- Matches insights.md disclaimer-first pattern

**Phase 6: Comparison Synthesis**
- Side-by-side cost table (GKV vs PKV, with tax netting row)
- PKV provider options extracted from research agent output
- Projection summary from calc agent (base scenario inline + all crossover years)
- Expat section (conditional on `show_expat == true`): Anwartschaft, EU portability, non-EU gaps

**Phase 7: Recommendation**
- Reasoned recommendation based on all scenarios and user profile
- Family Familienversicherung advantage highlighted when applicable
- Age-55 lock-in risk re-emphasized when `show_age_warning == true`
- Health flag risk tier caveat when Tier 1 or Tier 2 detected
- Concrete next steps with top provider name from research output

## Requirements Satisfied

| Requirement | Status |
|-------------|--------|
| ELIG-01 | Done — Phase 1 JAEG eligibility gate |
| EDGE-01 | Done — Phase 2 expat detection + Section 6.4 guidance |
| EDGE-02 | Done — Phase 2 age-55 warning banner with §6 Abs. 3a |
| INFRA-03 | Done — Phase 5 disclaimer before advisory content |
| INFRA-04 | Done — command file exists and is fully wired |

## Installer Verification (Task 2)

`bin/install.js` uses `copyWithPathReplacement` (recursive copy). Verification confirmed:
- `RECURSIVE_COPY=true` — no explicit file list, all new files in `commands/` and `agents/` directories are handled automatically
- `CMD_EXISTS=true` — `commands/finyx/insurance.md` present in source directory
- Path references in `insurance.md` use `@~/.claude/` prefix convention correctly
- No changes to `bin/install.js` required

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — command is fully wired. All agent spawn prompts reference real agent names, real profile fields, and real reference doc paths. No hardcoded data or placeholder values that would prevent the command from functioning.

## Self-Check: PASSED

File exists:
- `commands/finyx/insurance.md` — FOUND (476 lines)

Commits exist:
- `9d17fad` — feat(11-01): create /finyx:insurance slash command — FOUND

Acceptance criteria:
- `name: finyx:insurance` — 1 match
- `allowed-tools` includes Read, Bash, Write, Task, AskUserQuestion — PASSED
- `JAEG` — 15 matches (>= 3 required)
- `insurance_calc_result` — 6 matches (>= 2 required)
- `insurance_research_result` — 4 matches (>= 2 required)
- `§6 Abs. 3a` — 7 matches (>= 1 required)
- `Anwartschaft` — 9 matches (>= 1 required)
- `Versicherungsberater` — 11 matches (>= 1 required)
- `multiSelect` / `AskUserQuestion` — 8 matches (>= 1 required)
- `health_flags` — 7 matches (>= 1 required)
- `disclaimer.md` — 4 matches (>= 1 required)
- `health-insurance.md` — 13 matches (>= 1 required)
- `profile.json` — 7 matches (>= 1 required)
- Line count >= 350 — 476 lines, PASSED
- Phase 1 through Phase 7 headers — PASSED
- `GKV MANDATORY` — 1 match, PASSED
- `cross_border` — 3 matches, PASSED
- Disclaimer in Phase 5 BEFORE Phase 6 and Phase 7 — PASSED
