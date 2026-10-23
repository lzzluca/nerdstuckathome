---
title: "The user is the director: a north star for my writing app"
date: 2026-10-24
excerpt: "Deep into building a writing app, I realized we had no direction to make decisions against. Now we have one, and it raises a question I can't fully answer: if the user directs, who is the writer?"
tags: ["ai"]
draft: true
---

<!-- Draft from my notes ("Punto 0 per writing app"). The app is the one Ink lives in: see "A day with Ink". -->

I have been building a writing app, the one where [Ink](/posts/a-day-with-ink) lives, and until recently without a clear direction. Every feature looked reasonable on its own, so every feature made it onto the list. What I was missing was a north star: one idea to measure each decision against.

I think I have it now. The user is the director.

## What "director" means

A film director doesn't operate the camera or write every line, but nothing ends up on screen without their decision. In the app, the AI writes, and the user decides what happens, when it happens, and whether a proposal makes it into the book. That's already how Ink works: it writes nothing into the book on its own, and everything it makes is a proposal the user accepts or discards.

What changes is that this stops being one rule among many and becomes the test for everything else.

## The question I can't fully answer

If the user is the director, the user isn't the writer. The AI is. I'm not sure how people who write will take that, and I'm not sure what I think about it either.

<!-- TODO: my own position. Some angles to pick from:
- Is directing a lesser form of authorship, or a different one? (Directors, editors, showrunners.)
- Who the app is for: people who have the story but get stuck on the page, not people who want the AI to have the ideas.
- What the app should refuse to do, if anything.
-->

## Tools around the director

With the director as the north star, the useful tools are the ones that help someone steer.

The blueprint is the clearest fit. The user sets the rhythm of the story: what should happen and roughly when. The blueprint checker then tells them whether things are actually happening at the right moment in the chapters written so far. The AI writes; the user keeps control of the pacing.

<!-- TODO: other "support" tools worth naming. Keep anything differentiating at the concept level. -->

## What the north star puts in doubt

Two modules I designed early now look different: the narrative debugger, and the knowledge graph as we've thought about it until now.

<!-- TODO: why. What did each one assume about the user's role, and what would a director actually need from them? -->

## Picking features by value

The practical consequence is a filter for the feature list. For each contract or feature, the question becomes: does this help the user direct? If yes, how much value does it add for a director? If no, it waits, however interesting it is to build.

<!-- TODO: two or three concrete examples of features that moved up or down with this filter. -->
