# Risikoleben Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver a personalized Risikolebensversicherung (term life insurance) analysis by computing a coverage benchmark from gross income and mortgage balance, comparing the user's existing death benefit against the computed recommendation, emitting health underwriting warnings, tracking policy expiry (not annual renewal), handling mid-term cancellation deadlines, and spawning the research agent for criteria-based market comparison.

CRITICAL: Risikoleben `renewal_date` is the POLICY END DATE (Vertragsende / Ablaufdatum), NOT an annual renewal. Always display as "Policy expires: {date}" — never as "Next renewal".

This command writes NO files. All output is conversational advisory text.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect user context before analysis. Collect all three questions in a single round-trip where possible.

**Question 1 — Primary reason for term life (singleSelect):**
"What is the primary reason you have (or are considering) a term life insurance policy?"
- Mortgage protection
- Family income replacement
- Business partner protection (Geschäftspartnerabsicherung)
- Multiple reasons

**Question 2 — Number of dependents (singleSelect):**
"How many financial dependents rely on your income?"
- No dependents
- 1 dependent
- 2 dependents
- 3+ dependents

**Question 3 — Outstanding mortgage (singleSelect):**
"Do you have an outstanding mortgage that would need to be covered?"
- Yes — have outstanding mortgage
- No mortgage
- Prefer not to share

Store results as `user_preferences` object:
```
user_preferences = {
  primary_reason: [selected],
  dependents_count: [selected],
  has_mortgage: [selected]
}
```

---

## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

**Read `$PROFILE_PATH`** (resolved by the gate check above; the @-include is a project-local fast-path) and extract:
- Type slug: `"risikoleben"` — search `insurance.policies[]` for entries where `type == "risikoleben"`
- If found, extract:
  - `coverage_amount` — Versicherungssumme (death benefit sum) in EUR
  - `coverage_components` — array (e.g., ["Todesfallschutz", "Konstante Versicherungssumme", "Nachversicherungsgarantie"])
  - `start_date` — ISO date (Versicherungsbeginn)
  - `renewal_date` — **POLICY END DATE** (Vertragsende / Ablaufdatum) — NOT annual renewal
  - `kuendigungsfrist_months` — notice period for mid-term cancellation
  - `sonderkundigungsrecht` — boolean
  - `premium_monthly` — monthly premium in EUR
- If no risikoleben policy found: set `existing_policy = null`.

**Read income and mortgage data:**
- `gross_income` = `countries.germany.gross_income` (annual gross income in EUR)
- Try `investor.mortgageBalance`, `investor.outstanding_loan`, `countries.germany.mortgage_balance`, or similar fields — if any is found and non-null, set `mortgage_balance = [value]`; otherwise set `mortgage_balance = null`
- If `gross_income` is null or absent: set `income_known = false`
- If `gross_income` is present: set `income_known = true`

**Tax year staleness check:**
```bash
CURRENT_YEAR=$(date +%Y)
echo "Current year: $CURRENT_YEAR"
```

Read `tax_year` from `${CLAUDE_SKILL_DIR}/references/germany/risikoleben.md` frontmatter. If `CURRENT_YEAR != tax_year`, emit:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reference docs are from tax year {tax_year}. Current year is {CURRENT_YEAR}.
Premium benchmarks and health underwriting norms may have changed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Disclaimer

Emit the main header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► RISIKOLEBENSVERSICHERUNG
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

Term life insurance analysis is based on your recorded coverage_amount and
income/mortgage data from your profile. Benchmark multipliers are from the
Risikoleben reference doc and reflect financial planning guidance, not
statutory requirements.

This tool does not replace a consultation with a licensed Versicherungsberater.

⚠ CRITICAL — HEALTH UNDERWRITING (Gesundheitsprüfung):
Term life insurance requires full health underwriting. If you are considering
switching to a new policy, do NOT cancel your existing policy before the new
policy is APPROVED and ACTIVE. Cancelling first may leave you uninsured if
the new application is declined due to health underwriting — and reinstatement
is not guaranteed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 3: Coverage Benchmark Comparison

