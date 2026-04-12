# Kfz-Schutzbriefversicherung Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Kfz-Schutzbriefversicherung (motor breakdown assistance) analysis: overlap detection with existing Kfz policy and ADAC membership as the primary value driver, service component benchmark comparison, cancellation deadline tracking, and criteria-based market research. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — ADAC membership (singleSelect):**
"Do you have an ADAC membership (or equivalent auto club)?"
- Yes
- No

**Question 2 — Kfz policy Schutzbrief add-on (singleSelect):**
"Does your current Kfz insurance policy include a Schutzbrief add-on?"
- Yes
- No
- Not sure
- No Kfz policy

**Question 3 — Monthly budget range (singleSelect):**
"What is your monthly budget for breakdown assistance coverage?"
- Under €3/month
- €3–8/month
- €8–15/month
- No budget constraint

Store results as `user_preferences`:
```
user_preferences = {
  has_adac: [Yes/No],
  kfz_has_schutzbrief: [Yes/No/Not sure/No Kfz policy],
  budget_range: [selected]
}
```

Pass `user_preferences` to the research agent in Phase 5.



## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

Read `.finyx/profile.json` (already loaded by the router). Find the entry in `insurance.policies[]` where `type == "kfz-schutzbrief"`.

Extract:
- `coverage_amount` — null (service-based product; no fixed monetary sum)
- `premium_monthly` — monthly premium in EUR
- `coverage_components` — array of included service components
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes (may include geographic scope)

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**If profile is missing:** emit error (see error_handling) and stop.



## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► KFZ-SCHUTZBRIEF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Emit the full legal disclaimer from the loaded `disclaimer.md` (loaded by router):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

Then append:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 INSURANCE-SPECIFIC NOTICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This analysis evaluates coverage criteria based on published benchmarks
(GDV, ADAC, Verbraucherzentrale). It does not constitute a recommendation
for any specific insurance product or provider.

Verify all coverage details with your insurer. This tool does not replace
advice from a licensed Versicherungsberater (§34d GewO).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 3: Coverage Benchmark Comparison

Read `${CLAUDE_SKILL_DIR}/references/germany/kfz-schutzbrief.md` — specifically the "Coverage Benchmarks" section — to obtain the current benchmark thresholds. Do NOT hardcode values; read them from the reference doc at runtime.

This is a service-based insurance type. `coverage_amount` is null — there is no monetary sum benchmark. Assessment is based on service components only.

### 3.1 Kfz Policy Overlap Check (MUST come first)

Find the entry in `insurance.policies[]` where `type == "kfz"`.

**If a Kfz policy entry is found:**

Check the Kfz entry's `coverage_components` array for any of the following strings (case-insensitive substring match):
- "Schutzbrief"
- "Pannenhilfe"
- "Abschleppen"
- "ADAC-Schutzbrief"

If any of these strings are found in the Kfz coverage_components:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 OVERLAP DETECTED: Kfz Policy Includes Breakdown Coverage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your Kfz policy ({provider}) appears to include breakdown
assistance coverage. A standalone Kfz-Schutzbrief policy
may be redundant. Verify with your Kfz insurer before
purchasing additional coverage.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If none of these strings are found in the Kfz coverage_components: no overlap banner — proceed to ADAC check.

**If no Kfz policy entry is found in `insurance.policies[]`:**

Emit this info note (not an error):

```
Note: No Kfz policy found in your profile — cannot check for included Schutzbrief
coverage. Add your Kfz policy via `/finyx:insurance portfolio` to enable overlap detection.
```

### 3.2 ADAC Membership Check

If `has_adac == "Yes"` (from Phase 0 preferences):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ADAC MEMBERSHIP DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ADAC Vollmitgliedschaft provides equivalent or superior
breakdown coverage for all vehicles you drive — not just
owned vehicles. A standalone Schutzbrief policy is likely
redundant. Consider cancelling at next Kuendigungsfrist.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.3 Service Component Benchmark Table

**If `existing_policy_found == true`:**

