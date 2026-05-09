# Health Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->

<objective>

Deliver a personalized PKV vs GKV comparison by orchestrating eligibility checks, a health questionnaire, and two specialist agents. The command:
1. Checks PKV eligibility against JAEG threshold (per D-01, D-02) — reads the JAEG value from the loaded health-insurance.md, never hardcodes it
2. Emits age-55 lock-in warning when applicable (per D-03) — uses §6 Abs. 3a SGB V legal basis
3. Detects expat status and shows Anwartschaft/portability guidance (per D-06, D-07)
4. Collects health questionnaire via single multiSelect with ~25 binary flags grouped by category (per D-04, D-05)
5. Spawns calc + research agents in parallel (per D-08, D-09)
6. Emits legal disclaimer BEFORE any advisory content (per D-10, matching insights.md pattern)
7. Synthesizes unified comparison with a clear, reasoned recommendation

This command writes NO files. All output is conversational advisory text.

</objective>

<process>

## Phase 0: Preferences

Use AskUserQuestion to collect user preferences before running eligibility checks. Collect all three questions in a single round-trip where possible.

**Question 1 — Monthly budget range:**
"What is your monthly budget range for health insurance premiums?"
- Under €400
- €400–600
- €600–800
- €800+
- No budget constraint

**Question 2 — Coverage priority (single-select):**
"What is your primary coverage priority?"
- Lowest premium
- Best coverage depth
- Maximum flexibility (tariff switching)
- Balanced

**Question 3 — Lifestyle / coverage needs (multiSelect):**
"Which coverage features are important to you? Select all that apply."
- International travel coverage (worldwide, not just EU)
- Alternative medicine / Heilpraktiker coverage
- Single-room hospital (Einbettzimmer)
- Chief physician treatment (Chefarztbehandlung)
- Dental coverage beyond basic (Zahnzusatz)
- Vision coverage (glasses/contacts/laser)
- Outpatient psychotherapy (Ambulante Psychotherapie)

Store results as `user_preferences` object:
```
user_preferences = {
  budget_range: [selected],
  coverage_priority: [selected],
  lifestyle_needs: [comma-separated list of selected items, or "none"]
}
```

Pass `user_preferences` to BOTH agents in Phase 4 Task prompts inside a `<user_preferences>` block:
```
<user_preferences>
budget_range: [selected]
coverage_priority: [selected]
lifestyle_needs: [comma-separated list of selected items, or "none"]
</user_preferences>
```

---

## Phase 1: Validation and Eligibility Gate

**Check profile exists:**
```bash
PROFILE_PATH=$("${CLAUDE_SKILL_DIR}/../../scripts/resolve-profile.sh") || exit $?
```

**Read `$PROFILE_PATH`** (resolved by the gate check above; the @-include is a project-local fast-path) and extract:
- `identity.residence_country` — confirm Germany is in scope
- `identity.family_status` — "single" or "married"
- `identity.children` (or `investor.children`) — number of dependent children
- `identity.cross_border` — boolean expat flag
- `identity.income_countries` — array of active income countries (if present)
- `countries.germany.gross_income` — annual gross income in EUR
- `countries.germany.marginal_rate` — decimal percentage for tax netting
- `countries.germany.tax_class` — null means Germany not active
- `employment.type` — "employee", "self_employed", or "beamter"

**Check Germany is active:**
If `countries.germany.tax_class` is null or absent:
```
ERROR: Health insurance advisor requires German income data.
Update your profile with /finyx:profile — add your German income and tax class.
```
Stop here.

**Tax year staleness check:**
```bash
CURRENT_YEAR=$(date +%Y)
echo "Current year: $CURRENT_YEAR"
```

The loaded health-insurance.md has `tax_year: 2025` in its frontmatter. If `CURRENT_YEAR != 2025`, emit this warning before proceeding:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE: STALENESS WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reference docs are from tax year 2025. Current year is [CURRENT_YEAR].
JAEG, BBG, Zusatzbeitrag rates, and Pflegeversicherung rates may have changed.
Verify all thresholds against official GKV-Spitzenverband / BMF publications
before making any decisions based on this output.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**JAEG Eligibility Gate (ELIG-01):**