Read all benchmark formulas and multipliers from `${CLAUDE_SKILL_DIR}/references/germany/risikoleben.md`. Do NOT hardcode multiplier values — read them from the reference doc Coverage Benchmarks section at runtime.

### 3.1 Benchmark Computation

**Compute the recommended Versicherungssumme from profile data:**

Read multiplier values from the reference doc. The formula structure (from the reference doc) is:

```
From profile:
  gross_income = countries.germany.gross_income
  mortgage_balance = [from investor data, or null]

Benchmark computation (multipliers from reference doc — do NOT hardcode):
  If user has "3+ dependents" (from Phase 0):
    income_multiple = [upper multiplier from reference doc, e.g. 5]
  Else:
    income_multiple = [standard multiplier from reference doc, e.g. 3]

  income_based_sum = gross_income × income_multiple

  If mortgage_balance is known:
    recommended_sum = max(income_based_sum, mortgage_balance)
  Else:
    recommended_sum = income_based_sum

  minimum_sum = gross_income × [minimum multiplier from reference doc]
```

If `income_known == false`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 BENCHMARK: UNKNOWN — INCOME NOT IN PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cannot compute Versicherungssumme benchmark — your gross income is not
recorded in your profile.

Add your income via `/finyx:profile` (Germany → gross income) to enable
the benchmark formula. Showing general guidance from reference doc instead.

General guidance: Versicherungssumme should be at minimum 3× your annual
gross income, and up to 5× if you have multiple dependents or a mortgage.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Skip the comparison table below and show only general guidance from the reference doc.

### 3.2 Coverage Comparison Table

**If `income_known == true` and existing policy found:**

Determine status:
- PASS: `coverage_amount >= recommended_sum`
- MARGINAL: `minimum_sum <= coverage_amount < recommended_sum`
- FAIL: `coverage_amount < minimum_sum`
- UNKNOWN: `coverage_amount` is null (policy recorded but sum not extracted)

Compute: `coverage_gap = recommended_sum - coverage_amount` (if FAIL or MARGINAL)

Determine term type from `coverage_components`:
- "Konstante Versicherungssumme" or similar → Level term
- "Fallende Versicherungssumme" or "Annuität" → Declining term
- Not found → Unknown

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 YOUR RISIKOLEBEN COVERAGE vs BENCHMARKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Benchmark basis:
  Annual gross income:  €{gross_income}
  Mortgage balance:     €{mortgage_balance or "not in profile"}
  Dependents:           {dependents_count from Phase 0}
  Recommended sum:      €{recommended_sum}

