#!/usr/bin/env bash

set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

log() {
  printf '[raystack:xray] %s\n' "$*"
}

run() {
  log "$*"
  "$@"
}

install_binary() {
  if command -v xray >/dev/null 2>&1; then
    log "Xray already installed"
    return
  fi

  log "Installing Xray"
  run bash -c 'curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh | '"${SUDO:+sudo }"'bash -s -- install'
}

ensure_directories() {
  run ${SUDO} mkdir -p /usr/local/etc/xray
  run ${SUDO} mkdir -p /var/log/xray
}

ensure_service() {
  if [[ -f /etc/systemd/system/xray.service ]]; then
    log "systemd unit already present"
    return
  fi

  log "Writing systemd unit"
  ${SUDO} tee /etc/systemd/system/xray.service >/dev/null <<'EOF'
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_ADMIN
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_NET_ADMIN
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=5
LimitNPROC=500
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
}

main() {
  install_binary
  ensure_directories
  ensure_service
}

main "$@"
