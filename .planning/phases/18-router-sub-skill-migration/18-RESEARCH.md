# Phase 18: Router + Sub-skill Migration - Research

**Researched:** 2026-04-12
**Domain:** Claude Code slash-command architecture — prompt-level routing and sub-skill file dispatch
**Confidence:** HIGH

## Summary

Phase 18 converts the monolithic `skills/insurance/SKILL.md` (currently ~600 lines of health insurance logic) into a thin router that detects insurance type from user input and delegates to per-type sub-skill prompts. The health insurance flow migrates verbatim to `skills/insurance/sub-skills/health.md`. No new libraries or runtimes are involved — this is a pure Markdown prompt restructuring within the existing Claude Code skill architecture.

The router mechanism works by reading the sub-skill `.md` file at runtime using the Read tool (via `${CLAUDE_SKILL_DIR}/sub-skills/health.md` path), then following the instructions in that file. This is the only viable dispatch mechanism in a Markdown prompt system with no code execution beyond Bash. AskUserQuestion is the correct tool when the insurance type cannot be inferred from the user's initial input.

**Primary recommendation:** Router SKILL.md uses keyword detection on the user's input to determine type, asks when ambiguous, then reads and executes the matched sub-skill file from `${CLAUDE_SKILL_DIR}/sub-skills/`. Health SKILL.md content moves unchanged to `sub-skills/health.md`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None — all implementation choices are at Claude's discretion.

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

Key constraints from codebase:
- Skills use `SKILL.md` as entry point with YAML frontmatter (`name`, `description`, `allowed-tools`)
- Agents live under `skills/{name}/agents/`
- References live under `skills/{name}/references/`
- Current insurance SKILL.md is a full health insurance advisor (~600 lines)
- Router must preserve the `/finyx:insurance` command name
- Sub-skills are `.md` prompt files loaded by the router based on keyword detection

### Deferred Ideas (OUT OF SCOPE)
None — infrastructure phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | Insurance skill uses router pattern dispatching to per-type sub-skill prompts | Router SKILL.md reads sub-skill files via Read tool using `${CLAUDE_SKILL_DIR}/sub-skills/{type}.md`; keyword detection + AskUserQuestion for ambiguous input |
</phase_requirements>

## Standard Stack

No new dependencies — this phase uses only existing Claude Code architecture primitives.

### Core Primitives Already in Use
| Primitive | Purpose | How Used in Router |
|-----------|---------|-------------------|
| `SKILL.md` YAML frontmatter | Entry point declaration | Router keeps `name: finyx-insurance`, updates description |
| `${CLAUDE_SKILL_DIR}` variable | Resolved by Claude Code to skill directory | Read sub-skill files at `${CLAUDE_SKILL_DIR}/sub-skills/{type}.md` |
| `Read` tool | Load file contents into context | Router loads the matched sub-skill file |
| `AskUserQuestion` | Interactive disambiguation | Used when type is ambiguous from input |
| `<execution_context>` block | Auto-load files before process starts | Router loads only `disclaimer.md` and `profile.json` — sub-skill files are loaded on demand |

### No Alternatives Considered
There are no alternative routing mechanisms in this architecture. The stack is fixed: Markdown prompts + Claude Code tool calls.

## Architecture Patterns

### Recommended Project Structure
```
skills/insurance/
├── SKILL.md                    # Router only (~60 lines, replaces ~600-line monolith)
├── sub-skills/
│   └── health.md               # Full health insurance flow (moved verbatim from SKILL.md)
├── agents/
│   ├── finyx-insurance-calc-agent.md     # Unchanged
│   └── finyx-insurance-research-agent.md # Unchanged
└── references/
    ├── disclaimer.md                      # Unchanged
    └── germany/
        └── health-insurance.md            # Unchanged
```

### Pattern 1: Keyword Detection Router
**What:** Router SKILL.md inspects the user's `$ARGUMENTS` (the text after `/finyx:insurance`) for insurance type keywords. If no arguments, asks once. Reads the matched sub-skill file, then follows its instructions.

**When to use:** Any time a single skill entry point must dispatch to multiple independent flows.

**Example (router SKILL.md process):**