Build the service component comparison table using profile data vs. reference doc benchmarks:

```
## Your Coverage vs Recommended Benchmarks

| Component         | Your Coverage                                         | Required    | Status       |
|-------------------|-------------------------------------------------------|-------------|--------------|
| Pannenhilfe       | {found in coverage_components / not found}            | Required    | PASS/FAIL    |
| Geographic scope  | {inland / EU-wide — from coverage_components or notes}| EU-wide     | PASS/WARN    |
| Abschleppen       | {found in coverage_components / not found}            | Required    | PASS/FAIL    |
| Mietwagen         | {found in coverage_components / not found}            | Recommended | PASS/INFO    |
| 24/7 Hotline      | {found in coverage_components / not found}            | Required    | PASS/FAIL    |
```

PASS/FAIL/WARN/INFO logic:
- Pannenhilfe: PASS if "Pannenhilfe" appears in `coverage_components[]`; FAIL if absent
- Geographic scope: PASS if "EU" or "Europa" or "europ" (case-insensitive) appears in `coverage_components[]` or `notes`; WARN if only "Inland" or "Deutschland" found
- Abschleppen: PASS if "Abschleppen" appears in `coverage_components[]`; FAIL if absent
- Mietwagen: PASS if "Mietwagen" or "Mietfahrzeug" appears in `coverage_components[]`; INFO if absent (recommended, not required)
- 24/7 Hotline: PASS if "Hotline" or "24/7" or "Notruf" appears in `coverage_components[]`; FAIL if absent

**If `existing_policy_found == false`:**

Show the benchmark table from the reference doc with a "Not recorded" column in place of "Your Coverage":

```
No Kfz-Schutzbrief policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized coverage comparison.

Reference benchmarks (GDV / ADAC / Verbraucherzentrale):
```

Then show the benchmark table with "Not recorded" as the Your Coverage column value for all rows.



## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Kfz-Schutzbrief policy recorded — cancellation tracking not available."

**If `existing_policy_found == true`:**

Check whether cancellation tracking fields are present: `start_date` AND `kuendigungsfrist_months`.

**If fields are missing:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CANCELLATION DEADLINE: UNKNOWN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Policy details not found. Add start date and cancellation
period via `/finyx:insurance portfolio` to track deadlines.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If fields are present:**

1. Compute Hauptfalligkeit: use `renewal_date` if present; otherwise compute next anniversary from `start_date` (same month/day, next year or current year if still in the future)
2. Compute `deadline = Hauptfalligkeit - kuendigungsfrist_months months`
3. Compute `days_until_deadline = deadline - today`

Cases:
- `days_until_deadline < 0` — deadline has passed: "Cancellation deadline for this renewal period has passed. Next opportunity: {next Hauptfalligkeit minus kuendigungsfrist_months}."
- `0 <= days_until_deadline <= 30` — emit ALERT banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CANCELLATION DEADLINE ALERT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You have {days_until_deadline} days to cancel your Kfz-Schutzbrief policy.
Deadline: {deadline_date} ({kuendigungsfrist_months} months before renewal on {renewal_date})

To cancel: contact {provider} in writing before {deadline_date}.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- `days_until_deadline > 30` — show informatively: "Next cancellation deadline: {deadline_date} ({days_until_deadline} days from today). Renewal date: {renewal_date}."

**Sonderkündigungsrecht check:**

If `sonderkundigungsrecht == true`, emit:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SONDERKÜNDIGUNGSRECHT OPEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You have an extraordinary cancellation right currently open
for your Kfz-Schutzbrief policy. This window typically lasts
4 weeks from the triggering event (e.g., premium increase,
claim settlement).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Kfz-Schutzbriefversicherung.

insurance_type: kfz-schutzbrief
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
has_adac: {Yes/No from Phase 0}
kfz_has_schutzbrief: {Yes/No/Not sure/No Kfz policy from Phase 0}
budget_range: {selected in Phase 0}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.



## Phase 6: Recommendation

