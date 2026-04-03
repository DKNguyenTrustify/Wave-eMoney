# Monday Demo Plan — April 7, 10AM

## Goal

Present to Rita + Minh + team a **working end-to-end EMI disbursement pipeline** that shows:
1. Email comes in → AI parses it → ticket auto-created on dashboard
2. Visual workflow diagram everyone can follow
3. Dashboard handles the full 7-step flow (already built)

---

## Problem: Gemini API Is Dead

Google Gemini free tier has `limit: 0` for all models — even 2-3 calls exceed quota. This blocks the entire n8n AI pipeline.

### Solution: Switch to Groq API (Free Tier)

| | Gemini (broken) | Groq (replacement) |
|---|---|---|
| Free tier | limit: 0 (unusable) | 30 req/min, 14,400 req/day |
| Model | gemini-2.0-flash | llama-3.3-70b-versatile |
| Speed | ~2s | ~0.5s (fastest inference) |
| JSON mode | responseMimeType | response_format: json_object |
| API format | Google proprietary | OpenAI-compatible |
| Sign up | console.cloud.google.com | console.groq.com (free, instant) |

**Effort to swap: ~30 minutes** — change the HTTP Request URL + body format + response parser.

### How to Get Groq API Key

1. Go to `console.groq.com`
2. Sign up with Google account (instant, no credit card)
3. Create API key → copy it
4. Paste into n8n HTTP Request node URL header

---

## What to Do (Priority Order)

### Day 1: Thursday April 3 (Today)

| # | Task | Effort | Return | Details |
|---|------|--------|--------|---------|
| 1 | Get Groq API key | 5 min | Unblocks everything | Sign up at console.groq.com |
| 2 | Rewrite n8n pipeline with Groq | 30 min | HIGH — AI parsing works again | See "n8n Rewrite" section below |
| 3 | Test full email → dashboard flow | 15 min | Confirms demo works | Send test email → check dashboard |

### Day 2-3: Friday-Saturday

| # | Task | Effort | Return | Details |
|---|------|--------|--------|---------|
| 4 | Polish Mermaid diagrams | 30 min | HIGH — visual presentation | Two diagrams already created (see below) |
| 5 | Prepare demo script | 30 min | HIGH — smooth presentation | Write step-by-step demo talking points |
| 6 | Add 2-3 realistic demo emails | 20 min | MEDIUM — impressive variety | Different companies, amounts, scenarios |

### Day 4: Sunday (Buffer)

| # | Task | Effort | Return | Details |
|---|------|--------|--------|---------|
| 7 | Dry run the full demo | 30 min | HIGH — catch issues early | Run through entire flow as if presenting |
| 8 | Fix any issues found | Variable | — | Buffer time |

### NOT doing (low return / high effort)

- Bank slip OCR (Minh said "later")
- Power BI integration (no access)
- Phases 7-9 (production only)
- Local LLM setup (Minh said "later")
- UI/UX overhaul (works fine for demo)

---

## n8n Pipeline Rewrite: Gemini → Groq

### Node 4: HTTP Request Changes

**Old (Gemini — broken):**
```
URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=API_KEY
Body: { contents: [{ parts: [{ text: prompt }] }], generationConfig: { responseMimeType: "application/json", temperature: 0.1 } }
Response path: candidates[0].content.parts[0].text
```

**New (Groq — free):**
```
URL: https://api.groq.com/openai/v1/chat/completions
Headers: Authorization: Bearer GROQ_API_KEY
Body: {
  model: "llama-3.3-70b-versatile",
  messages: [{ role: "user", content: prompt }],
  response_format: { type: "json_object" },
  temperature: 0.1
}
Response path: choices[0].message.content
```

### Node 5: Parse Response Changes

**Old (Gemini response):**
```javascript
let aiText = '';
if (d.candidates && d.candidates[0]) {
  aiText = d.candidates[0].content.parts[0].text || '';
}
```

**New (Groq/OpenAI response):**
```javascript
let aiText = '';
if (d.choices && d.choices[0]) {
  aiText = d.choices[0].message.content || '';
}
```

Everything else stays the same — prompt, authority matrix check, dashboard URL generation, routing.

---

## Visual Diagrams (Already Created)

Two Mermaid files ready to paste into [mermaid.live](https://mermaid.live):

1. **`EMI_System_Workflow.mmd`** — Full system workflow (Phase 1-6)
   - Shows the complete flow from client email to case closure
   - Color-coded by phase: navy (trigger), blue (AI), orange (finance), teal (e-money), green (monitoring)
   - Good for: team presentation, explaining the business logic

2. **`n8n_Pipeline_Diagram.mmd`** — n8n-specific pipeline
   - Shows the 8-node automation pipeline
   - Highlights Groq AI as the processing engine
   - Good for: technical discussion with Rita, explaining the automation layer

### How to Use

1. Open [mermaid.live](https://mermaid.live)
2. Copy-paste the `.mmd` file content
3. Export as PNG/SVG for slides
4. Or paste directly into a Markdown doc (GitHub renders Mermaid natively)

---

## Demo Script (Monday 10AM)

### Opening (2 min)
"This is our EMI disbursement pipeline. Let me show you the complete flow."
→ Show the EMI_System_Workflow diagram

### Live Demo (5 min)
1. Send a test email to the admin mailbox (pre-written)
2. Show n8n execution: Gmail Trigger → AI Parse → Ticket created
3. Open dashboard from the notification email link
4. Walk through: Intake → Finance Approval → E-Money → CSV files → Checker → Close

### Technical Q&A (3 min)
- "AI parsing uses Groq (Llama 3.3) — free tier, no cost"
- "Employee data stays in browser — never sent to cloud" (Minh's requirement)
- "n8n pipeline is modular — can swap to local LLM later"
- Show n8n_Pipeline_Diagram for technical detail

---

## Alignment with Rita's Workflow

| Rita's Phase | What We Demo | Status |
|---|---|---|
| Phase 1: Request Intake | Email → AI parsing → auto-ticket | Working (after Groq swap) |
| Phase 2+5: File Preparation | Dashboard generates all 7 CSV files | Working |
| Phase 3: Maker-Checker | Checker review with approve/reject | Working |
| Phase 4: Group Mapping | MapAgent/UnmapAgent for OTC | Working |
| Phase 6: Monitoring & Close | Simulated monitoring + close checklist | Working |
| Phases 7-9 | Not in scope for demo | Acknowledged |

### What Minh Flagged (Addressed)

- **Missing Steps 1-2**: Acknowledged in diagram — we show the email forwarding flow
- **No cloud for employee data**: Employee list parsing is 100% client-side
- **Flow first, AI later**: Flow is complete. AI is an enhancement layer.
- **Controlled mailbox**: Gmail Trigger watches one inbox — matches Minh's architecture
