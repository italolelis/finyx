---
task_id: 260409-45h
type: quick
tasks: 2
---

<objective>
Fix /finyx:insurance command and both agents based on user testing feedback. Expand health questionnaire, add preferences phase, deepen research agent provider comparisons, add anti-hallucination rule to calc agent, and add concrete next steps to recommendations.
</objective>

<tasks>

<task id="1" type="auto">
  <name>Enhance insurance command: preferences phase, expanded questionnaire, concrete next steps</name>
  <read_first>
    - commands/finyx/insurance.md (full file — already loaded)
  </read_first>
  <files>commands/finyx/insurance.md</files>
  <action>
Edit commands/finyx/insurance.md with these 3 changes:

**Change A — Add Phase 0 "Preferences" BEFORE Phase 1 (Eligibility Gate).**

Insert a new "Phase 0: Preferences" between the `<process>` tag and current Phase 1. Use AskUserQuestion to collect:

1. Monthly budget range for health insurance (e.g., "under 400", "400-600", "600-800", "800+", "no budget constraint")
2. Coverage priority — single-select: "Lowest premium", "Best coverage depth", "Maximum flexibility (tariff switching)", "Balanced"
3. Lifestyle/coverage needs — multiSelect with these options:
   - International travel coverage (worldwide, not just EU)
   - Alternative medicine / Heilpraktiker coverage
   - Single-room hospital (Einbettzimmer)
   - Chief physician treatment (Chefarztbehandlung)
   - Dental coverage beyond basic (Zahnzusatz)
   - Vision coverage (glasses/contacts/laser)
   - Outpatient psychotherapy (Ambulante Psychotherapie)

Store results as `user_preferences` object. Pass to BOTH agents in Phase 4 Task prompts inside a `<user_preferences>` block. Format:
```
<user_preferences>
budget_range: [selected]
coverage_priority: [selected]
lifestyle_needs: [comma-separated list of selected items, or "none"]
</user_preferences>
```

Renumber existing phases: Phase 1 becomes Phase 1 (unchanged label), etc. — only the new Phase 0 is inserted before it.

**Change B — Expand health questionnaire from 15 to ~25 flags in Phase 3.**

Replace the current 15-flag list with these grouped categories (~25 flags). Keep the multiSelect format and GDPR preamble:

**Cardiovascular [CV]:**
- High blood pressure (diagnosed/treated)
- Heart condition or cardiac event
- Elevated cholesterol (treated)

**Metabolic [MET]:**
- Diabetes (Type 1 or Type 2)
- Thyroid condition (treated)
- BMI above 30

**Musculoskeletal [MSK]:**
- Chronic back condition
- Joint condition (diagnosed)
- Prior orthopedic surgery
- Sports injury history (recurring)

**Mental Health [MH]:**
- Depression or anxiety (diagnosed/treated)
- Other psychiatric condition
- Current psychotherapy

**Medications & Hospitalizations [MED]:**
- Currently taking prescription medications
- Hospitalized in the last 5 years
- Planned surgery or procedure in next 12 months

**Lifestyle [LIFE]:**
- Smoker (current or quit within last 5 years)
- Alcohol consumption above moderate (>14 units/week)

**Reproductive [REPR]:**
- Pregnancy planned in next 2 years

**Dental & Vision [DV]:**
- Dental treatment needed (crowns, implants, orthodontics)
- Vision correction needed (glasses, contacts, or planned laser)

**Family History [FAM]:**
- Parent with heart disease before age 60
- Parent with diabetes
- Parent with cancer before age 60

**Other [OTH]:**
- Allergies requiring regular treatment
- Sleep apnea (diagnosed)

Update the flag mapping in Phase 4 Task 1 (calc agent prompt) to include the new flags. New mappings:
- [MSK] Sports injury history → sports_injury: 1
- [MED] Currently taking prescription medications → regular_medication: 1 (replaces old OTH version)
- [MED] Hospitalized in last 5 years → recent_hospitalization: 1
- [MED] Planned surgery → planned_surgery: 1
- [LIFE] Smoker → smoker: 1
- [LIFE] Alcohol above moderate → high_alcohol: 1
- [REPR] Pregnancy planned → pregnancy_planned: 1
- [DV] Dental treatment needed → dental_needs: 1
- [DV] Vision correction needed → vision_needs: 1
- [FAM] Parent heart disease → family_cardiac: 1
- [FAM] Parent diabetes → family_diabetes: 1
- [FAM] Parent cancer → family_cancer: 1

Also update the notes section "Health Flags Session-Only" — change "15 health flags" to "25 health flags".

**Change C — Add concrete next steps per provider in Phase 7 (Recommendation).**

