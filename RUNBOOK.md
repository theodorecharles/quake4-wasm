# quake4-wasm implementation runbook

Read `/home/ted/Development/WASM_PORTS_RUNBOOK.md` first. It defines shared browser-shell, asset, lifecycle, graphics, input, Docker, test, and coordination rules. This file defines the Quake 4-specific implementation path.

## Objective

Ship Quake 4's real single-player campaign and multiplayer in a browser using openQ4 plus legally installed Steam PK4s. Preserve authentic menus/HUD/GUIs, campaign AI and scripting, vehicles, cinematics, renderer, BSE effects, saves, console, sound, multiplayer, bots where supported, and dedicated server behavior.

## Current checkpoint

- Downstream repository: `theodorecharles/quake4-wasm`.
- Implementation base: `themuffinator/openQ4`.
- Work branch: `devel`.
- Original engine reference belongs in ignored `references/doom3-source/` because Quake 4 is id Tech 4 and no complete Quake 4 GPL source release exists.
- Steam app 2210 is complete at `/home/ted/.steam/debian-installation/steamapps/common/Quake 4`.
- Retail data is present under `q4base/`, including the installed PK4 set and multiplayer/game PK4s.
- openQ4 has native Single Player and Multiplayer and documents Arena Campaign/bot functionality, but it has no maintained Emscripten target.
- The openQ4 game library derives from the Quake 4 SDK and retains SDK EULA terms. Complete a redistribution review before publishing compiled game-code binaries; do not assume the engine GPL automatically relicenses SDK game code or Raven assets.

## Downstream-only rule

Do not submit anything upstream. Do not open or comment on openQ4, id Software, or related pull requests, issues, discussions, or releases. Do not message maintainers. Never push to `upstream`. All generated work stays in `theodorecharles/quake4-wasm`.

## Source authority

Use this order:

1. the Steam Quake 4 client in actual SP/MP play;
2. openQ4's implementation for Quake 4 behavior;
3. ignored id Doom 3 GPL source for engine architecture and original id Tech 4 behavior;
4. Doom 3/dhewm3 work only as a reviewed sibling-port reference;
5. `wolfet-wasm` for generic browser-shell patterns.

Never copy changes from `doom3-wasm` merely because both are id Tech 4; compare openQ4's renderer, BSE, game SDK, network protocol, and UI differences.

## Native baseline and build discovery

Before web edits:

1. Read openQ4's build documentation and CMake options completely.
2. Prove the native client without touching the Steam install.
3. Prove the native dedicated server if present, or add a minimal server-only configuration from existing code.
4. Record exact commit, compiler, dependencies, and runtime data path.

Then create a downstream Emscripten configuration:

```text
scripts/build-web.sh
scripts/build-server.sh
scripts/setup-data.sh
cmake/Toolchain-Emscripten.cmake or CMakePresets.json
```

Use an explicit `Q4WASM_CLIENT` CMake option. Compile immediately and fix the first meaningful error. Keep native builds intact behind `__EMSCRIPTEN__` boundaries.

## First web reductions

For the initial engine/title milestone:

- single thread first;
- SDL2 Emscripten video and input;
- WebGL 2/GLES renderer;
- static game/renderer linkage or deliberate side modules; no native `dlopen` assumptions;
- no native process spawning, editors, crash handlers, CD-key dialogs, LAN broadcast, or voice capture;
- browser-compatible audio path before OpenAL parity;
- non-blocking Emscripten main loop;
- diagnostics for every disabled subsystem.

Disable nonessential BSE effects only as a named temporary unblocker. The final renderer must restore Quake 4 particles/effects because weapons, ambient scenes, and campaign feedback depend on them.

## Renderer strategy

Inventory desktop OpenGL/ARB programs, GLSL version assumptions, framebuffer/shadow paths, stencil operations, texture formats/compression, and BSE rendering. Do not depend on Emscripten's legacy desktop-GL emulation for final correctness.

WebGL 2 milestone order:

1. context and truthful extension/capability report;
2. clear/frame and 2D GUI;
3. static BSP/world geometry;
4. materials and light interactions;
5. animated MD5 entities and weapons;
6. BSE particles/effects;
7. shadow volumes/maps as supported;
8. post-processing, portals, vehicles, cinematics, and advanced effects.

Create shader translation/variants that are valid GLSL ES 3.00. Audit invalid enums and texture uploads instead of ignoring `GL_INVALID_ENUM`.

## Retail data

