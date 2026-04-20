-- ============================================================================
-- EMI Dashboard — Make Storage Bucket PRIVATE
-- Date: April 13, 2026
-- Purpose: Stop public URL access. Switch to signed URLs (1h expiry).
-- ============================================================================

-- Step 1: Update bucket to private
UPDATE storage.buckets
SET public = false
WHERE id = 'attachments';

-- Step 2: RLS policy — allow service_role unrestricted access (webhook uses this)
-- (Service role bypasses RLS by default, but explicit is good)

-- Step 3: RLS policy — allow anon to download via signed URLs only
-- (This is automatic — signed URLs don't need RLS bypass)

-- Verification (run after to confirm)
-- SELECT id, name, public FROM storage.buckets WHERE id = 'attachments';
-- Expected: public = false
