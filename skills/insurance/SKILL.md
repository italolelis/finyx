---
name: finyx-insurance
description: Insurance advisor for Germany — portfolio overview, gap detection, per-type analysis (Haftpflicht, Hausrat, Kfz, Rechtsschutz, Zahnzusatz, Risikoleben, Reise, Fahrrad, Kfz-Schutzbrief, Mietkaution), PDF policy parsing, and health insurance (GKV vs PKV). Use when the user asks about insurance, Versicherung, coverage, policies, premiums, or any German insurance type.
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
  - WebSearch
  - WebFetch
disable-model-invocation: true
---

<objective>
Route the user's insurance question to the appropriate sub-skill advisor.
This skill:
1. Detects the insurance type from user input or asks when ambiguous
2. Loads and executes the matched sub-skill from ${CLAUDE_SKILL_DIR}/sub-skills/
3. Preserves the /finyx:insurance entry point for all insurance types
</objective>

<execution_context>
${CLAUDE_SKILL_DIR}/references/disclaimer.md
@.finyx/profile.json
<!-- Project-local fast-path. Authoritative profile path is resolved at runtime via scripts/resolve-profile.sh. See scripts/README.md. -->
</execution_context>

<process>

## Phase 0: Type Detection

Inspect `$ARGUMENTS` (the user's input after `/finyx:insurance`).

Keyword map (case-insensitive match against user input):
- "health", "kranken", "pkv", "gkv", "krankenversicherung" → sub-skill: health
- "haftpflicht", "liability", "privathaftpflicht", "haftpflichtversicherung" → sub-skill: haftpflicht
- "hausrat", "household", "contents", "hausratversicherung" → sub-skill: hausrat
- "kfz", "car", "auto", "kfz-versicherung", "autoversicherung", "kasko" → sub-skill: kfz
- "rechtsschutz", "legal", "rechtsschutzversicherung" → sub-skill: rechtsschutz
- "zahnzusatz", "dental", "zahn", "zahnzusatzversicherung" → sub-skill: zahnzusatz
- "risikoleben", "life", "term life", "risikolebensversicherung" → sub-skill: risikoleben
- "reise", "travel", "reiseversicherung" → sub-skill: reise
- "fahrrad", "bicycle", "bike", "fahrradversicherung" → sub-skill: fahrrad
- "kfz-schutzbrief", "schutzbrief", "roadside", "schutzbriefversicherung" → sub-skill: kfz-schutzbrief
- "mietkaution", "rental deposit", "kaution", "mietkautionsversicherung" → sub-skill: mietkaution
- "doc", "pdf", "document", "reader", "dokument", "police", "unterlagen" → sub-skill: doc-reader
- "portfolio", "overview", "summary", "all policies", "alle versicherungen", "uebersicht" -> sub-skill: portfolio

If matched: set `sub_skill_type` to the matched value and proceed to Phase 1.

If not matched (no input or unrecognized type):
Use AskUserQuestion with singleSelect:
"Which insurance type would you like advice on?"
- Portfolio overview (all policies, gaps, overlaps, adequacy summary)
- Health insurance (Krankenversicherung — GKV vs PKV)
- Liability insurance (Haftpflichtversicherung — personal liability)
- Household contents insurance (Hausratversicherung — contents protection)
- Car insurance (Kfz-Versicherung — liability, partial or comprehensive)
- Legal protection insurance (Rechtsschutzversicherung — legal cost coverage)
- Dental supplemental insurance (Zahnzusatzversicherung — dental top-up)
- Term life insurance (Risikolebensversicherung — death benefit for dependents)
- Travel insurance (Reiseversicherung — health, cancellation, luggage)
- Bicycle insurance (Fahrradversicherung — theft and damage)
- Roadside assistance (Kfz-Schutzbriefversicherung — breakdown and towing)
- Rental deposit insurance (Mietkautionsversicherung — deposit replacement)
- Document reader (parse PDF policy documents into your profile)

Map the answer:
- "Portfolio overview (all policies, gaps, overlaps, adequacy summary)" -> sub_skill_type = "portfolio"
- "Health insurance (Krankenversicherung — GKV vs PKV)" → sub_skill_type = "health"
- "Liability insurance (Haftpflichtversicherung — personal liability)" → sub_skill_type = "haftpflicht"
- "Household contents insurance (Hausratversicherung — contents protection)" → sub_skill_type = "hausrat"
- "Car insurance (Kfz-Versicherung — liability, partial or comprehensive)" → sub_skill_type = "kfz"
- "Legal protection insurance (Rechtsschutzversicherung — legal cost coverage)" → sub_skill_type = "rechtsschutz"
- "Dental supplemental insurance (Zahnzusatzversicherung — dental top-up)" → sub_skill_type = "zahnzusatz"
- "Term life insurance (Risikolebensversicherung — death benefit for dependents)" → sub_skill_type = "risikoleben"
- "Travel insurance (Reiseversicherung — health, cancellation, luggage)" → sub_skill_type = "reise"
- "Bicycle insurance (Fahrradversicherung — theft and damage)" → sub_skill_type = "fahrrad"
- "Roadside assistance (Kfz-Schutzbriefversicherung — breakdown and towing)" → sub_skill_type = "kfz-schutzbrief"
- "Rental deposit insurance (Mietkautionsversicherung — deposit replacement)" → sub_skill_type = "mietkaution"
- "Document reader (parse PDF policy documents into your profile)" → sub_skill_type = "doc-reader"

## Phase 1: Sub-skill Dispatch

Read `${CLAUDE_SKILL_DIR}/sub-skills/${sub_skill_type}.md`.
<!-- Examples: health.md, haftpflicht.md, hausrat.md, kfz.md, rechtsschutz.md, zahnzusatz.md, risikoleben.md, reise.md, fahrrad.md, kfz-schutzbrief.md, mietkaution.md, portfolio.md, doc-reader.md -->

Follow all instructions in the loaded file from its Phase 0 onward.

</process>

<error_handling>

**Unknown insurance type (sub-skill file not found):**
```
ERROR: No sub-skill found for type "[sub_skill_type]".
Currently available insurance types:
  - health          (Krankenversicherung — GKV vs PKV)
  - haftpflicht     (Haftpflichtversicherung — personal liability)
  - hausrat         (Hausratversicherung — household contents)
  - kfz             (Kfz-Versicherung — car insurance)
  - rechtsschutz    (Rechtsschutzversicherung — legal protection)
  - zahnzusatz      (Zahnzusatzversicherung — dental supplement)
  - risikoleben     (Risikolebensversicherung — term life)
  - reise           (Reiseversicherung — travel insurance)
  - fahrrad         (Fahrradversicherung — bicycle insurance)
  - kfz-schutzbrief (Kfz-Schutzbriefversicherung — roadside assistance)
  - mietkaution     (Mietkautionsversicherung — rental deposit)
  - portfolio        (Portfolio -- all policies, gaps, overlaps, cost summary)
  - doc-reader    (Document reader -- parse PDF policy documents)

Run /finyx:insurance [type]  (or use the type selection menu)
```

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile, then retry.
```

</error_handling>

<notes>

## Router Scope

This SKILL.md is a pure dispatcher — it contains NO insurance-type-specific logic. All advisory content lives in sub-skill files under `${CLAUDE_SKILL_DIR}/sub-skills/`.

## Tool Permissions

The `allowed-tools` list is the union of all tools required by any sub-skill. Tool permissions are set at skill load time (YAML frontmatter), so the router must declare every tool any sub-skill may use. Current sub-skill tool requirements:
- health.md: Read, Bash, Write, Task, AskUserQuestion, WebSearch, WebFetch
- portfolio.md: Read, Task, AskUserQuestion, Write

Sub-skills for other types will be added in Phases 21-22. When adding new sub-skills in future phases, verify their tool requirements and expand `allowed-tools` if needed.

## Sub-skill File Contract

Sub-skill files (e.g., `sub-skills/health.md`) must:
- Be plain Markdown — NO YAML frontmatter (sub-skills are not registered commands)
- NOT include an `<execution_context>` block (the router's execution_context already loads disclaimer.md and profile.json)
- Start with a `# [Type] Insurance Sub-skill` heading
- Contain their own `<objective>`, `<process>`, `<error_handling>`, and `<notes>` sections
- Use `${CLAUDE_SKILL_DIR}` for all reference and agent path references (resolves to `skills/insurance/`)

</notes>
