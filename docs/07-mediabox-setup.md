# Phase 6: Media PC ("mediabox"): hardware, BIOS, Ubuntu Server, drives

**Goal:** turn the old i7-8700K PC into an always-on media and storage server.
The Pi keeps the network jobs (DNS, Tailscale, monitoring). The PC does the heavy
lifting: video transcoding, photo processing, and the drives.

| | Pi (`homepi`) | Media PC (`mediabox`) |
|---|---|---|
| Runs | Pi-hole, Unbound, Tailscale, Uptime Kuma, Portainer, Home Assistant (optional) | Jellyfin/Plex, Immich, file shares, Time Machine, backups |
| Why there | About 5 W, and simple. DNS must stay up even when the PC reboots | Intel Quick Sync, SATA drives, 16 GB RAM |
| Address | `192.168.77.53` | `192.168.77.20` |

**Time:** 2–3 hours, mostly the OS install and waiting. **Needs:** a boot SSD,
at least one data drive, a USB stick (8 GB+), a monitor and keyboard for setup.

## The hardware (as built)

| Part | Spec | For this job |
|---|---|---|
| CPU | i7-8700K, 6C/12T, UHD 630 iGPU | **Quick Sync** handles several simultaneous 1080p/4K transcodes at low power. Can't decode AV1 in hardware; the CPU covers the occasional AV1 file |
| Board | ASUS ROG Strix Z370-E (BIOS 2201) | 6 SATA ports, 2 M.2 slots, Intel I219-V gigabit Ethernet |
| GPU | GTX 1070 Ti | **Not needed.** See A3 |
| RAM | 16 GB DDR4 | Enough for Plex/Jellyfin + Immich + Samba |
| PSU | Corsair CX650M | Plenty; modular, so add SATA power cables for more drives |
| Drives | None: the SSD and HDD moved to the new build | Needs a boot drive and data drive(s) |
| OS | None (Windows went with the SSD) | Fresh install, so the OS is a free choice (section B) |

## A. Hardware prep

1. **Boot drive:** an NVMe SSD, 500 GB–1 TB, in an M.2 slot. It holds the OS, Docker,
   Plex/Jellyfin metadata and the Immich database, which all benefit from SSD speed.
   On Z370 boards some M.2 slots disable SATA ports when used. Check the
   M.2/SATA sharing table in the Z370-E manual before plugging in data drives.
2. **Data drive(s):** see [research-questions.md](research-questions.md). A sensible
   start is one large CMR hard drive for media and photos, plus one for backups.
   NAS-class drives (WD Red Plus, Seagate IronWolf, Toshiba N300) or recertified
   enterprise drives are good value. Check the case has 3.5" bays.
3. **Remove the GTX 1070 Ti (recommended).** Quick Sync does the transcoding. The card
   only adds idle power draw, heat, and NVIDIA's proprietary driver on Linux. Put it
   in the new build or sell it. Plug the monitor into the **motherboard's** HDMI/DP
   port for setup.
   *Keeping it anyway?* Then in the BIOS set **iGPU Multi-Monitor: Enabled**, or the
   iGPU disappears and Quick Sync with it.
4. **BIOS** (Del at boot, then F7 for Advanced Mode). Names may differ slightly:
   - Advanced → System Agent (SA) Configuration → Graphics Configuration →
     **Primary Display: IGFX** (or Auto with the 1070 Ti removed).
   - Advanced → APM Configuration → **Restore AC Power Loss: Power On**. The server
     comes back by itself after a power cut.
   - Boot → CSM → **Disabled** (pure UEFI install).
   - Optional: check ASUS support for a BIOS newer than 2201 (Intel security
     microcode) and flash it with EZ Flash from a USB stick.
5. Ethernet cable from the AX5400 to the PC.

## B. Install Ubuntu Server

**Why Ubuntu Server:** it's free and uses the same Docker approach as the Pi, so the
kit's app stacks run unchanged. Quick Sync works in containers with one line.
Alternatives, if your research points elsewhere:

