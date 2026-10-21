---
title: "A day with Ink: from a few tools, to a writer that proposes"
date: 2026-10-20
excerpt: "Building an agent as writing assistant: introducing Ink."
tags: ["ai"]
draft: false
---

*2026-10-20. Notes from building the agent of a novel-planning app, with
Claude Code as pair. Twenty commits, one grilling session, and a few things
I had to be told twice.*

The app is a planning board for a novel: scenes on a timeline, characters,
a plot, notes, and an AI assistant called Ink in the right column. The rule
that was never up for debate: **Ink writes nothing into the book on its own.
Everything it makes is a proposal the user accepts.**

Yesterday Ink had four tools and a card for each proposal. Today it has a
writer.

## Morning: the model, then the question

The first thing was practical. Ink ran on a local Gemma through Ollama and
took minutes per turn. I switched it to DeepSeek through an OpenAI-compatible
endpoint, and the first lesson of the day was not about AI at all: the API
process had been started before the `.env` change, `tsx watch` does not
reload environment files, and five stale watchers were still alive. Kill
everything, restart, and log the provider and model at startup so this never
costs an hour again.

With a fast model, the question I had been postponing came up: what is Ink
for? We ran a long interview, five rounds of numbered questions with a
recommended answer each, and the answers reshaped the design:

- Tools are typed on the shape of a change (create scenes, split a scene,
  edit scenes, write the plot, review, read a scene, label a scene). The
  *intention* is free text, an `instruction` the chat writes for the writer.
  No "translate" tool, no "shorten" tool: those are instructions.
- Two model roles. The chat routes, converses, and writes briefs. The
  writer produces every piece of narrative: outlines, splits, prose,
  edits, the plot. The reviewer runs on the writer's slot. Each is one
  system prompt with holes filled by code.
- Proposals are scenes: real rows in the timeline with a `status` of
  `proposed` and a `replaces` pointer, instead of ghost cards in the chat.
  Accepting one proposal that points at a scene is an edit; accepting two is
  a split. They are dashed in the timeline, where the user already lives.
- No limits, but visible tokens. I was about to cap scenes per turn and
  words per scene. The decision was the opposite: show what each turn cost
  under every reply and let the user decide.

## Afternoon: eight items, unattended

I went away and left a list. What came back, each step verified from a
shell script that drives the chat and from the browser where the UI changed:

1. A `usage` event under every reply: tokens in, out, and how full the
   context window got, chat and sub-agents added up.
2. The migration and endpoints for proposed scenes, with accept and discard
   for one or for all.
3. The writer behind `editScenes`: an empty proposal appears in the timeline
   first, the prose streams into it, it is saved when done. Four in flight at
   a time, so "translate every scene" is one call.
4. Main scenes from the plot and splitting a scene through the writer, both
   returning the same `## Title` sections the importer already reads. And
   the plot itself from a two-line idea.
5. A scene opens in the centre column, with the current text next to the
   proposed one.
6. The reviewer: the structural facts are computed in code and handed to a
   model whose text streams straight to the user.
7. A real Stop, as a request of its own. A dropped browser tab no longer
   kills a write in progress: the turn finishes and the proposal is saved.
8. Once the book has prose, the chat's prompt lists an index and a tool
   fetches one scene on demand.

Two decisions I made alone and flagged for review: the writer returned
content only, no summary, and the reviewer's text bypasses the chat
entirely. The first one did not survive the evening.

## Evening: where the prose goes

Back at the keyboard, the questions were about plumbing, which turned out
to be where the tokens were going.

What does a tool return to the chat? The JSON object the tool's function
returns, serialized into a message of role `tool`. And that
message joins the conversation history, which is sent again on every later
turn until it falls out of the 40-message window. The writer's prose was in
that object. So every scene Ink wrote was re-sent, in full, on every message
for the next forty.

The fix was the structured output I had avoided in the afternoon, done
without structured output. The writer now closes with a `## Summary` line.
The streaming loop holds the marker back from the timeline, the parser cuts
it from the content on save, and the tool returns title, word count and
that one sentence. The chat never sees the prose unless it asks for it. The
summary comes from the model that wrote the text, not from one reading an
excerpt.

Why did the chat hallucinate duplicates? After a split, the listing read
"8. Title", "9. Title (PROPOSED)", "10. Title (PROPOSED)". Two lookalikes side
by side, and the chat told the user there were duplicates to clean up. I had
patched it with a sentence in the prompt. The better fix was structural: the
listing now says, on both sides, what the relation is. A proposal names the
scene it replaces; a scene names the proposals waiting to replace it, "its
possible next version, not duplicates". A prompt rule asks the model to
remember; a listing that states the relation gives it nothing to
misremember.

And since a prompt change cannot be unit-tested, the day ended with an
eval: a shell script that plants two replacements of a scene through the
API, asks the chat where that scene stands, and fails if the reply contains
"duplicate". It passed twice. The result is not deterministic, so it runs
every time the prompt or the listing changes. When there are three of these,
promptfoo; not before. The chat, incidentally, did better than pass: it
noticed that accepting the two replacements would leave a causal hole two
scenes later.

## What I had to be told

- "Ten messages of history for the writer?" Why ten. The writer gets the
  same trimmed history the chat has. Arbitrary numbers are a smell.
- "The instruction is a brief, not the work." The chat's first instinct was
  to outline all eight scenes inside the instruction it sent to the writer.
- Terms in English, in the product and in the code: outline, prose, split,
  write, instruction. The Italian stays in the conversation.
- The end-to-end test is still not done: two different two-line prompts,
  and then my own story.

## What is next

Retrieval. The index shows a scene's first lines, so a user who refers to a
*fact* rather than a scene number leaves Ink blind, and "where did I mention
the blue car" needs more reads than a turn has steps. Three layers, in order
of cost: a token budget instead of a word threshold, so a short novel is
always sent whole; a summary per scene in the index, which the writer now
produces anyway; and a search tool, full-text first, embeddings only if
paraphrase proves necessary. None of it is built. Tomorrow's question is
which one first.
