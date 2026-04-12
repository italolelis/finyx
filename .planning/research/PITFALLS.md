# Domain Pitfalls: Comprehensive Insurance Advisor (v2.1)

**Domain:** German insurance comparison/advisory CLI tool covering all major insurance types
**Researched:** 2026-04-12
**Confidence:** HIGH (verified with official German law sources, BaFin, and domain-specific documentation)

---

## Critical Pitfalls

### Pitfall 1: Crossing the §34d GewO Legal Boundary — Unlicensed Vermittlung

**What goes wrong:**
Finyx gives a specific recommendation like "Switch from Allianz Hausrat tariff X to HUK tariff Y — you save €84/year and get better coverage." Under §34d GewO, this constitutes Versicherungsvermittlung (insurance distribution), which requires an IHK-issued license. Giving personalized switch-to-specific-product recommendations without that license is a regulatory violation.

**Why it happens:**
The line between "advisory" and "distribution" is not where most developers expect. Explaining *that* a user is over-insured = advisory. Recommending *which specific competing tariff* to sign up for = distribution. The Insurance Distribution Directive (IDD) applies to automated tools: EIOPA Q&A 3407 (August 2025) formally asked the European Commission whether AI chatbots fall under IDD — the answer is "likely yes" for product-specific switching recommendations.

**Consequences:**
Regulatory violation of §34d GewO. As an open-source tool, liability rests with the user but the reputational risk of shipping a tool that crosses this line is significant. BaFin can issue cease-and-desist orders.

**Prevention:**
- Finyx must never recommend a specific tariff or provider for a new contract. Frame outputs as: "Based on Stiftung Warentest ratings and your profile, tariffs with these characteristics tend to score well. Use Check24/Verivox to get actual quotes."
- Use "class of product" recommendations: "Vollkasko is likely not cost-effective for your 12-year-old Volkswagen" is advisory. "Switch to ADAC Teilkasko" is distribution.
- Every output block must include: "This is educational analysis, not an insurance recommendation. Finyx is not a registered Versicherungsvermittler."
- The boundary: recommend *criteria* and *coverage characteristics*, not *specific products* or *providers*.

**Detection:**
Review every output that includes a provider name or tariff name. If it says "sign up for X" or "cancel Y and get Z" — rewrite to "tariffs with these features exist at providers like X, verify current terms directly."

---

### Pitfall 2: Stale Reference Data Presented as Current Pricing

**What goes wrong:**
The agent does web research to find Kfz insurance pricing, PKV tariffs, or Hausrat premiums, then presents these in an output that users treat as current quotes. Prices are highly individual (location, vehicle, health history, SF-Klasse) and change frequently. Reference doc authors update annually but Check24 rates update in real-time. An agent that says "expect around €180/year for Haftpflicht in Munich" is training-data hallucination dressed as research.

**Why it happens:**
WebSearch returns articles, not live quotes. Insurance pricing is parametric — the same tariff costs €90 for one person and €310 for another. No web search returns a user-specific price.

**Consequences:**
Users make cancellation decisions based on stale estimates, then find actual quotes are 40–60% different. Particularly dangerous for PKV where health history affects pricing dramatically.

**Prevention:**
- Never output a specific euro price for any insurance as a quote. Output price *ranges* from authoritative sources (Stiftung Warentest, Finanztip) with explicit "verify with provider" instructions.
- Add explicit staleness framing: "Stiftung Warentest 2024 data shows Haftpflicht tariffs range €45–€180/year for singles — get your personal quote from Check24."
- Reference doc headers must include `last_updated` and `data_source` fields. Agents emit a staleness warning if `last_updated` is > 12 months.

**Detection:**
Any output containing a specific price without a "get your own quote" disclaimer is a failure. Any output citing a specific premium without a date range is a failure.

---

### Pitfall 3: Comparing Incomparable Coverage Tiers

**What goes wrong:**
The agent compares two Hausrat tariffs on price without accounting for coverage tier differences: one tariff is "Basis" (no Fahrraddiebstahl, no grobe Fahrlässigkeit coverage), the other is "Komfort" (full coverage). The price difference looks like savings but is actually a coverage downgrade. The user switches and discovers the gap after a claim.

**Why it happens:**
Coverage tier comparison requires structured analysis of AVB (Allgemeine Versicherungsbedingungen) clauses. Web search returns marketing pages, not AVB comparison. Agents default to price-first framing.

