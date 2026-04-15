# Reloia HA Apps

Home Assistant app repository containing a packaged `caddy-proxy-manager` app.

## Apps

- `caddy-proxy-manager`: Home Assistant wrapper for [`fuomag9/caddy-proxy-manager`](https://github.com/fuomag9/caddy-proxy-manager)

## Notes

- This package targets `amd64` and `aarch64`.
- The add-on is configured to pull a prebuilt multi-arch image from GHCR at `ghcr.io/reloia/caddy-proxy-manager`.
- It runs on `host_network` so Caddy can bind ports `80`, `443`, and any extra L4 ports directly.
- It stores all persistent state below the app's `/data` directory.
