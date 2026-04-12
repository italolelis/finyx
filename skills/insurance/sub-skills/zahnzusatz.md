# Zahnzusatz Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver a personalized Zahnzusatzversicherung (supplemental dental insurance) analysis by comparing the user's existing coverage against benchmarks from the reference doc, emitting a Staffelung warning with annual cap escalation context, explaining the GKV Festzuschuss baseline, tracking cancellation deadlines, and spawning the research agent for criteria-based market comparison.

This command writes NO files. All output is conversational advisory text.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect user context before analysis. Collect all three questions in a single round-trip where possible.

**Question 1 — Immediate dental needs (singleSelect):**
"Do you currently have or anticipate any dental needs?"
- No current dental issues
- Have upcoming dental work planned
- Currently in treatment

> CRITICAL: If user selects "Have upcoming dental work planned" or "Currently in treatment", the Staffelung warning in Phase 3 becomes urgent — year-1 caps may severely limit reimbursement for imminent treatment.

**Question 2 — Implant relevance (singleSelect):**
"Are implants a coverage priority for you?"
- May need implants in future
- No implant concerns
- Not sure

**Question 3 — Children / KFO relevance (singleSelect):**
"Do you have or plan to have children who may need orthodontic treatment?"
- Have children under 18
- No children / children over 18

Store results as `user_preferences` object:
```
user_preferences = {
  dental_needs_urgency: [selected],
  implant_priority: [selected],
  kfo_relevance: [selected]
}
```

---

## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

**Read `.finyx/profile.json`** (already loaded by the router at startup) and extract:
- Type slug: `"zahnzusatz"` — search `insurance.policies[]` for entries where `type == "zahnzusatz"`
- If found, extract:
  - `coverage_amount` — year-1 Staffelung cap in EUR; null means unlimited or not recorded
  - `coverage_components` — array of coverage items (e.g., ["Zahnersatz 80%", "Zahnbehandlung 80%", "PZR 2x/year", "Implantate included"])
  - `start_date` — ISO date, used to compute Wartezeit elapsed
  - `renewal_date` — Hauptfälligkeit (annual renewal date)
  - `kuendigungsfrist_months` — cancellation notice period
  - `sonderkundigungsrecht` — boolean
  - `premium_monthly` — monthly premium in EUR
- If no zahnzusatz policy found: set `existing_policy = null` and proceed to benchmark comparison using reference doc benchmarks only.

**Tax year staleness check:**
```bash
CURRENT_YEAR=$(date +%Y)
echo "Current year: $CURRENT_YEAR"
```

Read `tax_year` from `${CLAUDE_SKILL_DIR}/references/germany/zahnzusatz.md` frontmatter. If `CURRENT_YEAR != tax_year`, emit:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reference docs are from tax year {tax_year}. Current year is {CURRENT_YEAR}.
GKV Festzuschuss rates are set annually by the G-BA — verify before acting.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Disclaimer

Emit the main header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► ZAHNZUSATZVERSICHERUNG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Output the full legal disclaimer from the loaded `disclaimer.md`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

Then append the insurance-specific addendum:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 INSURANCE-SPECIFIC NOTICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dental insurance analysis is based on your recorded coverage_components and
benchmarks from the Zahnzusatz reference doc. Actual reimbursement depends
on individual policy terms, Regelversorgung definitions, and Bonusheft status.

This tool does not replace a consultation with a licensed Versicherungsberater.
Always verify your current Bonusheft status with your GKV before switching.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 3: Coverage Benchmark Comparison

Read all benchmarks from `${CLAUDE_SKILL_DIR}/references/germany/zahnzusatz.md`. Do NOT hardcode any threshold values — read them from the reference doc at runtime.

### 3.1 GKV Festzuschuss Baseline Context

Before any comparison, explain the GKV baseline so the user understands what they already have:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GKV DENTAL BASELINE (§55 SGB V)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GKV pays a Festzuschuss (fixed grant) based on Regelversorgung (standard
treatment). Your Festzuschuss level depends on your Bonusheft status:

| Bonusheft Status                        | GKV Festzuschuss          |
|-----------------------------------------|---------------------------|
| No Bonusheft                            | 60% of Regelversorgung    |
| 5-year uninterrupted check-up record    | 70% of Regelversorgung    |
| 10-year uninterrupted check-up record   | 75% of Regelversorgung    |

IMPORTANT: The GKV Festzuschuss covers Regelversorgung only — not the
actual cost of quality dental work. For crowns, implants, and bridges, the
patient typically pays the gap between GKV Festzuschuss and actual cost.
Zahnzusatz covers this gap.