| Criterion             | Your Coverage                        | Recommended             | Status   |
|-----------------------|--------------------------------------|-------------------------|----------|
| Versicherungssumme    | €{coverage_amount}                   | ≥€{recommended_sum}     | PASS/MARGINAL/FAIL |
| Coverage gap          | —                                    | €{coverage_gap or "—"}  | INFO     |
| Term type             | {level/declining from components}    | Level (income replace.) | INFO     |
| Policy expires        | {renewal_date} (Vertragsende)        | Until youngest age 25   | INFO     |
| Gross income basis    | —                                    | €{gross_income}/year    | REF      |
| Mortgage balance      | —                                    | €{mortgage_balance or "not in profile"} | REF |
```

Note on "Policy expires": This is the Vertragsende (fixed-term end date) — NOT an annual renewal. Risikoleben does not auto-renew; it expires at this date. A new policy will require new health underwriting at your then-current age.

**If `income_known == true` and no existing policy:**
Show benchmark table without "Your Coverage" column. Recommended sum: €{recommended_sum}.

---

## Phase 4: Cancellation Deadline Check

**CRITICAL SEMANTICS — Risikoleben `renewal_date` is the POLICY END DATE:**

Risikoleben is a FIXED-TERM contract. `renewal_date` = Vertragsende (Ablaufdatum). The policy does not auto-renew — it expires on this date. Display as "Policy expires: {renewal_date}" everywhere. NEVER display as "Next renewal".

**Policy expiry check:**
```
days_until_expiry = renewal_date minus today
```

If `days_until_expiry <= 180` (6 months):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ⚠ POLICY EXPIRING SOON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your term life policy expires on {renewal_date} ({days_until_expiry} days).

ACTION REQUIRED: Start the application process for a replacement policy NOW.
Health underwriting at a new insurer takes 4–8 weeks. Apply while your current
policy is still active — do NOT wait until expiry.

At expiry, coverage ceases permanently. A new policy requires new health
underwriting at your current age — premiums will be higher than your
current rate.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Mid-term cancellation deadline (if user is considering switching):**

Read `kuendigungsfrist_months` and `start_date` from profile.

```
mid_term_cancellation_deadline = [next anniversary of start_date] minus kuendigungsfrist_months
```

Cancellation display logic:

If `sonderkundigungsrecht == true`:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ⚠ SONDERKÜNDIGUNGSRECHT OPEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your policy has an open special cancellation right. You may cancel within
4 weeks of the trigger event (premium increase or coverage change).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Otherwise, show mid-term cancellation window status (open within 30 days or standard timeline display).

If cancellation fields are absent from profile:
```
Mid-term cancellation deadline: Unknown — add policy details via /finyx:insurance portfolio
```

**⚠ No cash value (Kein Rückkaufswert):**
```
Note: Risikoleben has NO Rückkaufswert (no cash surrender value). If you cancel
mid-term, all premiums paid are forfeited with no refund. This is standard for
pure term life — premiums are fully consumed by the risk premium.

Early cancellation may be appropriate only if your insured risk (mortgage paid
off, dependents financially independent) has materially changed.
```

---

## Phase 5: Research Agent

Spawn the research agent via the Task tool:

```
You are the finyx-insurance-research-agent. Research current market conditions
for Risikolebensversicherung (term life insurance).

insurance_type: risikoleben

User context:
primary_reason: {user_preferences.primary_reason}
dependents_count: {user_preferences.dependents_count}
has_mortgage: {user_preferences.has_mortgage}
existing_policy: {existing_policy != null ? "yes" : "no"}
gross_income_bracket: {derive from gross_income — e.g., "70,000–80,000 EUR/year" or "unknown"}

Focus your research on:
1. Coverage criteria checklist for Risikoleben (what to demand from any policy)
2. Level vs declining term — when each structure is appropriate
3. Nachversicherungsgarantie — importance and typical trigger events
4. Beitragsbefreiung bei BU — whether this add-on is worth the premium
5. Red flags to watch for in term life policies
6. Health underwriting expectations — what conditions trigger surcharges vs exclusions

