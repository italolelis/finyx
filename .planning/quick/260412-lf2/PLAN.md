---
task_id: 260412-lf2
title: Make broker handling agnostic — remove hardcoded broker bias
type: quick
tasks: 3
---

<objective>
Remove hardcoded broker names and decision matrices from `commands/finyx/broker.md`. Make the command discover brokers dynamically via WebSearch, use reference docs as baseline only, respect user's existing broker preferences from profile, and record chosen brokers back to profile on consent.

Also update `commands/finyx/help.md` to remove specific broker names from the broker command description.
</objective>

<tasks>

<task id="1" type="auto">
  <name>Rewrite broker.md — agnostic discovery with WebSearch</name>
  <read_first>
    - commands/finyx/broker.md (full current file — the rewrite target)
    - commands/finyx/invest.md (reference for WebFetch/WebSearch pattern and profile.json broker reading)
    - finyx/references/germany/brokers.md (understand what baseline data looks like)
    - finyx/references/brazil/brokers.md (understand what baseline data looks like)
  </read_first>
  <files>commands/finyx/broker.md</files>
  <action>
Rewrite `commands/finyx/broker.md` with these changes:

**Frontmatter — add WebFetch and WebSearch to allowed-tools:**
```yaml
allowed-tools:
  - Read
  - Bash
  - Write
  - WebFetch
  - WebSearch
  - AskUserQuestion
```

**Phase 1: Validation** — keep as-is (profile check, country detection).

**Phase 2: Reference Doc Staleness Check** — keep as-is but add a note that reference docs are baselines, not exhaustive lists.

**Phase 2.5 (NEW): Profile Broker Check** — Read `countries.germany.brokers[]` and `countries.brazil.brokers[]` from profile. If user already has broker entries, display them:
```
You already have these brokers in your profile:
- [broker_name] ([country])
```
Ask: "Would you like to compare these, explore new options, or both?"

**Phase 3: German Broker Discovery (was hardcoded comparison)** — Restructure:
1. Load `germany/brokers.md` as baseline reference data
2. Use WebSearch to find "best German brokers 2026 ETF Sparplan comparison" and "neue Neobroker Deutschland 2026"
3. Merge baseline + web results into a unified comparison table
4. The table columns stay the same: Broker, Trade Fee, Sparplan Fee, Custody, Regulated By
5. Include ANY broker found via search that is BaFin-regulated or accessible to German residents (Revolut, moomoo, Smartbroker, Finanzen.net Zero, etc.)
6. Do NOT limit to only Trade Republic / Scalable / ING / comdirect
7. After the table, show key differentiators for each broker found — keep the same format (bullet points with URL)
8. Add note: "Reference data from [last_verified date]. Live search performed [today]. Always verify on broker website."

**Phase 4: Brazilian Broker Discovery** — Same pattern as Phase 3 but for Brazil:
1. Load `brazil/brokers.md` as baseline
2. WebSearch for "melhores corretoras Brasil 2026 ações ETF" and "corretoras taxa zero Brasil"
3. Merge into unified table
4. Do NOT limit to NuInvest / XP / BTG

**Phase 5: Profile-Based Recommendation (was hardcoded decision matrix)** — Restructure:
1. Keep the 3 AskUserQuestion questions (trading frequency, strategy, tax simplicity)
2. REMOVE the hardcoded decision matrices that map scenarios to specific broker names
3. REPLACE with generic criteria-based scoring:
   - For each broker discovered in Phase 3/4, score against user answers:
     - Trading frequency answer maps to: fee structure weight (per-trade vs flat vs free)
     - Strategy answer maps to: Sparplan availability, product range
     - Tax simplicity answer maps to: automatic withholding, Freistellungsauftrag support, Jahressteuerbescheinigung
   - Present top 2-3 brokers ranked by fit, with reasoning tied to user's answers
   - Use format: "Based on your answers, [Broker] scores highest because [reason tied to Q1/Q2/Q3]"
4. Do NOT hardcode "if Sparplan + rarely → Trade Republic" — instead evaluate dynamically

**Phase 5.5 (NEW): Record Broker Preference** — After recommendation:
```
Would you like me to save your preferred broker(s) to your profile?
This helps other Finyx commands (like /finyx:invest) know where your accounts are.
```
If yes, update `countries.[country].brokers[]` in `.finyx/profile.json` via Write. Only add new entries — do not overwrite existing broker data.

**Phase 6: Tax Reporting Quality** — Keep the structural content (German vs foreign broker tax differences) but make it generic:
- Replace "Trading212, IBKR" with "foreign brokers (non-German entities)"
- Keep the comparison table but use "German Broker" vs "Foreign Broker" as column headers (already mostly this way)
- The Brazilian section is already generic — keep as-is

**Phase 7: Disclaimer** — keep as-is.

