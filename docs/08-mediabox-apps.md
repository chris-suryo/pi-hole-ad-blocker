# Phase 7: Media server, photos, file shares, backups (on the media PC)

**Goal:** Jellyfin and/or Plex with hardware transcoding, Immich replacing iCloud
Photos, Mac file shares and Time Machine, and backups. Everything runs on
`mediabox` and is reachable at home and, over Tailscale, away.

## 1. Shared settings

```bash
cd ~/homelab
cp stacks/.env.example stacks/.env
getent group render | cut -d: -f3      # note this number
nano stacks/.env                        # set TZ, RENDER_GID=<that number>, check PUID/PGID (id -u / id -g)
```

## 2. Jellyfin, Plex, or both?

| | Jellyfin | Plex |
|---|---|---|
| Hardware transcoding (Quick Sync) | **Free** | **Plex Pass only** ($6.99/mo or $69.99/yr) |
| Watching away from home | Free over Tailscale | Plex Pass on your server, or a Remote Watch Pass ($2.99/mo) per viewer |
| Apps | Good: web, iOS/Android, Android/Google TV, Fire TV, Roku, Apple TV (Swiftfin or Infuse) | The most polished, on nearly every TV |
| Sharing with friends (e.g. Paul) | Share the `mediabox` machine to their tailnet, or give them an account over a public URL | Built in. The owner's Plex Pass covers every shared viewer |

**Decision: Plex with Plex Pass** is the main server ([decisions.md](decisions.md)).
Friends and family outside the tailnet stream through it (§4), and the owner's Plex
Pass covers all of them and turns on Quick Sync. **Jellyfin is optional** alongside it,
for the household over Tailscale. Both read the same media folder (read-only).

Requests and library automation (Seerr, Sonarr, Radarr, downloaders) come from
[chris-suryo/plex-server](https://github.com/chris-suryo/plex-server), which runs on this
PC after Phases 6–7 and files everything under `/srv/storage/data/media`.

## 3. Jellyfin (optional)

```bash
./stacks/up.sh jellyfin
```

Open `http://mediabox.local:8096`, create the admin account, and add libraries at
`/media/movies` and `/media/tv`. Then **Dashboard → Playback → Transcoding**:

- Hardware acceleration: **Intel QuickSync (QSV)**
- QSV device: `/dev/dri/renderD128`, or whatever `verify.sh` reported
- Hardware decoding for: **H264, HEVC, MPEG2, VC1, VP8, VP9, HEVC 10bit, VP9 10bit**.
  Not AV1: 8th-gen Intel can't decode it.
- **Enable hardware encoding:** on. **Intel Low-Power encoders:** off.
- **Tone mapping:** on (for 4K HDR files shown on non-HDR screens).

**Prove it works:** play a movie and pick a lower quality in the player, which forces a
transcode. On the PC run `sudo intel_gpu_top`: the **Video** row should be busy, and
Dashboard → Activity shows the transcode. Test a 4K HDR file early; tone mapping is
the heaviest job.

## 4. Plex (main server, shared with friends and family)

Get a claim token at https://www.plex.tv/claim (valid 4 minutes), then:

```bash
PLEX_CLAIM=claim-xxxxxxxx ./stacks/up.sh plex
```

Open `http://mediabox.local:32400/web` and add libraries at `/media/movies` and
`/media/tv`. With Plex Pass: Settings → Transcoder → tick **Use hardware
acceleration when available** and **Use hardware-accelerated video encoding**, and
pick the Intel device. A hardware transcode shows as "(hw)" on the dashboard.

### Remote access for friends and family

This opens **one port to the internet: TCP 32400, to this PC only**. Nothing else on the
network is forwarded.

1. **Check for CGNAT.** Find the router's WAN/Internet IP (TP-Link: Network Map →
   Internet) and compare it with https://ifconfig.me opened from a device at home.
   **They must match.** If the router shows `100.64.x`–`100.127.x` or a private
   address (`10.x`, `172.16–31.x`, `192.168.x`), port forwarding can't work. Either the
   Xfinity gateway isn't in bridge mode ([Phase 1](02-network-router.md)) or the ISP is
   using CGNAT.
