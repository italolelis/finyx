# Insurance Document Reader Sub-skill

<!-- Sub-skill loaded by router SKILL.md. All CLAUDE_SKILL_DIR paths resolve to skills/insurance/ -->
<!-- TODO: migrate to $PROFILE_PATH from scripts/resolve-profile.sh in a follow-up iteration. -->

<objective>

Parse insurance policy PDFs from a configured folder, extract structured data via the doc-reader agent, present batch results for confirmation, and save confirmed extractions to insurance.policies[]. Uses Write tool — requires user confirmation before every write.

This is an ORCHESTRATOR sub-skill — it does NOT extract PDF content itself. It coordinates folder scanning, agent spawning, batch review, and profile writing.

</objective>

<process>

## Phase 0: Document Location Resolution

Read `.finyx/profile.json`. Check `documents.locations.insurance`.

If `documents.locations.insurance` is not null and not an empty string:
- Set `docs_folder` to the value
- Emit: "Using configured insurance document folder: {docs_folder}"

If `documents.locations.insurance` is null OR the `documents` section is absent:
- Use AskUserQuestion (text input): "Where are your insurance policy documents stored? Enter the folder path (e.g., /Users/you/Documents/insurance or ~/Dropbox/Versicherungen). This path will be saved to your profile for future use."
- Set `docs_folder` to user input
- Use AskUserQuestion (singleSelect): "Save '{docs_folder}' as your insurance document folder in your profile?" with options:
  - "Yes, save for future use"
  - "No, use for this session only"
- If "Yes, save for future use":
  1. Read `.finyx/profile.json` in full
  2. Update `documents.locations.insurance = docs_folder` (create the `documents.locations` section if absent)
  3. Write the FULL updated JSON back using Write tool
  4. Emit: "Saved document folder to your profile."



## Phase 1: Folder Scan

Run via Bash tool:
```bash
ls "{docs_folder}"/*.pdf 2>/dev/null
```

If zero PDFs found: emit the following error and STOP:
```
No PDF files found in {docs_folder}.
Ensure the folder contains .pdf files and the path is correct.
```

Present found files as a numbered list.

Use AskUserQuestion (multiSelect): "Which PDF files would you like to process?" — list all found PDF filenames plus a "Process all" option.

If user selects "Process all": set `selected_files` to the full list of found PDFs.
Otherwise: set `selected_files` to the user's selection.



## Phase 2: Disclaimer

Emit header banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► INSURANCE ► DOCUMENT READER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Emit the full legal disclaimer from the loaded `disclaimer.md` (loaded by router).

Then append:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 DOCUMENT READER NOTICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Extracted data will be reviewed before saving.
Nothing is written to your profile without your explicit confirmation.

This reader requires text-layer PDFs. Scanned/image-only PDFs
cannot be processed — enter those policies manually via
/finyx:insurance portfolio.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```



## Phase 3: Type Auto-detection + Agent Spawn (per PDF)

Initialize:
- `extraction_results = []` — successful extractions
- `failed_extractions = []` — files that could not be processed

For each file in `selected_files`:

### 3.1 Filename-based type detection

Check if the filename (lowercased) contains any known type slug via substring match:

| Filename substring | Maps to insurance_type |
|--------------------|------------------------|
| haftpflicht | haftpflicht |
| hausrat | hausrat |
| kfz-schutzbrief OR schutzbrief | kfz-schutzbrief |
| kfz | kfz |
| rechtsschutz | rechtsschutz |
| zahnzusatz | zahnzusatz |
| risikoleben | risikoleben |
| reise | reise |
| fahrrad | fahrrad |
| mietkaution | mietkaution |
| kranken OR health | health |

If multiple slugs match: use the longest matching slug (e.g., "kfz-schutzbrief" takes precedence over "kfz").

### 3.2 Manual type selection (if filename detection fails)

If no slug matched: use AskUserQuestion (singleSelect) for THIS file:
"What type of insurance document is '{filename}'?"
- Health insurance (health)
- Personal liability (haftpflicht)
- Household contents (hausrat)
- Car insurance (kfz)
- Legal protection (rechtsschutz)
- Dental supplement (zahnzusatz)
- Term life insurance (risikoleben)
- Travel insurance (reise)
- Bicycle insurance (fahrrad)
- Roadside assistance (kfz-schutzbrief)
- Rental deposit insurance (mietkaution)
- Skip this file

If "Skip this file": add to `failed_extractions` with reason "Skipped by user" and continue to next file.

### 3.3 Spawn doc-reader agent

Use Task tool to spawn `finyx-insurance-doc-reader-agent` with:
```
You are the finyx-insurance-doc-reader-agent. Extract structured policy data from the provided document.

doc_path: {full_path_to_pdf}
insurance_type: {detected_or_selected_type}

Return your output wrapped in <doc_reader_result> tags.
```

### 3.4 Collect result

Parse the `<doc_reader_result>` tag from the agent's output.

If agent returns an error message (scanned image, unreadable file, unknown type) OR does not return `<doc_reader_result>`:
- Add to `failed_extractions`: `{ file: filename, error: [agent error message] }`
- Continue to next file.

If `<doc_reader_result>` is present:
- Add to `extraction_results`: `{ file: filename, type: insurance_type, result: [parsed doc_reader_result content] }`



## Phase 4: Batch Review

Present all extraction results in a summary table:

```
## Extraction Results

