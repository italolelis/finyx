# Fahrradversicherung Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Fahrradversicherung (bicycle insurance) analysis: Neuwert benchmark comparison, e-bike coverage branch (Akkuschaden/Elektronikschaden), Hausrat overlap detection, cancellation deadline tracking, and criteria-based market research. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — Bike purchase value (text):**
"What is the current replacement value (Neuwert) of your bicycle in EUR? (Enter a number, e.g. 1500)"

**Question 2 — E-bike (singleSelect):**
"Is your bicycle an e-bike (Pedelec/S-Pedelec)?"
- Yes
- No

**Question 3 — Hausrat add-on (singleSelect):**
"Does your Hausratversicherung include a Fahrrad-Zusatz (bicycle add-on)?"
- Yes
- No
- Not sure
- No Hausrat policy

**Question 4 — Monthly budget (singleSelect):**
"What is your monthly budget for bicycle insurance?"
- Under €5/month
- €5–15/month
- €15–30/month
- No budget constraint

Store results as `user_preferences`:
```
user_preferences = {
  bike_value_eur: [number entered],
  is_ebike: [Yes/No],
  has_hausrat_fahrrad: [Yes/No/Not sure/No Hausrat policy],
  budget_range: [selected]
}
```

Pass `user_preferences` to the research agent in Phase 5.



## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

Read `$PROFILE_PATH` (resolved by the gate check above; the @-include is a project-local fast-path). Find the entry in `insurance.policies[]` where `type == "fahrrad"`.

Extract:
- `coverage_amount` — insured bicycle value in EUR (Neuwert)
- `premium_monthly` — monthly premium in EUR
- `coverage_components` — array of included coverage items
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes (may include Selbstbeteiligung info or lock requirements)

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**If profile is missing:** emit error (see error_handling) and stop.



## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► FAHRRADVERSICHERUNG
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
(GDV, Verbraucherzentrale, Stiftung Warentest). It does not constitute
a recommendation for any specific insurance product or provider.

Verify all coverage details with your insurer. This tool does not replace
advice from a licensed Versicherungsberater (§34d GewO).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 3: Coverage Benchmark Comparison

Read `${CLAUDE_SKILL_DIR}/references/germany/fahrrad.md` — specifically the "Coverage Benchmarks" section — to obtain current benchmark thresholds. Do NOT hardcode values; read them from the reference doc at runtime.

**IMPORTANT: Fahrradversicherung is sum-based. The benchmark is the bike's replacement value (Neuwert) entered in Phase 0.**

**If `has_hausrat_fahrrad == "Yes"` from Phase 0, emit the Hausrat overlap warning immediately after the benchmark table (see below).**

**If `existing_policy_found == true`:**

Build the comparison table using profile data vs benchmark values:

```
## Your Coverage vs Recommended Minimum

| Criterion | Your Coverage | Benchmark | Status |
|-----------|--------------|-----------|--------|
| Versicherungssumme | €{coverage_amount} | €{bike_value_eur} (Neuwert) | PASS/FAIL |
| Neuwertentschädigung | {found/not found in coverage_components} | Required | PASS/FAIL |
| Diebstahl | {found/not found in coverage_components} | Required | PASS/FAIL |
| Vandalismus | {found/not found in coverage_components} | Recommended | PASS/INFO |
| Selbstbeteiligung | {from notes or coverage_components, else Unknown} | €0–150 | INFO |
```

PASS/FAIL logic:
- Versicherungssumme: PASS if `coverage_amount >= bike_value_eur`; FAIL if below or unknown
- Neuwertentschädigung: PASS if found in `coverage_components[]`; FAIL if absent
- Diebstahl: PASS if found in `coverage_components[]`; FAIL if absent
- Vandalismus: PASS if found; INFO if absent (Recommended, not Required)
- Selbstbeteiligung: INFO status always (no hard pass/fail)

**E-bike branch — if `is_ebike == "Yes"` from Phase 0:**

Add these additional rows to the table:

```
| Akkuschaden | {found/not found in coverage_components} | Required (e-bike) | PASS/FAIL |
| Elektronikschaden | {found/not found in coverage_components} | Required (e-bike) | PASS/FAIL |
```

After the table, add the e-bike note:

```
E-bike battery replacement cost is EUR 500–2,000. Akkuschaden coverage is critical for e-bike owners.
Verify that your policy explicitly lists e-bike battery and motor coverage — standard bicycle policies
do not automatically extend to e-bike electronics.
```

**Hausrat overlap check — if `has_hausrat_fahrrad == "Yes"` from Phase 0:**

Emit immediately after the comparison table:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 HAUSRAT OVERLAP DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your Hausratversicherung includes a Fahrrad-Zusatz. Standalone
Fahrradversicherung may be redundant or only needed for coverage
exceeding your Hausrat limits.

Hausrat Fahrrad-Zusatz typically covers Diebstahl only and caps
coverage at €3,000–5,000. Compare your Hausrat Fahrrad-Zusatz limit
against your bike's Neuwert of €{bike_value_eur} before purchasing
or maintaining additional standalone coverage.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `existing_policy_found == false`:**

Show the benchmark-only table with this note:

```
No Fahrradversicherung policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized coverage comparison.

Reference benchmarks (GDV / Verbraucherzentrale / Stiftung Warentest):
```

