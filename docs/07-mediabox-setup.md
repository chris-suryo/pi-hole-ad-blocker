# Phase 6: Media PC ("mediabox"): hardware, BIOS, Ubuntu Server, drives

**Goal:** turn the old i7-8700K PC into an always-on media and storage server.
The Pi keeps the network jobs (DNS, Tailscale, monitoring). The PC does the heavy
lifting: video transcoding, photo processing, and the drives.

| | Pi (`homepi`) | Media PC (`mediabox`) |
|---|---|---|
| Runs | Pi-hole, Unbound, Tailscale, Uptime Kuma, Portainer, Home Assistant (optional) | Jellyfin/Plex, Immich, file shares, Time Machine, backups |
| Why there | About 5 W, and simple. DNS must stay up even when the PC reboots | Intel Quick Sync, SATA drives, 16 GB RAM |
| Address | `192.168.77.53` | `192.168.77.20` |

**Time:** 3–4 hours including the hardware session. **Needs:** the parts on the
[buy list](01-hardware-inventory.md#shopping-list), a USB stick (8 GB+), and a
monitor and keyboard for setup.

## The hardware (as built)

| Part | Spec | For this job |
|---|---|---|
| CPU | i7-8700K, 6C/12T, UHD 630 iGPU | **Quick Sync** handles several simultaneous 1080p/4K transcodes at low power. Can't decode AV1 in hardware; the CPU covers the occasional AV1 file |
| Board | ASUS ROG Strix Z370-E (BIOS 2201) | 6 SATA ports, 2 M.2 slots, Intel I219-V gigabit Ethernet |
| GPU | GTX 1070 Ti | **Not needed.** Removed in the [hardware walkthrough](07a-hardware-walkthrough.md) |
| RAM | 16 GB DDR4 | Enough for Plex/Jellyfin + Immich + Samba |
| PSU | Corsair CX650M | Plenty; modular, so add SATA power cables for more drives |
| Drives | None: the SSD and HDD moved to the new build | Needs a boot drive and data drive(s) |
| OS | None (Windows went with the SSD) | Fresh install, so the OS is a free choice (section B) |

## A. Hardware session

Follow **[07a-hardware-walkthrough.md](07a-hardware-walkthrough.md)**, a
step-by-step guide for one session with the case open:

1. Remove the GTX 1070 Ti. Quick Sync does the transcoding; the card would only add
   idle power, heat and NVIDIA's driver on Linux.
2. Install the NVMe boot SSD. It holds the OS, Docker, Plex/Jellyfin metadata and
   the Immich database.
3. Install the hard drives.
4. BIOS: use the iGPU, **restart after a power cut**, pure UEFI.

Then connect Ethernet from the AX5400 to the PC.

## B. Install Ubuntu Server

**Why Ubuntu Server:** it's free and uses the same Docker approach as the Pi, so the
kit's app stacks run unchanged. Quick Sync works in containers with one line.
Alternatives considered ([decisions.md](decisions.md)):

| OS | Good | Trade-off |
|---|---|---|
| **Ubuntu Server 26.04 LTS** (chosen) | Free, huge community, same tooling as the Pi, ZFS built in | Everything is command line (Portainer adds a web UI) |
| TrueNAS Community Edition | ZFS (checksums, snapshots), web UI, apps | Wants a whole boot disk and matched drives; more to learn |
| Unraid | Mix-and-match drives, very popular for Plex | Paid licence |
| Windows 11 | Plex runs natively | Immich needs Docker Desktop/WSL2 (awkward); forced update reboots |

Steps:
1. Download **Ubuntu Server 26.04 LTS (amd64)**, the latest point release, from ubuntu.com. Write it
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

## E. Drives: burn-in, then a ZFS mirror

The two data drives become one **ZFS mirror** called `tank`: each drive holds a
full copy, so either can die without losing data or going offline. It's mounted at
`/srv/storage` and split into datasets (`media`, `photos`, `shared`,
`timemachine`, `backups`) with automatic snapshots.
Reasoning: [decisions.md](decisions.md).

### E1. Find the drives' stable names

```bash
ls -l /dev/disk/by-id/ | grep ata- | grep -v part
```

Use these `ata-<model>_<serial>` names from now on. `/dev/sda`-style names can
swap between reboots. The boot SSD shows up as `nvme-…`; never pass that one.

### E2. Burn-in (about 4 days, destroys everything on the drives)

Recertified drives earn trust by passing this, not by their label. Run it in `tmux`
so it keeps going when you close SSH:

```bash
tmux new -s burnin
cd ~/homelab
./scripts/mediabox/02-burn-in.sh /dev/disk/by-id/ata-AAAA /dev/disk/by-id/ata-BBBB
# type ERASE, then detach with Ctrl-b d. Check later with: tmux attach -t burnin
```

Both drives are tested at the same time: SMART short test, then writing and reading
back every sector, then a SMART long test. The script refuses the boot disk and
anything mounted. Logs are in `~/burn-in/<date>/`. **Do the Pi phases (2–5) while
this runs.**

A **FAIL** means returning that drive under warranty. The exception is
`UDMA_CRC_Error_Count` on its own, which usually means a bad SATA cable: swap it
and re-test.

### E3. Create the mirror

```bash
./scripts/mediabox/03-create-pool.sh /dev/disk/by-id/ata-AAAA /dev/disk/by-id/ata-BBBB
```

The script:
- creates `tank` with sensible settings (4K sectors, compression, macOS-friendly metadata)
- creates the datasets and caps Time Machine at 2 TB (change with `TM_QUOTA=1.5T`)
- installs automatic snapshots: [`config/sanoid/sanoid.conf`](../config/sanoid/sanoid.conf)
- installs drive self-tests: [`config/smartd/smartd.conf`](../config/smartd/smartd.conf)
- makes Docker wait for the pool at boot, so apps never write to the bare folder underneath

Ubuntu's ZFS package already scrubs (verifies every block) monthly.

### E4. Check

```bash
./scripts/verify.sh          # ZFS healthy, SMART PASSED, snapshots appearing within the hour
sudo zpool status tank       # both drives ONLINE under "mirror-0"
```

**Undo a mistake:** `ls /srv/storage/photos/.zfs/snapshot/` lists snapshots; copy
files back out of any of them.

## Done when

- [ ] `ssh <you>@mediabox` works (over Tailscale) and the PC has the reserved `192.168.77.20`
- [ ] Both drives PASSED burn-in, and `tank` shows both ONLINE
- [ ] `./scripts/verify.sh`: Quick Sync found, SMART PASSED, ZFS healthy, no FAIL lines
- [ ] Pulling the power cord and plugging it back in makes the PC boot by itself