Read the JAEG threshold from the loaded health-insurance.md Section 4.1. The 2025 value is €77,400/year. Do NOT hardcode this value — read it from the reference doc at runtime so it stays accurate as docs are updated.

Check employment type:
- If `employment.type == "beamter"`: redirect to health-insurance.md Section 6.1 (Beihilfe system). Do not proceed with standard GKV/PKV comparison.
- If `employment.type == "self_employed"`: self-employed persons may choose PKV regardless of income (per Section 4.2 of health-insurance.md). Set `pkv_eligible = true` and skip the income gate.

For employees: compare `countries.germany.gross_income` against the JAEG threshold read from Section 4.1.

**If income < JAEG (employee path only):**

Spawn the calc agent with `gkv_only=true` context, show GKV estimate, then STOP:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE: GKV MANDATORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your gross income (€[gross_income]) is below the Versicherungspflichtgrenze
(JAEG: €[jaeg_from_doc]/year). PKV is not available to employees below this
threshold.

Your estimated GKV cost:
```

Spawn the calc agent with these instructions:
```
You are the finyx-insurance-calc-agent. Compute GKV costs only for this user (no PKV comparison needed — user is below JAEG threshold).

Profile data is at `.finyx/profile.json`. Reference doc is at `${CLAUDE_SKILL_DIR}/references/germany/health-insurance.md`.

<health_flags>
none
</health_flags>

Complete Phase 1 and Phase 2 (GKV Breakdown) only. Return your GKV breakdown output wrapped in <insurance_calc_result> tags.
```

Extract and display `<gkv_breakdown>` from the result. Then STOP — do NOT proceed to questionnaire or full comparison.

**If income >= JAEG or self-employed:** set `pkv_eligible = true` and proceed to Phase 2.

---

## Phase 2: Warnings and Expat Detection

**Age-55 Lock-In Warning (EDGE-02):**

Check `identity.age` (or ask inline if not present — see error handling). If age is unknown, use AskUserQuestion: "What is your current age?"

If `age >= 50` and `pkv_eligible == true`, emit the following banner BEFORE the questionnaire:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ⚠  AGE-55 LOCK-IN WARNING (§6 Abs. 3a SGB V)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You are [age] years old. Under §6 Abs. 3a SGB V, if you switch
to PKV and remain insured for 10+ years past age 55, returning
to GKV becomes near-impossible — even if your income drops below
the JAEG threshold in later years.

This is effectively an IRREVERSIBLE decision at your age.
Consider this carefully before proceeding.

The calc and research agents will also flag this. Consulting a
licensed Versicherungsberater before switching is strongly advised.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Set `show_age_warning = true` for the recommendation phase (Phase 7).

**Expat Detection (EDGE-01):**

Check profile: `identity.cross_border === true` OR `identity.income_countries` array has length > 1.

If either signal is present: set `show_expat = true`.

If neither signal is present, ask inline:

Use AskUserQuestion: "Are you or have you been a resident outside Germany within the last 5 years? (yes / no)"

If user confirms: set `show_expat = true`.
If user denies: set `show_expat = false` and skip Section 6.4 in Phase 6.

---

## Phase 3: Health Questionnaire

Use AskUserQuestion with multiSelect to collect all ~25 binary health flags in a single round-trip (per D-04). This satisfies GDPR Art. 9 by never writing health data to any file.

Present the following question:

**Preamble:** "Select any conditions that apply. This information is used ONLY for this session to estimate PKV risk tier — it is never stored or persisted (GDPR Art. 9 compliant). Select none if no conditions apply."

**Options (~25 flags grouped by category):**

**Cardiovascular [CV]:**
- [CV] High blood pressure (diagnosed/treated)
- [CV] Heart condition or cardiac event
- [CV] Elevated cholesterol (treated)

**Metabolic [MET]:**
- [MET] Diabetes (Type 1 or Type 2)
- [MET] Thyroid condition (treated)
- [MET] BMI above 30

**Musculoskeletal [MSK]:**
- [MSK] Chronic back condition
- [MSK] Joint condition (diagnosed)
- [MSK] Prior orthopedic surgery
- [MSK] Sports injury history (recurring)

**Mental Health [MH]:**
- [MH] Depression or anxiety (diagnosed/treated)
- [MH] Other psychiatric condition
- [MH] Current psychotherapy

**Medications & Hospitalizations [MED]:**
- [MED] Currently taking prescription medications
- [MED] Hospitalized in the last 5 years
- [MED] Planned surgery or procedure in next 12 months

**Lifestyle [LIFE]:**
- [LIFE] Smoker (current or quit within last 5 years)
- [LIFE] Alcohol consumption above moderate (>14 units/week)

**Reproductive [REPR]:**
- [REPR] Pregnancy planned in next 2 years

**Dental & Vision [DV]:**
- [DV] Dental treatment needed (crowns, implants, orthodontics)
- [DV] Vision correction needed (glasses, contacts, or planned laser)

**Family History [FAM]:**
- [FAM] Parent with heart disease before age 60
- [FAM] Parent with diabetes
- [FAM] Parent with cancer before age 60

**Other [OTH]:**
- [OTH] Allergies requiring regular treatment
- [OTH] Sleep apnea (diagnosed)

Collect the selected flags as a list. Map each selected flag to the corresponding `health_flags` field names expected by the calc agent (see Phase 4 Task 1 prompt). If none are selected, pass `health_flags: none`.

---

## Phase 4: Agent Spawning

Spawn BOTH agents in PARALLEL via the Task tool — do NOT wait for one before spawning the other.

Resolve the following values before constructing prompts:
- `user_age` — from profile or asked in Phase 2
- `employment_type` — from profile (default: "employee" if absent)
- `family_status` — from profile
- `children_count` — from profile (default: 0 if absent)
- `health_flags_block` — mapped from Phase 3 selections (format shown below)

**Task 1 — Calc Agent:**

```
You are the finyx-insurance-calc-agent. Compute a GKV vs PKV cost comparison.

