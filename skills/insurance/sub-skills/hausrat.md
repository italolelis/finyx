# Hausrat Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Hausratversicherung (household contents insurance) analysis: living-area-based Versicherungssumme benchmark computation (€650/m²), Unterversicherungsverzicht check, cancellation deadline tracking including Umzug/address-change Sonderkündigungsrecht, and criteria-based market research. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — Living area (text input):**
"What is your apartment or house living area in square meters (Wohnfläche)?
This is needed to compute your minimum recommended Versicherungssumme (€650/m²).
Leave blank if unknown — we will note this in the analysis."
(Free text; accept numeric values like "75" or "75.5"; treat blank or non-numeric as unknown)

**Question 2 — Elementarschäden interest (singleSelect):**
"Are you interested in Elementarschäden coverage (flooding, earthquake, landslide)?"
- Yes, important to me
- No, not needed
- Not sure — include in analysis

**Question 3 — Fahrrad-Zusatz interest (singleSelect):**
"Do you own valuable bicycles you would like covered?"
- Yes — have bikes worth more than €500
- No
- Not sure

Store results as `user_preferences`:
```
user_preferences = {
  living_area_sqm: [numeric or null],
  elementar_interest: [selected],
  fahrrad_interest: [selected]
}
```

The `living_area_sqm` from Phase 0 is critical for Phase 3 benchmark computation.

Pass `user_preferences` to the research agent in Phase 5.

## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

Read `$PROFILE_PATH` (resolved by the gate check above; the @-include is a project-local fast-path). Find the entry in `insurance.policies[]` where `type == "hausrat"`.

Extract:
- `coverage_amount` — Versicherungssumme in EUR (e.g., 48750)
- `premium_monthly` — monthly premium in EUR
- `coverage_components` — array of included coverage items (e.g., ["Einbruchdiebstahl", "Leitungswasser", "Elementarschäden"])
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period in months
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes (may include Selbstbeteiligung info)

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**Living area fallback:** If the user did not provide `living_area_sqm` in Phase 0 (blank or unknown), check the profile for a living area field:
- Check `investor.livingAreaSqm`, `criteria.minSize`, or any field containing "sqm", "wohnflaeche", "living_area", or "area_sqm"
- If found: set `living_area_sqm` to that value
- If not found in either Phase 0 or profile: set `living_area_sqm = null`

**If profile is missing:** emit error (see error_handling) and stop.

## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► HAUSRAT
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
(GDV, Verbraucherzentrale, Stiftung Warentest). The €650/m² benchmark
is a GDV/Verbraucherzentrale recommendation, not a legal minimum.

Actual replacement value of your household contents may exceed this
benchmark. Verify all coverage details with your insurer. This tool
does not replace advice from a licensed Versicherungsberater (§34d GewO).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 3: Coverage Benchmark Comparison

Read `${CLAUDE_SKILL_DIR}/references/germany/hausrat.md` — specifically the "Coverage Benchmarks" section and the "Versicherungssumme calculation" block — to obtain the current benchmark thresholds and the €650/m² multiplier. Do NOT hardcode values; read them from the reference doc at runtime.

**Compute the benchmark sum:**

If `living_area_sqm` is known (from Phase 0 or profile fallback):
```
minimum_sum = living_area_sqm × 650
```
Example: 75m² → minimum_sum = €48,750

If `living_area_sqm` is null: mark adequacy as UNKNOWN (do not skip Phase 3 entirely — show the benchmark table with UNKNOWN in the status column).

**If `existing_policy_found == true`:**

Build the comparison table:

```
## Your Coverage vs Recommended Minimum

| Criterion                  | Your Coverage                                       | Recommended Minimum              | Status  |
|----------------------------|-----------------------------------------------------|----------------------------------|---------|
| Versicherungssumme         | €{coverage_amount}                                  | ≥€{living_area_sqm × 650}        | PASS/FAIL/UNKNOWN |
| Unterversicherungsverzicht | {Included/Not found in coverage_components}         | Required                         | PASS/FAIL |
| Einbruchdiebstahl          | {Included/Not found in coverage_components}         | Included                         | PASS/FAIL |
| Leitungswasser             | {Included/Not found in coverage_components}         | Included                         | PASS/FAIL |
| Elementarschäden           | {Included/Not found in coverage_components}         | Recommended in risk areas        | INFO |
| Fahrrad-Zusatz             | {Included/Not found in coverage_components}         | Up to €3,000–5,000 if needed     | INFO |
```

PASS/FAIL logic:
- Versicherungssumme: PASS if `coverage_amount >= minimum_sum`; FAIL if below; UNKNOWN if `living_area_sqm` is null
- If FAIL: compute and show the gap: "Coverage gap: €{minimum_sum - coverage_amount} below minimum"
- Unterversicherungsverzicht: PASS if present in `coverage_components[]`; FAIL if absent (critical — flag prominently)
- Einbruchdiebstahl, Leitungswasser: PASS if present in `coverage_components[]`; FAIL if absent
- Elementarschäden, Fahrrad-Zusatz: INFO status (context-dependent, not hard PASS/FAIL)

**Unterversicherungsverzicht FAIL special handling:** If this criterion is FAIL, add a prominent note:
"WARNING: Without Unterversicherungsverzicht, your insurer can pay proportionally less than your actual loss if your Versicherungssumme is below the replacement value of your contents. This is the most common failure mode in Hausrat claims."

