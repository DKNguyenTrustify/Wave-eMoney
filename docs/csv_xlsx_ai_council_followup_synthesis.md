# AI Council Follow-up Synthesis — Dashboard Alignment + UX

**Date:** Apr 16, 2026
**AIs:** ChatGPT, Gemini, DeepSeek, Qwen, Perplexity, Claude
**Status:** All 6 responses analyzed. Claude's response was the strongest.

---

## Q1: Attachment Preview — 5/5 consensus: HTML table with scroll

All AIs recommend rendering a read-only HTML `<table>` from the parsed 2D array. No iframe, no embedded viewer, no heavy library. Key design features from each:

| Feature | Source AI | Adopt? |
|---|---|---|
| **Sticky header** (`position: sticky; top: 0`) | All 5 | YES — essential for scrolling |
| **Pagination / "Load more"** for 50+ rows | ChatGPT, Qwen, Perplexity | YES — show first 20 rows, "View all" button |
| **Column highlighting** (mapped cols get color backgrounds) | ChatGPT | YES — huge for operator trust |
| **Raw View toggle** (tab between Grid View and raw text) | ChatGPT, DeepSeek | YES — mimics "view original" for image/PDF |
| **Row numbers** (#1, #2, ...) | DeepSeek, Qwen | YES — matches spreadsheet mental model |
| **Monospace font for data cells** | Gemini, Qwen | YES — signals raw data, not rendered content |
| **Right-align numeric columns** | Qwen | YES — financial UI convention |
| **Zebra striping** (alternating row colors) | All 5 | YES — basic readability |
| **"Download Original" button** | ChatGPT, DeepSeek | YES — fallback for manual inspection |
| **Mobile horizontal scroll** | Qwen, Perplexity | YES — `overflow-x: auto` on table wrapper |

### My pick: DeepSeek's design + ChatGPT's column highlighting + Qwen's pagination code

DeepSeek has the cleanest HTML structure (Grid View + Raw Text tabs), ChatGPT's column highlighting is the trust differentiator, and Qwen's rendering JS is the most production-ready.

---

## Q2: Badge and Label alignment — consensus with minor variation

### (a) Confidence badge

| AI | Recommendation |
|---|---|
| ChatGPT | "Parsed 96%" (dynamic score) |
| Gemini | "Data Extracted 100%" or "Native File" |
| DeepSeek | "Spreadsheet" (blue badge, no %) |
| Qwen | "Parsed ✓" (no percentage) |
| Perplexity | "Parsed 100%" |

**My pick: "Parsed ✓"** (Qwen's approach). Rationale: deterministic parsing IS 100% — showing a percentage is misleading (there's no probability involved). The checkmark communicates success without false precision. Blue badge color distinguishes from green "Vision" badge.

### (b) Column header in AI Analysis table

| AI | Recommendation |
|---|---|
| ChatGPT | "From Attachment" (remove modality entirely) |
| Gemini | "From Attachment (File Data)" |
| DeepSeek | "From Attachment (Extracted)" |
| Qwen | "From Attachment (Parsed)" |
| Perplexity | "From Attachment (Parsed)" |

**My pick: "From Attachment"** (ChatGPT's generic approach). Already renamed from "Document" to "Attachment" in KAN-42. Adding "(Parsed)" vs "(Vision)" creates branching UI logic. Keep it generic — the badge communicates the extraction method.

Wait — we already changed this to "From Attachment (Vision)" in KAN-42. If we remove "(Vision)" entirely, it becomes just "From Attachment" for ALL ticket types. Cleaner. No branching.

### (c) Attachment Type tile

**All 5 agree: show file extension** (`xlsx`, `csv`). Not "spreadsheet" (too generic). The `document_type` value (payroll_form) is separate metadata.

### (d) Other label fixes

| Fix | Source | Adopt? |
|---|---|---|
| Change "Email vs Bank Slip" in Amount Check to "Email vs Attachment" | ChatGPT | YES — "Slip" implies image |
| Remove "(Vision)" from column header globally | ChatGPT | YES — already discussed above |
| Show "[Wallet Only]" badge when employee name is empty | Gemini, DeepSeek | YES — prevents operator panic at blank cells |
| Add tooltip to confidence badge explaining extraction method | Perplexity | MAYBE post-demo |

---

## Q3: Synthetic test files — combined list (deduplicated)

All AIs proposed 7-8 files each. Deduplicated to the most valuable 8:

| # | Filename | Format | Rows | Edge Case | Stress Pattern |
|---|---|---|---|---|---|
| 1 | `test_burmese_unicode_headers.csv` | CSV | 10 | Myanmar script headers | Zero-width spaces, mixed Myanmar/English names |
| 2 | `test_merged_cells_header.xlsx` | XLSX | 15 | Merged header spanning cols | Column index misalignment |
| 3 | `test_no_names_wallet_only.xlsx` | XLSX | 50 | No name column (wallet IDs only) | 14-16 digit wallet IDs, name=null |
| 4 | `test_large_150_rows.csv` | CSV | 150 | Performance + pagination | Verify preview truncation + full parse |
| 5 | `test_semicolon_windows1252.csv` | CSV | 20 | Delimiter + encoding detection | Semicolon delimiter, CP1252 encoding |
| 6 | `test_metadata_and_totals.csv` | CSV | 80 | Metadata header + TOTAL footer | Skip metadata + skip TOTAL row |
| 7 | `test_mixed_number_formats.csv` | CSV | 20 | "1,000,000" vs "1000000" vs "1.000.000" | Number normalization |
| 8 | `test_multi_sheet.xlsx` | XLSX | 50 | Data on Sheet2, Sheet1 = cover | Sheet selection logic |

---

## Q4: Remaining blind spots — prioritized (5 AIs combined)

### CRITICAL

1. **Mixed attachments (PDF + CSV in same email)** — flagged by ALL 5 AIs
   - Need: precedence rule (XLSX/CSV > PDF > Image)
   - Need: show both attachments, let operator toggle primary source
   - Need: flag discrepancy if totals don't match between sources

2. **Operator correction workflow** — flagged by ALL 5 AIs
   - Need: "Edit Mapping" / "Adjust Columns" button
   - Operator can reassign column mappings via dropdown
   - Re-renders employee list client-side without re-calling Gemini
   - Persist correct mapping for future tickets from same client

### HIGH

3. **Parse failure messaging** — flagged by 4/5 AIs
   - Need: red banner "Unable to parse file" with specific reason
   - Show raw text preview for debugging
   - Offer "Manual Upload" fallback

4. **"Slip" → "Attachment" label in Amount Check** — flagged by ChatGPT
   - Currently "Email vs Bank Slip" — misleading for CSV/XLSX
   - Change to "Email vs Attachment"

### MEDIUM

5. **Template drift / cache decay** — Qwen unique insight
   - Cached mappings can go stale if client changes template
   - TTL on cache (90 days) + force re-prompt if headers deviate >20%

6. **Mobile/tablet table rendering** — flagged by 3/5 AIs
   - `overflow-x: auto` + smaller font on mobile
   - Sticky headers still work

### LOW

7. **Audit trail for mappings** — DeepSeek, Qwen
   - Log mapping decisions + whether manual override was used
   - Useful for compliance, not blocking for demo

8. **Accessibility (ARIA, keyboard nav)** — Qwen, Perplexity
   - Post-demo polish

---

---

## Claude's unique contributions (strongest response of all 6)

### Preview philosophy shift
Other AIs said "show a table." Claude said "show the PARSER'S INTERPRETATION overlaid on the original data." Color-code rows by role:
- Yellow = metadata rows (skipped)
- Green = header row (detected)
- White = data rows (parsed)
- Strikethrough gray = total/summary rows (excluded)
- Red = invalid rows (flagged)

This lets operators audit the PARSER, not just the DATA. If the parser picked row 17 as header when it should be row 18, the operator catches it visually.

### Cross-highlight (killer feature)
Hovering a row in the preview highlights the corresponding employee row in the Employee List (Section 6), and vice-versa. This is the bridge between "what the file contains" and "what the system extracted." No other AI proposed this.

### Don't paginate for banking
"Operators expect to scroll a spreadsheet like a spreadsheet." Sticky header + sticky row numbers + max-height scroll. Only virtualize above 1000 rows. Contradicts other AIs who suggested pagination — Claude is right for the banking context.

### Badge: "Parsed · 98%" (not 100%)
Parsing rows is deterministic but column MAPPING has uncertainty. Showing 100% trains operators to stop checking. Show Gemini's actual mapping confidence. Thresholds: ≥90% green, 70-89% yellow, <70% red.

### Column header should be dynamic, not generic
`From Attachment (Vision)` vs `From Attachment (Parsed)` — the qualifier communicates HOW data was extracted, which affects trust calibration. One-line change: `${ATTACHMENT_TYPE_LABEL[ticket.attachment_kind]}`.

### P0 gaps the other AIs understated

1. **Re-parse must invalidate Finance approval** — if operator corrects mapping, previous approval auto-clears. Otherwise: approved wrong data gets disbursed.

2. **Operator-guided header selection as fallback** — "Could not locate header row. Click on the row that contains column labels." This is recovery, not just an error message.

3. **Template drift detection** — when known sender changes template, show side-by-side "Previous mapping vs New mapping" diff before first disbursement.

4. **Sender feedback should be diagnostic** — not "unable to process" but "row 18 contains `1.35E+12` which appears to be a phone number saved as a number. Please re-save the column as text."

### Security surface (unique to Claude)
- XXE safe because regex parser (no DOM/SAX)
- ZIP bomb: cap decompressed size at 50MB
- External links in XLSX: log presence, don't follow
- VBA macros: log but don't execute
- Formulas with `WEBSERVICE()`: safe (reading cached `<v>` only)

### Final observation (strategic)
> "The Rita demo will go fine on happy-path XLSX parsing. The Myanmar ops team demo will find every ugly edge case within twenty minutes. Invest the time between demos in the P0s, not in preview polish."

---

## My overall assessment (updated with all 6 AIs)

The 6 AIs gave remarkably consistent answers on architecture but diverged on UX depth. The biggest insight I didn't have before:

1. **"Slip" → "Attachment" rename in Amount Check** — I missed this label inconsistency despite doing KAN-42
2. **Column highlighting in preview** — ChatGPT's idea of coloring mapped columns is the single best UX feature for operator trust
3. **Mixed attachments are CRITICAL** — I was treating this as "later" but all 5 AIs flagged it as the highest-priority UX gap
4. **Operator correction workflow is non-negotiable** — every AI said "what if the mapping is wrong?" and they're right. Without an override, one bad mapping = wrong disbursement.

## What changes for our implementation plan (updated with Claude)

### Demo scope (today/tomorrow) — achievable
- Spreadsheet preview as HTML table with:
  - Row-type color coding (metadata/header/data/total per Claude)
  - Column highlighting for mapped cols (per ChatGPT)
  - Sticky header + sticky row numbers (per Claude)
  - Cross-highlight between preview and employee list (per Claude — killer feature)
  - No pagination, just scroll (per Claude — banking context)
- "Parsed · N%" badge with Gemini mapping confidence (per Claude, not flat 100%)
- Dynamic column header: "From Attachment (Vision)" vs "From Attachment (Parsed)" (per Claude)
- "Email vs Attachment" in Amount Check (replace "Slip")
- "[Wallet Only]" placeholder for empty name columns

### Between demos (P0s — invest here per Claude's advice)
- Operator column mapping override UI (dropdown form + Re-parse button)
- Parse failure recovery paths (operator-guided header selection, Edit Mapping fallback)
- Re-parse invalidates previous Finance approval

### Post go-live (P1s)
- Mixed attachment handling (precedence rule + toggle)
- Template drift detection (side-by-side diff for known senders)
- Diagnostic sender feedback per failure class
- Template mapping cache with TTL

### Production hardening (P2s)
- Full audit log per spreadsheet ticket
- XLSX security surface checks (ZIP bomb cap, external links log)
- Sampling convention documentation for operators
- Mode-switching filter (batch spreadsheet vs image tickets)