Profile data is at `.finyx/profile.json`. Reference doc is at `${CLAUDE_SKILL_DIR}/references/germany/health-insurance.md`.

<health_flags>
[For each selected flag from Phase 3, map to the agent's expected field names:
  - [CV] High blood pressure → hypertension: 1
  - [CV] Heart condition or cardiac event → cardiac_event: 1  (maps to high-rejection flag)
  - [CV] Elevated cholesterol (treated) → elevated_cholesterol: 1
  - [MET] Diabetes (Type 1 or Type 2) → diabetes: 1
  - [MET] Thyroid condition (treated) → thyroid: 1
  - [MET] BMI above 30 → elevated_bmi: 1
  - [MSK] Chronic back condition → back_spinal: 1
  - [MSK] Joint condition (diagnosed) → joint_conditions: 1
  - [MSK] Prior orthopedic surgery → previous_surgery: 1
  - [MSK] Sports injury history (recurring) → sports_injury: 1
  - [MH] Depression or anxiety (diagnosed/treated) → depression_anxiety: 1  (maps to high-rejection flag)
  - [MH] Other psychiatric condition → other_psychiatric: 1  (maps to high-rejection flag)
  - [MH] Current psychotherapy → psychotherapy_current: 1  (maps to high-rejection flag)
  - [MED] Currently taking prescription medications → regular_medication: 1
  - [MED] Hospitalized in the last 5 years → recent_hospitalization: 1
  - [MED] Planned surgery or procedure in next 12 months → planned_surgery: 1
  - [LIFE] Smoker (current or quit within last 5 years) → smoker: 1
  - [LIFE] Alcohol consumption above moderate → high_alcohol: 1
  - [REPR] Pregnancy planned in next 2 years → pregnancy_planned: 1
  - [DV] Dental treatment needed → dental_needs: 1
  - [DV] Vision correction needed → vision_needs: 1
  - [FAM] Parent with heart disease before age 60 → family_cardiac: 1
  - [FAM] Parent with diabetes → family_diabetes: 1
  - [FAM] Parent with cancer before age 60 → family_cancer: 1
  - [OTH] Allergies requiring regular treatment → allergies_severe: 1
  - [OTH] Sleep apnea (diagnosed) → sleep_apnea: 1
Unselected flags: set to 0. If none were selected: write "none"]
</health_flags>

