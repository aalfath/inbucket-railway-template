#!/bin/sh
# Starts Inbucket on localhost and Caddy (basic auth) on $PORT.
set -eu

if [ -z "${INBUCKET_PASSWORD:-}" ]; then
  echo "INBUCKET_PASSWORD is not set: refusing to expose Inbucket without a login." >&2
  exit 1
fi

export PORT="${PORT:-8080}"
export INBUCKET_USERNAME="${INBUCKET_USERNAME:-admin}"

# Inbucket listens only on localhost for HTTP; Caddy is the public entry.
export INBUCKET_WEB_ADDR="127.0.0.1:9000"
# SMTP and POP3 listen on all interfaces (IPv4 and IPv6, for Railway's
# private network and the TCP proxy).
export INBUCKET_SMTP_ADDR="${INBUCKET_SMTP_ADDR:-:2500}"
export INBUCKET_POP3_ADDR="${INBUCKET_POP3_ADDR:-:1100}"

# Mail is stored on the Railway volume mounted at /storage.
export INBUCKET_STORAGE_TYPE="${INBUCKET_STORAGE_TYPE:-file}"
export INBUCKET_STORAGE_PARAMS="${INBUCKET_STORAGE_PARAMS:-path:/storage}"
mkdir -p /storage /config

# Session cookie key: use the template's generated secret, else keep a
# random one on the volume (never the image's fixed default).
if [ -z "${INBUCKET_WEB_COOKIEAUTHKEY:-}" ] || [ "${INBUCKET_WEB_COOKIEAUTHKEY}" = "secret-inbucket-session-cookie-key" ]; then
  if [ ! -s /storage/.cookie-auth-key ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > /storage/.cookie-auth-key
  fi
  INBUCKET_WEB_COOKIEAUTHKEY="$(cat /storage/.cookie-auth-key)"
  export INBUCKET_WEB_COOKIEAUTHKEY
fi

INBUCKET_PASSWORD_HASH="$(caddy hash-password --plaintext "$INBUCKET_PASSWORD")"
export INBUCKET_PASSWORD_HASH

/start-inbucket.sh -logjson &
INBUCKET_PID=$!
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill -TERM "$INBUCKET_PID" "$CADDY_PID" 2>/dev/null' INT TERM

# Exit (so Railway restarts the container) as soon as either process stops.
while kill -0 "$INBUCKET_PID" 2>/dev/null && kill -0 "$CADDY_PID" 2>/dev/null; do
  sleep 2
done
echo "A process exited; stopping the container." >&2
kill -TERM "$INBUCKET_PID" "$CADDY_PID" 2>/dev/null || true
wait || true
exit 1
