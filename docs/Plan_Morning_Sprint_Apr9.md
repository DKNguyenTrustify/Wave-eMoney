# Morning Sprint Plan — April 9, 2026 (8:45 AM - 9:45 AM)

**Goal:** Quick wins before the 10:00 AM team meeting with Rita + Win
**Time budget:** 60 minutes
**Rule:** Only ship things that are done-done. No half-finished features.

---

## Sprint Tasks (Priority Order)

### Task 1: "Asked Client" Mismatch Status (20 min)
**Why:** Minh decided this on Apr 8. Showing it tomorrow = responsiveness to leadership.

**What to change in `index.html`:**

1. **Add new status constant** — `ASKED_CLIENT` alongside existing statuses
2. **Mismatch tickets get "Asked Client" status** — when pipeline detects mismatch, set status to `asked_client` instead of generic `pending`
3. **Badge styling** — orange/amber badge for "Asked Client" (distinct from green Pending, red Rejected)
4. **Ticket modal** — when status is `asked_client`:
   - Show "Asked Client" badge prominently
   - "Return for Correction" button opens mailto draft (already exists)
   - "Override & Continue" allows manual progression (already exists)
   - Add note: "This ticket is preserved for audit. A corrected resubmission will create a new ticket."
5. **Dashboard ticket list** — "Asked Client" status visible in the status column

**What NOT to do:**
- Don't build the record-linking feature (old ticket → new ticket) — that needs database
- Don't build auto-email sending — mailto draft is enough for now
- Don't change pipeline — this is dashboard-only

### Task 2: Git Cleanup + Commit (10 min)
**Why:** Untracked files sitting in repo. Clean state before meeting.

**Actions:**
- `git add` the new diagram files (`workflow_current_v51_chatgpt.png`, `workflow_current_v51_deepseek.html`)
- `git add` renamed sample PDFs (`grok_payroll_acme_innovations_3emp_USD.pdf`, `grok_payroll_global_solutions_3emp_EUR.pdf`)
- `git add` Win's handwriting test image (`research/real_samples/win_handwriting_otc_payroll_4emp.jpg`)
- `git rm` the deleted `samples/TestPDF.pdf`
- Commit: "Add workflow diagrams, Win handwriting test sample, rename test PDFs"
- Push to main (auto-deploys to Vercel)

### Task 3: Remove Circuit Breaker Debug Reset (5 min)
**Why:** Production hygiene. The debug line `staticData.visionErrors = 0;` should be removed from n8n Cloud.

**Action:** Manual — go to n8n Cloud → v5.1 → Vision Process node → remove the debug reset line if still present.

### Task 4: Verify Dashboard (5 min)
**Why:** Confirm everything looks right before meeting.

**Actions:**
- Open wave-emi-dashboard.vercel.app
- Click TKT-014 (Win's handwriting test) — verify employee table, mismatch badges, "Return for Correction"
- Quick check other tickets still work
- Screenshot for meeting if needed

---

## Buffer (20 min)

If Tasks 1-4 finish early, pick ONE:

| Option | Effort | Impact |
|---|---|---|
| **A: Prepare talking points** for 10 AM meeting — what to show Rita/Win | 10 min | High |
| **B: Culture Survey OCR test** — send PDF through pipeline | 15 min | Data for infrastructure doc |
| **C: Start PostgreSQL schema sketch** — feeds KAN-26 | 20 min | Shows progress on Jira ticket |

**Recommended:** Option A. Walking into the meeting with clear talking points > more code.

---

## Meeting Talking Points (if needed)

For the 10 AM meeting, DK can show:

1. **Win's handwriting test result** — "We tested with Win's real Myanmar handwriting last night. 100% name transliteration, 100% amounts, mismatch detected correctly."
2. **Workflow diagram** — ChatGPT PNG (already shared) or DeepSeek HTML (open in browser)
3. **"Asked Client" status** — "Minh's decision from yesterday is implemented. Mismatch tickets are flagged and preserved for audit."
4. **Pipeline status** — v5.1 active, dual vision (Groq + Gemini), 14 tickets processed total
5. **What's next** — Infrastructure recommendation (Rita's ask), waiting on Kim/Thet Hnin Wai inputs

---

## What NOT to Do Tomorrow Morning

- Don't start NextJS migration (KAN-26) — needs infrastructure decision first
- Don't build E-Money Movement Form — no template from Thet Hnin Wai yet
- Don't build OTC validation — no rules from Kim yet
- Don't refactor UI/UX heavily — Dong joins next week
- Don't compare LLMs — Rita said infrastructure first

---

## Success Criteria

By 9:45 AM, these should be true:
- [ ] "Asked Client" status visible on mismatch tickets
- [ ] Git repo clean, diagrams + Win sample committed
- [ ] Circuit breaker debug line removed from n8n Cloud
- [ ] Dashboard verified working on Vercel
- [ ] DK knows what to say in the 10 AM meeting
