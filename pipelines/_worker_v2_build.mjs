// Build EMI Worker v2 workflow from Worker v1 template
// Purpose: v13.1 zero-waste — Webhook trigger + Gemini retry + self-chain
// Run: node _worker_v2_build.mjs
//
// CHANGES vs v1:
//   1. Cron "every 30s" trigger → REMOVED
//   2. Webhook Trigger ADDED (path: emi-worker-v2)
//   3. "Chain Next Job" Code node ADDED after both Mark Complete branches
//      → self-fires webhook if more pending rows exist (uses Supabase worker_config)
//   4. Gemini 3 Extract node → retryOnFail enabled (3 tries, 2s delay)
//   5. Sticky note updated for v13.1 architecture
//   6. Workflow name updated

import { readFileSync, writeFileSync } from 'fs';

const SRC = 'g:/My Drive/Tech Jobs/Trustify/03_build/wave-emi-dashboard/pipelines/n8n-workflow-worker-v1.json';
const DST = 'g:/My Drive/Tech Jobs/Trustify/03_build/wave-emi-dashboard/pipelines/n8n-workflow-worker-v2.json';

const SUPABASE_URL = 'https://dicluyfkfqlqjwqikznl.supabase.co';

const worker = JSON.parse(readFileSync(SRC, 'utf8'));

// =====================================================================
// 1. Remove Cron trigger + old sticky note
// =====================================================================
worker.nodes = worker.nodes.filter(n =>
  n.id !== 'cron-trigger' &&
  n.id !== 'sticky-note-worker'
);

// =====================================================================
// 2. Add new Webhook Trigger (replaces Cron)
// =====================================================================
const webhookTrigger = {
  parameters: {
    httpMethod: 'POST',
    path: 'emi-worker-v2',
    responseMode: 'lastNode',
    options: {}
  },
  id: 'webhook-trigger-worker',
  name: 'Webhook: Worker Dispatch',
  type: 'n8n-nodes-base.webhook',
  typeVersion: 2,
  position: [400, 400],
  webhookId: 'emi-worker-v2'
};

// =====================================================================
// 3. Add new sticky note for v13.1 architecture
// =====================================================================
const stickyV13_1 = {
  parameters: {
    content: `## EMI Worker v2 — KAN-46 v13.1 Zero-Waste

**Purpose:** Process one email job from Supabase email_queue when triggered by webhook.
**Trigger:** Webhook \`/emi-worker-v2\` — fired by Supabase Database Trigger (on INSERT) OR pg_cron recovery sweeper.
**No Cron here** — all scheduling lives in Supabase (free, doesn't burn n8n trial cap).

### Flow
1. Webhook fires (from DB trigger with single-flight gate OR recovery sweep)
2. Claim & Reconstitute → atomic claim via claim_next_email_job RPC
3. If no row claimed: exit silently (race with another Worker — harmless)
4. If row claimed: run v12.4 processing chain (Prepare → Gemini → Parse → Notify)
5. Mark Complete (notify path OR rejection path)
6. Chain Next Job → if more pending exists, fire self-webhook for next cycle

### Concurrency protection
- **Database trigger single-flight gate**: only fires webhook if no row in 'processing'
  → Burst of 25 emails = 1 webhook fire, not 25
- **FOR UPDATE SKIP LOCKED** in claim RPC: no two Workers claim same row
- **5-min TTL on locked_at**: crashed Worker auto-releases its lock

### Gemini retry
- Retry on Fail: 3 tries, 2s base delay, exponential backoff
- Protects against Gemini 429 rate limits on consumer tier

### Execution count (target: <30/day)
- 1 exec per claimed email (plus self-chain if queue drains serially)
- pg_cron recovery sweep: ~0-1/day (conditional)
- NO idle polling cost

### Rollback (<30 sec)
1. Supabase SQL: \`ALTER TABLE email_queue DISABLE TRIGGER on_email_queue_insert; SELECT cron.unschedule('worker-recovery-sweep');\`
2. n8n UI: deactivate this workflow + Spooler
3. n8n UI: activate v12.4`,
    height: 540,
    width: 520
  },
  id: 'sticky-note-worker-v13-1',
  name: 'Worker v2 Architecture (v13.1)',
  type: 'n8n-nodes-base.stickyNote',
  typeVersion: 1,
  position: [-180, 180]
};

