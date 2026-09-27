# Development & deployment notes

## Writing posts

Add a new file to `src/content/blog/your-post-slug.md`:

```md
---
title: "Your title"
date: 2026-10-01
excerpt: "One or two sentences for the homepage/RSS."
tags: ["tag-one", "tag-two"]
draft: false   # set true to hide it from the site while you write
---

Your content in Markdown here.
```

The URL is derived from the filename: `your-post-slug.md` → `/posts/your-post-slug`.

Local preview: `npm run dev` → `http://localhost:4321`.

## First-time server setup (Contabo VPS, already running Caddy)

1. Add the site block from `deploy/Caddyfile.snippet` to `/etc/caddy/Caddyfile`.
   (If FreshRSS or anything else gets its own block later, they just sit
   side by side in the same file — no change needed here.)
2. Create the target directory and give the deploy user ownership:
   ```sh
   sudo mkdir -p /var/www/nerdstuckathome
   sudo chown luca:luca /var/www/nerdstuckathome
   ```
3. Validate and reload Caddy:
   ```sh
   sudo caddy validate --config /etc/caddy/Caddyfile
   sudo systemctl reload caddy
   ```
4. DNS for `nerdstuckathome.com` (and `www`) already points at the VPS —
   Caddy provisions the HTTPS cert automatically on first request.




## Deploying

**Manual** — edit `deploy/deploy.sh` with the VPS host, then run it. It builds
and syncs in one go:

```sh
./deploy/deploy.sh
```

**Automatic (GitHub Actions)** — add these repo secrets (Settings → Secrets
and variables → Actions):

- `VPS_HOST` — server IP or hostname
- `VPS_USER` — SSH user
- `VPS_SSH_KEY` — the private key that can SSH in as that user

Every push to `main` builds and rsyncs `dist/` to `/var/www/nerdstuckathome`
on the server automatically (see `.github/workflows/deploy.yml`).

## What's already in here

- Homepage (`src/pages/index.astro`) — featured post + list
- Single post page (`src/pages/posts/[id].astro`)
- Tag index + per-tag pages (`src/pages/tags/`)
- About page (placeholder copy — needs a real bio)
- RSS feed at `/rss.xml`
- Five draft posts scaffolded in `src/content/blog/`, each with a section
  outline
- Responsive layout (stacks to one column under ~900px)

## Not done yet

- Real content for the five draft posts (and the About page bio)
- A favicon / social preview image
- Analytics, if any (self-hosted Plausible/Umami would fit the
  no-third-party-trackers ethos of the design)