```markdown
## Phase 0: Type Detection

Inspect `$ARGUMENTS` (the user's input after `/finyx:insurance`).

Check for keywords (case-insensitive):
- "health", "kranken", "pkv", "gkv", "krankenversicherung" → type = "health"
- "liability", "haftpflicht", "privathaftpflicht" → type = "liability"
- (additional types added in Phase 21/22)

If type is identified: proceed to Phase 1.

If type is NOT identified (no input or unrecognized):
Use AskUserQuestion with singleSelect:
"Which insurance type would you like advice on?"
- Health insurance (Krankenversicherung — GKV vs PKV)
- (more types appear here as Phase 21/22 add sub-skills)

## Phase 1: Sub-skill Dispatch

Read the matched sub-skill file:
```bash
echo "Loading sub-skill: ${CLAUDE_SKILL_DIR}/sub-skills/{type}.md"
```

Read `${CLAUDE_SKILL_DIR}/sub-skills/health.md` (when type == "health").

Follow all instructions in the loaded sub-skill file from its Phase 0 onward.
```

**Key design decisions:**
- Router SKILL.md has NO health insurance logic — it is purely dispatch
- Sub-skill files are self-contained: they include their own phase numbering, error handling, and notes
- `${CLAUDE_SKILL_DIR}` in the sub-skill content refers to the parent skill directory (insurance), so all existing agent and reference paths resolve correctly without modification
- The `execution_context` block in router SKILL.md loads only `disclaimer.md` and `profile.json` — sub-skill files load their own domain references via the Read tool when executed

### Pattern 2: Sub-skill File as Self-Contained Prompt
**What:** `sub-skills/health.md` is the verbatim content of the current SKILL.md (minus the YAML frontmatter, which belongs only to the router). It is a plain Markdown file — not a slash-command itself.

**Why plain Markdown, not a SKILL.md:** Sub-skill files are not registered as Claude Code commands — they have no YAML frontmatter. They exist as readable prompt content dispatched by the router. This preserves the single `/finyx:insurance` entry point.

**Reference path compatibility:** All `${CLAUDE_SKILL_DIR}/references/...` paths in the current SKILL.md content resolve relative to `skills/insurance/` regardless of whether the content is in SKILL.md or sub-skills/health.md. No path changes are needed in the health flow content when moving it.

### Pattern 3: Router allowed-tools Must Be a Superset
**What:** The router SKILL.md's `allowed-tools` must declare ALL tools used by any sub-skill it can dispatch to — because tool permissions are set at skill load time (YAML frontmatter), not at sub-skill read time.

**Current health insurance tools:**
```yaml
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
  - WebSearch
  - WebFetch
```

The router must declare this full set. As new sub-skills are added in Phase 21/22, the router's `allowed-tools` may need to expand. This is a known maintenance point.

### Anti-Patterns to Avoid
- **Embedding health logic in the router:** The router must remain a pure dispatcher. Any health-specific logic that leaks into SKILL.md couples the router to the sub-skill and defeats the architecture.
- **Sub-skill as a registered command:** Sub-skills must NOT have YAML frontmatter — they should not appear as `/finyx:insurance-health` commands. Single entry point is the contract.
- **Hardcoding the `${CLAUDE_SKILL_DIR}` path:** Never write an absolute path like `~/.claude/skills/insurance/sub-skills/health.md`. Always use `${CLAUDE_SKILL_DIR}/sub-skills/health.md` so the skill works regardless of install location (global vs local).
- **Duplicating execution_context:** The router's `execution_context` loads shared files once. Sub-skill files should NOT redeclare `<execution_context>` blocks — they inherit the router's loaded context. Sub-skills reference files with Read tool calls inside their process phases.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Insurance type classification | Custom NLP or scoring | Keyword matching on `$ARGUMENTS` + AskUserQuestion fallback | There are <15 insurance types, keywords are unambiguous German/English terms |
| Sub-skill loading | Dynamic require() or scripting | Read tool on `${CLAUDE_SKILL_DIR}/sub-skills/{type}.md` | Claude Code Read tool is the correct mechanism for loading Markdown context |
| Multi-step routing flow | State machine logic | Single phase: detect → read → execute | The router has exactly one job; complexity belongs in sub-skills |

**Key insight:** Claude Code prompt files have no module system. "Loading" a sub-skill means reading its text into context with the Read tool and then following its instructions. This is the correct and only mechanism.

## Common Pitfalls

