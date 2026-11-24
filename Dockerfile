# Stage 1: official Xray image (binary only, no shell)
# NOTE: in ghcr.io/xtls/xray-core:1.8.21 the binary lives at /usr/bin/xray
# (see XTLS/Xray-core v1.8.21 .github/docker/Dockerfile)
FROM ghcr.io/xtls/xray-core:1.8.21 AS xray

# Stage 2: minimal Alpine runtime
FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=xray /usr/bin/xray /usr/local/bin/xray
COPY config.json /etc/xray/config.json
EXPOSE 3000
# Inject the UUID and WireGuard env vars into the config at container start, then run xray.
# (No separate shell script file: avoids shebang/CRLF startup failures.)
# WG secrets stay in env vars (Vexlo), never committed: WG_PRIVATE_KEY, WG_PUBLIC_KEY, WG_ENDPOINT.
ENTRYPOINT ["sh", "-c", "sed -i \"s/__UUID__/${UUID:?UUID env var is required}/;s|__WG_PRIVATE_KEY__|${WG_PRIVATE_KEY:?WG_PRIVATE_KEY env var is required}|;s|__WG_PUBLIC_KEY__|${WG_PUBLIC_KEY:?WG_PUBLIC_KEY env var is required}|;s|__WG_ENDPOINT__|${WG_ENDPOINT:?WG_ENDPOINT env var is required}|\" /etc/xray/config.json && exec /usr/local/bin/xray run -config /etc/xray/config.json"]
