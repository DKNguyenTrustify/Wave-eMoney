# AI Council Prompt v2 — v12 Model Selection (FREE-tier focused)

**Purpose:** Send this prompt verbatim to 6 AIs (Claude, GPT, Gemini, Grok, DeepSeek, Perplexity). Collect responses. Synthesize to pick the model for v12 migration.

**Key reframe vs v1:** Primary constraint is ZERO out-of-pocket cost during demo + pre-production phase. Pay-as-you-go (Anthropic Console) risks demo disruption on rate limit + personal billing awkwardness. We want free tier now with clean migration path to AWS Bedrock when Trustify funds production.

**Expected turnaround:** 30-60 min end-to-end.

---

## Prompt to paste

```
You are a senior data engineer advising on a cost-constrained LLM choice for a production pipeline that's currently in DEMO + PRE-PRODUCTION phase.

Our system:
- Myanmar EMI (Electronic Money Issuer) salary disbursement pipeline for Wave Money
- n8n Cloud workflow: Outlook email trigger → text extraction + attachment vision → single Claude-style messages.create call per email → Vercel webhook → Supabase + dashboard
- Email volume: ~500-1000/month production, burst 3-5 emails within 60 seconds during peak
- Each email: 1 attachment (JPG/PNG/PDF), payroll with 4-50 employees
- Current stack: Groq llama-3.3-70b (text) + Groq llama-4-scout (image vision) + Gemini 2.5 Flash (PDF vision) — ALL FREE tier
- Target: simplify to single provider for cleaner architecture in v12

Key extraction needs:
(a) Text from email body — structured JSON: company, amount, payment_date, payroll_period, initiator_name, purpose, cost_center, approvers[]
(b) Vision from attachment — employee list (name + phone/account + amount), corporate_wallet, currency
(c) Myanmar handwriting OCR with mixed Burmese script + English (real use case, currently 85% confidence)
(d) JSON-only output, no markdown, no prose

HARD CONSTRAINTS:
1. ZERO out-of-pocket cost during demo + pre-production (next 4-8 weeks)
   - Pay-as-you-go Anthropic Console = $5 free credit then billing = NOT acceptable for demo runway
   - Grok + Gemini free tiers are currently working — don't lose that capability
2. Must survive burst load: 5 emails arriving within 60 seconds should NOT trigger rate-limit errors
3. Myanmar handwriting quality must not regress from current ~85% Vision confidence on llama-4-scout
4. Must support image + PDF in a single model call (eliminate dual-path complexity from Groq/Gemini split)
5. Must have a CLEAN migration path to AWS Bedrock when production infrastructure lands (~2-3 weeks out, Rita's directive)

Candidate models (include any I missed):
A. Gemini 2.5 Flash — Google AI Studio free (1500/day, 15 RPM)
B. Gemini 2.0 Flash — same
C. Groq llama-3.3-70b-versatile (free, 30 RPM)
D. Groq llama-4-scout (free, vision)
E. DeepSeek V3 — api.deepseek.com free tier
F. Claude Haiku 4.5 — Anthropic Console, $5 credit only
G. Claude Haiku 3.5 — Anthropic Console, $5 credit only
H. Claude Sonnet 3.5 — Anthropic Console, $5 credit only
I. Amazon Nova Lite — Bedrock (AWS account required; free tier credits apply)
J. Amazon Nova Pro — Bedrock
K. Mistral Large — via OpenRouter or Mistral free tier
L. Llama 3.3 70B on Together AI / OpenRouter (some free)
M. (your suggestion if better)

Score each candidate on a 1-10 scale for:
(a) TRUE free-tier availability for 1000 calls/month production volume (not trial credit)
(b) Rate limit headroom for 5-burst-in-60-seconds (RPM tier)
(c) Myanmar handwriting OCR quality (from what you know about multilingual vision)
(d) Structured JSON output reliability
(e) Image + PDF support in a single messages call
(f) Migration path to AWS Bedrock (same model family accessible)
(g) Prompt caching support (~500-token system prompt reused per call)

Then answer these TWO questions:

Q1: If we MUST stay on free tier during demo (next 4-8 weeks), which single model OR hybrid (e.g., Gemini for vision + Llama for text) gives us the best balance of quality + zero-cost + rate limit tolerance?

Q2: When Trustify approves AWS Bedrock production budget (~Q2 estimate), what's the cleanest migration path from your Q1 answer to production-ready Bedrock deployment?

Reply format:
1. Score table (models vs 7 criteria)
2. Top 3 free-tier picks with rationale
3. Answer Q1 (~100 words)
4. Answer Q2 (~100 words)
```

---

## What I'll do with the 6 responses

1. Count votes per model
2. Compare Q1/Q2 reasoning
3. Flag any disagreements worth web-searching
4. Write synthesis with confidence level → we pick together → v12 execution

---

## Why this reframe is smarter

**Before:** "Pick the best Claude variant" → implicit assumption that paid API is fine → demo risk + awkward billing.

**After:** "Pick the best free-tier-now + Bedrock-later path" → respects real constraint → demo runs smooth → clean upgrade when infra ready.

The v12 migration from Groq+Gemini might actually be "stay on Gemini-only" or "consolidate on Groq-only" rather than "go to Claude now." That's OK — the goal is architectural cleanup (single provider), not Claude-at-all-costs.

**Key insight:** Vinh's Apr 13 directive "switch to Claude" was framed as "because Bedrock supports Claude." But during pre-production, we can use ANY model that migrates cleanly. Gemini might migrate to Vertex AI on GCP (not Bedrock — drops Gemini). Groq might migrate to Llama on Bedrock (same model weights, different provider). Claude directly migrates within Bedrock. All three have different migration stories.

The Council helps us see that clearly.

---

## Related memory files

- `project_claude_migration_initiative.md` — original Apr 13 Vinh+Rita directive
- `project_v12_acceptance_criteria.md` — quality bar v12 must clear regardless of model
- `feedback_infrastructure_first.md` — Rita's "infra > LLM" priority
