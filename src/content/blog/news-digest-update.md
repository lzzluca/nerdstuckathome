---
title: "My news digest pipeline, one month later"
date: 2026-11-08
excerpt: "The media pipeline runs, podcasts included. YouTube refused every subtitle request, so Whisper did the work for weeks, until Gemini took over. And the hardest part turned out to be choosing the sources, not summarizing them."
tags: ["self-hosting", "ai", "automation"]
draft: true
---

A month ago I wrote about [the design of my news digest pipeline](/posts/self-hosted-rss-pipeline): everything lands in FreshRSS on my VPS, videos and podcasts become text, and on Sunday morning I get one summary per topic. Back then part of it was still a plan. This is what it turned into, including the parts that didn't go as planned.

The short version: it all runs now, on the VPS, with nothing to do by hand.

## What runs today

- Every night, `media.py` takes the new videos and podcast episodes of the `_media` categories and turns each one into a short summary. The summaries go into a feed that FreshRSS reads like any other.
- Every Sunday at 05:00, `digest.py` summarizes the last seven days of each text category with Claude: blogs, newsletters, and those media summaries too.
- Every five minutes, a cron line checks GitHub for new commits and redeploys the container. It's temporary, and I'll explain why below.

In the first post I said that scheduled Claude tasks write the digests. That was only a bridge while the pipeline was being built, and in the end it couldn't even work: FreshRSS's `robots.txt` blocks them. Now `digest.py` reads FreshRSS from inside the Docker network, so nothing has to be public.

## YouTube: three attempts

Problem: YouTube refuses subtitles to my VPS. Every request got an HTTP 429, even after waiting a day, with the cookies of a logged-in account and with `curl-cffi` pretending to be a real browser. I'm not 100% sure why, my guess: datacenter IPs are simply on a list.

First attempt that worked: download the audio (the cookies are enough for that) and transcribe it with Whisper on the VPS CPU. It works, but in practice it took about 25 minutes per video, every night, for a backlog of dozens of videos.

The one that stuck: Gemini. Its API accepts a YouTube URL directly, and Google reads the video from its own servers. That means: no 429, and no need for cookies, downloads or Whisper on my VPS. The first real video was summarized in a few seconds instead of 25 minutes, and the summary was good: concrete, with names, dates and the main argument. The free tier allows up to 8 hours of YouTube per day, which is plenty for me. I used an AI Studio project without billing on purpose: if I hit the limit, the API just says no, and there's nothing to charge.

When Gemini fails (quota, a model that gets retired, anything), the old path with cookies and Whisper still runs. If in two weeks the log shows no failures, I'll delete it: less code, and one secret fewer on the server.

## Podcasts

Podcasts were the easier part, as expected: the episode's audio file is in the feed, so the pipeline downloads it and transcribes it with Whisper, in 10-minute chunks so that a long episode doesn't need more memory.

Follow-up problem: one show failed with a 403. It's hosted on beehiiv, and beehiiv refuses requests that present themselves as `python-requests`, the default User-Agent of the library I use. With a User-Agent of its own (`news-digest/1.0 (podcast downloader)`) the same URL answers 200. One line of code, but finding it took a `grep` in the logs.

Two more things worth knowing:

1. I added a rule: items older than seven days are marked as read without a summary. Otherwise a video that failed once would stay unread forever, and be retried forever.
2. Only podcasts with a public feed work. For the platform-exclusive ones I read the show notes, and that's fine.

## The real problem was the sources

This is the part I didn't expect. Once the pipeline worked, I realized that summarizing well doesn't help much if the sources are wrong. My feeds came from years of habit, there was a lot of noise, and the same news arrived from five places.

So I tried to make Claude find the best sources for me: every Sunday, unattended, search the week's best content on my topics, see who wrote it and where it was shared, and keep a log for eight weeks. I spent a whole morning designing it to be honest with itself (that could be a post on its own!). Then it hit a wall: a run with nobody watching can't open web pages, because every new site asks me for an approval, and I'm not at the screen on Sunday morning. With search results alone it found almost nothing.

What I did instead is much simpler: a minimal base of sources picked by hand, each one checked to be still active and scored by how much an AI engineer can't afford to miss it. For AI that's twelve feeds. Anthropic has no RSS feed at all, so I added its news and engineering pages with FreshRSS's "HTML + XPath" feeds, which scrape the page (it will break the day they change the layout, but for now it works).

I'm not 100% happy about giving up on the measurement, but chasing the perfect source list was taking more time than reading.

## What's next

- Check Gemini's log in two weeks, then remove the old YouTube path.
- The same base of sources for web and frontend.
- Then stop touching the pipeline: revoke Claude's push access to the repo and remove the auto-deploy cron, which exists only so Claude can push changes while I'm away from the server.

For me the takeaway is that building the pipeline was the fun part, but choosing the sources mattered more. Now the plan is to spend Sunday mornings reading the digests.

Thanks for reading!
