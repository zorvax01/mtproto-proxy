# MTProto proxy — Telemt (Rust) with FakeTLS
# Listens on 443 inside the container. Railway exposes it via TCP Proxy
# (Settings → Networking → TCP Proxy, internal port 443).
# No secret is baked into this image. SECRET / TAG / TLS_DOMAIN come from
# Railway environment variables only; entrypoint.sh writes config.toml
# from them at container start.
FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /tmp/telemt-extract \
    && curl -fsSL -o /tmp/telemt.tar.gz \
        https://github.com/telemt/telemt/releases/latest/download/telemt-x86_64-linux-gnu.tar.gz \
    && tar -xzf /tmp/telemt.tar.gz -C /tmp/telemt-extract \
    && cp "$(find /tmp/telemt-extract -name telemt -type f | head -n 1)" /usr/local/bin/telemt \
    && chmod +x /usr/local/bin/telemt \
    && rm -rf /tmp/telemt.tar.gz /tmp/telemt-extract \
    && ls -l /usr/local/bin/telemt

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

WORKDIR /app
EXPOSE 443
ENTRYPOINT ["/app/entrypoint.sh"]
