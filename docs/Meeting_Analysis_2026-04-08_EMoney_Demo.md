# Meeting Analysis — EMoney Demo & Feedback Session, April 8, 2026 (10:30 AM)

**Meeting:** EMoney Test Demo and Feedback Session (~45 min)
**Transcript:** `_meetings/2026-04-08_EMoney_Demo_Feedback_Session.vtt` (3822 lines)
**Attendees:**
- **Myanmar Ops (Wave Money):** Nyan San Kim (ops), Thet Hnin Wai / "Tetnan" (ops), Myo Jo Khaing (manager)
- **Trustify/Zaya:** Rita Nguyen (client lead), Win Win Naing (Head of Product & AI), Vinh Nguyen Quang (PM — label covers Vinh, Khoa, DK)
**Document by:** DK + Claude

---

## Key Discovery: Win Win Naing's Role

Rita introduced Win as **"Head of Product and AI"** — not just Myanmar ops:

> **Rita (0:30):** "Win-Win, who has been introduced to you on email, is joining us as our Head of Product and AI, and she will follow through this and make sure that you get what you need."

This is a bigger role than we knew. Win is the product owner for this project, not just a domain consultant.

---

## What Was Demoed

1. **Email intake** — showed how client email forwards to controlled mailbox
2. **AI pre-check** — extraction from email body + salary slip attachment
3. **Mismatch detection** — demonstrated 10M email vs 7.8M attachment → flagged
4. **Dashboard interface** — extracted data, confidence levels, status indicators
5. **Workflow visualization** — Win presented the full process flow diagram

**What was NOT demoed (per earlier standup decision):**
- Myanmar handwriting (skipped — Grok images have fake Myanmar text)
- PDF attachment support (not shown)
- Full E-Money processing flow (Steps 4-7)

---

## Myanmar Ops Team Feedback — The Critical Insights

### 1. Mismatch Handling Process (~13:15)

**Nyan San Kim asked the most important question:**

> "How do we process this from this step right now? This is the amount mismatch. So if we click something on this, will it send it back to the salesperson email or what's the process from here to returning back to the corporate team?"

**What they need:** When mismatch detected → system sends rejection email back to commercial/sales team → client corrects and resubmits → new ticket created (NOT replacing the old one).

**Win clarified:** Mismatched ticket should be marked as "tentative" (flagged, no further processing). Corrected resubmission creates a NEW ticket — separate for audit trail purposes.

> **Win (15:18):** "When this happened, maybe we can put this data as tentative. We will not do any further process for this one."

> **Win (16:36):** "New one will be better for the system... for the audit purpose, better to keep separate."

**Impact on our system:** Our "Return for Correction" button is correct. But we need:
- A "Tentative / Flagged" status for mismatch tickets (not just visual — actual status)
- Audit trail — old ticket preserved, new corrected ticket is separate
- This aligns with Minh's feedback from Apr 7

### 2. Client-Specific Finance Verification (~18:52)

**Thet Hnin Wai revealed:** Finance approval is NOT required for ALL clients — only specific ones.

> **Thet Hnin Wai (18:52):** "For the finance manager verification, it is happening for some specific clients only. All clients are not required for the finance team verification."

**What they need:** A client master list that controls whether finance approval step is required or skipped.

**Win's response:** "If you have the master list for those emails, we don't need to do this part. For the rest of them, we have to filter out according to this logic."

**Impact:** Finance approval flow needs to be conditional — not always required. This is a workflow logic change, not just UI.

### 3. OTC/POI Validation Rules (~22:00)

**Nyan San Kim detailed 5-6 validation rules for OTC disbursements:**

> "For salary to OTC, we are making the disbursement to their POI number, not to their wallet. So there are additional checkpoints: POI digit has to be 6 digits, each transaction amount cannot exceed more than 1 million..."

Additional rules mentioned:
- POI must be exactly 6 digits
- Per-transaction max: 1,000,000 MMK
- No exact duplicate transactions
- 3-4 other criteria (Kim will send the full list)

**Impact:** Our current validation only checks MSISDN format. OTC path needs completely different validation. Kim promised to send the full criteria.

### 4. L2 KYC Verification for Wallet/MA (~24:50)

**Nyan San Kim explained:** For wallet (SalaryToMA) disbursements, recipients must be L2 verified users (KYC completed) on Wave Money's MFS system.

> "For the wallet, they have to be L2 users, meaning verified user, meaning KYC completed user."

**Win clarified:** This check cannot be done within our AI pre-check — it requires querying Wave Money's BI portal. This is an offline/external check.

**Impact:** Our system can flag "L2 check required" but cannot verify it. This is a future integration point with Wave Money's internal systems.

### 5. E-Money Movement Form — NEW REQUIREMENT (~37:39)

**The biggest discovery of the meeting.** Thet Hnin Wai introduced a step nobody had discussed before:

> **Thet Hnin Wai (37:39):** "Upon getting from the client directly, our corporate sales team, I need to prepare the e-money movement form, which is not same as our back uploader form in the system."

**Rita's reaction:**

> **Rita (38:50):** "Every time I talk to you guys, there's a new step."

> **Rita (39:37):** "This is why we're missing gaps at the beginning of this, because I didn't look at any of that."

**What it is:** An internal transfer form that specifies:
- Which corporate wallet to pull funds FROM (varies per client)
- The total amount to transfer
- Has a "summary sheet" (internal) and "detail sheet" (goes to disbursement processor)
- Required BEFORE actual disbursement can happen

