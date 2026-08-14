#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
emsdk_root="${Q4WASM_EMSDK:-/home/ted/emsdk}"
jobs="${JOBS:-2}"
gamelibs_root="${OPENQ4_GAMELIBS_REPO:-}"
build_dir="${Q4WASM_WEB_BUILD_DIR:-${repo_root}/build/web-meson}"
web_dir="${Q4WASM_WEB_DIR:-${repo_root}/build/web}"

if [[ ! -f "${emsdk_root}/emsdk_env.sh" ]]; then
	echo "Emscripten environment not found: ${emsdk_root}/emsdk_env.sh" >&2
	exit 1
fi
if [[ -z "${gamelibs_root}" || ! -d "${gamelibs_root}/src/game" || ! -d "${gamelibs_root}/src/mpgame" ]]; then
	echo "Set OPENQ4_GAMELIBS_REPO to a companion openQ4-game checkout containing src/game and src/mpgame." >&2
	exit 1
fi

if [[ -n "${OPENQ4_MESON:-}" ]]; then
	meson_cmd=("${OPENQ4_MESON}")
elif [[ -x "${repo_root}/.tmp/q4wasm-tools/bin/meson" ]]; then
	meson_cmd=("${repo_root}/.tmp/q4wasm-tools/bin/meson")
else
	meson_cmd=(meson)
fi

export EMSDK_QUIET=1
source "${emsdk_root}/emsdk_env.sh"
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

mkdir -p "${web_dir}/baseoq4"
cp "${build_dir}/openQ4-client_wasm32.js" "${web_dir}/openQ4-client_wasm32.js"
cp "${build_dir}/openQ4-client_wasm32.wasm" "${web_dir}/openQ4-client_wasm32.wasm"
cp "${build_dir}/baseoq4/game-sp_wasm32.wasm" "${web_dir}/baseoq4/game-sp_wasm32.wasm"
cp "${build_dir}/baseoq4/game-mp_wasm32.wasm" "${web_dir}/baseoq4/game-mp_wasm32.wasm"

node --check "${web_dir}/openQ4-client_wasm32.js"
test "$(od -An -tx1 -N4 "${web_dir}/openQ4-client_wasm32.wasm" | tr -d ' \n')" = "0061736d"
test "$(od -An -tx1 -N4 "${web_dir}/baseoq4/game-sp_wasm32.wasm" | tr -d ' \n')" = "0061736d"
test "$(od -An -tx1 -N4 "${web_dir}/baseoq4/game-mp_wasm32.wasm" | tr -d ' \n')" = "0061736d"

printf 'Built retail-data-free Quake 4 web checkpoint:\n'
printf '  %s (%s bytes)\n' "${web_dir}/openQ4-client_wasm32.js" "$(stat -c '%s' "${web_dir}/openQ4-client_wasm32.js")"
printf '  %s (%s bytes)\n' "${web_dir}/openQ4-client_wasm32.wasm" "$(stat -c '%s' "${web_dir}/openQ4-client_wasm32.wasm")"
printf '  %s (%s bytes)\n' "${web_dir}/baseoq4/game-sp_wasm32.wasm" "$(stat -c '%s' "${web_dir}/baseoq4/game-sp_wasm32.wasm")"
printf '  %s (%s bytes)\n' "${web_dir}/baseoq4/game-mp_wasm32.wasm" "$(stat -c '%s' "${web_dir}/baseoq4/game-mp_wasm32.wasm")"
printf 'Retail q4base PK4s are not copied; browser data remains user-supplied.\n'
