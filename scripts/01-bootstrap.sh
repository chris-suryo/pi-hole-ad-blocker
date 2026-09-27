#!/usr/bin/env bash
# Phase 2: update the OS, install base tools, turn on automatic security updates.
# Safe to re-run.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
require_not_root
require_pi_os

info "Updating packages (a few minutes on a fresh install)"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

info "Installing base tools"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install \
  curl ca-certificates git dnsutils htop unattended-upgrades

info "Enabling automatic security updates"
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
ok "unattended-upgrades on (Debian default policy: security updates only)"

info "Power check"
ma="$(psu_max_ma || true)"
if [[ -z "$ma" ]]; then
  warn "Firmware doesn't report the supply limit; skipping."
elif (( ma >= 5000 )); then
  ok "Supply negotiated ${ma} mA: USB ports get the full 1.6 A budget"
else
  warn "Supply negotiated ${ma} mA: USB ports are capped at 600 mA total."
  warn "Fine for Pi-hole. NOT enough for a bus-powered USB drive; see docs/01-hardware-inventory.md."
fi

iface="$(lan_iface)"
if [[ "$iface" == eth* ]]; then
  ok "Online via $iface ($(lan_ip))"
else
  warn "Online via ${iface:-nothing}. A DNS server should be on wired Ethernet."
fi

echo
info "Done. Reboot to load any new kernel/firmware:  sudo reboot"
info "Then run:  ./scripts/verify.sh"
