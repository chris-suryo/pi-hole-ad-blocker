# Research brief: paste into a research-capable LLM

**How to use:**
1. Fill in the four `[FILL IN]` lines below. "Unknown" is fine; the brief asks for
   options in that case.
2. Copy everything from **"Begin prompt"** to the end into the research tool.
3. Paste its full answer back into the Claude Code session. The final **DECISIONS**
   block is formatted so the kit can be updated from it directly.

---

## Begin prompt

You are helping plan a two-machine home lab for a US household on Xfinity internet.
Research **current (late 2026)** information: prices, product availability,
software versions. Cite a source URL and date for every price and every claim
that could have changed recently. When sources disagree, say so. Be specific:
exact models, versions, settings. Don't pad.

### The setup (decided; don't re-litigate unless something is clearly wrong)

- **Network:** Xfinity gateway in bridge mode → AX5400-class router (model: **[FILL IN]**)
  doing routing, Wi-Fi and DHCP.
- **Raspberry Pi 5 (8 GB), always on:** Pi-hole v6 + Unbound (network-wide DNS),
  Tailscale (subnet router + exit node), Uptime Kuma, optional Portainer and Home
  Assistant (container). Raspberry Pi OS Lite 64-bit (Debian 13).
- **Media PC, always on:** i7-8700K (UHD 630 iGPU, Quick Sync), ASUS ROG Strix Z370-E
  (6 SATA, 2 M.2), 16 GB DDR4, Corsair CX650M PSU, Intel I219-V gigabit, 3.5" bays.
  GTX 1070 Ti being removed. Planned: Ubuntu Server LTS + Docker running
  Jellyfin and/or Plex, Immich (photos, replacing iCloud Photos), Samba + Time
  Machine, backups. It sits out of the way, so drive noise doesn't matter.
- **Goal:** "run it like a small business": reliable, monitored, backed up,
  documented, secure. The owner is new to servers, so prefer well-trodden,
  well-documented options over clever ones.
- **Out of scope:** torrent/download automation.

### Household facts

- Storage need: "pretty large." Mostly 1080p, some 4K, growing. Photo library size / current iCloud plan: **[FILL IN]**
- Playback devices (TVs, streaming sticks, phones): **[FILL IN]**
- Smart home: a few smart bulbs (brand: **[FILL IN]**), Google Home speaker(s),
  Apple HomePod mini (Thread border router), Nanoleaf.
- Remote viewing: household members away from home, via Tailscale. Possibly a friend.

### Questions

**1. Drives to buy now.** Plan: 2 identical CMR drives, 16–20 TB each, plus a 1 TB
NVMe boot SSD.
- Best current price per TB at 16, 18, 20, 22 and 24 TB: recertified enterprise
  (ServerPartDeals, goHardDrive: Exos, Ultrastar) vs new NAS drives (IronWolf Pro,
  Red Pro, Toshiba N300/MG). Include warranty terms.
- Any known reliability issues with specific recent models (Backblaze drive stats).
- Does the Corsair CX650M's SATA power cable supply 3.3 V? Would it trigger the
  power-disable pin on these drives?
- Is a third drive (dedicated backup) worth buying now, or does off-site cover it?

**2. Storage layout.** ZFS mirror (Ubuntu `zfsutils-linux`) vs mdadm RAID 1 + ext4
vs one data drive + one backup drive vs mergerfs + SnapRAID. Recommend one for this
owner and goal, with:
- snapshot tooling (sanoid or similar)
- the path to add capacity later
- the RAM needed with 16 GB total

**3. Operating system check.** Ubuntu Server LTS + Docker vs Proxmox VE vs TrueNAS
Community Edition for this owner and goal. Would Proxmox, with Home Assistant OS in
a VM, be worth the extra complexity? Recommend one.

**4. UPS.** Pure sine wave, NUT-compatible (Network UPS Tools), load about 150 W
(PC + Pi + router + modem), at least 15 minutes of runtime. Give 2–3 current
models with prices. Explain how NUT would shut down both machines from one UPS
USB connection.

**5. The "small business" layer.** For a one-person home lab reachable only on the
LAN and via Tailscale (no open ports), recommend current best choices, in order,
with effort estimates:
- Reverse proxy with real HTTPS certificates via DNS challenge and a cheap domain
  (Caddy vs Traefik vs Nginx Proxy Manager), and where to register the domain.
- How names should resolve through Pi-hole locally and Tailscale remotely.
- Single sign-on (Authelia vs Authentik vs Pocket ID vs Tailscale identity headers).
  Is it worth it at this scale?
- Monitoring and alerting beyond Uptime Kuma (Beszel, Netdata, Prometheus + Grafana),
  with alerts via ntfy for SMART, UPS, backups and disk space.
- Container update notifications (Diun, What's Up Docker, etc.). Which auto-updaters
  are deprecated?
- Backup tool for restic-style encrypted, deduplicated backups with a web UI
  (Backrest, Kopia, etc.).

**6. Off-site backup** for about **[photo library size]** of photos plus a few GB of
configs. Compare Backblaze B2, Hetzner Storage Box, Wasabi, and a Raspberry Pi with
a USB drive at a relative's house over Tailscale. Include monthly cost, full-restore
cost, and restic/Kopia compatibility.

**7. Home Assistant for these devices.** Container on the Pi vs HA OS (VM on the
PC, or a dedicated Home Assistant Green)? What's actually lost without the add-on
store? How to bring each device in:
- Matter/Thread via the HomePod mini
- Nanoleaf
- Google Home
- exposing HA devices back to Apple Home and Google Home

Is any USB radio (Zigbee/Thread) worth buying for these devices?

**8. Plex vs Jellyfin** for these playback devices with light 4K use:
- UHD 630 limits for 4K HDR → 1080p SDR tone-mapped transcodes in each
- current Plex Pass / Remote Watch Pass pricing and rules
- whether Plex treats Tailscale access as remote
- quality of Jellyfin clients on the listed devices

**9. iCloud Photos → Immich (v3) migration.** The best current method (icloudpd,
Apple's privacy data export, immich-go), keeping originals, Live Photos, edits,
albums and metadata. How to handle "Optimize iPhone Storage". How reliable is
ongoing iPhone backup with the Immich app over Tailscale?

**10. Router specifics** for **[router model]**:
- where the LAN DHCP DNS server setting lives
- IPv6 behaviour with Pi-hole (does it advertise its own IPv6 DNS?)
- guest/IoT network isolation
- any Xfinity bridge-mode issues

### Output format

For each question: a **Recommendation** (1–3 lines), then a compact comparison
table (with prices and dates where relevant), then **Risks/gotchas**. Finish with this
block exactly, one line per item, so it can be applied automatically:

```
DECISIONS
drives: <model> x<count> <size>TB, <new|recertified>, <seller>, ~$<price> each (<date>)
boot_ssd: <model> <size>
third_drive: <yes|no> <why>
layout: <zfs-mirror|mdadm-raid1|data+backup|mergerfs-snapraid>
snapshots: <tool, schedule>
os: <ubuntu-server|proxmox|truenas>
ups: <model>, ~$<price>
reverse_proxy: <tool>, domain registrar: <registrar>
sso: <tool|none>
monitoring: <tools>
update_notifications: <tool>
backup_tool: <tool>
offsite: <provider>, ~$<cost>/month
home_assistant: <container-on-pi|haos-vm|ha-green>
radio_dongle: <none|model>
media_server: <jellyfin|plex|both>
photo_migration: <method>
router_notes: <one line>
```
