# Phase 2: UI/UX Enhancement — Implementation Plan

**Version:** Phase 2 (post-v3 pipeline verification)
**Status:** PLAN — review before executing
**Prerequisite:** v3 Vision Pipeline fully operational (verified April 4, 2026)
**Files to modify:** `index.html` (primary), `n8n-workflow-v3.json` (minor pipeline enhancement)
**Estimated effort:** 3-4 hours total

---

## 0. Why This Phase Exists

The v3 pipeline works end-to-end: email parsing, vision AI extraction, cross-validation, notification, and dashboard ingestion. But the **UI/UX doesn't showcase this well enough**:

- Dashboard ticket rows are **not clickable** — you see a summary but can't drill in
- Incoming Emails n8n tickets are **one-line summaries** — no detail, no context
- Vision AI results are **hidden on the Finance page only** — the most impressive feature is buried
- No way to see **the email content or what the AI read** — users can't verify why the system flagged something
- The pipeline produces rich data (body_preview, vision extraction, authority matrix, metadata) but **most of it isn't displayed**

**Goal:** Make every AI extraction result visible, clickable, and impressive — without adding new infrastructure.

---

## 1. Current State vs Target State

| Area | Current | Target |
|------|---------|--------|
| Dashboard ticket rows | Static table, not clickable | Click → rich detail modal with all AI results |
| Incoming Emails n8n tickets | One-line: ID + company + amount | Expandable cards matching mock email quality |
| Vision AI display | Finance page only (purple sidebar) | Dedicated section on every ticket view |
| Email content | Only `body_preview` (200 chars) | Full email body visible for verification |
| Attachment/document | Not shown anywhere | Vision extraction displayed as "AI Document Analysis" card |
| AI extraction comparison | Not shown | Side-by-side: Email Text AI vs Vision Document AI |
| Ticket navigation | No cross-page linking | Click ticket ID anywhere → opens detail modal |
| Pipeline stats | 1 banner ("X tickets with Vision AI") | AI Processing dashboard section |

---

## 2. Security Analysis: Email & Attachment Display

### Is it safe to show email content and attachments in the app?

**Short answer: Yes for demo, with a blur/reveal toggle for polish.**

| Concern | Assessment |
|---------|-----------|
| Email body text | **Safe.** Disbursement request emails contain company names, amounts, approver names — not employee PII. Already captured in `body_preview`. |
| Email metadata (from/to/cc) | **Safe.** Already displayed on Incoming Emails page and Finance page. |
| Bank slip image | **Safe for demo.** Test images are mock/sample bank slips. In production, real bank slips contain account numbers — but even then, they're already being processed by the Vision AI through an external API (Groq). |
| Employee Excel files | **NEVER on cloud.** This is Minh's rule. Employee files stay client-side only — already enforced. Not affected by this phase. |
| Attachment base64 in ticket data | **Trade-off.** Currently cleared after Vision Process (by design). Carrying a thumbnail (~50KB) to the dashboard would increase localStorage but enable image preview. |

### Minh's Rule Compliance

> "No cloud for sensitive data" — employee Excel files must never be sent to cloud APIs.

This phase is compliant:
- All display is client-side (localStorage + browser rendering)
- Email body text is already sent to Groq for text extraction — displaying it locally is less exposure, not more
- Bank slip image is already sent to Groq Vision API — displaying a thumbnail locally adds no new risk
- Employee data handling is unchanged

### Recommendation

- **Demo mode (default):** Show everything — email body, metadata, vision results, authority matrix
- **Privacy toggle:** Add a "Sensitive Data" blur/reveal button. Click to blur email content, attachment preview, and personal names. Click again + enter PIN to reveal. This is a **UX polish for demos** (looks professional), not a security mechanism.

---

## 3. Implementation Tasks

### Task 1: Ticket Detail Modal (HIGHEST IMPACT)

**What:** Click any ticket ID on Dashboard or Incoming Emails → opens a rich detail modal.

**Why:** Currently there's no way to inspect a ticket's full data. The Finance page shows detail but only for Finance role and only for pending tickets.

**Existing infrastructure:** Modal system already exists (`.modal-overlay`, `.modal` CSS classes; Demo Modal and E-Money Success Modal use this pattern).

**New function:** `openTicketDetail(ticketId)`

**Modal layout:**

