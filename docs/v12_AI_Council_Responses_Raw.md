# AI Council Raw Responses — v12 Model Selection

**Collected:** 2026-04-15 (during KAN-36 delivery sprint)
**Prompt source:** `docs/v12_AI_Council_Prompt.md` (v1 — focused on Claude variants, pre-Gemini-consolidation reframe)
**Purpose:** Raw preservation for internal reference. Synthesis + decision in `v12_AI_Council_Findings.md`.
**Status:** Research artifact. NOT driving current execution (team decided Apr 15 meeting to stay on Gemini+Groq free tier).

---

## ⚠️ Important context

This Council was run with the v1 prompt that asked "which Claude variant?" — assuming pay-as-you-go Anthropic API was acceptable.

Since running this Council, the team meeting (Apr 15, 1:30 PM) reframed:
- Stick with Gemini + Groq free tier for demo + pre-production
- Bedrock LLM research = Tracy's long-term scope, separate from our engineering work
- v12a = Gemini consolidation (drop Groq), NOT Claude migration
- Full Claude migration deferred until Bedrock infrastructure ready (~Q2, Tin's domain)

So these responses are **preserved intelligence for the future migration**, not the input to v12a scope.

---

## ChatGPT

### Score Table (1–10)

| Model             | (a) OCR Myanmar Handwriting | (b) JSON Reliability | (c) Rate Limit Headroom | (d) Cost Efficiency | (e) Bedrock Availability | (f) Prompt Caching | (g) Vision+PDF Single Call |
| ----------------- | --------------------------- | -------------------- | ----------------------- | ------------------- | ------------------------ | ------------------ | -------------------------- |
| Claude Haiku 4.5  | 7                           | 8                    | 10                      | 10                  | 7                        | 9                  | 9                          |
| Claude Haiku 3.5  | 6                           | 7                    | 10                      | 10                  | 9                        | 8                  | 8                          |
| Claude Sonnet 3.5 | 8                           | 9                    | 7                       | 7                   | 10                       | 9                  | 9                          |
| Claude Sonnet 3.7 | 8                           | 9                    | 7                       | 7                   | 9                        | 9                  | 9                          |
| Claude Sonnet 4.0 | 9                           | 9                    | 6                       | 6                   | 8                        | 9                  | 9                          |
| Claude Sonnet 4.5 | 9                           | 10                   | 6                       | 6                   | 7                        | 10                 | 10                         |
| Claude Sonnet 4.6 | 9                           | 10                   | 6                       | 6                   | 6                        | 10                 | 10                         |
| Claude Opus 4.6   | 10                          | 10                   | 3                       | 2                   | 5                        | 10                 | 10                         |
| Amazon Nova Pro   | 7                           | 8                    | 8                       | 8                   | 10                       | 7                  | 8                          |
| Amazon Nova Lite  | 6                           | 7                    | 9                       | 10                  | 10                       | 7                  | 7                          |

### Top 3
1. Claude Sonnet 3.5 — "Best balance across all constraints: strong multilingual vision, high JSON determinism, proven stability. Already widely deployed on Bedrock → lowest migration friction."
2. Claude Haiku 4.5 — "Excellent cost + rate limit headroom. Slight drop in handwriting OCR vs Sonnet tier."
3. Claude Sonnet 4.5 — "Best-in-class structured output + vision reasoning. But cost + tighter rate limits make it risky."

### Final pick: **Claude Sonnet 3.5**
Rationale: meets 85% Myanmar target with better multilingual vision than Haiku, high JSON schema adherence, fits Tier 1 rate limits, viable cost with prompt caching, fully available on Bedrock today, avoids model revalidation later.

---

## Gemini

### Score Table

| Model | (a) Myanmar OCR | (b) JSON Reliability | (c) Burst Headroom | (d) Cost Efficiency | (e) Bedrock Avail. | (f) Prompt Caching | (g) V+PDF Parity |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Claude Haiku 4.5 | 8 | 9 | 10 | 10 | 10 | 10 | 10 |
| Claude Haiku 3.5 | 6 | 8 | 10 | 10 | 10 | 10 | 10 |
| Claude Sonnet 3.5 | 7 | 9 | 8 | 8 | 10 | 10 | 10 |
| Claude Sonnet 3.7 | 8 | 9 | 8 | 8 | 10 | 10 | 10 |
| Claude Sonnet 4.0 | 8 | 9 | 8 | 8 | 10 | 10 | 10 |
| Claude Sonnet 4.5 | 9 | 10 | 8 | 8 | 10 | 10 | 10 |
| Claude Sonnet 4.6 | 10 | 10 | 8 | 7 | 9 | 10 | 10 |
| Claude Opus 4.6 | 10 | 10 | 4 | 5 | 9 | 10 | 10 |
| Amazon Nova Pro | 7 | 8 | 7 | 8 | 10 | 7 | 8 |
| Amazon Nova Lite | 5 | 7 | 9 | 10 | 10 | 7 | 8 |

### Top 3
1. Claude Sonnet 4.6 — "Only model that guarantees zero compromises on handwritten Burmese OCR constraint while leaving ample Tier 1 headroom."
2. Claude Haiku 4.5 — "Speed/cost champion. Crushes rate limit and budget."
3. Claude Sonnet 4.5 — "Safe fallback, fully saturated across all Bedrock regions."

### Final pick: **Claude Sonnet 4.6**
Rationale: Zero-compromise choice. Handles both images + PDFs in single call. Prompt caching support. ~$5.40/month at our volume. Drop-in replacement for current dual-path.

---

## DeepSeek

### Score Table (with totals)

| Model | OCR MY | JSON | RPM | Cost | Bedrock | Caching | V+PDF | **Total** |
|:------|:------:|:----:|:---:|:----:|:-------:|:-------:|:-----:|:---------:|
| Claude Haiku 4.5 | 5 | 9 | 10 | 10 | 7 | 10 | 8 | 59 |
| Claude Haiku 3.5 | 4 | 9 | 10 | 10 | 10 | 10 | 8 | **61** |
| Claude Sonnet 3.5 | 9 | 9 | 7 | 5 | 10 | 10 | 9 | 59 |
| Claude Sonnet 3.7 | 9 | 9 | 7 | 5 | 8 | 10 | 9 | 57 |
| Claude Sonnet 4.0 | 9 | 9 | 6 | 5 | 5 | 10 | 9 | 53 |
| Claude Sonnet 4.5 | 9 | 9 | 6 | 5 | 4 | 10 | 9 | 52 |
| Claude Sonnet 4.6 | 9 | 9 | 6 | 5 | 10 | 10 | 9 | 58 |
| Claude Opus 4.6 | 10 | 9 | 3 | 2 | 10 | 10 | 9 | 53 |
| Amazon Nova Pro | 6 | 8 | 8 | 8 | 10 | 6 | 7 | 53 |
| Amazon Nova Lite | 4 | 7 | 9 | 10 | 10 | 6 | 6 | 52 |

### Top 3
1. Claude Haiku 3.5 (61 pts) — lowest cost + rate headroom + Bedrock
2. Claude Haiku 4.5 (59 pts) — better safety/alignment, not on Bedrock yet
3. Claude Sonnet 4.6 (58 pts) — strongest Bedrock-readiness + proven OCR

### Final pick: **Claude Sonnet 4.6**
Rationale: Eliminates migration rework (Bedrock today). Vision benchmarks show Sonnet-class leads on handwriting OCR. ~$20/month at volume. Single call handles image + PDF. Prompt caching ~90% discount. Trade ~$15/mo extra vs Haiku for OCR reliability Haiku may not sustain.

---

## Grok

### Score Table

| Model | OCR MY | JSON | Burst | Cost | Bedrock | Caching | V+PDF |
|-------|--------|------|-------|------|---------|---------|-------|
| Claude Haiku 4.5 | 7 | 9 | 10 | 9 | 10 | 10 | 10 |
| Claude Haiku 3.5 | 5 | 8 | 10 | 10 | 10 | 10 | 9 |
| Claude Sonnet 3.5 | 6 | 9 | 8 | 7 | 10 | 10 | 9 |
| Claude Sonnet 3.7 | 7 | 9 | 8 | 7 | 10 | 10 | 9 |
| Claude Sonnet 4.0 | 8 | 10 | 8 | 7 | 10 | 10 | 10 |
| Claude Sonnet 4.5 | 8.5 | 10 | 8 | 7 | 10 | 10 | 10 |
| **Claude Sonnet 4.6** | **9** | **10** | **8** | **7** | **10** | **10** | **10** |
| Claude Opus 4.6 | 9 | 10 | 6 | 5 | 10 | 10 | 10 |
| Amazon Nova Pro | 8 | 9 | 9 | 9 | 10 | 9 | 10 |
| Amazon Nova Lite | 6 | 8 | 10 | 10 | 10 | 9 | 10 |

### Top 3
1. Claude Sonnet 4.6 — "Highest OCR parity with current Llama-4-scout baseline + full feature parity + Bedrock today"
2. Claude Haiku 4.5 — "Best cost/rate trade-off if OCR tolerance can drop to ~70–75%"
3. Amazon Nova Pro — "Strong runner-up for immediate Bedrock-native cost + multimodal"

### Final pick: **Claude Sonnet 4.6**
Rationale: Cites IDP benchmarks — Sonnet 4.6 matches Opus 4.6 on handwriting/tables (~80 pts), beats Haiku 4.5 by >10 pts. Structured JSON in one call, full prompt caching support, Tier-1 burst far above 5 RPM, <$50/mo with caching, zero-code Bedrock migration.

---

## Claude (Anthropic)

### Score Table

| Model | OCR MY | JSON | Burst RPM | Cost @1M | Bedrock | Caching | V+PDF |
|-------|--------|------|-----------|----------|---------|---------|-------|
| Haiku 4.5 | 6 | 8 | 10 | 9 | 10 | 10 | 9 |
| Haiku 3.5 | 4 | 7 | 10 | 9 | 10 | 9 | 6 |
| Sonnet 3.5 | 6 | 8 | 8 | 7 | 10 | 9 | 9 |
| Sonnet 3.7 | 6.5 | 8.5 | 8 | 7 | 10 | 9 | 10 |
| Sonnet 4.0 | 7.5 | 9 | 8 | 7 | 8 (deprecated) | 9 | 10 |
| Sonnet 4.5 | 8.5 | 9 | 8 | 7 | 10 | 10 | 10 |
| **Sonnet 4.6** | **9** | **9.5** | **8** | **7** | **10** | **10** | **10** |
| Opus 4.6 | 9.5 | 9.5 | 6 | 5 | 10 | 10 | 10 |
| Nova Pro | 5 | 7 | 9 | 9 | 10 | 7 | 8 |
| Nova Lite | 3 | 6 | 10 | 10 | 10 | 7 | 7 |

### Top 3
1. Claude Sonnet 4.6 — "Best multilingual vision in the Claude line at flat $3/$15 per MTok. Full PDF + image parity, native caching, Bedrock APAC Singapore via Global CRIS. ~$5/month at 1M tokens — 10× headroom under $50 ceiling."
2. Claude Haiku 4.5 — "Cheapest path that's still defensible. Worth A/B testing on Burmese."
3. Claude Sonnet 4.5 — "Functionally equivalent to 4.6. Fine fallback."

### Final pick: **Claude Sonnet 4.6** (`claude-sonnet-4-6`)
Rationale: "Two criteria — cost and rate limits — aren't actually binding at 5 RPM/1M tokens. Decision collapses to: which maximizes Burmese handwriting accuracy while preserving caching + PDF-in-call + Bedrock-APAC portability for Q2 migration. Sonnet 4.6 wins on all four."

---

## Qwen

### Score Table

| Model | OCR MY | JSON | RPM | Cost | Bedrock | Caching | V+PDF |
|-------|--------|------|-----|------|---------|---------|-------|
| Claude Haiku 4.5 | 5 | 8 | 9 | 9 | 7 | 10 | 8 |
| Claude Haiku 3.5 | 4 | 7 | 10 | 10 | 10 | 10 | 8 |
| Claude Sonnet 3.5 | 8 | 9 | 8 | 9 | 10 | 10 | 10 |
| Claude Sonnet 3.7 | 8 | 9 | 7 | 8 | 7 | 10 | 10 |
| Claude Sonnet 4.0 | 9 | 9 | 7 | 7 | 8 | 10 | 10 |
| Claude Sonnet 4.5 | 9 | 10 | 6 | 6 | 6 | 10 | 10 |
| Claude Sonnet 4.6 | 9 | 10 | 6 | 5 | 5 | 10 | 10 |
| Claude Opus 4.6 | 10 | 10 | 5 | 3 | 5 | 10 | 10 |
| Amazon Nova Pro | 7 | 8 | 8 | 7 | 10 | 6 | 8 |
| Amazon Nova Lite | 6 | 7 | 10 | 10 | 10 | 6 | 7 |

### Top 3
1. Claude Sonnet 3.5 — "Only model clearing 85% Burmese handwriting floor natively + strict JSON + full Bedrock GA across US/APAC + mature cache_control"
2. Claude Sonnet 4.0 — "Marginal uplift over 3.5 but Bedrock availability staggered"
3. Claude Haiku 4.5 — "Excellent cost/RPM but drops 10–15% on Burmese mixed-script vs Sonnet"

### Final pick: **Claude Sonnet 3.5**
Rationale: Only candidate simultaneously clearing 85% threshold + strict JSON + unified image+PDF. ~$8-14/month at 1M tokens. GA on Bedrock across all US/APAC regions with identical cache_control semantics. 4.x models have staggered Bedrock parity.

---

## Perplexity

### Score Table (with source citations)

| Model | OCR MY | JSON | RPM | Cost | Bedrock | Caching | V+PDF |
|-------|--------|------|-----|------|---------|---------|-------|
| Claude Haiku 4.5 | 8 | 9 | 10 | 10 | 10 | 10 | 10 |
| Claude Haiku 3.5 | 7 | 8 | 10 | 10 | 8 | 9 | 10 |
| Claude Sonnet 3.5 | 9 | 10 | 8 | 8 | 10 | 10 | 10 |
| Claude Sonnet 3.7 | 9 | 10 | 8 | 8 | 10 | 10 | 10 |
| Claude Sonnet 4.0 | 9 | 10 | 8 | 7 | 10 | 10 | 10 |
| Claude Sonnet 4.5 | 9 | 10 | 8 | 7 | 10 | 10 | 10 |
| Claude Sonnet 4.6 | 10 | 10 | 8 | 7 | 10 | 10 | 10 |
| Claude Opus 4.6 | 10 | 10 | 6 | 4 | 10 | 10 | 10 |
| Amazon Nova Pro | 8 | 8 | 9 | 6 | 10 | 5 | 10 |
| Amazon Nova Lite | 7 | 7 | 9 | 9 | 10 | 5 | 10 |

### Top 3
1. Claude Haiku 4.5 — "Tops cost, rate limits, caching; strong vision for low-complexity extraction"
2. Claude Sonnet 4.6 — "Best OCR/JSON; rate limits sufficient for 5/min bursts"
3. Claude Haiku 3.5 — "Budget king but older vision lags on handwriting"

### Final pick: **Claude Haiku 4.5**
Rationale: Tier 1 50 RPM handles 5-email bursts comfortably. ~$0.25/1M input. Native vision+PDF in single call. Prompt caching slashes 500-token system prompt 90%. Bedrock-ready. Slightly lower accuracy than Sonnet 4.6 but bursts/cost prioritize Haiku.
