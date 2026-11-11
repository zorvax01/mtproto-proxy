# mtproto-proxy — Telegram MTProto Proxy on Railway (FakeTLS, Amsterdam)

Telemt (Rust) MTProto proxy with FakeTLS, deployed on Railway with Docker,
exposed via Railway TCP Proxy (raw TCP, port 443 inside the container).
Region: EU West, Amsterdam — close to Telegram's DC2/DC4 in Amsterdam.

FakeTLS makes the traffic look like an ordinary TLS connection to the
mask domain, which is much harder for DPI to detect and throttle than a
plain (`dd`) MTProto secret. MTProto only proxies Telegram traffic — it
is not a general VPN/SOCKS proxy.

## Environment variables (set in Railway → Variables, never in this repo)

| Variable | Description | Required |
| --- | --- | --- |
| `SECRET` | 32 lowercase hex chars (16 bytes), e.g. generated with `openssl rand -hex 16`. This is the per-user secret; the `ee` link secret is derived from it + the domain. | Yes |
| `TLS_DOMAIN` | FakeTLS/SNI mask domain, e.g. `google.com` | No (default `google.com`) |
| `TAG` | Advertisement tag from `@MTProxybot` — enables the sponsored channel | No |

The secret is **not** in this repo. The `TAG` is not persistent inside the
container, so it must stay set as a Railway variable on every run.
Changing `TLS_DOMAIN` breaks old links — the domain is embedded in the
`ee` secret.

## The link

```
https://t.me/proxy?server=HOST&port=PORT&secret=eeSECRET<hex of TLS_DOMAIN>
tg://proxy?server=HOST&port=PORT&secret=eeSECRET<hex of TLS_DOMAIN>
```

For `TLS_DOMAIN=google.com`, the tail is `676f6f676c652e636f6d` (hex of
`google.com`), so the link secret is `ee` + `SECRET` + `676f6f676c652e636f6d`.
Telemt also prints the exact link in the deployment logs at startup.

No Railway HTTP domain is needed for MTProto. A normal `*.up.railway.app`
domain is HTTP-only and will not work for this proxy — MTProto needs raw
TCP, so TCP Proxy is the correct exposure. A custom domain can later be
CNAME-pointed at the TCP proxy domain (DNS only, no Cloudflare proxying),
keeping Railway's port.

## Deploy on Railway

1. Create a new service in Railway from this GitHub repo.
2. Set `SECRET` (and `TLS_DOMAIN=google.com`) in Variables.
3. Set the service region to EU West (Amsterdam) in Settings → Region.
4. Go to service Settings → Networking → TCP Proxy, add a TCP proxy with
   internal port `443`. Railway gives you a public host + port, e.g.
   `xxx.proxy.rlwy.net:12345`.
5. Build the proxy link from the host, port and the `ee` secret above.

## Sponsored channel (TAG) — how to set it yourself

1. Deploy the proxy first and copy the TCP host, port and `ee` secret.
2. In Telegram open `@MTProxybot` and send `/newproxy`.
3. Give it the host, port and secret. The bot replies with a `TAG`
   (32 hex chars).
4. Paste that `TAG` into Railway → Variables for this service and redeploy.
   The entrypoint writes it into the Telemt config as `ad_tag`.
5. Manage / change the sponsored channel from `@MTProxybot` afterwards —
   the channel is bound to the tag there, not in this repo.

To remove the sponsor, delete the `TAG` variable in Railway and redeploy.

## Why Telemt and not the official image or mtg

- The official `telegrammessenger/proxy` image (2020) has no FakeTLS.
- `mtg` v2 removed adtag support entirely, so the sponsored channel
  would stop working; its author recommends Telemt for adtag use.
- Telemt supports FakeTLS (`tls = true`) and `ad_tag`, and is actively
  maintained. `use_middle_proxy` is on only when a `TAG` is set: the
  sponsored channel only works through Telegram's middle proxies, which
  add an extra hop and make media/uploads slower, so with no tag the
  proxy connects directly to the DCs (faster, more reliable).

## Notes

- Telethon (Python) cannot test a FakeTLS (`ee`) proxy — it does not do
  the FakeTLS handshake. Verify an `ee` proxy with the real Telegram app.
  From a shell you can still check the port answers a TLS ClientHello.
- Railway TCP traffic is billed as network egress, so keep an eye on the
  trial ($5 / 30 days) usage.
- Changing the region does not change the TCP Proxy domain/port, but
  always confirm the endpoint shown in Settings after a move.