2. **Forward the port on the AX5400.** TP-Link: Advanced → NAT Forwarding → Virtual
   Servers → Add:

   | Field | Value |
   |---|---|
   | Service name | `Plex` |
   | External port | `32400` |
   | Internal IP | `192.168.77.20` |
   | Internal port | `32400` |
   | Protocol | TCP |

3. **Plex → Settings → Remote Access** (click *Show Advanced*):
   - **Enable** remote access.
   - Tick **Manually specify public port**: `32400`.
   - **Internet upload speed**: your measured upload. Run a speed test at home;
     Xfinity upload is far lower than download.
   - **Limit remote stream bitrate**: **8 Mbps (1080p)**. Each remote viewer then uses
     at most 8 Mbps, so 20 Mbps of upload serves about two at once.

   It should report **Fully accessible outside your network**. In Settings → Network,
   leave "List of IP addresses and networks that are allowed without auth" **empty**.
4. **Share:** Settings → **Manage Library Access** → **Grant Library Access**. Enter
   their Plex username or email and pick the libraries.
5. **Plex Pass on the owner's account** ($69.99/yr or $249.99 for 5 years). Every
   shared friend then streams remotely for free, and hardware (Quick Sync)
   transcoding is unlocked. With the 8 Mbps cap, most remote streams are transcodes.
6. **Secure the account and server:**
   - Turn on **two-factor authentication** for the Plex account (plex.tv → Account →
     Authentication).
   - Update the container promptly when a new Plex version is flagged:
     `./stacks/up.sh plex`. An unpatched, internet-facing Plex server was the way in
     for the 2022 LastPass breach.

**Undo:** delete the Virtual Server rule on the router and switch Remote Access off in
Plex. Household devices on Tailscale keep working either way.

**Media naming** (both servers): `movies/Movie Name (2019)/Movie Name (2019).mkv` and
`tv/Show Name/Season 01/Show Name S01E01.mkv`.

## 5. Immich (photos: the iCloud Photos replacement)

```bash
./stacks/immich/setup.sh               # downloads the official compose file and writes .env
cd stacks/immich && docker compose up -d
```

Photos go to `/srv/storage/photos/immich`, and the database lives on the boot SSD
(`/srv/appdata/immich/postgres`). Open `http://mediabox.local:2283` and create the
admin account. On your iPhone:

1. Install **Immich** from the App Store.
2. Server URL: `http://mediabox:2283`. This works at home and away while Tailscale is on.
3. Turn on **Backup** for the Camera Roll.

Face and object recognition run on the 8700K's CPU, which is plenty. The first
import of a big library takes a while; let it run overnight.

**Optional, Quick Sync for Immich's video conversions:** in
`stacks/immich/docker-compose.yml`, under `immich-server`, uncomment the three
`extends:` lines and set `service: quicksync`. Then run `docker compose up -d` and pick
Quick Sync in Administration → Settings → Video Transcoding.

**Keep iCloud running** until Immich has everything and you've tested a restore
from backup.

**Migrating your existing iCloud library** (chosen method):
1. Request a copy of your iCloud Photos at privacy.apple.com. Apple takes up to a
   week and delivers it in many zip parts.
2. Keep the downloaded zips untouched in `/srv/storage/shared/icloud-export/`.
   They're the archive of record.
3. Import with **immich-go** (v0.32 or newer, which supports Immich v3):
   `immich-go upload from-icloud --server=http://mediabox:2283 --api-key=<key> --memories <export folder>`.
   Create the API key in Immich → Account Settings → API Keys.
4. Compare counts, then spot-check Live Photos, videos, edited photos, albums, dates
   and locations before shrinking the iCloud plan.

## 6. File shares and Time Machine (Samba)

