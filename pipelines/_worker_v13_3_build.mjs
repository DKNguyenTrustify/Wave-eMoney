// Build EMI Worker v13.3 workflow from v2 (v13.2) template
// Purpose: KAN-47 multi-attachment support — up to 5 attachments per email,
//          parallel Gemini extraction, client-fail-first gate order,
//          extended rejection templates.
// Run: node _worker_v13_3_build.mjs
//
// CHANGES vs v2 (v13.2):
//   1. Workflow name + webhook path updated for v13.3 (prevents traffic collision)
//   2. Prepare for AI v3 — emit attachments[] array (up to 5) with per-attachment
//      validation. Filter out smime.p7m signature blobs. Flag too-many-attachments.
//   3. Gemini 3 Extract — Promise.allSettled over attachments[] with 25s per-call
//      race timeout (fits within n8n Code node's HARD 60s cap; see
//      feedback_n8n_code_node_60s_hard_cap.md for the probe that proved this).
//   4. AI Parse & Validate v3 — aggregate Gemini array results; mark partial
//      failures with _extraction_error per attachment (human-in-loop visibility).
//   5. Skip Filter — gate order: client-fail reasons route BEFORE system-fail
//      (password_protected > too_many_attachments > unreadable > combined).
//   6. Send Rejection Email — 3 distinct templates + combined template for
//      multi-reason rejections (Vinh's all-or-nothing spec).
//   7. Webhook payload: accepts both legacy `attachment_base64` (single) and
//      new `attachments: [...]` (array) — forward-compatible with v13.2 data
//      shape until Layer B's webhook.js is fully rolled out.
//
// Hand-off pattern (see feedback_n8n_iac_handoff_pattern.md):
// Output JSON → DK imports ONCE into a new n8n workflow. Credentials auto-link
// by ID on same-instance import. Do NOT edit the workflow in n8n UI after import;
// any future v13.3.x change comes via this build script + re-import.

import { readFileSync, writeFileSync } from 'fs';

const SRC = 'g:/My Drive/Tech Jobs/Trustify/03_build/wave-emi-dashboard/pipelines/n8n-workflow-worker-v2.json';
const DST = 'g:/My Drive/Tech Jobs/Trustify/03_build/wave-emi-dashboard/pipelines/n8n-workflow-worker-v13_3.json';

const worker = JSON.parse(readFileSync(SRC, 'utf8'));

// =====================================================================
// 1. Metadata: name + webhook path + webhookId
// =====================================================================
worker.name = 'EMI Worker v13.3 (KAN-47) — Multi-Attachment + Parallel Gemini + Client-Fail-First Gates';

const webhookNode = worker.nodes.find(n => n.id === 'webhook-trigger-worker');
if (!webhookNode) throw new Error('webhook-trigger-worker node not found in source JSON');
webhookNode.parameters.path = 'emi-worker-v13-3';
webhookNode.webhookId = 'emi-worker-v13-3';

// =====================================================================
// 2. Prepare for AI v3 — multi-attachment (TODO: Layer C Step 3)
// =====================================================================
// Will replace jsCode with v13.3 multi-attachment version in a follow-up commit.
// For now: baseline carries v2's single-attachment logic unchanged.

// =====================================================================
// 3. Gemini 3 Extract — parallel Promise.allSettled (TODO: Layer C Step 4)
// =====================================================================
// Will replace jsCode with Promise.allSettled + per-call 25s race in a
// follow-up commit. Probe (Apr 21) proved n8n Code node has a HARD 60s
// cap shared across items, so parallel is the only design that fits.

// =====================================================================
// 4. AI Parse & Validate v3 — array aggregation (TODO: Layer C Step 5)
// =====================================================================
// Will replace jsCode to consume attachments[] array of Gemini results.

// =====================================================================
// 5. Send Rejection Email — 3+combined templates (TODO: Layer C Step 7)
// =====================================================================
// Will expand the email body to a multiplex switch on _skip_reason.

// =====================================================================
// 6. Connection rewiring (TODO: Layer C Step 6 — gate order)
// =====================================================================
// Skip Filter's two branches will remain the same topology; decision order
// is encoded in Prepare for AI v3's reason-selection, not the topology.

// =====================================================================
// 7. Update sticky note for v13.3 architecture (TODO)
// =====================================================================
// Will update sticky-note content in a follow-up commit once all node
// changes are in place.

// =====================================================================
// Write out
// =====================================================================
writeFileSync(DST, JSON.stringify(worker, null, 2));
console.log('✓ Worker v13.3 written to:', DST);
console.log('  Nodes:', worker.nodes.length);
console.log('  Connections:', Object.keys(worker.connections).length);
console.log('  Webhook path:', webhookNode.parameters.path);
console.log('');
console.log('Layer C progress: Step 1 complete (scaffolding).');
console.log('Remaining: Step 3 (Prepare for AI v3) → Step 4 (Gemini parallel) → ...');
