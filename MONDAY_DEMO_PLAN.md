# Monday Demo Plan — April 7 + Tuesday Follow-up

## Status: READY FOR MONDAY

Pipeline v2.1 tested and working (April 3). All 4 of Vinh's showcase items confirmed. Showcase flow sent to Vinh.

---

## Monday Demo (v2 — Text Pipeline, PROVEN)

### What We Show (Vinh's 4 Items)

| # | Showcase Item | Status |
|---|--------------|--------|
| 1 | Client sends payroll email to control mailbox | DONE — Gmail Trigger |
| 2 | Pipeline fetches the email | DONE — n8n auto-fetch |
| 3 | Extract data + map to CSV | DONE — Groq AI + 7 Utiba CSVs |
| 4 | Create ticket + send to finance | DONE — Auto-ticket + notification email |

### Bonus (beyond what was asked)

- Authority matrix validation (Sales HOD + Finance Manager)
- 3 scenarios: NORMAL, MISSING_APPROVAL, OTC (SalaryToOTC)
- Maker-Checker review flow
- Email metadata: From, To, Date, attachments

### Demo Script (10 min)

**Opening (2 min)**
- Show Monday_Showcase_Flow diagram
- "Goal: replace manual payroll checking with AI automation"

**Live Demo (5 min)**
1. Show Gmail control mailbox
2. Send OTC test email live (Myanmar Jade Mining Corp)
3. Show n8n execution — all nodes green, ~2 seconds
4. Show AI extraction: company, amount, type, approvers, scenario
5. Open dashboard from notification email link
6. Walk: Intake → Finance approve → Generate CSVs → Checker → Close

**Q&A (3 min)**
- "AI uses Groq/Llama 3.3 — free tier, zero cost"
- "Employee data stays in browser, never to cloud" (Minh's requirement)
- "Pipeline is modular — swap LLM provider anytime"

### Monday Morning Warmup (30 min before call)

1. Open n8n, confirm v2 workflow is Published
2. Send one test email (Golden Star — NORMAL) to warm up
3. Verify notification arrives at both inboxes
4. Open dashboard URL — confirm ticket loaded
5. Have Myanmar Jade OTC email ready to send live

---

## Tuesday Follow-up (v3 — Vision Pipeline, IF NEEDED)

### What v3 Adds

If Monday demo doesn't impress enough, Tuesday shows the next evolution:

1. **Attachment extraction** — AI reads bank slip images attached to emails
2. **Amount cross-validation** — "Email says 128M MMK, document says 128M MMK — MATCH"
3. **New scenario: AMOUNT_MISMATCH** — flags when document amount differs from email
4. **Document signer extraction** — vision reads authorized signatories from images

### Architecture (1 new node, 2 modified)

```
Gmail Trigger (+ Download Attachments)
  → Prepare for AI v3 (+ rate limiter + binary→base64)
  → Groq Text Extract (unchanged)
  → [NEW] Vision Process (conditional Groq Vision)
  → AI Parse & Validate v3 (+ merge text + vision)
  → Route → Notify
```

### Rate Limit Protection

| Limit | Value | Why |
|-------|-------|-----|
| Text calls/day | 100 | Well under Groq 1,000/day limit |
| Vision calls/day | 20 | Conservative — most emails have no attachments |
| Circuit breaker | 3 errors → stop | Prevents Gemini-style burnout |
| Max attachment | 4 MB | Groq Vision hard limit |

**Graceful degradation:** If vision fails → text-only ticket still works. Every failure path produces a valid ticket.

### Vision LLM

- **Primary:** Groq `llama-4-scout-17b-16e-instruct` (free, same API key)
- **Backup:** Google Gemini 2.0 Flash (native PDF, but rate limit risk)
- **Dead:** ~~llama-3.2-11b-vision-preview~~ (deprecated Oct 2024)

### Build Status

- [ ] Go/no-go gate: Gmail attachment download test (30 min)
- [ ] Prepare for AI v3: rate limiter + binary extraction
- [ ] Vision Process node: conditional Groq Vision API call
- [ ] AI Parse & Validate v3: merge text + vision results
- [ ] Dashboard: vision results in Finance page
- [ ] Test all scenarios (with/without attachments)

### Demo Positioning for Tuesday

> "Monday we showed AI reading email text. Today I'll show the next step — AI reading the actual bank slip document attached to the email, and automatically cross-checking the amount. This addresses Rita's Phase 1 requirement: 'OCR the bank slip and confirm amount matches the form.'"

---

## Test Emails (3 scenarios)

### Test 1: NORMAL (SalaryToMA)
**Subject:** `Salary Disbursement Request - Golden Star Trading Co., Ltd`
- Amount: 45,500,000 MMK, 35 employees
- Approvers: U Kyaw Min Oo (Sales HOD), Daw Aye Thida (Finance Manager)
- Expected: scenario=NORMAL, matrix_complete=true

### Test 2: MISSING_APPROVAL
**Subject:** `Urgent: March Payroll - Shwe Taung Construction`
- Amount: 128,000,000 MMK, 210 employees
- Approvers: U Zaw Myo Htut (Sales HOD only)
- Expected: scenario=MISSING_APPROVAL, matrix_complete=false

### Test 3: OTC (SalaryToOTC)
**Subject:** `OTC Salary Disbursement - Myanmar Jade Mining Corp`
- Amount: 67,200,000 MMK, 85 employees
- Approvers: Daw Su Su Hlaing (Sales HOD), U Than Htike Aung (Finance Manager)
- Expected: scenario=NORMAL, type=SalaryToOTC

---

## Key Constraints (Always Respect)

- **Minh:** "Flow first, AI later" / "OCR later" / "No cloud for sensitive data"
- **Real employee data (MSISDNs, salaries) NEVER sent to cloud APIs**
- **Demo uses mock data only** — sample bank slips from internet, test emails
- **v2 is Monday's demo — never touch it. v3 is separate.**

---

## Groq API Limits (Free Tier)

| Model | RPM | Requests/Day | Tokens/Min | Tokens/Day |
|-------|-----|-------------|------------|------------|
| llama-3.3-70b (text) | 30 | 1,000 | 12,000 | 100,000 |
| llama-4-scout (vision) | 30 | 1,000 | 30,000 | 500,000 |

For demo (5-10 emails): zero concern. Our caps (100 text, 20 vision per day) add extra safety.

---

## Diagrams (ready to export as PNG from mermaid.live)

| File | Purpose |
|------|---------|
| `EMI_System_Workflow.mmd` | Full Phase 1-6 system workflow (team presentation) |
| `n8n_Pipeline_Diagram.mmd` | n8n-specific 8-node pipeline (technical discussion) |
| `Monday_Showcase_Flow.mmd` | Client-facing 6-step demo flow (sent to Vinh) |

---

## Alignment with Stakeholders

| Person | What They Want | Monday Coverage | Tuesday Coverage |
|--------|---------------|-----------------|-----------------|
| **Vinh** | 4 showcase items for client | All 4 done | + attachment extraction |
| **Minh** | Flow first, OCR later | Flow complete | OCR as "next step" preview |
| **Rita** | Phase 1: parse email, OCR slip, validate approvers | 85% (no OCR) | 95% (vision + reconciliation) |
| **Client** | Replace manual payroll checking with AI | Live demo end-to-end | + document AI reading |
