---
name: wave_emi_user_handover_guide
aliases: ["Wave EMI User Handover Guide", "Myanmar Team Handover Guide"]
description: Official end-user handover guide for the Wave EMI salary disbursement system. Written for Win Win Naing and the Wave Money Finance team. Covers how to submit requests, use the dashboard, data safety rules (fake data ONLY), limitations, and escalation. Includes sign-off section for acknowledgment.
type: reference
topics: [handover, user-guide, wave-emi, myanmar, data-safety, legal]
status: active
created: 2026-04-20
last_reviewed: 2026-04-20
---

# Wave EMI System — User Handover Guide

**Version 1.0 — Official Handover**
**Date**: April 20, 2026
**Prepared by**: DK Nguyen, Trustify Technology
**For**: Win Win Naing, Wave Money Finance team, and all authorized Wave EMI users

---

## Table of Contents

1. [What This System Does](#1-what-this-system-does)
2. [⚠️ IMPORTANT — Data Safety Rule](#2-important--data-safety-rule)
3. [Before You Start](#3-before-you-start)
4. [How to Submit a Disbursement Request (Step by Step)](#4-how-to-submit-a-disbursement-request)
5. [How to Use the Dashboard](#5-how-to-use-the-dashboard)
6. [Understanding Ticket Status](#6-understanding-ticket-status)
7. [What to Do When a Ticket Is Flagged](#7-what-to-do-when-a-ticket-is-flagged)
8. [Example of Good Fake Test Data](#8-example-of-good-fake-test-data)
9. [What the System Cannot Do Yet (Known Limits)](#9-what-the-system-cannot-do-yet)
10. [Getting Help](#10-getting-help)
11. [Acknowledgment and Sign-Off](#11-acknowledgment-and-sign-off)

---

## 1. What This System Does

The Wave EMI System is an internal tool to help process salary disbursement requests.

When you send an email with a payroll request to the system, it will:

1. Read your email automatically.
2. Read your attached file (PDF, image, or bank slip).
3. Create a ticket in a dashboard so your team can review it.
4. Send you back a confirmation email.
5. Let your team approve the request and prepare payment files.

**In short**: Email in → Ticket out. The system saves you from copying payroll data by hand.

---

## 2. ⚠️ IMPORTANT — Data Safety Rule

**Please read this section carefully before using the system.**

### The Rule: Use FAKE data only. Never use real customer data.

This system is **in testing phase**. It works well, but it is **not yet approved for enterprise banking use**. This means:

- The servers that run the system are **not yet bank-compliant**.
- The AI that reads your emails is a **consumer-grade AI**, not an enterprise AI.
- Your data passes through **cloud services outside of bank-controlled infrastructure**.

### What this means for you:

> ❌ **DO NOT** send real customer names, real phone numbers (real MSISDN), real NRC numbers, real account numbers, real company names of actual Wave Money clients, or real amounts tied to real people.
>
> ✅ **DO** use made-up (fake, mock, fabricated) names, numbers, and amounts for all testing.

### Why this matters

If real customer data leaks through this system, the consequences fall on **you as the user**, not on Trustify Technology. By continuing to use this system, you agree that:

1. You are responsible for the data you submit.
2. You will use only fake/mock/fabricated data for all testing.
3. Using real customer data is a violation of this handover agreement.
4. Trustify Technology is not liable for any data exposure caused by user misuse.

**If you are unsure whether data is "fake enough"**, ask DK before sending.

---

## 3. Before You Start

You will need:

- [ ] An email account ending in **`@zeyalabs.ai`** (for example, `khanhnguyen@zeyalabs.ai`)
- [ ] Internet connection
- [ ] A web browser (Chrome, Edge, or Firefox recommended)
- [ ] The dashboard URL saved as a bookmark: **`https://project-ii0tm.vercel.app`**
- [ ] This guide (keep it for reference)

### Important rules about email addresses:

- The **sender** of every request email **must be** from the `@zeyalabs.ai` domain.
- The **receiver** (where you send the email to) **must always be** `emoney@zeyalabs.ai`.
- If you send from a Gmail, Yahoo, or any other address, the system will ignore your email.

---

## 4. How to Submit a Disbursement Request

Follow these steps every time you want to create a new ticket.

### Step 1: Open your email client

Use Outlook, Microsoft 365 Web, or any email tool connected to your `@zeyalabs.ai` account.

### Step 2: Start a new email

Click **New Email**.

### Step 3: Fill in the "To" field

Type exactly:
```
emoney@zeyalabs.ai
```

### Step 4: Write the subject line

Use this simple format:
```
Salary disbursement — [Fake Company Name] — [Fake Amount] [Currency]
```

**Example of a good subject**:
```
Salary disbursement — Test Corp Ltd — 2,450,000 MMK
```

### Step 5: Write the email body

Include these fields (simple format, no HTML needed):

```
Company: [Fake company name]
Total amount: [Amount and currency]
Number of employees: [Number]
Disbursement type: [SalaryToMA or SalaryToOTC]

Approvals:
- [Fake approver name 1] ([Role]) — Approved
- [Fake approver name 2] ([Role]) — Approved

Attached: payroll breakdown with employee details.
```

**Tip**: You can copy the template from **Section 8** of this guide and change the values.

### Step 6: Attach your file

Attach **ONE** of the following file types:

| File Type | Extension | Example |
|---|---|---|
| PDF document | `.pdf` | A bank slip or payroll report |
| JPEG image | `.jpg` or `.jpeg` | A photo of a handwritten payroll |
| PNG image | `.png` | A screenshot of a payroll table |

**Rules**:
- File size must be **less than 10 MB**.
- Do **not** password-protect the file. The system cannot read password-protected files.
- Attach **only one file** per email.
- The attachment should contain fake payroll data that matches the amounts in your email body.

### Step 7: Send the email

Click **Send**.

### Step 8: Wait for confirmation (about 1 minute)

Within about 1 minute, you will receive a **confirmation email** in your inbox from `emoney@zeyalabs.ai`. The email will contain:

- A **Ticket ID** (example: `TKT-005`)
- A summary of what the system read from your email and attachment
- A list of checks the system performed
- A link to the ticket in the dashboard

If you do **not** receive a confirmation email within 5 minutes, see **Section 10** (Getting Help).

---

## 5. How to Use the Dashboard

The dashboard shows all submitted tickets and their progress.

### Step 1: Open the dashboard

In your browser, go to:
```
https://project-ii0tm.vercel.app
```

Bookmark this page — you will use it every day.

### Step 2: Review the summary bar at the top

You will see four numbers at the top:

- **Pipeline Queue — LIVE**: how many emails are currently being processed
  - Pending: waiting to be read
  - Processing: being read right now
  - Completed: done, ticket created
  - Failed: system could not read it

- **All Emails**: total number of tickets created
- **Mismatch**: tickets that need human review (something does not match)
- **Ready for Finance**: tickets ready for the Finance team to approve

### Step 3: Click on a ticket to open it

Each ticket row shows:
- Ticket ID (example: `TKT-005`)
- Company name
- Type (MA or OTC)
- Amount
- Status

Click any row to see full details.

### Step 4: Review ticket details

Inside a ticket, you can see:

| Section | What it tells you |
|---|---|
| **Amount Check** | Three-way match: email vs attachment vs employee total |
| **Original Attachment** | The file you submitted (click to expand) |
| **Auto-Extracted from Email** | Data the AI read from your email body |
| **From Attachment** | Data the AI read from your attached file |
| **Employee list** | Names, wallet numbers, and amounts from your attachment |
| **Field comparison table** | Side-by-side view of what email said vs what attachment said |

### Step 5: Take action on the ticket

Depending on status, you may:
- **Save & Submit for Finance** — send the ticket for approval
- **Return to Client** — send it back if data is wrong
- **Generate CSV for Finance** — produce the payment files

---

## 6. Understanding Ticket Status

Every ticket has a status. Here is what each means:

| Status | Color | Meaning | What You Should Do |
|---|---|---|---|
| **Normal** | Green | All checks passed. Amounts match. | Review and approve if ready. |
| **Ready for Finance** | Green | Checked by Maker. Waiting for Finance. | Finance team should approve or reject. |
| **Amount Mismatch** | Yellow/Red | Email amount does not match attachment amount. | See Section 7. Ask the sender to resubmit. |
| **Asked Client** | Yellow | System asked the client for missing info. | Wait for client to resubmit. |
| **Failed** | Red | System could not read the email or attachment. | See Section 7. Contact DK if unclear. |

### Risk levels

Each ticket also shows a **Risk Level**:

- **Low** — all checks passed, normal flow
- **Medium** — some data missing but not blocking
- **High** — amount mismatch or missing required approver

---

## 7. What to Do When a Ticket Is Flagged

### Case A: "Amount Mismatch"

**What happened**: The amount written in the email does not match the total in the attached file.

**Example**:
- Email says: 4,500 USD
- Attachment total: 24,500 USD

**What to do**:
1. Do **not** approve the ticket.
2. Click **"Return to Client"** in the dashboard.
3. Ask the sender to resubmit a new email with the correct amount.
4. Close or ignore the old ticket.

### Case B: "Failed" — System could not read the document

**What happened**: The attached file could not be read by the AI. Common reasons:
- The file is password-protected.
- The handwriting is unclear.
- The image is blurry or upside down.
- The file is corrupted.

**What to do**:
1. The sender will automatically receive an email explaining the problem.
2. Ask the sender to resubmit with a clearer file.
3. If the problem repeats, tell DK.

### Case C: No confirmation email received within 5 minutes

**What to do**:
1. Check your spam / junk folder.
2. Verify the email was sent to exactly `emoney@zeyalabs.ai` (no typo).
3. Verify the sender email ends in `@zeyalabs.ai`.
4. If still no email, ping DK on Teams.

---

## 8. Example of Good Fake Test Data

Copy and adapt this example for your own tests. All names, numbers, and amounts are **fabricated** — safe to use.

### Example email

**To**: `emoney@zeyalabs.ai`

**Subject**: `Salary disbursement — Test Corp Ltd — 2,450,000 MMK`

**Body**:
```
Company: Test Corp Ltd
Total amount: 2,450,000 MMK
Number of employees: 3
Disbursement type: SalaryToMA

Approvals:
- Test Approver One (Sales HOD) — Approved on 2026-04-20
- Test Approver Two (Finance Manager) — Approved on 2026-04-20

Attached: payroll breakdown.

Regards,
[Your name] (QA test)
```

**Attachment**: A fake PDF or image containing:

| # | Employee Name | Wallet (fake MSISDN) | Amount |
|---|---|---|---|
| 1 | John Test Doe | 09111111111 | 800,000 MMK |
| 2 | Jane Sample Smith | 09222222222 | 850,000 MMK |
| 3 | Bob Mock Johnson | 09333333333 | 800,000 MMK |
| | **Total** | | **2,450,000 MMK** |

### Rules for fake data

| Data Type | Fake Pattern to Use | Example | Real Pattern to AVOID |
|---|---|---|---|
| Company name | "Test ___", "Sample ___", "Mock ___" | Test Corp Ltd | CB Bank, KBZ, Yoma, AYA, any real company |
| Employee name | Obvious fake names | John Test Doe, Ma Ma Sample | Any real person's name |
| Phone / MSISDN | Repeated digits or `0911...` `0922...` | 09111111111 | Any real Myanmar phone number |
| NRC number | Do not use at all | (leave blank) | Any real NRC pattern |
| Bank account | Round fake numbers | 12345678, 87654321 | Any real account number |
| Amount | Round fake numbers | 2,450,000 MMK | Amounts that match real payrolls |
| Approver name | "Test Approver One", "Fake HOD" | Test Approver One | Any real approver (Thet Hnin Wai, etc.) |

---

## 9. What the System Cannot Do Yet

Please know these limitations. If you hit any of them, it is **not a bug** — it is a known limit.

| Limitation | Impact | Workaround |
|---|---|---|
| **Password-protected files** | System cannot open them | Send the file without password protection |
| **Myanmar handwritten documents** | AI may not read handwriting correctly | Send typed/printed documents when possible |
| **Files larger than 10 MB** | System will reject the attachment | Reduce file size or split into smaller chunks |
| **Non-`@zeyalabs.ai` senders** | Email will be ignored | Always send from your `@zeyalabs.ai` account |
| **Multiple attachments per email** | Only the first is processed | Send one attachment per email |
| **Long Myanmar script text** | AI may translate inconsistently | Use English where possible for test data |
| **Real-time status updates** | Dashboard may take 30-60 seconds to refresh | Refresh the page manually if needed |

---

## 10. Getting Help

### First: try to solve it yourself

1. Re-read the relevant section of this guide.
2. Check that your email followed all the rules in **Section 4**.
3. Verify your data is fake per **Section 2** and **Section 8**.

### Next: contact DK

If the problem persists, contact:

- **DK Nguyen (Trustify Technology)**
- Contact method: **Microsoft Teams**
- When you message, include:
  - The Ticket ID (example: `TKT-005`)
  - A screenshot of what you see
  - What you were trying to do
  - When it happened

### Response time expectations

- **Monday–Friday working hours (Vietnam GMT+7)**: within 1-2 hours
- **Evenings / weekends**: best effort, may be next business day
- **Urgent outage**: ping DK directly on Teams with "URGENT" in the message

### Do NOT

- ❌ Do not send real customer data to "test" if the system is slow.
- ❌ Do not share the dashboard URL or system details outside the authorized team.
- ❌ Do not attempt workarounds using real data "just once" — this violates the data safety rule.

---

## 11. Acknowledgment and Sign-Off

By signing below, you confirm that you have read and understood this handover guide, and that you agree to:

1. Use only fake/mock/fabricated data when testing this system.
2. Never submit real customer names, phone numbers, NRCs, account numbers, or financial data.
3. Always send request emails from your `@zeyalabs.ai` account to `emoney@zeyalabs.ai`.
4. Take full responsibility for the data you submit.
5. Contact DK Nguyen for any questions before using the system.
6. Acknowledge that this system is in testing phase and not yet certified for enterprise banking use.
7. Acknowledge that Trustify Technology is not liable for any data exposure caused by misuse.

### Primary recipients

| Name | Role | Organization | Signature | Date |
|---|---|---|---|---|
| Win Win Naing | Operations | Wave Money | ___________________ | __________ |
| _________________ | Finance | Wave Money | ___________________ | __________ |
| _________________ | Finance | Wave Money | ___________________ | __________ |

### Delivered by

| Name | Role | Organization | Signature | Date |
|---|---|---|---|---|
| DK Nguyen | Data Engineer | Trustify Technology | ___________________ | __________ |

---

## Appendix — Quick Reference Card

Keep this one-page summary at your desk.

| Task | How |
|---|---|
| Dashboard URL | `https://project-ii0tm.vercel.app` |
| Email target | `emoney@zeyalabs.ai` |
| Required sender domain | `@zeyalabs.ai` |
| Allowed file types | PDF, JPG, JPEG, PNG |
| Max file size | 10 MB |
| Expected confirmation time | ~1 minute |
| Data rule | **FAKE DATA ONLY** |
| Help contact | DK Nguyen — Microsoft Teams |

---

**End of Guide**

*This guide is version 1.0, dated April 20, 2026. If you receive an updated version, please replace this document.*
