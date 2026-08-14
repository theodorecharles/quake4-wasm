# Quake 4 WebAssembly runbook

Status: **Still in development**

This downstream ports the native openQ4 engine to Emscripten. It does not reuse
an existing WebAssembly port and it does not contain Quake 4 retail data.

## Rules

- Do not submit, push, file, or discuss this work upstream.
- Keep all changes in this downstream repository.
- Never commit or bake retail `q4base` files into a source archive or image.
- Keep `/data` private; the HTTP server must return 404 for `/data` and every
  child path.
- Preserve SP and MP as separate, testable variants.

## Canonical browser contract

The repository pins `wasm-game-framework` 0.7.0 at public commit
`536d919ef6e6cd171aa826812db9f888ffbf04a3`.

Downstream owns only:

- `docker/wasm-game.json`: declarative shell, variant, PWA, icon, background,
  viewport, graphics, and fullscreen metadata;
- `docker/wasm-game-data.json`: exact owner-data policy for the registered
  `q4base` PK4 set;
- `docker/game-adapter.js`: framework-to-engine state/input/data adapter;
- `docker/q4-worker.js`: worker bootstrap and Emscripten filesystem mounts;
- engine JS/WASM, game-module WASM, source-derived runtime packages, and
  source-licensed presentation assets.

There is no downstream `index.html`, shell stylesheet, service worker, or web
manifest. The framework generates those artifacts and provides the
`WasmGameFramework` API, `wasm-game-framework-*` events/classes, owner-data
container provisioning, IndexedDB browser cache, launch preferences, PWA
metadata, responsive canvas policy, and security headers.

## Variants and images

The suite image selects either variant with `?game=`:

- `quake4`: Quake 4 single player — **Still in development**
- `quake4-mp`: Quake 4 multiplayer — **Still in development**

`scripts/build-docker.sh` also builds locked `quake4` and `quake4-mp` images.
Both use the same exact owner PK4 policy and browser cache namespace so changing
variants does not duplicate gigabytes of data.

## Retail and source-derived data

The owner mounts registered data at `/data/q4base`. On first use, the framework
streams the exact manifest files from the container into its private browser
cache. Later launches restore unchanged files from IndexedDB. The worker mounts
the resulting browser `File` objects read-only through WORKERFS at
`/owner-data/q4base`; saves/configuration use IDBFS at `/save`.

Two OpenQ4 runtime packages are built from source and are safe to ship with the
engine. Do not replace either package with a retail file and do not weaken these
assertions:

| Package | Bytes | MD5 | Runtime checksum |
|---|---:|---|---|
| `baseoq4/pak0.pk4` | 4,285,437 | `17550cb028326cdf1cee440bc5d73d74` | `0x29a1151e` |
| `baseoq4/pak1.pk4` | 641,646,791 | `c3434e1d28bebdc367d6e50f3b1fda3a` | `0xdf8f4531` |

Both build scripts verify MD5, byte size, and ZIP integrity. Docker staging
rejects every unrecognized `.pk4` or `.pak`.

## Build

```bash
cd /home/ted/Development/wasm/quake4-wasm
source /home/ted/emsdk/emsdk_env.sh
OPENQ4_GAMELIBS_REPO="$PWD/.tmp/pinned-gamelibs" JOBS=4 \
  ./scripts/build-web.sh
IMAGE_REPO=local/quake4-wasm IMAGE_TAG=dev ./scripts/build-docker.sh
```

The pinned GameLibs revision is
`0c9c121ff337b1c6df129ecedcfe569e7c50c332`. Its compiled SP/MP modules and
accompanying SDK EULA follow the recorded owner decision in
`docs/REDISTRIBUTION.md`.

## Verified browser boundary (2026-08-14)

Serialized Chrome tests exercised both SP and MP from the framework 0.7.0 suite
image with the exact Steam owner-data set.

- The browser restored all 32 owner PK4s from its private cache.
- The engine mounted both source-derived OpenQ4 packages above.
- The Emscripten main loop remained cooperative in a dedicated worker.
- Native splash, unsupported interface enumeration, background pthreads, and
  selector/`document`-based GL access are removed on the browser path.
- A direct WebGL 2 context is created against the transferred OffscreenCanvas.
- Both SP and MP reach decl loading, configuration, input initialization,
  no-device sound fallback, and renderer capability probing.

The current blocker is renderer translation: OpenQ4 still requires desktop
fixed-function/ARB program entry points that WebGL 2 does not expose. The next
implementation pass must select or build a GLSL ES 3.00 path, then verify the
authentic menu before claiming runtime status **Live**. Audio is also disabled
after OpenAL cannot open a browser device.

## Acceptance sequence

1. Translate/replace the required ARB program path with valid WebGL 2 shaders.
2. Render the authentic SP and MP menus.
3. Verify dynamic aspect-correct canvas sizing and menu pointer mapping.
4. Start the campaign and one multiplayer map.
5. Verify WASD, relative mouse, Escape/menu state, console editing, and normal
   browser shortcuts outside capture.
6. Restore browser audio and persistent saves.
7. Rebuild suite plus locked images; test headers, ranges, PWA metadata,
   service worker behavior, `/data` isolation, and both runtime variants.

Upstream contacted: **no**.
