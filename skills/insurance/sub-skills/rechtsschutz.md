# Rechtsschutz Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Rechtsschutzversicherung (legal expenses insurance) analysis: module-based coverage comparison (Berufs-, Verkehrs-, Miet-, Privatrechtsschutz), Wartezeit status check, cancellation deadline tracking with note on ongoing covered disputes, and criteria-based market research. Rechtsschutz is service-based — coverage_amount is null and no monetary sum benchmark is used. Read-only advisory — writes NO files.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect life-situation data that determines which Rechtsschutz modules are relevant for this user.

**Question 1 — Employment status (singleSelect):**
"What is your current employment status?"
- Employee (Arbeitnehmer)
- Self-employed (Selbstständig)
- Civil servant (Beamter)
- Retired (Rentner)
- Student

**Question 2 — Do you rent your home? (singleSelect):**
"Do you currently rent your home?"
- Yes — renting
- No — homeowner

**Question 3 — Do you drive a car? (singleSelect):**
"Do you regularly drive a car?"
- Yes — regular driver
- No

Store results as `user_preferences`:
```
user_preferences = {
  employment_status: [selected],
  renting: [yes/no],
  driving: [yes/no]
}
```

Derive module relevance:
- `Berufsrechtsschutz` relevant if: employee, self-employed, civil servant
- `Mietrechtsschutz` relevant if: renting
- `Verkehrsrechtsschutz` relevant if: driving
- `Privatrechtsschutz` always relevant

Pass `user_preferences` to the research agent in Phase 5.

## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

Read `$PROFILE_PATH` (resolved by the gate check above; the @-include is a project-local fast-path). Find the entry in `insurance.policies[]` where `type == "rechtsschutz"`.

Extract:
- `coverage_components` — array of active modules (e.g., ["Berufsrechtsschutz", "Verkehrsrechtsschutz", "Mietrechtsschutz", "Privatrechtsschutz"])
- `coverage_amount` — IMPORTANT: this field is null for Rechtsschutz (service-based). Do NOT use it as a monetary benchmark. Confirm it is null; if a value is recorded, note it is non-standard.
- `premium_monthly` — monthly premium in EUR
- `start_date` — ISO date (YYYY-MM-DD)
- `renewal_date` — ISO date of next Hauptfalligkeit
- `kuendigungsfrist_months` — cancellation notice period in months
- `sonderkundigungsrecht` — boolean (true if extraordinary cancellation right is open)
- `provider` — insurer name
- `notes` — free-text notes (may include Selbstbeteiligung or case information)

Set `existing_policy_found = true` if a matching entry is found, `false` otherwise.

**If profile is missing:** emit error (see error_handling) and stop.

## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► RECHTSSCHUTZ
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

This analysis evaluates module coverage based on your life situation.
Rechtsschutzversicherung is service-based — there is no single monetary
sum to compare. Coverage is assessed by active modules vs recommended
modules for your employment, housing, and driving situation.

Verify all coverage details with your insurer. This tool does not replace
advice from a licensed Versicherungsberater (§34d GewO).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 3: Coverage Benchmark Comparison

Read `${CLAUDE_SKILL_DIR}/references/germany/rechtsschutz.md` — specifically the "Coverage Benchmarks" section and the module descriptions — to obtain the recommended modules and Wartezeit standard. Do NOT hardcode values; read them from the reference doc at runtime.

CRITICAL: This is a module-based comparison, NOT a monetary sum comparison. Do not use `coverage_amount` for any benchmark — it is null for Rechtsschutz.

**Wartezeit computation:**
- If `existing_policy_found == true` and `start_date` is present:
  - Compute `days_since_start = today - start_date`
  - If `days_since_start < 90` (3 months): Wartezeit is still active. Flag: "Wartezeit active — coverage for legal disputes initiated within the first 3 months of the policy may be limited."
  - If `days_since_start >= 90`: Wartezeit has passed.
  - If `start_date` is absent: mark Wartezeit status as UNKNOWN.