**Consequences:**
User has a coverage gap they were not warned about. For Hausrat: grobe Fahrlässigkeit exclusion means insurance doesn't pay if the user forgot to lock a window. For Kfz: comparing Teilkasko to Vollkasko on price without flagging the coverage difference is misleading.

**Prevention:**
- Structure coverage comparison with explicit tier labels before price comparison.
- For every insurance type, define the minimum coverage floor the agent must verify before price-comparing: Hausrat (grobe Fahrlässigkeit included?), Haftpflicht (Deckungssumme ≥ €50M for Personen?), Kfz (Haftpflicht limit, Kasko type, SF-Klasse compatibility).
- Output format must show: Coverage Tier | Key Inclusions | Key Exclusions | Price Range — never just price.

**Detection:**
Any output that ranks tariffs by price without a coverage-comparison table first is a failure.

---

### Pitfall 4: Missing Kündigungsfristen — User Misses the Cancellation Deadline

**What goes wrong:**
User asks about switching Kfz insurance. Agent gives a correct recommendation but does not flag that the Kündigungsfrist for annual contracts is **November 30** (one month before December 31 renewal) and it is already November 15. User misses the window and is locked in for another year.

**Why it happens:**
Kündigungsfristen are contract-specific and insurance-type-specific. The agent knows the general rule but does not apply it to the user's specific situation with a date-aware urgency check.

**Consequences:**
User is locked into a worse or more expensive contract for 12 months. Particularly painful for Kfz (locked until next November 30) and multi-year household contracts.

**Prevention:**
- For every insurance review that could lead to a switch, the agent must: (1) ask the user when their contract renews, (2) calculate Kündigungsfrist deadline, (3) emit a date-aware warning if within 6 weeks of deadline.
- Reference doc `insurance-types.md` must include per-type standard Kündigungsfristen: Kfz (1 month before renewal, default Dec 31 = Nov 30), Hausrat/Haftpflicht (3 months), Lebensversicherung (varies — check contract).
- Use `currentDate` from system context to compute urgency in all deadline calculations.

**Detection:**
Run the agent on a "should I switch my Kfz?" prompt in November. If the output does not mention the November 30 deadline, it is broken.

---

### Pitfall 5: Ignoring Sonderkündigungsrecht — Missed Escape Windows

**What goes wrong:**
User recently received a premium increase notice from their insurer. They ask Finyx about their insurance costs. Finyx does not recognize that the premium increase triggered a Sonderkündigungsrecht, which gives them 1 month from notification to cancel and switch mid-contract. User does not know this window exists and waits until regular renewal.

**Why it happens:**
Sonderkündigungsrecht triggers are event-driven and require the agent to ask about recent insurer communications, not just current contract terms.

**Consequences:**
User pays higher premiums for up to 11 months unnecessarily. The Sonderkündigungsrecht window (1 month from notification) is narrow and easy to miss.

**Key Sonderkündigungsrecht triggers:**
- Beitragserhöhung (premium increase) — 1 month after notification
- After a claim settlement — 1 month after settlement
- Vehicle sale (Kfz) — buyer can cancel seller's policy within 1 month
- After a Schaden event — both insurer and insured can cancel
- Moving abroad permanently — 3 months notice

**Prevention:**
- The insurance questionnaire must ask: "Have you received any premium increase notices or made any claims in the past 3 months?"
- If yes → agent must evaluate Sonderkündigungsrecht eligibility and compute the remaining window.
- Reference doc must enumerate all Sonderkündigungsrecht triggers per insurance type.

---

## Critical: Kfz Insurance Type Pitfalls

### Pitfall 6: Oversimplifying Vollkasko vs Teilkasko vs Haftpflicht

**What goes wrong:**
Agent recommends Teilkasko for a 3-year-old car "because Vollkasko isn't worth it for older cars." But the car has a Leasing or financing agreement requiring Vollkasko, or the user's high SF-Klasse means Vollkasko premium is lower than expected. Or the reverse: agent recommends Vollkasko for a 15-year-old car with low market value.

**Coverage coverage boundaries (must be in reference doc):**
- **Haftpflicht** (mandatory): Covers damage *you cause to others*. Does NOT cover damage to your own vehicle.
- **Teilkasko** (optional add-on): Covers your vehicle from theft, wildlife collision (Wildunfall), fire, storm, hail, broken glass. Does NOT cover self-caused accidents or vandalism.
- **Vollkasko** (optional add-on, superset of Teilkasko): Adds coverage for self-caused accidents AND vandalism. SF-Klasse applies to Vollkasko, not Teilkasko.

