ARG CPM_REF=2adb8e38074c0555be50ffad120fdf7a4b8be1fd
ARG BUILD_VERSION=0.1.0

FROM ubuntu:24.04 AS upstream
ARG CPM_REF
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone https://github.com/fuomag9/caddy-proxy-manager.git . \
    && git checkout "${CPM_REF}"

FROM oven/bun:1-slim AS web-deps
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=upstream /src/package.json /src/bun.lock ./
RUN bun install --frozen-lockfile --ignore-scripts

FROM oven/bun:1-slim AS web-builder
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATABASE_PATH=/tmp/build.db
ENV DATABASE_URL=file:/tmp/build.db
WORKDIR /app
COPY --from=web-deps /app/node_modules ./node_modules
COPY --from=upstream /src ./
RUN bun run build && rm -f /tmp/build.db

FROM golang:1.26 AS caddy-builder
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
RUN GOPROXY=direct xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4 \
    --with github.com/fuomag9/caddy-blocker-plugin \
    --with github.com/corazawaf/coraza-caddy/v2 \
    --output /usr/bin/caddy

FROM clickhouse/clickhouse-server:latest AS clickhouse

FROM ubuntu:24.04
ARG BUILD_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dumb-init \
    jq \
    procps \
    sqlite3 \
    wget \
    && rm -rf /var/lib/apt/lists/*

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="aarch64|amd64"

COPY --from=web-builder /usr/local/bin/bun /usr/local/bin/bun
COPY --from=web-builder /app/public /opt/cpm-web/public
COPY --from=web-builder /app/.next/standalone /opt/cpm-web
COPY --from=web-builder /app/.next/static /opt/cpm-web/.next/static
COPY --from=web-builder /app/package.json /opt/cpm-web/package.json
COPY --from=web-builder /app/.next/server/instrumentation.js /opt/cpm-web/.next/server/instrumentation.js
COPY --from=web-builder /app/.next/server/instrumentation /opt/cpm-web/.next/server/instrumentation
COPY --from=web-builder /app/.next/server/chunks /opt/cpm-web/.next/server/chunks
COPY --from=web-builder /app/drizzle /opt/cpm-web/drizzle

COPY --from=upstream /src/docker/caddy/Caddyfile /opt/cpm/etc/Caddyfile
COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

COPY --from=clickhouse /usr/bin/clickhouse /usr/bin/clickhouse
COPY --from=clickhouse /etc/clickhouse-server /etc/clickhouse-server

COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

ENTRYPOINT ["dumb-init", "--", "/usr/local/bin/run.sh"]