### Pitfall 1: Sub-skill Uses `execution_context` Block
**What goes wrong:** If `sub-skills/health.md` includes an `<execution_context>` block, Claude Code will not process it (only SKILL.md frontmatter-equipped files have `<execution_context>` semantics). The block is rendered as plain text and files are not loaded.
**Why it happens:** Copying the current SKILL.md content verbatim includes the `<execution_context>` block.
**How to avoid:** When extracting health content to `sub-skills/health.md`, remove the `<execution_context>` block. Replace it with explicit Read tool calls in the sub-skill's Phase 0 or Phase 1 if specific files must be loaded. In practice, the router's execution_context already loads `disclaimer.md` and `profile.json`, so the sub-skill's main dependencies are covered.
**Warning signs:** Sub-skill references files it expects to be auto-loaded but they're not in context.

### Pitfall 2: Router's allowed-tools Is Incomplete
**What goes wrong:** If the router's YAML `allowed-tools` does not include `Task`, `WebSearch`, or `WebFetch`, any sub-skill that spawns agents or makes web requests will fail with a tool permission error.
**Why it happens:** Router initially seems to only need `AskUserQuestion` and `Read` — but sub-skill tools are scoped to the router's permissions.
**How to avoid:** Set router `allowed-tools` to the union of all current and anticipated sub-skill tool requirements. The current health sub-skill needs: `Read`, `Bash`, `Write`, `Task`, `AskUserQuestion`. Add `WebSearch` and `WebFetch` proactively for Phase 21/22 sub-skills.
**Warning signs:** Agent Task calls fail or tool-not-allowed errors appear when running the health sub-skill after migration.

### Pitfall 3: Path Breaks After Move
**What goes wrong:** Agents in `sub-skills/health.md` reference `${CLAUDE_SKILL_DIR}/references/germany/health-insurance.md` inline in Task prompts as string literals. If the sub-skill path changes these literals, agents fail.
**Why it happens:** Confusion between where `${CLAUDE_SKILL_DIR}` resolves (always `skills/insurance/`) vs. where the sub-skill file lives (`skills/insurance/sub-skills/health.md`).
**How to avoid:** `${CLAUDE_SKILL_DIR}` always resolves to the skill root regardless of sub-skill depth. All existing path references in the health flow are correct as-is — copy them verbatim.
**Warning signs:** Agents cannot find reference docs during testing after migration.

### Pitfall 4: Forgetting to Remove YAML Frontmatter from Sub-skill
**What goes wrong:** If `sub-skills/health.md` has YAML frontmatter, it may be interpreted as a skill definition (depends on Claude Code version), creating a phantom command or breaking the router's Read call.
**Why it happens:** Mechanical copy-paste of SKILL.md content including the frontmatter.
**How to avoid:** Strip the frontmatter block (`---` ... `---`) from the sub-skill file. Sub-skills are plain Markdown.
**Warning signs:** `/finyx:insurance-health` appears as a command, or Read tool returns unexpected metadata.

### Pitfall 5: Router Description Doesn't Reflect New Scope
**What goes wrong:** Router SKILL.md keeps the old description "Health insurance advisor for Germany — GKV vs PKV comparison...". When Phase 21/22 add more sub-skills, the description is stale.
**Why it happens:** Lazy copy of old frontmatter.
**How to avoid:** Update router description to reflect the router role: "Insurance advisor for Germany — routes to per-type sub-skills: health (GKV/PKV), liability, household, and more."

## Code Examples

### Router SKILL.md Skeleton
```markdown
---
name: finyx-insurance
description: Insurance advisor for Germany — routes to per-type sub-skills based on insurance type
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
</execution_context>

<process>

## Phase 0: Type Detection

Inspect `$ARGUMENTS`.

Keyword map (case-insensitive match against user input):
- "health", "kranken", "pkv", "gkv", "krankenversicherung" → sub-skill: health

If matched: proceed to Phase 1.
If not matched (no input or unrecognized type):
Use AskUserQuestion with singleSelect:
"Which insurance type would you like advice on?"
- Health insurance (Krankenversicherung — GKV vs PKV)

Set `sub_skill_type` from the answer.

## Phase 1: Sub-skill Dispatch

Read `${CLAUDE_SKILL_DIR}/sub-skills/{sub_skill_type}.md`.
Follow all instructions in the loaded file from its Phase 0 onward.

</process>
```

