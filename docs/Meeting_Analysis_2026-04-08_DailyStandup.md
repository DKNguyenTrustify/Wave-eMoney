# Meeting Analysis — Daily Standup, April 8, 2026 (10:00 AM)

**Meeting:** Yoma Bank Daily Standup (~30 min)
**Transcript:** `_meetings/2026-04-08_Yoma_Daily_Standup.vtt` (full VTT, 2213 lines)
**Attendees:** Rita Nguyen (client), Tracy Nguyen, Vinh Nguyen Quang (PM), Tin Dang, Win Win Naing, Minh Ngo
**Topics:** AI infrastructure decision (0:00-6:40), Culture Survey app (6:40-14:55), **EMoney app (14:55-18:02)**, Elevator app (18:02-29:00), Wrap-up (29:00-30:30)
**Document by:** DK + Claude

---

## Part 1: AI Infrastructure Decision (0:00 - 6:40) — CRITICAL

This is the most important discussion in the transcript. Rita draws a clear line that the team keeps blurring.

### Rita's Core Message

> **Rita (0:03):** "You guys keep merging all of these conversations. I am saying I need from you the recommendation on what we do when we are using real data."

> **Tracy (0:24):** "For the mock data, Gemini does a good job and it's cheaper than the bedrock."

> **Rita (0:40):** "Fine. Bedrock is made for the enterprise version anyway."

> **Rita (0:46):** "It's overkill. Bedrock is overkill."

### Rita Escalates — Infrastructure, Not LLM

> **Rita (3:56):** "The question isn't just about the LLM, it's about the infrastructure."

> **Rita (4:02):** "We cannot have our bank, the e-money thing on Vercel. I don't think... I haven't done a security audit on Vercel, but I do not believe that it's PCI compliant."

> **Rita (4:18):** "We should use that [PCI compliance] as a bar for anything financial services."

> **Rita (4:39):** "How do you guys envision the e-money app being hosted and run in a month from now? That is what I want to know."

> **Rita (5:20):** "My point exactly. This isn't about the LLM conversation. This is about the **infrastructure** conversation. The infrastructure should support the LLM that you guys want to use."

> **Rita (5:35):** "And if Bedrock doesn't, and you guys are super hung up on Gemini and Bedrock doesn't support Gemini, then **find me the right infrastructure** for this."

> **Rita (5:43):** "Because the LLM is irrelevant. Like we can sign up for any ******* API key."

> **Minh (5:49):** "The final question here for now is that you guys need to **figure out the infrastructure first** and then we go with any LLM. So that's all. We don't need to care about what kind of LLM."

> **Rita (6:17):** "The LLM is almost completely irrelevant in this conversation of how do we keep things secure."

### What This Means

| Topic | Rita's Position |
|-------|----------------|
| **LLM choice** | "Irrelevant" — use whatever works |
| **Mock/testing** | Gemini is fine and cheaper |
| **Infrastructure** | THE real question — needs PCI compliance for financial services |
| **Vercel** | Not acceptable for production ("I do not believe it's PCI compliant") |
| **Bedrock** | Good for enterprise but overkill for testing |
| **Action needed** | Trustify must recommend the production infrastructure — not just the LLM |

### What Trustify Must Deliver

An **infrastructure recommendation** covering:
- Where to host the app (not Vercel — needs PCI-compliant hosting)
- Where to run the AI models (Bedrock, GCP, Azure — with security audit)
- How to handle real financial data securely
- Timeline for migration from Vercel demo to production infrastructure

**This is a DIFFERENT deliverable than the "Enterprise AI Platform Comparison" we planned.** Rita doesn't care about comparing Claude vs Gemini vs GPT. She cares about: "Where does this whole system live when we use real money data?"

---

## Part 2: EMoney App Update (14:55 - 18:02)

### What Vinh Presented

> **Vinh (14:57):** "The next one is going to be the e-money app. So the e-money app, we managed to test the **Myanmar handwriting with Gemini model** and it can detect the Myanmar handwriting and extract the data. Also displayed to the dashboard."

> **Tin Dang (15:14):** "Yeah, it's really good."

> **Vinh (15:16):** "So we will show to the team today."

### Win's Reaction to Myanmar Handwriting

> **Win (15:43):** "Okay, so maybe I will do that draw for you because the [Myanmar text on the image] is totally wrong. Yeah, let me draw one plain paper and draw for you after this."

> **Vinh (16:07):** "Oh, the language? Oh, the language is not correct."

> **Win (16:08):** "Yeah, no, not my language, not my language."

> **Vinh (16:11):** "Ohh, that's not working at all, that's not working."

**CRITICAL FINDING:** Win confirmed that the Myanmar text on Grok-generated handwriting images is **garbage** — not real Myanmar language. The AI-generated images look like Myanmar script but are actually nonsensical characters. Win offered to write real fake data by hand.