Tip: Keep your Bonusheft current — biannual dental check-ups boost your
GKV Festzuschuss from 60% to 70% or 75% over 5-10 years.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.2 Coverage Comparison Table

Read minimum and recommended thresholds from the reference doc Coverage Benchmarks table.

**If existing policy found (`existing_policy != null`):**

Compute Wartezeit elapsed: months from `start_date` to today.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 YOUR ZAHNZUSATZ COVERAGE vs BENCHMARKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Criterion             | Your Coverage                   | Recommended           | Status      |
|-----------------------|---------------------------------|-----------------------|-------------|
| Zahnersatz            | {from coverage_components}%     | ≥70% min / ≥80% rec'd | PASS/FAIL   |
| Zahnbehandlung        | {from coverage_components}%     | ≥70% min / ≥80% rec'd | PASS/FAIL   |
| PZR (cleaning)        | {included? / frequency}         | 2x/year included      | PASS/MISSING|
| Implantate            | {covered? / capped?}            | Covered if priority   | PASS/MISSING/N/A |
| Wartezeit             | {computed from start_date}      | ≤3 months (no is best)| INFO        |
| Staffelung year-1 cap | €{coverage_amount or Unlimited} | No Staffelung ideal   | INFO        |
```

Status logic:
- PASS: meets or exceeds minimum threshold from reference doc
- FAIL: below minimum threshold
- MISSING: component not found in coverage_components
- N/A: user selected "No implant concerns" in Phase 0
- INFO: informational only (no pass/fail binary)

**If no existing policy (`existing_policy == null`):**

Show benchmarks only (no "Your Coverage" column) and note:
"No Zahnzusatz policy found in your profile. Use the benchmark column to evaluate any new policy."

### 3.3 Staffelung Warning Block

ALWAYS show the Staffelung warning block, regardless of whether an existing policy is found or whether the user has immediate dental needs:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ⚠ STAFFELUNG (Annual Cap Escalation)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Most Zahnzusatz policies limit reimbursement in the first years:

| Policy Year | Typical Annual Zahnersatz Cap |
|-------------|-------------------------------|
| Year 1      | €500–1,000                    |
| Year 2      | €1,000–2,000                  |
| Year 3      | €2,000–3,500                  |
| Year 4+     | €3,500–unlimited              |

Read actual Staffelung pattern from reference doc — values above are illustrative.

WHY THIS MATTERS:
If you have immediate dental needs (crowns, implants, bridges planned),
a policy with Staffelung may reimburse only €500–1,000 in year 1 even if
your treatment costs €5,000+. You would bear the full gap above the cap.

Policies WITHOUT Staffelung exist but cost significantly more in premiums.
Weigh the higher premium against your expected near-term dental costs.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If user selected "Have upcoming dental work planned" or "Currently in treatment" in Phase 0, prepend an urgency notice:

```
🚨 URGENT: You indicated upcoming/active dental work. Check your year-1
Staffelung cap BEFORE proceeding — see table below.
```

---

## Phase 4: Cancellation Deadline Check

Read from profile: `renewal_date`, `kuendigungsfrist_months`, `sonderkundigungsrecht`.

**Compute standard cancellation deadline:**
```
cancellation_deadline = renewal_date minus kuendigungsfrist_months
days_until_deadline = cancellation_deadline minus today
```

**Display logic:**

If `sonderkundigungsrecht == true`:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ⚠ SONDERKÜNDIGUNGSRECHT OPEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your policy has an open special cancellation right. You can cancel within
4 weeks of the trigger event (premium increase or coverage change) with no
standard notice period.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Else if `days_until_deadline <= 30`:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ⚠ CANCELLATION WINDOW: {days_until_deadline} DAYS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your standard cancellation deadline is {cancellation_deadline}.
You have {days_until_deadline} days to cancel without penalty.
Renewal date: {renewal_date}
Notice period: {kuendigungsfrist_months} months
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Else if cancellation fields are present:
```
Next cancellation deadline: {cancellation_deadline}
({days_until_deadline} days — renewal on {renewal_date}, {kuendigungsfrist_months}-month notice required)
```

If cancellation fields are absent from profile:
```
Cancellation deadline: Unknown — add policy details via /finyx:insurance portfolio
```

**⚠ Zahnzusatz switching warning:**
```
IMPORTANT: Switching Zahnzusatz insurers means starting a new Wartezeit
(waiting period, typically 3 months) at the new insurer. Treatments begun
under the old policy may not be covered by the new policy.

