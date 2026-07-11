# New Xray x25519 key-output parsing

## Goal

Repair REALITY credential generation for current Xray releases that emit
`PrivateKey:` and `Password:` from `xray x25519`.

## Scope

The installer will parse `PrivateKey:` as the server private key and `Password:`
as the client-side REALITY public key. The `Hash32:` output is intentionally
ignored. Support for the older `Private key:` / `Public key:` format is not in
scope.

## Failure behavior

Existing empty-value validation remains. If either required value cannot be
parsed, installation stops before writing REALITY credentials or configuration.

## Verification

A shell test will provide representative current Xray output and assert that
the parser extracts the private key and password values correctly. It will also
cover malformed output and confirm that it fails validation.