**If `existing_policy_found == false`:**

```
No Hausrat policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized coverage comparison.

Reference benchmarks (GDV / Verbraucherzentrale):
```

Show the benchmark table from the reference doc with a "Not recorded" column in place of "Your Coverage."

If `living_area_sqm` is known: also show "Your estimated minimum Versicherungssumme: €{living_area_sqm × 650} (based on {living_area_sqm}m² at €650/m²)."

If `living_area_sqm` is null: "Provide your living area to compute a personalized minimum Versicherungssumme — the €650/m² benchmark requires this input."

## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Hausrat policy recorded — cancellation tracking not available."

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

1. Compute Hauptfalligkeit: use `renewal_date` if present; otherwise compute next anniversary from `start_date`
2. Compute `deadline = Hauptfalligkeit - kuendigungsfrist_months months`
3. Compute `days_until_deadline = deadline - today`

Cases:
- `days_until_deadline < 0` — deadline passed: "Cancellation deadline for this renewal period has passed. Next opportunity: {next Hauptfalligkeit minus kuendigungsfrist_months}."
- `0 <= days_until_deadline <= 30` — emit ALERT banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CANCELLATION DEADLINE ALERT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You have {days_until_deadline} days to cancel your Hausrat policy.
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
for your Hausrat policy. This window typically lasts 4 weeks
from the triggering event (e.g., premium increase, claim settlement).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Umzug (address change) note:** Always include this note when a policy is found:
"Note: If you move to a new address (Umzug), you must notify your insurer. If the premium increases due to the new address risk class, you have a Sonderkündigungsrecht — typically 4 weeks from the premium increase notification. Your policy provides temporary coverage at both addresses during the move."

## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Hausratversicherung.

insurance_type: hausrat
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
living_area_sqm: {value or unknown}
elementar_interest: {selected in Phase 0}
fahrrad_interest: {selected in Phase 0}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.

## Phase 6: Recommendation

Synthesize findings from Phase 3 (coverage gaps), Phase 4 (cancellation window), and Phase 5 (market context) into 2–3 paragraphs of advisory.

Reasoning framework:

**Versicherungssumme gap (from Phase 3):**
- If FAIL: "Your current Versicherungssumme of €{coverage_amount} is €{gap} below the recommended minimum of €{minimum_sum} (based on {living_area_sqm}m² × €650/m²). Underinsurance means partial claim payouts — switching to adequate coverage is the highest-priority action."
- If UNKNOWN: "Provide your living area via `/finyx:profile` or re-run this analysis to compute a personalized benchmark."

**Unterversicherungsverzicht gap:**
- If FAIL: "Unterversicherungsverzicht is missing from your policy. This means your insurer can proportionally reduce claim payouts if your sum insured is found to be below replacement value. Request this clause be added at your next renewal."

**Elementarschäden (if user expressed interest in Phase 0):**
- Include: "You indicated interest in Elementarschäden coverage. If your location has flood or landslide risk, this add-on is worth the premium — verify your local risk classification at zuers.de before deciding."

**Cancellation window:**
- If within 30 days: "Your cancellation window is open. If the market research identifies better coverage, act before {deadline_date}."
- If Sonderkündigungsrecht is open: "Use the open extraordinary cancellation right to switch if a better policy is found."

**Always include concrete next steps:**
1. If coverage gaps found: update policy or switch at next renewal
2. If living area unknown: "Add your Wohnfläche to your profile via `/finyx:profile`"
3. Market alternatives: reference research agent output for criteria-based options
4. "Frame all decisions as advisory — consult a licensed Versicherungsberater for binding recommendations."

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**Reference doc read error:**
If `${CLAUDE_SKILL_DIR}/references/germany/hausrat.md` cannot be read, proceed with Phase 3 benchmark table omitted and note: "Reference doc not available — benchmark comparison skipped. Re-run `/finyx:insurance hausrat` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance hausrat` to retry.
Coverage benchmark comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Living Area Dependency

The €650/m² benchmark requires `living_area_sqm`. Sources in priority order:
1. User input in Phase 0 (most direct)
2. Profile field lookup: `investor.livingAreaSqm`, `criteria.minSize`, or any sqm-related field
3. If both absent: mark adequacy as UNKNOWN — do NOT skip Phase 3

Never skip Phase 3 entirely due to missing living area — always show the benchmark table with UNKNOWN status and prompt the user to provide the data.

## Unterversicherungsverzicht Importance

This clause is critical. Without it, the insurer applies Unterversicherungseinwand: if the sum insured is €30,000 but the replacement value of contents is €50,000, the insurer pays only 60% of any claim (30/50 ratio). The clause waives this pro-ration when the sum meets the threshold. Always flag its absence as a high-priority gap.

## Umzug Sonderkündigungsrecht

An address change (Umzug) is a risk event for Hausrat insurers. The new address may be in a higher risk class (e.g., burglary statistics, flood zone). If the premium increases, the insured has a Sonderkündigungsrecht within 4 weeks of receiving the new premium notice. Always mention this in Phase 4 when a policy is present — it's a commonly missed right.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/hausrat.md` directly in Phase 3 via the Read tool to get benchmark thresholds (including the €650/m² multiplier). Read from the reference doc — do not hardcode the multiplier.

</notes>
