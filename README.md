# Inbucket on Railway

A Railway template for [Inbucket](https://www.inbucket.org/) **3.2.0**, a disposable email testing service. Inbucket accepts every message sent to its SMTP server, stores it without delivering it, and lets you read it in a web UI, through its REST API or over POP3.

## What the template deploys

One service, built from this repo:

- `Dockerfile`: `inbucket/inbucket:3.2.0` (pinned by digest) plus the `caddy` binary from `caddy:2.11.9-alpine` (pinned by digest).
- `railway-start.sh`: starts Inbucket on `127.0.0.1:9000` and Caddy on `$PORT` (8080). Inbucket's web UI has no login of its own, so Caddy adds HTTP basic auth in front of the UI and the REST API.
- `Caddyfile`: basic auth for everything except `/healthz`, which Railway's health check uses. It only returns the UI's empty page, no mail.
- A volume at `/storage` holds the mail (Inbucket's `file` storage).

| Port | What | How to reach it |
|---|---|---|
| 8080 | Web UI and REST API (basic auth) | The service's Railway domain |
| 2500 | SMTP, no auth, accepts any recipient | Private network: `inbucket.railway.internal:2500` (`${{Inbucket.RAILWAY_PRIVATE_DOMAIN}}`), or the TCP proxy shown in the service's Networking settings |
| 1100 | POP3 | Private network only |

## Variables

| Variable | Default | What it does |
|---|---|---|
| `PORT` | `8080` | Port Caddy listens on (the public web port) |
| `INBUCKET_USERNAME` | `admin` | Basic-auth user for the web UI and API |
| `INBUCKET_PASSWORD` | generated secret | Basic-auth password. The container refuses to start without it |
| `INBUCKET_WEB_COOKIEAUTHKEY` | generated secret | Key for Inbucket's session cookie |

Any other [Inbucket setting](https://github.com/inbucket/inbucket/blob/main/doc/config.md) can be added as a variable, for example `INBUCKET_STORAGE_RETENTIONPERIOD` (default `72h`), `INBUCKET_STORAGE_MAILBOXMSGCAP` (default `300`) or `INBUCKET_SMTP_DEFAULTACCEPT` with `INBUCKET_SMTP_ACCEPTDOMAINS` to only accept certain domains.

## Using it

- Point your app's SMTP settings at `${{Inbucket.RAILWAY_PRIVATE_DOMAIN}}` port `2500`, with no TLS and no auth (any user and password are accepted).
- Open the service's domain and log in with `INBUCKET_USERNAME` and `INBUCKET_PASSWORD` (see the service's Variables tab). Type a mailbox name (the part before `@`) to read its mail, or open the Monitor tab to see everything as it arrives.
- REST API with the same login, for example `curl -u admin:YOUR-PASSWORD https://YOUR-DOMAIN/api/v1/mailbox/alice`.

Inbucket never delivers mail to real addresses. The public SMTP port (TCP proxy) accepts mail from anyone who knows its address, so remove the TCP proxy if you only send from inside Railway.

## Updates

Updates are merged to `main` here. Railway shows deployers of this template an "update available" notice, and they choose when to apply it. Each version is listed in [CHANGELOG.md](CHANGELOG.md), breaking changes first.
