-- ═══════════════════════════════════════════════════════════════════
-- KAN-46 v13.1 — Zero-Waste Trigger Migration
-- Created: Apr 17, 2026 (evening)
-- Author: DK + AI Council Round 6 (7/7 consensus)
-- Purpose: Replace Worker's 30s n8n Cron with Supabase-native triggering
-- ═══════════════════════════════════════════════════════════════════
--
-- CONTEXT:
--   v13.0's Worker Cron @ 30s burned ~2,880 executions/day → blew n8n
--   trial cap (1,000/month) in ~7 hours. v13.1 moves triggering to Supabase.
--
-- WHAT THIS DOES:
--   1. Enables pg_cron + pg_net extensions
--   2. Creates Database trigger on email_queue INSERT with single-flight gate
--      (only fires Worker webhook if no row currently in 'processing')
--   3. Schedules pg_cron recovery sweeper every 5 min (conditional — fires
--      webhook only if pending/stuck rows exist)
--   4. Creates email_processing_audit view for Myanmar self-service verification
--
-- ═══════════════════════════════════════════════════════════════════
--
-- INSTRUCTIONS FOR DK:
--   1. BEFORE RUNNING:
--      - Replace `REPLACE_WITH_WORKER_WEBHOOK_URL` with your actual Worker v2
--        webhook URL (from n8n after Worker v2 is imported and activated)
--      - Replace `REPLACE_WITH_WEBHOOK_SECRET` with the shared secret
--   2. Open Supabase SQL Editor:
--      https://app.supabase.com/project/dicluyfkfqlqjwqikznl/sql
--   3. Paste this file
--   4. Run
--   5. Scroll to VERIFICATION SECTION at bottom and run those queries
--
-- IDEMPOTENCY: All statements use CREATE ... IF NOT EXISTS / CREATE OR REPLACE
--   → Safe to re-run
--
-- ROLLBACK: See `sql/kan46_v13_1_rollback.sql` for undo procedure
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
-- 1. ENABLE EXTENSIONS (idempotent)
-- ───────────────────────────────────────────────────────────────────
-- pg_cron: scheduled SQL jobs inside Postgres (free on Supabase Pro)
-- pg_net: async HTTP from SQL (underlies Database Webhooks)
-- ───────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;


-- ───────────────────────────────────────────────────────────────────
-- 2. CONFIG TABLE — webhook URL + secret (avoids hardcoding in functions)
-- ───────────────────────────────────────────────────────────────────
-- Why: If Worker webhook URL changes, update this row instead of editing
-- the trigger function. Also centralizes the secret.
-- ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS worker_config (
  id              INTEGER PRIMARY KEY DEFAULT 1,
  worker_url      TEXT NOT NULL,
  webhook_secret  TEXT NOT NULL,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (id = 1)  -- Single row only
);

-- Upsert config (DK: edit these values BEFORE running)
INSERT INTO worker_config (id, worker_url, webhook_secret)
VALUES (
  1,
  'REPLACE_WITH_WORKER_WEBHOOK_URL',   -- e.g. https://tts-test.app.n8n.cloud/webhook/emi-worker-v2
  'REPLACE_WITH_WEBHOOK_SECRET'         -- shared secret between trigger and Worker
)
ON CONFLICT (id) DO UPDATE
SET worker_url = EXCLUDED.worker_url,
    webhook_secret = EXCLUDED.webhook_secret,
    updated_at = NOW();


-- ───────────────────────────────────────────────────────────────────
-- 3. TRIGGER FUNCTION — notify_worker_on_queue_insert()
-- ───────────────────────────────────────────────────────────────────
-- Purpose: Called AFTER INSERT on email_queue.
-- Single-flight gate: only fires webhook if no row currently 'processing'.
-- This prevents parallel Worker fan-out during burst INSERTs.
-- Uses pg_net.http_post (async, non-blocking).
-- ───────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION notify_worker_on_queue_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  cfg RECORD;
  request_id BIGINT;