```
┌─────────────────────────────────────────────────────┐
│  TKT-010 · ACME Innovations Ltd           [X Close] │
│  ┌─────┐ ┌─────┐ ┌─────────┐ ┌──────┐              │
│  │ MA  │ │ HIGH│ │ MISMATCH│ │ n8n  │              │
│  └─────┘ └─────┘ └─────────┘ └──────┘              │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ── AI Pipeline Results ──────────────────────────── │
│                                                      │
│  ┌──────────────────┐  ┌──────────────────────────┐ │
│  │ Email Text AI     │  │ Vision Document AI        │ │
│  │ (Groq llama-3.3)  │  │ (Groq llama-4-scout)     │ │
│  │                    │  │                           │ │
│  │ Company: ACME...   │  │ Doc Type: payroll_form    │ │
│  │ Amount: 25,000,000 │  │ Amount: 24,500            │ │
│  │ Type: SalaryToMA   │  │ Confidence: 100%          │ │
│  │ Approvers:         │  │ Signers: Maria Chen       │ │
│  │  - Sales HOD ✓     │  │                           │ │
│  │  - Fin. Mgr ✓      │  │ ⚠ AMOUNT MISMATCH        │ │
│  └──────────────────┘  └──────────────────────────┘ │
│                                                      │
│  ── Email Source ──────────────────────────────────── │
│  From: dknguyen@... · To: xaondk@...                 │
│  Date: 2026-04-04 · Thread: ...                      │
│  Subject: Salary Disbursement Request - ACME...      │
│  Body: [expandable preview of email text]             │
│  Attachments: bank_slip.png (727 KB)                 │
│                                                      │
│  ── Authority Matrix ─────────────────────────────── │
│  Required     │ Found          │ Status               │
│  Sales HOD    │ U Kyaw Zin     │ ✓ Present            │
│  Finance Mgr  │ Daw Su Su Lwin │ ✓ Present            │
│                                                      │
│  ── Processing Status ────────────────────────────── │
│  Track A (Pre-checks): ⏳ Pending                    │
│  Track B (Finance):    ⏳ Pending                    │
│  Status: Awaiting Emp. List                          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Code changes:**

1. **HTML** — Add new modal container after existing modals (~line 405):
   ```html
   <div class="modal-overlay" id="ticket-detail-modal" onclick="if(event.target===this)this.classList.remove('open')">
     <div class="modal" style="max-width:800px;max-height:90vh;overflow-y:auto">
       <div id="ticket-detail-content"></div>
     </div>
   </div>
   ```

2. **CSS** — Add styles for the detail modal layout (~line 230):
   - `.detail-grid` — 2-column grid for side-by-side AI results
   - `.ai-card` — styled card for each AI extraction (text vs vision)
   - `.ai-card.text` — blue accent border
   - `.ai-card.vision` — purple accent border
   - `.detail-section` — section divider with label
   - `.confidence-bar` — horizontal progress bar for confidence %
   - `.mismatch-highlight` — animated yellow highlight for mismatched values

3. **JS** — New function `openTicketDetail(ticketId)` (~line 2100):
   - Looks up ticket from `state.tickets`
   - Builds full detail HTML with all sections
   - Populates `#ticket-detail-content`
   - Opens modal overlay

4. **Dashboard table** — Make ticket ID and company clickable:
   ```javascript
   // Current (line ~941):
   <td><strong>${t.id}</strong>${n8nBadge}</td><td>${t.company}</td>

   // New:
   <td><a href="#" onclick="openTicketDetail('${t.id}');return false" style="...">${t.id}</a>${n8nBadge}</td>
   <td><a href="#" onclick="openTicketDetail('${t.id}');return false">${t.company}</a></td>
   ```

5. **Incoming Emails n8n tickets** — Make ticket items clickable:
   ```javascript
   // Current (line ~984): static div
   // New: wrap in clickable div with cursor:pointer + onclick
   ```

**Estimated effort:** 60-90 minutes

---

### Task 2: Enhanced n8n Ticket Cards on Incoming Emails

**What:** Expand n8n automated intake tickets from one-line summaries to rich cards matching the quality of mock email cards.

**Why:** n8n tickets have all the same data as mock emails (company, amount, type, approvers, body_preview, vision results) but are displayed as cramped one-liners. Users can't tell what the AI actually extracted.

**Current display (~10 lines):**
```
TKT-010 · ACME Innovations Ltd · 25,000,000 MMK · Awaiting Emp. List 📎 1 👁 Vision 100% ⚠ Doc: 24,500...
From: dknguyen@... · To: xaondk@... · 2026-04-04T08:39:35.000Z
Document: payroll_form · Signers: Maria Chen
```