STRONGLY DISCOURAGED: Cancelling mid-treatment. Complete ongoing dental work
before cancelling your existing Zahnzusatz policy.
```

---

## Phase 5: Research Agent

Spawn the research agent via the Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions
for Zahnzusatz (supplemental dental insurance).

insurance_type: zahnzusatz

User context:
dental_needs_urgency: {user_preferences.dental_needs_urgency}
implant_priority: {user_preferences.implant_priority}
kfo_relevance: {user_preferences.kfo_relevance}
existing_policy: {existing_policy != null ? "yes" : "no"}

Focus your research on:
1. Coverage criteria checklist for Zahnzusatz (what to demand from any policy)
2. Staffelung — which segments offer no-Staffelung options and at what premium premium difference
3. Implant coverage — how commonly included and typical caps
4. KFO (orthodontics) — child vs adult coverage norms
5. Red flags to watch for in Zahnzusatz policies

Load ${CLAUDE_SKILL_DIR}/references/germany/zahnzusatz.md for benchmarks.
Return your output wrapped in <insurance_research_result> tags.
```

Collect `<insurance_research_result>` from the agent output.

---

## Phase 6: Recommendation

Synthesize findings from Phases 3–5 into a clear recommendation.

**Reasoning framework:**

1. **If user has immediate dental needs AND policy has Staffelung (year-1 cap < €2,000):**
   Warn prominently that the year-1 cap likely covers a fraction of imminent treatment costs.
   Recommend either: (a) accepting the cap and planning treatment timing, or (b) seeking a no-Staffelung policy before treatment starts — noting the premium difference from research.

2. **If Zahnersatz reimbursement < 70%:**
   Flag as insufficient per reference doc minimum. Recommend upgrading to at least 70% (ideally ≥80%).

3. **If PZR not included:**
   Note that PZR is a standard inclusion in most comprehensive policies and its absence is a gap.

4. **If implant coverage is missing and user selected "May need implants in future":**
   Recommend adding implant coverage before a need arises — retroactive addition may not be possible.

5. **If no Bonusheft context mentioned:**
   Remind user to maintain biannual dental check-ups to grow their GKV Festzuschuss from 60% to 75%.

6. **If no existing policy:**
   Summarize what to look for in a new Zahnzusatz policy using benchmarks from the reference doc.

Present a concrete next step for the user:
- If a gap is identified: "Add your full Zahnzusatz policy details via `/finyx:insurance portfolio` to refine this analysis."
- If switching is appropriate: "Request comparison offers using the criteria checklist from the research report above."

Frame all recommendation language as "based on this analysis" — not as definitive advice.

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No Zahnzusatz policy in profile:**
No error — proceed with benchmark comparison using reference doc only. Notify user:
"No Zahnzusatz policy found in your profile. Showing benchmark guidance for policy evaluation."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the
expected <insurance_research_result> block. Re-run /finyx:insurance zahnzusatz to retry.
Benchmark comparison above is based on reference doc data only.
```

**Missing cancellation fields:**
Show "Unknown" gracefully — do not error. Prompt user to add details via portfolio sub-skill.

</error_handling>

<notes>

## Write Targets

This command writes NO files. All output is conversational advisory text.

## Staffelung Warning

The Staffelung warning block in Phase 3 is ALWAYS shown — even when the user has no existing policy and no immediate dental needs. This is a structural risk that every Zahnzusatz user should understand.

## Wartezeit and Switching

When recommending switching or upgrade, ALWAYS include the switching Wartezeit warning. New Zahnzusatz policies impose a fresh Wartezeit — typically 3 months for standard treatment, up to 8 months for prosthetics. Mid-treatment cancellation is a common user mistake that leaves claims uncovered.

## Sonderkündigungsrecht Reference

The reference doc lists three Sonderkündigungsrecht triggers: premium increase, claim settlement, and coverage term changes. The `sonderkundigungsrecht` flag in the profile indicates whether a window is currently open. The sub-skill does not compute this — it reads the flag as set by the document reader agent.

## KFO (Kieferorthopädie)

KFO (orthodontics) coverage is usually limited to children under 18. Adult orthodontics is commonly excluded or heavily capped. Relevant only when user selected "Have children under 18" in Phase 0.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/zahnzusatz.md` in Phase 3 for all benchmark values. Benchmarks must NOT be hardcoded — they must be read from the reference doc at runtime.

## Agent Scope

The research agent (`finyx-insurance-research-agent`) is generic and parameterized by `insurance_type: zahnzusatz`. Per §34d GewO compliance, it returns criteria and benchmarks only — no specific provider names or tariff rankings.

</notes>
