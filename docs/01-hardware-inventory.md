# Hardware inventory and what it means for the server

The Pi comes from the TurboPi robot build. The values below were measured on
13–15 September 2026 while it was in the robot. The robot's full inventory
lives in that project's repo. This page keeps only what matters for server use.

## The Pi

| Item | Value | Server implication |
|---|---|---|
| Board | Raspberry Pi 5, **8 GB**, Rev 1.1 (bought open-box) | Plenty for Pi-hole, Unbound, Tailscale, Uptime Kuma, Portainer and Home Assistant |
| Health | `throttled=0x0`, all sticky bits clear | Good. `scripts/verify.sh` re-checks this every run |
| Cooling | Official Active Cooler fitted | Keep it. 51–52 °C plateau under 120 s full load, no throttling |
| Bootloader | 2025-06-13 | Fine. The server OS will keep it updated (see "Going back to the robot") |
| OS on robot card | Raspberry Pi OS 64-bit, Debian 13 "Trixie" | **Don't reuse.** The server gets a fresh card |
| Storage | 128 GB microSD, the robot's card | **Stays with the robot, untouched** |

## Power

On the robot, the Apple 20 W USB-C charger (5 V / 3 A) was measured rock solid:
9 mV sag from idle to full load. **It stays the Pi's supply.** With a 3 A supply the
Pi 5 limits all USB ports combined to 600 mA, but that only matters for drives
powered from the Pi's USB. The drives now live in the media PC
([07-mediabox-setup.md](07-mediabox-setup.md)), so the official 27 W PSU isn't needed.

`scripts/verify.sh` still reports the negotiated limit
(`/proc/device-tree/chosen/power/max_current`: 3000 = 3 A, 5000 = 5 A). A warning
at 3000 mA is expected and harmless unless you plug a drive into the Pi.

## Spares and parts from the robot build

| Part | Status | Decision |
|---|---|---|
| **Raspberry Pi RTC battery** (official, 2-pin JST) | Never fitted: the robot sandwich had to come apart | **Fit it now** (Phase 2). Keeps the clock right through power cuts, which DNSSEC needs |
| **52Pi aluminium case + fan** | Didn't fit the robot. Bought around 13 Sep, so the return window is probably closing | **Decide this week.** Keep it only if it fits a Pi 5 *with the Active Cooler*. If it needs the cooler removed, return it |
| Spare black active cooler (4-wire JST) | Unused, lower spec than the fitted one | Keep as a spare |
| Apple 20 W PD (A2305) | Proven | Stays the Pi's supply |

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

## The media PC

The old i7-8700K PC becomes `mediabox`. Specs and what they mean are in
[07-mediabox-setup.md](07-mediabox-setup.md#the-hardware-as-built).

## Shopping list

| Item | For | Needed by |
|---|---|---|
| microSD, 32–64 GB, A2 rated (e.g. SanDisk Extreme / Samsung PRO Plus) | Pi OS; the robot card stays untouched | Phase 2 |
| 2 Ethernet cables | Router to Pi, router to media PC | Phases 2 and 6 |
| NVMe SSD, 500 GB–1 TB | Media PC boot drive | Phase 6 |
| USB stick, 8 GB+ | Ubuntu installer | Phase 6 |
| Hard drive(s) | Media PC data + backup: **size them after research** | Phase 6 |