**Module relevance mapping (from Phase 0):**
```
Privatrechtsschutz → always "Recommended" (regardless of life situation)
Berufsrechtsschutz → "Recommended" if employment_status is employee/self-employed/civil servant; "N/A" if retired/student
Mietrechtsschutz   → "Recommended" if renting == yes; "N/A" if homeowner
Verkehrsrechtsschutz → "Recommended" if driving == yes; "N/A" if not driving
```

**Module presence check:** For each module, check whether it appears in `coverage_components[]`. Case-insensitive substring match is acceptable (e.g., "Berufsrechtsschutz" in ["Berufsrechtsschutz", "Privatrechtsschutz"]).

**If `existing_policy_found == true`:**

Build the module comparison table:

```
## Your Module Coverage vs Recommended

| Module                  | Your Coverage         | Recommended for You              | Status         |
|-------------------------|-----------------------|----------------------------------|----------------|
| Privatrechtsschutz      | {ACTIVE/NOT ACTIVE}   | Always recommended               | PASS/MISSING   |
| Berufsrechtsschutz      | {ACTIVE/NOT ACTIVE}   | {Recommended/N/A}                | PASS/MISSING/N/A |
| Verkehrsrechtsschutz    | {ACTIVE/NOT ACTIVE}   | {Recommended/N/A}                | PASS/MISSING/N/A |
| Mietrechtsschutz        | {ACTIVE/NOT ACTIVE}   | {Recommended/N/A}                | PASS/MISSING/N/A |
| Wartezeit status        | {Active/Passed/UNKNOWN} | 3 months (standard)            | INFO           |
| Selbstbeteiligung       | {from notes/components, or Unknown} | €150–300 typical | INFO           |
```

Status values:
- PASS: module present in coverage_components AND recommended for user
- MISSING: module NOT present in coverage_components AND recommended for user
- N/A: module not relevant for this user's life situation (per Phase 0 preferences)
- INFO: informational only, no PASS/FAIL

**If `existing_policy_found == false`:**

```
No Rechtsschutz policy found in your profile.
Add your policy via `/finyx:insurance portfolio` to see a personalized module comparison.

Recommended modules for your situation:
```

Show the recommended modules based on Phase 0 preferences (which modules are relevant vs N/A for this user). Do not show coverage_amount or any monetary benchmark.

## Phase 4: Cancellation Deadline Check

**If `existing_policy_found == false`:** skip with brief note: "No Rechtsschutz policy recorded — cancellation tracking not available."

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
You have {days_until_deadline} days to cancel your Rechtsschutz policy.
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
for your Rechtsschutz policy. This window typically lasts 4 weeks
from the triggering event (e.g., premium increase, resolved covered case).

Review your last insurer correspondence to confirm the trigger
date and act before the window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Ongoing covered disputes note (always include when policy is found):**
"Important: If you have ongoing legal disputes currently covered by this policy, cancellation does NOT void coverage for those active cases — the insurer must continue covering cases for which a Deckungszusage was already granted. New disputes after the cancellation date are not covered."

## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions for Rechtsschutzversicherung.

insurance_type: rechtsschutz
current_year: {current year}
current_premium_monthly: {premium_monthly from profile if known, else omit}

<user_preferences>
employment_status: {selected in Phase 0}
renting: {yes/no from Phase 0}
driving: {yes/no from Phase 0}
relevant_modules: {comma-separated list of relevant modules for this user}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Render the full `<insurance_research_result>` output to the user.

**If the agent fails to return `<insurance_research_result>`:** emit the error from error_handling and continue to Phase 6 with market context unavailable.

## Phase 6: Recommendation

Synthesize findings from Phase 3 (module gaps), Phase 4 (cancellation window), and Phase 5 (market context) into 2–3 paragraphs of advisory.

Reasoning framework:

