#!/bin/sh
# Build /app/config.toml for Telemt from Railway env vars and run it.
# SECRET: 32 lowercase hex chars (the per-user secret, NOT the ee link secret)
# TAG:    optional 32-hex ad tag from @MTProxybot (sponsored channel)
# TLS_DOMAIN: FakeTLS/SNI mask domain, default google.com
set -e

: "${SECRET:?SECRET env var is required}"
TLS_DOMAIN="${TLS_DOMAIN:-google.com}"

mkdir -p /app/tlsfront

{
  echo "[general]"
  # Middle proxy is REQUIRED for the sponsored channel (ad_tag), but it adds
  # an extra hop through Telegram's intermediate servers and makes media
  # much slower. With no TAG set, go direct to the DCs (faster, more
  # reliable). When TAG is set later, middle proxy turns on automatically.
  if [ -n "${TAG:-}" ]; then
    echo "use_middle_proxy = true"
  else
    echo "use_middle_proxy = false"
  fi
  if [ -n "${TAG:-}" ]; then
    echo "ad_tag = \"$TAG\""
  fi
  echo "log_level = \"normal\""
  echo ""
  echo "[general.modes]"
  echo "classic = false"
  echo "secure = false"
  echo "tls = true"
  echo ""
  echo "[general.links]"
  echo "show = \"*\""
  echo ""
  echo "[server]"
  echo "port = 443"
  echo ""
  echo "[server.api]"
  echo "enabled = true"
  echo "listen = \"127.0.0.1:9091\""
  echo "whitelist = [\"127.0.0.1/32\", \"::1/128\"]"
  echo "minimal_runtime_enabled = false"
  echo "minimal_runtime_cache_ttl_ms = 1000"
  echo ""
  echo "[[server.listeners]]"
  echo "ip = \"0.0.0.0\""
  echo ""
  echo "[censorship]"
  echo "tls_domain = \"$TLS_DOMAIN\""
  echo "mask = true"
  echo "tls_emulation = true"
  echo "tls_front_dir = \"tlsfront\""
  echo ""
  echo "[access.users]"
  echo "user = \"$SECRET\""
} > /app/config.toml

cd /app
exec /usr/local/bin/telemt /app/config.toml
