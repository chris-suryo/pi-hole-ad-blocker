# Phase 5: Docker + Uptime Kuma (monitoring)

**Goal:** a standard way to run apps on the Pi, plus a dashboard that alerts
you when something breaks. Pi-hole, Unbound and Tailscale stay installed
directly on the OS: they're core network plumbing and simplest to keep alive
that way. Everything else runs in Docker.

**Time:** about 15 min.

## 1. Install Docker

```bash
cd ~/homelab
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
| Media PC apps (Phase 7) | HTTP | listed in [08-mediabox-apps.md](08-mediabox-apps.md#8-monitoring-and-dashboard) |

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

## Optional: Portainer dashboard

A web page for your containers: status, logs, restart buttons.

```bash
./stacks/up.sh portainer
```

Open `https://homepi.local:9443` and accept the self-signed certificate warning.
Create the admin account within a few minutes of starting, or Portainer locks
itself for safety (`docker restart portainer` to retry).

**Ground rule:** use it to *look and restart*. Add or change apps through the
compose files in `stacks/`, so the repo always describes what's running. Apps
created inside Portainer exist nowhere else.

Portainer controls Docker, which is root-level control of the Pi. It's only
reachable on your LAN and tailnet. Keep it that way.

## Optional: Home Assistant

Only worth it if you have smart-home devices (lights, plugs, thermostat, cameras)
or plan to buy some.

```bash
./stacks/up.sh home-assistant
```

Open `http://homepi.local:8123` and follow the onboarding. It finds many devices on
the network automatically. This is the container install, which has no add-on
store. For Zigbee or Z-Wave devices you'll later want a USB radio stick; the
compose file already gives it USB access.

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
