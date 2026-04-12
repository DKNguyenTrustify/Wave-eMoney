# Wave EMI — Stabilization + Hardening Plan (Pre Go-Live Apr 19)

**Date:** April 12, 2026
**Context:** Schema refactoring succeeded. 7 days buffer before go-live. Time to harden, not ship new features.
**Pending inputs:** Win's team feedback, batch/unbatch spec from DK

---

## Executive Summary

We've proven the system works end-to-end (TKT-019 verified). Now the goal shifts from "can it work?" to "will it hold up under real production pressure?" This plan addresses bugs found today plus proactive hardening across **stability, security, scalability, and future features**.

Three buckets, executed in order:
1. **Known bugs** — fix the 2 cosmetic issues from today
2. **Security hardening** — things that should be fixed BEFORE real client data enters the system
3. **Future-proofing** — structural choices that make adding features easier

---

## Part 1: Known Bugs (from today's testing)

### Bug 1.1: Attachment count shows 0 when files exist
**Severity:** Low (cosmetic) | **Effort:** 10 min | **Risk:** Minimal

**Symptom:** Email with PDF attached shows "Attachments: 0 file(s)" in notification. Dashboard also shows wrong count in some places.

**Root cause:** `Prepare for AI v3` node's `scanParts()` only handles Gmail's `payload.parts` format. Outlook binaries go to `item.binary` but metadata (`attachment_names`, `attachment_count`) never populated.

**Fix:** In the `if (item.binary)` loop, push `meta.fileName` to `attachment_names` array. Set `attachment_count = attachment_names.length` in output.

**Deliverable:** Pipeline v9.

### Bug 1.2: SafeLinks wraps URLs (Microsoft 365 behavior, not our bug)
**Severity:** Cosmetic | **Effort:** Varies | **Risk:** Zero (works anyway)

**Symptom:** Our clean `https://project-ii0tm.vercel.app/?ticket=TKT-019` becomes a 400-char SafeLinks URL in the delivered email.

**Root cause:** Microsoft 365 policy on `emoney@zeyalabs.ai` tenant. Outside our control.

**Options:**
- **A (do nothing):** SafeLinks redirects correctly. Every corporate user sees this. Clients don't question it.
- **B (IT ticket):** Ask Vinh/Tin's admin to disable SafeLinks outbound rewriting for this mailbox. Not trivial, likely denied for security reasons.
- **C (workaround):** Send URL as plain text without `https://` prefix. Ugly, manual copy-paste.

**Recommendation:** Option A. Revisit post-go-live only if Minh raises concern.

---

## Part 2: Security Hardening (CRITICAL — identified today)

These should be addressed BEFORE real client employee data enters the system.

### Security 2.1: Webhook endpoint has zero authentication
**Severity:** HIGH | **Effort:** 30 min | **Risk:** Critical in production

**Issue:** `api/webhook.js` accepts POST from anywhere on the internet. Anyone who discovers the URL can create fake tickets, including fake client emails with attachments.

**Fix:** Add a shared secret header check:
```javascript
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;
if (req.headers['x-webhook-secret'] !== WEBHOOK_SECRET) {
  return res.status(401).json({ error: 'Unauthorized' });
}
```
Add secret to Vercel env vars AND to n8n Parse & Validate node's HTTP request.

### Security 2.2: Supabase Storage bucket is PUBLIC
**Severity:** HIGH | **Effort:** 45 min | **Risk:** Data exposure

**Issue:** `attachments` bucket is public. Anyone with a guessed URL (`dicluyfkfqlqjwqikznl.supabase.co/storage/v1/object/public/attachments/TKT-019/file.pdf`) can download client bank slips and employee lists containing phone numbers.

**Fix:**
- Change bucket to PRIVATE
- Generate signed URLs (expire after 1 hour) when dashboard requests access
- Update dashboard code to fetch signed URLs on demand
- Requires Supabase service role (already in webhook env)

### Security 2.3: RLS policies missing on new tables
**Severity:** HIGH | **Effort:** 1 hour | **Risk:** Anon key can read/write everything

**Issue:** We created 5 new tables (`tickets_v2`, etc.) but no Row Level Security policies. Anyone with the anon key (which is in the client code!) can SELECT/INSERT/UPDATE/DELETE all rows.

**Fix:**
- Enable RLS on all 5 tables
- Dashboard reads via signed session, not anon key (post-auth)
- For now, interim: anon key = read-only, writes only via webhook (service role)
- Post go-live: implement Supabase Auth for users

### Security 2.4: CORS is wide open
**Severity:** Medium | **Effort:** 15 min | **Risk:** Cross-site attacks

**Issue:** `res.setHeader('Access-Control-Allow-Origin', '*')` accepts requests from any origin.

