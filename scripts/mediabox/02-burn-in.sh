#!/usr/bin/env bash
# Phase 6: burn-in test for NEW hard drives before they hold any data.
# DESTROYS EVERYTHING on the drives given. Tests all drives in parallel:
#   SMART short test -> full write+read of every sector (badblocks) -> SMART long test
#   -> compare SMART health counters.
# Takes about 4 days for 20 TB drives. Run it inside tmux so it survives SSH drops:
#   tmux new -s burnin
#   ./scripts/mediabox/02-burn-in.sh /dev/disk/by-id/ata-AAA /dev/disk/by-id/ata-BBB
#   (detach: Ctrl-b then d; reattach later: tmux attach -t burnin)
# Non-destructive SMART-only check (about 1.5 days): add --smart-only as the first argument.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/../common.sh"
require_debian
# Runs for days, far longer than sudo remembers a password, so run the whole thing as root.
[[ $EUID -eq 0 ]] || exec sudo "$0" "$@"

smart_only=false
if [[ "${1:-}" == --smart-only ]]; then smart_only=true; shift; fi
if (( $# == 0 )); then
  echo "usage: $0 [--smart-only] /dev/disk/by-id/ata-... [/dev/disk/by-id/ata-...]" >&2
  echo "Your drives:" >&2
  find /dev/disk/by-id -name 'ata-*' ! -name '*-part*' -printf '  %p -> %l\n' 2>/dev/null >&2
  exit 1
fi
command -v smartctl >/dev/null || die "Run scripts/mediabox/01-bootstrap.sh first (installs smartmontools)."

declare -a devs=()
for arg in "$@"; do devs+=("$(safe_erase_target "$arg")"); done

echo
printf '%-10s %-28s %-22s %s\n' DEVICE MODEL SERIAL SIZE
for d in "${devs[@]}"; do
  printf '%-10s %-28s %-22s %s\n' "${d#/dev/}" "$(lsblk -dno MODEL "$d")" "$(lsblk -dno SERIAL "$d")" "$(lsblk -dno SIZE "$d")"
done
echo
if $smart_only; then
  info "SMART-only mode: nothing will be erased."
else
  warn "EVERYTHING on the drives above will be destroyed."
  read -r -p "Type ERASE to continue: " answer
  [[ "$answer" == ERASE ]] || die "Cancelled."
fi

owner="${SUDO_USER:-root}"
log_root="$(getent passwd "$owner" | cut -d: -f6)/burn-in/$(date +%F)"
mkdir -p "$log_root"

# smartctl's exit code is a bitmask that is non-zero on perfectly usable drives
# (e.g. old entries in a recertified drive's error log), so judge by its output only.
sc() { smartctl "$@" 2>&1 || true; }

wait_selftest() {
  sleep 90
  while [[ "$(sc -c "$1")" == *"in progress"* ]]; do sleep 600; done
}

# SMART counters that should read zero on a healthy drive:
# 5 reallocated, 187 uncorrectable, 197 pending, 198 offline-uncorrectable, 199 cable CRC errors.
counters() { sc -A "$1" | awk '$1 ~ /^(5|187|197|198|199)$/ {print $2 "=" $10}'; }

burn_in() {
  set +e # keep going and log everything; the verdict comes from the results below
  local d="$1" serial log
  serial="$(lsblk -dno SERIAL "$d")"
  log="$log_root/$serial.log"
  {
    echo "== $d $serial  start $(date)"
    sc -i "$d" | grep -E 'Model|Serial|Capacity|Rotation|SATA Version'
    sc -A "$d" | grep -E 'Power_On_Hours|Start_Stop_Count'
    counters "$d" >"$log_root/$serial.before"

    echo "-- SMART short test ($(date))"; sc -t short "$d" >/dev/null; wait_selftest "$d"

    if ! $smart_only; then
      echo "-- badblocks write+read of every sector ($(date))"
      # -b 8192: badblocks counts blocks in 32 bits; 4096-byte blocks overflow above 16 TB.
      badblocks -b 8192 -c 64 -wsv -t random -o "$log_root/$serial.badblocks" "$d"
    fi

    echo "-- SMART long test ($(date))"; sc -t long "$d" >/dev/null; wait_selftest "$d"
    counters "$d" >"$log_root/$serial.after"
    sc -l selftest "$d" | grep -E '^(Num|# ?[1-5] )'
    echo "== done $(date)"
  } >"$log" 2>&1
}

info "Started $(date). Logs: $log_root/<serial>.log (follow with: tail -f $log_root/*.log)"
for d in "${devs[@]}"; do burn_in "$d" & done
wait
chown -R "$owner:" "$(dirname "$log_root")"

echo
info "Results"
all_ok=true
for d in "${devs[@]}"; do
  serial="$(lsblk -dno SERIAL "$d")"
  problems=""
  [[ "$(sc -H "$d")" == *PASSED* ]] || problems+=" SMART-health"
  [[ "$(sc -l selftest "$d" | grep -m1 '^# 1')" == *"Completed without error"* ]] || problems+=" self-test"
  if [[ -s "$log_root/$serial.badblocks" ]]; then
    problems+=" bad-blocks($(wc -l <"$log_root/$serial.badblocks"))"
  fi
  if [[ -f "$log_root/$serial.after" ]]; then
    while IFS='=' read -r attr value; do
      [[ "${value:-0}" == 0 ]] || problems+=" $attr=$value"
    done <"$log_root/$serial.after"
  else
    problems+=" incomplete(see log)"
  fi
  if [[ -z "$problems" ]]; then
    ok "$serial PASSED"
  else
    printf '%sFAIL%s %s:%s (log: %s/%s.log)\n' "$C_ERR" "$C_OFF" "$serial" "$problems" "$log_root" "$serial"
    all_ok=false
  fi
done
if $all_ok; then
  info "All drives passed. Next: ./scripts/mediabox/03-create-pool.sh (docs/07-mediabox-setup.md, E3)"
else
  warn "Return failed drives under warranty. UDMA_CRC_Error_Count alone usually means a bad SATA cable, not a bad drive."
  exit 1
fi
