#!/usr/bin/env bash
# Health check for every phase. Read-only; run it any time: ./scripts/verify.sh
# Checks for components that aren't installed yet are skipped. May ask for your
# sudo password (reading Pi-hole's config needs root).
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
set +e

passes=0 warns=0 fails=0
pass() { ok "$*"; passes=$((passes + 1)); }
soft() { warn "$*"; warns=$((warns + 1)); }
bad()  { printf '%sFAIL%s %s\n' "$C_ERR" "$C_OFF" "$*"; fails=$((fails + 1)); }
section() { printf '\n%s[%s]%s\n' "$C_DIM" "$*" "$C_OFF"; }
have() { command -v "$1" >/dev/null 2>&1; }

section "Hardware"
if have vcgencmd; then
  throttled="$(vcgencmd get_throttled | cut -d= -f2)"
  if [[ "$throttled" == 0x0 ]]; then
    pass "No under-voltage or throttling since boot (get_throttled=0x0)"
  else
    bad "get_throttled=${throttled}: under-voltage/throttling seen. Check the PSU and cable."
  fi

  temp="$(vcgencmd measure_temp | grep -o '[0-9.]*' | cut -d. -f1)"
  if [[ -z "$temp" ]]; then soft "Couldn't read the CPU temperature"
  elif (( temp < 70 )); then pass "CPU ${temp}°C"
  elif (( temp < 80 )); then soft "CPU ${temp}°C: warm. Is the fan spinning?"
  else bad "CPU ${temp}°C: throttling territory"
  fi
fi

ma="$(psu_max_ma)"
if [[ -n "$ma" ]]; then
  if (( ma >= 5000 )); then pass "Supply negotiated ${ma} mA"
  else soft "Supply negotiated ${ma} mA: USB capped at 600 mA total (no bus-powered drives)"
  fi
fi

root_use="$(df --output=pcent / | tail -1 | tr -dc '0-9')"
if (( root_use < 80 )); then pass "Root filesystem ${root_use}% used"
else soft "Root filesystem ${root_use}% used"
fi

