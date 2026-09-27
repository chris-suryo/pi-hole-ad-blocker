# Phase 2: Move the Pi off the robot, fresh OS, bootstrap

**Goal:** a clean `homepi` server on a new card, wired to the router, with a fixed
address. The robot's card and setup stay intact so you can go back.

**Time:** about 1 hour, plus download time. **Needs:** new microSD, Ethernet
cable, a Mac with [Raspberry Pi Imager](https://www.raspberrypi.com/software/).

## A. Retire the Pi from the robot, reversibly

1. On the robot: `sudo shutdown -h now`. Wait for the green LED to stop, then disconnect the battery.
2. Take the Pi out of the standoff sandwich.
3. **Remove the robot's 128 GB card. Bag and label it "TURBOPI – do not wipe".**
4. *(Optional insurance)* Image the robot card on the Mac before storing it:
   ```bash
   diskutil list                       # find the 128 GB card, e.g. /dev/disk4
   diskutil unmountDisk /dev/disk4
   sudo dd if=/dev/rdisk4 bs=4m status=progress | gzip > ~/turbopi-$(date +%F).img.gz
   ```
   **Triple-check the disk number.** Reading is safe, but the same number typed
   into a write command destroys that disk. Expect about 15–30 GB and 20+ minutes.

## B. While it's apart: RTC battery and cooling

1. **Fit the RTC battery.** Plug it into the 2-pin **BAT** connector (J5, next to
   the USB-C port) and stick it somewhere it can't touch the board.

   Why it matters here: after a power cut the Pi boots with no idea what time it
   is. Unbound's DNSSEC checks fail with a wrong clock, and the clock can't be
   fixed without DNS. The battery keeps time while the power is off.
2. Charging is enabled after the OS is installed (step D4). Only do that for the
   **official rechargeable** battery.
3. Keep the Active Cooler as is. Decide on the 52Pi case now if you haven't
   (docs/01-hardware-inventory.md), because its return window is closing.

## C. Flash the server OS

1. Put the **new** card in the Mac. It must not be the 128 GB robot card.
2. Raspberry Pi Imager:
   - Device: **Raspberry Pi 5**
   - OS: **Raspberry Pi OS (other) → Raspberry Pi OS Lite (64-bit)**. No desktop.
   - Storage: the new card. Check the size shown.
3. Customisation, when Imager offers it:
   - Hostname: **`homepi`**
   - Username + a strong password. The docs assume you use this login everywhere.
   - Wi-Fi: **skip it** if the Pi will be wired, which it should be.
   - Locale / timezone: yours
   - SSH: **enable, public-key only**. Paste your Mac's key:
     `cat ~/.ssh/id_ed25519.pub`. If that file doesn't exist, create one with
     `ssh-keygen -t ed25519`.
   - Raspberry Pi Connect: off. Tailscale covers remote access.
4. Write, eject, insert into the Pi.

## C3. First boot and a fixed address

1. Ethernet from the AX5400 to the Pi, then power.
2. After about 2 minutes, from the Mac: `ssh <you>@homepi.local`.
   If `.local` doesn't resolve, find `homepi` in the router's client list and use its IP.
3. Get the Pi's wired MAC address: `ip link show eth0` → the value after `link/ether`.
4. **Router → Address Reservation:** reserve **`192.168.77.53`** for that MAC.
   (.53 is the DNS port, so it's easy to remember. It sits outside the DHCP pool from
   Phase 1. If the router insists on an address inside the pool, pick one there.)
5. `sudo reboot`, reconnect, and check `hostname -I` shows `192.168.77.53`.

## D. Bootstrap

1. Get this kit onto the Pi:
   ```bash
   sudo apt update && sudo apt install -y git
   git clone https://github.com/chris-suryo/pi-hole-ad-blocker.git ~/homelab
   cd ~/homelab
   ```
   If the kit isn't on the default branch yet, add
   `-b claude/dazzling-bell-p7pqqj` to the clone command.
2. Run:
   ```bash
   ./scripts/01-bootstrap.sh
   sudo reboot
   ```
3. Reconnect and check health:
   ```bash
   cd ~/homelab && ./scripts/verify.sh
   ```
   Expect: `throttled=0x0`, temperature well under 70 °C, "Wired: eth0". A supply
   warning at 3000 mA is expected with the Apple 20 W charger.
4. **RTC charging (official rechargeable battery only):**
   ```bash
   echo 'dtparam=rtc_bbat_vchg=3000000' | sudo tee -a /boot/firmware/config.txt
   sudo reboot
   ```
   Never enable this with a non-rechargeable coin cell.
5. *(Optional)* If you'll never use Bluetooth, add `dtoverlay=disable-bt` to the
   same file. If you skipped Wi-Fi in Imager, Wi-Fi is already inactive.

## Done when

- [ ] `ssh <you>@homepi.local` works with your key
- [ ] `hostname -I` shows the reserved address after a reboot
- [ ] `./scripts/verify.sh` shows no FAIL lines
- [ ] Robot card is bagged and labelled

## Rollback

Shut down, swap the robot card back in, remount on the robot. Nothing on it changed.
