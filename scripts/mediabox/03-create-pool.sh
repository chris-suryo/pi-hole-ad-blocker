#!/usr/bin/env bash
# Phase 6: create the ZFS mirror "tank" from two burned-in drives, plus its datasets,
# automatic snapshots (Sanoid) and drive-health monitoring (smartd), and make Docker
# wait for the pool at boot.
# DESTROYS EVERYTHING on the two drives. Safe to re-run: an existing pool is kept.
#   ./scripts/mediabox/03-create-pool.sh /dev/disk/by-id/ata-AAA /dev/disk/by-id/ata-BBB
# Time Machine cap (default 2T):  TM_QUOTA=1.5T ./scripts/mediabox/03-create-pool.sh ...
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/../common.sh"
require_not_root
require_debian
is_pi && die "This is the media PC script."

pool=tank
mnt=/srv/storage
tm_quota="${TM_QUOTA:-2T}"

info "Installing ZFS, Sanoid and smartmontools"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install zfsutils-linux sanoid smartmontools

if sudo zpool list -H "$pool" >/dev/null 2>&1; then
  ok "Pool '$pool' already exists; keeping it"
else
  (( $# == 2 )) || die "usage: $0 /dev/disk/by-id/ata-AAA /dev/disk/by-id/ata-BBB"
  for arg in "$@"; do
    [[ "$arg" == /dev/disk/by-id/* ]] \
      || die "Use /dev/disk/by-id/... names, which stay the same across reboots (not $arg). List them: ls /dev/disk/by-id/ | grep -v part"
    safe_erase_target "$arg" >/dev/null
  done
  s1="$(lsblk -bdno SIZE "$1")" s2="$(lsblk -bdno SIZE "$2")"
  [[ "$s1" == "$s2" ]] || warn "The drives differ in size; the mirror will only use the smaller one's capacity."

  echo
  lsblk -dno NAME,MODEL,SERIAL,SIZE "$(readlink -f "$1")" "$(readlink -f "$2")"
  warn "Both drives above will be erased and mirrored as '$pool', mounted at $mnt."
  read -r -p "Type ERASE to continue: " answer
  [[ "$answer" == ERASE ]] || die "Cancelled."

  # ashift=12: 4K sectors (can't be changed later). xattr=sa + posixacl: needed for
  # Samba/macOS metadata. lz4 compression is essentially free.
  sudo zpool create -f -o ashift=12 \
    -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl -O dnodesize=auto \
    -O mountpoint="$mnt" "$pool" mirror "$1" "$2"
  ok "Created mirror '$pool'"
fi

for ds in media photos shared timemachine backups; do
  sudo zfs list -H "$pool/$ds" >/dev/null 2>&1 || sudo zfs create "$pool/$ds"
done
sudo zfs set recordsize=1M "$pool/media"          # big sequential video files
sudo zfs set quota="$tm_quota" "$pool/timemachine" # Time Machine would otherwise fill the pool
sudo chown "$USER:$USER" "$mnt"/{media,photos,shared,timemachine,backups}
mkdir -p "$mnt"/media/{movies,tv,music}
ok "Datasets: $(sudo zfs list -H -o name -r "$pool" | tr '\n' ' ')"

# Without this, Docker can start before the pool mounts at boot and apps would write
# into the empty /srv/storage folder on the boot drive.
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/10-wait-for-zfs.conf >/dev/null <<'CONF'
[Unit]
After=zfs-mount.service
Requires=zfs-mount.service
CONF
sudo systemctl daemon-reload
ok "Docker waits for the pool at boot"

sudo install -m 0644 "$REPO_DIR/config/sanoid/sanoid.conf" /etc/sanoid/sanoid.conf
if sudo systemctl enable --now sanoid.timer >/dev/null 2>&1; then
  ok "Sanoid snapshots scheduled"
else
  warn "Couldn't enable sanoid.timer; check: systemctl list-timers | grep sanoid"
fi

[[ -f /etc/smartd.conf.orig ]] || sudo cp /etc/smartd.conf /etc/smartd.conf.orig
sudo install -m 0644 "$REPO_DIR/config/smartd/smartd.conf" /etc/smartd.conf
sudo systemctl restart smartmontools
ok "smartd: weekly short and monthly long self-tests"

if [[ -f /etc/cron.d/zfsutils-linux ]]; then
  ok "Monthly scrub: Ubuntu's zfsutils-linux runs it on the second Sunday"
else
  warn "No zfsutils scrub job found. Add one (15th of each month): echo '0 3 15 * * root zpool scrub $pool' | sudo tee /etc/cron.d/zfs-scrub"
fi

echo
sudo zpool status "$pool"
sudo zfs list -r -o name,used,avail,quota,recordsize,mountpoint "$pool"
