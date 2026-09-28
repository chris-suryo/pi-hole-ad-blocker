# homelab: Raspberry Pi 5 + media PC

Step-by-step kit for a small home setup built from two machines you already own:

- **Raspberry Pi 5 (`homepi`), the always-on network box:** network-wide ad and
  tracker blocking (Pi-hole + Unbound), secure remote access (Tailscale),
  monitoring (Uptime Kuma), and optionally Portainer and Home Assistant.
- **Old i7-8700K PC (`mediabox`), the media and storage box:** Jellyfin and/or Plex
  with Intel Quick Sync hardware transcoding, Immich to replace iCloud Photos, Mac
  file shares and Time Machine, and backups.

DNS stays on the low-power Pi, so the internet keeps working when the PC reboots.
The heavy work (video, photos, drives) goes to the PC.

> **Status:** decisions made ([decisions.md](docs/decisions.md)), parts to order, nothing installed yet.
> Build order and what's left to write: [10-pro-layer.md](docs/10-pro-layer.md#build-order).

## What ends up running

```
Internet
   │
Xfinity gateway ─── bridge mode: modem only
   │
AX5400 router ───── Wi-Fi + DHCP; tells every device "use the Pi for DNS"
   │ Ethernet                           │ Ethernet
   ▼                                    ▼
homepi  Raspberry Pi 5 (.53)          mediabox  i7-8700K PC (.20)
 ├─ Pi-hole     :53, /admin            ├─ Jellyfin  :8096   ┐ Quick Sync
 ├─ Unbound     :5335 (local)          ├─ Plex      :32400  ┘ transcoding (Plex optional)
 ├─ Tailscale   subnet + exit node     ├─ Immich    :2283   photos
 └─ Docker                             ├─ Samba             shares + Time Machine
     ├─ Uptime Kuma    :3001           ├─ Tailscale
     ├─ Portainer      :9443 (opt.)    └─ ZFS mirror "tank" 2× 20 TB → /srv/storage
     └─ (Home Assistant → VM on the PC, Phase 8)
```

## Phases

| # | Phase | Machine | Guide | Time |
|---|---|---|---|---|
| 0 | Decisions and shopping | — | [below](#before-you-start) | — |
| 1 | Xfinity gateway to bridge mode, AX5400 as router | Router | [02-network-router](docs/02-network-router.md) | 45–60 min |
| 2 | Move the Pi off the robot, fresh OS, fixed address | Pi | [03-pi-prep-and-os](docs/03-pi-prep-and-os.md) | ~1 h |
| 3 | Pi-hole + Unbound, then point the router at it | Pi | [04-pihole-unbound](docs/04-pihole-unbound.md) | ~30 min |
| 4 | Tailscale: subnet router, exit node, Pi-hole everywhere | Pi | [05-tailscale](docs/05-tailscale.md) | ~20 min |
| 5 | Docker + Uptime Kuma (+ optional Portainer, Home Assistant) | Pi | [06-docker-apps](docs/06-docker-apps.md) | ~15 min |
| 6 | Media PC: GPU out, SSD and drives in ([walkthrough](docs/07a-hardware-walkthrough.md)), BIOS, Ubuntu Server | PC | [07-mediabox-setup](docs/07-mediabox-setup.md) | 3–4 h |
| 7 | Jellyfin/Plex, Immich, Samba, backups | PC | [08-mediabox-apps](docs/08-mediabox-apps.md) | varies |
| 8 | Run it like a small business: backups to B2, UPS, HTTPS names, monitoring, Home Assistant VM | Both | [10-pro-layer](docs/10-pro-layer.md) | ongoing |
| — | Routine care and fixes | Both | [09-maintenance-troubleshooting](docs/09-maintenance-troubleshooting.md) | — |

Phases 1–5 don't depend on the PC, and 6–7 only need Phase 1. `./scripts/verify.sh`
checks whatever is installed on the machine it runs on.

## Before you start

**Decided** ([decisions.md](docs/decisions.md)):
- PC runs 24/7, out of the way: Ubuntu Server 26.04, a ZFS mirror of two 20–22 TB drives, Jellyfin, Immich.
- Backups to Backblaze B2. CyberPower UPS.
- HTTPS names via Caddy + Cloudflare.
- Home Assistant as a VM on the PC.

**Still open:** confirm the router model on its sticker (the research assumed a TP-Link Archer AXE75).

**Order now** (models and buying checks: [shopping list](docs/01-hardware-inventory.md#shopping-list)):
- [ ] **2 identical 20–22 TB hard drives**: SATA (not SAS), CMR, recertified enterprise with a 2–5 year warranty.
- [ ] **1 TB NVMe SSD** (TLC) and a **USB stick**.
- [ ] **UPS:** CyberPower CP1500PFCLCD.
- [ ] **microSD**, 32–64 GB A2, for the Pi, and **2 Ethernet cables**.
- [ ] **52Pi case: keep or return this week** ([details](docs/01-hardware-inventory.md#spares-and-parts-from-the-robot-build)).

**While parts ship:** do Phases 1–5 (router and Pi). They need only the microSD and a cable.

## Layout

```
docs/               phase guides, hardware walkthrough, shopping list, decisions, research brief
scripts/            Pi scripts, run in order; 05-install-docker.sh and verify.sh work on both machines
scripts/mediabox/   media PC scripts: bootstrap, drive burn-in, ZFS pool
config/             Unbound (Pi); Samba, Sanoid, smartd (PC)
stacks/             Docker apps: ./stacks/up.sh <name>; Immich: stacks/immich/setup.sh
```

## Conventions

- Addresses: LAN `192.168.77.0/24`, router `.1`, Pi `.53` (`homepi`), PC `.20` (`mediabox`).
  Substitute yours if you choose differently in Phase 1.
- The kit is cloned to `~/homelab` on each machine. Scripts run as your normal user and `sudo` when needed.
- **This repo is public.** No passwords, keys, tokens or `.env` files go in it
  (`.gitignore` covers the generated ones). App data lives in `/srv/appdata`, outside the checkout.
- **Not included:** torrent/download automation (qBittorrent, Sonarr, Radarr).