**Common wrong recommendations:**
- Recommending Teilkasko for a leased car (financing agreements often mandate Vollkasko)
- Recommending dropping Vollkasko without checking SF-Klasse — at SF-50, Vollkasko can cost *less* than Teilkasko at SF-0
- Not accounting for Selbstbeteiligung (deductible) when comparing costs

**Prevention:**
- Before recommending Kasko type, agent must ask: (1) Is the car leased/financed? (2) What is the car's current market value (Zeitwert)? (3) What SF-Klasse are you in?
- Rule of thumb in reference doc: Vollkasko worth it if annual Vollkasko premium < 1/3 of car's Zeitwert.
- Always note that Teilkasko has no SF-Klasse — this affects premium structure fundamentally.

---

### Pitfall 7: Not Accounting for Schadenfreiheitsklasse (SF-Klasse) Complexity

**What goes wrong:**
Agent quotes premium estimates without factoring in SF-Klasse. A driver at SF-35 pays ~25% of the base rate. A new driver at SF-0 pays 100%+. A driver who just filed a claim dropped from SF-10 to SF-3 (insurer-specific downgrade table). Agent comparing premiums across providers without considering that SF-Klasse recognition varies between insurers is giving meaningless numbers.

**SF-Klasse system facts (must be in reference doc):**
- Range: SF-M (worst, <0), SF-S, SF-0, SF-½, SF-1 through SF-50
- New drivers: SF-0 (or SF-½ after 3 years of license without a vehicle)
- After claim: downgraded by insurer-specific table (e.g., SF-10 → SF-3 at some, SF-10 → SF-5 at others)
- Rabattschutz: some tariffs protect SF-Klasse after first claim — but Rabattschutz at Insurer A is NOT recognized at Insurer B when switching
- SF-Klasse is per-vehicle, per-coverage type (Haftpflicht and Vollkasko tracked separately)

**Prevention:**
- Reference doc must include standard SF-Klasse downgrade examples (with caveat that tables vary by insurer)
- Agent must ask for current SF-Klasse before any Kfz premium analysis
- Agent must warn: "If switching insurers, verify your SF-Klasse is transferable. Rabattschutz SF-Klassen may not be honored."
- Never present SF-Klasse as transferable between providers without the Rabattschutz caveat

**Detection:**
Any Kfz output that includes a premium estimate without referencing SF-Klasse as an input variable is a failure.

---

## Per-Type Coverage Pitfalls

### Pitfall 8: Hausrat — Unterversicherung and Versicherungssumme Miscalculation

**What goes wrong:**
Agent accepts the user's stated Hausrat Versicherungssumme (e.g., "€30,000") without checking whether it covers the actual Neuwert (replacement value) of their household contents. If the actual Neuwert is €50,000, the user has 40% Unterversicherung. After a total loss, the insurer only pays proportionally: €30k/€50k × claim = 60% of the actual loss.

**Unterversicherung formula:**
`Payout = (Versicherungssumme / Actual Neuwert) × Claim Amount`

**Standard calculation rules:**
- Rule of thumb: €650–€750/m² of living space
- Modern household with electronics, furniture, clothing for a family of 3 in 80m² flat: ~€52,000–€60,000
- Most users dramatically underestimate Neuwert (they think "what would I get at a garage sale," not "what does it cost to replace with new items")

**Prevention:**
- Agent must ask for flat size (m²) and calculate estimated Neuwert using standard per-m² rate
- Flag if user's stated Versicherungssumme is >20% below the calculated estimate
- Recommend Unterversicherungsverzicht tariffs (insurers waive the Unterversicherung check if the area-based formula is used)
- Note: Neuwertentschädigung (replacement value, not depreciated value) is the standard — verify the tariff includes it

---

### Pitfall 9: Haftpflicht — Deckungssumme Far Below Recommended Minimum

**What goes wrong:**
User has an old Haftpflicht policy with a €5M Deckungssumme. This was standard 10 years ago but is now considered insufficient. A serious accident causing permanent disability can easily exceed €10M in lifetime compensation claims. Agent does not flag the inadequate coverage.

**Current recommended minimums (HIGH confidence, Stiftung Warentest and Finanztip consistently recommend):**
- Personenschäden: ≥ €15M (some recommend €50M)
- Sachschäden: ≥ €5M
- Vermögensschäden: ≥ €250,000

