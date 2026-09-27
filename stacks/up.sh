#!/usr/bin/env bash
# Start (or update) one app stack with the shared settings in stacks/.env.
#   ./stacks/up.sh uptime-kuma
#   ./stacks/up.sh jellyfin
# Re-running pulls newer images and recreates containers that changed.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

stacks=""
for f in "$here"/*/compose.yaml; do stacks+="$(basename "$(dirname "$f")") "; done
stack="${1:-}"
[[ -n "$stack" && -f "$here/$stack/compose.yaml" ]] || { echo "usage: $0 <stack>   stacks: $stacks" >&2; exit 1; }

if [[ ! -f "$here/.env" ]]; then
  cp "$here/.env.example" "$here/.env"
  echo "Created stacks/.env from the example. Check TZ and PUID/PGID, then re-run." >&2
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$here/.env"
set +a

# Create the data folder ourselves; if Docker creates it, it's owned by root.
mkdir -p "$APPDATA/$stack"

docker compose --env-file "$here/.env" -f "$here/$stack/compose.yaml" up -d --pull always
docker compose --env-file "$here/.env" -f "$here/$stack/compose.yaml" ps
