---
name: ai_council_readme
aliases: ["AI Council Folder Guide"]
description: Navigation guide for the AI Council folder - prompts, responses, synthesis, and phase-specific reviews. Covers the Wave EMI Dashboard's pattern of consulting multiple AIs for high-stakes decisions.
type: reference
topics: [ai-council, methodology, research, prompts, responses]
status: active
created: 2026-04-20
last_reviewed: 2026-04-20
---

# AI Council Folder Guide

The **AI Council** is DK's pattern of consulting multiple AIs (ChatGPT, Claude, Gemini, Grok, Perplexity, DeepSeek, Qwen) for high-stakes architecture decisions. Each AI gets the same prompt; their unique angles are synthesized into a final decision.

See `memory/feedback_ai_council_round6_best_of_breed.md` for the synthesis methodology.

## 📁 Folder structure

### `prompts/` — Input side
Consolidated prompts sent to the Council. One file per prompt cycle.

| File | Used for | Date |
|---|---|---|
| `ai_council_research_prompt.md` | Round 1 — early research scope | Pre-KAN-46 |
| `ai_council_downloadable_samples_prompt.md` | Round 2 — find downloadable Myanmar banking samples | Phase 3 |
| `ai_council_generate_test_documents_prompt.md` | Round 3 — generate test docs via Grok | Phase 3 |
| `ai_council_find_real_documents_prompt.md` | Round 4 — find real documents online | Phase 3 |
| `ai_council_docs_architecture_prompt.md` | Round 7 — docs system architecture review (Apr 19, 2026) | Apr 19 |

### `responses/` — Per-AI output
Each AI's response to a specific prompt. Filename pattern: `<ai>-<promptN>-response.md` or `<ai>-response.md`.

Contains responses from: **ChatGPT, Claude, DeepSeek, Gemini, Grok, Perplexity, Qwen** — across prompts 1-4 (Phase 3 era).

### `synthesis/` — Decision outputs
Final decision documents after synthesizing the Council's input.

| File | Synthesizes |
|---|---|
| `research_synthesis.md` | Phase 3 research rounds (prompts 1-4) |
| `ai_council_synthesis_phase3_1.md` | Phase 3.1 reviews |

### `phase3_1_reviews/` — Specific phase reviews
Reviews from each AI for the Phase 3.1 planning iteration. Kept separate because they're a bounded set (7 AIs × Phase 3.1 = 7 files).

## 🗄️ Older AI Council work (archived)

KAN-46 rounds (Rounds 4-6 that shaped the v13.x architecture) are archived in:
- `../../_archive/wave_emi_ai_council_old/` (at 03_build level)

These were the inputs for ADR-001, ADR-002, ADR-003 (see `decisions/` folder).

## 🧭 Methodology

From `memory/feedback_ai_council_round6_best_of_breed.md`:

1. **Frame the prompt carefully** — context, constraints, required format, explicit invitation to disagree
2. **Send to 4-6 AIs** — too few = groupthink; too many = synthesis overhead
3. **Collect responses** — save verbatim, even if some are weak
4. **Synthesize**:
   - **Convergence** (what most agree on) → accept as baseline
   - **Divergence** (unique insights) → evaluate each for integration value
   - **Best-of-breed** (combine critical uniques) → design no single AI proposed
5. **Document the decision** as an ADR (not an AI Council file — the rounds are INPUTS, not decisions)

## When to run a new round

Run an AI Council round when:
- You're making a non-trivial architectural decision
- You suspect your own reasoning has blind spots
- Stakes are high enough to justify 30-60 min of prompt + synthesis effort
- The decision would be expensive to reverse

Don't run a round for:
- Minor implementation choices
- Decisions that are obvious after 5 min of thought
- Tasks where execution beats deliberation

## Related

- `memory/feedback_ai_council_round6_best_of_breed.md` — synthesis methodology
- `memory/feedback_ai_council_round5_methodology.md` — Round 5 methodology
- `../../decisions/` — ADRs that capture decisions informed by Council rounds
- `../../_archive/wave_emi_ai_council_old/` — KAN-46 Round 4-6 archives