**Prevention:**
- Reference doc must include current recommended Deckungssummen for private Haftpflicht
- Agent must always check Deckungssumme before assessing adequacy — never assume "has Haftpflicht = adequate"
- Flag any Deckungssumme < €15M for Personenschäden as potentially inadequate

---

### Pitfall 10: Rechtsschutz — Wartezeit, Streitentstehung, and Family/Inheritance Exclusions

**What goes wrong:**
User buys Rechtsschutz today and expects coverage for a rental dispute they have been escalating for 2 weeks. Rechtsschutz has a standard 3-month Wartezeit for most coverage areas (employment law has 3 months, contract disputes 3 months). The dispute started before contract conclusion — it is excluded permanently regardless of when the policy starts.

**Wartezeiten by coverage area:**
- Verkehrsrechtsschutz: no waiting period (traffic)
- Privatrechtsschutz (contract, neighbor): 3 months
- Berufsrechtsschutz / Arbeitsrecht: 3–6 months (insurer-dependent)
- Straf-Rechtsschutz: typically no waiting period

**Blanket exclusions (do NOT suggest Rechtsschutz covers these):**
- Family law (divorce, custody, Unterhalt)
- Inheritance disputes (Erbstreitigkeiten)
- Investment / speculation disputes
- Intentional criminal acts
- Disputes about construction contracts (varies — some tariffs include)

**The Deckungsprozess trap:** When the insurer disputes whether a claim is covered, the insured must potentially sue their own insurer to get coverage. This is a known risk and should be mentioned.

**Prevention:**
- Reference doc must enumerate Wartezeiten and exclusions per Rechtsschutz coverage module
- Agent must ask: "Do you have any pending or ongoing legal disputes?" If yes → warn that new Rechtsschutz will not cover pre-existing disputes
- Never recommend Rechtsschutz as a solution to an existing dispute

---

### Pitfall 11: Zahnzusatz — Pre-existing Treatment Plans Are Excluded

**What goes wrong:**
User asks about Zahnzusatz. Their dentist has already recommended a crown (Zahnersatz). User buys a Zahnzusatz policy. The treatment is excluded because it was "planned or recommended before contract start," even though they have not started it yet. Policies without Wartezeit still exclude pre-existing treatment plans.

**Key Zahnzusatz traps:**
- Standard Wartezeiten: 3 months (Behandlung), 8 months (Zahnersatz) — though "ohne Wartezeit" tariffs exist
- "Ohne Wartezeit" ≠ "no exclusions": pre-planned treatments are always excluded regardless of waiting period
- Missing teeth at contract start are typically excluded (especially >4 missing teeth)
- Health questionnaire answers must be truthful — misrepresentation voids the contract retroactively
- Annual benefit caps (Jahreshöchstleistung) vary enormously: €500–€5,000/year — must compare absolute amounts, not percentages

**Prevention:**
- Agent must ask: "Has your dentist recommended any treatments in the past 12 months that have not been completed?"
- If yes → warn that this treatment will be excluded from most Zahnzusatz policies regardless of Wartezeit
- Reference doc must document Jahreshöchstleistung comparison approach (not just reimbursement percentage)

---

### Pitfall 12: BU (Berufsunfähigkeitsversicherung) — Abstrakte vs Konkrete Verweisung

**What goes wrong:**
Agent compares BU policies without checking for the abstrakte Verweisung clause. If the policy includes abstract referral rights, the insurer can deny benefits because the insured *could theoretically* work in another profession — even if they never do. A software engineer who becomes unable to code can be denied because they could theoretically work as a hardware store cashier.

**The single most important BU quality indicator:**
"Verzicht auf abstrakte Verweisung" (waiver of abstract referral) — any BU policy that does not include this clause is considered substandard by every independent German rating (Stiftung Warentest, Finanztip, map-report).

**Other BU pitfalls:**
- Gesundheitsfragen must be answered with full disclosure — any omission can void the contract at claim time (even innocent omissions)
- BU is age and health sensitive: premiums rise sharply with age and deteriorating health; deferring purchase is costly
- Mental health is the leading BU claim cause in Germany — verify the tariff covers Burnout and depression without additional exclusions

**Prevention:**
- Reference doc must flag "Verzicht auf abstrakte Verweisung" as non-negotiable requirement
- Agent must include this check in any BU assessment
- Never recommend BU tariffs that include abstrakte Verweisung

---

