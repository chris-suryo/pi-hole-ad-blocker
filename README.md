# homepi: Raspberry Pi 5 home server kit

Step-by-step kit for turning a Raspberry Pi 5 into an always-on home server:

- **Network-wide ad and tracker blocking:** Pi-hole + Unbound (private DNS)
- **Secure remote access:** Tailscale (reach home from anywhere, ad-blocking on cellular)
- **Monitoring:** Uptime Kuma
- **Later:** a media server (Jellyfin or Plex), photo backup to replace iCloud
  (Immich), and file shares/Time Machine

> **Status:** kit written; nothing installed yet. Work through the phases in order.
> Phase 6 (storage) needs decisions first; see [research questions](docs/research-questions.md).

## What ends up running

```
Internet
   │
Xfinity gateway ── bridge mode: modem only
   │
AX5400 router ──── Wi-Fi + DHCP; tells every device "use the Pi for DNS"
   │ Ethernet
Raspberry Pi 5 "homepi" (192.168.77.53)
   ├── Pi-hole     :53, :80/admin   blocks ad/tracker domains for the whole house
   ├── Unbound     :5335 (local)    resolves privately, checks DNSSEC
   ├── Tailscale                    home network + ad-blocking from anywhere
   └── Docker
        ├── Uptime Kuma  :3001      alerts when something's down
        ├── Jellyfin     :8096      movies/TV (or Plex :32400)     ┐ Phase 6,
        └── Immich       :2283      iCloud Photos replacement      ┘ needs a drive
```

## Phases

| # | Phase | Guide | Time |
|---|---|---|---|
| 0 | Decisions and shopping | [below](#before-you-start) | — |
| 1 | Xfinity gateway to bridge mode, AX5400 as router | [02-network-router](docs/02-network-router.md) | 45–60 min |
| 2 | Move the Pi off the robot, fresh OS, fixed address, bootstrap | [03-pi-prep-and-os](docs/03-pi-prep-and-os.md) | ~1 h |
| 3 | Pi-hole + Unbound, then point the router at it | [04-pihole-unbound](docs/04-pihole-unbound.md) | ~30 min |
| 4 | Tailscale: subnet router, exit node, Pi-hole everywhere | [05-tailscale](docs/05-tailscale.md) | ~20 min |
| 5 | Docker + Uptime Kuma | [06-docker-apps](docs/06-docker-apps.md) | ~15 min |
| 6 | Storage, Jellyfin/Plex, Immich, Samba, backups | [07-storage-media-photos](docs/07-storage-media-photos.md) | varies |
| — | Routine care and fixes | [08-maintenance-troubleshooting](docs/08-maintenance-troubleshooting.md) | — |

Each phase ends with checks and a rollback. `./scripts/verify.sh` checks everything
installed so far and skips the rest.

## Before you start

**Answer** (these change the instructions):
1. Exact AX5400 model from the sticker (TP-Link / ASUS / Netgear menus differ; Netgear can't hand out a custom DNS server).
2. Can the Pi sit next to the router on Ethernet?
3. The storage/media questions in [research-questions.md](docs/research-questions.md). Needed for Phase 6 only.

**Buy or gather:**
- [ ] **New microSD**, 32–64 GB, A2. The robot's 128 GB card stays untouched.
- [ ] **Ethernet cable**, router to Pi.
- [ ] **52Pi case: keep or return this week.** It was bought around 13 Sep ([details](docs/01-hardware-inventory.md#spares-and-parts-from-the-robot-build)).
- [ ] Later, only for bus-powered drives: **official 27 W PSU**. The Apple 20 W caps USB at 600 mA ([why](docs/01-hardware-inventory.md#power-the-one-conclusion-that-changes)).

## Layout

```
docs/          phase guides, hardware inventory, research questions
scripts/       run on the Pi, in order; safe to re-run; verify.sh = health check
config/        Unbound and Samba config used by the scripts/guides
stacks/        Docker apps: ./stacks/up.sh <name>; Immich: stacks/immich/setup.sh
```

## Conventions

- Example addresses: LAN `192.168.77.0/24`, router `.1`, Pi `.53`, hostname `homepi`.
  Substitute yours if you choose differently in Phase 1.
- Scripts run **on the Pi as your normal user** from `~/homepi`; they `sudo` when needed.
- **This repo is public.** No passwords, keys, tokens or `.env` files go in it
  (`.gitignore` covers the generated ones). App data lives in `/srv/appdata`, outside the checkout.
