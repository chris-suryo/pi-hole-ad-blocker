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

Drives chosen 2026-09-28, with prices as of that day ([decisions.md](decisions.md)).
Other prices were checked 2026-09-27; re-check on the day.

### Buy now

| Item | Get this | Price |
|---|---|---|
| **2× hard drives** | **WD Ultrastar HC560 20 TB, SATA, recertified**, from **goHardDrive**, with the **5-year seller warranty**. Mirrored, they give **20 TB usable** | **$499.95 each** (~$1,000 total) |
| **2× Molex-to-SATA power adapters** | **Crimped, not molded.** Put them in the same order as the drives. The CX650M may send 3.3 V on pin 3, which keeps these drives from spinning up; the adapters are the fix ([how](07a-hardware-walkthrough.md#troubleshooting)) | A few dollars |
| NVMe SSD, 1 TB | Any reputable **TLC** PCIe 3.0/4.0 drive (WD Blue SN5000, Crucial P3 Plus, Samsung 990 EVO Plus). The Z370 runs it at PCIe 3.0 speed | |
| UPS | **CyberPower CP1500PFCLCD** (1500 VA / 1000 W, pure sine, USB) | ~$240 on sale, $275 list |
| microSD for the Pi | 32–64 GB, A2 (SanDisk Extreme, Samsung PRO Plus) | |
| 2 Ethernet cables | Cat 6: router to Pi, router to PC | |
| USB stick | 8 GB+ for the Ubuntu installer | |

**Before you click buy on the drives, check the listing:**

- [ ] The model number contains **LE6** (SATA), e.g. WUH722020BL**E6**…, **not L5** (SAS, e.g.
  WUH722020BL**5**204). SAS drives won't work on your motherboard.
- [ ] It's the **HC560 20 TB** (model starts WUH722020), not an Ultrastar **HC6xx**. Those
  are host-managed SMR and won't work in a normal PC.
- [ ] The **5-year** goHardDrive warranty applies to that listing.
- [ ] Two identical drives. Optional: split them into two orders a few days apart, so
  they're less likely to come from the same batch.

Also check the motherboard box for SATA data cables before buying more.

### If the HC560 is sold out

Buy **two identical** drives from one of these, best value first (prices 2026-09-28):

| Option | Price each | Notes |
|---|---|---|
| Seagate Exos 22 TB, recertified, goHardDrive | $599.95 | 22 TB usable. The listing must say SATA. Get the adapters too |
| Seagate IronWolf Pro 20 TB, new, Micro Center | $569.99 | New, and no power-disable issue, so the adapters aren't needed |
| ServerPartDeals Exos 22 TB | $649 | 3-year warranty; worse value |
| Marketplace listings at $800+ | — | **Avoid** |

### Later (Phase 8), not now

- **Domain name**, at Cloudflare Registrar (~$10–15/yr), for HTTPS names
- **Backblaze B2** account for off-site backups (~$6.95/TB/month)

### Not needed

- **More RAM:** 16 GB covers everything, including ZFS.
- **A third drive:** off-site backup protects more for now.
- **27 W Pi power supply:** no drives on the Pi.
- **Zigbee/Thread USB stick:** the HomePod mini is your Thread border router.
