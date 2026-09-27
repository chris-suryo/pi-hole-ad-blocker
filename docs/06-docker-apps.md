# Phase 5: Docker + Uptime Kuma (monitoring)

**Goal:** a standard way to run apps on the Pi, plus a dashboard that alerts
you when something breaks. Pi-hole, Unbound and Tailscale stay installed
directly on the OS: they're core network plumbing and simplest to keep alive
that way. Everything else runs in Docker.

**Time:** about 15 min.

## 1. Install Docker

```bash
cd ~/homepi
./scripts/05-install-docker.sh
exit          # log out so the docker group applies, then ssh back in
docker ps     # should work without sudo
```

The script installs Docker Engine + Compose, turns on log rotation (protects
the SD card), and creates `/srv/appdata` for app data, outside this git
checkout.

## 2. Shared settings

```bash
cp stacks/.env.example stacks/.env
nano stacks/.env     # set TZ; check PUID/PGID match `id -u` / `id -g`
```

## 3. Uptime Kuma

```bash
./stacks/up.sh uptime-kuma
```

Open `http://homepi.local:3001` (or `http://homepi:3001` over Tailscale) and
create the admin account. Add monitors:

| Monitor | Type | Target |
|---|---|---|
| Pi-hole DNS | DNS | Resolver `192.168.77.53`, port 53, hostname `example.com` |
| Pi-hole web | HTTP | `http://192.168.77.53/admin` |
| Router | Ping | `192.168.77.1` |
| Internet | Ping | `1.1.1.1` |
| Each app you add later | HTTP | e.g. `http://192.168.77.53:8096` |

**Notifications:** Settings → Notifications. The free **ntfy** app (iOS/Android)
is the least fuss. Pushover, Discord and email also work.

**Blind spot:** Uptime Kuma runs *on* the Pi, so it can't tell you the Pi
itself died. For that, add a free "dead man's switch" at
[healthchecks.io](https://healthchecks.io). Create a check with a 5-minute period, then:

```bash
crontab -e
# add (use your own check URL):
*/5 * * * * curl -fsS -m 10 --retry 3 https://hc-ping.com/YOUR-UUID >/dev/null
```

If the pings stop, healthchecks.io emails or pushes you.

## Day-to-day

| Task | Command |
|---|---|
| Update an app | `./stacks/up.sh <name>` (pulls the latest image, recreates if changed) |
| Logs | `docker logs -f <name>` |
| Stop | `docker compose -f stacks/<name>/compose.yaml down` |
| What's running | `./scripts/verify.sh` or `docker ps` |

## Rollback

`docker compose -f stacks/uptime-kuma/compose.yaml down`, then delete
`/srv/appdata/uptime-kuma` to remove its data.