Overlap detection is the PRIMARY value of this sub-skill. Lead the recommendation section with overlap findings before any other analysis.

**Overlap synthesis (lead with this):**

- If BOTH Kfz policy overlap AND ADAC membership detected: emit strong recommendation:
  "Both your Kfz policy and your ADAC membership appear to include breakdown coverage. A standalone Kfz-Schutzbrief policy is very likely redundant — strongly consider cancelling at your next Kuendigungsfrist to eliminate duplicate coverage."
- If only Kfz policy overlap detected: "Your Kfz policy ({provider}) appears to include Schutzbrief coverage. Verify the exact scope with your insurer before keeping or purchasing a standalone policy."
- If only ADAC membership detected: "Your ADAC Vollmitgliedschaft covers breakdown assistance for all vehicles you drive — not just your own vehicle. A standalone Schutzbrief policy is likely redundant."
- If neither overlap detected: proceed with standard gap and market synthesis.

**ADAC vs. Schutzbrief scope note (always include):**

"Note: ADAC Vollmitgliedschaft covers the member across any vehicle they drive, while a standalone Schutzbrief policy covers only the insured vehicle. If you regularly drive other vehicles, ADAC membership provides broader coverage."

**Coverage gaps (from Phase 3):**
- For each FAIL component: flag explicitly with a one-line explanation.
- If geographic scope is WARN (Inland only): "Your coverage is limited to Germany. EU-wide coverage is the recommended minimum for any travel abroad — upgrade or purchase accordingly."

**Cancellation window (from Phase 4):**
- If within 30 days: "Your cancellation window is open. If the overlap analysis above confirms redundancy, act before {deadline_date}."
- If Sonderkündigungsrecht is open: "You have an extraordinary cancellation right — use it to cancel the redundant policy."

**Always include concrete next steps:**
1. If overlaps detected: "Consider cancelling at the next Kuendigungsfrist. Verify scope of Kfz add-on with your insurer before cancelling."
2. If no overlaps: reference the research agent output for criteria-based market alternatives.
3. "Frame all decisions as advisory — consult a licensed Versicherungsberater for binding recommendations."

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**Reference doc read error:**
If `${CLAUDE_SKILL_DIR}/references/germany/kfz-schutzbrief.md` cannot be read, proceed with Phase 3 benchmark table omitted and note: "Reference doc not available — benchmark comparison skipped. Re-run `/finyx:insurance kfz-schutzbrief` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance kfz-schutzbrief` to retry.
Coverage benchmark comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Service-Based Type

Kfz-Schutzbriefversicherung is a service-based product — the insurer dispatches a tow truck, books a rental car, or arranges hotel accommodations. There is no fixed monetary indemnity sum. `coverage_amount` is always null for this type. Phase 3 assesses service components, not monetary sums.

## Overlap Detection as Primary Value

The defining feature of this sub-skill is overlap detection. Many users already have equivalent breakdown coverage via:
1. ADAC Vollmitgliedschaft — covers member across all vehicles they drive
2. Kfz policy Schutzbrief add-on — covers the insured vehicle

Checking for these overlaps before recommending market research prevents wasteful duplicate coverage. Phase 3.1 (Kfz overlap) always runs before Phase 3.2 (ADAC check) and before the component benchmark table.

## Kfz Policy Guard

If no Kfz policy entry (`type == "kfz"`) is found in `insurance.policies[]`, this is an informational note — NOT an error. The user may simply not have recorded their Kfz policy in Finyx yet. Emit the info note and continue with ADAC check and component benchmark.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/kfz-schutzbrief.md` directly in Phase 3 via the Read tool to get benchmark thresholds. This is intentional — benchmarks must be read at runtime, not hardcoded.

## ADAC Coverage Scope

ADAC Vollmitgliedschaft (full membership) covers the member across any vehicle they drive — not just owned vehicles. A standalone Schutzbrief policy covers only the registered insured vehicle. This distinction is important when the user drives company cars or borrows vehicles regularly.

</notes>