**Target display (~40 lines):**
```
┌────────────────────────────────────────────────────────────────┐
│ 📩 Salary Disbursement Request - ACME Innovations Ltd          │
│ dknguyen0105vietnam@gmail.com · 2026-04-04 08:39               │
│ ┌────┐ ┌──────────────────┐ ┌──────────────────────────┐      │
│ │ MA │ │ ⚠ Amount Mismatch│ │ 👁 Vision AI: 100%       │      │
│ └────┘ └──────────────────┘ └──────────────────────────┘      │
│                                                                │
│  AMOUNT REQUESTED          VISION DOCUMENT AMOUNT              │
│  25,000,000 MMK            24,500 MMK ⚠                       │
│                                                                │
│  "Please process salary disbursement for ACME Innovations..."  │
│                                                                │
│  🔐 Authority Matrix                                           │
│  Sales HOD     │ U Kyaw Zin      │ ✓ Present                   │
│  Finance Mgr   │ Daw Su Su Lwin  │ ✓ Present                   │
│                                                                │
│  📎 Attachments: bank_slip.png (1 file)                        │
│  📄 Document Type: payroll_form · Signers: Maria Chen          │
│                                                                │
│  ✅ Parsed → TKT-010                    [View Details]         │
└────────────────────────────────────────────────────────────────┘
```

**Code changes:**

1. Replace the `n8nTickets.forEach` block (~line 983-993) with a richer card template
2. Each n8n ticket gets a `.card.email-card` container (same class as mock emails)
3. Show: subject, from/date, type+scenario badges, vision badge
4. Two-column amount display (email amount vs document amount)
5. Body preview text
6. Authority matrix table (using `email_approvals` and `required_approvals`)
7. Attachment info + document type from vision
8. "View Details" button → `openTicketDetail()`

**Data availability check:**

| Field needed | Available in ticket? | Source |
|-------------|---------------------|--------|
| `original_subject` | Yes | Prepare node → Parse & Validate → ticket |
| `from_email` | Yes | Already displayed |
| `email_date` | Yes | Already displayed |
| `body_preview` | Yes | From Groq text extraction |
| `amount_requested` | Yes | From Groq text extraction |
| `amount_on_document` | Yes (v3) | From Vision AI extraction |
| `email_approvals` | Yes | From Groq text extraction |
| `required_approvals` | Yes | Hardcoded ["Sales HOD", "Finance Manager"] |
| `vision_parsed` | Yes (v3) | From Vision Process |
| `vision_confidence` | Yes (v3) | From Vision Process |
| `document_type` | Yes (v3) | From Vision Process |
| `document_signers` | Yes (v3) | From Vision Process |
| `has_attachments` | Yes | From Prepare node |
| `attachment_names` | Yes | From Prepare node |

All fields are already available — no pipeline changes needed for this task.

**Pipeline enhancement (optional):** To show the original subject on n8n tickets, we need `original_subject` in the ticket data. Currently `createTicketFromN8n()` does NOT save `original_subject`. Add:
```javascript
original_subject: data.original_subject || '',
```

**Estimated effort:** 45-60 minutes

---

### Task 3: Email Body Display for Verification

**What:** Show the email body text in the ticket detail, so users can verify why the AI extracted what it did.

**Why:** The user's core concern — "users can easily detect why our system raised the difference or warning of the ticket it created by the email trigger."

**Current state:** `body_preview` captures ~200 characters (from Groq text extraction prompt). The actual email body is NOT stored in the ticket.

**Option A (simple): Use existing body_preview**
- Already available in every n8n ticket
- 200 chars is enough to show the key content
- No pipeline changes needed
- Display in ticket detail modal and n8n card

**Option B (richer): Carry full email body through pipeline**
- Requires pipeline change: add `email_body` field to Prepare for AI v3 output
- Retrieve in AI Parse & Validate v3 from Prepare node reference
- Include in ticket data (increases URL/localStorage size)
- Limit to first 1000 characters to keep payload manageable

**Recommendation:** Start with Option A (zero pipeline changes). Add Option B later if 200 chars isn't enough for the demo. The body_preview is generated by Groq from the full email, so it already contains the key information.

**Code changes (Option A):**
- In `openTicketDetail()`: render `body_preview` in an "Email Content" section
- In n8n ticket cards: show `body_preview` as italic quote text