```bash
sudo apt install -y samba
sudo smbpasswd -a "$USER"                          # the password the Mac will use
sed "s/YOURUSER/$USER/g" config/samba/shares.conf | sudo tee -a /etc/samba/smb.conf >/dev/null
testparm -s >/dev/null && sudo systemctl restart smbd
```

- Finder → Go → Connect to Server → `smb://mediabox.local/shared`
- Time Machine: System Settings → General → Time Machine → Add Backup Disk →
  **timemachine**. Adjust the size cap in `config/samba/shares.conf` first
  (about 2× the Mac's used space).

## 7. Backups (don't skip)

| What | Where | Notes |
|---|---|---|
| Photos (`/srv/storage/photos`) | Backup drive **and** off-site | Irreplaceable. Immich also writes nightly database dumps into this folder, so they come along |
| App settings (`/srv/appdata`) | Backup drive **and** off-site | Plex/Jellyfin watch history, Immich database files, and every plex-server app (Seerr, Sonarr, Radarr, …), since they use `/srv/appdata/<app>` too |
| plex-server secrets (`~/plex-server/.env`) | Backup drive **and** off-site | VPN credentials and API keys. restic encrypts backups, so this is safe to include |
| Pi-hole settings | Media PC | Web admin → Settings → Teleporter → Export; save to the `shared` folder |
| Media library (`/srv/storage/data/media`) | Optional | Re-obtainable, so usually excluded |
| **Exclude:** `/srv/storage/data/torrents`, `/srv/storage/data/usenet` | — | In-progress downloads: large, constantly changing, re-downloadable |

**Chosen:** Backrest (web UI) + restic, backing up to `tank/backups` and to
**Backblaze B2** off-site. Step-by-step setup is Phase 8, step 5
([10-pro-layer.md](10-pro-layer.md)). Until it's running and a restore has been tested:
**don't delete anything from iCloud or your phone.**

## 8. Monitoring and dashboard

In **Uptime Kuma on the Pi** (`http://homepi:3001`), add HTTP monitors:

| Service | URL |
|---|---|
| Jellyfin | `http://192.168.77.20:8096/health` |
| Plex | `http://192.168.77.20:32400/identity` |
| Immich | `http://192.168.77.20:2283/api/server/ping` |
| Seerr (plex-server) | `http://192.168.77.20:5055/api/v1/status` |
| Sonarr (plex-server) | `http://192.168.77.20:8989/ping` |
| Radarr (plex-server) | `http://192.168.77.20:7878/ping` |
| Media PC up | Ping `192.168.77.20` |

**Portainer:** to manage this PC's containers from the Pi's Portainer, run
`./stacks/up.sh portainer-agent` here, then add it in Portainer straight away
(details in [06-docker-apps.md](06-docker-apps.md#optional-portainer-dashboard)).

## 9. Port map (shared with plex-server)

Every port in use on `mediabox`. Keep this table in sync with
[chris-suryo/plex-server](https://github.com/chris-suryo/plex-server) and check it before
adding a service.

| Port | Service | Repo |
|---|---|---|
| **32400/tcp** | Plex. **Forwarded from the internet (the only forwarded port)** | this one |
| 1900/udp, 8324, 32410–32414/udp, 32469 | Plex discovery/DLNA (host networking) | this one |
| 8096, 7359/udp | Jellyfin | this one |
| 2283 | Immich | this one |
| 445 | Samba (file shares, Time Machine) | this one |
| 9001 | Portainer agent | this one |
| 80, 443 · 9898 | Planned (Phase 8): Caddy · Backrest | this one |
| 5055 | Seerr (public only via Cloudflare Tunnel) | plex-server |
| 8989 · 7878 · 9696 · 6767 | Sonarr · Radarr · Prowlarr · Bazarr | plex-server |
| 8181 | Tautulli | plex-server |
| 8085 · 8080 | SABnzbd · qBittorrent (behind Gluetun) | plex-server |
