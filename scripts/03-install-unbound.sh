#!/usr/bin/env bash
# Phase 3b: install Unbound and make Pi-hole use it as its only upstream.
# Afterwards no third-party DNS provider sees your household's lookups.
# Safe to re-run.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
require_not_root
require_pi_os
command -v pihole >/dev/null 2>&1 || die "Install Pi-hole first: ./scripts/02-install-pihole.sh"

dns_status() { dig "$@" +time=5 +tries=2 +noall +comments | grep -o 'status: [A-Z]*' | cut -d' ' -f2; }

# Unbound talks to the DNS root servers directly. Some ISPs intercept outbound DNS,
# which breaks that, so check before changing anything.
info "Checking the root DNS servers are reachable directly (a.root-servers.net)"
if [[ "$(dns_status @198.41.0.4 . NS +norec)" == NOERROR ]]; then
  ok "Root servers reachable, no interception"
else
  die "Can't query a.root-servers.net directly. Your ISP or router may be intercepting DNS. Keep Pi-hole's current upstream and see docs/09."
fi

info "Installing Unbound"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install unbound
sudo install -m 0644 "$REPO_DIR/config/unbound/pi-hole.conf" /etc/unbound/unbound.conf.d/pi-hole.conf

# Debian's unbound package adds a resolvconf hook that repoints the Pi's own resolver
# at unbound. That fights with Pi-hole, so undo it (per the Pi-hole Unbound guide).
sudo systemctl disable --now unbound-resolvconf.service 2>/dev/null || true
if [[ -f /etc/resolvconf.conf ]]; then
  sudo sed -Ei 's/^unbound_conf=/#unbound_conf=/' /etc/resolvconf.conf
fi
sudo rm -f /etc/unbound/unbound.conf.d/resolvconf_resolvers.conf

sudo unbound-checkconf
sudo systemctl enable unbound
sudo systemctl restart unbound

info "Testing Unbound on 127.0.0.1#5335 (the first lookup can take a few seconds)"
for _ in 1 2 3 4 5; do
  [[ "$(dns_status pi-hole.net @127.0.0.1 -p 5335)" == NOERROR ]] && break
  sleep 2
done
[[ "$(dns_status pi-hole.net @127.0.0.1 -p 5335)" == NOERROR ]] \
  || die "Unbound isn't resolving. Check: sudo journalctl -u unbound -n 50"
ok "Unbound resolves"

if [[ "$(dns_status fail01.dnssec.works @127.0.0.1 -p 5335)" == SERVFAIL ]]; then
  ok "DNSSEC: bad signature rejected (SERVFAIL, as it should)"
else
  warn "DNSSEC: fail01.dnssec.works did not SERVFAIL. Is the clock right? (timedatectl)"
fi

if dig dnssec.works @127.0.0.1 -p 5335 +time=5 +noall +comments | grep -q 'flags:.* ad'; then
  ok "DNSSEC: good signature validated (ad flag)"
else
  warn "DNSSEC: dnssec.works missing the 'ad' flag"
fi

info "Pointing Pi-hole at Unbound"
if sudo pihole-FTL --config dns.upstreams '["127.0.0.1#5335"]' >/dev/null; then
  ok "Pi-hole upstream: $(sudo pihole-FTL --config dns.upstreams)"
else
  warn "Couldn't set it from the command line. In the web admin: Settings > DNS >"
  warn "untick every provider, add custom upstream 127.0.0.1#5335, Save."
fi

if [[ -n "$(dig +short +time=5 example.com @127.0.0.1)" ]]; then
  ok "End to end: client -> Pi-hole -> Unbound -> internet works"
else
  die "Pi-hole isn't answering through Unbound. Check the upstream setting in the web admin."
fi

echo
info "Next: point the router at this Pi (docs/04-pihole-unbound.md, step 4)"