After the existing recommendation logic in Phase 7, add a new subsection:

```
### Concrete Next Steps

For each of the top 3 providers from the research agent output, present:

1. **[Provider Name]**
   - Apply: [URL from research agent's provider data]
   - Required documents: [from research agent output]
   - Estimated processing time: [from research agent output]
   - First step: [specific action — e.g., "Request a non-binding quote online at [URL]"]

If the research agent did not return application URLs or document requirements for a provider, note: "[Provider]: Application details not found in research — visit [provider website] directly."
```

Also add to the Research Agent Task 2 prompt in Phase 4: append to the prompt text:
```
Also research per provider: (a) direct application URL, (b) required documents to apply, (c) estimated application processing time. Include these in your output.
```
  </action>
  <acceptance_criteria>
    - grep -c "Phase 0: Preferences" commands/finyx/insurance.md returns 1
    - grep -c "user_preferences" commands/finyx/insurance.md returns at least 3
    - grep -c "budget_range" commands/finyx/insurance.md returns at least 1
    - grep -c "Heilpraktiker" commands/finyx/insurance.md returns at least 1
    - grep -c "Smoker" commands/finyx/insurance.md returns at least 1
    - grep -c "Pregnancy planned" commands/finyx/insurance.md returns at least 1
    - grep -c "family_cardiac" commands/finyx/insurance.md returns at least 1
    - grep -c "Hospitalized in the last 5 years" commands/finyx/insurance.md returns at least 1
    - grep -c "Concrete Next Steps" commands/finyx/insurance.md returns at least 1
    - grep -c "Required documents" commands/finyx/insurance.md returns at least 1
    - grep -c "25 health flags" commands/finyx/insurance.md returns at least 1
  </acceptance_criteria>
  <done>Insurance command has Phase 0 preferences, ~25-flag questionnaire grouped by category, and concrete next steps per provider in recommendation phase.</done>
</task>

<task id="2" type="auto">
  <name>Enhance both agents: deeper research, anti-hallucination, profile context</name>
  <read_first>
    - agents/finyx-insurance-research-agent.md (full file — already loaded)
    - agents/finyx-insurance-calc-agent.md (full file — already loaded)
  </read_first>
  <files>agents/finyx-insurance-research-agent.md, agents/finyx-insurance-calc-agent.md</files>
  <action>
**Change A — Deepen research agent provider comparisons (agents/finyx-insurance-research-agent.md).**

In Phase 3 "Extract Provider Data", expand the extraction fields table. Add these fields after the existing ones:

| Field | Description |
|-------|-------------|
| `tariff_tiers` | Specific tariff tier names with coverage breakdown: ambulant (outpatient), stationaer (inpatient/hospital), Zahn (dental) — e.g., "AM TOP: ambulant 100%, stationaer Einbettzimmer+Chefarzt, Zahn 90%" |
| `documents_required` | List of documents needed to apply (e.g., Gesundheitsfragen, income proof, ID, last 3 years medical records) |
| `application_process` | Step-by-step: how to apply (online form, broker, direct agent), typical timeline from application to coverage start |
| `waiting_periods` | Waiting periods for specific coverage areas (e.g., dental 8 months, psychotherapy 3 months, Entbindung 8 months) |
| `preexisting_exclusions` | How the provider handles pre-existing conditions: exclusion clauses, surcharge ranges, or acceptance with limitations |
| `basistarif_fallback` | Whether provider offers Basistarif (legally required) and any noted differences in service quality or acceptance |
| `customer_satisfaction` | Customer satisfaction ratings, claims processing ratings from neutral sources (DFSI, Assekurata, MAP-Report) |
| `apply_url` | Direct URL to request a quote or start application |

Add a new query to Phase 2, Query Group A (after existing query 3):

4. `"PKV [current_year] Kundenzufriedenheit Bewertung DFSI Assekurata MAP-Report"`

In Phase 5 output format, add new sections after 5.5:

### 5.6 Per-Provider Deep Dive

For each of the 3 providers:
- **Tariff tiers:** [tariff_tiers data]
- **Documents to apply:** [documents_required]
- **Application process:** [application_process]
- **Waiting periods:** [waiting_periods]
- **Pre-existing condition handling:** [preexisting_exclusions]
- **Basistarif fallback:** [basistarif_fallback]
- **Customer satisfaction:** [customer_satisfaction]
- **Apply URL:** [apply_url]

Renumber existing 5.6 Sources to 5.7, 5.7 Confidence to 5.8.

