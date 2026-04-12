---
last_verified: 2026-04-06
country: germany
domain: broker-comparison
source: broker websites, fin-advisor skill
---

# German Broker Comparison Reference

This document covers the main German and foreign brokers available to German-resident investors — including fee structures, savings plan support, and tax reporting quality. It is loaded by `/finyx:broker` to provide accurate, date-stamped guidance.

> **Staleness notice:** Broker fees change frequently. The `/finyx:broker` command will warn you if this document is more than 6 months old. Always verify current fees on the broker's website before making decisions.

---

## Note on Coverage

This reference document covers commonly-used German and foreign brokers. It is NOT exhaustive.
If the user's broker is not listed here, the `/finyx:broker` command will research it live
via WebSearch. The absence of a broker from this document does not indicate it is unsuitable.

Brokers change fees frequently. Always verify current fees on the broker's website.

---

## 1. German Brokers

### Trade Republic

- **Trade fee:** €1.00/order (Fremdkostenpauschale)
- **Savings plans (Sparplan):** FREE for all ETFs and stocks
- **Custody fee:** none
- **Inactivity fee:** none
- **Cash interest:** yes (on uninvested cash, rate varies)
- **Freistellungsauftrag:** supported (managed in app)
- **Tax reporting:** Jahressteuerbescheinigung generated automatically
- **Regulation:** BaFin (Germany)
- **Products:** ~2,000 ETFs, ~9,000 stocks, crypto, bonds, derivatives
- **Exchange:** LS Exchange (single exchange for stocks/ETFs)
- **URL:** https://traderepublic.com

**Best for:** Low-cost Sparplan investors, ETF-first strategy, mobile-first experience.

---

### Scalable Capital

- **Trade fee (FREE model):** €0.99/order for trades below €250; FREE from €250 on gettex/EIX
- **Trade fee (PRIME+ model):** €4.99/month flat rate — all trades free from €250
- **Savings plans:** FREE regardless of model (no per-rate order fee)
- **Custody fee:** none
- **Freistellungsauftrag:** supported
- **Tax reporting:** Jahressteuerbescheinigung delivered by April 12 of the following year
- **Regulation:** BaFin (Germany)
- **URL:** https://de.scalable.capital

**Best for:** Active traders (PRIME+ pays off above ~5 trades/month), or zero-commission Sparplan via FREE model.

---

### ING (DiBa)

- **Trade fee:** €4.90 + 0.25% of order value (minimum ~€4.90, no published cap)
- **Savings plans:** promotional ETFs free; standard ETFs 1.75% per rate
- **Custody fee:** none
- **Freistellungsauftrag:** supported
- **Tax reporting:** Jahressteuerbescheinigung delivered ~March 10 of following year
- **Regulation:** BaFin (Germany)
- **Products:** Full banking + brokerage; ~1,100 ETFs available for Sparplan
- **URL:** https://ing.de

**Best for:** Existing ING bank customers who prefer consolidation; less suitable for frequent trading.

---

### comdirect

- **Trade fee:** €4.90 + 0.25% of order value
- **Savings plans:** 1.5% per rate for standard ETFs; promotional ETFs free
- **Custody fee:** none (for accounts with at least 2 trades/quarter or Sparplan active; otherwise €3.90/month)
- **Freistellungsauftrag:** supported
- **Tax reporting:** Jahressteuerbescheinigung
- **Regulation:** BaFin (Germany)
- **URL:** https://comdirect.de

**Best for:** Users who want a full-service bank with brokerage; higher fees than neo-brokers.

---

## 2. Foreign Brokers (Tax Comparison)

### Trading212

- **Trade fee:** FREE (no commission for stocks/ETFs)
- **Custody fee:** none
- **FX fee:** 0.15% for currency conversion
- **Freistellungsauftrag:** NOT supported (non-German entity)
- **Tax withholding:** none — investor is fully responsible
- **Tax reporting (Germany):** provides a downloadable tax report, but it is NOT a Jahressteuerbescheinigung and requires manual cross-check; user must file Anlage KAP and Anlage KAP-INV manually
- **Regulation:** FCA (UK), BaFin (EU entity separately)
- **URL:** https://trading212.com

### Interactive Brokers (IBKR)

- **Trade fee:** tiered from $0.005/share (US); EUR 1.25 min for EU stocks (IBKR Lite differs)
- **Custody fee:** none (with monthly commissions ≥ $10; otherwise account maintenance fee applies)
- **Freistellungsauftrag:** NOT supported (non-German entity)
- **Tax withholding:** none for German capital gains tax — all self-reported
- **Tax reporting (Germany):** no Jahressteuerbescheinigung; user must fill Anlage KAP and KAP-INV manually using IBKR's annual activity statement
- **Regulation:** BaFin (Germany entity), FCA (UK entity), SEC/FINRA (US)
- **URL:** https://www.interactivebrokers.eu

---

## 3. Tax Reporting Quality (BROKER-04)

This section explains the key compliance difference between German and foreign brokers for German tax residents.

### German Brokers (Trade Republic, Scalable Capital, ING, comdirect)

German-regulated brokers automatically:

1. **Withhold Abgeltungssteuer** (25% + 5.5% Solidaritätszuschlag = 26.375%) at source on all capital income
2. **Apply Freistellungsauftrag** — no tax withheld up to the allocated amount (up to €1,000 single / €2,000 married, Sparerpauschbetrag since 2023)
3. **Generate Jahressteuerbescheinigung** — the official tax certificate required for ELSTER submission or pre-filled tax return; covers all capital income, tax withheld, and Kirchensteuer
4. **Handle Vorabpauschale** — automatically deduct the annual prepayment amount in January for accumulating ETFs, based on the BMF-published Basiszins

**Result:** In most cases, no Anlage KAP filing is required for German broker accounts. The Finanzamt already has full information.

### Foreign Brokers (Trading212, IBKR, and others)

Foreign brokers outside the German withholding system require manual action:

1. **No withholding** — capital gains tax, dividend tax, and Vorabpauschale are entirely the investor's responsibility
2. **No Freistellungsauftrag** — the Sparerpauschbetrag cannot be assigned; allocate it entirely to German brokers instead
3. **No Jahressteuerbescheinigung** — German Finanzamt does not receive automatic reporting; investor files Anlage KAP and Anlage KAP-INV using the broker's annual activity statement as source material
4. **Vorabpauschale must be calculated manually** — investor computes the prepayment for accumulating ETFs held at foreign brokers and declares it on Anlage KAP-INV

**Practical implication:** A German-resident investor using IBKR or Trading212 as their sole broker must file Anlage KAP regardless of whether gains exceed the Sparerpauschbetrag. This is a meaningful compliance overhead compared to German brokers.

---

## 4. Comparison Summary

| Broker | Trade Fee | Sparplan | Custody | Freistellungsauftrag | Jahressteuerbescheinigung |
|--------|-----------|----------|---------|----------------------|--------------------------|
| Trade Republic | €1.00/order | Free | None | Yes | Yes (automatic) |
| Scalable Capital FREE | Free ≥€250 / €0.99 below | Free | None | Yes | Yes |
| Scalable Capital PRIME+ | €4.99/month flat | Free | None | Yes | Yes |
| ING | €4.90 + 0.25% | 1.75% (promo: free) | None | Yes | Yes |
| comdirect | €4.90 + 0.25% | 1.5% (promo: free) | None | Yes | Yes |
| Trading212 | Free | Free | None | No | No |
| IBKR | Tiered from €1.25 | No | None | No | No |
