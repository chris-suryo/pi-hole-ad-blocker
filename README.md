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

> **Status:** kit written; nothing installed yet. Work through the phases in order.
> Drive sizes and backups need decisions first; see [research questions](docs/research-questions.md).

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
 ├─ Unbound     :5335 (local)          ├─ Plex      :32400  ┘ transcoding
 ├─ Tailscale   subnet + exit node     ├─ Immich    :2283   photos
 └─ Docker                             ├─ Samba             shares + Time Machine
     ├─ Uptime Kuma    :3001           ├─ Tailscale
     ├─ Portainer      :9443 (opt.)    └─ /srv/storage      data drive(s)
     └─ Home Assistant :8123 (opt.)
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
| 6 | Media PC: hardware, BIOS, Ubuntu Server, drives | PC | [07-mediabox-setup](docs/07-mediabox-setup.md) | 2–3 h |
| 7 | Jellyfin/Plex, Immich, Samba, backups | PC | [08-mediabox-apps](docs/08-mediabox-apps.md) | varies |
| — | Routine care and fixes | Both | [09-maintenance-troubleshooting](docs/09-maintenance-troubleshooting.md) | — |

Phases 1–5 don't depend on the PC, and 6–7 only need Phase 1. `./scripts/verify.sh`
checks whatever is installed on the machine it runs on.

## Before you start

**Answer** (these change the instructions):
1. Exact AX5400 model from the sticker (TP-Link / ASUS / Netgear menus differ; Netgear can't hand out a custom DNS server).
2. Does the PC's case have 3.5" drive bays, and are you OK leaving it on 24/7? (Roughly $40–70/yr in electricity with the GTX 1070 Ti removed, depending on your rate.)
3. Any smart-home devices? That decides whether Home Assistant is worth setting up.
4. The storage questions in [research-questions.md](docs/research-questions.md). Needed for Phases 6–7.

**Buy or gather:**
- [ ] **New microSD**, 32–64 GB, A2, for the Pi. The robot's 128 GB card stays untouched.
- [ ] **2 Ethernet cables**: router to Pi, router to PC.
- [ ] **52Pi case: keep or return this week.** It was bought around 13 Sep ([details](docs/01-hardware-inventory.md#spares-and-parts-from-the-robot-build)).
- [ ] For the PC: **NVMe boot SSD** (500 GB–1 TB), a **USB stick**, and **hard drive(s)**, sized after research.

The Pi stays on the Apple 20 W charger. No drives hang off it, so the 27 W PSU isn't needed.

## Layout

```
docs/               phase guides, hardware inventory, research questions
scripts/            Pi scripts, run in order; 05-install-docker.sh and verify.sh work on both machines
scripts/mediabox/   media PC scripts
config/             Unbound (Pi) and Samba (PC) config
stacks/             Docker apps: ./stacks/up.sh <name>; Immich: stacks/immich/setup.sh
```

## Conventions

- Addresses: LAN `192.168.77.0/24`, router `.1`, Pi `.53` (`homepi`), PC `.20` (`mediabox`).
  Substitute yours if you choose differently in Phase 1.
- The kit is cloned to `~/homelab` on each machine. Scripts run as your normal user and `sudo` when needed.
- **This repo is public.** No passwords, keys, tokens or `.env` files go in it
  (`.gitignore` covers the generated ones). App data lives in `/srv/appdata`, outside the checkout.
- **Not included:** torrent/download automation (qBittorrent, Sonarr, Radarr).
