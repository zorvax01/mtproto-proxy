# mtproto-proxy — Telegram MTProto Proxy on Railway

Official Telegram MTProto proxy (`telegrammessenger/proxy:1.4`), deployed
on Railway with Docker, exposed via Railway TCP Proxy (raw TCP, port 443
inside the container). Region: US West.

MTProto only proxies Telegram traffic — it is not a general VPN/SOCKS proxy.

## Environment variables (set in Railway → Variables, never in this repo)

| Variable | Description | Required |
| --- | --- | --- |
| `SECRET` | 32 lowercase hex chars (16 bytes), e.g. generated with `openssl rand -hex 16` | Yes |
| `TAG` | Advertisement tag from `@MTProxybot` — enables the sponsored channel | No |
| `WORKERS` | Worker processes (default `2`) | No |

The secret is **not** in this repo. The `TAG` is not persistent inside the
container, so it must stay set as a Railway variable on every run.

## Deploy on Railway

1. Create a new service in Railway from this GitHub repo.
2. Set `SECRET` in Variables (and `WORKERS=2` if you want).
3. Set the service region to US West in Settings → Region.
4. Go to service Settings → Networking → TCP Proxy, add a TCP proxy with
   internal port `443`. Railway gives you a public host + port, e.g.
   `xxx.proxy.rlwy.net:12345`.
5. Your proxy link is:

   ```
   https://t.me/proxy?server=HOST&port=PORT&secret=ddSECRET
   tg://proxy?server=HOST&port=PORT&secret=ddSECRET
   ```

   Note the `dd` prefix in the link only — the `SECRET` variable itself has
   no `dd` prefix.

No Railway HTTP domain is needed for MTProto. A normal `*.up.railway.app`
domain is HTTP-only and will not work for this proxy — TCP Proxy is the
correct exposure. A custom domain can later be CNAME-pointed at the TCP
proxy domain (DNS only, no Cloudflare proxying), keeping Railway's port.

## Sponsored channel (TAG) — how to set it yourself

1. Deploy the proxy first and copy the TCP host, port and `SECRET`.
2. In Telegram open `@MTProxybot` and send `/newproxy`.
3. Give it the host, port and secret. The bot replies with a `TAG`
   (32 hex chars).
4. Paste that `TAG` into Railway → Variables for this service and redeploy.
5. Manage / change the sponsored channel from `@MTProxybot` afterwards —
   the channel is bound to the tag there, not in this repo.

To remove the sponsor, delete the `TAG` variable in Railway and redeploy.

## History

- First version: this official image, US West, plain `dd` secret. It worked
  for media; messages had ~1s drops every ~10s, suspected Iran DPI.
- A Telemt FakeTLS version in Amsterdam (Nov 2026) was tried to fix the
  drops, but media downloads stalled even in direct mode (no middle
  proxy). Reverted to this official-image US West setup, which is the
  known-good baseline for media. FakeTLS and region can be re-tested one
  variable at a time later if wanted.

## Notes

- The official image fetches Telegram core IPs at container start, so
  restart the service about once a day to keep them fresh.
- Stats are only on localhost inside the container (`http://localhost:2398/stats`).
- Railway TCP traffic is billed as network egress, so keep an eye on the
  trial ($5 / 30 days) usage.
