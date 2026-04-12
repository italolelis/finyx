---
phase: 16-bulk-migration
verified: 2026-04-12T00:00:00Z
status: gaps_found
score: 4/5 must-have truths verified
gaps:
  - truth: "No shared root-level agents remain — every agent scoped to its owning skill"
    status: failed
    reason: "agents/ root directory still exists with 8 agent files, all identical to their scoped counterparts under skills/*/agents/. CONTEXT.md explicitly states 'No root agents directory remains' as the phase goal. SKILL-03 requirement is not satisfied while the root directory persists."
    artifacts:
      - path: "agents/"
        issue: "Root agents/ directory still present with 8 files: finyx-allocation-agent.md, finyx-analyzer-agent.md, finyx-insurance-calc-agent.md, finyx-insurance-research-agent.md, finyx-location-scout.md, finyx-projection-agent.md, finyx-reporter-agent.md, finyx-tax-scoring-agent.md"
    missing:
      - "Remove agents/ root directory (all agents are already correctly scoped under skills/*/agents/)"
human_verification:
  - test: "Run /finyx:realestate and invoke analyze or report workflow"
    expected: "Task tool spawns finyx-analyzer-agent or finyx-reporter-agent correctly from skills/realestate/agents/"
    why_human: "Cannot verify Claude Code agent dispatch path resolution without running the command"
  - test: "Run /finyx:insights to produce cross-domain financial dashboard"
    expected: "Spawns finyx-allocation-agent and finyx-projection-agent, produces scored output"
    why_human: "Cross-skill data dependencies (reads tax/invest/insurance data) require live execution"
---

# Phase 16: Bulk Migration Verification Report

