#!/usr/bin/env bash

set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

log() {
  printf '[raystack:caddy] %s\n' "$*"
}

run() {
  log "$*"
  "$@"
}

detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
    return
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
    return
  fi

  if command -v yum >/dev/null 2>&1; then
    echo "yum"
    return
  fi

  log "Supported package manager not found"
  exit 1
}

install_caddy_apt() {
  if command -v caddy >/dev/null 2>&1; then
    log "Caddy already installed"
    return
  fi

  run ${SUDO} mkdir -p /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/caddy-stable-archive-keyring.gpg ]]; then
    run bash -c 'curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | '"${SUDO:+sudo }"'gpg --dearmor -o /etc/apt/keyrings/caddy-stable-archive-keyring.gpg'
  fi

  if [[ ! -f /etc/apt/sources.list.d/caddy-stable.list ]]; then
    printf '%s\n' \
      'deb [signed-by=/etc/apt/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main' \
      | ${SUDO} tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  fi

  run ${SUDO} apt-get update -y
  run ${SUDO} apt-get install -y caddy
}

install_caddy_rpm() {
  if command -v caddy >/dev/null 2>&1; then
    log "Caddy already installed"
    return
  fi

  run bash -c 'curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/setup.rpm.sh | '"${SUDO:+sudo }"'bash'

  if command -v dnf >/dev/null 2>&1; then
    run ${SUDO} dnf install -y caddy
    return
  fi

  run ${SUDO} yum install -y caddy
}

ensure_directories() {
  run ${SUDO} mkdir -p /etc/caddy
}

main() {
  local package_manager
  package_manager="$(detect_package_manager)"

  case "${package_manager}" in
    apt)
      install_caddy_apt
      ;;
    dnf|yum)
      install_caddy_rpm
      ;;
  esac

  ensure_directories
}

main "$@"
