#!/usr/bin/env bash
# Manual deploy: build locally, rsync the static output to the VPS.
# Usage: ./deploy/deploy.sh
# Requires: SSH key access to the VPS as the `luca` user, and
#   /var/www/nerdstuckathome already created + owned by that user on the server.

set -euo pipefail
cd "$(dirname "$0")/.."   # always run from repo root, wherever the script is invoked from

VPS_HOST="luca@169.58.0.254" # e.g. luca@nerdstuckathome.com once DNS is live
REMOTE_PATH="/var/www/nerdstuckathome"


echo "Building..."
npm run build   # writes the static site to ./dist/

echo "Syncing dist/ to $VPS_HOST:$REMOTE_PATH ..."
# Everything in ./dist/ is copied into $REMOTE_PATH on the server — that's
# the folder Caddy's `file_server` block (deploy/Caddyfile.snippet) serves
# directly, so whatever lands there is live immediately, no restart needed.
rsync -avz --delete ./dist/ "$VPS_HOST:$REMOTE_PATH/"

echo "Done. Caddy serves static files directly — no reload needed."
