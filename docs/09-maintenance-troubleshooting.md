# Maintenance and troubleshooting

## Routine

| When | Machine | What | Command |
|---|---|---|---|
| Automatic | Both | Security updates | unattended-upgrades (set up by the bootstrap scripts) |
| Automatic | Pi | Blocklist refresh | Pi-hole updates gravity weekly by itself |
| Monthly | Both | OS updates | `sudo apt update && sudo apt full-upgrade`, then `sudo reboot` if the kernel changed. Reboot the PC first, then the Pi, so DNS is only down briefly |
| Monthly | Pi | Pi-hole | `pihole -up` |
| Monthly | Both | Apps | `./stacks/up.sh <name>` for each |
| Monthly | PC | Immich | Read Immich's release notes first (it has breaking changes), then `cd stacks/immich && docker compose pull && docker compose up -d` |
| Monthly | Both | Health | `./scripts/verify.sh`, including SMART disk health on the PC |
| After big changes | Pi | Pi-hole backup | Web admin → Settings → Teleporter → Export, then save the zip to the PC's `shared` folder |
| Occasionally | Both | Kit updates | `cd ~/homelab && git pull` |

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| **Nothing loads for anyone, but Wi-Fi is connected** | Pi off/crashed, so no DNS | Quick: router DHCP DNS back to automatic, toggle Wi-Fi. Then: is the Pi on? `ssh`, then `pihole status`, then `sudo systemctl restart pihole-FTL unbound` |
| One site or app broken | Something it needs is blocked | Query Log → filter by that device → **Allow** the blocked domain. Or `pihole disable 5m` to confirm it's Pi-hole |
| A device never appears in Pi-hole | It bypasses Pi-hole: IPv6 DNS, browser DoH, Private DNS, hardcoded DNS | See the leak table in [04-pihole-unbound.md](04-pihole-unbound.md#devices-that-sneak-around-pi-hole) |
| Everything SERVFAILs after a power cut | Clock wrong, so DNSSEC fails | `timedatectl`; fit/charge the RTC battery (Phase 2). Short term: `sudo systemctl restart systemd-timesyncd unbound` |
| Unbound script: "can't query a.root-servers.net" | ISP/router intercepting DNS | Skip Unbound and keep Pi-hole on a normal upstream like Quad9. Re-test after bridge mode, because the Xfinity gateway itself is a usual suspect |
| `verify.sh`: throttled not `0x0` | Under-voltage | Better PSU/cable; unplug bus-powered drives |
| Data drive missing after reboot (media PC) | Loose SATA data/power cable, or a failing drive (boot continues because of `nofail`) | `lsblk`, `dmesg -T \| tail`, `sudo smartctl -H /dev/sdX`; reseat cables |
| Container keeps restarting | Bad config or permissions | `docker logs <name>`; check `/srv/appdata/<name>` is owned by you |
| Phone away from home: no internet with Tailscale on | Pi down + "Override DNS servers" | Turn Tailscale off on the phone; fix the Pi |
| Jellyfin/Plex stutters, and `intel_gpu_top` shows the Video row idle | Transcoding in software | Check hardware acceleration is set (docs/08); `verify.sh` should find the Intel render node; BIOS iGPU enabled |
| Jellyfin container won't start: "RENDER_GID is missing" | `stacks/.env` not filled in | `getent group render \| cut -d: -f3`, put it in `RENDER_GID=` |
| `verify.sh`: SMART FAILED | Drive dying | Make sure the backup is current, then replace the drive |
| PC didn't come back after a power cut | BIOS setting | Restore AC Power Loss → Power On (docs/07, step A4) |

## Going back to the robot

See [01-hardware-inventory.md](01-hardware-inventory.md#going-back-to-the-robot-later).
Before pulling the Pi, set the router's DHCP DNS back to automatic, or the house
loses DNS when the Pi leaves.
