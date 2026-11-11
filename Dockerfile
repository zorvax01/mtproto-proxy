# MTProto proxy — official Telegram image
# Listens on 443 inside the container. Railway exposes it via TCP Proxy
# (Settings → Networking → TCP Proxy, internal port 443).
# No secret is baked into this image. SECRET / TAG / WORKERS come from
# Railway environment variables only.
FROM telegrammessenger/proxy:1.4

EXPOSE 443