**Code changes (Option B — if needed later):**

1. **Prepare for AI v3** — add to output:
   ```javascript
   email_body: body.substring(0, 1000),
   ```

2. **AI Parse & Validate v3** — retrieve and pass through:
   ```javascript
   const email_body = prepData.email_body || '';
   // ... add to ticket object
   ticket.email_body = email_body;
   // ... add to results
   email_body: ticket.email_body || '',
   ```

3. **createTicketFromN8n()** — add field:
   ```javascript
   email_body: data.email_body || '',
   ```

4. **openTicketDetail()** — render expandable email body section

**Estimated effort:** 15 minutes (Option A), +30 minutes (Option B)

---

### Task 4: AI Pipeline Results Showcase

**What:** Create a visually striking "AI Analysis" section that shows side-by-side what the text AI and vision AI extracted.

**Why:** This is the "wow" feature — the AI reads both the email text AND the bank slip image, then cross-validates. But currently, this story isn't told visually anywhere except the Finance page.

**Design: Side-by-Side AI Comparison Card**

```
┌──────── AI Pipeline Analysis ─────────────────────────────────┐
│                                                                │
│  ┌─ Text Extraction ───────┐  ┌─ Document Vision ──────────┐ │
│  │ 🤖 Groq llama-3.3-70b   │  │ 👁 Groq llama-4-scout      │ │
│  │                          │  │                             │ │
│  │ Company                  │  │ Document Type               │ │
│  │ ACME Innovations Ltd     │  │ payroll_form                │ │
│  │                          │  │                             │ │
│  │ Amount                   │  │ Amount on Document          │ │
│  │ 25,000,000 MMK           │  │ 24,500 ← ⚠ MISMATCH       │ │
│  │                          │  │                             │ │
│  │ Type                     │  │ Confidence                  │ │
│  │ SalaryToMA               │  │ ████████████████████ 100%   │ │
│  │                          │  │                             │ │
│  │ Approvers                │  │ Signers on Document         │ │
│  │ ✓ Sales HOD              │  │ Maria Chen                  │ │
│  │ ✓ Finance Manager        │  │                             │ │
│  └──────────────────────────┘  └─────────────────────────────┘ │
│                                                                │
│  Cross-Validation Result:                                      │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ ⚠ AMOUNT MISMATCH — Email says 25,000,000 MMK but         ││
│  │   document shows 24,500. Difference: 24,975,500 (>1%)     ││
│  │   → Flagged for human review                              ││
│  └────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────┘
```

