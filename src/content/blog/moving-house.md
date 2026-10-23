---
title: "Moving house: why this blog now runs on my own server"
date: 2026-05-27
excerpt: "After years on WordPress.com, Nerd stuck at home moves to its own domain and a server I run myself. The old posts stay where they are."
tags: ["self-hosting"]
draft: false
---

I've been writing on and off since 2012 at [nerdstuckathome.wordpress.com](https://nerdstuckathome.wordpress.com): JavaScript and MooTools, Vim and Git tips, a couple of Intigriti challenge write-ups, and more recently some notes on running Gemma on a phone. From today, new posts land here.

I wanted more control over the blog, and a few things pushed me to actually do it.

The domain is mine again. My old `nerdstuckathome.blog` expired in January 2025, and I lost it. This time `nerdstuckathome.com` points at a server I run, and moving to another host later only means changing a DNS record.

The posts are files. Each one is Markdown in a Git repository, built into a static site with [Astro](https://astro.build/). No database, no admin panel, no ads or platform branding, and the whole history of every post is in `git log`.

One server does several jobs. The same small VPS that serves this blog also runs FreshRSS and the [pipeline behind my weekly news digest](/posts/self-hosted-rss-pipeline), so the blog costs nothing extra.

The old blog isn't going anywhere. It stays online as an archive, and the older posts are still [over there](https://nerdstuckathome.wordpress.com).