### sub-skills/health.md Structure
```markdown
# Health Insurance Sub-skill

[All content from current SKILL.md <objective>, <process>, <error_handling>, <notes> blocks — verbatim]
[YAML frontmatter removed]
[<execution_context> block removed — router already loaded disclaimer.md and profile.json]
```

## Runtime State Inventory

Not applicable — this is a code/file restructuring phase with no runtime state, databases, or external service registrations. The `${CLAUDE_SKILL_DIR}` variable is resolved at Claude Code runtime from the install location, not from stored state.

**Verification:** No Mem0 records, no n8n workflows, no OS-registered tasks, no secrets, no build artifacts reference `skills/insurance/SKILL.md` directly (paths are resolved via `${CLAUDE_SKILL_DIR}` variable).

## Environment Availability

Step 2.6: SKIPPED — this phase is purely Markdown file restructuring with no external tool dependencies beyond Claude Code itself, which is already present.

## Validation Architecture

Validation is disabled (`nyquist_validation: false` in `.planning/config.json`).

Manual verification protocol for this phase:
1. `/finyx:insurance health` (or `/finyx:insurance krankenversicherung`) routes to health sub-skill
2. Health sub-skill produces identical output to the pre-migration SKILL.md for the same inputs
3. Agents (`finyx-insurance-calc-agent`, `finyx-insurance-research-agent`) are callable from the sub-skill with unchanged paths
4. `/finyx:insurance` with no arguments prompts for type selection and then routes correctly
5. `/finyx:insurance someunknowntype` also prompts for selection

## Open Questions

1. **Does `${CLAUDE_SKILL_DIR}` resolve inside sub-skill file content?**
   - What we know: `${CLAUDE_SKILL_DIR}` is replaced by Claude Code's template engine when the SKILL.md frontmatter is processed. It is used in `execution_context` blocks and as a literal string inside `<process>` instructions for the model to use in Read tool calls.
   - What's unclear: Whether the variable is replaced in files loaded *by* the router via Read tool (i.e., in `sub-skills/health.md` content). It may be treated as a literal string that the model carries from the router context.
   - Recommendation: In `sub-skills/health.md`, keep `${CLAUDE_SKILL_DIR}` references as literal strings — the model will interpolate them correctly based on the value established when the router's execution_context was processed. This is how existing agent files use it (see `finyx-insurance-calc-agent.md` line 29: `${CLAUDE_SKILL_DIR}/references/germany/health-insurance.md`).
   - Confidence: MEDIUM — verified by analogy with agent files which use the variable as string literals in their process sections and it resolves correctly.

2. **Should Phase 18 add a `portfolio` type to the router?**
   - What we know: Phase 20 adds a portfolio sub-skill. Phase 18 CONTEXT says success criteria only require health routing.
   - What's unclear: Whether stubbing the portfolio route now saves refactoring later.
   - Recommendation: Do not stub — keep Phase 18 minimal (ARCH-01 only). Phase 20 will add the portfolio entry to the router's keyword map. This avoids phantom routes to non-existent sub-skills.

## Sources

### Primary (HIGH confidence)
- Direct inspection of `skills/insurance/SKILL.md` (604 lines, verified 2026-04-12)
- Direct inspection of `skills/insurance/agents/finyx-insurance-calc-agent.md` — `${CLAUDE_SKILL_DIR}` usage pattern
- Direct inspection of `skills/insurance/agents/finyx-insurance-research-agent.md` — `${CLAUDE_SKILL_DIR}` usage pattern
- Direct inspection of `skills/insights/SKILL.md`, `skills/tax/SKILL.md`, `skills/invest/SKILL.md` — established SKILL.md patterns
- `.planning/config.json` — `nyquist_validation: false` confirmed

### Secondary (MEDIUM confidence)
- Analogy with agent file `${CLAUDE_SKILL_DIR}` usage pattern (agents use it as string literals in process sections, model interpolates at runtime)

## Metadata

**Confidence breakdown:**
- Router pattern: HIGH — codebase conventions are fully established, pattern is a direct application
- Sub-skill file contract: HIGH — plain Markdown read by Read tool, no ambiguity
- `${CLAUDE_SKILL_DIR}` resolution in sub-skill: MEDIUM — extrapolated from agent file behavior
- Pitfalls: HIGH — derived from direct code inspection of the file being migrated

**Research date:** 2026-04-12
**Valid until:** Stable (Claude Code plugin architecture is established — no fast-moving external dependencies)
