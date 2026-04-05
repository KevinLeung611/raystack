#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${PROJECT_DIR}/scripts"
CONFIG_DIR="${PROJECT_DIR}/config"

DOMAIN=""
UUID_FILE="/etc/raystack/uuid"

if [[ ${EUID} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

log() {
  printf '[raystack] %s\n' "$*"
}

fail() {
  printf '[raystack] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  ./install.sh --domain example.com
EOF
}

run() {
  log "$*"
  "$@"
}

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    fail "Missing required command: ${command_name}"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --domain)
        [[ $# -ge 2 ]] || fail "--domain requires a value"
        DOMAIN="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  [[ -n "${DOMAIN}" ]] || fail "--domain is required"
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

  fail "Supported package manager not found (apt, dnf, yum)"
}

install_dependencies() {
  local package_manager
  package_manager="$(detect_package_manager)"

  log "Installing dependencies with ${package_manager}"

  case "${package_manager}" in
    apt)
      run ${SUDO} apt-get update -y
      run ${SUDO} apt-get install -y curl unzip tar uuid-runtime ca-certificates gnupg debian-keyring debian-archive-keyring apt-transport-https
      ;;
    dnf)
      run ${SUDO} dnf install -y curl unzip tar util-linux ca-certificates dnf-plugins-core
      ;;
    yum)
      run ${SUDO} yum install -y curl unzip tar util-linux ca-certificates
      ;;
  esac
}

load_or_create_uuid() {
  if [[ -f "${UUID_FILE}" ]]; then
    UUID="$(tr -d '[:space:]' < "${UUID_FILE}")"
    log "Using existing UUID"
    return
  fi

  require_command uuidgen
  UUID="$(uuidgen)"
  run ${SUDO} mkdir -p "$(dirname "${UUID_FILE}")"
  log "Generating UUID"
  printf '%s\n' "${UUID}" | ${SUDO} tee "${UUID_FILE}" >/dev/null
}

start_services() {
  log "Starting services"
  run ${SUDO} systemctl daemon-reload
  run ${SUDO} systemctl enable --now xray
  run ${SUDO} systemctl enable --now caddy
  run ${SUDO} systemctl restart xray
  run ${SUDO} systemctl reload caddy
}

main() {
  parse_args "$@"

  require_command bash
  require_command systemctl

  install_dependencies
  run bash "${SCRIPTS_DIR}/install_xray.sh"
  run bash "${SCRIPTS_DIR}/install_caddy.sh"
  load_or_create_uuid
  run bash "${SCRIPTS_DIR}/generate_config.sh" --domain "${DOMAIN}" --uuid "${UUID}" --project-dir "${PROJECT_DIR}"
  start_services

  log "Install complete"
  log "Domain: ${DOMAIN}"
  log "UUID: ${UUID}"
  log "WS path: /ray"
  log "Local Xray port: 10000"
}

main "$@"
