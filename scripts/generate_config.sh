#!/usr/bin/env bash

set -euo pipefail

DOMAIN=""
UUID=""
PROJECT_DIR=""

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
  ./scripts/generate_config.sh --domain example.com --uuid <uuid> --project-dir /path/to/raystack
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
        UUID="$2"
        shift 2
        ;;
      --project-dir)
        PROJECT_DIR="$2"
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
  [[ -n "${UUID}" ]] || fail "--uuid is required"
  [[ -n "${PROJECT_DIR}" ]] || fail "--project-dir is required"
}

write_file_from_template() {
  local source_file="$1"
  local target_file="$2"

  ${SUDO} mkdir -p "$(dirname "${target_file}")"
  sed \
    -e "s|__DOMAIN__|${DOMAIN}|g" \
    -e "s|__UUID__|${UUID}|g" \
    "${source_file}" | ${SUDO} tee "${target_file}" >/dev/null
}

main() {
  parse_args "$@"

  log "Writing Xray config"
  write_file_from_template "${PROJECT_DIR}/config/xray.json" "/usr/local/etc/xray/config.json"

  log "Writing Caddy config"
  write_file_from_template "${PROJECT_DIR}/config/Caddyfile" "/etc/caddy/Caddyfile"
}

main "$@"
