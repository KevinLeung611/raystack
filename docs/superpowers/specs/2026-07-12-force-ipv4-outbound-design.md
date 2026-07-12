# Force IPv4 Xray outbounds

## Goal

Make every generated Xray configuration use IPv4 for outbound domain resolution
and connections.

## Scope

Update the `freedom` outbound in the WebSocket-only, REALITY-only, and combined
Xray templates to set:

```json
"settings": {
  "domainStrategy": "ForceIPv4"
}
```

No installation prompts, inbound settings, client configuration, or service
behavior changes are required.

## Verification

Render and parse each Xray template, then assert that every rendered template
contains `outbounds[0].settings.domainStrategy` with the value `ForceIPv4`.
