#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_DIR}/install.sh"

key_pair=$'PrivateKey: server-private-key\nPassword (PublicKey): client-public-key\nHash32: ignored-hash'
parse_reality_key_pair "${key_pair}"

[[ "${REALITY_PRIVATE_KEY}" == "server-private-key" ]] || {
  printf '%s\n' "Expected PrivateKey to be parsed" >&2
  exit 1
}
[[ "${REALITY_PUBLIC_KEY}" == "client-public-key" ]] || {
  printf '%s\n' "Expected Password-derived field to be parsed as the client public key" >&2
  exit 1
}

parse_reality_key_pair $'PrivateKey: server-private-key\nPassword: client-public-key'
[[ "${REALITY_PUBLIC_KEY}" == "client-public-key" ]] || {
  printf '%s\n' "Expected the plain Password field to be parsed" >&2
  exit 1
}

parse_reality_key_pair $'PrivateKey: server-private-key\nHash32: ignored-hash'
[[ -n "${REALITY_PRIVATE_KEY}" && -z "${REALITY_PUBLIC_KEY}" ]] || {
  printf '%s\n' "Expected malformed output to leave the client public key empty" >&2
  exit 1
}
