# Mietkautionsversicherung Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Mietkautionsversicherung (rental deposit insurance) analysis: rent-derived §551 BGB benchmark computation, mandatory Regresspflicht warning, premium rate assessment, landlord acceptance check, and criteria-based market research. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — Nettokaltmiete (text, REQUIRED):**
"What is your monthly net cold rent (Nettokaltmiete) in EUR? This is needed to compute the §551 BGB deposit cap."

- If the user skips or enters 0: set `nettokaltmiete = null` and flag that benchmark comparison will be limited.
- If a valid positive number is entered: store as `nettokaltmiete` (numeric, EUR).

**Question 2 — Landlord acceptance (singleSelect):**
"Has your landlord accepted a Mietkaution insurance guarantee (Mietbürgschaft) as deposit replacement?"
- Yes
- No
- Not yet discussed

**Question 3 — Monthly budget range (singleSelect):**
"What is your monthly budget for rental deposit insurance?"
- Under €5/month
- €5–15/month
- €15–30/month
- No budget constraint

Store results as `user_preferences`:
```
user_preferences = {
  nettokaltmiete: [number or null],
  landlord_accepted: [Yes/No/Not yet discussed],
  budget_range: [selected]
}
```

Pass `user_preferences` to the research agent in Phase 5.



## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

Read `$PROFILE_PATH` (resolved by the gate check above; the @-include is a project-local fast-path). Find the entry in `insurance.policies[]` where `type == "mietkaution"`.

Extract:
- `coverage_amount` — guaranteed deposit amount in EUR (the Bürgschaftssumme)
- `premium_monthly` — monthly premium in EUR
- `premium_annual` — annual premium in EUR (use if monthly not set; divide by 12)
- `coverage_components` — array of included coverage items
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**If profile is missing:** emit error (see error_handling) and stop.



## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► MIETKAUTIONSVERSICHERUNG
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
(§551 BGB, Verbraucherzentrale, GDV). It does not constitute a recommendation
for any specific insurance product or provider.

Verify all coverage details with your insurer. This tool does not replace
advice from a licensed Versicherungsberater (§34d GewO).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 3: Coverage Benchmark Comparison

Read `${CLAUDE_SKILL_DIR}/references/germany/mietkaution.md` — specifically the "Coverage Benchmarks" section — to obtain the current benchmark thresholds. Do NOT hardcode values; read them from the reference doc at runtime.

This is a sum-based insurance type. The benchmark is COMPUTED from Phase 0 input: `recommended_deposit = nettokaltmiete * 3` (per §551 BGB).

### 3.1 Computed Benchmark

**If `nettokaltmiete` is null (user skipped or entered 0):**

Emit:
```
Nettokaltmiete not provided — cannot compute §551 BGB benchmark.
Re-run with your monthly rent to see a personalized assessment.
```

Skip the comparison table and proceed to the Regresspflicht warning (Section 3.2).

**If `nettokaltmiete` is provided (positive number):**

Compute:
- `recommended_deposit = nettokaltmiete * 3`
- `premium_rate_pct` = if `existing_policy_found == true` AND `premium_annual` is known: `premium_annual / coverage_amount * 100` (expressed as %)

**If `existing_policy_found == true`:**

Build the comparison table:

```
## Your Coverage vs §551 BGB Benchmark

| Criterion                     | Your Coverage                                                       | Benchmark                                              | Status |
|-------------------------------|----------------------------------------------------------------------|--------------------------------------------------------|--------|
| Guarantee amount              | EUR {coverage_amount}                                               | EUR {nettokaltmiete * 3} (3× Kaltmiete per §551 BGB)  | PASS if coverage_amount >= computed |
| Max legal cap (§551 BGB)      | —                                                                   | EUR {nettokaltmiete * 3}                               | INFO   |
| Premium rate                  | {premium_annual / coverage_amount * 100}% of guarantee/year        | 3–5% of guarantee/year                                 | PASS/WARN |
```

PASS/FAIL/WARN/INFO logic:
- Guarantee amount: PASS if `coverage_amount >= recommended_deposit`; FAIL if `coverage_amount < recommended_deposit`
- Max legal cap: always INFO (informational reference only)
- Premium rate: PASS if `premium_rate_pct` is between 3% and 5%; WARN if `premium_rate_pct > 5%` (above market rate); INFO if below 3% (unusually low — flag to verify)

**If `existing_policy_found == false`:**

Show the benchmark table from the reference doc with a "Not recorded" column in place of "Your Coverage":

```
No Mietkaution policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized coverage comparison.

Reference benchmarks (§551 BGB / Verbraucherzentrale):
```

Then show the benchmark table with "Not recorded" as the Your Coverage column value for all rows, and the computed §551 BGB values in the Benchmark column.

### 3.2 Mandatory Regresspflicht Warning