### Pitfall 13: Kfz — Confusing Risikolebensversicherung with Kapitallebensversicherung Rückkaufswert

**What goes wrong:**
User asks about canceling their Lebensversicherung. Agent advises cancellation, mentioning Rückkaufswert. But the user has a Risikolebensversicherung (term life), not a Kapitallebensversicherung (whole life with savings component). Risikolebens has NO Rückkaufswert — canceling it simply ends coverage with zero payout.

**Key distinction:**
- **Risikolebensversicherung**: Pure death benefit, no savings component, no Rückkaufswert. Canceling = losing coverage, no money returned.
- **Kapitallebensversicherung**: Combined death benefit + savings (Sparanteil). Has Rückkaufswert. Canceling early is typically a bad deal (high agent commissions front-loaded, early surrender penalty). Alternative: Beitragsfreistellung (freeze contributions, preserve reduced death benefit).

**Prevention:**
- Agent must ask for the policy type before mentioning Rückkaufswert
- For Kapitallebens: always present Beitragsfreistellung as an alternative to full cancellation
- Reference doc must clearly separate these two insurance types

---

## Document Parsing Pitfalls

### Pitfall 14: Versicherungsschein Field Extraction — Wrong Fields from German PDFs

**What goes wrong:**
Agent parses a Versicherungsschein PDF and extracts incorrect values because:
- German PDFs use `.` as thousands separator and `,` as decimal separator — "1.250,00 €" is twelve hundred fifty euros, not 1.250 euros
- The Beitrag (premium) field may appear as annual (Jahresbeitrag), monthly (Monatsbeitrag), or quarterly — agent extracts the number without the period indicator
- "Versicherungssumme" and "Haftungssumme" appear near each other with different values; extracting the wrong one gives a 10× error
- Scanned PDFs with stamps or watermarks over key fields cause OCR to return garbage or skip the field entirely

**German-specific parsing rules that must be in the parsing logic:**
- Number format: always normalize "1.250,50" → 1250.50 before any arithmetic
- Always extract the period indicator (jährlich/monatlich/vierteljährlich) alongside the premium amount
- Verify extracted Deckungssumme is plausible for the insurance type (Haftpflicht: typically €5M–€50M, not €5,000)
- For scanned documents: treat any field where the confidence is low as "NOT FOUND" rather than a wrong value — ask user to confirm

**Prevention:**
- All document parsing must include explicit German number format normalization
- Extract period indicator as a required field alongside every monetary amount
- Include sanity checks: Haftpflicht premium < €500/year, Deckungssumme > €1M — flag anomalies for user confirmation
- Never propagate a parsed value into calculations without showing the user: "I parsed [field] as [value] — please confirm"

---

## Provider Research Pitfalls

### Pitfall 15: Check24 / Verivox Affiliate Bias in Source Prioritization

**What goes wrong:**
Agent uses Check24 or Verivox as the primary source for provider comparisons. These platforms are registered insurance brokers (Versicherungsmakler) that earn commissions on referrals. Providers who pay higher commissions rank better. Some quality providers (e.g., DEVK, Huk-Coburg direct) do not list on Check24 at all because they don't pay commissions. The agent presents a commission-biased subset as a comprehensive market view.

**Why it happens:**
Check24 is the most visible and scraped source for German insurance pricing. It appears comprehensive but covers ~60–70% of the market.

**Consequences:**
Systematically missing some of the best-value providers. The user is steered toward commission-paying providers, not necessarily the best ones.

**Prevention:**
- Source priority hierarchy in agent prompt: (1) Stiftung Warentest ratings (independent, subscription-funded), (2) Finanztip recommendations (no affiliate revenue model), (3) ADAC ratings for Kfz, (4) Check24/Verivox as quote-getting tools only, not ranking tools
- Always note when citing Check24: "Check24 does not list all providers — check Stiftung Warentest for providers not on portals"
- Never present a Check24 ranking as a neutral market ranking

---

### Pitfall 16: Ignoring Provider Stability — Insolvency Risk for Long-Duration Contracts

**What goes wrong:**
For long-duration contracts (BU, Lebensversicherung, PKV), agent recommends a smaller/newer provider because they currently offer the best premium. PKV and BU are 20–40 year commitments. A provider that cannot be taken over by a healthier insurer or faces financial difficulty can raise premiums drastically or transfer policies to Protektor (the German insurance rescue fund, which reduces benefits).

