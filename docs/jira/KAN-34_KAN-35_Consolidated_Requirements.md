# KAN-34 + KAN-35 + Verbal Enhancements — Consolidated Requirements

**Created:** Apr 14, 2026 morning
**Status:** In Progress
**Sources combined:** Jira tickets (KAN-34, KAN-35) + DK–Vinh Teams/verbal conversation this morning
**Rationale:** Per DK's guidance: "verbal conversation can pair with tickets to bring very good documentation" — preserve both formal and informal context so nothing is lost.

---

## 📋 Source Tickets + Context

### Official Jira Tickets
- **KAN-34** — [eMoney] Dashboard UI simplify — High priority, In Progress, DK assignee
  - Source: `docs/jira/KAN-34_eMoney_Dashboard_UI_Simplify.pdf`
- **KAN-35** — [eMoney] Email Return — Medium priority, To Do, Unassigned
  - Source: `docs/jira/KAN-35_eMoney_Email_Return_Date.pdf`
  - ⚠️ Assignee empty — DK should confirm with Vinh before executing (or auto-assume)

### Verbal Context (captured from DK's voice-to-text Apr 14 AM)
- Discussion with Vinh this morning about enhancements beyond KAN-34/35 formal scope
- DK explicitly asked these be preserved alongside Jira tickets
- Three additional asks not yet filed as Jira tickets (Vinh may formalize later)

---

## 🎯 Full Requirements Map (11 items)

### From KAN-34 (Dashboard UI Simplify) — 7 items

| # | Requirement | Scope | Source screenshot |
|---|---|---|---|
| 1 | Hide Finance Approval + E-Money Review tabs | Top nav | KAN-34 screenshot 1 |
| 2 | Hide Intake/Maker badge + Auto/Private/DEMO tags | Top-right | KAN-34 screenshot 1 |
| 3 | Add spacing below "eMoney Dashboard" title | Page title | KAN-34 screenshot 1 |
| 4 | Remove "Created" column from ticket table | Dashboard table | KAN-34 screenshot 2 |
| 5 | Remove "Track A" + "Track B" columns | Dashboard table | KAN-34 screenshot 2 |
| 6 | Display only 2 statuses: "Asked Client" (mismatch/incomplete) or "Ready for Finance" (clean+correct) | Dashboard status column | KAN-34 screenshot 2 |
| 7 | Display only 2 risks: "High" (mismatch/incomplete) or "Low" (clean+correct) | Dashboard risk column | KAN-34 screenshot 2 |

### From KAN-35 (Email Return) — 1 item

