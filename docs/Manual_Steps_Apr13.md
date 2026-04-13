# Manual Steps to Activate Hardening (Apr 13)

**Code is shipped + deployed.** These manual steps activate it.

**Order matters.** Do them in this sequence. Each is independent — if one fails, others still work.

---

## Step 1: Apply RLS Policies (Supabase SQL Editor) — 5 min

1. Open Supabase SQL Editor
2. Open new tab, paste contents of `db/08_security_rls_policies.sql`
3. Run
4. Verify with this query:
```sql
SELECT schemaname, tablename, rowsecurity FROM pg_tables
WHERE tablename IN ('tickets_v2','ticket_emails','ticket_attachments',
                    'ticket_vision_results','ticket_employee_extractions','activity_log');
```
Expected: `rowsecurity = true` for all 6 tables.

5. Open the dashboard (`https://project-ii0tm.vercel.app/`)
6. Verify all tickets still load
7. Click into TKT-019, click "Approve" or any action — verify it saves
8. **If anything breaks:** rollback by running:
```sql
ALTER TABLE tickets_v2 DISABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_emails DISABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_attachments DISABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_vision_results DISABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_employee_extractions DISABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log DISABLE ROW LEVEL SECURITY;
```

---

## Step 2: Make Storage Bucket Private (Supabase SQL Editor) — 3 min

1. Run `db/07_security_storage_private.sql`
2. Verify bucket is private:
```sql
SELECT id, name, public FROM storage.buckets WHERE id = 'attachments';
```
Expected: `public = false`

3. Open dashboard, open any ticket with attachment, click attachment expander
4. Should show signed URL link (PDF) or signed image (PNG)
5. **If broken:** rollback by running:
```sql
UPDATE storage.buckets SET public = true WHERE id = 'attachments';
```

**Note:** Existing tickets (TKT-001 to TKT-019) have full URLs in the database, so they still work via the legacy URL path. Only new tickets will use signed URLs.

---

## Step 3: Activate Webhook Authentication — 10 min

### 3a. Generate a secret
```bash
# Any random string works. Example:
openssl rand -hex 32
# Or just make one up: "wave-emi-2026-secret-do-not-share-ABC123"
```

### 3b. Add secret to Vercel Pro
1. Go to Vercel dashboard for `project-ii0tm`
2. Settings → Environment Variables
3. Add: `WEBHOOK_SECRET` = `<your secret>`
4. Apply to: Production
5. Redeploy (or wait for next push)

### 3c. Add same secret to n8n Pipeline v9
1. Import `pipelines/n8n-workflow-v9.json` (don't activate yet)
2. Open the "AI Parse & Validate v3" node (will be renamed to v9 in title but content is similar)
3. Find this line in the code:
```javascript
'X-Webhook-Secret': 'REPLACE_WITH_WEBHOOK_SECRET'
```
4. Replace `REPLACE_WITH_WEBHOOK_SECRET` with the SAME secret you added to Vercel
5. Save the workflow

### 3d. Verify by testing
1. **Don't activate v9 yet.** Leave v8 active.
2. Test that v8 still works (it doesn't send the secret, but webhook accepts when env var is set... wait, this will FAIL).

**Important:** Once `WEBHOOK_SECRET` is set on Vercel, ALL POSTs without the secret will be rejected. So:

**Recommended order:**
1. Set the secret in n8n v9 first
2. Activate v9, deactivate v8 (now v9 sends the secret in all calls)
3. THEN add the env var to Vercel
4. After Vercel redeploys, test with a new email

This way there's no window where v8 is active but webhook rejects its calls.

---

## Step 4: Activate Pipeline v9 — 5 min

1. In n8n Cloud, with v9 imported and secret set:
2. Click "Activate" on v9
3. Click "Deactivate" on v8
4. Send a test email to `emoney@zeyalabs.ai` with attachment
5. Verify:
   - Notification email arrives with clean URL `?ticket=TKT-020`
   - **Notification now says "Attachments: 1 file(s)"** (was "0 file(s)" — that's the v9 fix)
   - Dashboard shows the new ticket
   - Click attachment → loads via signed URL

---

## Test Plan Summary

| What | How | Expected |
|------|-----|----------|
| RLS active | `SELECT rowsecurity FROM pg_tables ...` | true for 6 tables |
| Dashboard reads | Open dashboard | All 19 tickets visible |
| Dashboard writes | Click "Approve" on a ticket | Save succeeds, no console error |
| Storage private | `SELECT public FROM storage.buckets ...` | false |
| Old attachments still work | Open TKT-019, click attachment | Opens (legacy URL still in DB) |
| New attachments use signed URL | Send test email with PDF, open new ticket | Signed URL loads file (1h expiry) |
| Webhook auth active | Send test email | Ticket created (because v9 sends secret) |
| Webhook rejects bad calls | `curl -X POST .../api/webhook -d '{}'` | 401 Unauthorized |
| v9 attachment count fix | Send test email with attachment | Notification says "1 file(s)" |

---

## Rollback Plan (if needed)

1. **RLS broke dashboard:** Run the disable-RLS rollback queries (Step 1)
2. **Storage broke:** Run `UPDATE storage.buckets SET public = true ...`
3. **Webhook broke:** Remove `WEBHOOK_SECRET` env var from Vercel, redeploy
4. **v9 broke:** Reactivate v8, deactivate v9 in n8n Cloud

All rollbacks are < 2 minutes and fully reversible.