Then show the benchmark table from the reference doc with a "Not recorded" column in place of "Your Coverage." Still apply the e-bike rows if `is_ebike == "Yes"` and the Hausrat overlap warning if `has_hausrat_fahrrad == "Yes"`.



## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Fahrradversicherung policy recorded — cancellation tracking not available."

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
You have {days_until_deadline} days to cancel your Fahrradversicherung policy.
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
for your Fahrradversicherung policy. This window typically lasts 4 weeks
from the triggering event (e.g., premium increase, claim settlement).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Fahrradversicherung.

insurance_type: fahrrad
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
bike_value_eur: {entered in Phase 0}
is_ebike: {Yes/No from Phase 0}
has_hausrat_fahrrad: {selected in Phase 0}
budget_range: {selected in Phase 0}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.



## Phase 6: Recommendation

Synthesize findings from Phase 3 (coverage gaps), Phase 4 (cancellation window), and Phase 5 (market context) into 2–3 paragraphs of advisory.

**If Hausrat overlap detected (`has_hausrat_fahrrad == "Yes"`):**
Lead the recommendation with the overlap analysis: "You indicated your Hausratversicherung includes a Fahrrad-Zusatz. Before evaluating standalone Fahrradversicherung, compare your Hausrat bicycle add-on's coverage limits against your bike's Neuwert of €{bike_value_eur}. If your Hausrat add-on cap covers the full replacement value and includes Vandalismus and accident damage, a standalone policy may be redundant."

**If e-bike without Akkuschaden (is_ebike == "Yes" AND Akkuschaden FAIL from Phase 3):**
Flag as critical gap: "CRITICAL GAP: Your e-bike is not covered for Akkuschaden. Battery replacement costs €500–2,000 and is one of the most common e-bike insurance claims. This gap should be resolved before your next renewal date."

**Coverage gaps (from Phase 3):**
- If Versicherungssumme is FAIL: "Your insured sum of €{coverage_amount} is below your bike's replacement value of €{bike_value_eur}. In a total loss, you would receive only €{coverage_amount} — a shortfall of €{bike_value_eur - coverage_amount}. Increase your Versicherungssumme to Neuwert."
- If Neuwertentschädigung is FAIL: "Your policy likely pays Zeitwert (depreciated value) rather than Neuwert (replacement cost). For a €{bike_value_eur} bicycle after 2 years, Zeitwert could mean a shortfall of 20–40%. Confirm payout basis with your insurer."
- For each other missing Required/Recommended component: flag with one-line explanation.

**Cancellation window (from Phase 4):**
- If within 30 days: "Your cancellation window is open. If the market research above identifies a better policy, act before {deadline_date}."
- If Sonderkündigungsrecht is open: "You have an extraordinary cancellation right — use it to switch if a better policy is found."

**Always include Neuwert adequacy assessment:**
"Ensure your insured sum stays current with your bicycle's replacement cost. Update your coverage after any significant bike upgrade or e-bike battery replacement."

**Always include concrete next steps:**
1. If coverage gaps found: "Run `/finyx:insurance portfolio` to update your coverage details, then return here to re-assess."
2. Market alternatives: reference the research agent output for criteria-based alternatives.
3. "Frame all decisions as advisory — consult a licensed Versicherungsberater for binding recommendations."

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**Reference doc read error:**
If `${CLAUDE_SKILL_DIR}/references/germany/fahrrad.md` cannot be read, proceed with Phase 3 benchmark table omitted and note: "Reference doc not available — benchmark comparison skipped. Re-run `/finyx:insurance fahrrad` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance fahrrad` to retry.
Coverage benchmark comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Sum-Based Coverage Type

Fahrradversicherung is sum-based: `coverage_amount` in profile.json holds the insured bicycle replacement value (Neuwert) in EUR. Phase 3 compares this sum against the user-entered bike_value_eur from Phase 0. This is the primary adequacy check.

## E-bike Branch Logic

If `is_ebike == "Yes"` from Phase 0, two additional rows are added to the Phase 3 comparison table (Akkuschaden, Elektronikschaden) and flagged as Required. The e-bike battery note is always appended. If Akkuschaden is FAIL and the user has an e-bike, Phase 6 leads with a CRITICAL GAP flag. Standard bicycle policies do not automatically extend to e-bike-specific components — explicit coverage_components entries are required.

## Hausrat Overlap Detection Rationale

Hausrat Fahrrad-Zusatz is a common add-on that covers bicycle theft up to a capped amount (typically €3,000–5,000) as part of the household contents policy. If the user has this add-on, a standalone Fahrradversicherung may be redundant — particularly for lower-value bicycles. The overlap warning in Phase 3 prompts the user to compare the Hausrat add-on limit against actual Neuwert before purchasing additional coverage. This prevents unnecessary double-insurance.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/fahrrad.md` directly in Phase 3 via the Read tool to get benchmark thresholds. Benchmarks must be read at runtime, not hardcoded.

## Lock Requirement Note

Many Fahrradversicherung policies require a qualified lock (qualifiziertes Schloss) for theft coverage. If `notes` or `coverage_components` mention lock requirements, surface this in Phase 6 with a reminder to verify the user's lock meets the insurer's specification. Failure to use an approved lock typically voids theft coverage.

</notes>