**Phase Goal:** All remaining 15 commands (profile and tax already done) are converted to skills following the validated pattern — every skill self-contained, every agent scoped, no shared root-level agents remain
**Verified:** 2026-04-12
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All 17 commands converted to SKILL.md files (15 in phase 16 + profile + tax from prior phases) | VERIFIED | 8 skills cover all 17 commands: invest+broker, realestate(7), pension, insurance, insights, help+status+update, profile, tax |
| 2 | Every advisory skill has `disable-model-invocation: true` | VERIFIED | invest, pension, insurance, insights, tax all have it (count=1); realestate, help, profile correctly omit it per D-07 |
| 3 | Every agent scoped under `skills/<name>/agents/` — no shared root-level agents remain | FAILED | All 8 agents are scoped correctly under skills/*/agents/ BUT root `agents/` directory still exists with identical copies. Phase goal and CONTEXT.md both require root removal. |
| 4 | Every skill bundles reference docs under `skills/<name>/references/` with no `@~/.claude/` paths | VERIFIED | Zero `@~/.claude/` occurrences across all skills; all use `${CLAUDE_SKILL_DIR}/references/` |
| 5 | Skill trigger descriptions are front-loaded, specific, under 250 chars | VERIFIED | All 8 descriptions verified: longest is realestate at 229 chars; all start with domain-specific terms |

**Score:** 4/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `skills/invest/SKILL.md` | invest + broker merged, >400 lines, finyx-invest | VERIFIED | 1065 lines, disable=true, broker terms=121 occurrences, ETF=57, allocation=21 |
| `skills/realestate/SKILL.md` | 7 workflows merged, >800 lines, finyx-realestate, no disable | VERIFIED | 2177 lines, no disable-model-invocation, all 7 workflow terms present, Task in allowed-tools |
| `skills/pension/SKILL.md` | pension advisory, >300 lines, finyx-pension, disable=true | VERIFIED | 660 lines, disable=true, Riester/Rürup/INSS domain terms present |
| `skills/insurance/SKILL.md` | insurance + 2 agents, >300 lines, finyx-insurance, disable=true | VERIFIED | 604 lines, disable=true, GKV/PKV terms=50, Task in allowed-tools |
| `skills/insights/SKILL.md` | insights + 2 agents, >200 lines, finyx-insights, disable=true | VERIFIED | 411 lines, disable=true, scoring/allocation/projection terms present, Task in allowed-tools |
| `skills/help/SKILL.md` | help+status+update merged, >300 lines, finyx-help, no disable | VERIFIED | 803 lines, no disable-model-invocation, status/update/command domain terms all present |
| `skills/*/agents/` (scoped) | All agents under owning skill directories | VERIFIED | realestate/agents/ (3), insurance/agents/ (2), insights/agents/ (2), tax/agents/ (1) — all present |
| `agents/` (root) | Should not exist (or be empty) | FAILED | Root directory exists with 8 agent files identical to scoped copies |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `skills/invest/SKILL.md` | `skills/invest/references/` | `${CLAUDE_SKILL_DIR}/references/` paths | VERIFIED | 3 CLAUDE_SKILL_DIR references; files exist: disclaimer.md, germany/brokers.md, brazil/brokers.md |
| `skills/realestate/SKILL.md` | `skills/realestate/references/` | `${CLAUDE_SKILL_DIR}/references/` paths | VERIFIED | 5 CLAUDE_SKILL_DIR references; files exist: disclaimer.md, methodology.md, erbpacht-detection.md, transport-assessment.md, germany/tax-rules.md |
| `skills/realestate/SKILL.md` | `skills/realestate/agents/` | Task tool agent delegation | VERIFIED | Task in allowed-tools; finyx-analyzer-agent, finyx-reporter-agent referenced by name in skill body |
| `skills/pension/SKILL.md` | `skills/pension/references/` | `${CLAUDE_SKILL_DIR}/references/` paths | VERIFIED | 3 CLAUDE_SKILL_DIR references; files exist: disclaimer.md, germany/pension.md, brazil/pension.md |
| `skills/insurance/SKILL.md` | `skills/insurance/references/` | `${CLAUDE_SKILL_DIR}/references/` paths | VERIFIED | 6 CLAUDE_SKILL_DIR references; files exist: disclaimer.md, germany/health-insurance.md |
| `skills/insurance/SKILL.md` | `skills/insurance/agents/` | Task tool agent delegation | VERIFIED | Task in allowed-tools; both finyx-insurance-calc-agent.md and finyx-insurance-research-agent.md present |
| `skills/insights/SKILL.md` | `skills/insights/references/` | `${CLAUDE_SKILL_DIR}/references/` paths | VERIFIED | 8 CLAUDE_SKILL_DIR references; files exist: disclaimer.md, insights/benchmarks.md, insights/scoring-rules.md |
| `skills/insights/SKILL.md` | `skills/insights/agents/` | Task tool agent delegation | VERIFIED | Task in allowed-tools; both finyx-allocation-agent.md and finyx-projection-agent.md present |
| `skills/help/SKILL.md` | `.finyx/` runtime files | .finyx/ path access | VERIFIED | 1 CLAUDE_SKILL_DIR reference; .finyx/ access pattern present |

### Data-Flow Trace (Level 4)

Not applicable — this is a Claude Code slash-command/skill architecture. Skills are Markdown prompt files, not runnable components with data state. No data-flow trace applies.

### Behavioral Spot-Checks

Step 7b: SKIPPED — Skills are Markdown prompt files interpreted by Claude Code at invocation time. There are no runnable entry points to execute in isolation without a Claude Code session.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SKILL-01 | 16-01 through 16-06 (also 14-01, 15-01) | All 17 commands converted to SKILL.md files with proper frontmatter | VERIFIED | 8 skill directories, all 17 commands mapped; every SKILL.md has name, description, allowed-tools |
| SKILL-02 | 16-01, 16-03, 16-04, 16-05 | Each advisory skill has `disable-model-invocation: true` | VERIFIED | invest, pension, insurance, insights, tax: all have it; realestate, help, profile correctly omit per D-07 |
| SKILL-03 | 16-02, 16-04, 16-05 (also 15-01) | Every agent under `skills/<name>/agents/` — no shared root-level agents | FAILED | Agents correctly scoped in skills/*/agents/ BUT root `agents/` directory persists with 8 identical files |
| SKILL-04 | All 6 plans | Each skill bundles reference docs under `skills/<name>/references/` | VERIFIED | All 8 skills have references/ subdirectory; zero `@~/.claude/` across entire skills/ tree |
| SKILL-05 | All 6 plans | Trigger descriptions front-loaded, specific, under 250 chars | VERIFIED | invest=187, realestate=229, pension=161, insurance=201, insights=179, help=152, profile/tax also compliant |

**ORPHANED requirements check:** REQUIREMENTS.md maps SKILL-01 through SKILL-05 to "Phase 15-16". All five are claimed by plans in this phase. No orphaned requirements.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `agents/` (root dir) | Duplicate agent files identical to scoped counterparts | Blocker | SKILL-03 not satisfied; "no shared root-level agents remain" phase goal not met; creates ambiguity about which copy Claude Code uses |

No placeholder comments, empty implementations, hardcoded empty data, or `@~/.claude/` path references found in any SKILL.md file.

### Human Verification Required

#### 1. Task Tool Agent Dispatch (realestate)

**Test:** Run `/finyx:realestate` and request property analysis or report generation
**Expected:** Claude Code spawns finyx-analyzer-agent or finyx-reporter-agent from `skills/realestate/agents/` (not root `agents/`)
**Why human:** Agent path resolution by Claude Code's Task tool cannot be verified by static analysis

#### 2. Cross-Skill Insights Execution

**Test:** Run `/finyx:insights` with a populated `.finyx/profile.json`
**Expected:** Both finyx-allocation-agent and finyx-projection-agent are spawned; scored output includes cross-domain data from tax/invest/insurance skills
**Why human:** Cross-skill data dependencies and live agent orchestration require runtime verification

### Gaps Summary

One gap blocks full goal achievement:

**Root `agents/` directory not removed.** The phase goal explicitly states "no shared root-level agents remain" and CONTEXT.md says "No root agents directory remains." All 8 agents have been correctly duplicated into their owning skill directories (`skills/realestate/agents/`, `skills/insurance/agents/`, `skills/insights/agents/`, `skills/tax/agents/`). The root `agents/` directory still exists with 8 files that are byte-for-byte identical to the scoped copies.

The fix is straightforward: `rm -rf agents/`. All agents are already in the right place under skills/. This is the only blocking gap.

Note: REQUIREMENTS.md and ROADMAP.md assign CLEAN-02 ("Legacy agents/ root directory removed") to Phase 17. However, the Phase 16 goal and CONTEXT.md explicitly include root agent removal as an in-scope deliverable. The gap exists regardless of which phase owns the cleanup ticket.

---

_Verified: 2026-04-12_
_Verifier: Claude (gsd-verifier)_