Load ${CLAUDE_SKILL_DIR}/references/germany/risikoleben.md for benchmarks.
Return your output wrapped in <insurance_research_result> tags.
```

Collect `<insurance_research_result>` from the agent output.

---

## Phase 6: Recommendation

Synthesize findings from Phases 3–5 into a clear recommendation.

**Reasoning framework:**

1. **If status is FAIL on Versicherungssumme:**
   Recommend increasing coverage by the specific gap amount (€{coverage_gap}). Explain the income/mortgage basis for the recommendation. Note that a new application requires new health underwriting.

2. **If status is MARGINAL on Versicherungssumme:**
   Flag that coverage meets the minimum but falls short of the recommended sum. Suggest reviewing whether the gap is acceptable given current financial obligations.

3. **If declining term AND user_preferences.primary_reason is "Family income replacement":**
   Flag potential mismatch — declining term reduces the benefit each year, which may leave income-replacement shortfall in later years. Level term is more appropriate for income protection.

4. **If level term AND user_preferences.has_mortgage is "Yes — have outstanding mortgage":**
   Note that level term is over-insurance for mortgage protection (the outstanding balance decreases over time while the death benefit stays constant). Declining term (Annuität) is more cost-efficient for pure mortgage coverage — though level term provides additional family income protection.

5. **If policy expiry is within 3 years:**
   Urge action to evaluate a replacement policy now while health underwriting is likely still favorable. Waiting until near-expiry and applying at an older age will result in higher premiums.

6. **If user has no dependents and no mortgage:**
   Gently question the rationale for coverage. Term life provides no benefit without financial dependents or co-obligors. If covering a partner, ensure they are named as beneficiary.

**Always include the health underwriting repeat warning in every recommendation:**
```
⚠ HEALTH UNDERWRITING REMINDER (Gesundheitsprüfung):
If you are considering switching or adding a new policy, arrange the new
coverage FIRST. Do NOT cancel your existing policy until the new policy is
APPROVED and ACTIVE. A declined application leaves a gap in coverage that
may be permanent if your health has changed.
```

Present a concrete next step:
- If increasing coverage: "Request a new policy quote, complete health underwriting, receive approval, THEN consider modifying or cancelling the existing policy."
- If switching: "Request comparison criteria from the research report above, apply for the new policy, receive approval, THEN cancel the old policy."
- If no policy: "Determine your required Versicherungssumme using the benchmark above (€{recommended_sum}), then apply — health underwriting is required."

Frame all recommendation language as "based on this analysis" — not as definitive advice.

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No Risikoleben policy in profile:**
No error — proceed with benchmark computation using income/mortgage data from profile.
Notify user: "No Risikoleben policy found in your profile. Showing benchmark guidance."

**No gross income in profile:**
Show UNKNOWN banner (see Phase 3.1) and provide general guidance from reference doc instead
of computed recommendation. Do not error — degrade gracefully.

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the
expected <insurance_research_result> block. Re-run /finyx:insurance risikoleben to retry.
Benchmark comparison above is based on reference doc data and profile income data only.
```

**Missing cancellation fields:**
Show "Unknown" gracefully — do not error. Prompt user to add details via portfolio sub-skill.

</error_handling>

<notes>

## Write Targets

This command writes NO files. All output is conversational advisory text.

## renewal_date Semantics (Critical)

Risikoleben `renewal_date` in the profile is the Vertragsende (Ablaufdatum) — the FIXED END DATE of the policy, not an annual renewal date. This is explicitly documented in the reference doc field extraction schema:

> "renewal_date for Risikoleben: Record as the policy end date (Vertragsende / Ablauf), not an annual renewal. Risikoleben is a fixed-term contract; it does not auto-renew — it expires."

ALWAYS display as "Policy expires: {date}" — NEVER as "Next renewal: {date}".

The Kündigungsfrist applies only to MID-TERM cancellation (the user choosing to exit the policy before Vertragsende), not to the natural policy expiry.

## Health Underwriting Warning

The Gesundheitsprüfung warning appears in THREE places:
1. Phase 2 Disclaimer (insurance-specific addendum)
2. Phase 4 mid-term cancellation section (contextually, if switching is relevant)
3. Phase 6 Recommendation (ALWAYS — even if no switching is recommended)

This triple placement is intentional: the health underwriting trap (cancel old policy → get rejected by new insurer → no coverage) is the most common and consequential mistake in Risikoleben management.

## No Rückkaufswert

Unlike Kapitallebensversicherung (savings life insurance), Risikoleben has NO cash surrender value. Mid-term cancellation forfeits all paid premiums. This must be stated clearly when discussing cancellation.

## Benchmark Multipliers

Read multipliers (3× minimum, 5× for 3+ dependents, max with mortgage) from the reference doc Coverage Benchmarks table — do NOT hardcode. The reference doc formula is the source of truth. If the doc's benchmark formula changes in future tax year updates, this sub-skill inherits the update automatically.

## start_date Usage

`start_date` is used to compute mid-term cancellation deadlines (next anniversary minus kuendigungsfrist_months). It is NOT used to derive policy expiry — that comes from `renewal_date` (= Vertragsende).

## Agent Scope

The research agent (`finyx-insurance-research-agent`) is parameterized by `insurance_type: risikoleben`. Per §34d GewO compliance, it returns criteria and benchmarks only — no specific provider names or tariff rankings.

</notes>
