---
name: finyx:status
description: Show current analysis state and recommended next action
allowed-tools:
  - Read
  - Bash
  - Glob
---

<objective>

Display current FINYX project status including:
- Workflow phase
- Locations and their analysis status
- Current shortlist
- Recommended next action

This is the "where am I?" command for orientation.

</objective>

<execution_context>

@~/.claude/finyx/references/disclaimer.md
@.finyx/profile.json

</execution_context>

<process>

## Step 1: Check Project Exists

```bash
[ -f .finyx/profile.json ] || { echo "NO_PROFILE"; }
```

**If NO_PROFILE:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► NO PROFILE FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No Finyx financial profile found in current directory.

To start: /finyx:profile
```
Exit.

## Step 2: Read State Files

Read:
- `.finyx/profile.json` - Financial profile
- `.finyx/STATE.md` - Current state

## Step 3: Scan Locations

```bash
ls -d properties/*/ 2>/dev/null | xargs -I {} basename {}
```

For each location, check:
- `.finyx/research/locations/[location].md` exists → SCOUTED
- `.finyx/analysis/[location]/UNITS.md` exists → ANALYZED
- `.finyx/analysis/[location]/SHORTLIST.md` exists → FILTERED

## Step 4: Display Status

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: [PROJECT_NAME]
Phase:   [CURRENT_PHASE]
Updated: [LAST_UPDATE]

───────────────────────────────────────────────────────
 INVESTOR PROFILE
───────────────────────────────────────────────────────

Income:       €[TOTAL]/year
Tax Rate:     [RATE]%
Available:    €[ASSETS]
Criteria:     ≥[YIELD]% yield, ≤€[PRICE], [SIZE]m²

───────────────────────────────────────────────────────
 LOCATIONS
───────────────────────────────────────────────────────

| Location | Status | Units | Shortlisted |
|----------|--------|-------|-------------|
| kassel   | ✅ FILTERED | 86 | 3 |
| munich   | 🔍 SCOUTED | - | - |
| taucha   | ❌ EXCLUDED | - | Quality |

───────────────────────────────────────────────────────
 SHORTLIST
───────────────────────────────────────────────────────

1. kassel/0.18 - €272k - 3.16% - 47.8m²
2. kassel/4.1  - €377k - 2.95% - 62.7m² - Parking ✅
3. kassel/3.7  - €401k - 3.20% - 73.8m²

───────────────────────────────────────────────────────
 NEXT ACTION
───────────────────────────────────────────────────────

[CONTEXTUAL RECOMMENDATION]

Examples:
- "Run /finyx:scout munich to research Munich location"
- "Run /finyx:analyze kassel to calculate metrics"
- "Run /finyx:compare to compare shortlisted units"
- "Run /finyx:report to generate advisor briefing"
```

## Step 5: Determine Next Action

Logic:
1. If no locations in properties/ → "Add property folders to properties/"
2. If locations exist but none scouted → "/finyx:scout [first-location]"
3. If scouted but not analyzed → "/finyx:analyze [location]"
4. If analyzed but not filtered → "/finyx:filter [location]"
5. If multiple locations filtered → "/finyx:compare"
6. If compared but no report → "/finyx:report"
7. If report exists → "Ready to decide. Review report or /finyx:stress-test"

Append the legal disclaimer from the loaded disclaimer.md reference at the end of all advisory output.

</process>
