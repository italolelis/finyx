# Reiseversicherung Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Reiseversicherung (travel insurance) analysis: service-based coverage component check with GKV gap warning, cancellation deadline tracking, and criteria-based market research. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — Policy scope (singleSelect):**
"What type of travel insurance policy do you have or are you looking for?"
- Annual policy (Jahreskarte)
- Single-trip (Einmalreise)
- Not sure / no policy yet

**Question 2 — Travel region (singleSelect):**
"What regions do you typically travel to?"
- Within Europe (EU/EEA)
- Worldwide including long-haul
- Both, depending on trip

**Question 3 — Monthly budget (singleSelect):**
"What is your monthly budget for travel insurance?"
- Under €5/month
- €5–15/month
- €15–30/month
- No budget constraint

Store results as `user_preferences`:
```
user_preferences = {
  policy_scope: [selected],
  travel_region: [selected],
  budget_range: [selected]
}
```

Pass `user_preferences` to the research agent in Phase 5.



## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

Read `.finyx/profile.json` (already loaded by the router). Find the entry in `insurance.policies[]` where `type == "reise"`.

Extract:
- `coverage_amount` — null for service-based types
- `premium_monthly` — monthly premium in EUR
- `coverage_components` — array of included coverage items
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes (may include per-trip duration limit or Einmalreise indication)

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**If profile is missing:** emit error (see error_handling) and stop.



## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► REISEVERSICHERUNG
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

Read `${CLAUDE_SKILL_DIR}/references/germany/reise.md` — specifically the "Coverage Benchmarks" section — to obtain current benchmark components. Do NOT hardcode values; read them from the reference doc at runtime.

**IMPORTANT: Reiseversicherung is service-based — coverage_amount is null. Do NOT use a sum-based benchmark. Evaluate by component presence.**

**Always emit the GKV gap warning unconditionally, before the comparison table:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 IMPORTANT: GKV COVERAGE GAP WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Gesetzliche Krankenversicherung (GKV) provides limited coverage abroad.
EU countries: The EHIC card covers emergency treatment only — it does NOT
cover medical repatriation (Krankenrücktransport), which can cost
€50,000–€300,000. Non-EU countries: GKV provides no coverage whatsoever.

Auslandskrankenversicherung is essential for all international travel,
regardless of existing GKV membership.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `existing_policy_found == true`:**

Build the component presence table using profile data vs reference doc benchmarks:

```
## Your Coverage vs Recommended Components

| Component | Your Coverage | Required | Status |
|-----------|--------------|----------|--------|
| Auslandskrankenversicherung | {found/not found in coverage_components} | Required | PASS/FAIL |
| Krankenrücktransport | {found/not found in coverage_components} | Required | PASS/FAIL |
| Reiserücktritt | {found/not found in coverage_components} | Recommended | PASS/INFO |
| Reisegepäck | {found/not found in coverage_components} | Optional | INFO |
| Reiseabbruch | {found/not found in coverage_components} | Recommended | PASS/INFO |
| Per-trip duration limit | {days from coverage_components or notes, else Unknown} | ≥42 days | PASS/WARN |
```

PASS/FAIL logic:
- Auslandskrankenversicherung: PASS if found in `coverage_components[]`; FAIL if absent
- Krankenrücktransport: PASS if found in `coverage_components[]`; FAIL if absent
- Reiserücktritt: PASS if found; INFO if absent (Recommended, not Required)
- Reisegepäck: INFO status always (Optional)
- Reiseabbruch: PASS if found; INFO if absent (Recommended, not Required)
- Per-trip duration limit: PASS if ≥42 days found in notes or coverage_components; WARN if unknown or less than 42 days

**If `existing_policy_found == false`:**

Show the benchmark-only table with this note:

```
No Reiseversicherung policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized coverage comparison.

Reference benchmarks (GDV / Verbraucherzentrale / Stiftung Warentest):
```

Then show the component benchmark table from the reference doc with a "Not recorded" column in place of "Your Coverage."



## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Reiseversicherung policy recorded — cancellation tracking not available."

**Check for single-trip policy:**

If `policy_scope == "Einmalreise"` from Phase 0 preferences, OR if `notes` or `coverage_components` contain "Einmalreise" (case-insensitive check), skip Phase 4 with this note:

