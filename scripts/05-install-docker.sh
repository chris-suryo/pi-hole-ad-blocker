#!/usr/bin/env bash
# Phase 5: Docker Engine + Compose, for the apps in stacks/. Safe to re-run.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
require_not_root
require_pi_os

if ! command -v docker >/dev/null 2>&1; then
  info "Installing Docker (official convenience script)"
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL https://get.docker.com -o "$installer"
  sudo sh "$installer"
else
  ok "Docker already installed: $(docker --version)"
fi

# The "local" log driver rotates and compresses by default. Without it, container
# logs grow forever and chew through the SD card.
if [[ ! -f /etc/docker/daemon.json ]]; then
  info "Configuring log rotation"
  echo '{ "log-driver": "local" }' | sudo tee /etc/docker/daemon.json >/dev/null
  sudo systemctl restart docker
else
  info "/etc/docker/daemon.json already exists; leaving it alone"
fi
sudo systemctl enable --now docker >/dev/null 2>&1

if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  warn "Added $USER to the docker group. Log out and back in (or reboot) before using docker."
fi

# App config lives outside the git checkout so it can't be committed by accident.
sudo mkdir -p /srv/appdata
sudo chown "$USER:$USER" /srv/appdata
ok "App data folder: /srv/appdata"

sudo docker compose version
echo
info "Next: log out/in, then  cp stacks/.env.example stacks/.env  and  ./stacks/up.sh uptime-kuma"
