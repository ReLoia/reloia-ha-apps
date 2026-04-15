# Caddy Proxy Manager

Home Assistant app wrapper for [`fuomag9/caddy-proxy-manager`](https://github.com/fuomag9/caddy-proxy-manager).

## Packaging model

- Single container package
- `host_network: true` so Caddy can bind `80`, `443`, and extra L4 ports directly
- Local services started inside the container:
  - ClickHouse on `127.0.0.1:8123`
  - Caddy admin API on `127.0.0.1:2019`
  - CPM web UI on `0.0.0.0:3000`

## Current limitations

- `arm64` is declared as supported, but this wrapper has not been built and runtime-tested on Home Assistant yet
- GeoIP update sidecar is not packaged yet
- This wrapper has been scaffolded and syntax-checked locally, but not container-built inside Home Assistant from this workspace
