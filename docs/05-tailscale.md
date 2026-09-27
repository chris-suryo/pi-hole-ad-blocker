# Phase 4: Tailscale (home network and ad-blocking from anywhere)

**Goal:** from your phone or laptop, anywhere:
- reach the Pi and anything at home (router page, Jellyfin, Immich, file shares)
- keep Pi-hole blocking ads on cellular and hotel Wi-Fi
- optionally send *all* traffic through home on untrusted Wi-Fi (exit node)

No ports are opened on the router. Tailscale builds an encrypted WireGuard
link out from each device, so there's nothing on your home IP for attackers to
find. The Personal plan is free.

**Time:** about 20 min. **Needs:** a Tailscale account (sign in with Apple,
Google or GitHub at https://tailscale.com).

## 1. Install on your phone and Mac first

Install the Tailscale app on each and sign in with the same account.

## 2. Install on the Pi

```bash
cd ~/homepi
./scripts/04-install-tailscale.sh
```

Open the login URL it prints and approve the Pi. The script:
- advertises your LAN (`192.168.77.0/24`) as a **subnet route** and the Pi as an **exit node**
- turns on IP forwarding
- runs with `--accept-dns=false`, so the Pi keeps using its own Pi-hole and doesn't loop through Tailscale DNS
- sets Pi-hole to answer tailnet devices (`dns.listeningMode=ALL`; in the web UI, Settings → DNS → switch to **Expert** → Interface settings → **Permit all origins**). This is safe only because the router forwards nothing to the Pi

## 3. Admin console (https://login.tailscale.com/admin)

1. **Machines → homepi → ⋯ → Edit route settings:** tick the `192.168.77.0/24`
   subnet and **Use as exit node**. Save.
2. **Machines → homepi → ⋯ → Disable key expiry.** Without this the server
   silently logs out after 180 days.
3. **DNS → Nameservers → Add nameserver → Custom:** the Pi's Tailscale IP
   (`100.x.y.z`, printed by the script; also `tailscale ip -4`).
   Turn on **Override DNS servers** (under Global nameservers; older docs call it "Override local DNS").
4. Optional: keep **MagicDNS** on so you can use names like `http://homepi:3001`.

## 4. Test from outside

Turn off Wi-Fi on your phone (cellular only) and switch Tailscale on:

- [ ] `http://<pi-tailscale-ip>/admin` loads Pi-hole
- [ ] The Pi-hole Query Log shows queries from a `100.x` client (your phone)
- [ ] `http://192.168.77.1` (the router) loads, which proves the subnet route
- [ ] In the Tailscale app → **Exit node → homepi**: a "what's my IP" site shows your home IP

On iPhone, set the Tailscale app's VPN to reconnect on demand so it stays on.

## Things to know

- **Exit node speed = your home upload speed.** Xfinity upload is much slower than
  download. Fine for browsing and email on hotel Wi-Fi. Don't leave it on for
  everyday use.
- **If the Pi is down, tailnet devices have no DNS**, because "Override DNS servers"
  sends everything to it. Turning Tailscale off on the phone fixes it instantly.
- **Subnet clashes:** if a network you're on also uses `192.168.77.x`, home
  addresses may be unreachable there. That's why Phase 1 picked an uncommon range.
- **Never port-forward** 53, 80, 22 or anything else to the Pi. Tailscale replaces all of that.

## Rollback

- Pi: `sudo tailscale down` (or `sudo tailscale logout` to remove it).
- Admin console: turn off **Override DNS servers**, or tailnet devices will keep
  trying to use the Pi.
- Pi-hole back to LAN-only: `sudo pihole-FTL --config dns.listeningMode LOCAL`.
