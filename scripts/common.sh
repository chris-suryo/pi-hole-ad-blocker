# Shared helpers for the setup scripts. Sourced, not run directly.
# shellcheck shell=bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_DIR

if [[ -t 1 ]]; then
  C_OK=$'\e[32m' C_WARN=$'\e[33m' C_ERR=$'\e[31m' C_DIM=$'\e[2m' C_OFF=$'\e[0m'
else
  C_OK='' C_WARN='' C_ERR='' C_DIM='' C_OFF=''
fi

info() { printf '%s==>%s %s\n' "$C_DIM" "$C_OFF" "$*"; }
ok()   { printf '%s ok %s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '%swarn%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
die()  { printf '%sfail%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

confirm() {
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

require_not_root() {
  [[ $EUID -ne 0 ]] || die "Run as your normal user, not root. The script calls sudo itself."
}

require_pi_os() {
  [[ "$(uname -m)" == "aarch64" ]] || die "Expected 64-bit Raspberry Pi OS (aarch64), got $(uname -m)."
  # shellcheck source=/dev/null
  . /etc/os-release
  [[ "${ID:-}" == "debian" || "${ID_LIKE:-}" == *debian* ]] || die "Expected a Debian-based OS, got ${ID:-unknown}."
}

# Interface carrying the default route (eth0 when wired, which is what we want).
lan_iface() {
  ip -4 route show default | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}'
}

lan_ip() {
  ip -4 -o addr show dev "$(lan_iface)" | awk '{split($4, a, "/"); print a[1]; exit}'
}

# e.g. 192.168.77.0/24
lan_cidr() {
  ip -4 route show dev "$(lan_iface)" scope link | awk '/proto kernel/ {print $1; exit}'
}

# Current supply limit the Pi 5 negotiated, in mA (3000 = 3A supply, 5000 = official 27W).
# Prints nothing if the firmware doesn't expose it.
psu_max_ma() {
  local f=/proc/device-tree/chosen/power/max_current
  [[ -r $f ]] && od -An -tu4 --endian=big "$f" | tr -d ' '
}
