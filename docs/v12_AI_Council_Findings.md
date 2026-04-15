# AI Council Findings — v12 Model Selection (Internal Synthesis)

**Purpose:** Internal synthesis of 7 AI Council responses (ChatGPT, Gemini, DeepSeek, Grok, Claude, Qwen, Perplexity). Preserved for future reference when Trustify funds Bedrock production migration.

**Status:** Research artifact. **NOT driving current engineering.** Team meeting Apr 15, 1:30 PM decided to stay on Gemini + Groq free tier. v12a = Gemini consolidation (debt kill). Full Claude migration deferred until Bedrock infrastructure ready — Tracy owns that research independently for long-term direction.

**Raw responses:** `v12_AI_Council_Responses_Raw.md`

---

## 🗳️ Vote tally — Final pick per AI

| AI | Final pick | Confidence signal |
|---|---|---|
| ChatGPT | Claude Sonnet 3.5 | Values Bedrock maturity over version |
| Gemini | **Claude Sonnet 4.6** | Values OCR quality |
| DeepSeek | **Claude Sonnet 4.6** | Values single-call migration readiness |
| Grok | **Claude Sonnet 4.6** | Cites IDP benchmarks for vision |
| Claude (Anthropic) | **Claude Sonnet 4.6** | Cost/rate limits not binding, OCR quality wins |
| Qwen | Claude Sonnet 3.5 | Bedrock GA across all regions with 3.5 |
| Perplexity | Claude Haiku 4.5 | Values rate/cost over marginal OCR |

### Winner: **Claude Sonnet 4.6 (4 of 7 votes, majority)**

Runner-ups:
- Claude Sonnet 3.5 (2 votes) — mentioned specifically for Bedrock maturity
- Claude Haiku 4.5 (1 vote) — rate/cost focused

### Clear losers (zero votes):
- Claude Opus 4.6 — too expensive + rate-limited
- Claude Sonnet 3.7, 4.0, 4.5 — all dominated by 4.6
- Amazon Nova Pro / Lite — weaker Burmese OCR, non-Anthropic caching semantics

---

## 📊 Aggregate scores — averaged across 7 AIs

Averaging scores (excluding DeepSeek total column which used different methodology):

| Model | OCR MY | JSON | Rate | Cost | Bedrock | Caching | V+PDF | **Avg** |
|---|---|---|---|---|---|---|---|---|
| Claude Sonnet 4.6 | **9.3** | **9.9** | 7.4 | 6.1 | 8.6 | **10.0** | **9.9** | **8.7** |
| Claude Sonnet 4.5 | 8.8 | 9.9 | 7.1 | 6.1 | 7.9 | **10.0** | **9.9** | 8.5 |
| Claude Sonnet 3.5 | 7.6 | 9.0 | 7.7 | 7.3 | **10.0** | 9.7 | 9.6 | 8.7 |
| Claude Sonnet 4.0 | 8.6 | 9.3 | 7.3 | 6.6 | 8.4 | 9.7 | 9.7 | 8.5 |
| Claude Sonnet 3.7 | 7.8 | 9.1 | 7.4 | 7.1 | 9.3 | 9.7 | 9.6 | 8.6 |
| Claude Haiku 4.5 | 6.6 | 8.6 | **9.7** | **9.6** | 9.1 | 9.9 | 9.1 | 8.9 |
| Claude Opus 4.6 | **9.8** | 9.8 | 4.7 | 3.7 | 8.4 | **10.0** | 9.7 | 8.0 |
| Claude Haiku 3.5 | 5.1 | 7.7 | **10.0** | 9.9 | 9.4 | 9.4 | 8.3 | 8.5 |
| Amazon Nova Pro | 6.9 | 8.0 | 8.4 | 7.6 | **10.0** | 6.7 | 8.1 | 7.9 |
| Amazon Nova Lite | 5.3 | 7.0 | 9.4 | 9.9 | **10.0** | 6.9 | 6.9 | 7.9 |

**Highest average score: Claude Haiku 4.5 (8.9)** — won on rate + cost but lost on OCR
**Highest weighted-for-OCR-priority: Claude Sonnet 4.6 (8.7)**
**Highest Bedrock-ready: Claude Sonnet 3.5 (8.7)** — perfect Bedrock score

---

## 🧠 Key consensus insights

All 7 AIs agreed on these points:

### 1. Rate limits are NOT the binding constraint
At 5 RPM peak and ~1000 emails/month, Tier 1 limits of any Claude model suffice. This was over-weighted in the prompt — turns out it's not a real tiebreaker.

### 2. Cost is NOT binding at our volume
Even Sonnet 4.6 at $3/$15 per MTok lands ~$5-20/month. Well under $50 budget. Haiku saves ~$10-15/month for lower quality — not worth the OCR risk.

### 3. Prompt caching is universally supported on Claude 4.x line
~90% discount on repeated system prompts. Our 500-token prompt benefits massively.

### 4. Image + PDF in single `messages.create` call is universal on Claude 4.x
Eliminates the dual-path complexity we have today (Groq for images, Gemini for PDFs).

### 5. Myanmar Burmese handwriting OCR favors LARGER multilingual models
Haiku consistently penalized by ~2-3 points on OCR metric across all AIs. Sonnet/Opus favored. This is where Claude/Grok/Gemini/DeepSeek split from Perplexity.