**Notes section** — Update:
- Change "Recommendation Is Profile-Based, Not Exhaustive" note to mention that the command uses live web search to discover current brokers beyond the baseline reference docs
- Remove any notes that reference specific broker names as the only options
  </action>
  <acceptance_criteria>
    - grep -c "WebFetch" commands/finyx/broker.md returns >= 1
    - grep -c "WebSearch" commands/finyx/broker.md returns >= 2 (allowed-tools + usage in process)
    - grep -c "hardcoded" commands/finyx/broker.md returns 0 (no self-referential language about hardcoding)
    - grep -cE "^\| Trade Republic \|.*€1\.00" commands/finyx/broker.md returns 0 (no hardcoded fee table rows)
    - grep -c "decision matrix" commands/finyx/broker.md returns 0 (removed hardcoded matrix)
    - grep -c "baseline" commands/finyx/broker.md returns >= 1 (reference docs described as baseline)
    - grep -c "WebSearch" commands/finyx/broker.md returns >= 1 (live discovery mentioned in process)
    - grep -c "profile.json" commands/finyx/broker.md returns >= 2 (reads from and writes to profile)
    - grep -c "countries\.\(germany\|brazil\)\.brokers" commands/finyx/broker.md returns >= 1 (profile broker reading)
  </acceptance_criteria>
  <done>broker.md uses reference docs as baseline, discovers brokers via WebSearch, scores dynamically against user answers instead of hardcoded matrix, and offers to save preferences to profile</done>
</task>

<task id="2" type="auto">
  <name>Update help.md — remove specific broker names from broker command description</name>
  <read_first>
    - commands/finyx/help.md (find broker-related descriptions)
  </read_first>
  <files>commands/finyx/help.md</files>
  <action>
Find and update these specific lines in `commands/finyx/help.md`:

1. Line ~134 — the broker command table row description currently says:
   `| /finyx:broker | Broker fee comparison and profile-based recommendation for German and Brazilian brokers |`
   Change to:
   `| /finyx:broker | Broker fee comparison and profile-based recommendation with live market discovery |`

2. Lines ~230-236 — the `/finyx:broker` detail section "Covers" list currently names specific brokers:
   ```
   - German broker fee comparison (Trade Republic, Scalable Capital FREE and PRIME+, ING, comdirect)
   - Brazilian broker fee comparison (NuInvest, XP Investimentos, BTG Pactual)
   ```
   Change to:
   ```
   - German broker fee comparison (live discovery + baseline reference data)
   - Brazilian broker fee comparison (live discovery + baseline reference data)
   - New broker detection via web search (discovers current market entrants)
   ```

3. The "Profile-based recommendation" bullet stays — it already describes behavior generically.

Do NOT change any other commands or sections in help.md.
  </action>
  <acceptance_criteria>
    - grep -c "Trade Republic" commands/finyx/help.md returns 0
    - grep -c "Scalable Capital" commands/finyx/help.md returns 0
    - grep -c "NuInvest" commands/finyx/help.md returns 0
    - grep -c "XP Investimentos" commands/finyx/help.md returns 0
    - grep -c "BTG Pactual" commands/finyx/help.md returns 0
    - grep -c "live discovery" commands/finyx/help.md returns >= 1
  </acceptance_criteria>
  <done>help.md no longer names specific brokers in the broker command description; uses generic "live discovery" language instead</done>
</task>

<task id="3" type="auto">
  <name>Verify invest.md is already agnostic (read-only confirmation)</name>
  <read_first>
    - commands/finyx/invest.md (verify no hardcoded broker names in recommendation logic)
  </read_first>
  <files>none — read-only verification</files>
  <action>
Confirm that `commands/finyx/invest.md` does NOT contain hardcoded broker recommendations or decision matrices. It should:
- Read brokers from `countries.[country].brokers[]` in profile (already does this in Phase 2)
- Not recommend specific broker names
- Use WebFetch for market data (already does this in Phase 7)

If any hardcoded broker bias is found, fix it using the same pattern as Task 1. If clean, report "invest.md already agnostic — no changes needed."
  </action>
  <acceptance_criteria>
    - No file changes needed (invest.md is already agnostic based on read)
  </acceptance_criteria>
  <done>invest.md confirmed agnostic — reads broker data from profile, no hardcoded recommendations</done>
</task>

</tasks>

<verification>
After all tasks:
1. `grep -rn "Trade Republic\|Scalable Capital\|NuInvest\|XP Investimentos\|BTG Pactual" commands/finyx/broker.md commands/finyx/help.md` — should return 0 matches (no hardcoded broker names in command files)
2. `grep -c "WebSearch" commands/finyx/broker.md` — should return >= 2
3. `grep -c "baseline" commands/finyx/broker.md` — should return >= 1
4. Reference docs (`finyx/references/germany/brokers.md`, `finyx/references/brazil/brokers.md`) are UNCHANGED
</verification>