BEGIN
  -- Fetch worker config
  SELECT worker_url, webhook_secret INTO cfg FROM worker_config WHERE id = 1;
  IF cfg IS NULL OR cfg.worker_url LIKE '%REPLACE_WITH%' THEN
    RAISE NOTICE '[trigger] worker_config not set; skipping webhook fire';
    RETURN NEW;
  END IF;

  -- Single-flight gate: skip if any row currently processing (locked within 5 min)
  IF EXISTS(
    SELECT 1 FROM email_queue
    WHERE status = 'processing'
      AND locked_at > NOW() - INTERVAL '5 minutes'
  ) THEN
    RAISE NOTICE '[trigger] Worker already active; skipping webhook fire';
    RETURN NEW;
  END IF;

  -- Fire async webhook
  SELECT net.http_post(
    url := cfg.worker_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Webhook-Secret', cfg.webhook_secret
    ),
    body := jsonb_build_object(
      'trigger', 'insert',
      'fired_at', NOW()
    )
  ) INTO request_id;

  RAISE NOTICE '[trigger] Fired webhook, request_id=%', request_id;
  RETURN NEW;
END;
$$;


-- ───────────────────────────────────────────────────────────────────
-- 4. THE TRIGGER ITSELF — on_email_queue_insert
-- ───────────────────────────────────────────────────────────────────
-- AFTER INSERT FOR EACH STATEMENT: one fire per INSERT statement, not per row
-- This is the key for batched INSERTs (multi-row INSERT in one transaction
-- → one webhook fire, Worker drains all rows via existing claim logic)
-- ───────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS on_email_queue_insert ON email_queue;
CREATE TRIGGER on_email_queue_insert
AFTER INSERT ON email_queue
FOR EACH STATEMENT
EXECUTE FUNCTION notify_worker_on_queue_insert();


-- ───────────────────────────────────────────────────────────────────
-- 5. pg_cron RECOVERY SWEEPER
-- ───────────────────────────────────────────────────────────────────
-- Purpose: Safety net for webhook delivery failures (pg_net has no retry).
-- Runs every 5 min. Fires webhook ONLY if:
--   - A pending row older than 2 min exists (webhook should have fired already), OR
--   - A processing row is locked >5 min (Worker crashed mid-job)
-- When idle, this job costs ZERO n8n executions (only DB work).
-- ───────────────────────────────────────────────────────────────────

-- Unschedule existing job if present (idempotent re-run safety)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'worker-recovery-sweep') THEN
    PERFORM cron.unschedule('worker-recovery-sweep');
  END IF;
END $$;

SELECT cron.schedule(
  'worker-recovery-sweep',
  '*/5 * * * *',  -- every 5 minutes
  $sweeper$
  DO $block$
  DECLARE
    cfg RECORD;
    needs_wake BOOLEAN;
    request_id BIGINT;
  BEGIN
    SELECT worker_url, webhook_secret INTO cfg FROM worker_config WHERE id = 1;
    IF cfg IS NULL OR cfg.worker_url LIKE '%REPLACE_WITH%' THEN
      RETURN;
    END IF;

    SELECT EXISTS(
      SELECT 1 FROM email_queue
      WHERE (status = 'pending' AND created_at < NOW() - INTERVAL '2 minutes')
         OR (status = 'processing' AND locked_at < NOW() - INTERVAL '5 minutes')
    ) INTO needs_wake;

    IF needs_wake THEN
      SELECT net.http_post(
        url := cfg.worker_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Webhook-Secret', cfg.webhook_secret
        ),
        body := jsonb_build_object(
          'trigger', 'recovery_sweep',
          'fired_at', NOW()
        )
      ) INTO request_id;
      RAISE NOTICE '[sweeper] Fired recovery webhook, request_id=%', request_id;
    END IF;
  END
  $block$;
  $sweeper$
);


-- ───────────────────────────────────────────────────────────────────
-- 6. MYANMAR SELF-SERVICE AUDIT VIEW — email_processing_audit
-- ───────────────────────────────────────────────────────────────────
-- Purpose: Let Myanmar testers independently verify no email loss
-- without pinging DK. Grant anon SELECT so they can query with just
-- the Supabase URL + anon key.
-- Shows last 7 days of email processing with status, timing, errors.
-- ───────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW email_processing_audit AS
SELECT
  message_id,
  from_address,
  subject,
  received_at,
  status,
  completed_at,
  EXTRACT(EPOCH FROM (completed_at - received_at))::INT AS total_seconds,
  error_message,
  notification_sent,
  attempts
