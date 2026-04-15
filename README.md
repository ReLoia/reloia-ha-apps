# Reloia HA Apps

Home Assistant app repository containing a packaged `caddy-proxy-manager` app.

## Apps

- `caddy-proxy-manager`: Home Assistant wrapper for [`fuomag9/caddy-proxy-manager`](https://github.com/fuomag9/caddy-proxy-manager)

## Notes

- This package targets `amd64` and `arm64`.
- It runs on `host_network` so Caddy can bind ports `80`, `443`, and any extra L4 ports directly.
- It stores all persistent state below the app's `/data` directory.
