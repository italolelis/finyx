# Phase 22: Per-Type Sub-skills (Tier 3-4) + Doc Reader - Research

**Researched:** 2026-04-12
**Domain:** Claude Code slash-command Markdown sub-skills + document location profile schema
**Confidence:** HIGH

## Summary

Phase 22 creates 4 new insurance sub-skill Markdown files (reise, fahrrad, kfz-schutzbrief, mietkaution) and a doc-reader sub-skill that orchestrates batch PDF extraction and saves results to `insurance.policies[]`. All 4 type sub-skills follow the identical 7-phase structure established in Phase 21. The doc reader introduces a new `documents.locations` section in `profile.json` and wraps the existing `finyx-insurance-doc-reader-agent` with folder-scan, auto-type-detection, and batch-confirmation logic.

All reference docs for the 4 new types already exist (reise.md, fahrrad.md, kfz-schutzbrief.md, mietkaution.md) with Field Extraction Schemas and Keyword Maps. The `finyx-insurance-doc-reader-agent` already exists and already enumerates all 4 new type slugs as valid types. The router SKILL.md already has keyword mappings for all 4 types and "doc/pdf/document" routing must be added. The profile schema (`profile.json`) does not yet have a `documents.locations` section — that is the only schema extension needed.

**Primary recommendation:** Create 5 files: 4 type sub-skills + 1 doc-reader sub-skill. Extend `profile.json` with `documents.locations`. No agent edits, no router logic changes beyond adding a "doc reader" dispatch keyword.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Tier 3-4 Sub-skill Approach**
- All 4 sub-skills follow the same 7-phase pattern as Tier 1-2 for consistency
- Mietkaution uses rent-based benchmark (3x Kaltmiete per section 551 BGB) — same structure, different benchmark source
- Kfz-Schutzbrief cross-references user's Kfz policy to check for included Schutzbrief coverage (overlap detection)

**Document Reader Sub-skill**
- User configures document locations in their profile (e.g., insurance_docs: "/path/to/insurance/folder") — profile stores per-category document paths (insurance, bank statements, real estate, investments, etc.)
- When user runs doc reader, it checks profile for configured document location first. If not configured, asks user where docs are and saves location to profile for future use
- Extracted data written to insurance.policies[] automatically with user confirmation via AskUserQuestion before saving
- Scanned/image PDFs detected and shown clear error: "This PDF appears to be a scanned image. Please use a text-based PDF or enter policy details manually via /finyx:insurance portfolio"
- Insurance type auto-detected by matching extracted terms against reference doc keywords
- The doc reader should be able to scan a folder of PDFs, not just single files — process each PDF found and present results for batch confirmation

**Profile Document Locations**
- New profile section: documents.locations with per-category paths (insurance, banking, investments, real_estate, etc.)
- Each location can be any path (local folder, NAS mount, etc.)
- Skills can reference their category's document location from the profile
- This is a new convention — document it in the profile schema for other skills to adopt

### Claude's Discretion
- Exact field mapping logic for auto-type detection
- How to present batch extraction results (table vs sequential)
- Error handling for partially parseable PDFs
- Whether to show extraction confidence scores

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TYPE-07 | Reiseversicherung (travel) sub-skill | reise.md reference doc exists with benchmarks, Field Extraction Schema, and Keyword Map. Coverage type: service-based (coverage_amount = null). Key benchmark: Auslandskrankenversicherung + Krankenrucktransport included, per-trip duration cap ≥42 days. |
| TYPE-08 | Fahrradversicherung (bicycle) sub-skill | fahrrad.md reference doc exists. Coverage type: sum-based (Neuwert in EUR). Key benchmark: Neuwertentschadigung required, e-bike specific coverage fields if applicable. Hausrat add-on overlap detection needed. |
| TYPE-09 | Kfz-Schutzbriefversicherung (roadside assistance) sub-skill | kfz-schutzbrief.md reference doc exists. Coverage type: service-based (coverage_amount = null). Key benchmark: EU-wide Pannenhilfe, 24/7 hotline. ADAC / Kfz-policy overlap detection is the defining feature of this sub-skill. |
| TYPE-10 | Mietkautionsversicherung (rental deposit) sub-skill | mietkaution.md reference doc exists. Coverage type: sum-based (guaranteed deposit amount). Benchmark is derived: coverage_amount should equal user's Nettokaltmiete × 3 (§551 BGB). Regresspflicht warning is mandatory per reference doc. |
| OPT-02 | Policy document PDF parsing into insurance.policies[] | finyx-insurance-doc-reader-agent already exists and supports all 4 new types. Doc reader sub-skill must: check profile for documents.locations.insurance path, ask + save if not configured, list PDFs in folder, spawn agent per PDF, present batch confirmation, write confirmed records to profile.json. |
</phase_requirements>

