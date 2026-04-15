# Caddy Proxy Manager

Home Assistant app wrapper for [`fuomag9/caddy-proxy-manager`](https://github.com/fuomag9/caddy-proxy-manager).

## Packaging model

- Single container package
- Home Assistant pulls the published multi-arch image `git.reloia.uk/reloia/caddy-proxy-manager:<version>`
- `host_network: true` so Caddy can bind `80`, `443`, and extra L4 ports directly
- Local services started inside the container:
  - ClickHouse on `127.0.0.1:8123`
  - Caddy admin API on `127.0.0.1:2019`
  - CPM web UI on `0.0.0.0:3000`

## Current limitations

- `aarch64` is declared as supported, but this wrapper still needs a successful registry build/push before Home Assistant can install it
- GeoIP update sidecar is not packaged yet
- This wrapper has been scaffolded and converted to prebuilt-image mode, but it has not been runtime-tested on Home Assistant from this workspace
