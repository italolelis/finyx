# Phase 22: Per-Type Sub-skills (Tier 3-4) + Doc Reader - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Create 4 per-type insurance sub-skills for situational/niche types (Reise, Fahrrad, Kfz-Schutzbrief, Mietkaution) and a document reader sub-skill that parses policy PDFs to extract structured data into the profile. The doc reader integrates with a document locations system in the user profile.

</domain>

<decisions>
## Implementation Decisions

### Tier 3-4 Sub-skill Approach
- All 4 sub-skills follow the same 7-phase pattern as Tier 1-2 for consistency
- Mietkaution uses rent-based benchmark (3x Kaltmiete per section 551 BGB) — same structure, different benchmark source
- Kfz-Schutzbrief cross-references user's Kfz policy to check for included Schutzbrief coverage (overlap detection)

### Document Reader Sub-skill
- User configures document locations in their profile (e.g., insurance_docs: "/path/to/insurance/folder") — profile stores per-category document paths (insurance, bank statements, real estate, investments, etc.)
- When user runs doc reader, it checks profile for configured document location first. If not configured, asks user where docs are and saves location to profile for future use
- Extracted data written to insurance.policies[] automatically with user confirmation via AskUserQuestion before saving
- Scanned/image PDFs detected and shown clear error: "This PDF appears to be a scanned image. Please use a text-based PDF or enter policy details manually via /finyx:insurance portfolio"
- Insurance type auto-detected by matching extracted terms against reference doc keywords
- The doc reader should be able to scan a folder of PDFs, not just single files — process each PDF found and present results for batch confirmation

### Profile Document Locations
- New profile section: documents.locations with per-category paths (insurance, banking, investments, real_estate, etc.)
- Each location can be any path (local folder, NAS mount, etc.)
- Skills can reference their category's document location from the profile
- This is a new convention — document it in the profile schema for other skills to adopt

### Claude's Discretion
- Exact field mapping logic for auto-type detection
- How to present batch extraction results (table vs sequential)
- Error handling for partially parseable PDFs
- Whether to show extraction confidence scores

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- skills/insurance/sub-skills/haftpflicht.md — simplest Tier 1 sub-skill as template
- skills/insurance/agents/finyx-insurance-doc-reader-agent.md — doc reader agent (from Phase 19)
- skills/insurance/references/germany/*.md — all 11 reference docs with Field Extraction Schemas
- skills/profile/references/profile.json — profile schema to extend with documents.locations

### Established Patterns
- Sub-skills: plain Markdown, no frontmatter, no execution_context
- Agent spawn via Task tool with structured XML output
- Write tool used only with user confirmation (portfolio sub-skill pattern)
- All reference docs have Field Extraction Schema sections

### Integration Points
- Router SKILL.md already has keywords for all 4 types + "doc"/"pdf"/"document" keywords needed
- Doc reader agent accepts doc_path + insurance_type parameters
- Portfolio sub-skill reads insurance.policies[] — extracted data feeds directly into portfolio analysis
- Profile schema needs documents.locations section

</code_context>

<specifics>
## Specific Ideas

- Document locations in profile should be a map: `documents.locations: { insurance: "/path", banking: "/path", ... }`
- The doc reader sub-skill should list files in the configured folder and let the user select which to process
- Batch mode: process all PDFs in folder, show summary table, let user confirm/reject each extraction

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
