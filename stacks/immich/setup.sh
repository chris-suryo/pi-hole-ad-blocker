#!/usr/bin/env bash
# Immich (self-hosted iCloud/Google Photos replacement). Immich ships its own compose
# file and changes it between releases, so this downloads the official one instead of
# keeping a stale copy in the repo, then writes a .env pointing at your storage.
#
#   ./stacks/immich/setup.sh            # first time; won't overwrite an existing .env
#   cd stacks/immich && docker compose up -d
#   Open http://homepi.local:2283
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

# shellcheck source=/dev/null
[[ -f ../.env ]] && { set -a; source ../.env; set +a; }
: "${TZ:=Etc/UTC}" "${APPDATA:=/srv/appdata}"

# Photos go on the big drive. The database stays on local disk (Immich does not
# support network shares for it); move it to an SSD if you have one.
UPLOAD_LOCATION="${UPLOAD_LOCATION:-/srv/storage/photos/immich}"
DB_DATA_LOCATION="${DB_DATA_LOCATION:-$APPDATA/immich/postgres}"

base=https://github.com/immich-app/immich/releases/latest/download
curl -fsSL -o docker-compose.yml "$base/docker-compose.yml"
curl -fsSL -o example.env "$base/example.env"
echo "Downloaded the latest official docker-compose.yml and example.env"

if [[ -f .env ]]; then
  echo ".env already exists; left unchanged. Delete it to regenerate."
else
  mountpoint -q /srv/storage || echo "warning: /srv/storage isn't a mounted drive yet; photos would land on the SD card" >&2
  # `|| true`: head closing the pipe early makes tr exit non-zero under pipefail.
  db_password="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true)"
  sed -e "s|^UPLOAD_LOCATION=.*|UPLOAD_LOCATION=${UPLOAD_LOCATION}|" \
      -e "s|^DB_DATA_LOCATION=.*|DB_DATA_LOCATION=${DB_DATA_LOCATION}|" \
      -e "s|^# *TZ=.*|TZ=${TZ}|" \
      -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${db_password}|" \
      example.env >.env
  chmod 600 .env
  echo "Wrote .env (random database password, TZ=${TZ})"
fi

mkdir -p "$UPLOAD_LOCATION" "$DB_DATA_LOCATION"
grep -E '^(UPLOAD_LOCATION|DB_DATA_LOCATION|TZ|IMMICH_VERSION)=' .env
echo
echo "Next:  cd stacks/immich && docker compose up -d"
