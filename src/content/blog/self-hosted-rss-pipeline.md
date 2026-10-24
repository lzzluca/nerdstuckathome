---
title: "Designing a self-hosted pipeline for my weekly news digest"
date: 2026-10-09
excerpt: "Blogs, newsletters, YouTube and podcasts, all flowing into one FreshRSS instance on my VPS and summarized once a week. What already runs, and the architecture I'm building for the rest."
tags: ["self-hosting", "ai", "automation"]
draft: false
---

I follow a lot of sources on AI, system design, web development and finance, and they're scattered everywhere: blogs, email newsletters, YouTube channels, podcasts. Keeping up with them matters to me, both to keep learning and because it's the kind of knowledge that comes up in job interviews. Opening a different app for each of them doesn't work.

What I want is one place where everything lands, and one summary per topic on Sunday morning. Everything should run on my own server, with nothing to do by hand (I work from one Mac in the Netherlands and another one when I'm in Italy, and I don't want to configure anything twice).

This post is about the design. Part of it already runs, and the media part is what I'm building next.

Table of contents

1. What already runs
2. How the feeds are organized
3. The media pipeline
4. What the first tests showed
5. What's next

## What already runs

The base is [FreshRSS](https://freshrss.org/), self-hosted on a small Contabo VPS with Docker Compose, behind Caddy. It's only for me.

Blogs and sites already speak RSS. Newsletters don't, so I wrote mail2rss: a small script that reads a dedicated Gmail account through the Gmail API (with a read-only token) and turns selected senders into feeds. It runs as a container on the same internal Docker network as FreshRSS, so the feeds are never exposed publicly. I wrote about it in [Configuring email to RSS](/posts/configuring-email-to-rss).

Then, every Sunday, scheduled Claude tasks read FreshRSS and write one digest per topic: AI, system design, web and frontend, finance.

![The whole setup: blogs and sites feed FreshRSS on my VPS directly; newsletters go through mail2rss, which reads a dedicated Gmail with a read-only token; YouTube channels and podcasts land in separate media categories. Scheduled Claude tasks write the Sunday digests from the text categories. The media pipeline, still being built, will transcribe the media items, summarize them with Claude CLI with its tools switched off, and mark them as read in FreshRSS](/images/posts/news-pipeline.svg)

## How the feeds are organized

Each topic has two FreshRSS categories:

```
AI          ← blogs and newsletters (text)
AI_media    ← YouTube channels and podcasts
```

The suffix does two jobs: it keeps related categories next to each other in the sidebar, and it gives the pipeline a clean boundary. The Sunday digests read the text categories, and the media pipeline reads only the `_media` ones.

## The media pipeline

Text is easy for an LLM to summarize, but a video or a podcast first has to become text. The plan:

```
FreshRSS (*_media, unread, ≤ 7 days old)
  → YouTube: fetch the transcript, fall back to Whisper
  → podcasts: download the episode from its public feed, transcribe with Whisper
  → platform-exclusive podcasts: a fallback to get the audio, then Whisper
  → Claude CLI on the VPS: summarize each transcript
  → mark the item as read in FreshRSS
```

A few decisions behind it:

1. FreshRSS is the state. The pipeline processes unread items up to seven days old and marks each one as read when it's done. There's no local database of processed IDs to keep in sync: if an item is unread, it hasn't been handled.
2. Time isn't a constraint, resources are. Whisper on a VPS CPU can take hours for one episode, and that's fine for a weekly digest. What I don't want is the pipeline starving FreshRSS or the blog on the same machine, so the limits (CPU and memory) live on the Docker container instead of in the code.
3. Summaries go through Claude CLI instead of a paid API. I already have a Claude subscription, so the pipeline calls Claude CLI on the VPS once per transcript. The constraint is staying within the plan's usage limits.
4. That call runs headless, with its tools switched off. A transcript is text written by someone else, and some of it could be written to steer an LLM. The summary step turns text into text, so it has no reason to be able to run anything, and with no tools a prompt injection hidden in a podcast has nothing to act on.
5. The pipeline gets only the permissions it can't work without. A separate FreshRSS user just for it would be cleaner (it's on the list for later).

## What the first tests showed

Problem: YouTube blocks requests from my VPS's IP. For now the plan is to use cookies from a logged-in session on the server and see how often they expire. If that turns out to be fragile, a VPN or a residential proxy are the fallbacks.

Whisper, on the other hand, was easier than I feared! In a first test on the VPS, `faster-whisper` with the `small` model transcribed 10 minutes of audio in 1.1 minutes, with a peak of 739 MB of RAM. Its weak spot is proper names (Whitenack became "Lightnack"), so the summary step also gets the episode title and description and is told to fix names from context.

The other surprise is scope. "One place for my news" turned into an aggregator, a mail-to-feed bridge, a transcription pipeline and a scheduler... so I'm keeping it simple on purpose: start with the smallest version that works, see how it behaves, and only then decide what's worth adding.

## What's next

Building the media pipeline itself. I'm also considering letting Claude CLI work on it directly on the VPS, unattended and overnight. I'll write a follow-up once it's running.

Thanks for reading!
