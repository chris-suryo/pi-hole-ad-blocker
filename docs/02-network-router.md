# Phase 1: Xfinity gateway in bridge mode + AX5400 as your router

**Why first:** Xfinity gateways don't let you change the DNS server they hand
out to your devices. That setting is how Pi-hole works for the whole house.
The fix is to make the Xfinity box a plain modem (**bridge mode**) and let
the AX5400 do routing, Wi-Fi and DHCP. You also get the better Wi-Fi you
bought it for. Doing this before the Pi means you set up addresses once.

**Time:** 45–60 min. The internet is down for about 10 minutes of it.

```
Before:  Internet ── Xfinity gateway (modem + router + Wi-Fi) ── devices
After:   Internet ── Xfinity gateway (modem only) ── AX5400 (router + Wi-Fi) ── devices
                                                        └── Pi (Ethernet)
```

## What changes when the gateway is bridged

- The gateway's Wi-Fi turns off. The AX5400 becomes your only Wi-Fi.
- Xfinity app network features that live in the gateway stop working:
  device list, pause, port forwarding, Advanced Security. If you have **xFi Pods**
  activated, bridge mode can't be turned on until they're removed.
- Xfinity Voice (home phone), if you have it, keeps working.
- Every device gets a new address range. The old `10.0.0.x` addresses (the
  robot's `10.0.0.3`, the PC, the Mac) go away.

## Before you start

- [ ] Find the exact AX5400 model on its sticker, e.g. TP-Link Archer AX73,
      ASUS RT-AX82U or Netgear RAX50. Menus differ; the brand notes below cover all three.
- [ ] Write down your current Wi-Fi name and password. Reusing them on the
      AX5400 means most devices reconnect on their own.
- [ ] Make sure you can get into the gateway's web admin page. Xfinity now locks it
      by default. In the **Xfinity app**: WiFi → View WiFi equipment → your gateway →
      **Advanced settings** → allow **Admin Tool** access. Then check
      `http://10.0.0.1` loads. The password is on the gateway's sticker unless you changed it.
- [ ] Pick a time when nobody needs the internet.

## Steps

### 1. Set up the AX5400 behind the gateway

1. Cable: gateway **Ethernet port** → AX5400 **WAN / Internet** port (usually a
   different colour).
2. Power on the AX5400. Connect a laptop to it by Ethernet or its default Wi-Fi
   (printed on the sticker).
3. Run its setup wizard. Either browse to the address on the sticker or use the
   brand's app (TP-Link Tether, ASUS Router, Netgear Nighthawk).
   - Internet connection type: **Dynamic IP / Automatic (DHCP)**.
   - Set a strong admin password. This is not the Wi-Fi password.
   - **Update the firmware** before anything else.
4. Wi-Fi: for now, use a **temporary name** (e.g. your old name + `-new`). Two
   networks with the same name would make step 2 confusing. You'll switch to the
   old name and password in step 4, once the Xfinity Wi-Fi is off. Keeping 2.4 GHz
   and 5 GHz under one name (band steering / "Smart Connect") is fine.
5. **LAN address (recommended):** change the router's LAN IP to `192.168.77.1`,
   subnet mask `255.255.255.0`, and set the DHCP pool to `192.168.77.100`–`.249`.
   Default ranges like `192.168.0.x` / `192.168.1.x` are what hotels and
   friends' houses use too. With Tailscale (Phase 4), that overlap makes "reach my
   home network" ambiguous. Any uncommon range works. Just avoid `10.0.0.x`,
   because that's how you'll reach the Xfinity gateway's admin page.
6. Leave DNS settings alone for now. Phase 3 changes them.
7. Hygiene: turn **off** remote/cloud management from the internet and WPS.
   Leave UPnP on unless you know you don't need it (consoles use it).

### 2. Turn on bridge mode on the Xfinity gateway

From a device still connected to the **Xfinity** network:

Browse to `http://10.0.0.1` → log in → **Gateway → At a Glance → Bridge Mode:
Enable**. Confirm the warning. (If the Xfinity app offers a bridge mode switch
under Advanced settings, that works too.)

The gateway restarts. Give it about 5 minutes; its Wi-Fi disappears.

### 3. Restart in order

1. Power off the AX5400.
2. Wait until the gateway is fully back up (steady light).
3. Power the AX5400 on.

### 4. Take over the old Wi-Fi name, then verify

On the AX5400, change the Wi-Fi name and password to the ones you wrote down. Most
devices, including smart-home gadgets, reconnect without you touching them.

- [ ] AX5400 status page: **WAN/Internet IP is a public address**, not `10.0.0.x`.
      If it's still `10.0.0.x`, bridge mode isn't on. If it's blank, power-cycle
      the gateway, then the router.
- [ ] Phone on the new Wi-Fi: a speed test on 5 GHz near the router should be close to your plan.
- [ ] A wired device gets a `192.168.77.x` address.

## Leave these for later phases

| Setting | When |
|---|---|
| DHCP reservation for the Pi | Phase 2, once the Pi is plugged in |
| DHCP DNS server = the Pi | Phase 3, **after** Pi-hole is tested |
| IPv6 DNS behaviour | Phase 3 check. Leave IPv6 on for now |

## Where the settings live (AX5400 brands)

Menus move between firmware versions. If you can't find a setting, search the
brand's support site for the name in bold.

| Setting | TP-Link Archer | ASUS | Netgear Nighthawk |
|---|---|---|---|
| LAN IP / DHCP pool | Advanced → Network → **LAN** / **DHCP Server** | LAN → **LAN IP** / **DHCP Server** | Advanced → Setup → **LAN Setup** |
| **Address reservation** | Advanced → Network → DHCP Server → **Address Reservation** | LAN → DHCP Server → **Manually Assigned IP** | LAN Setup → **Address Reservation** |
| **DNS handed to devices** | DHCP Server → **Primary / Secondary DNS** | LAN → DHCP Server → **DNS Server 1 / 2** | Not available: WAN DNS only (see Phase 3) |

## TP-Link Archer notes (your router)

The research assumed an **Archer AXE75 (AXE5400)**. Confirm the model on the sticker.
The notes below apply to current Archer AX/AXE models either way.

- **Firmware:** the sticker also shows the **hardware version** (e.g. "Ver: 2.6").
  TP-Link publishes separate firmware per hardware version, so download the one that
  matches exactly. Or just use the router's built-in online update.
- **DNS for devices:** Advanced → Network → DHCP Server → Primary DNS (Phase 3).
- **IPv6:** Advanced → IPv6. Leave it on for now; Phase 3 checks whether it leaks DNS.
- **Guest/IoT Wi-Fi:** Advanced → Wireless → Guest Network. Fine for visitors.
  **Don't** move smart-home gear onto it yet: isolation blocks the local discovery that
  Matter, HomeKit, Nanoleaf and Home Assistant rely on.

## Rollback

- **Undo bridge mode:** plug a laptop directly into the gateway by Ethernet, go to
  `http://10.0.0.1` and disable bridge mode. If that page won't load, a factory
  reset (hold the recessed reset button about 30 s) returns it to router mode. You'd
  then need the Wi-Fi name and password on the gateway's sticker.
- Plug devices back into the gateway and you're back where you started.
