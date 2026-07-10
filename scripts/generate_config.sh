#!/usr/bin/env bash

set -euo pipefail

DOMAIN=""
UUID=""
PROJECT_DIR=""
MODE=""
HTTPS_PORT="443"
REALITY_DEST=""
REALITY_SNI=""
REALITY_PRIVATE_KEY=""
REALITY_SHORT_ID=""

if [[ ${EUID} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

log() {
  printf '[raystack:config] %s\n' "$*"
}

fail() {
  printf '[raystack:config] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/generate_config.sh --mode <ws|reality|both> --uuid <uuid> --project-dir /path/to/raystack [options]

Options:
  --domain example.com
  --https-port <port>
  --reality-dest <host:port>
  --reality-sni <hostname>
  --reality-private-key <key>
  --reality-short-id <hex>
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --domain)
        DOMAIN="$2"
        shift 2
        ;;
      --uuid)
        [[ $# -ge 2 ]] || fail "--uuid requires a value"
        UUID="$2"
        shift 2
        ;;
      --mode)
        [[ $# -ge 2 ]] || fail "--mode requires a value"
        MODE="$2"
        shift 2
        ;;
      --project-dir)
        [[ $# -ge 2 ]] || fail "--project-dir requires a value"
        PROJECT_DIR="$2"
        shift 2
        ;;
      --https-port)
        HTTPS_PORT="$2"
        shift 2
        ;;
      --reality-dest)
        REALITY_DEST="$2"
        shift 2
        ;;
      --reality-sni)
        REALITY_SNI="$2"
        shift 2
        ;;
      --reality-private-key)
        REALITY_PRIVATE_KEY="$2"
        shift 2
        ;;
      --reality-short-id)
        REALITY_SHORT_ID="$2"
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

  [[ -n "${UUID}" ]] || fail "--uuid is required"
  [[ -n "${MODE}" ]] || fail "--mode is required"
  [[ -n "${PROJECT_DIR}" ]] || fail "--project-dir is required"

  case "${MODE}" in
    ws)
      [[ -n "${DOMAIN}" ]] || fail "--domain is required for WebSocket mode"
      ;;
    reality)
      [[ -n "${REALITY_DEST}" && -n "${REALITY_SNI}" && -n "${REALITY_PRIVATE_KEY}" && -n "${REALITY_SHORT_ID}" ]] \
        || fail "REALITY destination, SNI, private key, and short ID are required"
      ;;
    both)
      [[ -n "${DOMAIN}" ]] || fail "--domain is required when WebSocket mode is selected"
      [[ -n "${REALITY_DEST}" && -n "${REALITY_SNI}" && -n "${REALITY_PRIVATE_KEY}" && -n "${REALITY_SHORT_ID}" ]] \
        || fail "REALITY destination, SNI, private key, and short ID are required"
      ;;
    *)
      fail "Unsupported mode: ${MODE}"
      ;;
  esac
}

write_file_from_template() {
  local source_file="$1"
  local target_file="$2"

  ${SUDO} mkdir -p "$(dirname "${target_file}")"
  sed \
    -e "s|__DOMAIN__|${DOMAIN}|g" \
    -e "s|__UUID__|${UUID}|g" \
    -e "s|__HTTPS_PORT__|${HTTPS_PORT}|g" \
    -e "s|__REALITY_DEST__|${REALITY_DEST}|g" \
    -e "s|__REALITY_SNI__|${REALITY_SNI}|g" \
    -e "s|__REALITY_PRIVATE_KEY__|${REALITY_PRIVATE_KEY}|g" \
    -e "s|__REALITY_SHORT_ID__|${REALITY_SHORT_ID}|g" \
    "${source_file}" | ${SUDO} tee "${target_file}" >/dev/null
}

main() {
  parse_args "$@"

  log "Writing Xray config"
  write_file_from_template "${PROJECT_DIR}/config/xray-${MODE}.json" "/usr/local/etc/xray/config.json"

  if [[ "${MODE}" == "ws" || "${MODE}" == "both" ]]; then
    log "Writing Caddy config"
    write_file_from_template "${PROJECT_DIR}/config/Caddyfile" "/etc/caddy/Caddyfile"
  fi
}

main "$@"
