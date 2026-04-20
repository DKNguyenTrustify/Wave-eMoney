---
name: research_readme
aliases: ["Research Folder Guide"]
description: Navigation guide for the Wave EMI Dashboard research folder. Contains AI Council artifacts (consolidated subfolder) and domain references (Myanmar banking fields).
type: reference
topics: [research, ai-council, myanmar, guide]
status: active
created: 2026-04-20
last_reviewed: 2026-04-20
---

# Research Folder Guide

Active research for the Wave EMI Dashboard. Reorganized Apr 20, 2026 to consolidate scattered AI Council files.

## 📁 Structure

```
research/
├── README.md                           ← this file
├── myanmar_banking_field_reference.md  ← domain reference (NRC, MSISDN formats, etc.)
└── ai_council/                          ← AI Council artifacts (consolidated)
    ├── README.md                       ← AI Council folder guide
    ├── prompts/                        ← 5 consolidated prompts
    ├── responses/                      ← per-AI responses (20 files)
    ├── synthesis/                      ← decision synthesis documents
    └── phase3_1_reviews/               ← Phase 3.1 specific reviews
```

## 📚 Key files

### Domain reference
- [[myanmar_banking_field_reference]] — MSISDN format (`09xxxxxxxxx`), NRC format, Myanmar banking conventions

### AI Council
- See [ai_council/README.md](ai_council/README.md) for full guide

## Related

- `docs/wave_emi_app_walkthrough.md` — app walkthrough
- `docs/wave_emi_architecture_data_flow.md` — architecture
- `../samples/reference/` — real-world reference samples (some gitignored)
- `../../../decisions/` — ADRs that decisions informed by AI Council rounds
- `../../../_archive/wave_emi_ai_council_old/` — KAN-46 Round 4-6 archives