// =====================================================================
// 4. Enable Retry on Fail for Gemini 3 Extract node
// =====================================================================
// Note: Gemini 3 Extract is a Code node that uses helpers.httpRequest to call Gemini.
// n8n's retryOnFail attribute on a Code node retries the entire node if it throws.
// This catches cases where Gemini returns 429 and helpers.httpRequest throws.
const gemini = worker.nodes.find(n => n.id === 'gemini3-extract');
if (gemini) {
  gemini.retryOnFail = true;
  gemini.maxTries = 3;
  gemini.waitBetweenTries = 2000;
  console.log('  ✓ Gemini node: retryOnFail=true, maxTries=3, wait=2000ms');
} else {
  console.warn('  ⚠ Gemini node not found by id "gemini3-extract"');
}

// =====================================================================
// 5. Add "Chain Next Job" Code node — self-webhook if more pending
// =====================================================================
const chainNextCode = `// ═══════════════════════════════════════════════════════════════
// Chain Next Job — v13.1 self-webhook pattern
// ═══════════════════════════════════════════════════════════════
// After marking current row complete, check if more pending rows exist.
// If yes: fire webhook to self (Worker v2's own webhook URL).
// This drains the queue serially (one Worker exec per email) while the
// Database trigger's single-flight gate prevents parallel fan-out.
//
// Why this vs n8n Loop node: cyclic connections in n8n are fragile;
// self-webhook is simpler + naturally resumable after crashes.

const SUPABASE_URL = '${SUPABASE_URL}';
const SUPABASE_SERVICE_KEY = 'REPLACE_WITH_SUPABASE_SERVICE_ROLE_KEY';

// Fetch pending count + worker config from Supabase
let pendingCount = 0;
let cfg = null;

try {
  const countResp = await helpers.httpRequest({
    method: 'GET',
    url: \`\${SUPABASE_URL}/rest/v1/email_queue?status=eq.pending&select=id&limit=1\`,
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': 'Bearer ' + SUPABASE_SERVICE_KEY,
      'Prefer': 'count=exact'
    },
    returnFullResponse: true,
    json: true
  });
  // Supabase returns Content-Range: 0-0/N (where N is total count)
  const range = countResp.headers?.['content-range'] || '';
  const match = range.match(/\\/(\\d+|\\*)/);
  pendingCount = match && match[1] !== '*' ? parseInt(match[1], 10) : (Array.isArray(countResp.body) ? countResp.body.length : 0);
} catch (e) {
  console.log('[Worker] chain: pending count query failed:', e.message || String(e));
  // If we can't check, don't chain — recovery sweeper will catch it
  return { json: { _chain: 'skipped_count_error' } };
}

if (pendingCount === 0) {
  return { json: { _chain: 'done', pending: 0 } };
}

// Fetch worker config (URL + secret)
try {
  const cfgRows = await helpers.httpRequest({
    method: 'GET',
    url: \`\${SUPABASE_URL}/rest/v1/worker_config?id=eq.1&select=worker_url,webhook_secret\`,
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': 'Bearer ' + SUPABASE_SERVICE_KEY
    },
    json: true
  });
  cfg = Array.isArray(cfgRows) ? cfgRows[0] : null;
} catch (e) {
  console.log('[Worker] chain: config fetch failed:', e.message || String(e));
  return { json: { _chain: 'skipped_config_error' } };
}

if (!cfg || !cfg.worker_url || cfg.worker_url.includes('REPLACE_WITH')) {
  return { json: { _chain: 'skipped_no_config' } };
}

// Fire self-webhook (fire-and-forget; don't wait for response)
try {
  await helpers.httpRequest({
    method: 'POST',
    url: cfg.worker_url,
    headers: {
      'Content-Type': 'application/json',
      'X-Webhook-Secret': cfg.webhook_secret
    },
    body: { trigger: 'self_chain', fired_at: new Date().toISOString() },
    json: true,
    timeout: 5000  // don't wait long; we only care that the POST was sent
  });
} catch (e) {
  // Fire-and-forget — webhook receipt isn't our concern; n8n responds 200 immediately
  // If this truly failed, recovery sweeper will catch it within 5 min
  console.log('[Worker] chain: self-webhook (non-fatal):', e.message || String(e));
}

return { json: { _chain: 'fired', pending: pendingCount } };
`;