if [[ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" == yes ]]; then
  pass "Clock synchronised (DNSSEC depends on it)"
else
  soft "Clock not NTP-synchronised yet"
fi

section "Network"
iface="$(lan_iface)"
if [[ -z "$iface" ]]; then
  bad "No default route: the Pi is offline"
elif is_wired "$iface"; then
  pass "Wired: ${iface} $(lan_ip) on $(lan_cidr)"
else
  soft "Using ${iface} $(lan_ip). Wired Ethernet is recommended"
fi

section "Pi-hole"
if have pihole; then
  if systemctl is-active --quiet pihole-FTL; then
    pass "pihole-FTL running"
  else
    bad "pihole-FTL not running: sudo systemctl restart pihole-FTL"
  fi

  if [[ -n "$(dig +short +time=3 +tries=1 example.com @127.0.0.1)" ]]; then
    pass "Resolves example.com"
  else
    bad "Pi-hole isn't resolving example.com"
  fi

  blocked=""
  for d in pagead2.googlesyndication.com ads.doubleclick.net adservice.google.com; do
    if [[ "$(dig +short +time=3 +tries=1 "$d" @127.0.0.1 | head -1)" == 0.0.0.0 ]]; then
      blocked="$d"
      break
    fi
  done
  if [[ -n "$blocked" ]]; then
    pass "Blocking works (${blocked} -> 0.0.0.0)"
  else
    soft "None of the test ad domains were blocked. Lists loaded? Run: pihole -g"
  fi

  upstreams="$(sudo pihole-FTL --config dns.upstreams 2>/dev/null)"
  if [[ "$upstreams" == *127.0.0.1#5335* ]]; then
    pass "Upstream is Unbound"
  elif [[ -n "$upstreams" ]]; then
    soft "Upstream is ${upstreams}, not Unbound (run scripts/03-install-unbound.sh)"
  fi
else
  info "Pi-hole not installed yet: skipped"
fi

section "Unbound"
if have unbound; then
  if systemctl is-active --quiet unbound; then pass "unbound running"
  else bad "unbound not running: sudo journalctl -u unbound -n 50"
  fi
  status() { dig "$@" +time=5 +tries=1 +noall +comments | grep -o 'status: [A-Z]*' | cut -d' ' -f2; }
  if [[ "$(status pi-hole.net @127.0.0.1 -p 5335)" == NOERROR ]]; then pass "Unbound resolves"
  else bad "Unbound isn't resolving"
  fi
  if [[ "$(status fail01.dnssec.works @127.0.0.1 -p 5335)" == SERVFAIL ]]; then pass "DNSSEC rejects bad signatures"
  else soft "DNSSEC test didn't SERVFAIL. Clock wrong?"
  fi
else
  info "Unbound not installed yet: skipped"
fi

section "Tailscale"
if have tailscale; then
  if ts_ip="$(tailscale ip -4 2>/dev/null)" && [[ -n "$ts_ip" ]]; then
    pass "Connected as ${ts_ip}"
  else
    bad "Installed but not connected: sudo tailscale up (see scripts/04-install-tailscale.sh)"
  fi
  if [[ "$(sysctl -n net.ipv4.ip_forward)" == 1 ]]; then pass "IPv4 forwarding on (subnet router / exit node)"
  else bad "IPv4 forwarding off: re-run scripts/04-install-tailscale.sh"
  fi
  if have pihole; then
    mode="$(sudo pihole-FTL --config dns.listeningMode 2>/dev/null)"
    if [[ "$mode" == ALL ]]; then pass "Pi-hole answers tailnet devices"
    else soft "Pi-hole listeningMode is '${mode}': tailnet devices can't use it"
    fi
  fi
else
  info "Tailscale not installed yet: skipped"
fi

section "Docker"
if have docker; then
  if ! systemctl is-active --quiet docker; then
    bad "docker not running"
  elif ! running="$(docker ps --format '{{.Names}} ({{.Status}})' 2>/dev/null)"; then
    soft "Can't query docker as ${USER}. Log out/in after joining the docker group"
  elif [[ -z "$running" ]]; then
    info "No containers running"
  else
    while read -r line; do
      if [[ "$line" == *unhealthy* || "$line" == *Restarting* ]]; then bad "$line"
      else pass "$line"
      fi
    done <<<"$running"
  fi
else
  info "Docker not installed yet: skipped"
fi

if ! is_pi; then
  section "Quick Sync"
  if node="$(intel_render_node)"; then
    pass "Intel iGPU available for hardware transcoding: ${node}"
  else
    bad "No Intel iGPU render node. Enable the iGPU in the BIOS (docs/07-mediabox-setup.md)"
  fi
fi

if have smartctl; then
  section "Disk health (SMART)"
  while read -r disk; do
    health="$(sudo smartctl -H "/dev/$disk" 2>/dev/null | grep -Eo 'PASSED|FAILED|OK' | head -1)"
    case "$health" in
      PASSED|OK) pass "/dev/${disk} SMART ${health}" ;;
      FAILED)    bad "/dev/${disk} SMART FAILED: back it up and replace it now" ;;
      *)         info "/dev/${disk}: no SMART data (USB bridge or virtual disk)" ;;
    esac
  done < <(lsblk -dno NAME,TYPE | awk '$2 == "disk" && $1 !~ /^(mmcblk|zram|loop)/ {print $1}')
fi

section "Storage"
if mountpoint -q /srv/storage; then
  use="$(df --output=pcent /srv/storage | tail -1 | tr -dc '0-9')"
  if (( use < 85 )); then pass "/srv/storage mounted, ${use}% used"
  else soft "/srv/storage ${use}% used"
  fi
elif grep -q ' /srv/storage ' /etc/fstab 2>/dev/null; then
  bad "/srv/storage is in fstab but not mounted. Is the drive connected and powered?"
else
  info "No storage drive configured yet: skipped"
fi

printf '\n%d ok, %d warnings, %d failures\n' "$passes" "$warns" "$fails"
(( fails == 0 ))