<user_preferences>
budget_range: [from Phase 0 user_preferences]
coverage_priority: [from Phase 0 user_preferences]
lifestyle_needs: [from Phase 0 user_preferences]
</user_preferences>

Complete all phases of your process and return your output wrapped in <insurance_calc_result> tags.
```

**Task 2 — Research Agent:**

```
You are the finyx-insurance-research-agent. Research current PKV tariffs for this user profile.

Profile data is at `.finyx/profile.json`. Reference doc is at `${CLAUDE_SKILL_DIR}/references/germany/health-insurance.md`.

User context:
age: [user_age]
employment_type: [employment_type]
family_status: [family_status]
children_count: [children_count]
gross_income_bracket: [derive from gross_income — e.g., "80,000–90,000 EUR/year"]
current_year: [CURRENT_YEAR from Phase 1]

<user_preferences>
budget_range: [from Phase 0 user_preferences]
coverage_priority: [from Phase 0 user_preferences]
lifestyle_needs: [from Phase 0 user_preferences]
</user_preferences>

Also research per provider: (a) direct application URL, (b) required documents to apply, (c) estimated application processing time. Include these in your output.

Complete all phases of your process and return your output wrapped in <insurance_research_result> tags.
```

Collect both outputs:
- `<insurance_calc_result>` from Task 1
- `<insurance_research_result>` from Task 2

If either agent fails to return its expected XML block, record the error for display in Phase 6 (see error handling).

---

## Phase 5: Legal Disclaimer

Per D-10, emit the legal disclaimer BEFORE any advisory content — matching the insights.md disclaimer-first pattern. This ensures the user sees the advisory framing before receiving any comparison data or recommendations.

Emit the main header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Immediately emit the full legal disclaimer from the loaded `disclaimer.md`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 LEGAL DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[Output the full disclaimer.md content here]

Then append this insurance-specific addendum:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 INSURANCE-SPECIFIC NOTICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PKV premium estimates are based on age-bracket approximations and health
risk tier classification — actual premiums are determined by individual
medical underwriting. This tool does not replace a consultation with a
licensed Versicherungsberater or Versicherungsmakler.

Health insurance decisions are long-term commitments. Switching costs and
lock-in effects (§6 Abs. 3a SGB V) mean mistakes are difficult to reverse.

Always obtain actual PKV quotes from the providers listed in this report
before making any coverage decision.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 6: Comparison Synthesis

### 6.1 Side-by-Side Comparison Table

Extract from `<insurance_calc_result>`:
- GKV monthly cost from `<gkv_breakdown>`
- PKV net monthly cost (after employer subsidy) from `<pkv_estimate>`
- PKV net monthly cost after §10 EStG from `<tax_netting>`
- Family monthly total from `<family_impact>` (if applicable)

Present as:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PKV vs GKV: COST COMPARISON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

|                              | GKV      | PKV      |
|------------------------------|----------|----------|
| Monthly cost (you)           | €XXX     | €XXX     |
| Monthly cost (family total)  | €XXX     | €XXX     |
| Tax benefit (§10 EStG)       | —        | -€XX/mo  |
| Net monthly cost             | €XXX     | €XXX     |
| Monthly delta (PKV − GKV)   |          | €±XXX    |
```

Note: If family impact returns "N/A — single household", omit the family row.

### 6.2 PKV Provider Options

Extract from `<insurance_research_result>` the provider comparison table (Section 5.1 of the research agent output). Present it directly — do not re-derive or summarize provider data.

