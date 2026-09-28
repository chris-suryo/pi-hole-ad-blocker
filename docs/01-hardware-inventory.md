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

### Buy now

| Item | What to get | Why |
|---|---|---|
| microSD for the Pi | 32–64 GB, A2 rated (SanDisk Extreme, Samsung PRO Plus) | Pi OS; the robot card stays untouched |
| 2 Ethernet cables | Cat 6, lengths to suit | Router to Pi, router to media PC |
| NVMe SSD, 1 TB | Any reputable PCIe 3.0 or 4.0 drive (WD Blue SN5000, Crucial P3 Plus, Samsung 990 EVO Plus). The Z370 runs it at PCIe 3.0 speed, so don't pay extra for Gen 5 | Media PC boot drive: OS, Docker, app databases |
| **2 identical hard drives, 16–20 TB** | Best value: **recertified enterprise** (Seagate Exos X18/X20/X22, WD Ultrastar HC550/HC560) from ServerPartDeals or goHardDrive, with at least a 2-year warranty. New alternative: Seagate IronWolf Pro, WD Red Pro, Toshiba N300/MG. Must be **CMR**; avoid plain WD Red and Barracuda (SMR). Buy whichever size is cheapest per TB that day | Two identical drives let you mirror them now (each holds a full copy) or split them into data + backup later. Usable space is one drive's worth. Enterprise drives are loud, which is fine out of the way |
| USB stick, 8 GB+ | Any | Ubuntu installer |

Tips: check the motherboard box for SATA data cables before buying more.
Buying the two drives from different sellers, or a few days apart, avoids a
matched pair from one bad batch.

### Recommended ("run it like a small business")

| Item | What to get | Why |
|---|---|---|
| UPS (battery backup) | Line-interactive, **pure sine wave**, 1000–1500 VA, with a USB port (e.g. CyberPower CP1500PFCLCD, APC Back-UPS Pro BR1500MS2) | Rides through power blips and gives a clean shutdown on long outages. It protects the drives and keeps internet up. Pure sine suits the CX650M's active-PFC power supply. Plug in the PC, Pi, router and modem |
| Molex-to-SATA power adapter, crimped (not molded) | Any | Only if a recertified drive won't spin up ([why](07a-hardware-walkthrough.md#troubleshooting)) |

### Not needed

- **More RAM:** 16 GB covers everything planned.
- **27 W Pi power supply:** no drives on the Pi.
- **Zigbee/Thread USB stick:** your HomePod mini already acts as the Thread hub.
  Revisit only if you buy Zigbee devices.
- **Domain name:** later, for the HTTPS names in [10-pro-layer.md](10-pro-layer.md).
