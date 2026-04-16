# AI Council Synthesis — CSV/XLSX Parsing Architecture

**Date:** Apr 16, 2026
**AIs consulted:** ChatGPT, Gemini, Claude, Grok (via DeepSeek response), Qwen, Perplexity
**Decision:** Unanimous Option C (Hybrid) — deterministic parsing + AI-assisted column mapping

---

## Universal consensus (6/6 agree)

1. **Architecture C (Hybrid)** — parse file deterministically, send ONLY headers + 2-3 rows to Gemini for column mapping, apply mapping programmatically to all rows
2. **XLSX conversion** — parse sharedStrings.xml + sheet1.xml via regex, build 2D array, output as TSV/CSV text
3. **Token cost** — ~600-750 tokens per file (headers only). Caching by header fingerprint = zero tokens for repeat templates
4. **No public Myanmar bank templates** — gated behind corporate banking portals. Use our existing samples + ask Wave Money team for more

## Best unique insights per AI

### ChatGPT — Column scoring system
- Build synonym dictionaries for name/phone/amount fields (English + Burmese)
- Score each column: exact match (1.0), contains match (0.7), data pattern match (0.8)
- Only call Gemini when confidence < threshold
- Growing template registry: cache fingerprints, skip AI on known templates

### Gemini — Zawgyi encoding + MSISDN truncation
- Legacy Zawgyi encoding (pre-Unicode Myanmar) still exists in older client files. Same visual text, different code points. Can confuse Gemini.
- Excel strips leading zeros from phone numbers (09→9). Must detect and re-pad.
- LLMs are non-deterministic — NEVER let them process actual financial data rows. AI maps schema only.

### Claude — Banking safety (most thorough, most critical)
- **Idempotency key** `(sender_email + file_SHA256 + subject)` — duplicate disbursement is "the single most dangerous bug in a banking pipeline"
- **All-or-nothing** — if 48/50 rows parse but 2 fail, reject ENTIRE file. Never partial-disburse.
- **Sum reconciliation as hard gate** — 3-way check: metadata total vs footer total vs row sum. If any two disagree, reject.
- **Dry-run mode** — every run produces "what would happen" report before actual disbursement
- **Scientific notation** — `1358913481324` rendered as `1.35891E+12` if cell format wrong. Detect and reject.
- **Split name columns** — "Title" + "First Name" + "Last Name" in 3 cols. Gemini mapping should allow array of columns.
- **Header rows repeated every 50 rows** in large files. Skip if matches header.
- **Practical advice:** ship deterministic for Wave's own format FIRST, hybrid as "also handles unknown" — don't over-generalize for demo.
- **Few-shot examples in Gemini prompt** — feed known samples as examples for massive accuracy boost.

### Qwen — Privacy + caching
- Cache mappings per `column_signature_hash`. Same client same template = zero AI calls forever.
- Temperature: 0.0 for strict JSON mapping output
- Myanmar digit normalization: `[\u1040-\u1049]` → `0-9`
- Privacy: only 2 anonymized header rows hit the LLM (compliance with Myanmar PDPL)

### DeepSeek — Audit + fallback
- Log file name + AI mapping instructions + final parsed JSON for every transaction (audit trail)
- Manual review queue for low-confidence mappings
- Corporate wallet detection from "From Wallet" column

### Perplexity — Similar to consensus, no unique additions beyond others

## Blind spots we were missing (discovered via council)

1. **Zawgyi vs Unicode encoding** — legacy Myanmar encoding that LOOKS like Unicode but isn't
2. **Leading zero truncation** — Excel stores 09781234567 as 9781234567 (drops leading 0)
3. **Scientific notation** — large wallet IDs rendered as 1.35E+12
4. **Myanmar/Burmese digit characters** — ၁၂၃ are valid digits, need normalization to 123
5. **Idempotency / duplicate disbursement** — same file processed twice = double payment
6. **All-or-nothing validation** — partial parse success should still reject entire file
7. **Split name columns** — Title + FirstName + LastName across multiple columns
8. **Subtotal rows mid-table** — department breaks like "Subtotal — Engineering"
9. **Quoted CSV fields with embedded commas/newlines** — need state machine parser, not split()
10. **Hidden columns in XLSX** — exist in XML but shouldn't be parsed
11. **Formulas with stale cached values** — someone edited but didn't recalculate

## Implementation priority (Claude's pragmatic advice)

### Phase 1: Ship for demo (today/tomorrow)
- Deterministic parsing for Wave Money's own XLSX template (Sample 4)
- Hybrid mapping as "also handles unknown" on CSV samples
- Basic validation (sum check, amount > 0, phone regex)

### Phase 2: Production hardening (post go-live)
- Zawgyi detection + normalization
- Leading zero re-padding on MSISDNs
- Scientific notation detection + rejection
- Header fingerprint caching
- All-or-nothing validation gate
- Sum reconciliation (3-way)

### Phase 3: Enterprise features (Q2)
- Idempotency key for duplicate prevention
- Dry-run mode with approval gate
- Delta monitoring (month-over-month)
- Test fixtures directory (15+ edge case files)
- Multi-sheet XLSX handling
