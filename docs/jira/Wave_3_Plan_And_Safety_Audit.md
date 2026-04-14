# Wave 3 — Plan, Safety Audit & Session Progress Review

**Date:** Apr 14, 2026 morning (during DK's meeting)
**Context:** DK requested thorough review before committing to Wave 3 execution.
**Status:** ⏸️ PAUSED — awaiting DK's explicit go-ahead after review.

---

## PART 1 — Full Session Progress Audit (today, Apr 14)

### Commits shipped + verified

| SHA | Description | Items covered | Verified |
|-----|-------------|---------------|----------|
| `3e748f8` | Wave 1: Pipeline v10.1 — Payment Date + Payroll Period | KAN-35 #1, verbal #9 | ✅ TKT-024 notification confirms |
| `a31bd78` | Wave 2: Dashboard UI Simplify | KAN-34 #1-#7 | ✅ Screenshot (3 cards, tabs hidden, 7 cols, simplified status/risk) |
| `84ba23a` | Wave 2b: Auto badge (table) + Pagination | Verbal quick-wins A & B | ✅ Screenshot (Page 2/3, Prev/Next, no Auto badge in rows) |

### End-to-end verification results (TKT-024)

**Pipeline v10.1:**
- ✅ Ticket ID at top: "TKT-024"
- ✅ Payment type: "SalaryToMA (with employee list)"
- ✅ Attachment: "1 file(s): payroll_demo_12emp.jpg" (bug fixed, shows filename)
- ✅ 8-row verification checklist rendering
- ✅ Payment date row: "2026-04-18" (NEW from KAN-35)
- ✅ Payroll period row: "March 1 to March 31, 2026" (NEW from verbal #9)
- ✅ Approval check: Sales HOD + Finance Manager matched
- ✅ Employee list: 12 employees extracted (100% extraction rate)

**Dashboard:**
- ✅ Ticket count: 23 → 24 (TKT-024 appeared)
- ✅ MA badge (not OTC — because 12 employees extracted → salarytoMA)
- ✅ Low risk badge
- ✅ Vision 85% confidence
- ✅ Document type: payroll_form
- ✅ 7-column table (no Created, no Track A/B)
- ✅ Pagination: "Showing 11-20 of 23 tickets" with working Prev/Next

### Known issues / observations from verification

| # | Observation | Severity | Status | Action |
|---|-------------|----------|--------|--------|
| 1 | "Auto" badge STILL shows in ticket detail modal header | LOW | Not fixed | Fix in Wave 3 |
| 2 | TKT-024 amount = 0 MMK | EXPECTED | Not a bug | Email didn't specify; next test add `Total Amount: 4,730,000 MMK` |
| 3 | Three-Way Match shows ❌ | PRE-EXISTING | Not KAN-30 | Dashboard's own amount-check UI; pipeline still classifies NORMAL |
| 4 | Vision extracted N/A for total_amount | PRE-EXISTING | Not KAN-30 | Vision Process doesn't sum rows — quirk from prior work |

**All Vinh requirements from official tickets + verbal asks are VERIFIED.**

---

## PART 2 — Wave 3 Scope Recap

### Items to deliver

From verbal conversation with Vinh (Apr 14 AM) + today's TKT-024 observation:

| # | Feature | Type | Origin |
|---|---------|------|--------|
| 1 | "Return to Client" button in ticket detail modal | NEW UI | Verbal #10 |
| 2 | "Approve & Download Employee CSV" button | NEW UI + CSV generation | Verbal #11 |
| 3 | Remove "Auto" badge from ticket detail modal header (line 2911 in index.html) | POLISH | Observation from TKT-024 test |

### Files affected
- `index.html` ONLY (no pipeline changes, no DB schema changes)

---

## PART 3 — Safety Audit (9 risks evaluated)

### 🟢 LOW RISK items

**Risk 1: Remove Auto badge from modal (line 2911)**
- Change scope: delete one line
- Rollback: trivial (`git revert`)
- Verdict: **SAFE**

**Risk 2: CSV generation from `t.extracted_employees`**
- Data already exists on ticket (verified on TKT-024: 12 employees with name/phone/amount)
- Pure client-side JS (Blob + download link)
- Standard UTF-8 BOM for Excel/Myanmar text compatibility
- No network call, no server state
- Rollback: trivial
- Verdict: **SAFE** if we add graceful handling when array is empty

**Risk 3: Button placement in modal**
- Existing modal has "Save & Submit for Finance" + "Upload Employee List" at line 3012-3015 (inside upload zone block, conditional on `!t.prechecks_done`)
- Adding new buttons in a NEW dedicated section near modal TOP (right after header) avoids touching existing layout
- Verdict: **SAFE** if we add buttons in new area, not modify existing

### 🟡 MEDIUM RISK items

**Risk 4: Status change on "Return to Client"**
- Updates `t.status = 'ASKED_CLIENT'`
- Updates `state.tickets[id]` (in-memory)
- Calls `saveState()` which persists to localStorage + syncs to Supabase (via existing code path)
- Adds activity log entry
- Rollback: If status write fails, the `saveState()` pattern handles errors silently (we already validated this pattern works)
- Verdict: **MODERATE** — mitigation: use existing `saveState()` + `logActivity()` helpers, same pattern as `handleN8nSubmit`

**Risk 5: "Approve" sets `finance_status = 'APPROVED'`**
- Same pattern as Risk 4
- Additional: mark `prechecks_done = true` so ticket shows "Done" in Track A
- Verdict: **MODERATE** — same mitigation

**Risk 6: Modal state after action**
- After Return/Approve, modal should close + dashboard should re-render
- Existing pattern: `document.getElementById('ticket-detail-modal').classList.remove('open')` + `renderDashboard()`
- Verdict: **SAFE** if we follow existing pattern (seen at line 2915 for close button)

### 🔴 HIGHER RISK items (worth flagging)

**Risk 7: CSV format — start simple, don't over-engineer**
- Vinh's verbal ask: "Finance can download this file as a CSV or spreadsheet or whatsoever"
- TEMPTATION: implement Utiba-format CSVs (File 1, File 2, SalaryToMA, SalaryToOTC, etc. — 7 formats)
- REALITY: Wave 3 should ship the minimum viable — simple 3-column CSV (Name, Phone, Amount)
- Utiba formats are a separate KAN-XX ticket (already partially built in E-Money Review page)
- Verdict: **SAFE** if scope stays narrow; **RISKY** if we attempt Utiba formats tonight

**Risk 8: "Return to Client" — operational implications**
- In real production, this should trigger an email back to client with reason
- For Apr 20 demo (fake data): just update status + log activity, no email sent
- Decision: DEMO MODE — no email sent. Document as "production TODO"
- Verdict: **SAFE** for demo scope, risks production gap later (not our Apr 20 problem)

**Risk 9: What if Vinh later says "I didn't want that feature"**
- Verbal-only ask, no Jira ticket (yet)
- If Vinh reverses: `git revert <SHA>` removes buttons cleanly
- No irreversible state changes (new buttons are purely additive)
- Verdict: **SAFE** — full rollback available

### Overall verdict

**Wave 3 is SAFE to proceed IF we:**
- ✅ Keep scope narrow: 2 buttons + Auto badge fix (NOT Utiba formats)
- ✅ Use existing `saveState()`, `logActivity()`, `showToast()` patterns
- ✅ Place buttons in a NEW section (top of modal, below header) without modifying existing button areas
- ✅ Handle empty `extracted_employees` gracefully (disable Approve+CSV or show tooltip)
- ✅ Commit each sub-item as a separate testable change:
  - Commit A: Auto badge removal
  - Commit B: Return to Client button + handler
  - Commit C: Approve & Download CSV button + handler + CSV generation

**Wave 3 is UNSAFE IF we:**
- ❌ Try to generate Utiba-format CSVs (too ambitious for tonight)
- ❌ Add real email-sending for Return to Client (not needed for demo)
- ❌ Modify existing modal button logic (risk breaking current flow)
- ❌ Batch all 3 sub-items into one commit (lose granular rollback)

---

## PART 4 — Detailed Wave 3 Implementation Plan

### Architecture decisions (before coding)

1. **Button placement:** New "Quick Actions" row immediately after modal header (line 2916), before Amount Verification section. Visible above-the-fold, high priority.

2. **Button styling:**
   - 🔴 "Return to Client" → `btn btn-danger` (red, destructive)
   - 🟢 "Approve & Download CSV" → `btn btn-success` (green, positive)
   - Additional: tooltip if Approve is disabled (no employees)

3. **Return to Client flow:**
   - Click button → `prompt()` for reason (simple, no custom modal)
   - Update `t.status = 'ASKED_CLIENT'`
   - Update `t.return_reason = reasonText`
   - Add activity log entry: `"TKT-XXX returned to client: [reason]"`
   - Call `saveState()`
   - `showToast('Returned to client', 'warning')`
   - Close modal + re-render dashboard

4. **Approve & Download flow:**
   - Click button → immediately check `t.extracted_employees.length > 0` (else toast "No employee list available")
   - Generate CSV string with UTF-8 BOM
   - Create Blob + download link
   - Trigger download: `TKT-XXX_employees.csv`
   - Update `t.finance_status = 'APPROVED'`
   - Update `t.prechecks_done = true` (so Track A shows Done)
   - Add activity log: `"TKT-XXX approved by user · CSV downloaded"`
   - Call `saveState()`
   - `showToast('Approved + CSV downloaded', 'success')`
   - Close modal + re-render dashboard

5. **CSV format (simple, effective):**
   ```csv
   Name,Phone/Account,Amount (MMK)
   U Aung Min,09781234567,350000
   Daw Mya Mya,09876543210,280000
   ...
   TOTAL,,4730000
   ```
   - Header row + per-employee rows + TOTAL footer
   - UTF-8 BOM prefix for Excel compatibility on Windows (Myanmar text)
   - Comma separator, quoted fields if contain commas

### Exact code locations

| Change | Line in index.html | What to do |
|--------|-------------------|-----------|
| Remove Auto badge | 2911 | Delete entire line (keep other badges) |
| Add Quick Actions section | After line 2916 | Insert new div with 2 buttons |
| Add `returnToClient()` fn | Near line 2897 (before openTicketDetail) | New global function |
| Add `approveAndDownloadCSV()` fn | Same area | New global function |
| Add `generateEmployeeCSV()` helper | Same area | CSV string builder with BOM |

### Effort estimate (conservative)
- Auto badge removal: 5 min (single line edit + commit + push)
- Return button + handler: 25 min (HTML + onClick + saveState integration)
- Approve button + CSV logic: 35 min (HTML + CSV generator + download trigger + saveState)
- Testing across all 3 commits: 15 min
- **Total: ~80 min**

### Rollback strategy per commit

| Wave 3 commit | Rollback command | Impact |
|---------------|-----------------|--------|
| Auto badge removal | `git revert <SHA>` | Auto badge returns to modal |
| Return button | `git revert <SHA>` | Button disappears, no status change |
| Approve button | `git revert <SHA>` | Button disappears, no CSV download |

---

## PART 5 — What NOT to Do (discipline boundaries)

1. ❌ Do NOT implement Utiba CSV formats — defer to separate ticket post-Apr-20
2. ❌ Do NOT send actual emails on "Return to Client" — demo mode, fake data
3. ❌ Do NOT modify existing "Save & Submit for Finance" or "Upload Employee List" buttons
4. ❌ Do NOT touch the Amount Check / Three-Way Match logic (pre-existing, not our concern)
5. ❌ Do NOT add database schema changes (all state changes go through existing saveState())
6. ❌ Do NOT bundle 3 sub-items into 1 commit (lose granular rollback ability)
7. ❌ Do NOT skip the manual verification step between each commit

---

## PART 6 — My Recommendation

**Green light for Wave 3** — but with STRICT scope discipline.

**Proposed execution once DK returns and approves:**

1. **Pre-flight (2 min):** Verify git clean, latest HEAD `84ba23a`, Vercel + n8n both showing current state
2. **Commit A (5 min):** Remove Auto badge from modal + test (refresh dashboard, open any ticket, Auto badge gone)
3. **Commit B (25 min):** Return to Client button + handler + test (open TKT-024, click Return, enter reason "test reason", verify status changes to ASKED_CLIENT, modal closes, ticket shows "Asked Client" in list)
4. **Commit C (35 min):** Approve button + CSV download + test (open TKT-024, click Approve, verify CSV downloads with 12 employees + total row, status updates to Ready for Finance)
5. **Final verification (5 min):** Full dashboard state check, all changes visible, no regressions on other tickets
6. **Update consolidated requirements doc** progress table to reflect Wave 3 done

**Total ~1.5 hours of focused execution.**

**Then Wave 4** (TKT-021 cleanup + Jira close-outs + Vinh message) should be another 15-20 min.

---

## 🚦 AWAITING DK's EXPLICIT GO-AHEAD

Before I touch any code for Wave 3, DK needs to confirm:
1. ✅ Scope is correct (2 buttons + Auto badge fix — nothing more)
2. ✅ CSV format is fine as simple 3-column (not Utiba)
3. ✅ Demo mode for Return (no email sent) is acceptable
4. ✅ Button placement at top of modal is OK
5. ✅ Green light to start

**Until DK says go, I am PAUSED.**
