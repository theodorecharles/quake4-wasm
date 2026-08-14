#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="${IMAGE_REPO:-theodorecharles/quake4-wasm}:${IMAGE_TAG:-checkpoint}"

for artifact in \
  build/web/openQ4-client_wasm32.js \
  build/web/openQ4-client_wasm32.wasm \
  build/web/baseoq4/game-sp_wasm32.wasm \
  build/web/baseoq4/game-mp_wasm32.wasm; do
  test -s "$repo_root/$artifact" || {
    echo "Missing $artifact; run scripts/build-web.sh first." >&2
    exit 1
  }
done

if find "$repo_root/build/web" -type f \( -iname '*.pk4' -o -iname '*.pak' \) -print -quit | grep -q .; then
  echo "Refusing to build: retail or packaged game data found under build/web." >&2
  exit 1
fi

unexpected_file="$(find "$repo_root/build/web" -type f ! \( \
  -path "$repo_root/build/web/openQ4-client_wasm32.js" -o \
  -path "$repo_root/build/web/openQ4-client_wasm32.wasm" -o \
  -path "$repo_root/build/web/baseoq4/game-sp_wasm32.wasm" -o \
  -path "$repo_root/build/web/baseoq4/game-mp_wasm32.wasm" \
\) -print -quit)"
if [[ -n "$unexpected_file" ]]; then
  echo "Refusing to build: unexpected file under build/web: $unexpected_file" >&2
  exit 1
fi

docker build --platform linux/amd64 \
  --build-arg "VCS_REF=$(git -C "$repo_root" rev-parse HEAD)" \
  --tag "$image" "$repo_root"
echo "Built $image (browser-client checkpoint; no retail q4base data)"
