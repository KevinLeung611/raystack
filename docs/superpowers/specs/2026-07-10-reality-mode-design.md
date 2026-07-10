# Interactive VLESS WebSocket and REALITY installation

## Goal

Replace the required `install.sh --domain` interface with an interactive installer
that can deploy VLESS over WebSocket with TLS, VLESS over TCP with REALITY, or
both at once.

## Installation flow

1. `./install.sh` presents three choices:
   - VLESS + WebSocket + TLS
   - VLESS + TCP + REALITY
   - Both modes
2. The installer asks only for inputs needed by the selection:
   - WebSocket requires a domain.
   - REALITY displays a default destination and SNI. Pressing Enter accepts each
     default; entering a value overrides it.
3. A persisted UUID in `/etc/raystack/uuid` is reused, or one is created on the
   first install.
4. The installer writes the matching Xray configuration, then starts and checks
   the services that are applicable to the chosen mode.

## Runtime layout

| Selection | Xray inbound(s) | Caddy | Public ports |
| --- | --- | --- | --- |
| WebSocket | VLESS WebSocket on loopback | Terminates TLS and proxies to Xray | 443 (and 80 for ACME) |
| REALITY | VLESS TCP with REALITY | Not installed or managed | 443 |
| Both | VLESS WebSocket on loopback plus VLESS TCP with REALITY | Terminates TLS and proxies to the WebSocket inbound | 8443 for WebSocket, 443 for REALITY, 80 for ACME |

The concurrent case deliberately assigns port 443 to REALITY and moves Caddy's
HTTPS listener to 8443. This avoids a socket conflict while retaining Caddy's
HTTP listener on port 80 for certificate issuance.

## Configuration generation

Configuration generation will select a mode-specific Xray template (WebSocket,
REALITY, or combined) and a Caddy template that receives the selected HTTPS
port. Placeholder replacement will cover the domain, UUID, REALITY destination,
SNI, private key, public key, short ID, and WebSocket port/path as needed.

REALITY key material and short IDs are generated once per installation and
persisted under `/etc/raystack` so a rerun does not silently invalidate existing
clients. The defaults for destination and SNI are presented before use and can
be overridden interactively.

## Service ownership

Xray is installed and enabled for every selection. Caddy is installed, enabled,
and reloaded only when WebSocket is selected. A REALITY-only installation does
not install or start Caddy; an existing unrelated Caddy service is not removed.

## Completion output

The installer prints one client-configuration summary per selected mode:

- WebSocket: domain, port, UUID, `/ray` path, and TLS enabled.
- REALITY: address, port, UUID, TCP transport, SNI, public key, and short ID.

## Validation and failures

- Reject invalid menu choices and an empty WebSocket domain.
- Fail early when required commands, ports, or generated key material are
  unavailable.
- Validate rendered Xray JSON before replacing the runtime config.
- Validate Caddy's rendered config when Caddy is in scope.
- Check Xray after every install and Caddy only for WebSocket selections.
- Preserve the existing idempotent UUID behavior and avoid stopping or removing
  Caddy in REALITY-only mode.

## Tests

Shell-level tests will exercise non-interactive helper functions or supplied
input for all three selections, default and overridden REALITY values, port
selection, template rendering, invalid input, and service-selection behavior.
