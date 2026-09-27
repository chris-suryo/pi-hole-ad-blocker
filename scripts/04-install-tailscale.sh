#!/usr/bin/env bash
# Phase 4: Tailscale. Makes the Pi a subnet router (reach your home LAN from anywhere)
# and an exit node (route all traffic through home on untrusted Wi-Fi), and lets
# tailnet devices use Pi-hole.
#
# Usage: ./scripts/04-install-tailscale.sh
#        LAN_CIDR=192.168.77.0/24 ./scripts/04-install-tailscale.sh   # override detection
# Safe to re-run.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
require_not_root
require_pi_os

cidr="${LAN_CIDR:-$(lan_cidr)}"
[[ -n "$cidr" ]] || die "Couldn't detect the LAN subnet. Re-run with LAN_CIDR=x.x.x.0/24"
info "Home LAN to advertise: ${cidr}"

if ! command -v tailscale >/dev/null 2>&1; then
  info "Installing Tailscale"
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://tailscale.com/install.sh -o "$installer"
  sh "$installer"
fi

info "Enabling IP forwarding (required for subnet router / exit node)"
sudo tee /etc/sysctl.d/99-tailscale.conf >/dev/null <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf >/dev/null

# --accept-dns=false: the Pi must keep using its own Pi-hole, not loop back through
# Tailscale's DNS (which will point at this Pi once configured).
info "Bringing Tailscale up. If it prints a login URL, open it and sign in."
sudo tailscale up \
  --accept-dns=false \
  --advertise-routes="$cidr" \
  --advertise-exit-node

ts_ip="$(tailscale ip -4)"
ok "Tailscale up. This Pi's tailnet address: ${ts_ip}"

# Queries from tailnet devices arrive from 100.x.y.z, which Pi-hole's default
# "local networks only" mode drops. ALL is safe here because the router forwards
# no ports to the Pi: nothing on the internet can reach port 53.
if command -v pihole-FTL >/dev/null 2>&1; then
  info "Allowing Pi-hole to answer tailnet devices"
  if sudo pihole-FTL --config dns.listeningMode ALL >/dev/null; then
    ok "Pi-hole listening mode: ALL"
  else
    warn "Set it manually: web admin > Settings > DNS > Expert > Interface settings > Permit all origins"
  fi
fi

cat <<EOF

Finish in the Tailscale admin console (https://login.tailscale.com/admin/machines):
  1. homepi > ... > Edit route settings: approve ${cidr} and "Use as exit node".
  2. homepi > ... > Disable key expiry (so the server never gets logged out).
  3. DNS page > Nameservers > Add nameserver > Custom: ${ts_ip}
     then turn on "Override DNS servers".
Details and tests: docs/05-tailscale.md

Never port-forward 53 (or anything else) to this Pi on the router. Tailscale is the way in.
EOF
