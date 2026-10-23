---
title: "CSP the hard way: what rolling it out at Workera taught me"
date: 2026-10-23
excerpt: "A key customer asked for a strict Content Security Policy with a deadline. We planned two weeks; it took four months of removing inline scripts, chasing third-party vendors and teaching a new vocabulary to the whole engineering team."
tags: ["security", "frontend"]
draft: false
---

## Where it started

I came to Workera with six years of frontend security experience from EclecticIQ, and for at least two years there I was the go-to person for Content Security Policy. On paper CSP is simple: the server sends a header listing where scripts, styles, images and connections may come from, and the browser blocks everything else. If an attacker manages to inject a script, the browser refuses to run it.

The push came from outside. An important customer wanted CSP, gave us a deadline, and didn't accept `unsafe-inline`, the escape hatch that lets inline scripts run and that undoes most of what the policy protects against. We estimated two weeks. It took at least four months. Not full time, since it ran alongside other work, but four months all the same: first the components, then the templates, then the third-party software.

## Removing the inline JavaScript

Dropping `unsafe-inline` caused the most work, because we had a lot of inline JavaScript, much of it in templates that used Alpine.js. Alpine ships a CSP-compatible build, but we hadn't been using it, so the inline code had to be found and moved out, template by template.

## Where it breaks

A policy that works on one page can break another. Pages load different components and different libraries, so you can click through the app, see no errors, and still miss the one page that pulls in something the policy doesn't allow. Exercising every page by hand in a real product is close to impossible. Our first production rollout showed this: one of the assessment question types (the assessment is Workera's core product, the one that measures people's skills) depended on a library the policy blocked, so we went back and fixed it before enforcing again.

Then there are the third-party services, many of which don't support CSP at all. We had problems with PostHog, with a service that shows announcement banners inside the web app, with tldraw and with ElevenLabs. Plenty of vendors don't mention CSP anywhere in their docs. When their code needs something your policy forbids, you can loosen the policy for everyone, patch their code, or drop the vendor.

## Asking the vendor instead of patching

tldraw was the instructive case. I tested it against our policy and realized that making it compliant would be easy. I could have patched it myself, but a local patch is a liability: every upgrade can undo it, or bring in a new violation you only discover in production.

So I contacted the tldraw team, and they were open to adding support. [The ticket is public](TODO-tldraw-ticket-url). A fix upstream helps everyone who runs the library under a strict policy, and it survives the next release.

## Teaching the team the vocabulary

Part of the job had nothing to do with code. Before this project, CSP wasn't something the engineering team talked about. Terms like directives, nonces and hashes were new to most people.

So a lot of my time went into making that vocabulary common, and into writing compliance guidelines: what a new component may and may not do, and what to check before adding a vendor.

## How I'd introduce CSP on a new project today

1. Start in report-only mode. `Content-Security-Policy-Report-Only` makes the browser report violations without blocking anything. It would have caught our assessment problem before enforcement.
2. Collect the reports and fix what they show. Real traffic exercises the pages you would never think to test.
3. Inventory the third parties up front. Check whether each vendor works under a strict policy before you depend on it, and talk to the ones that don't.
4. Enforce only when the reports go quiet, and deploy when someone is around to watch.
5. Version the policy like code. It changes every time you add a vendor or a feature, and you want to know what changed and why.

That last point is why I started [cspgen](https://github.com/lzzluca/cspgen), an open-source CLI for reviewing, versioning and rolling out a Content Security Policy.

## Takeaways

- Whatever your estimate for CSP compliance is, it's probably low. Ours was two weeks; it took four months.
- Never enforce a policy you haven't run in report-only mode against real traffic.
- Ask vendors about CSP before you integrate them.
- When a library needs a fix, ask upstream before patching it locally.
