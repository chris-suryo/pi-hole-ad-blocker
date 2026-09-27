# Hardware inventory and what it means for the server

The Pi comes from the TurboPi robot build. The values below were measured on
13–15 September 2026 while it was in the robot. The robot's full inventory
lives in that project's repo. This page keeps only what matters for server use.

## The Pi

| Item | Value | Server implication |
|---|---|---|
| Board | Raspberry Pi 5, **8 GB**, Rev 1.1 (bought open-box) | Plenty of headroom for Pi-hole + Tailscale + a few Docker apps, including Immich |
| Health | `throttled=0x0`, all sticky bits clear | Good. `scripts/verify.sh` re-checks this every run |
| Cooling | Official Active Cooler fitted | Keep it. 51–52 °C plateau under 120 s full load, no throttling |
| Bootloader | 2025-06-13 | Fine. The server OS will keep it updated (see "Going back to the robot") |
| OS on robot card | Raspberry Pi OS 64-bit, Debian 13 "Trixie" | **Don't reuse.** The server gets a fresh card |
| Storage | 128 GB microSD, the robot's card | **Stays with the robot, untouched** |

## Power: the one conclusion that changes

On the robot the Apple 20 W USB-C charger (5 V / 3 A) was measured rock solid:
9 mV sag from idle to full load. The robot notes concluded "you don't need
the 27 W official PSU." **That was right for the robot. It's wrong for a
storage server.**

- With a 3 A supply, the Pi 5 limits **all USB ports combined to 600 mA**.
- A bus-powered 2.5" hard drive or portable SSD can draw more than that, and
  more still when it spins up. The result is random disconnects and filesystem
  corruption.
- The official **27 W (5 V / 5 A) supply** raises the USB budget to 1.6 A.

| Plan | Apple 20 W OK? |
|---|---|
| Pi-hole, Unbound, Tailscale, Docker apps (Phases 1–5) | Yes |
| Drives with their own power adapter (3.5" desktop enclosures) | Yes |
| Bus-powered USB SSD/HDD, or an NVMe HAT | **No. Buy the 27 W PSU** |

`scripts/01-bootstrap.sh` and `scripts/verify.sh` read the negotiated limit
(`/proc/device-tree/chosen/power/max_current`: 3000 = 3 A, 5000 = 5 A) and warn
if it's low.

## Spares and parts from the robot build

| Part | Status | Decision |
|---|---|---|
| **Raspberry Pi RTC battery** (official, 2-pin JST) | Never fitted: the robot sandwich had to come apart | **Fit it now** (Phase 2). Keeps the clock right through power cuts, which DNSSEC needs |
| **52Pi aluminium case + fan** | Didn't fit the robot. Bought around 13 Sep, so the return window is probably closing | **Decide this week.** Keep it only if it fits a Pi 5 *with the Active Cooler* (and an M.2 HAT if you'll go NVMe). If it needs the cooler removed, return it |
| Spare black active cooler (4-wire JST) | Unused, lower spec than the fitted one | Keep as a spare |
| Apple 20 W PD (A2305) | Proven | Fine until you add bus-powered drives |

A case is optional. A Pi 5 with the Active Cooler is fine running bare on a
shelf, as long as nothing metal can touch the underside.

## Robot-only config that must not follow the Pi

None of this belongs on the server. Using a fresh card makes that automatic:

- `dtoverlay=uart0-pi5` (motor/servo UART at 1 Mbaud)
- `turbopi.service` and `turbopi-gateway.service`
- Open ports 8080 (MJPEG), 9030 (vendor JSON-RPC), 9031 (gateway)
- The gateway token and `~/turbopi-venv`, `~/gateway-venv`

## Going back to the robot later

1. `sudo shutdown -h now`, then swap in the robot's 128 GB card and remount the Pi.
2. The server OS keeps the bootloader **EEPROM** updated, and that EEPROM stays with
   the board. The robot already uses the post-change UART method
   (`dtoverlay=uart0-pi5`), so a newer bootloader should be fine. If the motors
   don't respond after the swap, check the UART first.
3. The network will be different after Phase 1: the robot's old `10.0.0.x`
   address no longer exists. Give it a new DHCP reservation on the AX5400 and
   update the robot docs.

## Shopping list

| Item | Why | Needed by |
|---|---|---|
| microSD, 32–64 GB, A2 rated (e.g. SanDisk Extreme / Samsung PRO Plus) | Server OS; the robot card stays untouched | Phase 2 |
| Ethernet cable, router to Pi | A DNS server should be wired | Phase 2 |
| Official Raspberry Pi 27 W USB-C PSU | USB power budget for drives | Phase 6 (only for bus-powered drives) |
| Storage drive(s) | Media and photos | Phase 6: **decide after research** (docs/07) |
