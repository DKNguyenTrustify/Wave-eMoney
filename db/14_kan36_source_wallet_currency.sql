-- ============================================================================
-- EMI Dashboard — KAN-36 v11.4 Source Wallet + Currency Migration
-- Adds 2 new columns to tickets_v2 for ticket-level Source Info header row.
-- Recreates tickets_flat VIEW to expose them (columns appended at END per
-- PostgreSQL 42P16 constraint — same pattern as migration 13).
-- Date: 2026-04-15
-- Run AFTER 13_kan36_extraction_fields.sql
-- ============================================================================
-- CONTEXT:
-- Survey of 5 real payroll sample attachments (Myanmar + US + EU) showed:
--   1. "From Wallet" is ticket-level data, not per-employee (appears ONCE in
--      attachment header as "Corporate Wallet" or "Funding Source Account")
--   2. Currency varies (MMK for Myanmar, USD for ACME, EUR for Global)
-- Previous v11.3 implementation wrongly put company name as From Wallet
-- placeholder and repeated it per row. v11.4 moves it to modal header and
-- extracts real wallet ID from attachment via Vision.
-- ============================================================================

-- ─── STEP 1: Add ticket-level Source Info fields to tickets_v2 ──────────────
-- These come from Vision extraction on the attachment's header area.
-- Defaults chosen so legacy tickets (pre-v11.4) render cleanly in dashboard:
--   - corporate_wallet: '' (dashboard shows "—" when empty)
--   - currency: 'MMK' (Myanmar is production target; safest default)

-- Note: tickets_v2.currency already exists (from original schema, default 'MMK').
-- We only need to add corporate_wallet. The existing currency column is already
-- exposed by the tickets_flat VIEW since migration 03. No changes needed for it.

ALTER TABLE tickets_v2
  ADD COLUMN IF NOT EXISTS corporate_wallet TEXT DEFAULT '';   -- e.g. "1200000289", "CHASE OPERATING - 123456789"

-- ─── STEP 2: Recreate tickets_flat VIEW — append new columns at end ────────
-- PostgreSQL CREATE OR REPLACE VIEW does not allow inserting new columns
-- in the middle of the column list (error 42P16 — cannot change name of
-- view column). So we keep ALL existing columns in their exact positions
-- and APPEND the 2 new columns at the very end.
-- This matches the convention established in migration 13.

CREATE OR REPLACE VIEW tickets_flat AS
SELECT
  -- Core (from tickets_v2) — ORIGINAL ORDER
  t.id,
  t.ticket_number,
  t.company, t.type::text, t.currency,
  t.scenario::text, t.status::text, t.risk_level::text,
  t.amount_requested, t.amount_on_bank_slip, t.amount_on_document,
  t.has_mismatch, t.approval_matrix_complete,
  t.required_approvals, t.email_approvals,
  t.finance_status, t.finance_approved_by, t.finance_approved_at, t.finance_notes,
  t.prechecks_done, t.prechecks_at,
  t.employee_data, t.employee_total, t.total_employees,
  t.invalid_msisdn_count, t.names_cleaned_count, t.employee_file_name,
  t.reconciliation,
  t.bank_slip_filename, t.bank_slip_type,
  t.remark, t.transaction_id, t.depositor_name,
  t.sent_to_checker, t.checker_name, t.checker_request, t.files_prepared,
  t.mapping_in_progress, t.mapping_complete, t.disbursing,
  t.monitor_results, t.closed,
  t.n8n_source,
  t.created_at, t.updated_at,

  -- Email (latest email per ticket) — ORIGINAL ORDER
  e.source_email_id, e.from_email, e.to_email, e.cc_emails,
  e.reply_to, e.email_date, e.message_id, e.thread_id,
  e.original_subject, e.body_preview, e.email_body_full,
  e.has_attachments, e.attachment_names, e.attachment_count,
  e.n8n_parsed_at,

  -- Attachment — ORIGINAL ORDER
  a.storage_url AS attachment_url,
  a.mime_type AS attachment_mime_type,
  a.file_name AS attachment_file_name,

  -- Vision — ORIGINAL ORDER
  v.vision_parsed, v.vision_confidence, v.vision_status,
  v.document_type, v.document_signers,

  -- Employee extraction — ORIGINAL ORDER
  x.extracted_employees,
  x.employee_count AS extracted_employee_count,
  x.confidence AS employee_extraction_confidence,
  x.status AS employee_extraction_status,
  x.total_amount AS employee_total_extracted,
  x.amount_mismatch AS employee_amount_mismatch,

  -- APPENDED v11 KAN-35 / KAN-36 columns (migration 13) — ORIGINAL ORDER
  t.payment_date, t.payroll_period,
  t.initiator_name, t.purpose, t.cost_center,
  t.doc_company_name, t.doc_payment_date,
  t.doc_initiator_name, t.doc_purpose, t.doc_cost_center,

  -- ─── APPENDED v11.4 Source Info column (NEW in migration 14) ──────────
  -- Ticket-level data extracted from attachment header.
  -- Note: t.currency is already exposed above (original schema); no re-append needed.
  t.corporate_wallet

FROM tickets_v2 t
LEFT JOIN LATERAL (
  SELECT * FROM ticket_emails WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1
) e ON true
LEFT JOIN LATERAL (
  SELECT * FROM ticket_attachments WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1
) a ON true
LEFT JOIN LATERAL (
  SELECT * FROM ticket_vision_results WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1
) v ON true
LEFT JOIN LATERAL (
  SELECT * FROM ticket_employee_extractions WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1
) x ON true;

-- ─── STEP 3: Verification queries (run after migration to confirm) ─────────
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'tickets_v2' AND column_name = 'corporate_wallet';
-- Expected: 1 row.
--
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'tickets_flat' AND column_name = 'corporate_wallet';
-- Expected: 1 row.

-- ─── ROLLBACK (if needed) ──────────────────────────────────────────────────
-- Run in sequence:
-- 1. CREATE OR REPLACE VIEW tickets_flat (paste content from migration 13 output)
-- 2. ALTER TABLE tickets_v2 DROP COLUMN IF EXISTS corporate_wallet;
