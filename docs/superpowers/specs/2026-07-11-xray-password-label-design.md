# Xray Password label compatibility

## Goal

Repair current REALITY credential parsing for Xray output that labels the
client credential as `Password (PublicKey):` rather than `Password:`.

## Parsing rule

Each output line is split at its first colon. `PrivateKey` remains an exact
field-name match for the server private key. Any field name beginning with
`Password` is treated as the client-side REALITY public key, including
`Password` and `Password (PublicKey)`.

## Failure behavior

The installer retains its existing required-value check. Missing either the
private key or Password-derived client credential stops installation before any
REALITY credential files are written.

## Verification

The key-parser test will use the observed `Password (PublicKey)` label and
verify that it becomes the public key. It will continue testing malformed output
without a Password field.