**Fix:** Whitelist only Vercel deployments:
```javascript
const ALLOWED_ORIGINS = [
  'https://project-ii0tm.vercel.app',
  'https://wave-emi-dashboard.vercel.app',
  'https://tts-test.app.n8n.cloud'
];
```

### Security 2.5: Anon key exposed in client code
**Severity:** Medium (by design for Supabase) | **Effort:** N/A | **Risk:** Inherent

**Issue:** The anon key is visible in the browser. With RLS misconfigured, this is a disaster. With RLS configured properly, this is fine (Supabase's intended usage).

**Fix:** Covered by 2.3 (enable RLS). Once RLS is correct, the anon key exposure is safe.

---

## Part 3: Future-Proofing (Structural)

### Feature 3.1: Multiple attachments per email
**Severity:** Feature gap | **Effort:** 2 hours | **Risk:** Medium (pipeline change)

**Current:** Pipeline's `Prepare for AI v3` only extracts first attachment.
**Database:** Already supports unlimited (1:many relation).

**Fix:** Loop through ALL binary attachments, upload each to Storage, insert each into `ticket_attachments`. Run vision on each relevant one.

**Impact:** Client sends email with bank slip + employee list + receipt → all 3 preserved. Currently 2 are lost.

### Feature 3.2: Multiple emails per ticket (follow-ups, corrections)
**Severity:** Feature gap | **Effort:** 4 hours | **Risk:** Medium

**Current:** Each email creates a new ticket.
**Database:** Already supports via `ticket_emails` 1:many.
**Missing:** Logic to link incoming email to existing ticket (by thread_id, subject match, or manual).

**Fix:** In webhook, detect if `thread_id` or `message_id` references an existing ticket. If yes, insert new `ticket_emails` row; don't create new ticket.

### Feature 3.3: Idempotency on webhook
**Severity:** Reliability | **Effort:** 30 min | **Risk:** Low

**Issue:** If n8n retries a webhook call (network glitch), we create duplicate tickets.

**Fix:** Check if `message_id` already exists in `ticket_emails`. If yes, return existing ticket_id without creating new one.

### Feature 3.4: Supabase VIEW performance at scale
**Severity:** Performance | **Effort:** 30 min benchmark | **Risk:** Low

**Issue:** `tickets_flat` uses 4 LATERAL JOINs. Fine at 20 rows. What about 10,000?

**Fix:**
- Benchmark with 10,000 synthetic rows
- If slow: add composite indexes on `(ticket_id, created_at DESC)` for each child table
- Ultimate fix: materialized view refreshed on trigger (only if needed)

### Feature 3.5: Vercel serverless timeout for webhook
**Severity:** Reliability | **Effort:** 15 min | **Risk:** Low

**Issue:** Webhook does 6 sequential DB operations + attachment upload. On Vercel Hobby (10s timeout), could fail for large PDFs.

**Fix:**
- Parallelize independent inserts (emails, vision, extraction — all independent)
- Vercel Pro timeout is 60s (we're on Pro)
- Add timing logs to measure actual duration

---

## Part 4: Go-Live Features (spec-dependent)

### 4.1 Batch/Unbatch (waiting on DK's spec)
**Blocker:** Need Win's or DK's spec
**Database:** Already designed — add `batch_id` FK to tickets_v2 + create `batches` table
**Dashboard:** New "Batches" view, multi-select checkboxes on ticket list, "Create Batch" button

### 4.2 Finance Exemption List
**Blocker:** Need master list from Thet Hnin Wai (mentioned: MEB, YESC, MESC, SSB)
**Database:** Add `finance_exempt` boolean or separate `finance_exempt_clients` table
**Dashboard:** Auto-skip finance step when exempt client detected

### 4.3 Audit Confirmation Form
**Blocker:** Need Rita's spec on what fields to capture
**Database:** Add `audit_confirmation` JSONB field or separate table
**Dashboard:** New step at end of workflow — tick-box form with digital signature

---

## Part 5: Code Quality / Tech Debt

### 5.1 Dead code cleanup
- Delete `api/webhook-legacy.js` after v2 webhook verified in production
- Remove `generateTicketId()` from `index.html` (no longer used — DB trigger handles)
- Remove `checkN8nWebhook()` `?n8n_ticket=` branch (legacy, replaced by `?ticket=`)
- Drop old `tickets` table (safety net no longer needed after go-live verified)

### 5.2 Dashboard write-path full testing
Not all user actions tested against new schema. Need to verify:
- [ ] Finance approval (approve + reject) saves to tickets_v2
- [ ] Employee list upload populates `employee_data`
- [ ] Checker approval updates `sent_to_checker`, `checker_name`
- [ ] Group mapping (OTC) saves mapping state
- [ ] Disbursement monitoring saves `monitor_results`
- [ ] Closing saves `closed: true` + archive

### 5.3 Index.html splitting (deferred per memory)
2,800+ line single file. Split when NextJS rewrite happens (KAN-26 post go-live).

### 5.4 createTicketFromN8n() cleanup
Still has old flat-schema logic. With new architecture, this function only handles legacy `?n8n_ticket=` URLs. Can simplify or delete entirely.

---

## Part 6: Monitoring + Observability

### 6.1 Error tracking
**Current:** `console.warn()` scattered across code.
**Needed:** Structured logging, ideally Sentry or Vercel logs dashboard.

### 6.2 Health check endpoint
Add `api/health.js` that verifies:
- Supabase connection
- Storage bucket access
- Recent ticket creation (e.g., "last ticket < 1 hour ago" = healthy)

### 6.3 Activity log review UI
Currently we have `activity_log` table but no dashboard view. Useful for debugging production issues.

---

## Recommended Execution Order

When DK returns, execute in this order:

### Day 1 (Today/Tomorrow — ~4 hours)
1. **Pipeline v9** — attachment count fix (Bug 1.1) — 15 min
2. **Security 2.1** — webhook authentication — 30 min
3. **Security 2.4** — CORS whitelist — 15 min
4. **Feature 3.3** — webhook idempotency — 30 min
5. **Section 5.2** — write-path testing (all user actions) — 2 hours
6. **Save/commit/push** — 15 min

### Day 2 (before Apr 17 — ~4 hours)
7. **Security 2.2** — private Storage bucket + signed URLs — 45 min
8. **Security 2.3** — RLS policies — 1 hour
9. **Feature 3.1** — multi-attachment pipeline — 2 hours
10. **Receive Win's feedback + DK's spec, integrate into plan** — varies

### Day 3 (Apr 15-18 — ~4 hours)
11. **Go-live features** (whichever specs arrived)
12. **Feature 3.2** — multi-email thread linking (if time)
13. **Section 6.2** — health check endpoint
14. **Full end-to-end rehearsal** — 1 hour

### Day 4 (Apr 18 — final prep)
15. **Section 5.1** — dead code cleanup
16. **Documentation pass** — update all memory files
17. **Go-live checklist** — verify every deploy, every backup

### Apr 19 (GO-LIVE)
18. Watch monitor. Fix blockers only. Defer everything else.

---

## Pending Inputs from DK

**To be integrated when received:**
1. **Batch/unbatch spec** — from DK/Win. Will drive feature 4.1.
2. **Win's team feedback** — will likely add items to Parts 1-5.
3. **Internal Singapore Day 10 meeting transcription** — DK mentioned Gemini transcribed it; needs speaker attribution + insight extraction.
4. **Finance exemption master list** — from Thet Hnin Wai. Drives feature 4.2.

---

## Decisions Needed from DK

1. **SafeLinks** — Accept (Option A) or escalate to IT (Option B)?
2. **Auth strategy** — Anon key + RLS (simple) OR full Supabase Auth with logins (proper)?
3. **Multi-attachment priority** — tackle before go-live or after?
4. **Old `tickets` table** — drop Apr 19 or wait 1 week post go-live?
5. **Webhook secret** — who holds the secret (Vinh, Tin, or shared)?

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Real client data leaks via public Storage bucket | HIGH | HIGH | Security 2.2 before go-live |
| Webhook spammed by attacker creating fake tickets | MEDIUM | HIGH | Security 2.1 before go-live |
| n8n trial expires mid-weekend | MEDIUM | HIGH | PM handles (Minh commitment) |
| Vercel deployment lag between repos (Hobby vs Pro) | LOW | LOW | Verify both after every push |
| Supabase anon key compromised | HIGH (already public) | HIGH with bad RLS | Security 2.3 mandatory |
| Batch/unbatch spec arrives late | HIGH | MEDIUM | Build UI without spec using placeholder logic |
| Multi-attachment emails before Feature 3.1 ships | MEDIUM | MEDIUM | Current system stores 1, loses others silently. Document as known limitation. |

---

## Notes for the Session Resume

When DK comes back:
- This plan is the master document. Review, adjust, then execute top-down.
- DK may have NEW feedback from Win's team — integrate into Part 1 or Part 4.
- DK may finally share batch/unbatch spec — unblocks Part 4.1.
- DK may share transcription — separate task, not in this plan.
- Everything saved to memory (see `MEMORY.md`).

**Priority call:** If time is tight before go-live, the MUST-DO list is:
- Security 2.1 (webhook auth)
- Security 2.2 (private Storage)
- Security 2.3 (RLS)
- Bug 1.1 (attachment count)

Everything else is nice-to-have.
