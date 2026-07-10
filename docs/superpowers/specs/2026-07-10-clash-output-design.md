# Terminal Clash Meta configuration output

## Goal

After a successful installation, print client-ready YAML proxy entries for
Mihomo / Clash Meta without writing any client configuration to disk.

## Output scope

The installer retains its existing concise connection summary and adds a marked
YAML block suitable for pasting beneath a user's `proxies:` key:

- WebSocket selections output one VLESS WebSocket-over-TLS proxy.
- REALITY selections output one VLESS TCP-with-REALITY proxy.
- The combined selection outputs both proxies in the same YAML list.

No `proxy-groups`, rules, DNS configuration, or other client policy is emitted;
these are client-specific choices outside the installer scope.

## Node fields

The WebSocket node contains a descriptive name, VLESS type, server domain,
selected public port, UUID, `tls: true`, `network: ws`, and `/ray` under
`ws-opts.path`.

The REALITY node contains a descriptive name, VLESS type, a server-address
placeholder, port 443, UUID, `flow: xtls-rprx-vision`, `network: tcp`,
`tls: true`, `servername`, `reality-opts.public-key`,
`reality-opts.short-id`, and `client-fingerprint: chrome`.

## Safety and usability

The output is bounded by clear begin/end markers and includes a short note that
it targets Mihomo / Clash Meta. It never prints or persists the REALITY private
key. The public key and short ID remain available only as client parameters.

## Verification

Tests will render the output for each installation mode and check for required
mode-specific fields, both entries in combined mode, and the absence of the
private key.
