# KAN-36 — [eMoney] Ticket Detail Popup — Analysis & Implementation Plan

**Created:** 2026-04-14 (afternoon, handoff before context compaction)
**Ticket source:** `docs/jira/KAN-36_eMoney_Ticket_Detail_Popup.pdf`
**Reporter:** Vinh Nguyen · **Assignee:** DK · **Priority:** High · **Status:** In Progress
**Ticket created:** 2026-04-14 (today)

---

## 📋 Vinh's Requirements (from PDF)

The ticket detail modal (`openTicketDetail()` in `index.html`) needs a structural refactor with **two branches** based on payment type:

### For `salarytoMA` tickets
1. **Employee list** — 4 columns: `SI No`, `from Wallet`, `to Wallet`, `emoney amount`
2. **AI Analysis** — side-by-side view of email extraction vs document extraction, 6 fields:
   - Company name
   - Initiator Name
   - total amount
   - pay date
   - Purpose
   - Cost Center
   - **Color coding:** green = match, yellow = mismatch
3. Original Email section (keep)
4. Original Attachment section (keep)
5. **REMOVE** Approval Status section
6. **REMOVE** Processing Status section
7. **"Generate CSV for Finance" button** (replaces current "Approve & Download CSV")
   - Enabled only when: Company name ✓, Initiator Name ✓, payment type ✓, total amount correct ✓, pay date ✓, Purpose ✓, Cost Center ✓, valid phone number / bank account ✓
8. **"Inform client for missing data" warning** shown when:
   - Data incomplete OR amount mismatch
   - Must LIST the specific missing fields

### For `salarytoOTC` tickets
Same as above EXCEPT no employee list (OTC = no employee list by definition).

---

## 🔍 Gap Analysis — What We Have vs What We Need

### Fields we ALREADY extract ✅
- `company` (from Groq email extraction)
- `amount` / `amount_requested` (from Groq)
- `payment_date` (from v10.1 / KAN-35)
- `payment_type` (salarytoMA / salarytoOTC — from v10.1)
- `attachment_count`, `extracted_employees` (from vision)
- `amount_on_document` (from vision — for comparison)

### Fields we DON'T extract yet ❌
- `initiator_name` — who in the company is requesting this disbursement
- `purpose` — why this disbursement (e.g., "March 2026 salary", "bonus payout")
- `cost_center` — accounting category (e.g., "HR-OPS-001")