## Standard Stack

This project has no library dependencies. All implementation is Markdown prompt files. The "stack" is the established sub-skill authoring conventions.

### Core Conventions
| Component | Pattern | Source |
|-----------|---------|--------|
| Sub-skill file | Plain Markdown, no YAML frontmatter, no `<execution_context>` block | SKILL.md contract + existing files |
| Sub-skill location | `skills/insurance/sub-skills/{type}.md` | Established pattern |
| 7-phase structure | Phase 0 Preferences → 1 Validation → 2 Disclaimer → 3 Benchmark → 4 Cancellation → 5 Research Agent → 6 Recommendation | haftpflicht.md, hausrat.md, kfz.md |
| Reference doc access | `Read ${CLAUDE_SKILL_DIR}/references/germany/{type}.md` in Phase 3 at runtime | haftpflicht.md notes |
| Research agent spawn | Task tool with `<insurance_research_result>` XML tags | All Tier 1-2 sub-skills |
| No write | Type sub-skills are read-only advisory | haftpflicht.md notes |
| Profile path | `.finyx/profile.json` | All sub-skills |
| Profile pre-loaded | Router already loads profile.json via execution_context — sub-skills read it, don't re-load | SKILL.md execution_context |

### Supporting Agents (pre-existing, no changes needed)
| Agent | File | Purpose |
|-------|------|---------|
| finyx-insurance-research-agent | skills/insurance/agents/ | Market research per type — already parameterized |
| finyx-insurance-doc-reader-agent | skills/insurance/agents/finyx-insurance-doc-reader-agent.md | PDF extraction — already supports all 4 new slugs |

### Profile Schema Extension (new)
One new section added to `profile.json`:

```json
"_documents_schema": {
  "description": "Per-category document location paths. Used by skills to locate source documents for extraction.",
  "path_format": "Absolute path or path relative to user's home. Accepts local folder or NAS mount.",
  "categories": "insurance, banking, investments, real_estate — extensible for future skills"
},
"documents": {
  "locations": {
    "insurance": null,
    "banking": null,
    "investments": null,
    "real_estate": null
  }
}
```

## Architecture Patterns

### Recommended File Structure (new files only)

```
skills/insurance/sub-skills/
├── reise.md              # TYPE-07 — service-based, bundle components
├── fahrrad.md            # TYPE-08 — sum-based, Neuwert, e-bike check
├── kfz-schutzbrief.md    # TYPE-09 — service-based, ADAC overlap detection
├── mietkaution.md        # TYPE-10 — sum-based, §551 BGB rent benchmark
└── doc-reader.md         # OPT-02 — batch PDF extraction orchestrator

skills/profile/references/
└── profile.json          # EXTEND: add documents.locations section
```

Router SKILL.md: add "doc", "pdf", "document", "reader", "dokument" → sub_skill_type = "doc-reader" to the keyword map and Phase 1 dispatch comment.

### Pattern 1: Tier 3-4 Sub-skill (reise, fahrrad, kfz-schutzbrief, mietkaution)

Follow the identical 7-phase structure from haftpflicht.md. Key per-type variations:

