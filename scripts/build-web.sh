#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
emsdk_root="${Q4WASM_EMSDK:-${EMSDK_DIR:-}}"
jobs="${JOBS:-2}"
gamelibs_root="${OPENQ4_GAMELIBS_REPO:-}"
build_dir="${Q4WASM_WEB_BUILD_DIR:-${repo_root}/build/web-meson}"
web_dir="${Q4WASM_WEB_DIR:-${repo_root}/build/web}"
framework_dir="${Q4WASM_FRAMEWORK_DIR:-${repo_root}/../wasm-game-framework}"

framework_version="$(node -p "require('${framework_dir}/package.json').version")"
if [[ "${framework_version}" != "0.7.0" ]]; then
	echo "quake4-wasm requires wasm-game-framework 0.7.0, found ${framework_version}." >&2
	exit 1
fi

if command -v emcc >/dev/null 2>&1 && command -v em++ >/dev/null 2>&1; then
	:
elif [[ -n "${emsdk_root}" && -f "${emsdk_root}/emsdk_env.sh" ]]; then
	export EMSDK_QUIET=1
	source "${emsdk_root}/emsdk_env.sh"
else
	echo "Activate Emscripten first, or set Q4WASM_EMSDK/EMSDK_DIR to an emsdk checkout." >&2
	exit 1
fi
if [[ -z "${gamelibs_root}" || ! -d "${gamelibs_root}/src/game" || ! -d "${gamelibs_root}/src/mpgame" ]]; then
	echo "Set OPENQ4_GAMELIBS_REPO to a companion openQ4-game checkout containing src/game and src/mpgame." >&2
	exit 1
fi

if [[ -n "${OPENQ4_MESON:-}" ]]; then
	meson_cmd=("${OPENQ4_MESON}")
elif command -v meson >/dev/null 2>&1; then
	meson_cmd=(meson)
elif [[ -x "${repo_root}/.tmp/q4wasm-tools-wasm/bin/meson" ]]; then
	meson_cmd=("${repo_root}/.tmp/q4wasm-tools-wasm/bin/meson")
elif [[ -x "${repo_root}/.tmp/q4wasm-tools/bin/meson" ]] && "${repo_root}/.tmp/q4wasm-tools/bin/meson" --version >/dev/null 2>&1; then
	meson_cmd=("${repo_root}/.tmp/q4wasm-tools/bin/meson")
else
	echo "Meson is unavailable. Install Meson or set OPENQ4_MESON to its executable path." >&2
	exit 1
fi

export OPENQ4_GAMELIBS_REPO="${gamelibs_root}"

meson_args=(
	-Dplatform_backend=sdl3
	-Dq4wasm_client=true
	-Dbuild_engine=true
	-Dbuild_games=true
	-Dbuild_game_sp=true
	-Dbuild_game_mp=true
	-Dbuild_renderer_gl=false
	-Dbuild_renderer_vk=false
	-Duse_pch=false
	-Dglew:openq4_sdl3_loader=true
)

if [[ -f "${build_dir}/build.ninja" ]]; then
	"${meson_cmd[@]}" setup --reconfigure "${build_dir}" "${meson_args[@]}"
else
	"${meson_cmd[@]}" setup "${build_dir}" "${repo_root}" \
		--cross-file "${repo_root}/tools/cross/emscripten.ini" "${meson_args[@]}"
fi
ninja -C "${build_dir}" -j"${jobs}"

rm -rf "${web_dir}"
mkdir -p "${web_dir}/baseoq4"
cp "${build_dir}/openQ4-client_wasm32.js" "${web_dir}/openQ4-client_wasm32.js"
cp "${build_dir}/openQ4-client_wasm32.wasm" "${web_dir}/openQ4-client_wasm32.wasm"
cp "${build_dir}/baseoq4/game-sp_wasm32.wasm" "${web_dir}/baseoq4/game-sp_wasm32.wasm"
cp "${build_dir}/baseoq4/game-mp_wasm32.wasm" "${web_dir}/baseoq4/game-mp_wasm32.wasm"
cp "${build_dir}/baseoq4/pak0.pk4" "${web_dir}/baseoq4/pak0.pk4"
cp "${build_dir}/baseoq4/mod.json" "${web_dir}/baseoq4/mod.json"
cp "${build_dir}/baseoq4/pak1.pk4" "${web_dir}/baseoq4/pak1.pk4"
chmod 0644 "${web_dir}/baseoq4/pak0.pk4" "${web_dir}/baseoq4/pak1.pk4" "${web_dir}/baseoq4/mod.json"
cp "${repo_root}/docker/q4-worker.js" "${web_dir}/q4-worker.js"
cp "${repo_root}/docker/game-adapter.js" "${web_dir}/game-adapter.js"
cp "${repo_root}/docker/wasm-game.json" "${web_dir}/wasm-game.json"
cp "${repo_root}/docker/wasm-game-data.json" "${web_dir}/wasm-game-data.json"
cp "${repo_root}/assets/icons/quake4.ico" "${web_dir}/quake4.ico"
cp "${repo_root}/assets/icons/quake4.svg" "${web_dir}/quake4-pwa.svg"
cp "${repo_root}/assets/docs/img/banner.png" "${web_dir}/quake4-background.png"