| # | Requirement | Scope | Source |
|---|---|---|---|
| 8 | Change "Date time" row in notification → show Payment Date (client's intended pay day), NOT email receive time | Notification email verification status | KAN-35 screenshot |

### From verbal conversation (DK–Vinh Teams, Apr 14 AM) — 3 items

| # | Requirement | Scope | Source |
|---|---|---|---|
| 9 | Add "Payroll Period" as a SEPARATE new row in notification verification status (distinct from Payment Date) — shows the period salary covers (e.g., "March 2026") | Notification email verification status | Verbal — DK morning message |
| 10 | Add "Return to Client" action button on dashboard (per ticket) — sets ticket to ASKED_CLIENT status when AI extraction or vision check is incorrect | Dashboard ticket row/modal | Verbal — DK morning message |
| 11 | Add "Approve & Download Employee CSV" action button on dashboard — generates CSV client-side from `extracted_employees` array + marks ticket ready for Finance | Dashboard ticket row/modal | Verbal — DK morning message |

---

## ⚠️ Important Clarity — Payment Date vs Payroll Period

Per DK's verbal emphasis: these two date concepts **MUST be visually distinct** to avoid Ops confusion.

| Term | Definition | Example |
|---|---|---|
| **Payment Date (Pay Day)** | The specific date the client wants the salary to be disbursed | "April 20, 2026" |
| **Payroll Period** | The time range the salary covers (worked period) | "March 2026" or "Apr 1-15, 2026" |

Both fields will appear as **separate rows** in the verification checklist for clarity.

---

## 🎯 Execution Plan — 4 Waves

### Wave 1 — Pipeline v10.1: Payment Date + Payroll Period (items #8, #9)
**Effort:** ~30-40 min
**Risk:** Low (additive fields + template change)
**Files touched:** `pipelines/n8n-workflow-v10.json` (clone to v10.1) OR in-place edit
**Fallback:** v10 stays active until v10.1 tested

Changes:
- Groq AI Extract prompt: add `payment_date` + `payroll_period` to JSON schema with examples
- AI Parse & Validate: pass both fields through to ticket output
- Send Outlook Notification: rename "Date time" row → "Payment Date" + add new "Payroll Period" row
- Verification object: replace `date_time` boolean with `payment_date` + `payroll_period` booleans

### Wave 2 — Dashboard UI Simplify (items #1-#7)
**Effort:** ~50 min
**Risk:** Low (all changes in single file, additive removals)
**Files touched:** `index.html`
**Fallback:** `git revert` per-block

Changes:
- Extend `body.emoney-view` CSS: hide `#nav-finance`, `#nav-emoney`, `.role-badge`, `#role-select`, `.nav-tag` (auto/private/demo)
- Add margin-top to first `.summary-row-3` or margin-bottom to `.section-title`
- In ticket table header: remove Created, Track A, Track B `<th>`
- In ticket row render: remove corresponding `<td>` cells (keep data, just hide columns)
- Status display logic: collapse all status values to either "Asked Client" or "Ready for Finance" based on `has_mismatch || !approval_matrix_complete`
- Risk display logic: collapse to "High" / "Low" based on same condition

### Wave 3 — Dashboard Action Buttons (items #10, #11)
**Effort:** ~1.5 hrs
**Risk:** Medium (new UI + CSV generation logic)
**Files touched:** `index.html`
**Fallback:** `git revert`

Changes:
- Add 2 buttons to ticket detail modal footer:
  - 🔴 "Return to Client" — prompts for reason → updates ticket status to `ASKED_CLIENT` + writes activity log entry
  - 🟢 "Approve & Download Employee CSV" — generates CSV from `state.tickets[id].extracted_employees` → triggers browser download + updates `finance_status = 'APPROVED'`
- Use existing `showToast()` for feedback
- CSV format: `Name,Phone/Account,Amount` header + row per employee

### Wave 4 — Cleanup + Close-out
**Effort:** ~15 min
**Risk:** Zero

Actions:
- Clean up TKT-021 test ticket from Supabase (SQL in `KAN-30_KAN-31_Delivery_Messages.md`)
- Close KAN-30 + KAN-31 in Jira UI (comments pre-drafted)
- Ping Vinh in Teams confirming KAN-34 + KAN-35 completion + reference to verbal enhancements
- Optional: ask Vinh if he wants to formalize #9, #10, #11 as new Jira ticket or accept internal documentation

---

## 📊 Progress Tracking

| Item | Wave | Status | Commit | Date |
|---|---|---|---|---|
| #1 Hide Finance + E-Money tabs | 2 (then Wave 3B superseded) | ✅ Done | `3064498` → `f96dfef` → Wave 3B moved to nav | 2026-04-13 + 14 |
| #2 Hide badges (Intake/Auto/Private/DEMO) | 2 | ✅ Done | `a31bd78` | 2026-04-14 |
| #3 Spacing below Dashboard title | 2 | ✅ Done | `a31bd78` | 2026-04-14 |
| #4 Remove Created column | 2 | ✅ Done | `a31bd78` | 2026-04-14 |
| #5 Remove Track A + Track B columns | 2 | ✅ Done | `a31bd78` | 2026-04-14 |
| #6 Simplify status to 2 values | 2 | ✅ Done | `a31bd78` | 2026-04-14 |
| #7 Simplify risk to 2 values | 2 | ✅ Done | `a31bd78` | 2026-04-14 |
| #8 Payment Date (KAN-35) | 1 | ✅ Done | `3e748f8` | 2026-04-14 |
| #9 Payroll Period (verbal enhancement) | 1 | ✅ Done | `3e748f8` | 2026-04-14 |
| #10 Return to Client button (Option A + B) | 3 | ✅ Done | `cff29b5` → `cb7d59d` (payload fix) → `b82454f` (preview modal) → `32e0be2` (z-index) → `0504e9a` (loop guard) | 2026-04-14 |
| #11 Approve & Download CSV button | 3 | ✅ Done | `09b4cac` | 2026-04-14 |
| Verbal: Remove Auto badge from table | 2b | ✅ Done | `84ba23a` | 2026-04-14 |
| Verbal: Dashboard pagination (10/page) | 2b | ✅ Done | `84ba23a` | 2026-04-14 |
| Verbal: Auto badge also removed from modal | 3A | ✅ Done | `7c08b2f` | 2026-04-14 |
| Verbal: Activity Log as new top-nav tab | 3B | ✅ Done | `72d1e14` | 2026-04-14 |
| Verbal: Activity Log pagination + search | 3F | ✅ Done | `b869c61` | 2026-04-14 |
| Verbal: CSV re-download from approved banner | 3G | ✅ Done | `686f880` | 2026-04-14 |
| TKT-021 cleanup | Deferred | 🟡 Post-Apr-20 | — | — |
| Jira close-out (KAN-34, KAN-35) | 4 | ⏳ Ready (see KAN-30_KAN-31_Delivery_Messages.md for prepared comments) | — | — |

**Net: 17/17 requirements shipped. TKT-021 cleanup deferred to post-Apr-20 (safe — test ticket, not blocking).**

**Session total commits today (Apr 14): 13 commits from baseline `4a28bd1`**
- Wave 1: `3e748f8`
- Wave 2: `a31bd78`
- Wave 2b: `84ba23a`
- Wave 3A: `7c08b2f`
- Wave 3B: `72d1e14`
- Wave 3C: `ed1a840` (n8n workflow JSON — DK imported into consolidated workflow)
- Wave 3E: `09b4cac`
- Wave 3G: `686f880`
- Wave 3F: `b869c61`
- Wave 3D: `cff29b5`
- Wave 3D fix: `cb7d59d`
- Wave 3D-B: `b82454f`
- Wave 3D-B z-index fix: `32e0be2`
- Loop guard fix: `0504e9a`
- Wave 3 plan/audit doc: `30633a5`

---

## 🔴 Rollback Strategy

Each Wave commits separately → `git revert <SHA>` for single-wave rollback.
Pipeline v10.1 → v10 fallback in n8n Cloud (instant).
Session baseline: commit `4a28bd1` (end of KAN-30/31 work).

## 🎨 Stakeholder Messaging Note

When delivering, be explicit about verbal enhancements:
- "KAN-34 + KAN-35 done as specified"
- "Also added: Payroll Period field (per your morning note) + dashboard action buttons (per your dashboard-only vision)"
- "If you want KAN-36 filed for the verbal ones, happy to — otherwise we keep internal docs"