**Reise (TYPE-07):**
- Phase 0: Ask annual vs single-trip policy, countries visited, Jahreskarte vs Einmalreise
- Phase 3: Service-based — no sum benchmark. Check component presence: Auslandskrankenversicherung, Krankenrucktransport, Reiserucktritt. Critical check: per-trip duration limit field. Flag GKV gap warning unconditionally.
- Phase 4: Standard cancellation tracking. Note: single-trip policies are non-cancellable — skip if policy is Einmalreise.

**Fahrrad (TYPE-08):**
- Phase 0: Ask bike value (EUR), whether e-bike, whether has Hausrat Fahrrad-Zusatz
- Phase 3: Sum-based. Benchmark: coverage_amount should equal bike replacement value (Neuwert). Check Neuwertentschadigung in coverage_components. If e-bike: check Akkuschaden and Elektronikschaden. Hausrat overlap check: if user has hausrat policy with Fahrrad-Zusatz in coverage_components, flag potential redundancy.
- Phase 3: Standard Selbstbeteiligung INFO row.

**Kfz-Schutzbrief (TYPE-09):**
- Phase 0: Ask if user has ADAC membership, ask if user's Kfz policy has Schutzbrief add-on
- Phase 3: Service-based — no sum. Check component presence: Pannenhilfe, geographic scope (inland vs EU-wide), Abschleppen, Mietwagen, 24/7 Hotline. Cross-reference Kfz policy: read the kfz entry from insurance.policies[] — check its coverage_components for "Schutzbrief" or equivalent. If found: flag overlap. If user has ADAC (from Phase 0): flag redundancy.
- Phase 6: Overlap detection is the primary value — lead with it.

**Mietkaution (TYPE-10):**
- Phase 0: Ask Nettokaltmiete (monthly net cold rent), whether landlord has accepted guarantee
- Phase 3: Sum-based. Benchmark is computed: `recommended_coverage = nettokaltmiete * 3`. Compare coverage_amount against this computed value. Note: §551 BGB cap means coverage_amount should never exceed 3× Nettokaltmiete.
- Phase 3: Always include Regresspflicht warning — this is mandatory per mietkaution.md reference.
- Phase 4: Add note that policy must NOT be cancelled before tenancy ends without landlord's written release.

### Pattern 2: Doc Reader Sub-skill (OPT-02)

The doc-reader sub-skill is an orchestrator — it does NOT do extraction itself. It coordinates:
1. Profile path resolution
2. Folder scanning
3. Type detection per PDF
4. Agent spawning (one Task per PDF)
5. Batch confirmation
6. Profile write

**7-phase structure for doc-reader.md:**

- **Phase 0: Document Location Resolution**
  - Read `documents.locations.insurance` from profile.json
  - If `null` or absent: use AskUserQuestion (text input) to get folder path, then write it to profile.json using Write tool with user confirmation
  - Set `docs_folder` to the resolved path

- **Phase 1: Folder Scan**
  - Run: `ls "{docs_folder}"/*.pdf 2>/dev/null` (Bash tool)
  - If zero PDFs found: emit error and stop
  - Present the file list to user, let them confirm which to process (AskUserQuestion multiSelect or confirm-all)

- **Phase 2: Disclaimer**
  - Standard FINYX banner + disclaimer.md content
  - Add: "Extracted data will be reviewed before saving. Nothing is written without your confirmation."

- **Phase 3: Type Auto-detection + Agent Spawn (per PDF)**
  - For each selected PDF:
    - Attempt to detect insurance_type from filename (check for slug keywords: "haftpflicht", "hausrat", "reise", "fahrrad", "kfz", "rechtsschutz", "zahnzusatz", "risikoleben", "mietkaution", "schutzbrief")
    - If not detectable from filename: spawn doc-reader-agent with insurance_type = "auto-detect" hint or ask user to confirm type
    - Spawn `finyx-insurance-doc-reader-agent` via Task with: `doc_path = {pdf_path}`, `insurance_type = {detected_type}`
    - Collect `<doc_reader_result>` output per PDF

