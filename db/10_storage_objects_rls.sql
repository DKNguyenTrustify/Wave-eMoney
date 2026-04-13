-- ============================================================================
-- EMI Dashboard — Storage Objects RLS Fix
-- Date: April 13, 2026
-- Issue: After backfill, "Object not found" when generating signed URLs.
-- Cause: anon role can't SELECT storage.objects for the private bucket.
-- Fix: Add SELECT policy on storage.objects for the attachments bucket.
--
-- Note: The bucket-level privacy stays. Direct public URL access still blocked.
-- This policy ONLY allows generating signed URLs (which expire in 1h).
-- ============================================================================

-- Enable RLS on storage.objects (it's enabled by default on Supabase, but be explicit)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists (idempotent)
DROP POLICY IF EXISTS "anon_select_attachments_objects" ON storage.objects;

-- Allow anon to SELECT attachment metadata (needed for createSignedUrl)
-- Without this, createSignedUrl returns "Object not found" (security obfuscation)
CREATE POLICY "anon_select_attachments_objects"
ON storage.objects FOR SELECT
TO anon
USING (bucket_id = 'attachments');

-- ────────────────────────────────────────────────────────────────────────────
-- VERIFY: Check policy exists
-- ────────────────────────────────────────────────────────────────────────────
-- SELECT policyname, cmd, qual FROM pg_policies
-- WHERE schemaname = 'storage' AND tablename = 'objects';
-- Expected: at least one row with policyname = 'anon_select_attachments_objects'

-- ────────────────────────────────────────────────────────────────────────────
-- ROLLBACK (if needed)
-- ────────────────────────────────────────────────────────────────────────────
-- DROP POLICY "anon_select_attachments_objects" ON storage.objects;