**ALWAYS emit this warning, regardless of policy status or nettokaltmiete availability:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REGRESSPFLICHT — RIGHT OF RECOURSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPORTANT: Mietkautionsversicherung is not a subsidy.
If your landlord files a claim and the insurer pays, the
insurer has full right of recourse (Regresspflicht) to
recover the full amount from you. This product replaces
upfront cash deposit only — it does not eliminate your
deposit obligation.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Mietkaution policy recorded — cancellation tracking not available."

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
You have {days_until_deadline} days to cancel your Mietkaution policy.
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
for your Mietkaution policy. This window typically lasts
4 weeks from the triggering event (e.g., premium increase,
change in coverage terms).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Mandatory tenancy-end cancellation warning (always emit when existing_policy_found == true):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 TENANCY-END CANCELLATION WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WARNING: Do NOT cancel your Mietkautionsversicherung before
your tenancy ends without your landlord's written release
(Freigabe). Cancelling the policy while the tenancy is active
voids your deposit coverage and may require you to provide
a cash deposit immediately.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Mietkautionsversicherung.

insurance_type: mietkaution
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
nettokaltmiete: {number or null from Phase 0}
landlord_accepted: {Yes/No/Not yet discussed from Phase 0}
budget_range: {selected in Phase 0}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.



## Phase 6: Recommendation

Synthesize findings from Phase 3 (coverage benchmark and Regresspflicht), Phase 4 (cancellation window), and Phase 5 (market context) into 2–3 paragraphs of advisory.

**Landlord acceptance (from Phase 0 — address first if not yet discussed):**

If `landlord_accepted == "No"`: "Important: Not all landlords accept Mietkautionsversicherung as a substitute for a cash deposit. Your landlord has declined. A Mietkautionsversicherung is not usable in your current tenancy unless the landlord agrees — discuss with your landlord before purchasing."

If `landlord_accepted == "Not yet discussed"`: "Key prerequisite: Discuss with your landlord before purchasing a Mietkautionsversicherung. Many landlords prefer traditional cash deposits. Only purchase this product once the landlord has agreed in writing to accept a guarantee certificate (Bürgschaftsurkunde) in lieu of cash."

**Regresspflicht (always include in recommendation):**

"Reminder: Mietkautionsversicherung replaces the upfront cash deposit — it does not eliminate your deposit obligation. If the landlord makes a claim and the insurer pays, the insurer will recover the full amount from you via Regresspflicht. This product provides cash-flow benefit at move-in, not a subsidy."

**Coverage gaps (from Phase 3):**

If guarantee amount is FAIL: "Your guaranteed deposit (EUR {coverage_amount}) is below the §551 BGB maximum of EUR {recommended_deposit}. Verify whether your landlord requires the full 3× Nettokaltmiete or accepts a lower amount."

If premium rate > 5% (WARN): "Your current premium rate ({premium_rate_pct}%) is above the typical market range of 3–5%. Consider shopping for a lower-rate provider at next renewal."

**Cancellation window (from Phase 4):**

If within 30 days: "Your cancellation window is open. Only cancel if your tenancy is ending and you have your landlord's written deposit release (Freigabe)."

If Sonderkündigungsrecht is open: "You have an extraordinary cancellation right — use it only if your tenancy has ended and landlord has issued written Freigabe."

**Always include concrete next steps:**
1. If landlord has not yet accepted: "Discuss Mietbürgschaft acceptance with your landlord first — purchasing without agreement is pointless."
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
If `${CLAUDE_SKILL_DIR}/references/germany/mietkaution.md` cannot be read, proceed with Phase 3 benchmark table omitted and note: "Reference doc not available — benchmark comparison skipped. Re-run `/finyx:insurance mietkaution` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance mietkaution` to retry.
Coverage benchmark comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Computed Benchmark (§551 BGB)

Unlike other sub-skills that read fixed benchmark thresholds from reference docs, Mietkaution uses a COMPUTED benchmark: `recommended_deposit = nettokaltmiete * 3`. This is derived from the user's Phase 0 input and the §551 BGB statutory cap. The 3× multiplier is not hardcoded — it is read from the reference doc's Coverage Benchmarks section at runtime and applied to the user-provided nettokaltmiete.

## Regresspflicht as Mandatory Warning

Regresspflicht (the insurer's right to recover from the tenant after paying the landlord) is the most commonly misunderstood aspect of Mietkautionsversicherung. Users frequently mistake it for a subsidy. The Regresspflicht warning MUST appear in two locations:
1. Phase 3.2 — immediately after the benchmark comparison (always, regardless of policy status)
2. Phase 6 — in the recommendation section (always, as a reminder)

This dual placement is intentional due to the severity of the misconception risk.

## Cancellation-Before-Tenancy-End Risk

Cancelling a Mietkautionsversicherung while the tenancy is still active voids the deposit coverage. The landlord may immediately demand a cash deposit to replace the cancelled guarantee. This risk warrants the mandatory tenancy-end cancellation warning in Phase 4 (shown whenever an existing policy is found), regardless of whether the cancellation window is active.

## Landlord Prerequisite

Not all landlords accept Mietkautionsversicherung. The product is useless without landlord agreement. Phase 0 collects landlord acceptance status and Phase 6 addresses this as the first decision point if acceptance is missing.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/mietkaution.md` directly in Phase 3 via the Read tool to get benchmark thresholds. This is intentional — benchmarks must be read at runtime, not hardcoded.

</notes>