| # | File | Type | Provider | Coverage | Premium/mo | Confidence |
|---|------|------|----------|----------|------------|------------|
| 1 | huk-haftpflicht.pdf | haftpflicht | HUK-COBURG | EUR 5,000,000 | EUR 8.50 | HIGH |
| 2 | reise-2024.pdf | reise | ERGO | Service-based | EUR 12.00 | MEDIUM [!] |
```

`[!]` = one or more fields in the extraction are LOW CONFIDENCE or NOT FOUND — review before saving.

**Failed Extractions section** (if any):

```
## Failed Extractions

| # | File | Reason |
|---|------|--------|
| 3 | scan-old.pdf | Scanned image — no text layer detected |
```

**Needs Review section** (if any extractions have LOW CONFIDENCE or NOT FOUND fields):

```
## Needs Review

The following extractions have low-confidence or missing fields. Verify all fields against your
original policy document before relying on this data.

[!] reise-2024.pdf — MEDIUM CONFIDENCE overall. Fields flagged: premium_monthly (converted from annual), coverage_amount (null — service-based).
```

Use AskUserQuestion (multiSelect): "Which extractions would you like to save to your profile?" — list only successful extractions (from `extraction_results`). Include file name + provider in each option for clarity.

Set `confirmed_extractions` to the user's selection.

If no extractions confirmed: emit "No policies saved. Run `/finyx:insurance doc` again to process more documents." and STOP.



## Phase 5: Profile Write

For each entry in `confirmed_extractions`:

1. **Re-read profile:** Read `.finyx/profile.json` in full (re-read before EACH write to avoid stale state)

2. **Duplicate check:** Check `insurance.policies[]` for an existing entry where both `type` AND `provider` match the new extraction (case-insensitive string comparison).

3. **If duplicate found:**
   Use AskUserQuestion (singleSelect): "An existing {type} policy from {provider} was found in your profile. Update it with the new extraction?"
   - "Yes, update existing entry"
   - "No, skip this policy"

   If "No, skip this policy": skip this entry and continue to next.

4. **Construct policy object:** Build the JSON policy object from the fields in the `<doc_reader_result>` extracted JSON block.

5. **Write to profile:**
   - If updating existing: replace the matching entry in `insurance.policies[]`
   - If new: append to `insurance.policies[]`
   - Write the FULL updated profile.json back using Write tool.

6. Emit confirmation for each saved policy: "Saved: {type} policy from {provider}."

After all writes: emit count: "Saved {N} policies to your profile."



## Phase 6: Summary

Emit summary of all actions:

**Saved policies:**
For each saved policy: list type, provider, coverage_amount or "Service-based", premium_monthly.

**Skipped / not confirmed:**
List any extractions that were not selected for saving.

**Failed extractions:**
List any files that could not be processed with error reasons.

Suggest next steps:
```
Run /finyx:insurance portfolio to see your updated coverage overview and gap analysis.
```

</process>

<error_handling>

**No profile found:**
```
ERROR: No financial profile found.
Run /finyx:profile first to complete your financial profile, then retry.
```

**Empty folder:**
```
No PDF files found in {docs_folder}.
Ensure the folder contains .pdf files and the path is correct.
```

**All files fail (scanned images):**
```
No text-layer PDFs could be processed in {docs_folder}.
The document reader requires text-based PDFs. Scanned/image PDFs cannot be processed.
Enter policy details manually via /finyx:insurance portfolio.
```

**Partial failure:**
Show successful extractions and failed extractions in separate groups (see Phase 4 output format). Continue with successful extractions — do not abort the entire batch if some files fail.

**Agent returns no <doc_reader_result>:**
Record as failed extraction with error: "Agent did not return extraction output. Re-run or enter policy details manually."

</error_handling>

<notes>

## Write Targets

This sub-skill WRITES to `.finyx/profile.json` (unlike type advisory sub-skills which are read-only).
Every Write call MUST be preceded by AskUserQuestion confirmation.
Full JSON read-update-write cycle on every write to avoid partial corruption.

## documents.locations Schema

The `documents.locations` object is defined in profile.json under the top-level `documents` key:
```json
"documents": {
  "locations": {
    "insurance": null,
    "banking": null,
    "investments": null,
    "real_estate": null
  }
}
```

If the `documents` section is absent from the profile (older profiles), create it with all four keys, setting only `insurance` to the user-provided path and leaving the others as `null`.

## Agent Contract

The doc-reader agent (`finyx-insurance-doc-reader-agent`) is stateless — it only reads documents and returns structured output. It never writes files. This sub-skill is the only writer.

The agent requires:
- `doc_path` — full path to the PDF file
- `insurance_type` — one of the 11 valid slugs

The agent returns output wrapped in `<doc_reader_result>` tags containing:
- A JSON policy object matching `insurance.policies[]` schema
- A Field Confidence table
- An Exclusions list
- An Overall Confidence level

## Type Detection Priority

Filename-based detection takes precedence. Manual type selection (AskUserQuestion) is only used when filename detection fails. When multiple substrings match, use the longest match to resolve ambiguity (e.g., a file named "kfz-schutzbrief-allianz.pdf" should match "kfz-schutzbrief", not "kfz").

## Scanned PDF Handling

Scanned/image PDF detection is handled by the doc-reader agent — it returns an error message when it detects a non-text PDF. This sub-skill surfaces that error in the Failed Extractions section and continues with remaining files.

## Profile Write Safety

- Always re-read `profile.json` immediately before each write (never cache between writes)
- Never write partial JSON — always write the full profile object
- Duplicate detection is case-insensitive on both `type` and `provider` fields

</notes>
