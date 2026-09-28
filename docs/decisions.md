# Decision log

Why things are the way they are. Newest first. Add an entry whenever a choice
changes, so future you (or anyone helping) doesn't have to reverse-engineer it.

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
