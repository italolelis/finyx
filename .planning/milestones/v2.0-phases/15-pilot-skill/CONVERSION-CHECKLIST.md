# Skill Conversion Checklist

Template for converting `commands/finyx/{name}.md` to `skills/{name}/SKILL.md`.
Derived from Phase 14 (profile) and Phase 15 (tax) pilot conversions.
Use this checklist in Phase 16 for bulk migration of remaining commands.

## Pre-flight

- [ ] Verify `skills/{name}/` directory exists (created in Phase 13)
- [ ] Verify `skills/{name}/SKILL.md` stub exists
- [ ] Verify agents already copied to `skills/{name}/agents/` (Phase 13)
- [ ] Verify reference docs already in `skills/{name}/references/` (Phase 13)
- [ ] Identify cross-skill reference dependencies (files referenced but owned by another skill)

## Frontmatter

- [ ] `name: finyx-{name}` — matches original command name
- [ ] `description:` — Under 250 chars, front-loaded for model detection. Start with the domain noun, include key terms users would say
- [ ] `allowed-tools:` — Copy from source command. Remove `Task` if no agent delegation needed
- [ ] `disable-model-invocation: true` — REQUIRED for all advisory skills (tax, invest, pension, insurance, insights). OMIT for interview-based skills (profile) and action-based skills (realestate per D-07)

## Content Migration

- [ ] Copy `<objective>` section verbatim
- [ ] Copy `<execution_context>` — verify all paths use `${CLAUDE_SKILL_DIR}/references/`
- [ ] Copy `<process>` section — all phases verbatim
- [ ] Copy `<error_handling>` section verbatim
- [ ] Copy `<notes>` section verbatim
- [ ] For cross-skill references: add fallback note ("if not available, skip and direct to /finyx:{other}")

## Path Verification

- [ ] Zero occurrences of `@~/.claude/` in the file
- [ ] All `${CLAUDE_SKILL_DIR}/references/` paths resolve to files in `skills/{name}/references/`
- [ ] `@.finyx/profile.json` kept as-is (runtime user file, not a skill reference)

## Agent Scoping

- [ ] All agents for this skill exist under `skills/{name}/agents/`
- [ ] No skill-specific agents remain at project root `agents/`
- [ ] Agent file references within SKILL.md use relative or skill-scoped paths

## Validation

- [ ] `grep -q "disable-model-invocation: true" skills/{name}/SKILL.md` (if advisory)
- [ ] `grep -c "@~/.claude/" skills/{name}/SKILL.md` returns 0
- [ ] `wc -l < skills/{name}/SKILL.md` shows substantial content (not a stub)
- [ ] Key domain terms present (grep for 2-3 domain-specific terms)

## Skills requiring disable-model-invocation: true

tax, invest, broker, pension, insurance, insights

## Skills NOT requiring disable-model-invocation

profile (interview-based), realestate commands (scout, analyze, filter, compare, stress-test, report, init — per D-07)

---

## Notes from Pilot Conversions

### Phase 14 — profile skill

- Profile skill omits `disable-model-invocation` (interview-based, not advisory)
- Two-path profile storage: `.finyx/` project-local primary, `~/.finyx/` global fallback
- `@~/.claude/finyx/templates/` paths mapped to `${CLAUDE_SKILL_DIR}/references/` (templates migrate into skill references)

### Phase 15 — tax skill

- `allowed-tools` does NOT include `Task` — tax-scoring agent not invoked by this command
- PKV cross-skill reference (`health-insurance.md`) handled via fallback note (Option B): skip and direct to `/finyx:insurance` rather than duplicating the file
- `execution_context` loads 3 references: disclaimer.md, germany/tax-investment.md, brazil/tax-investment.md
- `@.finyx/profile.json` kept as-is (runtime file, resolved at execution time)

### General patterns observed

- Source commands already had `${CLAUDE_SKILL_DIR}/references/` paths from Phase 13 migration — no path rewriting needed
- Stub content (placeholder description + single comment line) is fully overwritten
- Line count check: stubs are ~10 lines; full skills are 400–600+ lines
- Cross-skill dependencies should use fallback notes rather than file duplication to avoid divergence
