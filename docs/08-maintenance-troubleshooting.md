# Maintenance and troubleshooting

## Routine

| When | What | Command |
|---|---|---|
| Automatic | Debian security updates | unattended-upgrades (set up in Phase 2) |
| Automatic | Blocklist refresh | Pi-hole updates gravity weekly by itself |
| Monthly | OS updates | `sudo apt update && sudo apt full-upgrade`, then `sudo reboot` if the kernel changed |
| Monthly | Pi-hole | `pihole -up` |
| Monthly | Apps | `./stacks/up.sh <name>` for each; for Immich: `cd stacks/immich && docker compose pull && docker compose up -d` (read Immich's release notes first; it has breaking changes) |
| Monthly | Health | `./scripts/verify.sh` |
| After big changes | Pi-hole backup | Web admin → Settings → Teleporter → Export (or `pihole-FTL --teleporter`), then save the zip to the Mac |
| Occasionally | Kit updates | `cd ~/homepi && git pull` |

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| **Nothing loads for anyone, but Wi-Fi is connected** | Pi off/crashed, so no DNS | Quick: router DHCP DNS back to automatic, toggle Wi-Fi. Then: is the Pi on? `ssh`, then `pihole status`, then `sudo systemctl restart pihole-FTL unbound` |
| One site or app broken | Something it needs is blocked | Query Log → filter by that device → **Allow** the blocked domain. Or `pihole disable 5m` to confirm it's Pi-hole |
| A device never appears in Pi-hole | It bypasses Pi-hole: IPv6 DNS, browser DoH, Private DNS, hardcoded DNS | See the leak table in [04-pihole-unbound.md](04-pihole-unbound.md#devices-that-sneak-around-pi-hole) |
| Everything SERVFAILs after a power cut | Clock wrong, so DNSSEC fails | `timedatectl`; fit/charge the RTC battery (Phase 2). Short term: `sudo systemctl restart systemd-timesyncd unbound` |
| Unbound script: "can't query a.root-servers.net" | ISP/router intercepting DNS | Skip Unbound and keep Pi-hole on a normal upstream like Quad9. Re-test after bridge mode, because the Xfinity gateway itself is a usual suspect |
| `verify.sh`: throttled not `0x0` | Under-voltage | Better PSU/cable; unplug bus-powered drives |
| Drive missing after reboot | USB power or loose cable (boot continues because of `nofail`) | `lsblk`, `dmesg -T \| tail`; self-powered enclosure or 27 W PSU |
| Container keeps restarting | Bad config or permissions | `docker logs <name>`; check `/srv/appdata/<name>` is owned by you |
| Phone away from home: no internet with Tailscale on | Pi down + "Override DNS servers" | Turn Tailscale off on the phone; fix the Pi |

## Going back to the robot

See [01-hardware-inventory.md](01-hardware-inventory.md#going-back-to-the-robot-later).
Before pulling the Pi, set the router's DHCP DNS back to automatic, or the house
loses DNS when the Pi leaves.
