---
name: samples_readme
aliases: ["Samples Folder Guide"]
description: Navigation guide for the samples folder. Split into demo/ (synthetic fixtures we created for demos) and reference/ (real-world reference material from Wave/Yoma/Myanmar banking ecosystem). Some reference files are gitignored for privacy.
type: reference
topics: [samples, demos, reference, test-fixtures, guide]
status: active
created: 2026-04-20
last_reviewed: 2026-04-20
---

# Samples Folder Guide

This folder holds ALL test fixtures and reference materials for the Wave EMI Dashboard. Two distinct purposes, split into subfolders.

## 📁 `demo/` — Synthetic demo fixtures

Files we created (or synthesized via Grok) specifically for product demos. Safe to share publicly; no real names, no real payment data.

| Type | Files |
|---|---|
| Demo guides (markdown) | `DEMO_GUIDE_Tuesday_Apr7.md`, `DEMO_SCRIPT_Quick_Showcase.md` |
| Demo email scripts | `demo_email_1_ACME_with_attachment.md`, `demo_email_2_Golden_Dragon_no_attachment.md` |
| Synthetic bank slips | `bank_slip_acme_innovations.png`, `bank_slip_gintar_solutions.png` |
| Synthetic payroll docs | `grok_payroll_acme_innovations_3emp_USD.pdf`, `grok_payroll_global_solutions_3emp_EUR.pdf`, `payroll_demo_12emp.jpg`, `payroll_demo_wave_21emp.jpg` |
| Test employee data | `sample_employees.csv` |
| Edge-case tests | `test_password_protected.xlsx` (for password protection handling test) |

**When to use**: Running live demos, recording walkthroughs, onboarding new devs, writing docs that need realistic-looking fixtures.

## 📁 `reference/` — Real-world reference samples

Real documents from the Wave / Yoma / Myanmar banking ecosystem. Some contain real names, real account numbers, or real internal procedures — these are **gitignored** to prevent accidental public exposure.

### Public / non-sensitive (git-tracked)
| Category | Files |
|---|---|
| Synthetic test payrolls | `test_payroll_kbz_8emp_with_nrc.csv`, `test_payroll_wave_money_15emp.csv`, `test_payroll_yoma_bank_10emp.csv`, `generic_employees_100.csv` |
| Test deposit slips | `test_deposit_slip_yoma.csv`, `wave_money_bankslip_3emp_MMK.xlsx` |
| Grok-generated fixtures | `grok_generated/` (handwriting tests, informal payroll docs) |
| Internet samples for training | `internet_samples/` (public payroll templates from various sources) |
| HTML/PNG document tests | `test_documents_html/`, `test_documents_png/` |
| Handwriting OCR tests | `win_handwriting_otc_payroll_4emp.jpg` |

### Sensitive (gitignored — NEVER commit)
| Category | Path |
|---|---|
| IFC Myanmar mobile money report | `reference/IFC_Myanmar_Mobile_Money_Report.pdf` |
| Yoma Bank internal manual | `reference/Yoma_Bank_BBP_User_Manual_v2.pdf` |
| Pyigyikhin report | `reference/PyiGyiKhin.pdf` |
| Myanmar NRC (national ID) dataset | `reference/myanmar_nrc_data.json`, `reference/nrc_datasets/` |
| Yoma Bank docs | `reference/yoma_bank_docs/` |
| Wave Money screenshots | `reference/wave_money_screenshots/` |
| Culture survey with names | `reference/culture_survey_bilingual/` |

**When to use**: Training AI parsing on realistic Myanmar banking document formats, cross-validating field extraction, testing OCR on authentic handwriting.

**⚠️ Security**: If you add new sensitive files to `reference/`, update `.gitignore` immediately. If in doubt, gitignore first and ungitignore later.

## When to add new files

### Demo fixtures → `demo/`
- Created for product demos, screenshots, tutorials
- Contains fake names, fake numbers, fake emails
- Safe to share publicly

### Reference samples → `reference/`
- Real-world documents for AI training or testing
- Contains real names, real data, or proprietary formats → gitignore it
- Contains synthetic/public data → git-track it

### Avoid
- Don't add runtime test data here (use `test/` folder if created later)
- Don't add user-uploaded files here (those belong in Supabase storage, not repo)

## Related

- `docs/wave_emi_testing_guide_outlook_pipeline.md` — testing procedure using these samples
- `docs/wave_emi_app_walkthrough.md` — walkthrough that references several demo files
- `.gitignore` — for the exact list of gitignored paths under `reference/`
