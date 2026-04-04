# V3 Vision Pipeline — Deployment & Testing Guide

## Progress

- [x] Step 0: Groq Vision API test — PASSED (llama-4-scout model available)
- [x] Step 1: v3 JSON pushed to GitHub
- [x] Step 2: v3 imported into n8n Cloud, Gmail credentials set
- [x] Step 2b: Gmail Trigger upgraded to v1.3, Download Attachments ON (under Parameters > Options)
- [x] Step 3: Test email sent WITH attachment to xaondk@gmail.com
- [x] Step 4: Gmail Trigger output verified — `attachment_0` binary present (727 kB, image/png)
- [x] Deactivated v2 pipeline
- [x] Step 5: Set Groq API key in Vision Process node
- [ ] **Step 5b: Fix Code node mode — re-import v3 JSON** ← YOU ARE HERE
- [ ] Step 6: Test full pipeline execution
- [ ] Step 7: Test without attachment (v2 compatibility)
- [ ] Step 8: Publish to production

---

## Step 5: Set Groq API Key in Vision Process Node — DONE

~~The Vision Process Code node has a placeholder. Replace `REPLACE_WITH_GROQ_API_KEY` with your real key.~~

**COMPLETED** — key is set. But also fixed the `Bearer ` prefix issue.

---

## Step 5b: Fix Code Node Mode — Re-import v3 JSON

**Problem found:** `this.getWorkflowStaticData is not a function` error.
**Root cause:** Code nodes were in "Run Once for All Items" mode, where `this.*` helpers aren't available.
**Fix:** Updated v3 JSON sets "Run Once for Each Item" mode for Prepare for AI v3 and Vision Process.

### How to apply the fix:

**Option A — Re-import (cleanest):**
1. In n8n Cloud, **delete the current v3 workflow**
2. Import the updated `n8n-workflow-v3.json` from GitHub (it's been pushed)
3. Set credentials again: Gmail OAuth2 on Gmail Trigger, Gmail notifications
4. The Groq API key is already embedded in the updated code
5. Gmail Trigger: make sure it's upgraded to v1.3 with Download Attachments ON

**Option B — Manual fix (if you don't want to re-import):**
1. Open **Prepare for AI v3** node
2. Change **Mode** dropdown from "Run Once for All Items" → **"Run Once for Each Item"**
3. Replace ALL the code with the updated version (see `prep_code_v2.js` below)
4. Open **Vision Process** node
5. Change **Mode** dropdown → **"Run Once for Each Item"**
6. Replace ALL the code with the updated version (see `vision_code_v2.js` below)

### Key code changes (for Option B):
- `$input.all()` + for loop → `$input.item` (single item)
- `itemIndex` → `$itemIndex` (n8n built-in variable)
- `results.push({json:...})` + `return results` → `return {json:...}` (single return)
- `continue` → `return []` (skip item)

### Updated code files (for reference):
- Prepare for AI v3: `C:\Users\xaosp\AppData\Local\Temp\v3build\prep_code_v2.js`
- Vision Process: `C:\Users\xaosp\AppData\Local\Temp\v3build\vision_code_v2.js`

---

## Step 6: Test Full Pipeline Execution

1. Make sure the Gmail Trigger still has the test email loaded (re-fetch if needed)
2. Click **Test Workflow** in n8n (runs all nodes in sequence)
3. Check each node output — click on each node to see its results:

### Node: Prepare for AI v3
| Field | Expected |
|-------|----------|
| `vision_eligible` | `true` |
| `attachment_base64` | Object with base64 data (long string) |
| `attachment_count` | `1` |
| `_source` | `email` |
| `from_email` | sender's address |
| `original_subject` | "Salary Disbursement Request - ACME Innovations Ltd" |

### Node: Groq AI Extract
| Field | Expected |
|-------|----------|
| `choices[0].message.content` | JSON string with company, amount, approvers |

This is text extraction (same as v2). Should parse ACME Innovations, 25,000,000, approvers.

### Node: Vision Process
| Field | Expected |
|-------|----------|
| `_vision_status` | `"success"` |
| `_vision_result.doc_type` | `"bank_slip"` or similar |
| `_vision_result.total_amount` | A number (amount from the image) |
| `_vision_result.confidence` | 0.0 to 1.0 (higher is better) |
| `_vision_result.authorized_signers` | Array of signer objects |
| `attachment_base64` | Should NOT be present (cleared after use) |

**If `_vision_status` is `"api_error"`:** Check the Groq API key is correct.
**If `_vision_status` is `"none"`:** The node didn't attempt vision — check `vision_eligible` in Prepare node.

### Node: AI Parse & Validate v3
| Field | Expected |
|-------|----------|
| `vision_parsed` | `true` |
| `vision_confidence` | Same as above |
| `amount` | From email text |
| `amount_on_document` | From bank slip image |
| `scenario` | `NORMAL` if amounts match, `AMOUNT_MISMATCH` if >1% diff |
| `dashboard_url` | Long URL with base64 ticket |

### Node: Route by Source → Send Gmail Notification
- Should send branded notification email to xaondk@gmail.com
- Email contains dashboard URL
- Open the URL — go to Finance page — should show **Vision AI block** (purple border)

---

## Step 7: Test WITHOUT Attachment (v2 Compatibility)

After Step 6 passes, send another email to **xaondk@gmail.com** with NO attachment:

**Subject:**
```
Salary Disbursement - Golden Dragon Ltd
```

**Body:**
```
Please process salary disbursement for Golden Dragon Ltd.
Amount: 15,000,000 MMK (SalaryToMA)

Approved by:
- U Aung Myint, Sales HOD — Approved
- Daw Su Su Lwin, Finance Manager — Approved
```

**Expected results (should behave identically to v2):**
- `vision_eligible: false`
- `_vision_status: "none"`
- `vision_parsed: false`
- No Vision AI block on dashboard Finance page
- Text extraction + authority matrix + notification all work normally

---

## Step 8: Publish to Production

Once Steps 6 and 7 both pass:

1. In n8n Cloud, toggle the v3 workflow **Active**
2. Keep **v2 deactivated** (both trigger on same Gmail — xaondk@gmail.com)
3. v3 handles everything v2 did + vision — no functionality loss

**Rollback:** Deactivate v3, reactivate v2. They are independent workflows.

**Before Monday demo:** If demoing v2, reactivate v2 and deactivate v3.

---

## Vercel Dashboard

Auto-deployed when we pushed to GitHub. No action needed.

**Verify:** Open https://wave-emi-dashboard.vercel.app — should load normally.

Vision display only appears on Finance page when a ticket has `vision_parsed: true`.

---

## Tuesday Demo Script

1. Open dashboard, show empty state (Ctrl+Shift+R to clear)
2. Send test email WITH bank slip attachment to xaondk@gmail.com
3. Wait ~30-60 seconds for pipeline to process
4. Open notification email → click dashboard URL
5. Show Finance page:
   - Ticket details (company, amount, type)
   - **Vision AI block** — document type, confidence %, amount match/mismatch
   - Authority matrix
6. Key talking point: "The AI reads both the email text AND the bank slip image, then cross-validates the amounts automatically"

---

## Gmail Trigger Setup Notes

- **Node version:** Must be v1.3 (upgrade from v1 if needed)
- **Download Attachments:** Found under **Parameters > Options** (not Settings tab)
- **Simplify:** OFF (we need full email headers for metadata extraction)
- **Poll:** Every Minute
- **Credential:** Gmail OAuth2 API (same as v2)

---

## Rate Limit Notes

Rate limits use n8n Workflow Static Data — they only persist in **production** (activated workflow), NOT in manual "Test Workflow" clicks.

For demo: don't worry about hitting limits — 20 vision calls/day and 100 text calls/day is plenty.

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| No `attachment_0` in Gmail Trigger | Download Attachments not ON | Parameters > Options > toggle ON |
| Gmail Trigger missing Download Attachments | Node version too old | Upgrade to v1.3 (click version text at bottom of Settings) |
| Vision returns 401 | API key placeholder not replaced | Set real key in Vision Process node code |
| Vision returns 404 | Model unavailable on Groq | Check Groq console for model availability |
| `_vision_status: "rate_limited"` | Hit 20 vision calls/day | Wait until next day |
| `_vision_status: "circuit_breaker"` | 3 consecutive vision errors | Fix root cause; resets on next success or next day |
| Loop guard skips email | Subject contains "EMI Pipeline:" | Correct behavior — filtering notification emails |
| Dashboard missing vision block | `vision_parsed` is false | Check Vision Process node output |
| `getBinaryDataBuffer` error | n8n Cloud version too old | Need n8n >= v1.114.0 |
| Duplicate emails processing | Both v2 and v3 active | Deactivate one — only one pipeline should be active |
