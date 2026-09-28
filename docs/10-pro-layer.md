# Phase 8: Run it like a small business

What separates "it works" from "it keeps working, and I'd know if it didn't":
redundancy, alerts, tested backups, clean access, written procedures. Tools were
chosen 2026-09-28 ([decisions.md](decisions.md)). Each item gets a step-by-step
section here when you reach it.

## Build order

The order matters more than the number of tools. Each step is proven before the
next one starts.

| # | Step | Where | Status |
|---|---|---|---|
| 1 | Router: bridge mode, AX5400 | Router | Guide ready ([02](02-network-router.md)) |
| 2 | Pi: OS, Pi-hole + Unbound, Tailscale, Uptime Kuma. **Do this while the drives ship and burn in** | Pi | Guides ready ([03](03-pi-prep-and-os.md)–[06](06-docker-apps.md)) |
| 3 | Media PC: hardware, Ubuntu 26.04, burn-in, **ZFS mirror + Sanoid snapshots + smartd** | PC | Guide and scripts ready ([07a](07a-hardware-walkthrough.md), [07](07-mediabox-setup.md)) |
| 4 | Jellyfin, Immich, Samba/Time Machine | PC | Guide ready ([08](08-mediabox-apps.md)) |
| 5 | **Backups:** Backrest + restic → local `tank/backups` and **Backblaze B2**; first restore test | PC | To write |
| 6 | **UPS:** CyberPower on USB to the PC (NUT server), Pi as NUT client; test by actually pulling the plug | Both | To write |
| 7 | **HTTPS names:** domain on Cloudflare, Caddy with a wildcard `*.home.<domain>` certificate, names in Pi-hole | Both | To write |
| 8 | **Monitoring:** Beszel metrics; ntfy alerts for SMART, ZFS, UPS, backups, disk space, service down; Diun update notices | Both | To write |
| 9 | **Home Assistant:** HA OS VM on the PC; Matter via HomePod mini; Nanoleaf, Google Home, Apple Home | PC | To write |
| 10 | Optional: single sign-on, guest/IoT Wi-Fi, metrics history | — | Later, maybe never |

## Standing rules

| Rule | In practice |
|---|---|
| **3-2-1 backups** | Photos exist on the ZFS mirror, in local restic backups, and in B2. Snapshots are not backups |
| **Restore drill** | Every quarter, restore a random folder from B2 and log the date in [decisions.md](decisions.md) |
| **One open port** | Only TCP 32400 → mediabox (Plex, for friends and family), on a 2FA-protected account with Plex kept updated. Seerr is reached through plex-server's Cloudflare Tunnel (no port). Everything else is Tailscale only |
| **Updates by hand** | OS security patches are automatic. Containers get updated monthly after Diun flags them and you've read the release notes. **Exception: Plex faces the internet, so update it within days of a release** |
| **Password manager + 2FA** | Every admin login in a password manager; 2FA on Tailscale, Cloudflare, Backblaze, GitHub and email |
| **Write it down** | Changes go in this repo: config in `stacks/` and `config/`, reasons in [decisions.md](decisions.md), fixes in [09](09-maintenance-troubleshooting.md) |
