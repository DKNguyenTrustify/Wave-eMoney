# AI Council Round 6 — KAN-46 Zero-Waste Execution Architecture

## TL;DR

We shipped v13.0 (Spooler + Worker + Supabase queue) successfully on Apr 17, 2026. End-to-end pipeline **proven working** (ticket TKT-053, full chain, notification delivered). However, the Worker's Cron trigger at 30s interval burns ~2,880 executions/day — **unsustainable** on n8n Cloud trial (1,000/month cap, 902 remaining, 13 days until May 1).

**Myanmar team begins gradual stress testing Monday Apr 20 and continues for the week**. We need the architecture with **absolute minimum n8n executions** while staying responsive.

Previous attempts and my own hybrid proposal all still waste executions. **Find better.**

---

## 1. Architecture context (what's actually deployed right now)

### Stack
- **n8n Cloud trial** at `tts-test.app.n8n.cloud` — trial ends ~May 1, 2026
- **Supabase Pro** at `dicluyfkfqlqjwqikznl.supabase.co` (Singapore region, not free tier)
- **Outlook mailbox** `emoney@zeyalabs.ai` (Zaya Labs Azure AD tenant — admin = Ryan, NOT our tenant, we cannot register an app there without tenant admin consent — see Round 5)
- **Dashboard** on Vercel Pro at `project-ii0tm.vercel.app` (single-file HTML/JS, vanilla)
- **Gemini API** (consumer tier, model `gemini-2.5-flash`)
- **Groq API** (still wired for text extract, model `llama-3.3-70b`)

### Shipped workflows (git commit `e62b3e9`)

**Spooler v1** — fast ingest (<5 sec per email)
- Triggers: Microsoft Outlook Polling (every 1 min) + Webhook (manual test path)
- Flow: trigger → Code node (extract metadata + base64 attachments, max 5, 4MB each) → POST to Supabase `/rest/v1/email_queue` with `Prefer: resolution=ignore-duplicates`
- 3x retry with 2s delay on Supabase POST failure
- `UNIQUE(message_id)` DB-level dedup
- Loop guard: skips `emoney@zeyalabs.ai` self-sends before queueing
- **Observed execution time: 1.5-3.7 sec**

**Worker v1** — serial processor (30-120 sec per job)
- Triggers: Cron "every 30 seconds" — **THE PROBLEM**
- Flow: Cron → Claim & Reconstitute (calls `claim_next_email_job` RPC, rebuilds item.json+item.binary to match Outlook Trigger shape) → Prepare for AI v3 → Skip Filter → Gemini 3 Extract → AI Parse & Validate v3 → Send Outlook Notification → Mark Complete (via `mark_email_completed` RPC)
- Rejection branch: Is Rejection Email? (empty_body) → Send Rejection Email → Mark Complete
- **Observed execution time when claimed: ~22-24 sec (inc. Gemini); when idle: ~1 sec (empty queue result)**

**Supabase schema** (`sql/kan46_schema_v1.sql`)
- `email_queue` table: id BIGSERIAL, message_id TEXT UNIQUE, from_address, subject, received_at, status, attempts, payload JSONB, error_message, notification_sent BOOLEAN, locked_at, locked_by, completed_at, created_at, updated_at
- Status state machine: `pending → processing → completed | failed`
- 4 RPCs: `claim_next_email_job` (FOR UPDATE SKIP LOCKED + 5-min TTL recovery), `claim_notification`, `mark_email_completed`, `mark_email_failed`
- 2 views: `email_queue_summary` (counts by status), `email_queue_stuck` (rows locked >5 min)
- RLS enabled, service_role = full, anon = SELECT on views only

**Dashboard Pipeline Queue card**
- Client-side JS calls `sb.from('email_queue_summary').select()` every 5 sec
- Shows `Pending / Processing / Completed / Failed` counts
- Auto-shows stuck badge if `email_queue_stuck` returns rows
- "Watch the queue drain" demo narrative works visually

### Verified working end-to-end Apr 17 PM
- TKT-053 (Acme Innovations): Spooler 3.7s → Worker 22.8s → Gemini Vision 95% → AMOUNT_MISMATCH flag correctly triggered → notification email delivered → row status = completed
- SKIP LOCKED concurrency guarantee proven at SQL level (Round 4-5 analysis)
- Rollback to v12.4 achievable in <30 sec via toggle

---

## 2. The hard constraint that changes everything

### n8n Cloud trial execution budget
- **Cap**: 1,000 executions per billing month
- **Used so far (Apr 1-17)**: 98
- **Remaining**: 902
- **Days to survive in current billing period**: 13 (Apr 17 → Apr 30)
- **Daily safe budget**: 902 ÷ 13 ≈ **69 executions/day**

### Myanmar stress test reality (per Rita's team briefing)
- Myanmar on public holiday; testers return **Monday Apr 20**
- Testing is **gradual, week-long, continuous** — NOT a single 30-min demo meeting
- Purpose: stress test, find bugs, give feedback for iteration — **NOT a go-live MVP launch**
- Expected volume: ~20-40 test emails/day spread across 5-10 weekdays
- They WILL deliberately try edge cases: large attachments, burst sends, malformed emails, concurrent arrivals, password-protected files, etc.

