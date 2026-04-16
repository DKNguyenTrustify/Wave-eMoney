# AI Council Prompt — CSV/XLSX Parsing Architecture

Paste this entire block to each AI (Claude, GPT, Gemini, Grok, DeepSeek).

---

You are a senior data engineer advising on CSV/XLSX file parsing for a Myanmar salary disbursement pipeline.

SYSTEM CONTEXT:

We have an automated email pipeline (n8n Cloud) that processes salary disbursement requests for Wave Money (Myanmar's largest mobile money provider). Currently handles:
- Images (JPG/PNG) via Gemini 3 Flash Vision AI extracts employee data
- PDFs via Gemini 3 Flash reads natively via inlineData
- Email body text via Gemini extracts structured fields

We need to ADD CSV/XLSX attachment handling. The challenge: we've analyzed 7 real/test samples and found HIGH column structure variation.

REAL DATA — 7 samples with different structures:

Sample 1 — Wave Money simple CSV:
    Employee Name,Phone Number,Amount (MMK)
    U Kyaw Soe Aung,09781234501,450000
    Daw Thin Thin Aye,09451234502,380000

Sample 2 — Yoma Bank CSV (with metadata header rows before the data table):
    COMPANY_NAME,PYI THIT THAR TRADING CO. LTD
    PAYROLL_MONTH,04/2026
    BANK_ID,YOMAMM
    TOTAL_RECORD,10
    (blank row)
    SR_NO,EMPLOYEE_NAME,EMPLOYEE_ACCT_ID,AMOUNT,CURRENCY,PAY_TYPE,NARRATION
    1,U Aung Ko Ko,00141112400201,350000,MMK,SALARY,Pyi Thit Thar_Salary_APR26

Sample 3 — KBZ Bank CSV (with NRC national ID numbers):
    Company,Mingalar Cement Industries Ltd
    Account,03012134567801
    Date,2026-04-01
    (blank row)
    No.,Beneficiary Name,Account Number,Amount (MMK),NRC Number,Remark
    1,U Win Myint,30121345678901234,850000,12/TAMANA(N)234567,Salary Apr 2026

Sample 4 — Wave Money XLSX (real production file, "MFS Emoney Transfer Approval Form"):
    Row 1: MFS Emoney Transfer Approval Form
    Row 2: Digital Money Myanmar Ltd. (Wave Money)
    Row 6: Initiator Name: Kyi Shwe Sin Oo | Fund Movement Purpose: GGI
    Row 7: Cost Center: Business Development | Total Amount: 6,000,000
    Row 17 (headers): Sl No. | From Wallet | To Wallet | emoney Amount | Finance Ref No.
    Row 18: 1 | 1358913481324 | 1358913481314 | 2,000,000
    Row 19: 2 | 1358913481334 | 1358913487334 | 2,000,000
    Row 20: 3 | 1358913481322 | 1358913481922 | 2,000,000
    Row 24: Total: 6,000,000

Sample 5 — Simple Wave Money CSV (MSISDN format):
    Name,MSISDN,Amount
    U Kyaw Min,09781234567,100000
    Daw Thin Thin,09451234567,100000

THE PROBLEM:

5 distinct column structures across these samples:
- Name column varies: "Employee Name" vs "EMPLOYEE_NAME" vs "Beneficiary Name" vs "Name" vs NO NAME AT ALL (wallet IDs only in Sample 4)
- Account column varies: "Phone Number" vs "EMPLOYEE_ACCT_ID" vs "Account Number" vs "MSISDN" vs "From Wallet/To Wallet"
- Amount column varies: "Amount (MMK)" vs "AMOUNT" vs "emoney Amount" vs "SALARY"
- Some files have metadata headers (company, date, bank info), some jump straight to data
- Some have extra fields (NRC national ID, currency code, pay type, narration)
- ALL headers are English in our current samples, but Myanmar (Burmese script) headers are possible from some clients

CONSTRAINTS:

1. Runtime: n8n Cloud Task Runner (sandboxed JavaScript, NO npm packages available, only built-in Node.js Buffer/crypto/zlib)
2. XLSX parsing: we CAN extract XML from the ZIP container using built-in zlib (proven — we've done it successfully)
3. We already have Gemini 3 Flash in the pipeline for email + vision processing
4. Target output schema (must produce this JSON regardless of input format):
    {
      "employees": [
        { "name": "U Kyaw Min", "account_or_phone": "09781234567", "amount": 100000 }
      ],
      "employee_count": 1,
      "total_amount_on_document": 100000,
      "corporate_wallet": "",
      "currency": "MMK"
    }
5. Must handle: English headers, potentially Burmese (Myanmar Unicode) headers, varying column order, metadata sections vs flat data, XLSX with merged cells

QUESTIONS — please answer ALL five:

Q1: Given the HIGH column variation, what parsing architecture do you recommend? Options we are considering:
  (A) Simple column mapping with template detection — fast but fragile, breaks on unknown templates
  (B) AI-assisted: extract CSV/XLSX content to text, send to Gemini alongside email body, Gemini maps columns intelligently — resilient but uses AI tokens
  (C) Hybrid: parse the file structure deterministically, send only column headers + first 2 rows to Gemini for mapping instruction, then apply that mapping to all rows programmatically
  (D) Your own suggestion if better than A/B/C
Pick ONE and explain your rationale.

Q2: For the XLSX format (Sample 4), the file is a ZIP containing XML. We extract sharedStrings.xml + sheet1.xml using built-in zlib. What is the most reliable way to convert this extracted XML to a readable text or CSV representation that Gemini can understand when included in a text prompt?

Q3: What blind spots or edge cases do you see that we might be missing? Consider:
  - Burmese Unicode column headers (Myanmar script like အမည်, ဖုန်းနံပါတ်, ပမာဏ)
  - Merged cells in XLSX (headers spanning multiple columns)
  - Multiple sheets in one XLSX workbook
  - CSV encoding (UTF-8 vs Windows-1252 vs UTF-16 BOM)
  - Delimiter variation (comma vs tab vs semicolon)
  - Number formatting ("1,000,000" vs 1000000 vs "1,000,000.00")
  - Empty rows between metadata and data table
  - TOTAL/summary rows at the bottom that should not be parsed as employees

Q4: Can you find any downloadable sample files of Myanmar bank transfer or payroll templates? Specifically looking for:
  - Wave Money MFS transfer forms (XLSX or CSV)
  - KBZ Bank salary transfer templates
  - Yoma Bank bulk payment templates
  - AYA Bank payroll upload formats
  - CB Bank corporate disbursement forms
  - Any Myanmar Central Bank (CBM) regulatory reporting template
  - Any Myanmar payroll software export samples
Provide direct download URLs where available. If no direct downloads exist, describe where these templates can typically be obtained.

Q5: Token efficiency — if we send the full CSV/XLSX content as text to Gemini 3 Flash, a 50-employee file is approximately 2-3KB of text. Is this efficient enough for a free-tier Gemini call (250K TPM limit, ~5-15 RPM), or should we preprocess to reduce tokens?

REPLY FORMAT:
1. Architecture recommendation (Q1) with rationale — pick ONE approach
2. XLSX-to-text conversion strategy (Q2) — specific implementation guidance
3. Blind spots + edge cases (Q3) — be thorough, list everything we should handle
4. Sample file URLs (Q4) — direct links if possible, alternatives if not
5. Token efficiency assessment (Q5) — numbers if you can estimate
6. Any additional recommendations we have not considered
