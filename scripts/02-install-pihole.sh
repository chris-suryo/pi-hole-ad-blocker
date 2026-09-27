#!/usr/bin/env bash
# Phase 3a: install Pi-hole with the official installer. Safe to re-run.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
require_not_root
require_pi_os

iface="$(lan_iface)"
ip="$(lan_ip)"
info "This Pi is ${ip} on ${iface}."
[[ "$iface" == eth* ]] || warn "Not on Ethernet. Wired is strongly recommended for a DNS server."

cat <<EOF

Pi-hole needs an address that never changes. Before continuing, your router must
have a DHCP reservation that always gives this Pi ${ip} (docs/03-pi-prep-and-os.md, step C3).

EOF
confirm "Is ${ip} reserved for this Pi in the router?" \
  || die "Add the reservation, reboot the Pi, check 'hostname -I' shows it, then re-run."

if command -v pihole >/dev/null 2>&1; then
  ok "Pi-hole is already installed:"
  pihole version || true
else
  cat <<'EOF'

The official installer is interactive. Suggested answers:
  - Static IP warning        -> Continue (the router reservation covers this)
  - Upstream DNS provider    -> Quad9 (filtered, DNSSEC). Temporary; Unbound replaces it next.
  - Default blocklist        -> Yes
  - Query logging            -> On
  - Privacy mode             -> 0 (show everything). It's your own network.
Note the admin password it prints at the end. You can change it in a moment.

EOF
  read -r -p "Press Enter to start the installer..."
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://install.pi-hole.net -o "$installer"
  sudo bash "$installer"
fi

if confirm "Set or change the web admin password now?"; then
  sudo pihole setpassword
fi

info "Testing: resolve a normal domain through Pi-hole"
if [[ -n "$(dig +short +time=3 +tries=1 example.com @127.0.0.1)" ]]; then
  ok "Pi-hole is answering DNS on 127.0.0.1"
else
  die "No answer from Pi-hole. Check: sudo systemctl status pihole-FTL"
fi

echo
info "Web admin:  http://${ip}/admin   (or http://pi.hole/admin once the router points at it)"
info "Next:       ./scripts/03-install-unbound.sh"
