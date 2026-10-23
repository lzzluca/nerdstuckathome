---
title: "A local LLM for my parents' phone: building an on-device assistant with Gemma 4"
date: 2026-10-15
excerpt: "What I learned building Luca for the Gemma 4 Good hackathon: an Android assistant for elderly users, running Gemma 4 E2B entirely on a mid-range phone."
tags: ["ai", "android"]
draft: false
---

## The brief: on-device AI for elderly users

My parents are in their 70s and live in Italy. Every week one of them calls me about a smartphone problem: an app they can't find, a button they can't see, a message that looks off. Most of the time I can help. Sometimes it's 9 PM and I don't pick up.

When Kaggle and Google DeepMind announced the [Gemma 4 Good hackathon](https://www.kaggle.com/competitions/gemma-4-good-hackathon), the Digital Equity & Inclusivity track felt written for that problem. So I built [Luca](https://github.com/lzzluca/luca): an Android assistant that elderly users can talk to in plain language, and that runs entirely on their phone.

What it does:

- Opens apps by handing off to the app's Play Store page, where the "Open" button is big and always in the same place, instead of making people hunt for an icon.
- Shows where to tap: it reads the current screen and draws a red box around the button the user needs.
- Flags scam messages before the user clicks anything.
- Talks like a person: "How do I open the gallery?", "Is this message safe?".

## Why on-device, why Gemma

The people I was building for don't fit the assumptions most AI products make. They don't own flagship phones: nobody's parents carry a €1,000+ device. They shouldn't have to create an account or pay a subscription, because sign-up flows are one of the things they need help with in the first place. And what the assistant sees, their messages and their screen, is exactly what should never leave the phone.

That points to a local LLM. Gemma 4 had the features I needed in a model small enough to try: it's multimodal, so it can look at a screenshot, and it runs on Android through [LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM).

## One model size, because only one fit

I'd planned to compare model sizes. That plan lasted until I tried running them. My test device was a Samsung Galaxy A55, a solid mid-range phone and a realistic stand-in for what my parents own. On it, Gemma 4 E2B was the only variant that ran at all. So there was no trade-off to explore: the hardware made the choice.

That constraint shaped the architecture. Running vision on every turn would have been too slow and too heavy, so Luca reads the screen in layers:

1. Accessibility tree + OCR first. Fast, cheap on the battery, and enough for most well-built apps.
2. Vision as a fallback, only when the UI is messy, unlabeled or mostly images.
3. Gemma decides every step: what to do, what to say, what to warn about.

## What worked, what didn't

Latency was the weak spot. On the A55, turns that needed vision were too slow for a fluid conversation. For someone already unsure of what's happening on their screen, a long silence feels like the app is broken. I measured where the time went, and what I changed, in [Luca + Gemma 4: Latency Reduction Strategy](/posts/luca-gemma-latency).

The model itself surprised me. For a model this size, Gemma 4 did more than I expected:

- It understands UIs. Give it a screenshot and it knows what a settings icon or a send button is.
- It returns the coordinates of elements in an image, which is what makes the red highlight box possible.
- It spots scams even when no keyword gives them away: it picks up on manipulation patterns like artificial pressure. "Buy now, this offer expires in 20 minutes!!" is exactly the kind of message it flags.

The gap showed up when my parents tried it. They liked it, but the version they used was still buggy, and they showed me where the design falls short. "Tell me where to tap" is a one-turn request: one question, one answer, one red box. "This website wants me to register" isn't. It needs several rounds, with the assistant guiding, the user acting, and the assistant checking the result. Luca handles the first kind well and struggles with the second. That kind of multi-turn back and forth is what most real requests look like.

## Where this could go next

Luca is a hackathon prototype, not a product. The list of things I'd fix first:

- Multi-turn conversations, so tasks that take several steps actually get finished.
- A dedicated registration helper, because sign-up flows are where elderly users get stuck most often.
- Latency on vision-heavy turns.
- Dialect support: many elderly Italians mostly speak a regional dialect at home.
- Basics: onboarding, a settings screen, a stop button, and visual feedback while Luca is listening or speaking.

The code is open source under Apache 2.0 at [lzzluca/luca](https://github.com/lzzluca/luca). There's a [video demo](https://youtu.be/aUE03TDudvA) and a [full write-up on Kaggle](https://www.kaggle.com/competitions/gemma-4-good-hackathon/writeups/new-writeup-1779054961877). Results haven't been announced yet as I write this.