- **Phase 4: Batch Review**
  - Present extraction results as a summary table:
    | File | Type | Provider | Coverage | Premium/mo | Confidence | Action |
    |------|------|----------|----------|------------|------------|--------|
    | ... | ... | ... | ... | ... | ... | Save / Skip |
  - Use AskUserQuestion (multiSelect) to let user choose which extractions to save

- **Phase 5: Profile Write**
  - For each confirmed extraction:
    - Check `insurance.policies[]` for existing entry with same `type` + `provider`
    - If exists: present "Update existing entry?" confirmation
    - Write the JSON policy object to `insurance.policies[]` using Write tool
  - Confirm count: "Saved {N} policies to your profile."

- **Phase 6: Summary**
  - List saved policies with key fields
  - Note any skipped or failed extractions
  - Suggest: "Run `/finyx:insurance portfolio` to see your updated coverage overview."

### Pattern 3: Auto-type Detection Logic (Claude's Discretion)

Detection order (filename → content keyword match):

1. **Filename match:** Check if PDF filename contains known slug. Case-insensitive substring match against: haftpflicht, hausrat, kfz, rechtsschutz, zahnzusatz, risikoleben, reise, fahrrad, schutzbrief, mietkaution, health, kranken
2. **Ask user if filename match fails:** AskUserQuestion singleSelect with the 11 type options — do not attempt content-based detection before agent spawn (the agent reads the content)
3. **Confidence display:** Show the per-field confidence table from `<doc_reader_result>`. Do NOT show a numeric score — use the existing HIGH/MEDIUM/LOW/NOT FOUND flags from the agent output format.

### Pattern 4: Batch Presentation (Claude's Discretion)

Use a summary table (not sequential cards) for the batch review — easier to scan multiple results at once. Show one row per PDF. Inline LOW CONFIDENCE fields with a warning icon indicator (text symbol `[!]` inline in the cell). Detailed field-level confidence shown as expandable note under the table, not inline.

### Pattern 5: Partially Parseable PDFs (Claude's Discretion)

If overall confidence = LOW (most fields are NOT FOUND or LOW): present as a separate "needs review" group in the batch table. Still offer Save option but with explicit warning: "[!] Low confidence extraction — verify all fields before relying on this data."

### Anti-Patterns to Avoid

- **Hardcoding benchmarks in sub-skill:** Always read from reference doc at runtime in Phase 3. Never hardcode €5M or trip day limits in the sub-skill Markdown.
- **Sub-skill with YAML frontmatter:** Sub-skills are plain Markdown. No `---` frontmatter block.
- **Sub-skill with execution_context block:** Router handles loading. Sub-skills must NOT add their own `<execution_context>` block.
- **Doc reader writing without confirmation:** Every Write call must be preceded by AskUserQuestion confirmation. No silent writes.
- **Kfz-Schutzbrief creating duplicate entry:** If the user's Kfz policy already includes Schutzbrief, the sub-skill should flag this overlap in Phase 3 without recommending a separate policy purchase.
- **Mietkaution sub-skill omitting Regresspflicht warning:** This is mandatory — the reference doc emphasizes it as "Critical." Always include it in Phase 3 or Phase 6.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| PDF text extraction | Custom parser | `finyx-insurance-doc-reader-agent` (already exists, already handles all 4 new types) |
| Insurance type validation | Custom type checker | Agent's built-in valid-types list (already includes reise, fahrrad, kfz-schutzbrief, mietkaution) |
| Coverage benchmarks | Hardcoded values in sub-skill | Read from reference doc at runtime (`${CLAUDE_SKILL_DIR}/references/germany/{type}.md`) |
| §551 BGB Mietkaution cap | Embedded legal rule | mietkaution.md reference doc already documents this |

## Common Pitfalls

### Pitfall 1: Kfz-Schutzbrief Overlap Check Requires Kfz Policy to Exist

**What goes wrong:** Phase 3 of kfz-schutzbrief.md tries to read kfz entry from insurance.policies[] but no kfz policy is in profile. Code crashes or produces confusing output.

**Why it happens:** Overlap check assumes the user has a Kfz policy.

