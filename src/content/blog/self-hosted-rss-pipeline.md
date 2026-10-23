---
title: "Designing a self-hosted pipeline for my weekly news digest"
date: 2026-10-24
excerpt: "Blogs, newsletters, YouTube and podcasts, all flowing into one FreshRSS instance on my VPS and summarized once a week. What already runs, and the architecture I'm building for the rest."
tags: ["self-hosting", "ai", "automation"]
draft: false
---

## Why I want this

I follow a lot of sources on AI, system design, web development and finance, and they're scattered everywhere: blogs, email newsletters, YouTube channels, podcasts. Keeping up with them matters to me, both to keep learning and because it's the kind of knowledge that comes up in job interviews. Opening a different app for each of them doesn't work.

What I want is one place where everything lands, and one summary per topic on Sunday morning. Everything should run on my own server, with nothing to do by hand. I work from one Mac in the Netherlands and another when I'm in Italy, and I don't want to configure anything twice.

This post describes the design. Part of it already runs; the media part is what I'm building next.

## What already runs

The base is [FreshRSS](https://freshrss.org/), self-hosted on a small Contabo VPS with Docker Compose, behind Caddy. It's only for me.

Blogs and sites already speak RSS. Newsletters don't, so I wrote mail2rss, a small script that reads a dedicated Gmail account through the Gmail API with a read-only token and turns selected senders into feeds. It runs as a container on the same internal Docker network as FreshRSS, so the feeds are never exposed publicly. I wrote about it in [Configuring email to RSS](/posts/configuring-email-to-rss).

Every Sunday, scheduled Claude tasks read FreshRSS and write one digest per topic: AI, system design, web and frontend, finance.

## How the feeds are organized

Each topic has two FreshRSS categories:

```
AI          ← blogs and newsletters (text)
AI_media    ← YouTube channels and podcasts
```

The suffix keeps related categories next to each other in the sidebar, and it gives the pipeline a clean boundary: the Sunday digests read the text categories, and the media pipeline reads only the `_media` ones.

## The media pipeline

Text is easy for an LLM to summarize. A video or a podcast first has to become text. The plan:

```
FreshRSS (*_media, unread, ≤ 7 days old)
  → YouTube: fetch the transcript, fall back to Whisper
  → podcasts: download the episode from its public feed, transcribe with Whisper
  → Claude CLI on the VPS: summarize each transcript
  → mark the item as read in FreshRSS
```

FreshRSS is the state. The pipeline processes unread items up to seven days old and marks each one as read when it's done. There's no local database of processed IDs to keep in sync: if an item is unread, it hasn't been handled.

Time isn't a constraint, resources are. Whisper on a VPS CPU can take hours for one episode, and that's fine for a weekly digest. What I don't want is the pipeline starving FreshRSS or the blog on the same machine, so the limits live on the Docker container (CPU and memory), not in the code.

For summaries I'm using Claude CLI instead of a paid API. I already have a Claude subscription, so the pipeline calls Claude CLI on the VPS once per transcript. The constraint is staying within the plan's usage limits.

The pipeline gets only the permissions it can't work without. A separate FreshRSS user just for it would be cleaner, and it's on the list for later.

## What's already harder than expected

YouTube blocks requests from my VPS's IP. For now the plan is to use cookies from a logged-in session on the server and see how often they expire. A VPN or a residential proxy are fallbacks if that turns out to be fragile.

The other surprise is scope. "One place for my news" turned into an aggregator, a mail-to-feed bridge, a transcription pipeline and a scheduler. I'm keeping it simple on purpose: start with the smallest version that works, see how it behaves, and only then decide what's worth adding.

## What's next

Building the media pipeline itself. I'm also considering letting Claude CLI work on it directly on the VPS, unattended and overnight. I'll write a follow-up once it's running.
