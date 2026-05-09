# Portfolio Insurance Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->
<!-- TODO: migrate to $PROFILE_PATH from scripts/resolve-profile.sh in a follow-up iteration. -->

<objective>

Deliver a portfolio-level insurance analysis by spawning the portfolio agent. The sub-skill:
1. Checks for existing policies in profile (`insurance.policies[]`)
2. Runs interactive policy entry if no policies exist
3. Emits disclaimer
4. Spawns `finyx-insurance-portfolio-agent` via Task tool
5. Renders the analysis as tier-classified conversational advisory output

This command writes to `.finyx/profile.json` ONLY during the interactive policy entry flow (Phase 0) when no policies exist. All other output is conversational only.

</objective>

<process>

## Phase 0: Policy Data Check

Read `.finyx/profile.json` (already loaded by the router).

Check `insurance.policies[]`.

**If the array is empty or the `insurance` key is absent:**

Use AskUserQuestion with multiSelect:

"You have no insurance policies recorded. Which insurance types do you currently have? Select all that apply, then we'll enter the details for each."

Options:
- Health insurance (GKV or PKV)
- Personal liability (Haftpflichtversicherung)
- Household contents (Hausratversicherung)
- Car insurance (Kfz-Versicherung)
- Legal protection (Rechtsschutzversicherung)
- Dental supplement (Zahnzusatzversicherung)
- Term life (Risikolebensversicherung)
- Travel insurance (Reiseversicherung)
- Bicycle insurance (Fahrradversicherung)
- Roadside assistance (Kfz-Schutzbriefversicherung)
- Rental deposit insurance (Mietkautionsversicherung)
- None -- I want to see what I'm missing (gap analysis only)

**If user selects "None -- I want to see what I'm missing":**
Proceed to Phase 1 with empty policies array. The portfolio agent will produce a gap-only analysis.

**For each selected type (other than None):**
Use AskUserQuestion to collect:
- Provider name (e.g., "HUK-COBURG", "Allianz")
- Monthly premium in EUR

Type-to-slug mapping:
- Health insurance (GKV or PKV) → type: "health"
- Personal liability (Haftpflichtversicherung) → type: "haftpflicht"
- Household contents (Hausratversicherung) → type: "hausrat"
- Car insurance (Kfz-Versicherung) → type: "kfz"
- Legal protection (Rechtsschutzversicherung) → type: "rechtsschutz"
- Dental supplement (Zahnzusatzversicherung) → type: "zahnzusatz"
- Term life (Risikolebensversicherung) → type: "risikoleben"
- Travel insurance (Reiseversicherung) → type: "reise"
- Bicycle insurance (Fahrradversicherung) → type: "fahrrad"
- Roadside assistance (Kfz-Schutzbriefversicherung) → type: "kfz-schutzbrief"
- Rental deposit insurance (Mietkautionsversicherung) → type: "mietkaution"

Build policy objects with ALL required schema fields for each collected policy:
```json
{
  "id": "{type}-{provider_slug}-{year}",
  "type": "{mapped slug}",
  "provider": "{provider name}",
  "premium_monthly": {monthly premium as number},
  "premium_annual": {premium_monthly * 12},
  "coverage_amount": null,
  "start_date": null,
  "renewal_date": null,
  "kuendigungsfrist_months": 3,
  "sonderkundigungsrecht": false,
  "doc_path": null,
  "coverage_components": [],
  "notes": null,
  "last_updated": "{current ISO date}"
}
```

ID generation rules:
- `provider_slug` = provider name lowercased, spaces replaced with hyphens, special chars removed (e.g., "HUK-COBURG" → "huk-coburg")
- `year` = current year (e.g., "2026")
- Example: `haftpflicht-huk-coburg-2026`

Write the updated profile.json with the new `policies[]` entries via the Write tool. Preserve all existing profile fields — only update `insurance.policies` array.

**If policies[] already has entries:** Proceed directly to Phase 1.

---

## Phase 1: Disclaimer