const chainNextJob = {
  parameters: {
    jsCode: chainNextCode,
    mode: 'runOnceForEachItem'
  },
  id: 'chain-next-job',
  name: 'Chain Next Job',
  type: 'n8n-nodes-base.code',
  typeVersion: 2,
  position: [2560, 400]
};

// Add the new nodes
worker.nodes.push(webhookTrigger, stickyV13_1, chainNextJob);

// =====================================================================
// 6. REWIRE CONNECTIONS
// =====================================================================
worker.connections = {
  'Webhook: Worker Dispatch': {
    main: [[{ node: 'Claim & Reconstitute', type: 'main', index: 0 }]]
  },
  'Claim & Reconstitute': {
    main: [[{ node: 'Prepare for AI v3', type: 'main', index: 0 }]]
  },
  'Prepare for AI v3': {
    main: [[{ node: 'Skip Filter (v11.1)', type: 'main', index: 0 }]]
  },
  'Skip Filter (v11.1)': {
    main: [
      [{ node: 'Is Rejection Email?', type: 'main', index: 0 }],
      [{ node: 'Gemini 3 Extract (Consolidated)', type: 'main', index: 0 }]
    ]
  },
  'Gemini 3 Extract (Consolidated)': {
    main: [[{ node: 'AI Parse & Validate v3', type: 'main', index: 0 }]]
  },
  'AI Parse & Validate v3': {
    main: [[{ node: 'Send Outlook Notification', type: 'main', index: 0 }]]
  },
  'Send Outlook Notification': {
    main: [[{ node: 'Mark Complete (Notify path)', type: 'main', index: 0 }]]
  },
  'Is Rejection Email?': {
    main: [
      [{ node: 'Send Rejection Email', type: 'main', index: 0 }],
      []
    ]
  },
  'Send Rejection Email': {
    main: [[{ node: 'Mark Complete (Rejection path)', type: 'main', index: 0 }]]
  },
  'Mark Complete (Notify path)': {
    main: [[{ node: 'Chain Next Job', type: 'main', index: 0 }]]
  },
  'Mark Complete (Rejection path)': {
    main: [[{ node: 'Chain Next Job', type: 'main', index: 0 }]]
  }
  // Chain Next Job has no downstream connections — it terminates the execution.
};

// =====================================================================
// 7. Update workflow metadata
// =====================================================================
worker.name = 'EMI Worker v2 (KAN-46 v13.1) — Webhook + Self-Chain + Gemini Retry';

// Write out
writeFileSync(DST, JSON.stringify(worker, null, 2));
console.log('✓ Worker v2 written to:', DST);
console.log('  Nodes:', worker.nodes.length);
console.log('  Connections:', Object.keys(worker.connections).length);
console.log('');
console.log('Next steps:');
console.log('  1. Run kan46_v13_1_triggers.sql in Supabase (with worker_url + secret)');
console.log('  2. Import n8n-workflow-worker-v2.json into n8n Cloud');
console.log('  3. Paste secrets (service_role × 3, Gemini, webhook_secret)');
console.log('  4. Attach Outlook credentials on 2 send nodes');
console.log('  5. Get the webhook URL from Webhook: Worker Dispatch node');
console.log('  6. Update worker_config table in Supabase with that URL + secret');
console.log('  7. Deactivate v12.4 + Spooler, activate Spooler + Worker v2');
console.log('  8. Send test email, watch dashboard drain');
