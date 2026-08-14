#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image_repo="${IMAGE_REPO:-theodorecharles/quake4-wasm}"
image_tag="${IMAGE_TAG:-dev}"
framework_dir="${Q4WASM_FRAMEWORK_DIR:-${repo_root}/../wasm-game-framework}"

for artifact in \
  build/web/openQ4-client_wasm32.js \
  build/web/openQ4-client_wasm32.wasm \
  build/web/baseoq4/game-sp_wasm32.wasm \
  build/web/baseoq4/game-mp_wasm32.wasm \
  build/web/baseoq4/pak0.pk4 \
  build/web/baseoq4/pak1.pk4 \
  build/web/baseoq4/mod.json \
  build/web/q4-worker.js \
  build/web/game-adapter.js \
  build/web/wasm-game.json \
  build/web/wasm-game-data.json \
  build/web/wasm-game-framework.json \
  build/web/quake4.ico \
  build/web/quake4-pwa.svg \
  build/web/quake4-background.png; do
  test -s "$repo_root/$artifact" || {
    echo "Missing $artifact; run scripts/build-web.sh first." >&2
    exit 1
  }
done

test "$(md5sum "$repo_root/build/web/baseoq4/pak0.pk4" | awk '{print $1}')" = "17550cb028326cdf1cee440bc5d73d74"
test "$(md5sum "$repo_root/build/web/baseoq4/pak1.pk4" | awk '{print $1}')" = "c3434e1d28bebdc367d6e50f3b1fda3a"
test "$(stat -c '%s' "$repo_root/build/web/baseoq4/pak0.pk4")" = "4285437"
test "$(stat -c '%s' "$repo_root/build/web/baseoq4/pak1.pk4")" = "641646791"
unzip -tqq "$repo_root/build/web/baseoq4/pak0.pk4"
unzip -tqq "$repo_root/build/web/baseoq4/pak1.pk4"

unexpected_package="$(find "$repo_root/build/web" -type f \( -iname '*.pk4' -o -iname '*.pak' \) ! -path "$repo_root/build/web/baseoq4/pak0.pk4" ! -path "$repo_root/build/web/baseoq4/pak1.pk4" -print -quit)"
if [[ -n "$unexpected_package" ]]; then
  echo "Refusing to build: unexpected game package under build/web: $unexpected_package" >&2
  exit 1
fi

unexpected_file="$(find "$repo_root/build/web" -type f ! \( \
  -path "$repo_root/build/web/openQ4-client_wasm32.js" -o \
  -path "$repo_root/build/web/openQ4-client_wasm32.wasm" -o \
  -path "$repo_root/build/web/baseoq4/game-sp_wasm32.wasm" -o \
  -path "$repo_root/build/web/baseoq4/game-mp_wasm32.wasm" -o \
  -path "$repo_root/build/web/baseoq4/pak0.pk4" -o \
  -path "$repo_root/build/web/baseoq4/pak1.pk4" -o \
  -path "$repo_root/build/web/baseoq4/mod.json" -o \
  -path "$repo_root/build/web/q4-worker.js" -o \
  -path "$repo_root/build/web/game-adapter.js" -o \
  -path "$repo_root/build/web/wasm-game.json" -o \
  -path "$repo_root/build/web/wasm-game-data.json" -o \
  -path "$repo_root/build/web/wasm-game-framework.json" -o \
  -path "$repo_root/build/web/quake4.ico" -o \
  -path "$repo_root/build/web/quake4-pwa.svg" -o \
  -path "$repo_root/build/web/quake4-background.png" \
\) -print -quit)"
if [[ -n "$unexpected_file" ]]; then
  echo "Refusing to build: unexpected file under build/web: $unexpected_file" >&2
  exit 1
fi

for variant in suite quake4 quake4-mp; do
  if [[ "$variant" == suite ]]; then
    image="${image_repo}:${image_tag}"
  else
    image="${image_repo}:${variant}-${image_tag}"
  fi
  "${framework_dir}/scripts/build-static-image.sh" "$repo_root/build/web" "$image" "$variant"
done
echo "Built Quake 4 suite plus quake4 and quake4-mp locked images (no retail q4base data)."
