# Apple REALITY default target

## Goal

Change the installer’s default REALITY target and SNI from Microsoft to Apple's
`swscan.apple.com`.

## Behavior

The default target becomes `swscan.apple.com:443` and the default SNI becomes
`swscan.apple.com`. The existing interactive prompts remain unchanged: pressing
Enter accepts the new values, while operators can provide custom values.

## Scope

Update the installer defaults and documentation/test example values. Do not
alter existing installed configurations; the new defaults apply only when the
installer is run again and the operator accepts them.

## Verification

Run shell syntax checks, the Clash-output tests, the REALITY key-parser tests,
and render all Xray templates with the new target/SNI example.
