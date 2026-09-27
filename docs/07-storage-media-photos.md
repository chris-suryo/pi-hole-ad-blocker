# Phase 6: Storage, media server, photos, file shares, backups

**Status: decide before building.** This phase depends on answers you don't have
yet: how much data, which TVs and apps, how much redundancy. The research
questions are in [research-questions.md](research-questions.md). The steps
below assume the simplest option (A) and can be adapted.

## Three rules before you buy anything

1. **Storage is not backup.** One drive in the Pi is *one* copy. Family photos
   need **3-2-1**: 3 copies, on 2 different kinds of media, 1 of them off-site.
   Mirroring two drives (RAID 1) protects against a dead drive, not against
   deletion, corruption, theft or fire.
2. **The Pi 5 can't hardware-transcode video.** It has no video encoder.
   Plex and Jellyfin work well when your TV/phone can play the file as-is
   ("direct play"). Converting video on the fly (4K → phone, or unsupported codecs)
   will stutter. What you watch on decides whether that matters.
3. **Power:** bus-powered USB drives need the 27 W PSU
   ([hardware doc](01-hardware-inventory.md#power-the-one-conclusion-that-changes)).
   Drives with their own power adapter don't.

## Hardware options

| Option | Rough cost | Good | Bad |
|---|---|---|---|
| **A. Pi + external USB drive(s)** (3.5" desktop enclosure with its own power, or a USB SSD) | $ | Uses what you have; simplest; add a second drive as a backup target | USB is less robust than SATA; single drive = no redundancy; no transcoding |
| **B. Pi + NVMe SSD on an M.2 HAT+** | $$ | Fast, silent, tiny; great for the Immich database and app data | Cost per TB is high, so it suits photos/apps more than a movie library; needs the 27 W PSU |
| **C. Pi + multi-drive SATA HAT** (e.g. Radxa Penta SATA HAT) | $$ | A real mini-NAS; mirroring possible | Most tinkering; separate 12 V supply; single PCIe lane |
| **D. Dedicated NAS or Intel N100-class mini PC** (e.g. UGREEN NASync, Synology) | $$$ | Intel Quick Sync = hardware transcoding for Plex/Jellyfin; multiple bays; polished apps | Another box to buy; the Pi then just does network jobs (Pi-hole, Tailscale) |

**Suggested path:** start with **A**: one large self-powered drive for
media and photos, plus a second drive (or cloud) for backups. Graduate to **D**
if you need transcoding or more bays. The Pi keeps doing network duty either way.

### Is it cheaper than iCloud?

iCloud+ 2 TB costs about $10/month in the US. Self-hosting costs drives up front,
plus an off-site backup (cloud storage like Backblaze B2 runs a few dollars per
TB per month). For a photo library under about 1–2 TB, self-hosting is
**not much cheaper once you pay for proper backup.** It wins on large media
libraries, owning your data, and no per-GB upsell. Keep iCloud running until
Immich has everything **and** you've tested restoring from backup.

## Media server: Jellyfin or Plex

| | Jellyfin | Plex |
|---|---|---|
| Cost | Free, open source | Free locally. **Since April 2025, streaming your own videos outside the home needs a paid plan**: Plex Pass ($6.99/mo or $69.99/yr) or a Remote Watch Pass for each viewer ($2.99/mo) |
| Apps | Good: web, iOS/Android, Android/Google TV, Fire TV, Roku, Apple TV (Swiftfin, or Infuse) | Best-in-class, on nearly every TV and device |
| Over Tailscale | Works; no account or cloud dependency | Works, but Plex hasn't said whether a VPN counts as "remote" (paid). Adding Tailscale's range to Plex's "LAN Networks" is an unofficial workaround Plex may block |
| On a Pi 5 | Same for both: direct play only, no hardware transcoding | |

**Default here: Jellyfin**, because it matches the "don't pay for anything" goal.
The Plex stack is included if your TVs or family strongly prefer it. Run one, not both.

## Build steps (option A)

### 1. Prepare the drive (this ERASES it)

```bash
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINT   # identify the drive by its SIZE and MODEL, e.g. sda
# Everything below uses sda. Check the name twice; the SD card is mmcblk0, never touch it.
sudo parted /dev/sda --script mklabel gpt mkpart storage ext4 0% 100%
sudo mkfs.ext4 -L storage /dev/sda1
sudo mkdir -p /srv/storage
echo "UUID=$(sudo blkid -s UUID -o value /dev/sda1) /srv/storage ext4 defaults,noatime,nofail,x-systemd.device-timeout=10s 0 2" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload && sudo mount -a
df -h /srv/storage
```

`nofail` means the Pi still boots if the drive is unplugged.

### 2. Folder layout

```bash
sudo mkdir -p /srv/storage/{media/{movies,tv,music},photos,shared,timemachine}
sudo chown -R "$USER:$USER" /srv/storage
```

Name media the way media servers expect: `movies/Movie Name (2019)/Movie Name (2019).mkv`
and `tv/Show Name/Season 01/Show Name S01E01.mkv`.

### 3. Jellyfin

```bash
./stacks/up.sh jellyfin
```

Open `http://homepi.local:8096`, then:
1. Create the admin user.
2. Add libraries pointing at `/media/movies` and `/media/tv`.
3. In Dashboard → Playback, leave hardware acceleration **off**.

Away from home, use `http://homepi:8096` with Tailscale on.

### 3b. Plex, instead of Jellyfin

Get a claim token at https://www.plex.tv/claim (valid 4 minutes), then:
```bash
PLEX_CLAIM=claim-xxxxxxxx ./stacks/up.sh plex
```
Open `http://homepi.local:32400/web`. Add libraries at `/media/movies` and `/media/tv`.

### 4. Immich (photos: the iCloud Photos replacement)

```bash
./stacks/immich/setup.sh             # downloads the official compose file and writes .env
cd stacks/immich && docker compose up -d
```

Open `http://homepi.local:2283` and create the admin account. On your iPhone:
1. Install **Immich** from the App Store.
2. Server URL: `http://homepi:2283`. This works at home and away, as long as
   Tailscale is on.
3. Turn on **Backup** for the Camera Roll.

Notes:
- Immich recommends 8 GB RAM (6 GB minimum). The Pi has 8 GB, shared with
  everything else. If memory gets tight, turn off Machine Learning in Immich's
  admin settings; you lose face and object search.
- The first upload of a big library takes a long time, and face and object
  recognition on the Pi's CPU takes longer. Let it run overnight.
- The database lives in `/srv/appdata/immich/postgres` (on the SD card). If you
  add an SSD, move it there.
- Getting photos *out* of iCloud (originals, Live Photos, albums) is its own
  project. See the research questions.

### 5. File shares and Time Machine (Samba)

```bash
sudo apt install -y samba
sudo smbpasswd -a "$USER"                          # a password for connecting from the Mac
sed "s/YOURUSER/$USER/g" config/samba/shares.conf | sudo tee -a /etc/samba/smb.conf >/dev/null
testparm -s >/dev/null && sudo systemctl restart smbd
```

- Mac: Finder → Go → Connect to Server → `smb://homepi.local/shared`
- Time Machine: System Settings → General → Time Machine → Add Backup Disk →
  **timemachine**. Adjust the size cap in `config/samba/shares.conf` before
  running the commands above.

### 6. Backups (don't skip)

| What | Where | How |
|---|---|---|
| Photos (`/srv/storage/photos`) | 2nd drive **and** off-site | `restic` nightly to a second USB drive; `restic` to Backblaze B2, or keep a small iCloud/Google tier for photos only |
| Immich database | Same as photos | Immich writes automatic DB dumps into its upload folder, so they travel with the photos |
| App settings (`/srv/appdata`) | 2nd drive | Same `restic` job |
| Pi-hole settings | Your Mac | Settings → Teleporter → Export, after any big change |
| Media library | Optional | Re-rippable, so usually skipped. Your call |

The exact backup script will be added once the storage hardware is chosen. The
rule until then: **don't delete anything from iCloud or your phone yet.**