### 6.3 Projection Summary

Extract from `<projection_table>` within `<insurance_calc_result>`.

Show the base scenario table (Scenario B: PKV +6%/yr, GKV +3%/yr) inline with the 10/20/30-year horizons. Then note:
- Conservative scenario crossover year: [from Scenario A]
- Base scenario crossover year: [from Scenario B]
- Optimistic scenario crossover year: [from Scenario C]

Include the non-linear growth warning from the calc agent's projection output.

### 6.4 Expat Considerations (conditional — only if `show_expat == true`, per D-07)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 EXPAT CONSIDERATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Emit guidance from health-insurance.md Section 6.2 covering:

**Anwartschaftsversicherung:** If you hold PKV and relocate abroad temporarily, an Anwartschaft policy preserves your entry age and health underwriting. Without it, re-entry after foreign residence resets your age brackets and requires new underwriting. Recommend Anwartschaft as the default strategy for PKV holders planning temporary relocation.

**EU Portability:** The European Health Insurance Card (EHIC/DSGVO-compliant successor) covers emergency care in EU/EEA countries for GKV members. PKV members may need supplemental international coverage — verify tariff scope with your PKV provider.

**Non-EU Gap Coverage:** EU portability (EHIC) does not apply outside the EU/EEA. Both GKV and PKV members planning non-EU stays should verify whether their domestic coverage extends internationally or whether a separate international health policy is required.

**Recommendation:** For PKV holders who may relocate: budget for Anwartschaft premiums (typically €30–80/month) as an insurance against re-entry costs. This is nearly always cheaper than exiting PKV and re-entering later at an older age.

---

## Phase 7: Recommendation

Based on the data from both agents, synthesize a clear, reasoned recommendation — not just a data presentation.

Reasoning framework:

**If GKV is clearly cheaper in ALL projection scenarios (all three crossover-year horizons show GKV wins):**
Recommend staying in GKV. Explain: current PKV cost advantage (if any) is reversed by [crossover year] under the base scenario. Emphasize that once the crossover happens, the gap compounds.

**If PKV is cheaper now but the base-scenario crossover occurs within 15 years:**
Flag the trajectory. Recommend evaluating PKV only if the user expects above-average income growth (which raises the GKV cap) or is willing to optimize via Beitragsrückerstattung and Selbstbeteiligung.

**If user has family (family_status == "married" or children > 0):**
Emphasize the Familienversicherung advantage of GKV — non-working partners and children at €0 additional premium is a significant structural advantage that PKV cannot match.

**If age >= 50 (show_age_warning == true):**
Re-emphasize the §6 Abs. 3a SGB V lock-in risk. Frame the PKV decision as close to irreversible. Recommend consulting a licensed Versicherungsberater before switching under any circumstances.

**If health flags from Phase 3 suggest risk tier > standard (Tier 1 or Tier 2):**
Note that actual PKV quotes from underwriting may exceed the estimates in this report. Risk surcharges or exclusion clauses are common — always obtain actual quotes before deciding.

**Always include concrete next steps:**
"To act on this analysis: get actual PKV quotes from [top provider from research agent output], compare with your current GKV Zusatzbeitrag, and consult a licensed Versicherungsberater for final verification."

Frame all recommendation language as "based on this analysis" — not as definitive advice.

### Concrete Next Steps

For each of the top 3 providers from the research agent output, present:

