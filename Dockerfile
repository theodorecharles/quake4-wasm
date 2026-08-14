# syntax=docker/dockerfile:1.7

FROM nginx:1.27-alpine

ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="Quake 4 WASM client checkpoint" \
      org.opencontainers.image.description="Quake 4 Emscripten client artifact checkpoint; no retail q4base data" \
      org.opencontainers.image.source="https://github.com/theodorecharles/quake4-wasm" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.vendor="theodorecharles"

COPY build/web/ /usr/share/nginx/html/
COPY docker/index.html /usr/share/nginx/html/index.html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY LICENSE /usr/share/nginx/html/OPENQ4-ENGINE-LICENSE
COPY docs/REDISTRIBUTION.md /usr/share/nginx/html/REDISTRIBUTION.md

RUN mkdir -p /data/q4base /data/custom_maps \
    && printf '%s\n' \
        'This is a Quake 4 browser-client checkpoint, not a public release.' \
        'The engine source is available at https://github.com/theodorecharles/quake4-wasm/tree/'"${VCS_REF}"'.' \
        'SDK-derived game-library source and its redistribution terms are not included in this image.' \
        'See /REDISTRIBUTION.md; do not publish until that gate is closed.' \
        > /usr/share/nginx/html/REDISTRIBUTION-GATE.txt

VOLUME ["/data"]
EXPOSE 8088/tcp 28004/udp
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8088/health >/dev/null
