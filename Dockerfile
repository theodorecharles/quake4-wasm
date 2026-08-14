# syntax=docker/dockerfile:1.7

ARG FRAMEWORK_IMAGE=wasm-game-framework:0.7.0
FROM ${FRAMEWORK_IMAGE}

ARG VCS_REF=unknown
ARG GAMELIBS_REF=0c9c121ff337b1c6df129ecedcfe569e7c50c332
LABEL org.opencontainers.image.title="Quake 4 WASM client checkpoint" \
      org.opencontainers.image.description="Quake 4 Emscripten client artifact checkpoint; no retail q4base data" \
      org.opencontainers.image.source="https://github.com/theodorecharles/quake4-wasm" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.vendor="theodorecharles"

COPY build/web/ /opt/game-site/
COPY LICENSE /opt/game-site/OPENQ4-ENGINE-LICENSE
COPY docs/REDISTRIBUTION.md /opt/game-site/REDISTRIBUTION.md
COPY docs/QUAKE4-SDK-EULA.rtf /opt/game-site/QUAKE4-SDK-EULA.rtf

RUN mkdir -p /data/q4base /data/custom_maps \
    && printf '%s\n' \
        'This is an owner-approved Quake 4 browser-client checkpoint; no retail q4base data is included.' \
        'The engine source is available at https://github.com/theodorecharles/quake4-wasm/tree/'"${VCS_REF}"'.' \
        'Compiled SDK-derived game modules from revision '"${GAMELIBS_REF}"' are included under the recorded owner decision.' \
        'The accompanying SDK EULA is available at /QUAKE4-SDK-EULA.rtf.' \
        'Retail q4base remains user-supplied through /data.' \
        'See /REDISTRIBUTION.md for the engineering evidence record.' \
        > /opt/game-site/REDISTRIBUTION-GATE.txt \
    && printf '%s\n' \
        'Corresponding source for this engine checkpoint:' \
        "https://github.com/theodorecharles/quake4-wasm/tree/${VCS_REF}" \
        'This image contains engine/runtime code and approved SDK-derived modules; supply proprietary Quake 4 data through /data.' \
        > /opt/game-site/SOURCE-OFFER.txt

ENV WASM_GAME_VARIANT=suite

VOLUME ["/data"]
EXPOSE 8088/tcp
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8088/ >/dev/null