**Missing modules (from Phase 3):**
- If Berufsrechtsschutz is MISSING and user is employed: "You are employed but Berufsrechtsschutz is not included in your policy. Labor court disputes (unfair dismissal, overtime, workplace accidents) would not be covered. This is a high-priority gap for employees."
- If Mietrechtsschutz is MISSING and user is renting: "You are renting but Mietrechtsschutz is not included. Rental disputes — including utility cost disputes, lease terminations, and maintenance conflicts — would not be covered. This is a high-priority gap for tenants."
- If Verkehrsrechtsschutz is MISSING and user drives: "You drive but Verkehrsrechtsschutz is not included. Traffic disputes after accidents, license suspension proceedings, or enforcement challenges would not be covered."
- If Privatrechtsschutz is MISSING: "Privatrechtsschutz (general civil disputes) is the core module and should be included in any Rechtsschutz policy."

**Wartezeit (from Phase 3):**
- If still active: "Your policy is less than 3 months old. The standard Wartezeit means coverage for disputes initiated in this period may be limited. Pre-existing legal matters known before policy inception are never covered."

**Cancellation window:**
- If within 30 days: "Your cancellation window is open. If the market research identifies better module coverage, act before {deadline_date}."
- If Sonderkündigungsrecht is open: "Use the open extraordinary cancellation right to switch if a better policy is found."

**Always include concrete next steps:**
1. For each missing relevant module: "Contact your insurer to add {module} at renewal, or switch to a policy that includes it."
2. "Run `/finyx:insurance portfolio` to update your policy details for more accurate module tracking."
3. Market alternatives: reference the research agent output for criteria-based options.
4. "Frame all decisions as advisory — consult a licensed Versicherungsberater for binding recommendations."

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**Reference doc read error:**
If `${CLAUDE_SKILL_DIR}/references/germany/rechtsschutz.md` cannot be read, proceed with Phase 3 module table showing module relevance from Phase 0 preferences only (no benchmark context from reference doc), and note: "Reference doc not available — module benchmark context skipped. Re-run `/finyx:insurance rechtsschutz` to retry."

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run `/finyx:insurance rechtsschutz` to retry.
Module comparison and cancellation tracking above are based on your profile data only.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. Profile updates are directed to `/finyx:insurance portfolio`.

## Coverage Amount is Always Null

Rechtsschutz is service-based (`coverage_type: service_based` per the reference doc). The `coverage_amount` field is null — the policy pays legal costs per case up to policy limits (typically €300,000–unlimited per case) rather than a single insured sum. NEVER display a monetary sum benchmark for Rechtsschutz. Phase 3 uses module-based PASS/MISSING/N/A logic only.

## Wartezeit (Waiting Period)

Standard Wartezeit is 3 months from `start_date`. Legal disputes initiated within this period are not covered. Pre-existing disputes (known before the policy start date) are never covered, regardless of Wartezeit. This is a commonly misunderstood aspect — always clarify it when Wartezeit is still active.

## Ongoing Disputes Not Voided by Cancellation

This is a key Rechtsschutz-specific rule: cancelling the policy does not invalidate coverage for ongoing cases where the insurer already issued a Deckungszusage (coverage confirmation). The insurer must continue covering those active disputes. This is different from all other insurance types where cancellation is clean.

## Module N/A vs MISSING

The distinction is important for the user experience:
- N/A: module is not relevant for this user's life situation (e.g., Verkehrsrechtsschutz for a non-driver). Do not present this as a gap.
- MISSING: module IS relevant for this user but absent from their policy. Present as a gap with priority.

Always derive relevance from Phase 0 preferences, not from assumptions about what the "typical" user needs.

## Reference Doc Loading

The router loads `disclaimer.md` and `profile.json` at startup. This sub-skill reads `${CLAUDE_SKILL_DIR}/references/germany/rechtsschutz.md` in Phase 3 via the Read tool to get module descriptions and Wartezeit standard. Benchmark reading is module-qualitative (not sum-based) — read the "Coverage Benchmarks" table for priority ratings per module.

</notes>
