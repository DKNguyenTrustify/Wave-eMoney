-- ═══════════════════════════════════════════════════════════════════
-- KAN-46 v13.1 — Rollback SQL
-- Purpose: Undo the triggers + pg_cron sweeper added by kan46_v13_1_triggers.sql
-- ═══════════════════════════════════════════════════════════════════
--
-- WHEN TO RUN:
--   - v13.1 rollback procedure (see docs/kan46_v13_1_rollback_runbook.md)
--   - Emergency: Database Webhook causing issues, need to fall back to v12.4
--
-- ═══════════════════════════════════════════════════════════════════

-- 1. Disable the Database Webhook trigger (keeps the function in case we want to re-enable)
ALTER TABLE email_queue DISABLE TRIGGER on_email_queue_insert;

-- 2. Unschedule the pg_cron recovery sweeper
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'worker-recovery-sweep') THEN
    PERFORM cron.unschedule('worker-recovery-sweep');
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════
-- VERIFY ROLLBACK
-- ═══════════════════════════════════════════════════════════════════

-- V1: Trigger should be disabled
SELECT tgname, tgenabled AS enabled_flag
FROM pg_trigger
WHERE tgname = 'on_email_queue_insert';
-- Expected: tgenabled='D' (disabled)
-- (if trigger was never created, query returns 0 rows — also fine)

-- V2: pg_cron job should be gone
SELECT jobname FROM cron.job WHERE jobname = 'worker-recovery-sweep';
-- Expected: 0 rows

-- ═══════════════════════════════════════════════════════════════════
-- RE-ENABLE (when ready to retry v13.1)
-- ═══════════════════════════════════════════════════════════════════
-- ALTER TABLE email_queue ENABLE TRIGGER on_email_queue_insert;
-- Then re-run the pg_cron schedule block from kan46_v13_1_triggers.sql

-- ═══════════════════════════════════════════════════════════════════
-- FULL UNDO (nuclear option — removes functions, config table, audit view)
-- ═══════════════════════════════════════════════════════════════════
-- UNCOMMENT ONLY IF YOU WANT TO FULLY REMOVE v13.1:
--
-- DROP TRIGGER IF EXISTS on_email_queue_insert ON email_queue;
-- DROP FUNCTION IF EXISTS notify_worker_on_queue_insert();
-- DROP VIEW IF EXISTS email_processing_audit;
-- DROP TABLE IF EXISTS worker_config;
-- -- (pg_cron job already unscheduled above)
-- -- (pg_net/pg_cron extensions left enabled — safe to keep)