> **Rita (15:58):** "This is why we have you here, Huynh." (to Win)

> **Win (16:00):** "The Burmese language is literally raw. I don't even know what it is."

### The Pivot — Skip Handwriting in Demo

> **Vinh (16:42):** "We're waiting for some mock data from Huynh [Win] for the actual handwriting."

> **Vinh (17:00):** "Yeah, so I think maybe we don't need to show the handwriting in today's demo, but we need to verify again if the Gemini model can actually detect the real [Burmese] language."

> **Win (17:41):** "Yeah, you guys get the one, but I can quickly write the thing with a plain paper, then we can start over it, but I'm not sure we can finish to... maybe better **skip the handwriting part**. You can start with the [typed/digital] or with many fake data."

> **Vinh (18:02):** "OK, yeah, and that is for the e-money app."

### What This Means for Our Work

| Point | Impact |
|-------|--------|
| **Grok handwriting images have fake Myanmar** | Win confirmed the Myanmar text is gibberish — our P0 test result (11/13 employees extracted) is misleading because the "Myanmar names" weren't real Myanmar |
| **Win will provide real handwriting samples** | She'll hand-write fake data on plain paper — this is the Level 2 validation from Minh's strategy |
| **Handwriting was SKIPPED from 10:30 demo** | They showed typed/digital extraction instead |
| **Gemini needs to be tested with REAL Myanmar** | Current test only proves Gemini reads English handwriting + numbers, not Myanmar script |

---

## Part 3: Closing (29:00 - 30:30)

> **Rita (29:29):** Discussed Star City Living app — "I will give you the front end and you guys use the code as the single source of truth"

> **Rita (30:01):** "We need to go to this e-money demo, so we gotta run."

They transitioned to the separate EMoney demo session (`E-money Test Demo and Feedback Session.vtt`).

---

## New Person: Tracy Nguyen

Tracy speaks with authority about AI providers. She:
- Recommended Gemini over Bedrock for testing
- Rita accepted her recommendation immediately
- Appears to be a technical lead or architect role

**DK should find out:** Who is Tracy? What's her role at Trustify/Zaya?

---

## Action Items

| # | Action | Owner | Priority | Notes |
|---|--------|-------|----------|-------|
| 1 | **Infrastructure recommendation** — PCI-compliant hosting for production eMoney app | DK + Vinh + Minh | **CRITICAL** — Rita's #1 ask | NOT just LLM comparison — where does the whole system live? |
| 2 | **Get real Myanmar handwriting from Win** | DK/Vinh → Win | HIGH | Win will hand-write fake data on plain paper |
| 3 | **Test Gemini with real Myanmar text** | DK | HIGH | Current test used fake Myanmar from Grok — need real characters |
| 4 | **Don't demo Grok-generated Myanmar images** | DK/Vinh | Immediate | Win confirmed the Myanmar text is garbage |
| 5 | **Find out who Tracy is** | DK | Soon | She influences Rita's technical decisions |

---

## Strategic Implications

### 1. Infrastructure > LLM

Rita made this crystal clear — three times. The Enterprise AI Comparison doc (Phase 4) needs to be **reframed as an Infrastructure Recommendation**, not just an LLM comparison. Cover:
- Hosting: AWS (EC2/ECS/Lambda), GCP, Azure — with PCI compliance assessment
- AI: Bedrock, Vertex AI, Azure AI — as PART of the infrastructure, not the focus
- Data handling: encryption, data residency, audit trails
- Migration path: Vercel (demo) → production infrastructure

### 2. Myanmar Handwriting — Back to Square One

Our P0 test was encouraging (11/13 employees) but **the Myanmar text was fake**. We need:
- Real Myanmar handwriting from Win (she volunteered)
- Re-test with real characters
- This is the TRUE validation of Myanmar OCR capability

### 3. Vercel is Demo-Only

Rita explicitly questioned Vercel's PCI compliance. The production app cannot live on Vercel. This accelerates the Supabase + proper hosting conversation.

### 4. Gemini Confirmed for Testing

Tracy + Rita confirmed Gemini for mock data. Our v5/v5.1 pipeline is the right architecture. But production will need infrastructure-level security regardless of which LLM we use.

---

## Correction to Previous Analysis

The incomplete transcript (TXT file) was missing the critical eMoney section. Key corrections:

| Previous Understanding | Corrected Understanding |
|----------------------|----------------------|
| "Myanmar handwriting test was partial success" | Myanmar text on Grok images is **gibberish** — test only proves English handwriting OCR works |
| "Bedrock deprioritized" | Bedrock is deprioritized for LLM, but **infrastructure** conversation (which may include AWS) is Rita's #1 priority |
| "Enterprise AI comparison is next deliverable" | **Infrastructure recommendation** is the next deliverable — LLM comparison is secondary |
