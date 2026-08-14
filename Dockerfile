# syntax=docker/dockerfile:1.7

FROM nginx:1.27-alpine

ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="Quake 4 WASM checkpoint" \
      org.opencontainers.image.description="Quake 4 native-only redistribution-gate status image; not a playable WASM release" \
      org.opencontainers.image.source="https://github.com/theodorecharles/quake4-wasm" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.vendor="theodorecharles"

COPY docker/index.html /usr/share/nginx/html/index.html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /data/q4base /data/custom_maps

VOLUME ["/data"]
EXPOSE 8088/tcp 28004/udp
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8088/health >/dev/null