**How to avoid:** Guard the Kfz policy lookup: if no kfz entry in policies[], emit: "No Kfz policy found in your profile — cannot check for included Schutzbrief coverage. Add your Kfz policy via `/finyx:insurance portfolio` to enable overlap detection."

**Warning signs:** Phase 3 exits prematurely or emits a null-pointer-style message.

### Pitfall 2: Mietkaution Benchmark Needs User's Nettokaltmiete

**What goes wrong:** Phase 3 tries to compute `3 × nettokaltmiete` but the value was not collected in Phase 0 or is not in the profile.

**Why it happens:** Unlike Hausrat (which has a fallback path through profile fields), Nettokaltmiete is not a standard profile field.

**How to avoid:** In Phase 0, make Nettokaltmiete a required question for Mietkaution (not optional). If user skips or enters 0: skip the benchmark comparison and note "Nettokaltmiete not provided — cannot compute §551 BGB benchmark."

### Pitfall 3: Doc Reader — Empty Folder or No Text-layer PDFs

**What goes wrong:** User configures a folder path that exists but contains no PDFs, or all PDFs are scanned images.

**Why it happens:** The sub-skill lists files but gets zero results, or agents return image-only errors for all files.

**How to avoid:** After folder scan, if zero PDFs: emit clear error with path. After agent spawns, if all results are image-only errors: aggregate and present a single "No text-layer PDFs found" message rather than repeating the error per file.

### Pitfall 4: Reise Single-trip Policy — Cancellation Logic

**What goes wrong:** Phase 4 attempts to compute cancellation deadline for a single-trip (Einmalreise) policy, which is non-cancellable after issuance.

**Why it happens:** The 7-phase template has Phase 4 always compute deadlines.

**How to avoid:** In Phase 1, detect policy type from `notes` or `coverage_components` — look for "Einmalreise" keyword. If detected: skip Phase 4 with note "Single-trip policies are non-cancellable once issued — cancellation tracking is not applicable."

### Pitfall 5: Router Keyword Missing for "doc" / "pdf" / "document"

**What goes wrong:** User types `/finyx:insurance doc` or `/finyx:insurance pdf` and gets "Unknown type" error because the router does not yet have these keywords mapped to "doc-reader".

**Why it happens:** Router was written before the doc-reader sub-skill existed. SKILL.md has a comment noting that sub-skills for Phase 22 will be added.

**How to avoid:** Add keyword entries to SKILL.md Phase 0 keyword map as part of this phase. Also add "doc-reader" to the AskUserQuestion type selection menu.

### Pitfall 6: documents.locations Written as Partial Update

**What goes wrong:** Doc reader writes only `documents.locations.insurance` to profile.json but overwrites adjacent fields or corrupts the JSON structure.

**Why it happens:** Write tool replaces the entire file — partial JSON edits require reading, updating in memory, then writing the full file.

**How to avoid:** In Phase 0, when saving the resolved folder path: Read profile.json first, update `documents.locations.insurance` in the in-memory object, write back the full JSON. This is the same pattern used by the portfolio sub-skill.

## Code Examples

### Reise — Phase 0 Questions Pattern

```markdown
## Phase 0: Preferences

Use AskUserQuestion to collect preferences before loading profile data.

**Question 1 — Policy scope (singleSelect):**
"Do you have an annual travel policy (Jahreskarte) or single-trip coverage (Einmalreise)?"
- Annual policy (Jahreskarte) — covers multiple trips per year
- Single-trip policy (Einmalreise) — covers one specific trip
- Not sure / no policy yet

**Question 2 — Travel region (singleSelect):**
"Where do you primarily travel?"
- Within Europe (EU/EEA)
- Worldwide including long-haul
- Both, depending on trip

Store results as `user_preferences`: { policy_scope, travel_region }
```

### Fahrrad — E-bike Detection Branch in Phase 3