```
Single-trip policies (Einmalreise) are non-cancellable once issued — the policy terminates
automatically at the end of the covered trip. Cancellation deadline tracking is not applicable.
```

**If `existing_policy_found == true` and annual policy (Jahreskarte):**

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
You have {days_until_deadline} days to cancel your Reiseversicherung policy.
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
for your Reiseversicherung policy. This window typically lasts 4 weeks
from the triggering event (e.g., premium increase, claim settlement).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Reiseversicherung.

insurance_type: reise
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
policy_scope: {selected in Phase 0 — Jahreskarte / Einmalreise / Not sure}
travel_region: {selected in Phase 0}
budget_range: {selected in Phase 0}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.



## Phase 6: Recommendation

Synthesize findings from Phase 3 (coverage gaps), Phase 4 (cancellation window), and Phase 5 (market context) into 2–3 paragraphs of advisory.

**Always open with the GKV adequacy statement:**
"GKV coverage abroad is insufficient for safe international travel. Auslandskrankenversicherung is the single most important travel insurance component — it covers unlimited medical costs and, critically, the Krankenrücktransport (medical repatriation) that can cost €50,000–€300,000."

**Coverage gaps (from Phase 3):**
- If Auslandskrankenversicherung is FAIL: "Your policy does not include Auslandskrankenversicherung — this is a critical gap. Without it, you have no coverage for foreign medical costs or repatriation."
- If Krankenrücktransport is FAIL: "Your policy does not include Krankenrücktransport. Medical repatriation to Germany can cost €50,000–€300,000 — this gap should be resolved immediately."
- If per-trip duration limit is WARN or unknown: "Your policy may have a per-trip duration cap below 42 days. Verify your Reisedauer limit with {provider} — coverage lapses entirely for any day that exceeds the cap."
- For each other missing Recommended component: flag explicitly with a one-line explanation.

**Annual vs. single-trip recommendation (if policy_scope is "Not sure" from Phase 0):**
"If you take more than 2–3 trips per year, an annual Jahreskarte is almost always more cost-effective than purchasing individual Einmalreise policies. Compare total Einmalreise premiums against the Jahreskarte annual cost."

**If policy_scope is "Einmalreise":**
"Note: purchasing a new single-trip policy per journey may become more expensive than an annual Jahreskarte above approximately 2–3 trips per year. Consider switching to a Jahreskarte if your travel frequency increases."

**Cancellation window (from Phase 4, annual policies only):**
- If within 30 days: "Your cancellation window is open. If the market research above identifies a better policy, act before {deadline_date}."
- If Sonderkündigungsrecht is open: "You have an extraordinary cancellation right — use it to switch if a better policy is found."

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
If `${CLAUDE_SKILL_DIR}/references/germany/reise.md` cannot be read, proceed with Phase 3 benchmark table omitted and note: "Reference doc not available — benchmark comparison skipped. Re-run `/finyx:insurance reise` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance reise` to retry.
Coverage benchmark comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Service-Based Coverage Type

Reiseversicherung is service-based: the insurer pays actual costs per event (medical bills, repatriation, trip cancellation costs). There is no fixed monetary sum insured. `coverage_amount` in profile.json is null for reise type. Phase 3 never applies a sum-based benchmark — it evaluates component presence only.

## Einmalreise Cancellation Skip Logic

If `policy_scope == "Einmalreise"` (from Phase 0) OR if the policy notes/coverage_components contain "Einmalreise", Phase 4 is skipped with an explanatory note. Single-trip policies are non-cancellable once issued and terminate automatically at trip end. This is not a gap — it is a structural property of the product.

## GKV Gap Warning Rationale

The GKV gap warning is emitted unconditionally in Phase 3 (before the comparison table) and referenced again in Phase 6. This is intentional: GKV coverage abroad is a widespread misconception. Even users with existing Reiseversicherung should be reminded that the EHIC card is insufficient for full travel coverage. The warning is not conditional on missing coverage — it is educational context that applies universally.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/reise.md` directly in Phase 3 via the Read tool to get benchmark components. Benchmarks must be read at runtime, not hardcoded.

## Per-Trip Duration Limit

Many annual travel policies cap individual trip duration at 42 days. Travelers taking extended trips (sabbaticals, long-haul journeys) must verify this limit. The per-trip duration limit is checked in Phase 3 from the `notes` field or `coverage_components` entries. If unknown, emit WARN status.

</notes>
