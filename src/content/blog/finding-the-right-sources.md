---
title: "Finding the right sources, before summarizing them"
date: 2026-11-08
excerpt: "My weekly digest summarized whatever I happened to follow. Now two scheduled tasks look for the best content of the week and keep a log of who wrote it and where it showed up, so in eight weeks I can decide what to follow with real data."
tags: ["ai", "automation", "learning"]
draft: false
---

A month ago I wrote about [the self-hosted pipeline for my weekly news digest](/posts/self-hosted-rss-pipeline): everything flows into FreshRSS on my VPS, and on Sunday morning Claude summarizes it. It works. But after a few Sundays I realized that the question I really cared about came before the summary: are the sources in my FreshRSS actually the most relevant ones?

I had picked them over the years, a bit by habit and a bit by chance. If a source is mediocre, summarizing it doesn't help much, and a lot of what I read was noise. There was also a lot of redundancy: the same topic covered by five sources in five slightly different ways, or even the same post summarized by three newsletters (and then summarized again by my digest!).

So this post is about how I'm trying to find the right sources, and how I'm checking that the result can be trusted.

## Why a search and not a fixed list

The VPS pipeline only reads the feeds I give it. That means: it can only find what I already follow. A search works the other way around. Claude looks for the topics I care about on the web and on aggregators (Hacker News, Reddit, newsletters that collect links), so what emerges is what the community found interesting that week: the trends, the posts that got clicked and discussed. Then I look at who wrote them.

To be honest, I think this approach is better for my goal, so the VPS pipeline is still running but I'll probably delete it. Getting to the current setup also took a couple of attempts that I threw away, but the setup is what's worth sharing.

## Some definitions

Two words come up all the time, so let's define them first:

- Source: who wrote the original content. An author's blog, a company's engineering blog, a YouTube channel, an official changelog. I identify a source by its domain (for example `simonwillison.net`), so the same author always counts as one source.
- Channel: where the content was reported or collected. Hacker News, a subreddit, a newsletter made of links to other people's posts. YouTube and Spotify are platforms, not channels.

A site can be both: a newsletter is a source for what it writes and a channel for what it links.

## How it's organized

I have two topics, AI engineering and web & frontend, and each one has two cloud scheduled tasks that run every Sunday:

1. A weekly digest, the summary I read. It arrives as a notification, and I don't keep it anywhere.
2. A source discovery task, which picks the 15 best pieces of the week and writes them into a registry: a document with a table of sources, a table of channels and a weekly log.

The experiment lasts eight weeks: a checkpoint on 6 December and the final report on 3 January. Then I decide what to follow.

## The hard part: not fooling myself

This is the part I spent most of the time on. A system like this can easily produce numbers that look meaningful and aren't. A few things I noticed, and what I did about each:

1. Circularity. If the task finds content mostly by browsing Hacker News, then Hacker News will look like it covers everything, because it's where the content came from. So the search goes in two separate passes, in this order: first by topic, ignoring the channels; then the channels. Every item records how it was found.
2. The score can't reward channels. For the same reason, the score that picks the top 15 ignores whether something was popular. It's fit to my topics (up to 50 points), intrinsic quality (up to 35: original, with code, numbers or architecture, from someone who knows the subject) and time to read (up to 15). Only after the top 15 is chosen does the task check which channels contained each item.
3. Coverage has to be measured fairly. For each channel the registry computes how much of the top 15 it contained, but only on the weeks the channel was actually readable: if Reddit blocks the request one Sunday, that's a missing week, not 0%. There's also a second number, the coverage on the items found by the topic search only. In my opinion that's the least biased one, so the channels are sorted by it.
4. Nothing is judged by its title. Only content the task actually opened can be scored, and for every channel the log keeps the URL it read, or "not reachable" with the reason. A channel can't be marked as checked if nobody read it.
5. The log is the truth. The weekly log is never edited after the fact, and the tables are recomputed from it from scratch every week, instead of incrementing old numbers that could drift.
6. My opinion is the ground truth. Next to every item there's a "✅?" that I replace with ✅ when I've read it and found it useful. The scores are Claude's judgement; the ✅ are mine, and they're the only real check. I have a weekly task in Todoist that reminds me to read the digests and add them.

Final bit, more practical than methodological: the tasks run unattended, so nobody is there to approve anything. The prompt says to use only web search and fetch, never shell commands, and to mark a page as unreachable and move on instead of waiting. (I learned this one the hard way: the first runs asked me for a permission on every URL!)

## What I expect to learn

Point 3 is the one that answers the redundancy problem. If one newsletter covers most of the top 15, I can drop the others that repeat it. If the strongest sources don't pass through any channel, I should follow them directly, and the registry also notes which ones have an RSS feed.

There are limits, and I'd rather say them now: eight weeks is a small sample, Claude's search has its own biases, some channels will be unreachable some weeks, and the ✅ depend on me actually reading. The final report has to state all of that (it's written in the prompt).

I'll write about the results in January. Thanks for reading!
