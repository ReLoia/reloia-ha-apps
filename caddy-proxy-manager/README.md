# Caddy Proxy Manager

Home Assistant app wrapper for [`fuomag9/caddy-proxy-manager`](https://github.com/fuomag9/caddy-proxy-manager).

## Packaging model

- Single container package
- Home Assistant pulls the published multi-arch image `ghcr.io/reloia/caddy-proxy-manager:<version>`
- `host_network: true` so Caddy can bind `80`, `443`, and extra L4 ports directly
- Local services started inside the container:
  - ClickHouse on `127.0.0.1:<clickhouse_port>` (default `9123`)
  - Caddy admin API on `127.0.0.1:2019`
  - CPM web UI on `0.0.0.0:<dashboard_port>` (default `8099`)

## Important options

- `dashboard_port`: Port for the CPM dashboard itself. Change this in Home Assistant if `8099` is already in use.
- `clickhouse_port`: Internal analytics database port. Change this if it conflicts with another host service such as Home Assistant on `8123`.
- `base_url`: Public URL used to access CPM itself. This should match the dashboard URL you actually use, for example `http://homeassistant.local:8099` or `https://cpm.example.com`.

## Current limitations

- `aarch64` is declared as supported, but this wrapper still needs a successful registry build/push before Home Assistant can install it
- GeoIP update sidecar is not packaged yet
- This wrapper has been scaffolded and converted to prebuilt-image mode, but it has not been runtime-tested on Home Assistant from this workspace