### 6. Bedrock availability varies between AIs' training data
- Some say Sonnet 4.6 is on Bedrock since Feb 2026 (DeepSeek, Grok, Claude, Perplexity)
- Others penalize Sonnet 4.6's Bedrock availability (ChatGPT, Qwen, Gemini slightly)
- Sonnet 3.5 universally scored 10/10 on Bedrock (mature, stable, GA in all regions)

---

## 🎯 Intelligence for future migration decision

If/when Trustify funds Bedrock production, the decision is narrowed to:

### Primary candidate: **Claude Sonnet 4.6**
- 4 of 7 AIs picked it
- Best OCR in Claude line outside Opus
- Full single-call vision + PDF parity
- Full prompt caching
- Cost ~$5-20/month at our volume
- Available on Bedrock (majority consensus)

### Safe fallback: **Claude Sonnet 3.5**
- 2 of 7 AIs picked it for Bedrock maturity
- All AIs gave it 10/10 Bedrock availability
- Slightly older but proven
- Pick this if Sonnet 4.6 Bedrock availability turns out unstable in target APAC region

### Budget alternative: **Claude Haiku 4.5**
- 1 AI picked, others ranked it 2nd or 3rd
- Cheapest Bedrock-ready Claude option
- REQUIRES A/B test on Burmese handwriting before commit — ~10-15% OCR risk per Qwen/DeepSeek
- Good for cost-sensitive deployment IF OCR holds

### Not recommended
- Opus 4.6 — overkill, rate-limited, expensive
- Sonnet 3.7 / 4.0 / 4.5 — dominated by 4.6 (newer + same price)
- Nova Pro / Lite — weaker Burmese, non-Anthropic caching semantics

---

## 🛠️ Recommended migration sequence (when budget lands)

**Phase 0 — Prep (before Bedrock access ready)**
- Use Anthropic direct API (console.anthropic.com) $5 free credit
- Build + test v12 with Sonnet 4.6 on ~50 real tickets
- Validate OCR quality ≥85% on Myanmar handwriting samples

**Phase 1 — Production on Anthropic direct**
- Trustify-owned API key (escalate before this)
- Monitor cost + rate limits for 30 days
- Build a fallback-to-Haiku path if Sonnet 4.6 becomes cost-prohibitive at real volume

**Phase 2 — Migration to Bedrock**
- Bedrock infra live (Tin's deliverable, ~Q2)
- Swap endpoint URL from `api.anthropic.com/v1/messages` to `bedrock-runtime.<region>.amazonaws.com`
- Swap auth from Anthropic API key to AWS SigV4
- Keep model ID `claude-sonnet-4-6` (or equivalent Bedrock slug `anthropic.claude-sonnet-4-6-20260101-v1:0` — whatever AWS uses at that date)
- Zero-code migration if Sonnet 4.6 is chosen

---

## ⚠️ Disagreements worth noting

### Sonnet 3.5 vs 4.6 debate
ChatGPT + Qwen picked 3.5 despite newer 4.6 existing. Their argument: Bedrock maturity + regional availability. Other AIs dismissed this as FUD since Sonnet 4.6 is reportedly GA on Bedrock since Feb 2026.

**Resolution for future decision:** Check AWS Bedrock console at migration time. If Sonnet 4.6 is stable in APAC region (Singapore / Tokyo), use it. If APAC lag or instability, fall back to Sonnet 3.5.

### OCR scoring variance
Scores for Sonnet 3.5 on OCR Myanmar varied 6-9. DeepSeek and Qwen claimed 9 (strong), others 6-7. No peer-reviewed benchmark resolved this.

**Resolution for future decision:** Run real Myanmar handwriting samples (we have 3: Win's real sample + 2 Grok-generated) through each candidate before final commit. A/B test is the only trustworthy signal.

### Haiku viability for Burmese handwriting
Perplexity claimed 8/10 OCR for Haiku 4.5. Most others said 5-7. Large disagreement.

**Resolution for future decision:** A/B test is mandatory before committing to Haiku. If it works, big cost savings. If not, Sonnet 4.6 is the safe default.

---

## 📝 Why we're not using this now

Team decision Apr 15 meeting:
1. **Demo stage doesn't justify LLM spend.** Gemini free tier + Groq free tier both work. Cost savings: ~$10-50/month.
2. **Rate limits haven't been real problem yet.** Haven't hit them in testing.
3. **Trustify hasn't approved production AI budget.** Can't commit to pay-as-you-go Anthropic.
4. **Bedrock infrastructure 2-3 weeks out (Tin).** No point migrating pipeline twice.
5. **Tracy owns long-term Bedrock + LLM research.** Engineering (DK) shouldn't duplicate her scope.
6. **v12a = Gemini consolidation** instead. Same architectural benefit (single provider) at zero cost.

When these conditions change — specifically when Tin's Bedrock infra lands and Trustify commits budget — this synthesis is the starting point for the real migration.

---

## 🔗 Related docs

- `docs/v12_AI_Council_Prompt.md` — the prompt that produced these responses
- `docs/v12_AI_Council_Responses_Raw.md` — raw responses preserved
- `memory/project_v12_acceptance_criteria.md` — quality bar any v12 variant must meet
- `memory/project_claude_migration_initiative.md` — original Apr 13 Vinh+Rita directive
- `memory/feedback_infrastructure_first.md` — Rita's "infra > LLM" priority
