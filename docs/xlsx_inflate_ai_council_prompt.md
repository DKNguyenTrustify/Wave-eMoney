# AI Council Prompt — Pure JS XLSX Parsing Without zlib

Paste to the SAME AI conversations (they have context from rounds 1+2).

---

URGENT FOLLOW-UP: We hit a critical blocker implementing CSV/XLSX support.

THE PROBLEM:

Our n8n Cloud Task Runner sandbox BLOCKS require('zlib'). We get: "Module 'zlib' is disallowed [line 399]"

We also tried sending XLSX to Gemini via inlineData — Gemini returns HTTP 400. It only supports images and PDF as document input, NOT XLSX.

So BOTH our approaches failed:
1. Manual XLSX XML parsing (needs zlib.inflateRawSync for DEFLATE-compressed ZIP entries) — BLOCKED
2. Gemini vision inlineData with XLSX MIME type — HTTP 400, unsupported format

WHAT WE NEED:

A way to parse XLSX files in a sandboxed JavaScript environment where:
- require('zlib') is BLOCKED (module disallowed)
- require() of ANY npm package is BLOCKED
- Only built-in Buffer, String, Array, Math, JSON, RegExp, and standard JS globals are available
- We CAN use: Buffer.from(), Buffer.alloc(), DataView, ArrayBuffer, Uint8Array, TextDecoder
- We CANNOT use: require(), import, eval, Function constructor, fetch, XMLHttpRequest
- We CAN use: await helpers.httpRequest() (n8n's built-in HTTP helper for external API calls)

THE XLSX FILE:

XLSX is a ZIP archive containing XML files. The key files we need:
- xl/sharedStrings.xml (string lookup table)
- xl/worksheets/sheet1.xml (cell data with row/column references)

ZIP entries use compression method 8 (DEFLATE). We need to decompress them to read the XML.

Our test file is 13KB with 3 employee rows + metadata. Typical production files: 10-50KB, 3-50 employees.

WHAT WE'VE ALREADY BUILT:

We have working code for:
- ZIP local file header parsing (reading filenames, sizes, compression method from the binary)
- Shared string XML parsing (regex-based, no DOM parser)
- Sheet XML to 2D array conversion
- CSV text parsing (works perfectly — no zlib needed)

The ONLY missing piece is: decompressing DEFLATE (method 8) compressed data from the ZIP entries.

QUESTIONS — answer ALL:

Q1: PURE JS DEFLATE DECOMPRESSION
Provide a complete, self-contained JavaScript function that decompresses raw DEFLATE data (RFC 1951) using ONLY standard JavaScript (no require, no npm, no eval). The function signature should be:

    function inflateRaw(compressedBytes) => decompressedBytes

Where compressedBytes is a Uint8Array or Buffer of DEFLATE-compressed data, and the return is the decompressed Uint8Array or Buffer.

Requirements:
- Must work in Node.js v22 sandboxed environment
- Must handle: fixed Huffman codes, dynamic Huffman codes, stored blocks
- File sizes: compressed entries typically 500 bytes - 10KB
- MUST be self-contained (no external dependencies)
- Performance: <100ms for a 10KB decompression is fine
- Provide the COMPLETE code, not pseudocode or references to libraries

Q2: ALTERNATIVE APPROACHES
If a pure JS inflate is too complex or risky, what OTHER approaches could work within our constraints? Consider:
- Using n8n's helpers.httpRequest() to call an external decompression API/service
- Sending the raw XLSX base64 to a serverless function that returns parsed CSV
- Using Google Sheets API to convert XLSX to CSV (we have Google credentials)
- Any other creative approach that avoids the zlib constraint

For each alternative, rate: complexity, reliability, latency, and whether it adds external dependencies.

Q3: MINIMAL INFLATE
If a full RFC 1951 implementation is too long, is there a MINIMAL inflate that handles only the compression patterns typically found in XLSX files (which use zlib default compression level 6)? XLSX XML content is highly regular (repetitive XML tags), so the Huffman trees might be predictable. Could we exploit this for a shorter implementation?

REPLY FORMAT:
1. Complete inflateRaw() function code (Q1) — paste-ready, tested
2. Alternative approaches ranked (Q2) — with recommendation
3. Minimal inflate assessment (Q3) — is it feasible and how short
4. Any risks or edge cases we should test