Emit the header banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE: PORTFOLIO OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Emit the full legal disclaimer from the loaded `disclaimer.md` (loaded by router's execution_context):

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

This portfolio analysis is advisory only. Coverage adequacy thresholds
are based on published benchmarks (GDV, Stiftung Warentest) — your
actual coverage needs depend on individual circumstances.

Verify all coverage details with your insurers. This tool does not
replace advice from a licensed Versicherungsberater (§34d GewO).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Spawn Portfolio Agent

Check profile for living area field:
- Look for `investor.livingAreaSqm`, `criteria.minSize`, or any field named with "sqm", "wohnflaeche", "living_area", or "area_sqm"
- If found: set `property_size_sqm` to that value
- If not found: set `property_size_sqm` to null

Spawn `finyx-insurance-portfolio-agent` via Task tool with this prompt:

```
You are the finyx-insurance-portfolio-agent. Analyze the user's full insurance portfolio.

Profile data is at `.finyx/profile.json`. Reference docs for all 11 insurance types are already loaded in your execution_context.

[If property_size_sqm is known:]
property_size_sqm: {value}

[If property_size_sqm is null:]
property_size_sqm: null — Hausrat adequacy will be marked UNKNOWN; advise user to add living area to profile via /finyx:profile.

Complete all phases of your process and return your output wrapped in <portfolio_analysis> tags.
```

Collect the `<portfolio_analysis>` output from the agent.

---

## Phase 3: Render Output

Parse the `<portfolio_analysis>` XML block returned by the agent.

**If agent did not return `<portfolio_analysis>`:**
Emit error: "Portfolio agent output not received. Re-run `/finyx:insurance portfolio` to retry."
Stop here.

**If `<portfolio_analysis>` was returned:**

Render as conversational advisory text organized by tier classification (Mandatory > Essential > Recommended > Situational):

### 3.1 Portfolio Overview

Present the total monthly and annual cost summary from the agent's Overview section:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 YOUR INSURANCE PORTFOLIO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Policies: [N]
Total monthly: EUR [XX.XX]
Total annual:  EUR [X,XXX.XX]
Analysis date: [date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.2 Coverage Adequacy

Present the Coverage Adequacy table from the agent output with benchmark source attribution.
Format benchmark column to include source (e.g., "≥€650/m² per GDV recommendation" for Hausrat, "≥€5,000,000 per Stiftung Warentest recommendation" for Haftpflicht).

### 3.3 Gap Detection

Present the Gaps table from the agent output.
Organize by tier: MANDATORY first, then ESSENTIAL, then OPTIONAL (Recommended/Situational).
Include family-context reason for each gap — the agent already derives this from `identity.family_status` and `identity.children`.

### 3.4 Overlap Warnings

Present each overlap as a separate warning banner with affected policies named inline:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WARNING: Potential Coverage Overlap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Overlap description with policy names and providers inline]
Recommended action: [action]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If no overlaps: output the agent's "No overlapping coverage detected" message without a warning banner.

### 3.5 Cost Summary

Present the per-policy cost table from the agent's Cost Summary section with monthly and annual totals.

**If property_size_sqm was null:**
Append note: "Hausrat adequacy requires living area (Wohnflaeche). Add it via `/finyx:profile` for a complete Hausrat coverage assessment."

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile.
```

**Portfolio agent fails to return XML:**
```
Portfolio agent output not received — finyx-insurance-portfolio-agent did not return the expected
<portfolio_analysis> block. Re-run `/finyx:insurance portfolio` to retry.
```

</error_handling>

<notes>

## Write Targets

This sub-skill writes to `.finyx/profile.json` ONLY during the interactive policy entry flow (Phase 0) when no policies exist. All other output is conversational only.

## Disclaimer Placement

Disclaimer is emitted in Phase 1 BEFORE any advisory content, matching the health.md disclaimer-first pattern. This ensures the user sees the advisory framing before receiving any portfolio data.

## Agent Spawning

Single agent spawn (portfolio agent). Unlike health.md which spawns two agents in parallel, portfolio uses only one agent — the `finyx-insurance-portfolio-agent` which handles all analysis internally.

## Property Size

The sub-skill checks the loaded profile for a living area field to pass as `property_size_sqm`. Check for `investor.livingAreaSqm`, `criteria.minSize`, or any sqm-related field name. If not found, Hausrat adequacy is marked UNKNOWN by the agent and the user is advised to add living area to their profile via `/finyx:profile`.

## Sub-skill Tool Permissions

This sub-skill requires: Read, Task, AskUserQuestion, Write
- Read: to check profile.json for living area field
- Task: to spawn the portfolio agent
- AskUserQuestion: for empty-portfolio interactive policy entry
- Write: to persist newly entered policy data to profile.json (Phase 0 only)

## Schema Compliance

Policy objects written in Phase 0 must include ALL fields from the `insurance.policies[]` schema:
id, type, provider, premium_monthly, premium_annual, coverage_amount (null), start_date (null),
renewal_date (null), kuendigungsfrist_months (3), sonderkundigungsrecht (false), doc_path (null),
coverage_components ([]), notes (null), last_updated (current ISO date).

</notes>
