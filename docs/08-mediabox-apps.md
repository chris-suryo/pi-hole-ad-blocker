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
| Sharing with friends (e.g. Paul) | Share the `mediabox` machine to their tailnet, or give them an account over a public URL | Built in, with the remote-viewing fee above |

**Decision: Jellyfin** ([decisions.md](decisions.md)). Add Plex alongside it only if
a TV has a clearly better Plex app, or to share with a friend who won't use
Tailscale. Both read the same media folder (read-only), so adding Plex later
costs nothing. Note that Plex counts viewing over Tailscale as remote, which is paid.

## 3. Jellyfin

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

## 4. Plex (alongside or instead)

Get a claim token at https://www.plex.tv/claim (valid 4 minutes), then:

```bash
PLEX_CLAIM=claim-xxxxxxxx ./stacks/up.sh plex
```

Open `http://mediabox.local:32400/web` and add libraries at `/media/movies` and
`/media/tv`. With Plex Pass: Settings → Transcoder → tick **Use hardware
acceleration when available** and **Use hardware-accelerated video encoding**, and
pick the Intel device. A hardware transcode shows as "(hw)" on the dashboard.

**Remote Access:** leave it off. Tailscale covers you. Only turn it on (it opens port
32400 to the internet) if you'll share with people who aren't on your tailnet.

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
| App settings (`/srv/appdata`) | Backup drive | Plex/Jellyfin watch history, Immich database files |
| Pi-hole settings | Media PC | Web admin → Settings → Teleporter → Export; save to the `shared` folder |
| Media library | Optional | Re-obtainable, so usually excluded |

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
| Media PC up | Ping `192.168.77.20` |

**Portainer:** to manage this PC's containers from the Pi's Portainer, run
`./stacks/up.sh portainer-agent` here, then add it in Portainer straight away
(details in [06-docker-apps.md](06-docker-apps.md#optional-portainer-dashboard)).
