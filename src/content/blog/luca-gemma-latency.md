---
title: "Luca + Gemma 4: Latency Reduction Strategy"
date: 2026-05-28
excerpt: "Measurements, design decisions, and why Luca's architecture changed: from a 54-second prompt to under 8 seconds, by keeping Gemma out of the event loop."
tags: ["ai", "android"]
draft: false
---

*Originally published on my [old blog](https://nerdstuckathome.wordpress.com/2026/05/28/luca-gemma-4-latency-reduction-strategy/). For the story behind Luca, see [A local LLM for my parents' phone](/posts/gemma-hackathon).*

## Measurements, design decisions, and why the architecture changed

Recently, I had fun participating in the [Gemma 4 hackathon from Kaggle](https://www.kaggle.com/competitions/gemma-4-good-hackathon/writeups/new-writeup-1779054961877), building Luca:

> Luca is a Gemma-powered accessibility assistant. Gemma 4 is used as the reasoning layer over curated Android accessibility context. To make on-device interaction usable, Luca combines Gemma with structured perception, compact prompts, local ID mapping, deterministic safety checks, and immediate spoken feedback.

One of the main challenges with running an offline LLM like Gemma on a low-to-mid-range phone CPU was the high latency encountered every time the model was queried.

The original architecture put Gemma in the mandatory critical path too often: first to route the user transcript, and then again to reason over the screen. Manual measurements showed this is too slow for a voice assistant UX.

The new strategy keeps Gemma central for reasoning, but reduces latency by giving it compact inputs, minimal outputs, immediate progress feedback, and by reserving optional high-confidence/static command handling for actions that do not require model reasoning.

---

## 1. Problem discovered

Luca is meant to help elderly or non-technical users operate their phone. That means the user experience depends heavily on quick spoken feedback. A 10-15 second silence after a simple command feels broken, even if the model eventually returns the correct JSON.

The early M2B design used a Gemma text-only pre-screen router for every turn. The router decided whether the utterance was a local tool, a screen question, a general answer, or a clarification. That was architecturally clean, but it put Gemma on the critical path for commands that should be nearly instant, such as changing language or moving the assistant bubble.

> **Key UX issue:** The user does not care that the internal routing is clean. If Luca waits 13 seconds before saying *“Certo, parlerò in italiano”*, the command feels unusable.

---

## 2. Measurements collected

These measurements came from manual device tests and Edge Gallery experiments while iterating on the router and screen-reasoning prompts. Exact timings vary by device/backend, but the pattern was consistent: prompt size, output size, and mandatory full-JSON completion have a large effect on perceived latency.

| Experiment | Scenario | Observed result | Conclusion |
| --- | --- | --- | --- |
| M2B router before compact optimization | “speak Italian” in app | router\_inference\_ms ≈ 14,747; turn\_total\_ms ≈ 14,955 | Tool itself took milliseconds; Gemma router dominated. |
| M2B compact router after optimization | “speak Italian” in app | router inference\_ms ≈ 12,724; turn\_total\_ms ≈ 12,894; prompt ≈ 1,047 chars; output ≈ 42 chars; max tokens 64 | Compact prompt helped only ~2s; still too slow for local commands. |
| Realistic text-only router prompt | Edge Gallery | ≈ 27s to complete JSON | Confirmed issue was not only the app; realistic JSON routing is expensive. |
| GPU backend experiment | Edge Gallery GPU | Invalid/corrupted output | GPU was not a usable latency fix because output degenerated into nonsense. |
| Rich UI tree + OCR anti-scam prompt | Edge Gallery | 54s and schema violation (target returned as string) | Too slow and not reliable enough for default synchronous UX. |
| Medium compact screen map prompt | Facebook “save post” scenario | ≈ 26s | Better than rich prompt, but still too slow for frequent UI help. |
| Ultra-compact UI target prompt | Elements list only; minimal JSON | ≈ 7.9s | Best observed Gemma path; still needs progress cue but becomes demo-usable. |



---

## 3. Main latency lessons

* **Gemma should not be the event loop:** Gemma remains valuable for reasoning, ambiguity resolution, screen explanation, and safety analysis. But it should not be called for every small routing or settings decision.
* **Prompt size matters:** The difference between rich prompts and ultra-compact prompts was dramatic: roughly 54s versus roughly 8s in the tests. This is why M3 must use compact screen maps instead of raw UI trees.
* **Output size and schema complexity matter:** Luca cannot safely act until a full JSON object has been generated and parsed. Even if the model starts generating earlier, the app waits for completion. Minimal JSON reduces completion time.
* **Streaming perception differs from completion latency:** In Edge Gallery, users can see text stream in. Luca cannot execute a tool or highlight a target until it has valid structured output. That makes full-output latency more important than first-token latency.
* **Immediate feedback changes perceived latency:** For screen tasks that genuinely need Gemma, Luca should say *“Sto controllando lo schermo…”* immediately, then continue processing. This prevents long silence.

---

## 4. Changes already made

| Change | What changed | Why it matters |
| --- | --- | --- |
| **Compact M2B router prompt** | Reduced router prompt and JSON output; maxOutputTokens set to 64. | Improved latency slightly and reduced parse surface. |
| **Semantic find\_app route Play Store-backed app discovery** | Collapsed launcher vs Play Store choices into one semantic app route. “Open/search app” now opens Play Store page/search and tells user to press Open or Install. | Gemma no longer chooses between device-specific launcher flows; app uses Play Store surface. More consistent across Android launchers; wording is honest. |
| **GemmaReasoner responsibility cleanup** | Screen reasoner no longer chooses local tools; `tool_request` forced null/ignored. | Avoids two model prompts deciding tools. |
| **Prompt ownership refactor** | Gemma prompt builders moved into `assistant-gemma`; app/session orchestrates. | Cleaner module boundaries. |
| **Localized session/TTS fixes** | TTS locale reapplied on activation; no hardcoded English follow-up in GemmaReasoner. | Avoids Italian text spoken with English voice and vice versa. |
| **Explicit M2B observation request** | ScreenContext route now drives explicit ObservationRequest; legacy M1 planner bypassed. | Avoids old keyword classifier overriding M2B routing. |



---

## 5. M3 latency-first design

The updated M3 design is structured-perception-first, compact-screen-map-first, and minimal-output-by-default. Raw Accessibility tree and OCR data remain internal. Gemma receives a compact representation with stable IDs and returns a `target_id`, not coordinates.

### Example Interaction

* **User request:** *“How do I save this post?”*
* **App:** Facebook
* **Screen:** feed

#### Visible text:

* T1 Facebook
* T2 Anna Bianchi
* T3 A beautiful walk in the park today
* T4 Like
* T5 Comment
* T6 Share

#### Interactive elements:

* E1 Search
* E2 Messenger
* E3 Create post
* E4 Post author profile: Anna Bianchi
* E5 More options for this post
* E6 Post image
* E7 Like
* E8 Comment
* E9 Share

#### Return JSON only:

```json
{"say":"short answer","target_id":"ID or null","confidence":0.0}
```

The app keeps the `target_id -> source -> bounds` registry internally. If Gemma returns `target_id` = `E5` and confidence is high enough, Luca maps E5 to bounds locally and highlights the correct element. This avoids asking Gemma to generate coordinates in the common case.

---

## 6. Why not just use a local command matcher immediately?

A local/high-confidence matcher would improve latency for common commands, but it introduces risks: language coverage, false positives, and brittle keyword logic.

For example, “open Facebook” and “how do I open a bank account?” both contain “open”, but only one is an app command.

The current plan is to first make M3 efficient. If M3 plus compact routing is still too slow, implement a conservative `HighConfidenceIntentRouter` or static command shortcuts with strict gates.

> **Important distinction:** M3 compact screen maps optimize Gemma when screen reasoning is needed. A high-confidence/static command layer skips Gemma only for actions that do not need reasoning, such as language, bubble movement, trigger selection, or app discovery.

---

## 7. HighConfidenceIntentRouter / static command layer: deferred but likely needed

The deferred fast path should not be broad fuzzy matching. It should use strict slot/gate rules and prefer false negatives over false positives. Unknown cases fall back to Gemma.

| Intent | Required gates | Positive examples | Negative examples |
| --- | --- | --- | --- |
| **language\_change** | language-change phrase + supported language | “speak Italian”, “parla italiano” | “speak about Italy”, “Italian restaurants” |
| **move\_overlay** | movement intent + Luca/bubble context + position | “move to the top right”, “spostati in basso a destra” | “move the photo to the top right” |
| **find\_app** | open/find/search verb + recognized app entity | “open Spotify”, “cerca YouTube” | “open a bank account”, “open source software” |
| **screen\_context shortcut** | explicit screen/message/button/safety anchor | “where do I press?”, “is this message spam?” | “what should I do?” without screen anchor |