**When no vision data (v2 tickets):**
```
┌──────── AI Pipeline Analysis ─────────────────────────────────┐
│  ┌─ Text Extraction ────────────────────────────────────────┐ │
│  │ 🤖 Groq llama-3.3-70b                                    │ │
│  │ Company: Golden Star Trading · Amount: 45,500,000 MMK    │ │
│  │ Type: SalaryToMA · Approvers: 2/2 complete               │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ 👁 Vision AI: Not processed (no attachment)               │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

**Code changes:**

1. **CSS** — New classes for AI comparison layout:
   - `.ai-pipeline-section` — container with gradient top border
   - `.ai-comparison` — 2-column grid
   - `.ai-card.text-ai` — blue-accented card (left)
   - `.ai-card.vision-ai` — purple-accented card (right)
   - `.confidence-bar` — horizontal bar with fill animation
   - `.cross-validation-result` — alert-style summary box
   - `.field-label` / `.field-value` — key-value pair styling

2. **JS** — New helper function `renderAIPipelineSection(ticket)`:
   - Returns HTML string for the AI comparison block
   - Handles both vision and non-vision tickets
   - Used by: `openTicketDetail()`, enhanced n8n cards, `renderFinance()`

3. **Integration** — Replace the current vision block in `renderFinance()` (lines 1273-1283) with `renderAIPipelineSection()` for consistency across all views.

**Estimated effort:** 45-60 minutes

---

### Task 5: Clickable Ticket IDs Everywhere

**What:** Every ticket ID mention becomes a clickable link to the detail modal.

**Where to add `onclick="openTicketDetail('TKT-XXX')"` handlers:**

| Location | Current | Change |
|----------|---------|--------|
| Dashboard ticket table rows | Static `<td>` | Clickable `<a>` on ID + company + full row hover |
| Incoming Emails n8n ticket list | Static `<div>` | Clickable card with "View Details" button |
| Finance page ticket cards | Inline detail (keep as-is) | Add consistent ticket ID link at top |
| E-Money queue cards | Has "Start Processing" button | Add ticket ID link alongside |
| Activity log entries | Plain text "TKT-XXX created..." | Wrap TKT-XXX in clickable link |

**Code changes:**

1. **Dashboard** — Wrap ID cell in anchor tag with onclick
2. **Dashboard** — Add `cursor:pointer` and `tr:hover` background to full row
3. **Incoming Emails** — Add "View Details" button to each n8n ticket card
4. **Activity log** — Regex-replace `TKT-\d+` with clickable spans

**Estimated effort:** 20-30 minutes

---

### Task 6: Privacy/Blur Toggle (Demo Polish)

**What:** A toggle button that blurs sensitive data across the app. Click to reveal with a simple PIN.

**Why:** Professional touch for live demos in front of clients. Shows awareness of data handling practices.

**What gets blurred:**
- Email addresses (from_email, to_email, cc)
- Person names (approvers, signers)
- Full email body text
- Attachment filenames

**What stays visible (even when blurred):**
- Company names
- Amounts
- Ticket IDs
- Status badges
- Vision confidence
- Document types
- Scenario labels

**Implementation:**

1. **CSS class:** `.blurred { filter: blur(4px); user-select: none; pointer-events: none; }`
2. **Toggle button** in the nav bar (next to DEMO badge):
   ```html
   <span class="nav-badge" onclick="togglePrivacy()" id="privacy-toggle"
     style="cursor:pointer">🔒 Private</span>
   ```
3. **JS function:**
   ```javascript
   let privacyMode = false;
   function togglePrivacy() {
     if (privacyMode) {
       const pin = prompt('Enter PIN to reveal:');
       if (pin !== '1234') return; // Simple demo PIN
     }
     privacyMode = !privacyMode;
     document.body.classList.toggle('privacy-mode', privacyMode);
     document.getElementById('privacy-toggle').textContent =
       privacyMode ? '🔓 Visible' : '🔒 Private';
     // Re-render current page
     showPage(currentPage);
   }
   ```
4. **Rendering:** Wrap sensitive values in `<span class="sensitive">` tags. CSS rule:
   ```css
   .privacy-mode .sensitive { filter: blur(5px); user-select: none; }
   ```

**Estimated effort:** 20-30 minutes

---

### Task 7: Pipeline Enhancement — Carry More Data to Dashboard

**What:** Modify the n8n pipeline to pass additional fields that the enhanced UI needs.

**Changes to `n8n-workflow-v3.json`:**

**7a: Add `original_subject` to createTicketFromN8n (dashboard-side only)**

Currently `createTicketFromN8n()` doesn't store `original_subject`. The data IS available in the n8n output (`$json.original_subject`), it's just not saved.

```javascript
// In createTicketFromN8n(), add:
original_subject: data.original_subject || '',
```

**This is a dashboard-only change** — no pipeline modification needed. The field is already in the n8n output.

**7b: Add `email_body` to pipeline (Option B from Task 3, if needed)**

If 200-char `body_preview` isn't enough:

1. **Prepare for AI v3** — add `email_body: body.substring(0, 1000)` to output
2. **AI Parse & Validate v3** — add `email_body: prepData.email_body || ''` to ticket and results
3. **createTicketFromN8n()** — add `email_body: data.email_body || ''`
4. **Re-embed code into JSON** — use reassemble script or manual paste

**Trade-off:** Each ticket grows by ~1KB. With 10 tickets, that's ~10KB in localStorage — negligible. But the dashboard URL (base64-encoded ticket) also grows. Test that the URL doesn't exceed browser limits (~2KB is safe, ~8KB is the practical max for URLs).

**Recommendation:** Implement 7a immediately (zero risk, zero cost). Defer 7b until we confirm body_preview is insufficient.

**7c: Carry attachment thumbnail (future — NOT for Phase 2)**

To show the actual bank slip image in the dashboard, we'd need to:
1. Resize the image to ~100KB thumbnail in Prepare for AI v3
2. Carry through the pipeline as `attachment_thumbnail`
3. Include in ticket data for dashboard display

This is complex (image resizing in n8n Code node, significant URL/localStorage bloat) and **not needed for the demo**. The Vision AI extraction results (doc_type, amount, signers, confidence) already tell the story. The original image can be shown by opening the email in Gmail.

**Estimated effort:** 5 minutes (7a), 30 minutes (7b), skip 7c

---

## 4. Build Sequence & Dependencies

```
Task 7a (add original_subject to createTicketFromN8n)
  │   ← Must be first, other tasks depend on this field
  ▼
