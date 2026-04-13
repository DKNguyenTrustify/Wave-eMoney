-- ============================================================================
-- EMI Dashboard — Row Level Security Policies
-- Date: April 13, 2026
-- Purpose: Enable RLS on all 5 normalized tables + define explicit policies
--
-- Strategy:
--   - service_role (webhook): full access (RLS bypassed automatically)
--   - anon (dashboard client): SELECT all + UPDATE tickets_v2 + INSERT activity_log
--                              NO direct INSERT/UPDATE on child tables (webhook only)
--                              NO DELETE anywhere
--
-- This matches current app behavior. Tighter rules (require Auth) come post go-live.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- Step 1: Enable RLS on all 5 normalized tables + activity_log
-- ────────────────────────────────────────────────────────────────────────────
ALTER TABLE tickets_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_vision_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_employee_extractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────────────────
-- Step 2: Drop any existing policies (clean slate)
-- ────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "anon_select_tickets_v2" ON tickets_v2;
DROP POLICY IF EXISTS "anon_update_tickets_v2" ON tickets_v2;
DROP POLICY IF EXISTS "anon_select_ticket_emails" ON ticket_emails;
DROP POLICY IF EXISTS "anon_select_ticket_attachments" ON ticket_attachments;
DROP POLICY IF EXISTS "anon_select_ticket_vision_results" ON ticket_vision_results;
DROP POLICY IF EXISTS "anon_select_ticket_employee_extractions" ON ticket_employee_extractions;
DROP POLICY IF EXISTS "anon_select_activity_log" ON activity_log;
DROP POLICY IF EXISTS "anon_insert_activity_log" ON activity_log;

-- ────────────────────────────────────────────────────────────────────────────
-- Step 3: tickets_v2 — anon can read all, update workflow fields
-- ────────────────────────────────────────────────────────────────────────────
CREATE POLICY "anon_select_tickets_v2"
  ON tickets_v2 FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "anon_update_tickets_v2"
  ON tickets_v2 FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- NOTE: anon CANNOT INSERT into tickets_v2 — webhook (service_role) does that.
-- NOTE: anon CANNOT DELETE from tickets_v2 — no policy = no delete.

-- ────────────────────────────────────────────────────────────────────────────
-- Step 4: Child tables — anon can SELECT only (read via VIEW)
-- Webhook (service_role) handles all INSERTs.
-- ────────────────────────────────────────────────────────────────────────────
CREATE POLICY "anon_select_ticket_emails"
  ON ticket_emails FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "anon_select_ticket_attachments"
  ON ticket_attachments FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "anon_select_ticket_vision_results"
  ON ticket_vision_results FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "anon_select_ticket_employee_extractions"
  ON ticket_employee_extractions FOR SELECT
  TO anon
  USING (true);

-- ────────────────────────────────────────────────────────────────────────────
-- Step 5: activity_log — anon can read + insert (dashboard logs user actions)
-- ────────────────────────────────────────────────────────────────────────────
CREATE POLICY "anon_select_activity_log"
  ON activity_log FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "anon_insert_activity_log"
  ON activity_log FOR INSERT
  TO anon
  WITH CHECK (true);

-- ────────────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after to confirm)
-- ────────────────────────────────────────────────────────────────────────────
-- Check RLS is enabled
-- SELECT schemaname, tablename, rowsecurity FROM pg_tables
-- WHERE tablename IN ('tickets_v2','ticket_emails','ticket_attachments',
--                     'ticket_vision_results','ticket_employee_extractions','activity_log');
-- Expected: rowsecurity = true for all

-- Check policies exist
-- SELECT schemaname, tablename, policyname, cmd FROM pg_policies
-- WHERE tablename IN ('tickets_v2','ticket_emails','ticket_attachments',
--                     'ticket_vision_results','ticket_employee_extractions','activity_log')
-- ORDER BY tablename, policyname;
-- Expected: 8 rows