metadata_dir="$(mktemp -d -t quake4-framework.XXXXXX)"
trap 'rm -rf -- "${metadata_dir}"' EXIT
"${framework_dir}/scripts/install-browser-package.sh" "${metadata_dir}" copy >/dev/null
cp "${metadata_dir}/wasm-game-framework.json" "${web_dir}/wasm-game-framework.json"

node --check "${web_dir}/openQ4-client_wasm32.js"
test "$(od -An -tx1 -N4 "${web_dir}/openQ4-client_wasm32.wasm" | tr -d ' \n')" = "0061736d"
test "$(od -An -tx1 -N4 "${web_dir}/baseoq4/game-sp_wasm32.wasm" | tr -d ' \n')" = "0061736d"
test "$(od -An -tx1 -N4 "${web_dir}/baseoq4/game-mp_wasm32.wasm" | tr -d ' \n')" = "0061736d"
node --check "${web_dir}/q4-worker.js"
node --check "${web_dir}/game-adapter.js"
cmp "${repo_root}/docker/q4-worker.js" "${web_dir}/q4-worker.js"
cmp "${repo_root}/docker/game-adapter.js" "${web_dir}/game-adapter.js"
test "$(md5sum "${web_dir}/baseoq4/pak0.pk4" | awk '{print $1}')" = "17550cb028326cdf1cee440bc5d73d74"
test "$(md5sum "${web_dir}/baseoq4/pak1.pk4" | awk '{print $1}')" = "c3434e1d28bebdc367d6e50f3b1fda3a"
test "$(stat -c '%s' "${web_dir}/baseoq4/pak0.pk4")" = "4285437"
test "$(stat -c '%s' "${web_dir}/baseoq4/pak1.pk4")" = "641646791"
unzip -tqq "${web_dir}/baseoq4/pak0.pk4"
unzip -tqq "${web_dir}/baseoq4/pak1.pk4"
test ! -e "${web_dir}/index.html"
test ! -e "${web_dir}/app.webmanifest"
test ! -e "${web_dir}/service-worker.js"

printf 'Built retail-data-free Quake 4 web checkpoint:\n'
printf '  %s (%s bytes)\n' "${web_dir}/openQ4-client_wasm32.js" "$(stat -c '%s' "${web_dir}/openQ4-client_wasm32.js")"
printf '  %s (%s bytes)\n' "${web_dir}/openQ4-client_wasm32.wasm" "$(stat -c '%s' "${web_dir}/openQ4-client_wasm32.wasm")"
printf '  %s (%s bytes)\n' "${web_dir}/baseoq4/game-sp_wasm32.wasm" "$(stat -c '%s' "${web_dir}/baseoq4/game-sp_wasm32.wasm")"
printf '  %s (%s bytes)\n' "${web_dir}/baseoq4/game-mp_wasm32.wasm" "$(stat -c '%s' "${web_dir}/baseoq4/game-mp_wasm32.wasm")"
printf '  %s (%s bytes)\n' "${web_dir}/baseoq4/pak0.pk4" "$(stat -c '%s' "${web_dir}/baseoq4/pak0.pk4")"
printf '  %s (%s bytes)\n' "${web_dir}/baseoq4/pak1.pk4" "$(stat -c '%s' "${web_dir}/baseoq4/pak1.pk4")"
printf 'Retail q4base PK4s are provisioned under /data and browser-cached by the framework; they are not copied into build/web.\n'