```markdown
## Phase 3: Coverage Benchmark Comparison

Read ${CLAUDE_SKILL_DIR}/references/germany/fahrrad.md — Coverage Benchmarks section.

If e-bike == true (from Phase 0):
  Check coverage_components for: "Akkuschaden", "Elektronikschaden" (or German equivalents from Keyword Map)
  - Akkuschaden: PASS if found / FAIL if absent
  - Elektronikschaden: PASS if found / FAIL if absent
  - Add note: "E-bike battery replacement cost is €500–2,000. Akkuschaden coverage is critical."

If e-bike == false:
  Skip e-bike specific rows.
```

### Kfz-Schutzbrief — Kfz Policy Overlap Check Pattern

```markdown
## Phase 3: Coverage Benchmark Comparison

Read ${CLAUDE_SKILL_DIR}/references/germany/kfz-schutzbrief.md — Coverage Benchmarks section.

**Overlap check — Kfz policy:**
Find entry in insurance.policies[] where type == "kfz".
If found:
  Check kfz.coverage_components for: "Schutzbrief", "Pannenhilfe", "Abschleppen", "ADAC-Schutzbrief"
  If found: emit OVERLAP warning:
  "Your Kfz policy ({provider}) appears to include breakdown assistance coverage.
   A standalone Kfz-Schutzbrief policy may be redundant.
   Verify with your Kfz insurer before purchasing additional coverage."
If not found: proceed with standard benchmark table.

**ADAC check (from Phase 0):**
If user confirmed ADAC membership:
  Emit: "ADAC Vollmitgliedschaft provides equivalent or superior breakdown coverage for all
   vehicles you drive — not just owned vehicles. A standalone Schutzbrief policy is likely
   redundant. Consider cancelling at next Kündigungsfrist."
```

### Mietkaution — §551 BGB Benchmark Computation

```markdown
## Phase 3: Coverage Benchmark Comparison

Read ${CLAUDE_SKILL_DIR}/references/germany/mietkaution.md — Coverage Benchmarks section.

Compute benchmark:
  recommended_deposit = nettokaltmiete_monthly * 3   (from Phase 0 user input)

Build comparison:
| Criterion | Your Coverage | Benchmark | Status |
|-----------|--------------|-----------|--------|
| Guarantee amount | €{coverage_amount} | €{recommended_deposit} (3× Kaltmiete) | PASS if coverage_amount >= recommended_deposit |
| Max legal cap (§551 BGB) | — | €{recommended_deposit} | INFO |
| Premium rate | {premium_annual / coverage_amount * 100}% | 3–5% | PASS/WARN |

Always emit Regresspflicht warning:
"IMPORTANT: Mietkautionsversicherung is not a subsidy. If your landlord files a claim and the
 insurer pays, the insurer has full right of recourse (Regresspflicht) to recover the full amount
 from you. This product replaces upfront cash only — it does not eliminate your deposit obligation."
```

### Doc Reader — Phase 0 Location Resolution Pattern

```markdown
## Phase 0: Document Location Resolution

Read .finyx/profile.json. Check documents.locations.insurance.

If documents.locations.insurance is not null:
  Set docs_folder = documents.locations.insurance
  Emit: "Using configured insurance document folder: {docs_folder}"

If documents.locations.insurance is null (or documents.locations section absent):
  Use AskUserQuestion (text input):
  "Where are your insurance policy documents stored?
   Enter the folder path (e.g., /Users/you/Documents/insurance or ~/Dropbox/Versicherungen).
   This path will be saved to your profile for future use."

  Set docs_folder = [user input]

  Confirm with AskUserQuestion (singleSelect):
  "Save '{docs_folder}' as your insurance document folder in your profile?"
  - Yes, save for future use
  - No, use for this session only

  If "Yes": Read profile.json, update documents.locations.insurance = docs_folder, write full JSON back.
```

### Doc Reader — Batch Confirmation Table Format