Add to the Anti-Patterns section:
- Do NOT fabricate tariff tier names, waiting periods, or customer ratings — if not found via WebSearch, state "not found" with [LOW CONFIDENCE]
- Do NOT skip the deep dive section — it is required for every provider in the comparison

Also update the output_format XML template to include the deep dive section structure.

**Change B — Add instruction to read profile and insights-config (agents/finyx-insurance-research-agent.md).**

In Phase 1 "Read Input Context", after the parameter parsing section, add:

```
**Read baseline context:**
Read `.finyx/profile.json` to understand the user's full financial picture (income, family, employment details). Also check for `.finyx/insights-config.json` — if it exists, read it for any prior insurance-related preferences or insights that provide baseline context for the research.

Use profile data to refine search queries (e.g., if self-employed, anchor queries to "Selbststaendige" tariffs; if family with children, prioritize family-friendly tariffs).
```

Add `.finyx/profile.json` and `.finyx/insights-config.json` awareness but do NOT add them to execution_context (they are passed via Task prompt context, not @-loaded).

**Change C — Add anti-hallucination rule to calc agent (agents/finyx-insurance-calc-agent.md).**

In the `<role>` section, after the "Confidence flags" paragraph, add:

```
**Anti-hallucination rule:** All growth rates, thresholds, and regulatory values (JAEG, BBG, Zusatzbeitrag, PV rates, PKV age brackets, projection growth rates) MUST come from health-insurance.md or the research agent output passed in context. Never use rates from training data or memory. If a value cannot be found in the reference doc or the reference doc feels outdated (e.g., tax_year in frontmatter does not match current year), flag the value as [NEEDS VERIFICATION] inline and proceed with the reference doc value as a conservative fallback.
```

Also add to the Anti-patterns list at the end of `<process>`:
```
- Do NOT use growth rates, JAEG thresholds, BBG caps, or Zusatzbeitrag rates from training data — ONLY from health-insurance.md Section references. Flag as [NEEDS VERIFICATION] if reference doc tax_year does not match current year.
```

**Change D — Research agent: accept and use user_preferences block.**

In Phase 1 of the research agent, after the parameter parsing section, add:

```
**User preferences (optional):**
The Task prompt may include a `<user_preferences>` block with:
- `budget_range` — monthly budget constraint
- `coverage_priority` — "Lowest premium", "Best coverage depth", "Maximum flexibility", or "Balanced"
- `lifestyle_needs` — comma-separated list of desired coverage features

Use these to:
- Filter providers: if budget_range is specified, deprioritize providers whose base tariff exceeds the budget ceiling
- Rank by priority: if coverage_priority is "Best coverage depth", weight comprehensive tariff tiers higher; if "Lowest premium", weight price competitiveness higher
- Match lifestyle needs: if user wants Heilpraktiker coverage, check and note which providers include it in their tariff or as add-on; same for Einbettzimmer, Chefarztbehandlung, dental, vision, psychotherapy, international coverage
```

In Phase 4 (Select Top 3 Providers), add a new criterion to the selection table:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| User preference match | High | Alignment with user's stated budget, coverage priority, and lifestyle needs |
  </action>
  <acceptance_criteria>
    - grep -c "tariff_tiers" agents/finyx-insurance-research-agent.md returns at least 2
    - grep -c "documents_required" agents/finyx-insurance-research-agent.md returns at least 2
    - grep -c "waiting_periods" agents/finyx-insurance-research-agent.md returns at least 2
    - grep -c "preexisting_exclusions" agents/finyx-insurance-research-agent.md returns at least 1
    - grep -c "basistarif_fallback" agents/finyx-insurance-research-agent.md returns at least 1
    - grep -c "customer_satisfaction" agents/finyx-insurance-research-agent.md returns at least 2
    - grep -c "apply_url" agents/finyx-insurance-research-agent.md returns at least 2
    - grep -c "Anti-hallucination" agents/finyx-insurance-calc-agent.md returns 1
    - grep -c "NEEDS VERIFICATION" agents/finyx-insurance-calc-agent.md returns at least 2
    - grep -c "profile.json" agents/finyx-insurance-research-agent.md returns at least 1
    - grep -c "insights-config.json" agents/finyx-insurance-research-agent.md returns at least 1
    - grep -c "user_preferences" agents/finyx-insurance-research-agent.md returns at least 2
    - grep -c "Deep Dive" agents/finyx-insurance-research-agent.md returns at least 1
  </acceptance_criteria>
  <done>Research agent has deep provider comparisons (tariff tiers, docs, waiting periods, exclusions, satisfaction ratings, apply URLs), reads profile/insights-config, accepts user preferences. Calc agent has anti-hallucination rule with NEEDS VERIFICATION flagging.</done>
</task>

</tasks>