| OS | Good | Trade-off |
|---|---|---|
| **Ubuntu Server LTS** (default) | Free, huge community, same tooling as the Pi | Everything is command line (Portainer adds a web UI) |
| TrueNAS Community Edition | ZFS (checksums, snapshots), web UI, apps | Wants a whole boot disk and matched drives; more to learn |
| Unraid | Mix-and-match drives, very popular for Plex | Paid licence |
| Windows 11 | Plex runs natively | Immich needs Docker Desktop/WSL2 (awkward); forced update reboots |

Steps:
1. Download the latest **Ubuntu Server LTS (amd64)** ISO from ubuntu.com. Write it
   to a USB stick with Raspberry Pi Imager (**Choose OS → Use custom**) or balenaEtcher.
2. Boot the PC from the stick (F8 at power-on opens the boot menu on ASUS boards).
3. In the installer:
   - **Network:** the wired port gets an address automatically. Fine.
   - **Storage:** "Use an entire disk" → pick the **NVMe SSD only**. Leave the data
     drives alone; step E sets them up. The default LVM layout is fine; the bootstrap
     script grows it to the full disk.
   - **Profile:** server name **`mediabox`**, same username as on the Pi.
   - **SSH:** tick **Install OpenSSH server**. If your Mac's public key is on your
     GitHub account, use "Import SSH key → from GitHub".
   - **Featured server snaps: select none.** In particular *not* `docker`: the snap
     version conflicts with the Docker the kit installs.
4. Reboot, pull the USB stick.

## C. Fixed address

1. Log in at the console and run `ip -br link` to find the wired interface
   (`enp0s31f6` or similar) and its MAC address.
2. In the router, **reserve `192.168.77.20`** for that MAC (same place as the Pi's
   reservation, Phase 2 step C3). `sudo reboot`, then check `ip -br addr`.
3. From the Mac: `ssh <you>@192.168.77.20`. If you didn't import a key, run
   `ssh-copy-id <you>@192.168.77.20` first.

## D. Bootstrap, Docker, Tailscale

```bash
sudo apt install -y git
git clone https://github.com/chris-suryo/pi-hole-ad-blocker.git ~/homelab
cd ~/homelab
./scripts/mediabox/01-bootstrap.sh     # updates, tools, Quick Sync check, grows the disk
sudo reboot
```

Then:

```bash
cd ~/homelab
./scripts/05-install-docker.sh          # same script as the Pi
exit                                    # log out/in for the docker group
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --accept-dns=false    # open the printed URL to add it to your tailnet
./scripts/verify.sh
```

In the Tailscale admin console, **disable key expiry** for `mediabox`, as for the Pi.
From now on `ssh <you>@mediabox` and `http://mediabox:<port>` work from anywhere
Tailscale is on. On the LAN, `mediabox.local` works too.

`verify.sh` on this machine should show a **Quick Sync** line with an Intel render
node, plus SMART health for each drive.

## E. Data drive(s) (this ERASES them)

```bash
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINT   # find the data drive by SIZE and MODEL, e.g. sda
# Everything below uses sda. Check twice: the boot SSD is nvme0n1, never touch it.
sudo parted /dev/sda --script mklabel gpt mkpart storage ext4 0% 100%
sudo mkfs.ext4 -L storage /dev/sda1
sudo mkdir -p /srv/storage
echo "UUID=$(sudo blkid -s UUID -o value /dev/sda1) /srv/storage ext4 defaults,noatime,nofail,x-systemd.device-timeout=10s 0 2" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload && sudo mount -a
sudo mkdir -p /srv/storage/{media/{movies,tv,music},photos,shared,timemachine}
sudo chown -R "$USER:$USER" /srv/storage
df -h /srv/storage
```

`nofail` lets the PC boot even if a drive dies or is unplugged. A second (backup)
drive gets the same treatment, mounted at `/srv/backup`; the backup job comes in
[Phase 7](08-mediabox-apps.md#7-backups-dont-skip).

## Done when

- [ ] `ssh <you>@mediabox` works (over Tailscale) and the PC has the reserved `192.168.77.20`
- [ ] `./scripts/verify.sh`: Quick Sync found, SMART PASSED, `/srv/storage` mounted, no FAIL lines
- [ ] Pulling the power cord and plugging it back in makes the PC boot by itself
