# Phase 8: Run it like a small business

**Status: plan.** Details get finalized after the [research brief](research-brief.md)
comes back. This is what separates "it works" from "it keeps working, and I'd know
if it didn't": redundancy, alerts, tested backups, clean access, written procedures.
Ordered by value for effort.

## Tier 1: with the hardware (Phases 6–7)

| Practice | What it means here | Why |
|---|---|---|
| **Mirrored storage with snapshots** | The two drives as a ZFS mirror; automatic hourly/daily snapshots | A dead drive means no downtime and no data loss. An accidental delete is undone from a snapshot. ZFS also detects silent corruption |
| **Battery backup + clean shutdown** | UPS on PC, Pi, router and modem. NUT software shuts the PC down cleanly when the battery runs low | Power cuts are the #1 cause of corrupted home servers |
| **Backups that follow 3-2-1** | Nightly encrypted backup of photos, app data and configs to an off-site target (restic) | The mirror protects against a dead drive; only a backup protects against fire, theft, ransomware or "I deleted the folder a month ago" |
| **Restore drill** | Restore a random folder from backup every quarter; note the date in this repo | An untested backup is a hope, not a backup |
| **Alerts to your phone** | ntfy push for: service down (Uptime Kuma), drive health (SMART), UPS on battery, backup failed, disk > 85% | Problems get fixed when they're small |

## Tier 2: once everything runs

| Practice | What it means here | Why |
|---|---|---|
| **Real names with HTTPS** | A cheap domain (≈$10–15/yr). A reverse proxy on the PC gives `jellyfin.yourdomain.com`, `photos.yourdomain.com`, etc., with real certificates. Names resolve only at home (Pi-hole) and on Tailscale, never on the public internet | No more IP:port, no browser warnings, and apps that need HTTPS just work |
| **Password manager + 2FA** | Every admin password (router, Pi-hole, Portainer, apps) in a password manager; 2FA on Tailscale, GitHub, Plex and your email | The accounts that control everything are the real attack surface |
| **Update discipline** | OS security updates stay automatic. Container updates are announced (not auto-applied) and done monthly after reading release notes | Nothing silently breaks overnight |
| **Runbook** | This repo: what runs where, how to restore, what to do when X breaks ([09-maintenance-troubleshooting.md](09-maintenance-troubleshooting.md)) | Future you, or whoever helps you, can fix it without guessing |

## Tier 3: optional polish

- **Single sign-on:** one login for all web apps.
- **Separate network for smart-home gadgets:** a guest/IoT Wi-Fi, if the AX5400 supports it.
- **Metrics dashboard:** CPU, disk and temperature history for both machines.
