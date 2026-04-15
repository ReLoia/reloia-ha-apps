#!/bin/bash
set -eu

OPTIONS_FILE="/data/options.json"
STATE_DIR="/data/caddy-proxy-manager"
CLICKHOUSE_DIR="${STATE_DIR}/clickhouse"
CADDY_DATA_DIR="${STATE_DIR}/caddy/data"
CADDY_CONFIG_DIR="${STATE_DIR}/caddy/config"
CADDY_LOG_DIR="${STATE_DIR}/caddy/logs"
WEB_DATA_DIR="${STATE_DIR}/web"
CADDYFILE_PATH="${STATE_DIR}/Caddyfile"

if [ ! -f "${OPTIONS_FILE}" ]; then
  echo "Missing ${OPTIONS_FILE}"
  exit 1
fi

json() {
  jq -r "${1}" "${OPTIONS_FILE}"
}

json_opt() {
  jq -r "${1} // empty" "${OPTIONS_FILE}"
}

export PRIMARY_DOMAIN="$(json '.primary_domain')"
export BASE_URL="$(json '.base_url')"
export SESSION_SECRET="$(json '.session_secret')"
export ADMIN_USERNAME="$(json '.admin_username')"
export ADMIN_PASSWORD="$(json '.admin_password')"
export OAUTH_ENABLED="$(json '.oauth_enabled')"
export OAUTH_PROVIDER_NAME="$(json '.oauth_provider_name')"
export OAUTH_CLIENT_ID="$(json_opt '.oauth_client_id')"
export OAUTH_CLIENT_SECRET="$(json_opt '.oauth_client_secret')"
export OAUTH_ISSUER="$(json_opt '.oauth_issuer')"
export OAUTH_AUTHORIZATION_URL="$(json_opt '.oauth_authorization_url')"
export OAUTH_TOKEN_URL="$(json_opt '.oauth_token_url')"
export OAUTH_USERINFO_URL="$(json_opt '.oauth_userinfo_url')"
export OAUTH_ALLOW_AUTO_LINKING="$(json '.oauth_allow_auto_linking')"

mkdir -p \
  "${CLICKHOUSE_DIR}/data" \
  "${CLICKHOUSE_DIR}/tmp" \
  "${CLICKHOUSE_DIR}/user_files" \
  "${CLICKHOUSE_DIR}/format_schemas" \
  "${CLICKHOUSE_DIR}/logs" \
  "${CADDY_DATA_DIR}" \
  "${CADDY_CONFIG_DIR}" \
  "${CADDY_LOG_DIR}" \
  "${WEB_DATA_DIR}" \
  /etc/clickhouse-server/config.d \
  /etc/clickhouse-server/users.d

cat > /etc/clickhouse-server/config.d/homeassistant.xml <<EOF
<clickhouse>
  <listen_host>127.0.0.1</listen_host>
  <http_port>8123</http_port>
  <tcp_port>9000</tcp_port>
  <path>${CLICKHOUSE_DIR}/data/</path>
  <tmp_path>${CLICKHOUSE_DIR}/tmp/</tmp_path>
  <user_files_path>${CLICKHOUSE_DIR}/user_files/</user_files_path>
  <format_schema_path>${CLICKHOUSE_DIR}/format_schemas/</format_schema_path>
  <logger>
    <log>${CLICKHOUSE_DIR}/logs/clickhouse-server.log</log>
    <errorlog>${CLICKHOUSE_DIR}/logs/clickhouse-server.err.log</errorlog>
    <level>warning</level>
  </logger>
</clickhouse>
EOF

cat > /etc/clickhouse-server/users.d/homeassistant.xml <<EOF
<clickhouse>
  <profiles>
    <default>
      <log_queries>0</log_queries>
    </default>
  </profiles>
  <users>
    <default>
      <password></password>
      <networks>
        <ip>127.0.0.1</ip>
        <ip>::1</ip>
      </networks>
      <access_management>1</access_management>
    </default>
  </users>
</clickhouse>
EOF

cat > "${CADDYFILE_PATH}" <<EOF
{
  admin 127.0.0.1:2019 {
    origins 127.0.0.1:2019 localhost:2019 localhost
  }
}

http://${PRIMARY_DOMAIN}, http://localhost {
  respond "Caddy Proxy Manager is running - configure proxy hosts via the web interface" 200
}
EOF

export NODE_ENV=production
export PORT=8099
export HOSTNAME=0.0.0.0
export NEXTAUTH_URL="${BASE_URL}"
export CADDY_API_URL="http://127.0.0.1:2019"
export DATABASE_PATH="${WEB_DATA_DIR}/caddy-proxy-manager.db"
export DATABASE_URL="file:${WEB_DATA_DIR}/caddy-proxy-manager.db"
export CERTS_DIRECTORY="${WEB_DATA_DIR}/certs"
export CLICKHOUSE_URL="http://127.0.0.1:8123"
export CLICKHOUSE_USER="default"
export CLICKHOUSE_PASSWORD=""
export CLICKHOUSE_DB="analytics"
export XDG_CONFIG_HOME="${CADDY_CONFIG_DIR}"
export XDG_DATA_HOME="${CADDY_DATA_DIR}"

/usr/bin/clickhouse server --config-file=/etc/clickhouse-server/config.xml &
CLICKHOUSE_PID=$!

for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8123/ping >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

caddy run --resume --config "${CADDYFILE_PATH}" --adapter caddyfile &
CADDY_PID=$!

for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:2019/config/ >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

(
  cd /opt/cpm-web
  exec bun server.js
) &
WEB_PID=$!

shutdown() {
  kill "${WEB_PID}" "${CADDY_PID}" "${CLICKHOUSE_PID}" 2>/dev/null || true
}

trap shutdown INT TERM

wait -n "${WEB_PID}" "${CADDY_PID}" "${CLICKHOUSE_PID}"
status=$?
shutdown
wait || true
exit "${status}"
