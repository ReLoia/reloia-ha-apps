#!/bin/sh
set -e

OPTS=/data/options.json
# Print an option's value; empty string if unset. Booleans print "true"/"false".
opt() { node -e "const v=require('$OPTS')['$1']; console.log(v ?? '')"; }

export APP_BASE_URL="$(opt base_url)"

SECRET="$(opt auth_secret)"
if [ -z "$SECRET" ]; then
  if [ ! -f /data/auth_secret ]; then
    node -e "console.log(require('crypto').randomBytes(48).toString('hex'))" > /data/auth_secret
  fi
  SECRET="$(cat /data/auth_secret)"
fi
export AUTH_SECRET="$SECRET"

mkdir -p /data/db /data/documents
export DATABASE_URL="file:/data/db/db.sqlite"
export DOCUMENT_STORAGE_FILESYSTEM_ROOT="/data/documents"

# --- Email (SMTP) ---
if [ "$(opt smtp_enabled)" = "true" ]; then
  if [ -z "$(opt smtp_host)" ]; then
    echo "smtp_enabled is true but smtp_host is empty" >&2
    exit 1
  fi
  export EMAILS_DRIVER=smtp
  export SMTP_HOST="$(opt smtp_host)"
  export SMTP_PORT="$(opt smtp_port)"
  export SMTP_SECURE="$(opt smtp_secure)"
  [ -n "$(opt smtp_user)" ]     && export SMTP_USER="$(opt smtp_user)"
  [ -n "$(opt smtp_password)" ] && export SMTP_PASSWORD="$(opt smtp_password)"
  # Sender address: verify the variable name in Papra's configuration reference
  [ -n "$(opt smtp_from)" ]     && export EMAILS_FROM_ADDRESS="$(opt smtp_from)"
fi

REG="$(opt registration_enabled)"
export AUTH_IS_REGISTRATION_ENABLED="${REG:-true}"

[ -n "$(opt ocr_languages)" ] && export DOCUMENTS_OCR_LANGUAGES="$(opt ocr_languages)"

eval "$(node -e '
const o = require("/data/options.json");
for (const e of (o.env_vars || [])) {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(e.name)) continue;
  console.log("export " + e.name + "=\x27" + String(e.value).replace(/\x27/g, "\x27\\\x27\x27") + "\x27");
}')"

exec docker-entrypoint.sh pnpm start:with-migrations
