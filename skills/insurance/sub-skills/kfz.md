# Kfz Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver personalized Kfz insurance analysis covering all 3 coverage tiers (Haftpflicht, Teilkasko, Vollkasko), SF-Klasse no-claims bonus impact, vehicle-specific tier recommendations, cancellation deadline tracking, and criteria-based market research via research agent. The sub-skill:

1. Collects 6 vehicle-specific data points (coverage tier, SF-Klasse, vehicle age, annual km, garage status, financed status) via AskUserQuestion
2. Reads the user's Kfz policy from profile (if present) for coverage comparison
3. Emits legal disclaimer before advisory content
4. Presents a 3-column tier comparison table (Haftpflicht / Teilkasko / Vollkasko) with when-to-upgrade guidance
5. Shows SF-Klasse impact on premium
6. Checks cancellation deadline using the special Kfz 30.11 rule
7. Spawns `finyx-insurance-research-agent` with vehicle-specific context
8. Synthesizes a recommendation addressing tier adequacy, coverage gaps, and concrete next steps

This sub-skill writes NO files. All output is conversational advisory text.

</objective>

<process>

## Phase 0: Preferences (Extended — Kfz Vehicle Data Collection)

Use AskUserQuestion to collect 6 vehicle-specific data points before running any analysis. Collect in 2-3 logical groupings to minimize round-trips.

**Round 1 — Current coverage and SF-Klasse:**

**Question 1 — Current coverage tier (singleSelect):**
"What is your current Kfz insurance coverage level?"
- Haftpflicht only (third-party liability — legally mandatory minimum)
- Haftpflicht + Teilkasko (partial comprehensive — covers theft, weather, wildlife)
- Vollkasko (full comprehensive — includes own-fault accidents and vandalism)
- Not currently insured / new vehicle
- Not sure

**Question 2 — SF-Klasse (text input with explanation):**
"What is your SF-Klasse (Schadenfreiheitsklasse)?
This is your no-claims bonus class — it directly affects your premium.
0 = new driver / no claims history, 35 = 35+ claim-free years.
A single at-fault accident typically drops you 4-6 classes.
Find it on your current policy document (Versicherungsschein)."

Accept numeric input 0–35. If the user doesn't know or can't find it: use "unknown" and note in Phase 3 that premium estimates will not be personalized.

**Round 2 — Vehicle characteristics:**

**Question 3 — Vehicle age (singleSelect):**
"How old is your vehicle?"
- 0–3 years (new or nearly new)
- 3–7 years
- 7–12 years
- 12+ years

**Question 4 — Annual km driven (singleSelect):**
"How many kilometers do you drive per year?"
- Under 10,000 km
- 10,000–20,000 km
- 20,000–30,000 km
- Over 30,000 km

**Round 3 — Storage and financing:**

**Question 5 — Garage (singleSelect):**
"Is your vehicle parked in a garage overnight?"
- Yes — private garage or enclosed parking
- No — street parking or open area

**Question 6 — Financed or leased (singleSelect):**
"Is your vehicle financed or leased?"
- Yes — financed or leased
- No — fully owned

Store all responses as a `vehicle_data` object:
```
vehicle_data = {
  current_tier: [selected from Q1],
  sf_klasse: [number 0-35 or "unknown"],
  vehicle_age: [selected bracket from Q3],
  annual_km: [selected bracket from Q4],
  garage: ["yes" or "no"],
  financed: ["yes" or "no"]
}
```

---

## Phase 1: Validation and Profile Read

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

**Read `$PROFILE_PATH`** (resolved by the gate check above; the @-include is a project-local fast-path) and extract:
- `insurance.policies[]` — search for the entry where `type == "kfz"`
- From the matching entry (if found):
  - `coverage_components` — string array of active tiers (e.g., `["Haftpflicht", "Teilkasko"]`)
  - `premium_monthly` — current monthly premium in EUR
  - `coverage_amount` — Deckungssumme for Haftpflicht tier (EUR); null for Teilkasko/Vollkasko
  - `start_date` — ISO date (used for cancellation deadline computation)
  - `renewal_date` — ISO date if explicitly set (use directly if present)
  - `kuendigungsfrist_months` — number (standard for Kfz: 1)
  - `sonderkundigungsrecht` — boolean
  - `provider` — insurer name
