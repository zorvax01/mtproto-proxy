# MTProto proxy — official Telegram image + internal stats server
# Listens on 443 inside the container. Railway exposes it via TCP Proxy
# (Settings → Networking → TCP Proxy, internal port 443).
# No secret is baked into this image. SECRET / TAG / WORKERS come from
# Railway environment variables only.
#
# The stats server (stats_server.pl, Perl core only) listens on 8080 on
# the Railway private network (mtproto-proxy.railway.internal:8080) and
# serves {"inbound":N,"rx":R,"tx":T}. No public domain is attached to
# port 8080, so it is only reachable from other services in this project.
FROM telegrammessenger/proxy:1.4

COPY stats_server.pl /usr/local/bin/stats_server.pl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/stats_server.pl /entrypoint.sh

EXPOSE 443 8080
ENTRYPOINT ["/entrypoint.sh"]