**Prevention:**
- For PKV, BU, and Risikolebens: reference doc must note that financial stability (BaFin-rated solvency, AM Best rating) is a selection criterion for long-term contracts
- Agent must note: "For long-term contracts like BU and PKV, prefer established large providers (Allianz, AXA, Debeka, Continentale) over price-optimized newer entrants — claims may be decades away"

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Insurance portfolio schema | Missing Versicherungsperiode (annual vs monthly) on every entry | Store as separate field, never derive from premium amount alone |
| Policy document parsing | German number format (1.250,00 €) parsed as 1.25 | Normalize before arithmetic; extract period indicator |
| Kfz analysis | SF-Klasse not captured, premium estimates meaningless | Add SF-Klasse to questionnaire as required field |
| Hausrat analysis | Unterversicherung not detected | Calculate Neuwert from m² and flag if stated sum is <80% of estimate |
| Rechtsschutz assessment | Recommending for active dispute | Always ask about pending disputes; warn about Wartezeit |
| Zahnzusatz | Pre-planned treatments excluded regardless of Wartezeit | Ask for recent dental treatment plans before recommending |
| BU assessment | Abstrakte Verweisung in tariff not flagged | Non-negotiable filter in any BU comparison |
| Provider research | Check24 presented as neutral market view | Always lead with Stiftung Warentest; present portals as quote tools only |
| Switch recommendations | Specific tariff recommendation = unlicensed Vermittlung | Recommend criteria and characteristics, never specific products |
| Cancellation advice | Missing Sonderkündigungsrecht trigger | Always ask about recent premium increases and claims |
| All outputs | Price quotes presented as current actuals | All prices must include vintage date and "verify with provider" |

---

## Sources

- [§34d GewO — official text](https://www.gesetze-im-internet.de/gewo/__34d.html) — Erlaubnispflicht for Versicherungsvermittler/Versicherungsberater (HIGH confidence)
- [BaFin — terminating insurance contracts](https://www.bafin.de/EN/Verbraucher/Versicherung/VertraegeKuendigen/vertraege_kuendigen_node_en.html) — Kündigungsfristen and Sonderkündigungsrecht (HIGH confidence)
- [ADAC — Sonderkündigungsrecht Kfz](https://www.adac.de/produkte/versicherungen/ratgeber/kfz-versicherung-sonderkuendigungsrecht/) — Kfz-specific special termination rights (HIGH confidence)
- [ADAC — Schadenfreiheitsklasse](https://www.adac.de/rund-ums-fahrzeug/auto-kaufen-verkaufen/versicherung/schadenfreiheitsklasse/) — SF-Klasse system and Rabattschutz behavior (HIGH confidence)
- [ADAC — Haftpflicht vs Teilkasko vs Vollkasko](https://www.adac.de/produkte/versicherungen/ratgeber/haftpflicht-teilkasko-vollkasko/) — coverage boundary definitions (HIGH confidence)
- [Finanztip — Unterversicherungsverzicht](https://www.finanztip.de/hausratversicherung/unterversicherungsverzicht/) — Hausrat Unterversicherung mechanics (HIGH confidence)
- [BU-Portal24 — abstrakte Verweisung](https://www.bu-portal24.de/abstrakte-verweisung.html) — BU abstrakte vs konkrete Verweisung explained (HIGH confidence)
- [insurtech4good — Is ChatGPT an IDD distributor?](https://www.insurtech4good.com/blog/is-chatgpt-an-insurance-distributor-in-the-eu/) — IDD scope for AI tools, EIOPA Q&A 3407 (MEDIUM confidence — regulatory interpretation)
- [EIOPA — Third IDD Report 2026](https://www.eiopa.europa.eu/eiopa-publishes-third-report-application-insurance-distribution-directive-2026-03-30_en) — Current regulatory thinking on AI in distribution (HIGH confidence)
- [rombey.capital — Insurance broker vs online portal](https://rombey.capital/en/insurance-broker-vs-online-comparison-portal-which-is-better-for-you/) — Check24/Verivox commission model and coverage gaps (MEDIUM confidence)
- [Finanztip — Teilkasko vs Vollkasko](https://www.finanztip.de/kfz-versicherung/teilkasko-vollkasko/) — vehicle value threshold for Vollkasko (HIGH confidence)
- [zahnzusatzversicherungen-vergleich.com — Wartezeit](https://www.zahnzusatzversicherungen-vergleich.com/vertragsdetails/wartezeit/) — Zahnzusatz waiting periods and pre-existing exclusions (MEDIUM confidence)