Validate the actual Steam `q4base/*.pk4` set locally and generate an ignored manifest. Do not publish, commit, or bake these PK4s into Docker. The owner supplies `/data/q4base` or selects local files in-browser.

Quake 4 data is multi-gigabyte. Build a lazy read-only PK4 filesystem backed by range/chunk requests and IndexedDB/OPFS. Index ZIP metadata without copying every PK4 into WASM memory. Keep writable saves/configs separate. A hard refresh reuses valid chunks; a code release does not invalidate unchanged retail data.

Custom maps/mods use `/data/custom_maps` after compatibility validation. Do not add unreviewed PK4s automatically to campaign or MP rotation.

## Menu and modes

The authentic engine GUI must expose:

- Single Player
  - New Game/difficulty
  - Load/Save
- Multiplayer
  - Join Game
  - Arena Campaign/bot play when supported by current openQ4 game code
  - Host/Local Match where useful
- Options
- Credits

Do not recreate the Quake 4 menu/HUD in HTML. The landing page name and settings flow into safe cvars/argv. Single Player does not wake the dedicated server; Multiplayer intent does.

## Single-player acceptance

- Render main menu and start a campaign.
- Reach the first interactive level.
- Verify AI, weapons, physics, scripted events, in-world GUIs, vehicles, BSE effects, doors/movers, dynamic lights/shadows, cinematics, death/reload, and a map transition.
- Save, reload the page, restore, and load.
- Verify aspect-correct HUD, objective text, subtitles, PDA/menus, and console.

Campaign success requires real play, not just loading a map by console.

## Multiplayer and bots

Build the native openQ4 dedicated process and bridge browser networking through same-origin `/ws` while preserving protocol semantics. Test two browsers: wake, connect, lobby, map load, movement, combat, chat, scoreboard, death/respawn, map transition, disconnect/reconnect.

openQ4 documents Arena Campaign with bot tiers. Inspect the exact commands/server behavior and licensing before integrating maintained population. If those bots are client-local or incompatible with dedicated multiplayer, do not claim bot backfill. If proven, target eight total participants with one transient slot and bots yielding to connected humans.

## Input and GUI

Quake 4 combines engine menus and interactive in-world GUIs. Pointer coordinates, hit testing, HUD, and world projection must share one viewport transform. Test:

- relative gameplay mouse and all default movement/weapon bindings;
- engine cursor and in-world GUI interaction;
- console editing/history including `/`, Backspace, Enter, Up/Down;
- Escape navigation, chat, scoreboard, death/respawn, cinematics, vehicle entry/exit, focus loss, and reconnect;
- normal browser shortcuts outside capture.

Never show two cursors or apply mouse deltas twice.

## Graphics profiles

Build Low/Medium/High/Ultra from verified openQ4 cvars: resolution scale, texture detail/compression, anisotropy, shader interactions, shadows, BSE particles, decals, post-processing, antialiasing where supported, model detail, and view distance. Dynamic 30/60/120 FPS follows shared hysteresis.

Do not lower settings in ways that hide objective actors, projectiles, lamps, effects, or in-world GUI information. Ultra is the maximum faithful WebGL 2 configuration, not a claim of desktop extension support.

## Modes and assists

`GAME_MODE=vanilla` preserves stock speed, movement, feedback, information visibility, and aim. Optional `arcade` additions must be server-authoritative where applicable and must never break campaign scripts or vehicles. Aim assistance/extra visibility is off in Vanilla and must not target teammates or occluded actors.

## Docker defaults

The public image includes web runtime, legal redistributable engine components after review, native server, and no retail data:

```text
HTTP_PORT=8088
GAME_SLOTS=8
KEEP_ALIVE=false
IDLE_TIMEOUT=15m
GAME_MODE=vanilla
```

Use `/data/q4base` and `/data/custom_maps`. Build `linux/amd64` first. Block Docker publication until the SDK-derived binary redistribution review is recorded.

## First worker assignment

1. Finish/verify the openQ4 checkout and ignored Doom 3 source reference.
2. Read licenses/EULAs and create `docs/REDISTRIBUTION.md` containing facts and release gates, not legal conclusions.
3. Prove the native client/server build commands.
4. Add the smallest Emscripten CMake platform option and compile immediately.
5. Classify blockers and fix only the first meaningful one until a substantial WASM artifact exists.
6. Return an engine-init browser handoff to Luna; do not use Chrome.
7. Commit and push `devel`.

## Status handoff

Report SP, MP, and bot milestones separately; exact commands; artifacts; assets; redistribution gate; browser test request; first renderer/platform blocker; and `Upstream contacted: no`.