### Design horizons
- **Short-term (2-3 weeks)**: Survive Myanmar testing on n8n trial without blowing cap
- **Long-term (3-6 months)**: Carries cleanly to self-hosted n8n on AWS (with Ryan's eventual tenant admin consent for Graph API) without rework

---

## 3. What I've already tried and rejected

### Attempt A: Keep Cron at 30s
- 2,880 idle executions/day
- Blows full cap in ~7 hours
- **Rejected**: DK hit trial cap warnings today, forced to unpublish Worker

### Attempt B: Longer Cron intervals
| Cron | Idle/day | 13-day cost | Fits budget? | Worst-case email latency |
|------|----------|-------------|--------------|--------------------------|
| 5 min | 288 | 3,744 | NO | 5 min |
| 10 min | 144 | 1,872 | NO | 10 min |
| 20 min | 72 | 936 | Barely (over) | 20 min |
| 30 min | 48 | 624 | YES but wastes ~600 | 30 min |
| 1 hour | 24 | 312 | YES | 60 min |

Even 30-min Cron wastes 624 executions during the 13 days with no emails arriving. And 30-min latency is brutal for gradual stress testing (testers hit "wait, what happened?" anxiety).

### Attempt C: Burst-test-and-hibernate
- Activate Worker only during testing, deactivate between
- **Rejected**: Myanmar tests gradually and unpredictably through the week; hibernation blocks their work.

### Attempt D: My hybrid event-driven (current proposal)
- Spooler adds a final HTTP Request node that POSTs to Worker's Webhook Trigger URL after successful Supabase insert
- Worker keeps Cron at 1-hour interval as pure fallback for crash recovery / missed webhooks
- Latency: seconds (near-instant) for normal operation
- Idle cost: 24/day from fallback Cron
- **Remaining waste**: 24/day × 13 = 312 executions on Cron runs that almost always find nothing
- This is better than B or C but still not zero-waste

---

## 4. The question

**What architecture produces the absolute minimum n8n executions while maintaining:**
1. Near-real-time response when Myanmar tests (<30 sec from email send to ticket appearing)
2. Crash recovery (Worker dies mid-process → row doesn't stay stuck forever)
3. No email loss under concurrent arrival (multiple emails arriving within seconds of each other)
4. Clean rollback to v12.4 if anything fails (<30 sec)
5. Observable via the existing dashboard Pipeline Queue strip
6. No new external services beyond what we already have (n8n Cloud + Supabase Pro + Vercel + Gemini)
7. Carries to AWS self-hosted n8n in 3-6 months without architectural rework

---

## 5. Specific questions — please answer each in order, do not skip or synthesize

### Q1: What's the right primitive for triggering Worker?

Options I see:
- **(a)** Spooler fires webhook to Worker after each insert (my current hybrid proposal)
- **(b)** **Supabase Database Webhook** (built-in, uses pg_net) fires directly to Worker webhook after every INSERT on `email_queue` — bypasses n8n for triggering entirely
- **(c)** **pg_cron** inside Supabase (free on Pro plan, separate from n8n) fires to Worker webhook on schedule — moves the Cron cost OUT of n8n
- **(d)** Supabase Realtime WebSocket subscription from a persistent listener (not practical — n8n isn't a persistent listener)
- **(e)** Combine (b) and (c) — trigger on insert AND periodic sweep for stuck rows
- **(f)** Something unconventional I haven't considered

Which is optimal? Defend with concrete execution-count math over the 13-day horizon assuming ~30 test emails/day average.

### Q2: How do we eliminate the n8n fallback Cron entirely?

The 1-hour fallback Cron in my hybrid exists to catch:
- (i) Webhook delivery failures (Spooler can't reach Worker webhook for some reason)
- (ii) Rows stuck in `processing` status >5 min because Worker crashed mid-execution
- (iii) Edge cases where a row exists in the queue but no trigger fired

Can we replace this Cron entirely?
- **Option X**: Supabase `pg_cron` scheduled SQL function that calls Worker webhook ONLY when `email_queue_stuck` or `pending` count > 0 (conditional trigger — skip the call when queue is idle)
- **Option Y**: Dashboard "Re-process stuck" button (human-in-loop, but DK may not be watching)
- **Option Z**: Worker's last step checks pending count via RPC and self-retriggers its own webhook if more work (chained self-wake)
- **Option AA**: Something else entirely

Critique each. Which has lowest total execution cost for the 13-day horizon?

### Q3: What happens under burst load (10+ emails arriving within 60 sec)?

With webhook-per-insert pattern, each `INSERT` triggers a separate Worker execution. If 10 emails arrive simultaneously, 10 Worker executions spin up.

`FOR UPDATE SKIP LOCKED` guarantees no two Workers grab the same row, but:
- Is **parallel Worker execution** safe given the v12.4 processing chain inside each one? (Gemini API call, XLSX parse, Supabase writes, Outlook notification send)
- Does n8n Cloud trial have **unstated parallel execution limits** we'll hit? (I'm aware trial lacks "Execute only one instance at a time" toggle)
- Will **Gemini quota errors** cascade if 5-10 concurrent Vision calls hit the API?
- **Memory concerns**: n8n Cloud trial container limits under concurrent XLSX/PDF processing?

Round 4 gave us the queue as a solution for **Outlook-Trigger concurrency**. Did we actually solve the **inner processing concurrency** problem or just relocate it?

### Q4: Self-hosted n8n on AWS migration — does this carry over cleanly?

In 3-6 months Trustify migrates to self-hosted n8n on AWS. Self-hosted n8n supports native Queue Mode (uses Redis/BullMQ for job distribution).
- Does our Spooler+Worker+Supabase queue become **redundant** (native Queue Mode replaces it entirely)?
- Or does Supabase queue **remain valuable** as an observability/audit layer even with Queue Mode?
- What's the **cleanest design that works in BOTH** environments (trial now, AWS later) with minimal rework?

### Q5: Error paths, failure modes, rollback

Current rollback story: deactivate Spooler+Worker → activate v12.4 → any unprocessed emails in Outlook re-polled on next 1-min poll → no data loss.
- Does your proposed architecture **preserve this <30-sec rollback**?
- What **new failure modes** does it introduce that v13.0 doesn't have?
- What's the **diagnostic story** when something breaks (dashboard view, logs, Supabase query, n8n execution logs)?
- If Supabase Database Webhook (pg_net) fails to deliver to n8n, how do we **detect** it?

### Q6: Dashboard observability

The live Pipeline Queue strip (Pending/Processing/Completed/Failed polled every 5s) is Minh's "visible no-loss proof" for stakeholders and also gives Myanmar testers immediate feedback.
- Does the new design still produce this visible signal at the same cadence?
- Does Myanmar team have a way to **independently verify no loss** without asking us? (i.e., can they SQL the `email_queue` view themselves?)

### Q7: Out-of-the-box / unconventional solutions

We know conventional answers (Cron, webhook, polling). Is there something unconventional worth exploring?
- **Supabase Edge Functions** as a bridge layer (Deno-based, free tier)?
- **Vercel serverless function** as an orchestration layer that bridges Supabase → n8n?
- **Browser-based trigger** when dashboard is open (wake Worker when someone is actually watching)?
- **Batching strategy** in Spooler (accumulate N emails then fire one Worker that processes all)?
- **n8n Wait node** patterns that might not count as separate executions?
- Any pricing/plan quirks about n8n Cloud trial execution counting we're missing?

Steelman at least one unconventional option.

### Q8: Final verdict

Give your final recommendation as **A / B / C / D / E** where:
- **A**: Supabase Database Webhook (pg_net) → n8n Worker (zero n8n idle polling)
- **B**: Supabase pg_cron → n8n Worker (minimal cost, centralizes scheduling in DB)
- **C**: Hybrid webhook + fallback Cron (DK's current refined proposal)
- **D**: A combined pattern (e.g., Database Webhook for insert + pg_cron for sweep)
- **E**: Your own original design (describe it in detail)

For whichever you pick, provide:
- Confidence rating 1-10
- One sentence on why the runner-up loses
- **Execution count estimate for 13-day horizon** assuming 30 test emails/day average

---

## 6. Required answer format (mandatory)

Please answer each Q1-Q8 **in order**. Do NOT synthesize or skip questions. For each:
- **Direct answer** in 2-3 sentences
- **Evidence** (docs, math, known platform behavior you can cite)
- **What DK's current design gets RIGHT**
- **What DK's current design gets WRONG or MISSES**

End your response with a dedicated section titled **"Final Synthesis"**:
- **Verdict**: A / B / C / D / E
- **Confidence**: 1-10
- **Execution count estimate** for 13-day horizon
- **What 2-3 things did DK fail to consider?** (the catch-the-missed-blindspot question)
- **Sanity check**: is there any reason Myanmar stress testing should NOT start Monday Apr 20? If yes, what must be fixed first?

---

## 7. Reference files (available if relevant)

If you want to ground your answer in code:
- `docs/kan46_final_architecture_decision.md` — Round 4 decision rationale (why Spooler+Worker+Queue won)
- `docs/kan46_round5_graph_api_critique_prompt.md` — Round 5 where Claude's dissent reversed
- `pipelines/n8n-workflow-spooler-v1.json` — current Spooler workflow
- `pipelines/n8n-workflow-worker-v1.json` — current Worker workflow
- `sql/kan46_schema_v1.sql` — queue schema + RPCs + views
- Commit: `e62b3e9` on Apr 17, 2026

---

## 8. Why this round matters

Round 4 solved the Outlook-Trigger concurrency crisis — we got the queue.
Round 5 validated the architecture against my (Claude's) Graph API dissent — 7/7 unanimous.
**Round 6 must solve the cap survival and zero-waste question before Myanmar testing begins Monday.**

This isn't a hypothetical optimization. DK already hit the trial warning today after 7 hours of 30s Cron. He has 902 executions for 13 days of real stress testing. Fast-follow cycles with Myanmar require the system to be **always-on and nearly free**.

Find the answer. Roast anything weak in my design. Catch what I missed.
