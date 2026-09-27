# Research questions (for deep research)

Open decisions the kit can't make without your data or current market info.
Each has the context a research tool needs. Paste them in as-is. Answers feed
[07-storage-media-photos.md](07-storage-media-photos.md) and the router steps.

## Facts only you can supply (answer these first)

1. Exact AX5400 router model (sticker), and Xfinity gateway model (XB7/XB8/XB10).
2. Size of your photo/video library, and your current iCloud plan.
3. Size of the movie/TV library you'd put on Plex/Jellyfin, now and in 2 years.
4. What you watch on: TV brand and its built-in apps, Apple TV, Roku, Fire TV,
   Chromecast, phones, and whether anyone watches from outside the house.
5. Apple-only household, or Android/Windows too? (The robot notes list a
   Windows PC and a Mac.)

## Questions for research

**Storage hardware**
> For a US household with a Raspberry Pi 5 (8 GB) already running Pi-hole and
> Tailscale, compare as of late 2026: (a) one or two self-powered USB 3.5"
> drives on the Pi, (b) NVMe via the official M.2 HAT+, (c) a Radxa Penta SATA HAT,
> (d) a 2-bay N100-class NAS (UGREEN NASync DXP2800, Synology DS225+/DS224+, etc.).
> Criteria: total cost for [X] TB usable with one backup copy, reliability,
> power draw, noise, hardware transcoding, and Synology's current drive-compatibility policy.

**Plex vs Jellyfin for my devices**
> Given these playback devices: [list from Q4]. Which of Plex and Jellyfin
> direct-plays common H.264/HEVC/AV1 files with the fewest transcodes on each?
> Current Plex remote-streaming rules and prices (Plex Pass / Remote Watch Pass),
> and whether Plex treats access over Tailscale as local or remote. Quality of
> Jellyfin clients on [devices], including Infuse and Swiftfin.

**Leaving iCloud Photos for Immich**
> Best-practice 2026 migration from iCloud Photos to self-hosted Immich (v3):
> exporting originals with Live Photos, edits, albums and metadata intact
> (icloudpd, Apple privacy data export, immich-go), handling "Optimize iPhone
> Storage", and ongoing iPhone backup reliability with the Immich iOS app over Tailscale.

**Off-site backup**
> Cheapest reliable off-site backup for 0.5–4 TB from a Raspberry Pi in 2026:
> Backblaze B2, Hetzner Storage Box, Wasabi, a second Pi at a relative's
> house over Tailscale, or keeping a smaller iCloud tier. Include restic/Kopia
> compatibility and egress costs for a full restore.

**Router specifics**
> For the [exact model]: where to set LAN DHCP DNS servers, how its IPv6
> settings interact with Pi-hole (RA/DHCPv6 DNS advertisement), whether it can
> redirect hardcoded DNS (port 53 NAT) to a local server, and any known issues
> with Xfinity bridge mode.