- `identity.city` or `identity.residence_city` — for Regionalklasse context; set to null if absent

Set `existing_policy_found = true` if a matching Kfz policy entry was found, `false` otherwise.

---

## Phase 2: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► KFZ-VERSICHERUNG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Emit the full legal disclaimer from the loaded `disclaimer.md` (loaded by router's execution_context):

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

Kfz premium estimates are illustrative ranges based on published
benchmarks — your actual premium depends on Typklasse, Regionalklasse,
SF-Klasse, and individual insurer underwriting. This tool does not
replace a licensed Versicherungsberater or Versicherungsmakler.

Kfz-Haftpflicht is mandatory in Germany (§1 PflVG). Driving an
uninsured vehicle on public roads is a criminal offense (§6 PflVG).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 3: Coverage Benchmark Comparison

Read `${CLAUDE_SKILL_DIR}/references/germany/kfz.md` for all benchmark data used in this phase. Do NOT hardcode premium ranges, SF-Klasse discount percentages, or coverage rules — read them from the reference doc at runtime.

### 3a: 3-Tier Coverage Comparison Table

ALWAYS show this table — it is the core output of the Kfz sub-skill, regardless of whether a policy was found. Read coverage details from the reference doc's Coverage Tiers section.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 KFZ COVERAGE TIER COMPARISON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Criterion | Haftpflicht | Teilkasko | Vollkasko |
|-----------|-------------|-----------|-----------|
| Third-party damage (Personen-/Sachschäden) | MANDATORY (§1 PflVG) | Included | Included |
| Theft (Diebstahl) | Not covered | COVERED | COVERED |
| Weather / natural events (Elementarschäden) | Not covered | COVERED | COVERED |
| Glass breakage (Glasbruch) | Not covered | COVERED | COVERED |
| Wildlife collision / marten bite (Wildunfall / Marderbiss) | Not covered | COVERED | COVERED |
| Own-fault accident damage (Selbstverschuldete Unfälle) | Not covered | Not covered | COVERED |
| Vandalism (Vandalismus) | Not covered | Not covered | COVERED |
| Typical monthly premium range | [from kfz.md reference doc] | [from kfz.md reference doc] | [from kfz.md reference doc] |

> Note: Typical premium ranges depend on SF-Klasse, Typklasse, and Regionalklasse — the ranges above are illustrative market benchmarks from the reference doc, not quotes.

If `existing_policy_found == true`, show current tier from `coverage_components`:

```
Your current coverage: {coverage_components joined as " + "}
```

### 3b: When-to-Upgrade Guidance

Based on `vehicle_data.vehicle_age` collected in Phase 0, show the recommendation from kfz.md Coverage Benchmarks:

- **0–3 years:** "Vollkasko strongly recommended — vehicle value is high and repair costs are expensive. Most financing contracts also require it."
- **3–7 years:** "Vollkasko or Teilkasko — weigh the vehicle's current market value against the premium difference. If the vehicle's replacement cost is still significant, Vollkasko remains worthwhile."
- **7–12 years:** "Teilkasko is usually sufficient — Vollkasko premiums may exceed the potential payout for vehicles in this age range. Evaluate based on actual market value."
- **12+ years:** "Haftpflicht or Teilkasko — Vollkasko is rarely cost-effective for older vehicles. Haftpflicht is the mandatory legal minimum; Teilkasko provides meaningful additional protection (theft, weather) at reasonable cost."

**Financing flag (if `vehicle_data.financed == "yes"`):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WARNING: Financed / Leased Vehicle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Financed and leased vehicles typically REQUIRE Vollkasko coverage
as a condition of the financing or leasing agreement. Check your
Kfz-Kredit or Leasingvertrag to confirm the required coverage tier.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3c: SF-Klasse Impact

**If `vehicle_data.sf_klasse` is a number (not "unknown"):**

Show the impact explanation. Read SF-Klasse discount data from kfz.md Rating Factors section:

"Your SF-Klasse {sf_klasse} reflects {sf_klasse} claim-free year(s). SF-Klasse is a major premium driver:
- SF 35 (35+ claim-free years) can reduce Haftpflicht premiums by 70–80% vs. SF 0 (new driver rate)
- One at-fault accident typically triggers a regression of 4–6 classes
- The SF-Klasse impact varies by insurer and vehicle segment — request personalized quotes when comparing"

