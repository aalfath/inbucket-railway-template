# Inbucket for Railway: the official Inbucket image plus a small Caddy proxy
# that puts HTTP basic auth in front of Inbucket's web UI and REST API
# (Inbucket has no login of its own).

# Caddy binary only (pinned).
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

# Official Inbucket image (pinned).
FROM inbucket/inbucket:3.2.0@sha256:48063d73be66889d95c43a6ee18ed5db08e3ad01196d8f7aa1e7f1e6e4625d93

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY railway-start.sh /railway-start.sh
RUN chmod 0755 /railway-start.sh

# 8080: web UI (through Caddy), 2500: SMTP, 1100: POP3
EXPOSE 8080 2500 1100

ENTRYPOINT ["/railway-start.sh"]