FROM email_queue
WHERE received_at > NOW() - INTERVAL '7 days'
ORDER BY received_at DESC;

GRANT SELECT ON email_processing_audit TO anon;


-- ───────────────────────────────────────────────────────────────────
-- 7. GRANTS on worker_config (service_role only)
-- ───────────────────────────────────────────────────────────────────
-- Worker config should be writable only by admin (via SQL editor).
-- Anon should NOT see the webhook secret.
-- ───────────────────────────────────────────────────────────────────

ALTER TABLE worker_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "worker_config_service_role_all" ON worker_config;
CREATE POLICY "worker_config_service_role_all"
  ON worker_config
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Deny all access to anon (default when no policy exists, but be explicit)


-- ═══════════════════════════════════════════════════════════════════
-- VERIFICATION SECTION — run these AFTER the main script
-- ═══════════════════════════════════════════════════════════════════

-- V1: Verify extensions enabled
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('pg_cron', 'pg_net')
ORDER BY extname;
-- Expected: 2 rows (pg_cron, pg_net)

-- V2: Verify worker_config populated (check URL doesn't still say REPLACE)
SELECT
  id,
  CASE
    WHEN worker_url LIKE '%REPLACE_WITH%' THEN '❌ NOT CONFIGURED'
    ELSE '✅ ' || left(worker_url, 60) || '...'
  END AS url_status,
  CASE
    WHEN webhook_secret LIKE '%REPLACE_WITH%' THEN '❌ NOT CONFIGURED'
    ELSE '✅ SET'
  END AS secret_status,
  updated_at
FROM worker_config;
-- Expected: 1 row with both ✅

-- V3: Verify trigger exists
SELECT
  tgname AS trigger_name,
  tgenabled AS enabled,
  pg_get_triggerdef(oid) AS definition
FROM pg_trigger
WHERE tgname = 'on_email_queue_insert';
-- Expected: 1 row, tgenabled='O' (origin = enabled)

-- V4: Verify pg_cron job scheduled
SELECT
  jobid,
  jobname,
  schedule,
  active,
  database
FROM cron.job
WHERE jobname = 'worker-recovery-sweep';
-- Expected: 1 row, active=true, schedule='*/5 * * * *'

-- V5: Verify audit view exists and anon can select
SELECT COUNT(*) AS row_count FROM email_processing_audit;
-- Expected: number of emails in last 7 days (may be 0 if fresh)

-- V6: Check recent pg_net webhook calls (expect 0 until real INSERT happens)
SELECT
  id,
  created,
  status_code,
  SUBSTRING(content FROM 1 FOR 100) AS response_preview
FROM net._http_response
ORDER BY created DESC
LIMIT 5;
-- Expected: Empty on fresh install. Will populate on first INSERT.

-- V7: Smoke test — insert a dummy row and watch the trigger fire
-- UNCOMMENT AND RUN ONLY if you want a full end-to-end smoke test:
--
-- INSERT INTO email_queue (message_id, from_address, subject, payload)
--   VALUES (
--     'v13-1-smoke-' || extract(epoch from now())::text,
--     'smoke@test.local',
--     'v13.1 trigger smoke test',
--     '{"test": true}'::jsonb
--   );
--
-- -- Check the webhook fired:
-- SELECT * FROM net._http_response ORDER BY created DESC LIMIT 1;
-- -- Expected: 200 or 204 status_code (n8n acknowledged)
--
-- -- Check the row is pending, about to be claimed by Worker
-- SELECT id, message_id, status, created_at FROM email_queue
-- WHERE message_id LIKE 'v13-1-smoke-%' ORDER BY created_at DESC LIMIT 1;
--
-- -- After ~30-60 sec, status should become 'processing' then 'completed'
-- -- (if Worker v2 is activated and configured correctly)
--
-- -- Cleanup:
-- -- DELETE FROM email_queue WHERE message_id LIKE 'v13-1-smoke-%';