### Employee list data — partial ⚠️
Current fields per employee: `name`, `account_or_phone`, `amount`
Vinh's required columns:
- `SI No` = row index (simple counter, 1, 2, 3...)
- `from Wallet` = **SOURCE WALLET** (company's corporate wallet) — we DON'T have this explicitly; could use `company` name or `depositor_name` as placeholder
- `to Wallet` = employee phone/account ✅ we have this
- `emoney amount` = employee amount ✅ we have this

**Decision for KAN-36:** `from Wallet` displays the depositor/company name as a proxy. Real wallet number would come from a lookup table in future (Finance knows the company's corporate wallet ID).

---

## 🎯 Split Strategy: v11 (fields + UI) then v12 (Claude migration) — LOCKED IN

Per DK's decision (Apr 14 afternoon):

### v11 Scope — "Add KAN-36 fields + dashboard refactor on existing Groq+Gemini"
- Pipeline: extend Groq prompt + Vision prompt for 3 new fields (initiator_name, purpose, cost_center)
- Parse & Validate: pass new fields through
- **Keep Groq+Gemini as models** — no model migration in v11
- Dashboard: full ticket detail modal refactor per Vinh spec
- Test end-to-end
- Validate stable BEFORE moving to v12

### v12 Scope — "Claude migration" (LATER, separate session)
- Replace Groq (text extract) + Gemini (vision) with **single Anthropic Claude API**
- All other logic unchanged (v11 fields, validation, dashboard all carry over)
- When AWS Bedrock infra ready → move Anthropic direct API → Bedrock endpoint
- **Design principle:** v11 must be structured so v12 is a **model swap, not rewrite**. Field names, prompt shapes, response formats stay consistent.

### Why split (vs bundle):
- **Risk isolation:** if v11 has bugs, fix those before adding Claude variable
- **Bug diagnosis:** isolated changes = clear attribution
- **Rollback granularity:** revert either independently
- **Honest pacing:** cramming 2 big upgrades into 1 = quality risk

---

## 📋 Implementation Plan — Next Session Execution

### Phase A — Pipeline v11 JSON changes (~45 min)

**File:** clone `pipelines/n8n-workflow-v10.1.json` → `pipelines/n8n-workflow-v11.json`

**Node 1: Prepare for AI v3 (Groq prompt extension)**
Add to the JSON schema Groq is asked to extract:
```json
{
  "is_disbursement": ...,
  "company": "...",
  "amount": ...,
  "type": "SalaryToOTC | SalaryToMA",
  "approvers": [...],
  "body_preview": "...",
  "payment_date": "...",
  "payroll_period": "...",
  "initiator_name": "the person/role requesting the disbursement (e.g., 'HR Manager', 'John Doe, Payroll Specialist')",
  "purpose": "why this disbursement (e.g., 'March 2026 Salary', 'Q1 Bonus', 'Contractor Payments')",
  "cost_center": "accounting cost center code if mentioned (e.g., 'HR-OPS-001', 'FIN-2026-Q1'); empty string if not mentioned"
}
```

**Node 2: Vision Process (attachment extraction extension)**
Similar addition to vision prompt — ask for these fields from the payroll/bank slip document.

**Node 3: AI Parse & Validate v3**
Pass new fields through to ticket output:
```javascript
initiator_name: parsed.initiator_name || '',
purpose: parsed.purpose || '',
cost_center: parsed.cost_center || '',
// Also from document (for side-by-side comparison):
doc_initiator_name: visionResult?.initiator_name || '',
doc_purpose: visionResult?.purpose || '',
doc_cost_center: visionResult?.cost_center || '',
// verification object extensions:
verification: {
  ...existing,
  initiator_name: !!parsed.initiator_name,
  purpose: !!parsed.purpose,
  cost_center: !!parsed.cost_center,
  phone_or_bank_valid: (ticket.extracted_employee_count > 0) // simplified check
}
```

**Model-agnostic design note:**
- Keep field names identical between Groq path and Vision path (same schema)
- Response parsing logic works on same field names regardless of provider
- v12 Claude migration = swap HTTP URL + auth + minor prompt syntax; field names + downstream code UNTOUCHED

### Phase B — Dashboard modal refactor (~1.5 hrs)

**File:** `index.html` (same `openTicketDetail()` function)

**Changes:**

1. **REMOVE Approval Status section** (currently at line ~3048 onwards)
2. **REMOVE Processing Status section** (currently at line ~3060 onwards)

3. **REWORK Employee List section** (currently shows Name/Phone/Amount):
```javascript
// New 4-column rendering for salarytoMA tickets
html += `<table class="employee-table">
  <thead><tr>
    <th>SI No</th>
    <th>From Wallet</th>
    <th>To Wallet</th>
    <th>eMoney Amount</th>
  </tr></thead>
  <tbody>`;
t.extracted_employees.forEach((e, idx) => {
  html += `<tr>
    <td>${idx + 1}</td>
    <td>${t.company || t.depositor_name || '—'}</td>
    <td>${e.account_or_phone}</td>
    <td>${fmt(e.amount)} MMK</td>
  </tr>`;
});
```

4. **NEW AI Analysis side-by-side section** replaces collapsible one:
```
┌────────────────────┬────────────────────┐
│ FROM EMAIL         │ FROM DOCUMENT      │
├────────────────────┼────────────────────┤
│ Company: ABC Co   │ Company: ABC Co   │ ← green if match
│ Initiator: Manager │ Initiator: (N/A)   │ ← yellow if mismatch/missing
│ Amount: 1.5M MMK   │ Amount: 1.5M MMK   │ ← green
│ Pay date: 2026-04-14│ Pay date: (N/A)    │ ← yellow
│ Purpose: Salary    │ Purpose: Salary    │ ← green
│ Cost Center: HR-01 │ Cost Center: HR-01 │ ← green
└────────────────────┴────────────────────┘
```
Render rule: compare email value vs document value. Case-insensitive string match. Green if match or both empty (same = neutral). Yellow if mismatch or one missing.

5. **Replace "Approve & Download CSV" button → "Generate CSV for Finance"**
   - Validation logic (all must be true):
     - `t.company && t.company !== 'Unknown Company'`
     - `t.initiator_name`
     - `t.payment_type`
     - Amount validated (no mismatch from AMOUNT_MISMATCH scenario)
     - `t.payment_date`
     - `t.purpose`
     - `t.cost_center`
     - For MA: all employees have valid phone/account; For OTC: at least one bank account
   - Enabled → existing `approveAndDownloadCSV()` logic (downloads CSV, updates status)
   - Disabled → button grayed out + tooltip "Missing data — see warning below"

6. **"Inform client for missing data" warning panel** (replaces Return button OR complements it):
```javascript
if (!allDataPresent || hasMismatch) {
  const missingFields = [];
  if (!t.company) missingFields.push('Company name');
  if (!t.initiator_name) missingFields.push('Initiator Name');
  // ... etc
  html += `<div class="warning-panel" style="background:#fef3c7;border:1px solid #fde68a;padding:14px 18px;border-radius:8px;margin-bottom:16px">
    <strong style="color:#92400e">⚠️ Inform client for missing data</strong>
    <ul style="margin:8px 0 0 0;padding-left:20px;color:#78350f">
      ${missingFields.map(f => `<li>${f}</li>`).join('')}
    </ul>
    <button class="btn btn-danger" onclick="returnToClient('${t.id}')" style="margin-top:10px">↩ Return to Client with This List</button>
  </div>`;
}
```

**Keep "Return to Client" button** from Wave 3 — it's still the way to trigger the return email. The warning panel enhances it by pre-populating the list of missing fields (operator can use this list as reason text).

### Phase C — Testing (~15 min)
- Send test email → pipeline extracts new fields → dashboard shows complete data
- Send test email with SOME fields missing → warning panel shows missing list, Generate CSV button disabled
- Click Return to Client with warning → email sent with missing-fields list
- Click Generate CSV when complete → CSV downloaded

### Phase D — v11 commit + deployment
- Commit JSON + index.html changes
- Push to both remotes
- DK imports v11 to n8n Cloud, activates, deactivates v10.1 (v10.1 stays as fallback)
- End-to-end verification

**Total effort estimate: ~2.5 hours in fresh session.**

---

## ⚠️ Risks + Mitigations for v11

| Risk | Mitigation |
|---|---|
| Groq extracts garbage for new fields on emails that don't mention them | Default to empty string. Warning panel lists them as missing (operator decides). |
| Side-by-side comparison false-positives on minor formatting differences | Case-insensitive compare + trim whitespace. Near-match fuzzy matching deferred to v13. |
| `from Wallet` placeholder (company name) may confuse Finance | Add tooltip: "Source wallet ID — coming from lookup table in future" |
| Existing v10.1 tickets don't have new fields | Show "N/A" or "Not extracted" for legacy tickets. Not a regression. |
| Test ticket TKT-021 — still in DB | Cleanup task parked post-Apr-20 |

---

## 🧭 Navigation

- **Vinh's spec (source of truth):** `docs/jira/KAN-36_eMoney_Ticket_Detail_Popup.pdf`
- **This plan:** `docs/jira/KAN-36_Analysis_And_Plan.md`
- **Next-session memory:** `memory/project_kan36_implementation_plan.md`
- **Pipeline v10.1 baseline:** `pipelines/n8n-workflow-v10.1.json`
- **Current dashboard code:** `index.html` — key function `openTicketDetail()` around line 3200+

---

## 🔀 Strategic Alignment Check

- ✅ Path A (Anthropic direct API → Bedrock later) confirmed direction
- ✅ v11 does NOT touch models (Groq+Gemini stays) — safe addition
- ✅ v11 field names designed to survive v12 Claude swap
- ✅ Validated-before-bundled approach prevents cascade failures
- ✅ Every new requirement handled within this framework (not tech debt)

This is the right way to absorb new tickets without breaking existing production.