**Rita's resolution:**

> **Rita (42:39):** "Easy. So all we need to do then is have an associated PDF or web form that these guys can download later per record."

**Impact:** We need to generate a downloadable E-Money Movement Form per ticket. This is a new feature — essentially a PDF/form generator. Not complex, but it's a newly discovered step in the workflow.

### 6. Batch Consolidation Request (~31:00)

**Nyan San Kim's wish list item:**

> "One of the requests that we would like to make was also not to process the disbursement per email or per batch. We want to consolidate the disbursements. For example, for our client like SSB, they have 31 branches, so it comes in 31 emails, but we don't want to do 31 disbursements. We want to consolidate all in one batch."

**Rita deferred this:**

> "Can I suggest that we park this specific request until after we're live? It can be done, Kim. But it just adds some logic at the front and some logic at the back that I would like to hold off until we get all of this right."

**Impact:** Feature request noted for post-launch. Not in scope for Phase 4.

---

## Rita's Key Directives

### Security & Rollout

> **Rita (27:02):** "Please don't use real data because it's on a public sandbox environment that isn't locked down yet. Put it through Copilot to anonymize it."

> **Rita (27:46):** "What we will not do is we will not turn on the automatic checking on the email. We'll turn on all of the other stuff first so that you can forward specific emails into the queue... and then we can just manually do spot checks. And then we'll turn it all on for you when the time is right."

**Rollout plan:** Manual forwarding first → spot check accuracy → then full automation.

### Follow-Up Testing

> **Rita (30:05):** "I'm going to ask Win to probably in a couple of days to probably do another test with you guys end to end."

**Next demo in ~2-3 days** (around Apr 10-11) — Win will lead it.

---

## Action Items

### From Development Team (DK's responsibility)

| # | Action | Priority | Source |
|---|--------|----------|--------|
| 1 | **Add "Tentative" status** for mismatch tickets — preserve for audit, no further processing | HIGH | Kim + Win |
| 2 | **Client-specific finance bypass** — master list controls whether finance approval required | HIGH | Thet Hnin Wai |
| 3 | **OTC/POI validation rules** — implement 5-6 criteria when Kim sends them | HIGH | Kim (will send) |
| 4 | **E-Money Movement Form generation** — downloadable PDF/form per ticket | MEDIUM | Thet Hnin Wai + Rita |
| 5 | **Missing approval detection** — beyond just amount mismatch | MEDIUM | Thet Hnin Wai |

### Waiting From Myanmar Ops

| # | What | From Whom |
|---|------|-----------|
| 1 | Full OTC/POI validation criteria list | Nyan San Kim |
| 2 | Client master list (which clients need finance approval) | Thet Hnin Wai |
| 3 | E-Money Movement Form template | Thet Hnin Wai (in process doc attachment) |
| 4 | Real Myanmar handwriting samples (fake data) | Win Win Naing |

### Timeline

- **Next 2-3 days:** Win leads another end-to-end test with Myanmar ops
- **Post-launch:** Batch consolidation feature
- **3 weeks:** Infrastructure decision for production environment

---

## New People Identified

| Name | Role | Notes |
|------|------|-------|
| **Nyan San Kim** | Wave Money Operations | Detailed process knowledge, OTC validation expert. Key stakeholder. |
| **Thet Hnin Wai** ("Tetnan") | Wave Money Operations | Currently does pre-checks manually. Introduced E-Money Movement Form requirement. |
| **Myo Jo Khaing** | Wave Money Manager | Thet Hnin Wai's manager. Attended as observer. |

---

## What This Means for Phase 4

The demo feedback reshapes Phase 4 priorities:

| Original Phase 4 Plan | Updated Based on Demo Feedback |
|----------------------|-------------------------------|
| Enterprise AI Platform Comparison | **Infrastructure Recommendation** (Rita's standup directive) |
| Myanmar OCR validation (Win samples) | Still needed — waiting on Win |
| Role system (Manager/observer) | **Client-specific finance bypass** (higher priority, from Thet Hnin Wai) |
| Supabase database | Still needed — part of infrastructure |
| UX polish with Dong | Focus on **"Tentative" status + audit trail** |

### New Features Discovered

| Feature | Effort | Priority |
|---------|--------|----------|
| Tentative/flagged status for mismatch tickets | Small — status + UI | HIGH |
| Client-specific finance approval bypass | Medium — master list + routing logic | HIGH |
| OTC/POI validation (6 digits, 1M limit, etc.) | Medium — when Kim sends rules | HIGH |
| E-Money Movement Form PDF generation | Medium — template + PDF builder | MEDIUM |
| Batch consolidation (31 emails → 1 disbursement) | Large — deferred post-launch | LOW |
| L2 KYC check integration | Future — requires Wave Money API | FUTURE |

---

## Honest Assessment

**The demo went well.** Myanmar ops team asked smart, detailed questions. They weren't confused by the UI — they were asking about business logic and workflow gaps. That's a good sign.

**But we're learning that the workflow is deeper than Rita initially scoped.** Every meeting reveals new steps (finance bypass rules, OTC validation, E-Money Movement Form). This is normal for banking operations automation — the ops team knows 10x more about the process than anyone else.

**DK's strategic move:** The E-Money Movement Form is a quick win. Rita said "easy" — a downloadable PDF per ticket. Building this before the next demo (2-3 days) would demonstrate responsiveness to Myanmar ops feedback.