Task 1 (Ticket Detail Modal)
  │   ← Core infrastructure, all other UI features plug into this
  ▼
Task 4 (AI Pipeline Results Showcase)
  │   ← Builds the reusable renderAIPipelineSection() function
  ▼
Task 2 (Enhanced n8n Ticket Cards)
  │   ← Uses the modal + AI section from Tasks 1 & 4
  ▼
Task 5 (Clickable Ticket IDs Everywhere)
  │   ← Uses openTicketDetail() from Task 1
  ▼
Task 3 (Email Body Display — Option A)
  │   ← Simple addition to the detail modal
  ▼
Task 6 (Privacy/Blur Toggle)
      ← Final polish, wraps sensitive values
```

**All tasks modify only `index.html`.** Task 7b (pipeline change) is deferred.

---

## 5. Detailed Estimates

| Task | Description | Lines of code | Time |
|------|-------------|---------------|------|
| 7a | Add `original_subject` to createTicketFromN8n | ~1 line | 2 min |
| 1 | Ticket Detail Modal (HTML + CSS + JS) | ~120 lines | 60-90 min |
| 4 | AI Pipeline Results Section (CSS + JS helper) | ~80 lines | 45-60 min |
| 2 | Enhanced n8n Ticket Cards | ~60 lines | 45-60 min |
| 5 | Clickable Ticket IDs | ~15 lines | 20-30 min |
| 3 | Email Body Display (Option A) | ~10 lines | 15 min |
| 6 | Privacy/Blur Toggle | ~30 lines | 20-30 min |
| **Total** | | **~315 lines** | **3-4 hours** |

---

## 6. What NOT to Change

- **E-Money sub-pages** — Steps 4-7 (Prepare, Checker, Mapping, Monitoring, Close) are already detailed and working. No changes needed.
- **Mock email cards** — Already rich with full detail. Leave as-is.
- **Finance page approval form** — Works correctly. Only replace the vision block with the new `renderAIPipelineSection()` for consistency.
- **CSV generation logic** — Business logic is not part of this phase.
- **n8n pipeline flow** — No new nodes, no flow changes. Only minor data pass-through additions.

---

## 7. Testing Checklist

After implementation, verify:

- [ ] Click TKT-010 on Dashboard → detail modal opens with all sections
- [ ] AI comparison card shows: Text AI (blue) + Vision AI (purple) side-by-side
- [ ] AMOUNT_MISMATCH cross-validation result displayed correctly (25M vs 24,500)
- [ ] Confidence bar shows 100% for TKT-010
- [ ] Click TKT-009 (no vision) → modal shows text AI only, vision section says "Not processed"
- [ ] Incoming Emails page: n8n tickets show as rich cards (not one-liners)
- [ ] n8n ticket cards show: subject, from/date, amounts, authority matrix, vision badge
- [ ] "View Details" button on n8n cards → opens detail modal
- [ ] Activity log TKT-XXX links are clickable → opens detail modal
- [ ] Finance page vision block matches new AI Pipeline section style
- [ ] Privacy toggle: ON → emails/names blurred, OFF → prompt for PIN → reveal
- [ ] Mobile responsive: detail modal scrollable, cards stack vertically
- [ ] Ctrl+Shift+R reset still works (clears all data)
- [ ] v2 tickets (no vision fields) display correctly with "Not processed" vision section
- [ ] New n8n tickets from pipeline still create correctly (test with fresh email)

---

## 8. Demo Impact

### Before Phase 2 (current):
> "The AI parsed the email and created a ticket. If you go to Finance Approval and switch roles, you can see the vision results."

### After Phase 2:
> "Click any ticket — here's the full AI analysis. The left card shows what our text AI extracted from the email. The right card shows what our vision AI extracted from the bank slip. Notice the amounts don't match — 25 million in the email but 24,500 on the document. The system automatically flagged this for human review. Every step is transparent and auditable."

This is the difference between "it works" and "look how well it works."

---

## 9. Files Modified Summary

| File | Changes |
|------|---------|
| `wave-emi-dashboard/index.html` | All UI/UX changes (Tasks 1-6, 7a) |
| `wave-emi-dashboard/n8n-workflow-v3.json` | Only if Task 7b needed (deferred) |

No new files created. No new dependencies. No build step.
