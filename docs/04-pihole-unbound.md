# Phase 3: Pi-hole + Unbound, then point the network at it

**Goal:** every device on the network gets ad/tracker blocking, and lookups are
resolved privately by the Pi itself (Unbound). No Google/Cloudflare DNS involved.

**Time:** about 30 min.

```
device ──"ads.example.com?"──▶ Pi-hole :53 ── on a blocklist? ──▶ 0.0.0.0 (ad never loads)
                                   │ no
                                   ▼
                              Unbound :5335 ──▶ root → .com → example.com servers (DNSSEC-checked)
```

## 1. Install Pi-hole

```bash
cd ~/homelab
./scripts/02-install-pihole.sh
```

The script checks that the address is reserved, runs the official installer
(it prints suggested answers first), offers to set the admin password, and tests
resolution. Open the admin page: `http://192.168.77.53/admin`.

## 2. Install Unbound and switch Pi-hole to it

```bash
./scripts/03-install-unbound.sh
```

This installs Unbound on `127.0.0.1:5335` using [`config/unbound/pi-hole.conf`](../config/unbound/pi-hole.conf).
It removes Debian's resolvconf hook, which otherwise hijacks the Pi's own DNS.
It checks that DNSSEC rejects a deliberately broken domain, then sets Pi-hole's
only upstream to `127.0.0.1#5335`.

In the admin page, **Settings → DNS** should show only the custom upstream
`127.0.0.1#5335`, with every provider box unticked.

## 3. Test from the Mac before switching the whole house

```bash
dig @192.168.77.53 example.com +short                     # an IP address
dig @192.168.77.53 pagead2.googlesyndication.com +short   # 0.0.0.0 = blocked
```

## 4. Point the router at the Pi

Set the **DNS server that DHCP hands out** to `192.168.77.53`, and **only**
that. A second entry like 8.8.8.8 would let devices skip Pi-hole whenever they
like.

| Brand | Where | Notes |
|---|---|---|
| TP-Link Archer | Advanced → Network → DHCP Server → **Primary DNS** and **Secondary DNS** both = `192.168.77.53` | A blank secondary can let the router add itself |
| ASUS | LAN → DHCP Server → **DNS Server 1** = `192.168.77.53`, DNS Server 2 blank | Set **"Advertise router's IP in addition to user-specified DNS" = No** |
| Netgear Nighthawk | Its DHCP always hands out the router itself, so set Advanced → Setup → Internet Setup → **Domain Name Server (DNS) Address → Use These DNS Servers** = `192.168.77.53` | Blocking works, but Pi-hole sees every query as coming from the router, so no per-device stats. Fix later by moving DHCP to Pi-hole |

Then get devices to pick it up: toggle Wi-Fi off/on on phones and laptops, or
reboot the router. Everything else updates as its lease renews, within a day.

## 5. Verify it's really working

- [ ] Pi-hole dashboard → **Clients**: several devices, not just `localhost`.
- [ ] Query Log: a phone's traffic shows up, with some queries marked blocked.
- [ ] On the Mac: `scutil --dns | grep nameserver` shows `192.168.77.53`.
- [ ] `./scripts/verify.sh`: no FAIL lines.

### Devices that sneak around Pi-hole

| Leak | What to do |
|---|---|
| **IPv6 DNS.** Xfinity gives you IPv6, and the router may advertise its own IPv6 DNS server | If `scutil --dns` shows extra nameservers, or phones barely appear in Pi-hole, turn off **IPv6** in the router (simplest). The alternative is setting the router's IPv6 LAN DNS to the Pi's IPv6 address |
| Chrome "Use secure DNS" / Edge equivalent | Turn it off in browser settings on each computer |
| Firefox DNS-over-HTTPS | Handled automatically: Pi-hole blocks Mozilla's "canary" domain, which tells Firefox to use the network's DNS |
| iCloud Private Relay (Apple devices) | Pi-hole blocks it by default, so Apple devices show "Private Relay unavailable on this network". Expected. Other networks unaffected |
| Android "Private DNS" set to a hostname | Set it to **Automatic** or Off |
| Chromecast / Google TV hardcoded to 8.8.8.8 | Only fixable with a router firewall redirect, which most consumer routers can't do. Accept it |

## 6. Tune blocklists (optional)

The default list is a sensible start. For more coverage, add **one** of these under
**Lists → Add blocklist**, then **Tools → Update Gravity** (or `pihole -g`):

- HaGeZi Multi PRO: `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt`
- OISD Big: `https://big.oisd.nl`

More lists means more broken sites, not more blocking. When something breaks,
open the **Query Log**, filter by that device, find the blocked domain around
the time it broke, and click **Allow**.

## 7. Make the Pi resilient to its own outage (recommended)

The Pi gets its own DNS from the router, which is now itself. If Pi-hole ever
stops, the Pi can't resolve names to fix itself (`apt`, `pihole -up`). Give it
a fallback:

```bash
con="$(nmcli -g NAME,DEVICE connection show --active | awk -F: '$2=="eth0"{print $1}')"
sudo nmcli connection modify "$con" ipv4.ignore-auto-dns yes ipv4.dns "127.0.0.1 9.9.9.9"
sudo nmcli connection up "$con"
cat /etc/resolv.conf   # 127.0.0.1 first, 9.9.9.9 second
```

## Rollback: tell the household this part

- **One site broken right now:** Pi-hole dashboard → **Disable blocking → 5 minutes**
  (or `pihole disable 5m`).
- **Internet "down" for everyone:** router → DHCP DNS back to automatic/blank, then
  toggle Wi-Fi on the devices. Pi-hole is now out of the path.
