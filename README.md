# raystack

`raystack` is a simple bash-based CLI project for deploying a VPS proxy stack with:

- Xray (`VLESS + WebSocket + TLS`)
- Caddy (automatic HTTPS)
- systemd service management

## Features

- Bash only
- Simple project structure
- Idempotent install flow
- Auto-generate UUID
- Generate Xray and Caddy config files
- Enable and start services with `systemd`

## Project Structure

```text
raystack/
├── install.sh
├── config/
│   ├── xray.json
│   └── Caddyfile
└── scripts/
    ├── install_xray.sh
    ├── install_caddy.sh
    └── generate_config.sh
```

## Requirements

- A Linux VPS with `systemd`
- Root access or `sudo`
- A domain name already pointed to the VPS

## Usage

Run the installer with your domain:

```bash
./install.sh --domain example.com
```

## What The Installer Does

1. Installs system dependencies
2. Installs Xray
3. Installs Caddy
4. Generates or reuses a UUID
5. Writes Xray and Caddy config files
6. Enables and starts the services

## Generated Runtime Files

The installer writes files to these system paths:

- `/usr/local/etc/xray/config.json`
- `/etc/caddy/Caddyfile`
- `/etc/systemd/system/xray.service`
- `/etc/raystack/uuid`

## Default Configuration

### Xray

- Protocol: `VLESS`
- Transport: `WebSocket`
- Path: `/ray`
- Local listen address: `127.0.0.1`
- Local port: `10000`

### Caddy

- Automatic HTTPS for your domain
- Reverse proxy for `/ray*` to `127.0.0.1:10000`
- Default response for other requests: `OK`

## Notes

- The install flow is designed to be safe to run more than once.
- Existing UUID is reused from `/etc/raystack/uuid`.
- Caddy handles TLS automatically after DNS is set correctly.
