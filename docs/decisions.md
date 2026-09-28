# Decision log

Why things are the way they are. Newest first. Add an entry whenever a choice
changes, so future you (or anyone helping) doesn't have to reverse-engineer it.

## 2026-09-28: Drives chosen

Prices as of 2026-09-28.

| Area | Decision | Why / notes |
|---|---|---|
| Data drives | **2× WD Ultrastar HC560 20 TB, SATA, recertified**, from **goHardDrive** at **$499.95 each** (~$1,000 total), with a **5-year seller warranty**. Mirrored: **20 TB usable** | Lowest price per TB of the options priced that day ($25.00/TB). The model number must contain **LE6** (SATA, e.g. WUH722020BLE6…), **not L5** (SAS). Supersedes the $400–470 target in the research entry below |
| Power adapters | **2× crimped (not molded) Molex-to-SATA power adapters**, in the same order | The CX650M may send 3.3 V on pin 3, which keeps these drives from spinning up. The fix is in [07a troubleshooting](07a-hardware-walkthrough.md#troubleshooting). Molex carries no 3.3 V. Crimped, because molded adapters are a known melting risk |

**Alternatives considered** (per drive; a mirror needs two identical drives):

| Option | Price | $/TB | Why not |
|---|---|---|---|
| Seagate Exos 22 TB, recertified, goHardDrive | $599.95 | $27.27 | 22 TB usable, but $200 more for the pair |
| Seagate IronWolf Pro 20 TB, **new**, Micro Center | $569.99 | $28.50 | New, and no power-disable issue, but ~$140 more for the pair |
| ServerPartDeals Exos 22 TB | $649 | $29.50 | 3-year warranty; worse value (~$300 more for the pair) |
| Marketplace listings | $800+ | — | Avoid |

## 2026-09-28: plex-server joins; Plex becomes the shared server

| Area | Decision | Why / notes |
|---|---|---|
| Split of repos | **This repo:** platform (Pi, router, media PC OS/ZFS) plus Plex/Jellyfin. **[chris-suryo/plex-server](https://github.com/chris-suryo/plex-server):** media automation (Seerr, Sonarr, Radarr, Prowlarr, Bazarr, Recyclarr, Tautulli, SABnzbd / qBittorrent + Gluetun, Unpackerr, Cloudflare Tunnel for Seerr only) | Supersedes "torrent automation out of scope" |
| Shared contract | mediabox `192.168.77.20`; PUID/PGID 1000; app data `/srv/appdata/<app>`; media + downloads in `/srv/storage/data/{media/{movies,tv},torrents,usenet}`; plex-server owns ports 5055, 8989, 7878, 9696, 6767, 8181, 8085, 8080 | Port map: [08 §9](08-mediabox-apps.md#9-port-map-shared-with-plex-server). Change either side only together with the other |
| Storage | ZFS dataset `media` replaced by **`data`** (media + downloads in one dataset); `MEDIA_DIR=/srv/storage/data/media` | Hardlinks can't cross datasets. `data` keeps the default 128K recordsize (torrent writes) and **3 daily snapshots** (undo a mistaken delete without hoarding download churn) |
| Media server | **Plex with Plex Pass** is primary; Jellyfin optional | Friends and family outside the tailnet stream via Plex; the owner's Plex Pass covers them and unlocks Quick Sync. Supersedes "Jellyfin primary" below |
| Remote access | **TCP 32400 → 192.168.77.20 forwarded**: the only open port. Remote bitrate capped at 8 Mbps (1080p); 2FA on the Plex account; Plex updated promptly | Supersedes "no open ports". Seerr uses a Cloudflare Tunnel (outbound only) |
| Backups | Add `~/plex-server/.env`; exclude `/srv/storage/data/{torrents,usenet}` | `/srv/appdata` already covers the plex-server apps |

## 2026-09-28: Research results applied

Source: the [research brief](research-brief.md), run through an external research
LLM on 2026-09-27, then reviewed here. Corrections from that review are marked ✱.

| Area | Decision | Why / notes |
|---|---|---|
| Data drives | **2× identical 20–22 TB SATA CMR enterprise drives, recertified**, from a seller with a **2–5 year warranty** (ServerPartDeals, goHardDrive). Target about $400–470 each | Recertified enterprise drives cost roughly $18–24/TB; new NAS-branded drives cost much more. ✱ 22 TB Ultrastar = **HC570** (HC560 = 20 TB, HC580 = 24 TB). ✱ **Avoid HC6xx** (host-managed SMR). ✱ The listing must say **SATA**, not SAS. ✱ Cheap "renewed" marketplace listings often carry only a 90-day warranty |
| Burn-in | Every drive is fully write/read-tested before use ([script](../scripts/mediabox/02-burn-in.sh)) | About 4 days for 20 TB. Recertified drives earn trust by passing, not by label |
| Third drive | **No**, for now. Off-site backup protects more. Add a cold/offline drive later | |
| Layout | **ZFS mirror** `tank`, datasets `media`, `photos`, `shared`, `timemachine`, `backups`, mounted under `/srv/storage` | Checksums, scrubs, snapshots, simple recovery from a failed drive. Grow later by adding a second mirrored pair. ✱ **App data stays on the NVMe** (database speed), backed up nightly into `tank/backups` |
| Snapshots | **Sanoid**: photos/shared/backups 24 hourly, 14 daily, 3 monthly; media 7 daily; Time Machine none (it versions itself) | Ubuntu's `zfsutils-linux` already scrubs monthly |
| Boot SSD | 1 TB TLC NVMe | |
| OS | **Ubuntu Server 26.04 LTS** + Docker Compose, bare metal | Current LTS. Proxmox and TrueNAS add a layer this setup doesn't need |
| UPS | **CyberPower CP1500PFCLCD** (pure sine, 1000 W) | USB to the media PC, which runs the NUT server; the Pi runs a NUT client. PC, Pi, router and modem all on battery outlets |
| HTTPS names | **Caddy** + a domain on **Cloudflare Registrar**, DNS-01 certificates, one wildcard `*.home.<domain>`. Names resolve only via Pi-hole (LAN and tailnet) | No open ports. A wildcard keeps individual service names out of public certificate logs. Caddy needs a build that includes the Cloudflare DNS module |
| Single sign-on | **None** for now | Every app has its own login, and access is LAN/tailnet only. Revisit with Pocket ID if wanted |
| Monitoring | Uptime Kuma + **Beszel** + smartd + NUT + ZFS health, all alerting via **ntfy** | Not Prometheus/Grafana; that becomes a hobby of its own |
| Updates | **Diun** notifies; updates are applied by hand after reading release notes | No auto-updaters |
| Backups | **Backrest + restic** → **Backblaze B2** (~$6.95/TB/month; restores normally free) | A relative's-house Pi can be a 4th copy later |
| Home Assistant | **HA OS in a VM on the media PC** (KVM/libvirt on Ubuntu) | Matter Server is only supported on HA OS. HA Green (~$100 appliance) is the no-maintenance alternative. No radio stick: the HomePod mini is the Thread border router |
| Media server | **Jellyfin**; Plex only if a device or friend needs it | Free Quick Sync, free remote over Tailscale. Plex treats Tailscale as remote (paid) |
| Photo migration | Apple privacy export (kept untouched as the archive) → **immich-go** `from-icloud` → Immich v3; validate before shrinking iCloud | |
| Router | TP-Link Archer (✱ **model to confirm**; the research assumed AXE75). DHCP DNS = Pi only; check IPv6 DNS advertisements; use guest-network isolation carefully (it can break Matter/HomeKit discovery) | |
| Build order | ✱ Router → **Pi (while drives ship and burn in)** → media PC → backups → UPS → HTTPS → monitoring → Home Assistant | The research put the Pi later. Doing it during the drives' 4-day burn-in costs nothing |

## 2026-09-27: Two machines

The Pi can't transcode video, so media and storage go to the old i7-8700K PC with
Quick Sync. DNS stays on the Pi so the internet survives PC reboots. The GTX 1070 Ti
is removed. Torrent automation is out of scope.
