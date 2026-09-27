# Research questions (for deep research)

Open decisions the kit can't make without your data or current market info.
Each question carries the context a research tool needs, so you can paste them in
as-is. Answers feed [07-mediabox-setup.md](07-mediabox-setup.md),
[08-mediabox-apps.md](08-mediabox-apps.md) and the router steps.

**Already decided:** the Pi runs network services. The old PC (i7-8700K, UHD 630,
Z370-E, 16 GB, no drives yet) runs media and storage on Ubuntu Server + Docker. The
GTX 1070 Ti is to be removed. Torrent automation is out of scope.

## Facts only you can supply (answer these first)

1. Exact AX5400 router model (sticker), and Xfinity gateway model (XB7/XB8/XB10).
2. The PC case model: how many 3.5"/2.5" bays.
3. Size of your photo/video library, and your current iCloud plan.
4. Size of the movie/TV library, now and in 2 years.
5. What you watch on: TV brand and its built-in apps, Apple TV, Roku, Fire TV,
   Chromecast, phones. Does anyone watch from outside the house?
6. Smart-home devices you own or want (for Home Assistant).

## Questions for research

**Drives and layout for the media PC**
> For an always-on Ubuntu Server media PC (i7-8700K, ASUS Z370-E with 6 SATA
> ports, [N] 3.5" bays) holding [X] TB of media plus [Y] TB of irreplaceable photos:
> recommend drive models and sizes as of late 2026 (NAS-class CMR vs recertified
> enterprise, e.g. serverpartdeals), and a layout: single data drive + separate
> backup drive, vs a mirror (mdadm RAID 1 or ZFS) + backup, vs mergerfs + SnapRAID.
> Include cost per usable TB, noise, and how each handles growing later.

**OS: confirm or overturn Ubuntu Server**
> For that PC, compare Ubuntu Server LTS + Docker, TrueNAS Community Edition,
> Unraid and OpenMediaVault for someone new to servers. Criteria: Intel Quick Sync in
> Plex/Jellyfin containers, running Immich, Time Machine over SMB, ease of adding
> drives, licence cost, and update/maintenance effort.

**Plex vs Jellyfin for my devices**
> Given these playback devices: [list from Q5]. Which of Plex and Jellyfin direct-plays
> common H.264/HEVC/AV1 files with the fewest transcodes on each? How good are
> Jellyfin clients on [devices], including Infuse and Swiftfin? Current Plex Pass /
> Remote Watch Pass pricing, and whether Plex treats access over Tailscale as local or
> remote. With an 8th-gen Intel iGPU (UHD 630), what are the real limits for 4K HDR
> to 1080p SDR tone-mapped transcodes in each?

**Leaving iCloud Photos for Immich**
> Best-practice 2026 migration from iCloud Photos to self-hosted Immich (v3):
> exporting originals with Live Photos, edits, albums and metadata intact
> (icloudpd, Apple's privacy data export, immich-go), handling "Optimize iPhone
> Storage", and ongoing iPhone backup reliability with the Immich iOS app over Tailscale.

**Off-site backup**
> Cheapest reliable off-site backup for [Y] TB of photos from a Linux server in 2026:
> Backblaze B2, Hetzner Storage Box, Wasabi, a Raspberry Pi with a USB drive at a
> relative's house over Tailscale, or keeping a smaller iCloud tier. Include
> restic/Kopia compatibility and the cost of a full restore.

**Router specifics**
> For the [exact model]: where to set LAN DHCP DNS servers, how its IPv6 settings
> interact with Pi-hole (RA/DHCPv6 DNS advertisement), whether it can redirect
> hardcoded DNS (port 53 NAT) to a local server, and any known issues with Xfinity
> bridge mode.
