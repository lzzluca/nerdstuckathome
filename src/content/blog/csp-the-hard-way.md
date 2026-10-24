---
title: "CSP the hard way: what rolling it out at Workera taught me"
date: 2026-10-23
excerpt: "A key customer asked for a strict Content Security Policy, with a deadline. We planned a month and it took four: removing inline code, chasing third-party vendors and teaching a new vocabulary to the whole engineering team."
tags: ["security", "frontend"]
draft: false
---

When I joined Workera I had six years of frontend security behind me at EclecticIQ, and for at least two of them I had been the go-to person for Content Security Policy. So when CSP landed on our plate, it looked like my kind of job. We estimated a month: it took at least four (not full time, since it ran alongside other work, but four months all the same).

This post is the story of those months, in the order things went wrong, plus what I'd do differently today.

Table of contents

1. Where it started
2. Removing the inline code
3. Where it breaks
4. Asking the vendor instead of patching
5. Teaching the team the vocabulary
6. How I'd introduce CSP on a new project today

## Where it started

On paper CSP is simple: the server sends a header listing where scripts, styles, images and connections may come from, and the browser blocks everything else. If an attacker manages to inject a script, the browser refuses to run it.

The push came from outside: an important customer wanted CSP, gave us a deadline, and one requirement was no `unsafe-inline`, for scripts or for styles. `unsafe-inline` is the escape hatch that lets inline code run, and it undoes most of what the policy protects against. So the order of work was: first the components, then the templates, then the third-party software.

## Removing the inline code

Dropping `unsafe-inline` caused the most work. On the style side, the inline styles had to go. On the script side, we had a lot of inline JavaScript, much of it in templates that used Alpine.js.

Problem: Alpine ships a CSP-compatible build, but we hadn't been using it. So the inline code had to be found and moved out, template by template.

## Where it breaks

A policy that works on one page can break another. Pages load different components and different libraries, so you can click through the app, see no errors, and still miss the one page that pulls in something the policy doesn't allow. Exercising every page by hand in a real product is close to impossible.

Our first production rollout proved it: one of the assessment question types (the assessment is Workera's core product, the one that measures people's skills) depended on a library the policy blocked. So we went back and fixed it before enforcing again.

Follow-up problem: the third-party services, many of which don't support CSP at all. We had problems with PostHog, with a service that shows announcement banners inside the web app, with tldraw and with ElevenLabs. Plenty of vendors don't mention CSP anywhere in their docs. When their code needs something your policy forbids, you have three options: loosen the policy for everyone, patch their code, or drop the vendor.

## Asking the vendor instead of patching

The most instructive case was tldraw. I tested it against our policy and realized that making it compliant would be easy. I could have patched it myself, but a local patch is a liability: every upgrade can undo it, or bring in a new violation that you only discover in production.

So I contacted the tldraw team, and they were open to adding support ([the ticket is public](https://github.com/tldraw/tldraw/issues/5153)). A fix upstream helps everyone who runs the library under a strict policy, and it survives the next release.

## Teaching the team the vocabulary

Part of the job had nothing to do with code. Before this project, CSP wasn't something the engineering team talked about, and terms like directives, nonces and hashes were new to most people.

So a lot of my time went into making that vocabulary common, and into writing compliance guidelines: what a new component may and may not do, and what to check before adding a vendor.

## How I'd introduce CSP on a new project today

1. Start in report-only mode. `Content-Security-Policy-Report-Only` makes the browser report violations without blocking anything. It would have caught our assessment problem (see "Where it breaks") before enforcement.
2. Collect the reports and fix what they show. Real traffic exercises the pages you would never think to test.
3. Inventory the third parties up front. Check whether each vendor works under a strict policy before you depend on it, and talk to the ones that don't.
4. Enforce only when the reports go quiet, and deploy when someone is around to watch.
5. Version the policy like code. It changes every time you add a vendor or a feature, and you want to know what changed and why.

Point 5 is the reason I started [cspgen](https://github.com/lzzluca/cspgen), an open-source CLI for reviewing, versioning and rolling out a Content Security Policy.

## Takeaways

- Whatever your estimate for CSP compliance is, it's probably low: ours was a month, and it took four.
- Never enforce a policy you haven't run in report-only mode against real traffic.
- Ask vendors about CSP before you integrate them.
- When a library needs a fix, ask upstream before patching it locally.

Thanks for reading!
