// KAN-46 v13.1 patch: harden Gemini JSON parsing + route diagnostic to Mark Failed
// Modifies worker-v2.json in place (produces worker-v2.json with v13.1.1 fixes)
// Run: node _worker_v2_patch.mjs
//
// CHANGES:
//   Fix A: Upgrade Gemini 3 Extract's JSON parsing to be brace-balanced
//          (handles Gemini 2.5 thinking mode preamble/postamble that breaks greedy regex)
//   Fix B: Add "Is Diagnostic" IF node after AI Parse & Validate v3
//          → routes _diagnostic items to new "Mark Failed (Diagnostic)" node
//          → prevents malformed self-send notifications
//   Fix C: "Mark Failed (Diagnostic)" node calls mark_email_failed RPC

import { readFileSync, writeFileSync } from 'fs';

const SRC = 'g:/My Drive/Tech Jobs/Trustify/03_build/wave-emi-dashboard/pipelines/n8n-workflow-worker-v2.json';
const SUPABASE_URL = 'https://dicluyfkfqlqjwqikznl.supabase.co';

const worker = JSON.parse(readFileSync(SRC, 'utf8'));

// =====================================================================
// FIX A: Harden Gemini JSON parsing
// =====================================================================
// Replace the old parse fallback (which uses greedy regex) with a
// brace-balancing extractor that handles Gemini 2.5 thinking preamble.

const gemini = worker.nodes.find(n => n.id === 'gemini3-extract');
if (!gemini) throw new Error('gemini3-extract node not found');

const oldParseBlock = `try {
      parsed = JSON.parse(content);
      status = attachment ? 'success_with_vision' : 'success_text_only';
      staticData.geminiErrors = 0;
    } catch(e) {
      const cleaned = content.replace(/\`\`\`json\\s*/g, '').replace(/\`\`\`\\s*/g, '').trim();
      const jsonMatch = cleaned.match(/\\{[\\s\\S]*\\}/);
      if (jsonMatch) {
        try { parsed = JSON.parse(jsonMatch[0]); status = attachment ? 'success_with_vision' : 'success_text_only'; staticData.geminiErrors = 0; }
        catch(e2) { status = 'parse_error'; staticData.geminiErrors++; }
      } else {
        status = 'parse_error';
        staticData.geminiErrors++;
      }
    }`;

const newParseBlock = `// v13.1.1 hardened parser — handles Gemini 2.5 thinking mode preamble/postamble
    function extractBalancedJSON(text) {
      if (!text || typeof text !== 'string') return null;
      // 1. Try direct parse on trimmed + fence-stripped text
      const fenceStripped = text.replace(/\`\`\`(?:json)?\\s*/g, '').replace(/\`\`\`\\s*/g, '').trim();
      try { return JSON.parse(fenceStripped); } catch(e) {}
      // 2. Brace-balancing: find the FIRST complete {...} block (largest containing)
      const candidates = [];
      for (let i = 0; i < fenceStripped.length; i++) {
        if (fenceStripped[i] === '{') {
          let depth = 1;
          for (let j = i + 1; j < fenceStripped.length; j++) {
            if (fenceStripped[j] === '{') depth++;
            else if (fenceStripped[j] === '}') {
              depth--;
              if (depth === 0) {
                candidates.push({ start: i, end: j, text: fenceStripped.slice(i, j + 1) });
                break;
              }
            }
          }
        }
      }
      // 3. Try each candidate, preferring the LARGEST parseable one (most likely the real payload)
      candidates.sort((a, b) => b.text.length - a.text.length);
      for (const c of candidates) {
        try {
          const parsed = JSON.parse(c.text);
          if (parsed && typeof parsed === 'object') return parsed;
        } catch(e) {}
      }
      return null;
    }
    const extracted = extractBalancedJSON(content);
    if (extracted) {
      parsed = extracted;
      status = attachment ? 'success_with_vision' : 'success_text_only';
      staticData.geminiErrors = 0;
    } else {
      status = 'parse_error';
      parsed = { _raw_preview: (content || '').slice(0, 500) };
      staticData.geminiErrors++;
    }`;

if (!gemini.parameters.jsCode.includes(oldParseBlock)) {
  console.error('❌ Could not find old parse block in Gemini node. Patch may have been already applied.');
  console.error('Searching for marker...');
  const hasNewMarker = gemini.parameters.jsCode.includes('extractBalancedJSON');
  if (hasNewMarker) {
    console.log('✅ New parser already present — Fix A skipped (idempotent).');
  } else {
    throw new Error('Neither old nor new marker found. Manual inspection required.');
  }
} else {
  gemini.parameters.jsCode = gemini.parameters.jsCode.replace(oldParseBlock, newParseBlock);
  console.log('  ✓ Fix A: Gemini parser hardened (brace-balancing + largest-candidate selection)');
}

// =====================================================================
// FIX B: Add "Is Diagnostic" IF node + "Mark Failed (Diagnostic)" Code node
// =====================================================================

// Check if already added (idempotent)
const alreadyHasDiagnostic = worker.nodes.some(n => n.id === 'is-diagnostic');