1. **[Provider Name]**
   - Apply: [URL from research agent's provider data]
   - Required documents: [from research agent output]
   - Estimated processing time: [from research agent output]
   - First step: [specific action — e.g., "Request a non-binding quote online at [URL]"]

If the research agent did not return application URLs or document requirements for a provider, note: "[Provider]: Application details not found in research — visit [provider website] directly."

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**No German income data:**
```
ERROR: Health insurance advisor requires German income data.
Your profile exists but Germany (tax_class) is not configured.
Run /finyx:profile to complete the country-specific German income section.
```

**Missing age in profile:**
Use AskUserQuestion inline in Phase 2: "What is your current age?" — this is required to check the age-55 lock-in condition. If the user declines to answer, skip the age-55 warning and note: "[Age not provided — age-55 lock-in check skipped]".

**Beamter employment type:**
Output redirect from health-insurance.md Section 6.1: "Employment type is Beamter. The standard PKV/GKV cost model does not apply — Beamter receive Beihilfe, which covers 50–80% of costs. Full Beamter comparison (Beihilfe + supplemental PKV) is planned for v1.3 (BEAM-01). Run /finyx:profile and update your employment type if this is incorrect."

**Calc agent fails to return XML:**
```
Calc agent output not received — finyx-insurance-calc-agent did not return the expected
<insurance_calc_result> block. Re-run /finyx:insurance to retry.
```

**Research agent fails to return XML:**
```
Research agent output not received — finyx-insurance-research-agent did not return the expected
<insurance_research_result> block. Re-run /finyx:insurance to retry.
Calc agent data is available — cost projection and GKV/PKV comparison are based on calc agent output only.
```

</error_handling>

<notes>

## Write Targets

This command writes NO files. All output is conversational advisory text. Health flags from Phase 3 exist only in the Task prompt session and are never persisted — GDPR Art. 9 compliant.

## Disclaimer Placement

Per D-10, the legal disclaimer is emitted in Phase 5 BEFORE any advisory content (comparison, projections, recommendation). This matches the insights.md disclaimer-first pattern. It differs from `/finyx:tax` and `/finyx:invest` which append the disclaimer at the end — the insurance command follows the insights.md precedent due to the long-term consequences of the decision.

## Self-Employed JAEG Exemption

Self-employed persons (`employment.type == "self_employed"`) can choose PKV regardless of income, per health-insurance.md Section 4.2. The JAEG income gate applies only to employees. Self-employed users bypass the JAEG check and proceed directly to Phase 2.

## Agent Parallel Spawning

Both agents MUST be spawned in parallel in Phase 4 — do not wait for the calc agent before spawning the research agent. This reduces total wall-clock time for the command.

## Health Flags Session-Only

The 25 health flags collected in Phase 3 are:
1. Shown to the user as a multiSelect question
2. Passed inline to the calc agent only in the Task prompt as `<health_flags>` content
3. NEVER written to `.finyx/profile.json` or any other file
4. NEVER included in the research agent prompt (search queries must not contain health data)

## Reference Doc Loading

The router already loads `disclaimer.md` and `profile.json` at startup. The health-insurance.md reference doc must be loaded by the sub-skill's Phase 1 or passed via agent Task prompts. Agents load it independently via their own context blocks. The command uses health-insurance.md for: (a) JAEG threshold reading in Phase 1, (b) staleness check against current year, and (c) §6 Abs. 3a legal text reference for the age-55 warning.

## Expat Section Trigger

Section 6.4 (Expat Considerations) is emitted only when `show_expat == true`. The trigger logic: `identity.cross_border === true` OR `identity.income_countries.length > 1` OR user confirms "yes" to the inline AskUserQuestion. Do NOT emit the expat section for confirmed non-expat users.

## GKV-Mandatory Fast Path

When income < JAEG (employee path), the command takes an abbreviated path: spawns calc agent (GKV only) → shows GKV cost → stops. No questionnaire, no research agent, no full comparison. This respects D-02 from the CONTEXT decisions.

## Skill Agents

Both specialist agents are scoped to this skill under `skills/insurance/agents/`:
- `finyx-insurance-calc-agent.md` — deterministic GKV/PKV cost calculations, risk tier classification, family impact, and 10/20/30-year projections
- `finyx-insurance-research-agent.md` — live PKV provider research via WebSearch, tariff comparison, application details

Reference documents are at `${CLAUDE_SKILL_DIR}/references/`:
- `disclaimer.md` — shared legal disclaimer
- `germany/health-insurance.md` — JAEG thresholds, GKV/PKV mechanics, Beihilfe, expat guidance

</notes>
