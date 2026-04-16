# AI Council Follow-up Prompt — CSV/XLSX Dashboard Alignment + UX

Paste this to the SAME AI conversations (they already have context from the first prompt).

---

This is a follow-up to our CSV/XLSX parsing discussion. You already have the context of our 7 samples, the Hybrid C architecture decision, and our n8n + Gemini pipeline. Now I need your help on three remaining areas.

CURRENT DASHBOARD BEHAVIOR (for image/PDF attachments):

When a ticket is created from an email with an image or PDF attachment, the dashboard ticket detail modal shows these sections in order:

1. HEADER BADGES: ticket ID, type (MA/OTC), risk level, "Vision 95%" confidence badge
2. ACTION BUTTONS: Return to Client, Generate CSV for Finance
3. AMOUNT VERIFIED / MISMATCH BANNER: green or yellow banner comparing email amount vs document amount
4. ORIGINAL ATTACHMENT PREVIEW: clickable expand area that shows inline image or PDF iframe — the operator can visually inspect the original bank slip or payroll form
5. SOURCE INFO ROW: From Wallet | Currency | Payroll Period | Attachment Type | Transaction ID
6. EMPLOYEE LIST TABLE: 4 columns (SI No | Employee Name | To Wallet | Amount) with currency-aware formatting
7. AMOUNT CHECK: 3-row validation (Email vs Slip, Employee Total vs Requested, Three-Way Match)
8. AI ANALYSIS — EMAIL VS ATTACHMENT: 7-row comparison table (Company, Initiator, Total Amount, Pay Date, Purpose, Cost Center, Authorizations)
9. EMAIL DETAILS: collapsible section showing the raw email body

THE PROBLEM FOR CSV/XLSX TICKETS:

When a CSV or XLSX file is the attachment (instead of an image/PDF), several sections will look different or may not work:

- Section 1: "Vision 95%" badge — there's no vision AI involved. What badge to show?
- Section 4: Original Attachment Preview — cannot render a spreadsheet as an inline image or iframe. What to show instead?
- Section 6: Employee Name column — some spreadsheets (like Wave Money's MFS form) have NO employee names, only wallet IDs. Name column would be empty.
- Section 8: "From Attachment (Vision)" column header — no vision was used. Misleading label?

QUESTIONS — please answer ALL four:

Q1: ATTACHMENT PREVIEW FOR SPREADSHEETS
When the original attachment is a CSV or XLSX file (not an image or PDF), what should the "Original Attachment" preview section show? Consider:
- The operator needs to visually verify the original data
- It should feel consistent with the image/PDF preview experience
- We're in a vanilla JS single-page app (no React, no framework)
- The spreadsheet data is already parsed and available as a 2D array on the client side

Propose a specific UI design with enough detail to implement (HTML/CSS structure, interaction pattern). Include how to handle large spreadsheets (50+ rows) in the preview.

Q2: DASHBOARD BADGE AND LABEL ALIGNMENT
For CSV/XLSX-sourced tickets, propose how to handle:
(a) The confidence badge — currently shows "Vision 95%". What should it show for parsed spreadsheets? Options: "Parsed 100%", "Spreadsheet", remove badge entirely, or keep "Vision" label?
(b) The "From Attachment (Vision)" column header in the AI Analysis table — should it change to "From Attachment (Parsed)" or stay generic?
(c) The "Attachment Type" tile in Source Info — should it show "xlsx", "csv", "spreadsheet", or the document_type value like "payroll_form"?
(d) Any other labels or indicators that would look wrong or misleading for a spreadsheet-sourced ticket?

Q3: SYNTHETIC TEST SAMPLE GENERATION
Since public Myanmar bank templates are not available for download, we need to generate synthetic test files for edge case testing. We already have 7 samples covering 5 distinct column structures.

Please provide:
(a) A list of 5-8 specific synthetic test files we should create, each targeting a different edge case (e.g., Burmese headers, merged cells, 100+ employees, mixed currency, etc.)
(b) For each file, specify: filename, format (CSV or XLSX), column structure, number of rows, specific edge case it tests, and the expected parsing result
(c) Any particular data patterns that would stress-test the Hybrid C architecture

Q4: REMAINING BLIND SPOTS
Given everything we've discussed (architecture C, file detection, XLSX extraction, dashboard alignment), what are we STILL missing? Consider:
- Operator workflow: how does an operator's daily routine change when spreadsheet tickets arrive alongside image/PDF tickets?
- Error messaging: what happens when a spreadsheet fails to parse? What does the operator see?
- Mixed attachments: what if an email has BOTH a PDF and a CSV attached?
- Undo/correction: what if the hybrid mapping gets a column wrong? Can the operator fix it?
- Accessibility: does the spreadsheet preview work on mobile/tablet?

REPLY FORMAT:
1. Attachment preview design (Q1) — specific HTML/CSS/JS approach
2. Badge and label recommendations (Q2) — pick one option per item with rationale
3. Synthetic test file specifications (Q3) — table format with all details
4. Remaining blind spots (Q4) — prioritized list with severity