```markdown
## Phase 4: Batch Review

Present extraction results:

| # | File | Type | Provider | Coverage | Premium/mo | Confidence | Save? |
|---|------|------|----------|----------|------------|------------|-------|
| 1 | huk-haftpflicht.pdf | haftpflicht | HUK-COBURG | €5,000,000 | €8.50 | HIGH | ✓ |
| 2 | reise-2024.pdf | reise | ERGO | Service-based | €12.00 | MEDIUM [!] | ✓ |
| 3 | scan-old.pdf | unknown | [NOT FOUND] | — | — | LOW [!] | — |

[!] = one or more fields are LOW CONFIDENCE or NOT FOUND — review before saving.

Use AskUserQuestion (multiSelect): "Which extractions would you like to save to your profile?"
```

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|-----------------|-------|
| Per-type sub-skill created per phase | All 4 Tier 3-4 types created in single phase | Established in Phase 21 — consistent |
| Doc reading: manual profile entry via portfolio sub-skill | Automated PDF extraction via doc-reader sub-skill | OPT-02 completes this |
| No document location convention | documents.locations profile section | New convention for all future skills |

## Open Questions

1. **Router keyword for doc-reader**
   - What we know: Router SKILL.md has a comment "Sub-skills for other types will be added in Phases 21-22" but no doc-reader keyword yet. The router's AskUserQuestion menu also does not include a "Document reader" option.
   - What's unclear: The router comment says "verify tool requirements and expand allowed-tools if needed" — doc-reader.md uses Write tool (already in allowed-tools list).
   - Recommendation: Add "doc", "pdf", "document", "dokument", "reader" → sub_skill_type = "doc-reader" to router Phase 0 keyword map. Add "Document reader (parse PDF policy documents)" to AskUserQuestion menu. No allowed-tools changes needed.

2. **profile.json schema location**
   - What we know: `skills/profile/references/profile.json` is the canonical schema template. The actual user profile is at `.finyx/profile.json`.
   - What's unclear: Should the planner update both? The template in `skills/profile/references/profile.json` drives what `/finyx:profile` creates for new users.
   - Recommendation: Update `skills/profile/references/profile.json` template to include `documents.locations`. Existing user profiles at `.finyx/profile.json` will be updated by the doc-reader sub-skill on first use (when it saves the path).

3. **doc-reader sub-skill filename**
   - What we know: Router dispatches `sub-skills/${sub_skill_type}.md`. If type is "doc-reader", file must be `skills/insurance/sub-skills/doc-reader.md`.
   - Recommendation: Use `doc-reader.md` — consistent with the hyphenated slug convention (kfz-schutzbrief.md).

## Environment Availability

Step 2.6: SKIPPED — phase creates Markdown files and JSON schema only. No external tool dependencies beyond the existing Claude Code runtime.

## Validation Architecture

nyquist_validation is explicitly `false` in `.planning/config.json` — section omitted.

## Sources

### Primary (HIGH confidence)
- Direct file reads: `skills/insurance/sub-skills/haftpflicht.md` — verified 7-phase structure
- Direct file reads: `skills/insurance/agents/finyx-insurance-doc-reader-agent.md` — verified valid types list, input/output format
- Direct file reads: `skills/insurance/references/germany/reise.md`, `fahrrad.md`, `kfz-schutzbrief.md`, `mietkaution.md` — all Field Extraction Schemas and benchmarks verified
- Direct file reads: `skills/insurance/SKILL.md` — verified router keyword map (all 4 types already present, doc-reader not yet)
- Direct file reads: `skills/profile/references/profile.json` — verified no documents.locations section exists yet

### Secondary (MEDIUM confidence)
- `.planning/phases/22-per-type-sub-skills-tier-3-4-doc-reader/22-CONTEXT.md` — user decisions
- `.planning/REQUIREMENTS.md` — requirement IDs and descriptions
- `.planning/STATE.md` — accumulated decisions from prior phases

## Metadata

**Confidence breakdown:**
- Sub-skill structure: HIGH — read existing Tier 1-2 sub-skills directly, pattern is explicit
- Reference doc content: HIGH — all 4 reference docs exist and were read directly
- Doc reader agent interface: HIGH — read agent file directly, verified input params and output format
- Router integration: HIGH — read SKILL.md directly, gap (doc-reader keyword) identified explicitly
- Profile schema extension: HIGH — read profile.json directly, documents.locations section confirmed absent

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (stable Markdown-only codebase, no external dependency changes)