[If the reference doc contains an SF-Klasse discount table: read and present the relevant row for the user's class]

**If `vehicle_data.sf_klasse == "unknown":**

"SF-Klasse not provided — premium estimates in the market research below will be general (not personalized to your no-claims class). Find your SF-Klasse on your current Versicherungsschein and re-run for a personalized estimate."

### 3d: Current Coverage Assessment

**Only show this section if `existing_policy_found == true`:**

Compare the current tier from `coverage_components` against the recommendation from Phase 3b.

- If `coverage_components` contains only "Haftpflicht" and vehicle age is 0–3 years:
  "Your vehicle age bracket (0–3 years) suggests Vollkasko — you currently have Haftpflicht only. This is a significant coverage gap for a newer vehicle."

- If `coverage_components` contains only "Haftpflicht" and `vehicle_data.financed == "yes"`:
  "Your vehicle is financed but you have only Haftpflicht. This likely violates your financing contract conditions — upgrade to Vollkasko as a priority."

- If `coverage_components` contains "Vollkasko" and vehicle age is 12+ years and `vehicle_data.financed == "no"`:
  "Your vehicle age bracket (12+ years) suggests Teilkasko or Haftpflicht may be more cost-effective. Downgrading Vollkasko could reduce premiums — weigh the saved premium against your vehicle's current market value."

- If coverage aligns with the recommendation: "Your current coverage level ({coverage_components}) aligns with the recommendation for your vehicle age bracket."

If `existing_policy_found == false`:
"No Kfz policy found in your profile. If you have a policy, add it via `/finyx:insurance portfolio` to enable coverage comparison."

---

## Phase 4: Cancellation Deadline Check

**Special Kfz rule:** Most Kfz policies in Germany renew on 01.01 (Kalenderjahr = Versicherungsjahr). The standard Kündigungsfrist is 1 month, meaning the cancellation deadline is **30.11 (November 30)**. This is the most important cancellation deadline in German insurance.

Read cancellation rules from `${CLAUDE_SKILL_DIR}/references/germany/kfz.md` Cancellation Rules section.

**If `existing_policy_found == true` and `start_date` and `kuendigungsfrist_months` are present:**

Compute the deadline:
1. Determine `renewal_date`:
   - If `renewal_date` is explicitly set in the policy entry: use it directly
   - If not set: compute the next 01.01 occurrence (most Kfz policies renew on 01.01 regardless of start date)
2. Compute `deadline = renewal_date - kuendigungsfrist_months months`
3. Compute `days_until_deadline = deadline - today`

Display based on proximity:

- **`days_until_deadline < 0` (deadline passed):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CANCELLATION WINDOW: CLOSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The standard cancellation deadline (30.11) has passed.
Next opportunity: 30.11.{next_year} for 01.01.{next_year+1} renewal.
Check for Sonderkündigungsrecht triggers below.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- **`0 <= days_until_deadline <= 30` (urgent — deadline approaching):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CANCELLATION DEADLINE ALERT — {X} DAYS REMAINING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You have {X} days to cancel your Kfz policy with {provider}.
Deadline: {deadline_date} (30.11 for 01.01 renewal)
Send cancellation in writing (Einschreiben recommended) to {provider}
before this date.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- **`days_until_deadline > 30` (informational):**
```
Cancellation deadline: {deadline_date} ({kuendigungsfrist_months} month notice before renewal on {renewal_date})
Most Kfz policies follow the 30.11 deadline for 01.01 renewal.
```

**Sonderkündigungsrecht check:**

If `sonderkundigungsrecht == true`:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SONDERKÜNDIGUNGSRECHT OPEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You have an extraordinary cancellation right currently open
for your Kfz policy. This window is typically 4 weeks from
the triggering event.

Review your last insurer correspondence to confirm the trigger
date. Act before the 4-week window closes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Sonderkündigungsrecht triggers for Kfz (from reference doc):**
- Premium increase without coverage change — cancel within 4 weeks of notification
- After an insured claim is paid — insurer or insured may cancel within 4 weeks
- After an uninsured claim (insurer declines) — insured may cancel within 4 weeks
- After SF-Klasse reclassification (regression after a claim) — insured has Sonderkündigungsrecht within 4 weeks of notification
- Vehicle sale or deregistration — policy terminates automatically

**If `existing_policy_found == false` or cancellation fields are missing:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CANCELLATION DEADLINE: UNKNOWN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Policy details not found or incomplete. Add your Kfz policy
start date and provider via `/finyx:insurance portfolio`.

Standard Kfz rule: most policies renew 01.01 — cancellation
deadline is 30.11 (1 month notice period required).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 5: Research Agent Spawn

Spawn `finyx-insurance-research-agent` via Task tool. Pass all collected vehicle data — this is critical for Kfz Regionalklasse personalization and SF-Klasse-aware market context.

```
You are the finyx-insurance-research-agent. Research current market conditions for Kfz-Versicherung.

insurance_type: kfz
current_year: {CURRENT_YEAR}
current_premium_monthly: {from existing policy premium_monthly if found, else omit}
sf_klasse: {vehicle_data.sf_klasse}
vehicle_age_years: {midpoint of vehicle_data.vehicle_age bracket — e.g., "0–3 years" → 2, "3–7 years" → 5, "7–12 years" → 9, "12+ years" → 15}
annual_km: {vehicle_data.annual_km bracket}
{If identity.city or identity.residence_city is present:}
user_city: {city value}

<user_preferences>
current_tier: {vehicle_data.current_tier}
garage: {vehicle_data.garage}
financed: {vehicle_data.financed}
</user_preferences>

Return your output wrapped in <insurance_research_result> tags.
```

Wait for the agent to return `<insurance_research_result>` and render its full output.

**If agent fails to return expected XML block:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run /finyx:insurance kfz to retry.
Coverage benchmark analysis above (Phases 3–4) is unaffected.
```

---

## Phase 6: Recommendation

Synthesize all data from Phases 0–5 into a clear, reasoned advisory recommendation.

**Tier recommendation logic:**

1. **Underinsurance gap (high priority):**
   - User has Haftpflicht only + vehicle age 0–3 years → "Significant coverage gap — Vollkasko is strongly recommended for your vehicle age. Out-of-pocket repair costs for a newer vehicle can be substantial."
   - User has Haftpflicht only + vehicle financed → "Coverage gap — your financing contract almost certainly requires Vollkasko. Verify your Kfz-Kredit terms immediately."
   - User has Haftpflicht only + vehicle age 3–7 years → "Consider upgrading to Teilkasko at minimum — theft, weather, and wildlife collision are not covered under Haftpflicht only."

2. **Over-insurance flag:**
   - User has Vollkasko + vehicle age 12+ years + not financed → "Potential over-insurance — Vollkasko premiums on older vehicles may exceed the vehicle's actual market value. A downgrade to Teilkasko could save €[estimated savings from research agent output] per year. Compare the annual premium saving against the vehicle's current Marktwert."

3. **SF-Klasse awareness:**
   - If sf_klasse is known and < 5 → "Your low SF-Klasse ({sf_klasse}) means premiums are near the base rate. As your no-claims history builds, premiums will improve — consider how many claim-free years remain before your next review."
   - If sf_klasse is known and >= 20 → "Your strong SF-Klasse ({sf_klasse}) reflects a significant no-claims discount. An at-fault accident would cause a regression of 4–6 classes — factor this risk into any decisions to lower your coverage tier."
   - If sf_klasse is "unknown" → "SF-Klasse not provided — check your Versicherungsschein for your current class; it is the single largest premium driver for Kfz."

4. **Market context (from research agent):**
   Include key findings from `<insurance_research_result>` — typical premium ranges for your profile, red flags to avoid, and criteria to check when comparing policies.

5. **Cancellation window:**
   Summarize from Phase 4 — mention the 30.11 deadline explicitly if the window is currently open or approaching.

**Concrete next steps:**

Present 2–3 prioritized actions:

1. If coverage gap identified: "Upgrade to {recommended_tier} — contact your insurer or compare alternatives before the next 30.11 deadline."
2. If over-insured: "Request a quote for Teilkasko from your current insurer and compare against your vehicle's current Marktwert (check ADAC Fahrzeugbewertung or Eurotax Schwacke)."
3. "Compare your current premium against market benchmarks — use criteria from the research output above. Request quotes from at least 2 alternatives before 30.11 to ensure you can switch if a better option is found."
4. "Add your Kfz policy details to your profile via `/finyx:insurance portfolio` if not already done — this enables ongoing deadline tracking."

Frame all language as "based on this analysis" — not as definitive advice.

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**SF-Klasse validation error:**
If the user provides a non-numeric input for SF-Klasse (other than "unknown") — accept the input as "unknown" and note: "SF-Klasse must be a number between 0 and 35 or 'unknown'. Proceeding with unknown — market estimates will not be personalized."

**Reference doc read error:**
If `${CLAUDE_SKILL_DIR}/references/germany/kfz.md` cannot be read: proceed with the coverage tier descriptions from this file's Phase 3, but flag benchmarks as "[reference doc unavailable — values are approximate]".

**Research agent failure:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run /finyx:insurance kfz to retry.
Coverage benchmark analysis (Phases 3–4) remains available above.
```

**Financed vehicle with Haftpflicht only:**
When this combination is detected in Phase 3d, emit an elevated warning (banner, not inline text) — this is a contractual compliance issue, not merely a coverage preference.

</error_handling>

<notes>

## Write Targets

This sub-skill writes NO files. All output is conversational advisory text. All profile updates (policy data entry, coverage tier changes) are handled by `/finyx:insurance portfolio`.

## Coverage Components Field

One policy entry per Kfz contract — NOT one entry per coverage level. The `coverage_components` field is a string array containing all active tiers for the contract:
- `["Haftpflicht"]` — Haftpflicht only
- `["Haftpflicht", "Teilkasko"]` — Haftpflicht + Teilkasko
- `["Haftpflicht", "Teilkasko", "Vollkasko"]` — Vollkasko (includes all lower tiers)

Do not expect separate policy entries per tier.

## Typklasse and Regionalklasse

These two rating factors are vehicle-model-specific and district-specific respectively:
- **Typklasse** varies by vehicle make, model, and variant — published annually by Kraftfahrtbundesamt (KBA). Beyond advisory scope — tell the user to check GDV's online Typklassen-Abfrage at gdv.de.
- **Regionalklasse** varies by registration district (Zulassungsbezirk) — the research agent handles this via the `user_city` parameter. If city is absent, the agent returns general market context instead of localized ranges.

## §1 PflVG — Legal Mandatory Status

Kfz-Haftpflicht is the ONLY insurance type in this skill set that is legally mandatory in Germany. §1 PflVG (Pflichtversicherungsgesetz) requires it for every vehicle driven on public roads. §6 PflVG makes operating an uninsured vehicle a criminal offense. Include this context when the user has no policy or Haftpflicht only, to reinforce the legal dimension beyond advisory preference.

## 30.11 Cancellation Deadline

The 30.11 deadline is Kfz-specific — it is the result of the 1-month Kündigungsfrist applied to the standard 01.01 renewal date. No other insurance type in this skill set has this calendar-pinned deadline. Always mention 30.11 explicitly when discussing Kfz cancellation.

## Sonderkündigungsrecht After SF-Klasse Reclassification

Unlike other insurance types where Sonderkündigungsrecht triggers are premium increases or claim settlements, Kfz adds SF-Klasse reclassification as a distinct trigger. After an at-fault claim, the SF-Klasse regression notification creates a 4-week cancellation window for the insured. This is particularly valuable because the regression also makes the user more attractive to competitors offering better terms on a lower SF-Klasse.

## Research Agent — §34d GewO Compliance

The research agent returns criteria-based market context for Kfz — it does NOT return specific provider names, tariff names, or product rankings (§34d GewO compliance for non-health types). This is intentional and encoded in the agent's process. The sub-skill must not attempt to extract or request provider-specific recommendations from the agent.

## Disclaimer Placement

Disclaimer is emitted in Phase 2 before any advisory content (Phase 3 onward) — consistent with health.md and portfolio.md disclaimer-first pattern.

## Router Integration

The router SKILL.md dispatches to this file via the `kfz` slug. No changes to SKILL.md are required. The router already loads `disclaimer.md` and `profile.json` at startup — this sub-skill must NOT add `<execution_context>` blocks or duplicate those loads.

</notes>
