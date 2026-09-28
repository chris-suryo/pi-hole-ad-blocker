#!/usr/bin/env bash
# Phase 6: base setup for the media PC ("mediabox", Ubuntu Server). Updates the OS,
# installs disk/GPU diagnostics, and confirms Intel Quick Sync is usable.
# Safe to re-run.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/../common.sh"
require_not_root
require_debian
is_pi && die "This is the media PC script. On the Pi use scripts/01-bootstrap.sh."

info "Updating packages"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

info "Installing tools (SMART disk health, GPU monitoring)"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install \
  curl ca-certificates git htop smartmontools intel-gpu-tools unattended-upgrades pciutils \
  tmux avahi-daemon   # tmux: long jobs survive SSH drops; avahi: mediabox.local works on the LAN
# Host-side VA-API driver, only for the vainfo check below; the media containers bring their own.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install vainfo intel-media-va-driver-non-free \
  || warn "Couldn't install vainfo/intel-media-va-driver-non-free; skipping the encoder check."

sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF
ok "Automatic security updates on"

info "Checking Intel Quick Sync"
if node="$(intel_render_node)"; then
  ok "Intel iGPU render node: ${node}"
  if command -v vainfo >/dev/null 2>&1; then
    if sudo vainfo --display drm --device "$node" 2>/dev/null | grep -q 'VAEntrypointEncSlice'; then
      ok "Hardware video encoding available (VA-API reports encoders)"
    else
      warn "vainfo lists no encoders on ${node}. Check the BIOS iGPU settings (docs/07-mediabox-setup.md)."
    fi
  fi
  [[ "$node" == /dev/dri/renderD128 ]] \
    || warn "Quick Sync is ${node}, not renderD128. Pick it explicitly in Jellyfin/Plex transcoding settings."
else
  warn "No Intel iGPU visible. In the BIOS, enable the iGPU (docs/07-mediabox-setup.md, step A3)."
fi

if lspci | grep -qi 'nvidia'; then
  warn "NVIDIA card detected. This kit doesn't use it (Quick Sync does the work); removing it saves idle power."
fi

info "Disk space"
root_vg="$(sudo lvs --noheadings -o vg_name "$(findmnt -no SOURCE /)" 2>/dev/null | tr -d ' ' || true)"
if [[ -n "$root_vg" ]]; then
  free_g="$(sudo vgs --noheadings --units g --nosuffix -o vg_free "$root_vg" | tr -d ' ' | cut -d. -f1)"
  free_g="${free_g:-0}"
  if (( free_g > 10 )); then
    warn "The Ubuntu installer left ${free_g} GB of the boot drive unallocated."
    if confirm "Grow the root filesystem to use it?"; then
      sudo lvextend -r -l +100%FREE "$(findmnt -no SOURCE /)"
    fi
  fi
fi
df -h /

echo
if [[ -f /var/run/reboot-required ]]; then info "Reboot required:  sudo reboot"; fi
info "Next: ./scripts/05-install-docker.sh, then docs/07-mediabox-setup.md step D"