if (!alreadyHasDiagnostic) {
  // New IF node: check if _diagnostic === true
  const isDiagnosticNode = {
    parameters: {
      conditions: {
        options: {
          caseSensitive: true,
          leftValue: '',
          typeValidation: 'strict'
        },
        conditions: [
          {
            id: 'diagnostic-check',
            leftValue: '={{ $json._diagnostic }}',
            rightValue: true,
            operator: {
              type: 'boolean',
              operation: 'true',
              singleValue: true
            }
          }
        ],
        combinator: 'and'
      },
      options: {}
    },
    id: 'is-diagnostic',
    name: 'Is Diagnostic?',
    type: 'n8n-nodes-base.if',
    typeVersion: 2,
    position: [1720, 400]
  };

  // New Mark Failed code node
  const markFailedCode = `// Mark row as failed (diagnostic path — Gemini couldn't extract)
// v13.1.1 fix: prevents self-send malformed notifications when extraction fails
const SUPABASE_URL = '${SUPABASE_URL}';
const SUPABASE_SERVICE_KEY = 'REPLACE_WITH_SUPABASE_SERVICE_ROLE_KEY';

const d = $input.item?.json || {};
let messageId = '';
try {
  const claimItem = $('Claim & Reconstitute').first();
  messageId = claimItem?.json?._queue_message_id || claimItem?.json?.id || '';
} catch(e) {}
if (!messageId) {
  messageId = d._queue_message_id || d.message_id || d.id || '';
}

const reason = d._reason || 'gemini_extraction_failed';
const status = d._gemini_status || 'unknown';
const errorMessage = \`[v13.1.1] \${reason} | gemini_status=\${status}\`;

if (!messageId) {
  console.log('[Worker] mark-failed-diagnostic: no message_id, cannot record failure');
  return { json: { _worker_status: 'no_message_id_cannot_mark_failed' } };
}

try {
  await helpers.httpRequest({
    method: 'POST',
    url: \`\${SUPABASE_URL}/rest/v1/rpc/mark_email_failed\`,
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': 'Bearer ' + SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
      'Prefer': 'params=single-object'
    },
    body: { p_message_id: messageId, p_error_message: errorMessage, p_retry: false },
    json: true
  });
  console.log(\`[Worker] Marked \${messageId} as failed: \${errorMessage}\`);
} catch(e) {
  console.log('[Worker] mark-failed-diagnostic RPC failed:', e.message || String(e));
}

return { json: { _worker_status: 'failed_diagnostic', message_id: messageId, reason, status } };
`;

  const markFailedNode = {
    parameters: {
      jsCode: markFailedCode,
      mode: 'runOnceForEachItem'
    },
    id: 'mark-failed-diagnostic',
    name: 'Mark Failed (Diagnostic)',
    type: 'n8n-nodes-base.code',
    typeVersion: 2,
    position: [1940, 280]
  };

  worker.nodes.push(isDiagnosticNode, markFailedNode);

  // Rewire: AI Parse & Validate v3 → Is Diagnostic?
  // Is Diagnostic? [true] → Mark Failed (Diagnostic)
  // Is Diagnostic? [false] → Send Outlook Notification (existing path preserved)

  // Find and update AI Parse & Validate v3 connection
  const parseConnections = worker.connections['AI Parse & Validate v3'];
  if (!parseConnections) throw new Error('AI Parse & Validate v3 connection not found');

  // Rewire to go through Is Diagnostic first
  worker.connections['AI Parse & Validate v3'] = {
    main: [[{ node: 'Is Diagnostic?', type: 'main', index: 0 }]]
  };

  // Is Diagnostic routing
  worker.connections['Is Diagnostic?'] = {
    main: [
      [{ node: 'Mark Failed (Diagnostic)', type: 'main', index: 0 }],  // true branch
      [{ node: 'Send Outlook Notification', type: 'main', index: 0 }]  // false branch (existing path)
    ]
  };

  // Mark Failed (Diagnostic) → Chain Next Job (so queue drain still happens)
  worker.connections['Mark Failed (Diagnostic)'] = {
    main: [[{ node: 'Chain Next Job', type: 'main', index: 0 }]]
  };

  console.log('  ✓ Fix B: Added Is Diagnostic? IF node');
  console.log('  ✓ Fix C: Added Mark Failed (Diagnostic) code node');
  console.log('  ✓ Connections rewired: AI Parse → Is Diagnostic → {Mark Failed | Send Notification}');
} else {
  console.log('  ✓ Fix B/C: already applied (is-diagnostic node exists)');
}

// =====================================================================
// Update workflow metadata
// =====================================================================
worker.name = 'EMI Worker v2 (KAN-46 v13.1.1) — Webhook + Self-Chain + Gemini Retry + Hardened Parse';

// Update sticky note
const sticky = worker.nodes.find(n => n.id === 'sticky-note-worker-v13-1');
if (sticky) {
  sticky.parameters.content = sticky.parameters.content.replace(
    '## EMI Worker v2 — KAN-46 v13.1 Zero-Waste',
    '## EMI Worker v2 — KAN-46 v13.1.1 Zero-Waste + Hardened Parse'
  );
  if (!sticky.parameters.content.includes('v13.1.1 patches')) {
    sticky.parameters.content += `\n\n### v13.1.1 patches (Apr 17 evening)
- **Fix A**: Gemini parser uses brace-balancing + largest-candidate selection (handles 2.5 thinking preamble)
- **Fix B+C**: \`_diagnostic\` items route to Mark Failed (not Send Notification) → prevents self-send on extraction failure`;
  }
}

writeFileSync(SRC, JSON.stringify(worker, null, 2));
console.log('');
console.log('✓ Patched worker-v2.json written');
console.log(`  Nodes: ${worker.nodes.length}`);
console.log(`  Connections: ${Object.keys(worker.connections).length}`);
console.log('');
console.log('Next steps for DK:');
console.log('  1. In n8n UI: open Worker v2 workflow');
console.log('  2. Delete all existing nodes (or delete the workflow)');
console.log('  3. Import this updated JSON file');
console.log('  4. Re-paste secrets in the 5 places (service_role x 4, Gemini API key, webhook_secret)');
console.log('  5. Re-attach Outlook credential on the 2 send nodes');
console.log('  6. Activate the workflow');
console.log('  7. Re-run a burst test to verify Wave no longer self-sends');
