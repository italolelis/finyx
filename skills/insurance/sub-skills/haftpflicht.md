# Privathaftpflicht Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Privathaftpflicht (personal liability) analysis: coverage benchmark comparison against the ≥€5M Deckungssumme standard, cancellation deadline tracking, and criteria-based market research. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — Monthly budget range (singleSelect):**
"What is your monthly budget for personal liability insurance?"
- Under €5/month
- €5–10/month
- €10–15/month
- €15+/month
- No budget constraint

**Question 2 — Renting status (singleSelect):**
"Do you currently rent your home?"
- Yes — renting
- No — homeowner

**Question 3 — Pets (singleSelect):**
"Do you have pets?"
- No pets
- Dog(s)
- Cat(s) only
- Other pets

Store results as `user_preferences`:
```
user_preferences = {
  budget_range: [selected],
  renting: [yes/no],
  pets: [type]
}
```

Pass `user_preferences` to the research agent in Phase 5.



## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

Read `$PROFILE_PATH` (resolved by the gate check above; the @-include is a project-local fast-path). Find the entry in `insurance.policies[]` where `type == "haftpflicht"`.

Extract:
- `coverage_amount` — Deckungssumme in EUR (e.g., 5000000)
- `premium_monthly` — monthly premium in EUR
- `coverage_components` — array of included coverage items
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes (may include Selbstbeteiligung info)

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**If profile is missing:** emit error (see error_handling) and stop.



## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► PRIVATHAFTPFLICHT
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

Read `${CLAUDE_SKILL_DIR}/references/germany/haftpflicht.md` — specifically the "Coverage Benchmarks" section — to obtain the current benchmark thresholds. Do NOT hardcode values; read them from the reference doc at runtime.

**If `existing_policy_found == true`:**

Build the comparison table using profile data vs reference doc benchmarks:

```
## Your Coverage vs Recommended Minimum

| Criterion               | Your Coverage                          | Recommended Minimum | Status |
|-------------------------|----------------------------------------|---------------------|--------|
| Deckungssumme           | €{coverage_amount}                     | ≥€5,000,000         | PASS/FAIL |
| Mietsachschaden         | {Included/Not found in coverage_components} | Included       | PASS/FAIL |
| Schlüsselverlust        | {Included/Not found in coverage_components} | Included       | PASS/FAIL |
| Gefälligkeitsschäden    | {Included/Not found in coverage_components} | Included       | PASS/FAIL |
| Forderungsausfalldeckung| {Included/Not found in coverage_components} | Included       | PASS/FAIL |
| Selbstbeteiligung       | {from notes or coverage_components, else Unknown} | €0–150    | INFO |
```

PASS/FAIL logic:
- Deckungssumme: PASS if `coverage_amount >= 5000000` (read exact threshold from reference doc "Minimum Acceptable" column)
- Coverage components (Mietsachschaden, Schlüsselverlust, Gefälligkeitsschäden, Forderungsausfalldeckung): PASS if the item appears in `coverage_components[]`; FAIL if absent or array is empty
- Selbstbeteiligung: INFO status (no hard pass/fail)

**If `existing_policy_found == false`:**

Show the benchmark table with reference doc values only, with this note:

```
No Haftpflicht policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized coverage comparison.

Reference benchmarks (GDV / Verbraucherzentrale):
```

Then show the benchmark table from the reference doc with a "Not recorded" column in place of "Your Coverage."



## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Haftpflicht policy recorded — cancellation tracking not available."

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
You have {days_until_deadline} days to cancel your Haftpflicht policy.
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
for your Haftpflicht policy. This window typically lasts 4 weeks
from the triggering event (e.g., premium increase, claim settlement).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Privathaftpflicht insurance.

insurance_type: haftpflicht
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
budget_range: {selected in Phase 0}
renting: {yes/no from Phase 0}
pets: {type from Phase 0}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.



## Phase 6: Recommendation

Synthesize findings from Phase 3 (coverage gaps), Phase 4 (cancellation window), and Phase 5 (market context) into 2–3 paragraphs of advisory.

Reasoning framework:

**Coverage gaps (from Phase 3):**
- If Deckungssumme is FAIL: "Your current Deckungssumme of €{coverage_amount} is below the recommended minimum of €5,000,000. Consider upgrading to a policy with ≥€10,000,000 Deckungssumme — premium difference is typically minimal."
- If Mietsachschaden is FAIL and user is renting: "You are renting but Mietsachschaden is not included in your policy. Damage to your rented apartment would not be covered — this is a critical gap."
- For each other missing component: flag explicitly with a one-line explanation.

**Cancellation window (from Phase 4):**
- If within 30 days: "Your cancellation window is open. If the market research above identifies a better policy, act before {deadline_date}."
- If Sonderkündigungsrecht is open: "You have an extraordinary cancellation right — use it to switch if a better policy is found."

**Pets note (always, if dogs selected in Phase 0):**
"Important: Privathaftpflichtversicherung does NOT cover dog liability. If you own dogs, a separate Hundehaftpflichtversicherung is required by law in most German states."

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
If `${CLAUDE_SKILL_DIR}/references/germany/haftpflicht.md` cannot be read, proceed with Phase 3 benchmark table omitted and note: "Reference doc not available — benchmark comparison skipped. Re-run `/finyx:insurance haftpflicht` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance haftpflicht` to retry.
Coverage benchmark comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Hundehaftpflicht Overlap

Privathaftpflichtversicherung does NOT cover dog owner liability (Hundehalterhaftpflicht). If the user has dogs (collected in Phase 0), always flag this in Phase 6. Most German states (including Bayern, Hamburg, Berlin) require Hundehaftpflicht by law. Check `coverage_components` for any explicit dog liability inclusion — if present, note it; if absent, flag the gap.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/haftpflicht.md` directly in Phase 3 via the Read tool to get benchmark thresholds. This is intentional — benchmarks must be read at runtime, not hardcoded.

## Benchmark Source

Benchmark thresholds (Coverage Benchmarks section in haftpflicht.md) come from GDV and Verbraucherzentrale. The reference doc has a "Minimum Acceptable" column and a "Recommended" column. Phase 3 uses "Minimum Acceptable" for PASS/FAIL and notes the "Recommended" value where higher.

## Sub-skill Complexity

Haftpflicht is the simplest sub-skill type: sum-based coverage_amount, straightforward PASS/FAIL on Deckungssumme, and a fixed list of coverage components to check. No computed benchmarks (unlike Hausrat) and no module-based logic (unlike Rechtsschutz).

</notes>
