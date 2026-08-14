# Redistribution gates

This document records release gates for the downstream Quake 4 browser port. It is an engineering checklist, not legal advice or a conclusion that any particular distribution is permitted.

## Component boundaries

### openQ4 engine

The engine checkout is covered by the repository-root `LICENSE` (GNU GPL version 3). Any published engine binary, including a WebAssembly build, must ship with the required notices and an offer or delivery mechanism for the corresponding source for that exact build. Downstream modifications and reproducible build inputs must remain available for the distributed version.

Release gate: verify the source commit, build configuration, dependency versions, license text, notices, and corresponding-source delivery before publishing an engine binary or container image.

### Quake 4 game library

The build expects game-library sources from a separate checkout selected through `OPENQ4_GAMELIBS_REPO`. Project documentation identifies those sources as derived from the Quake 4 SDK and subject to terms separate from the engine GPL. They are not vendored into this downstream repository.

Release gate: retain the exact license/EULA that accompanies the selected game-library source revision, record the owner's distribution decision, and preserve all required notices and restrictions. A successful local build is not redistribution clearance; a later source or distribution change reopens this gate.

### Retail Quake 4 data

Retail `q4base` files are user-supplied runtime data. They must remain outside Git history, source archives, release artifacts, web images, and Docker build layers. Validation may read an existing installation in place, and local manifests must remain ignored. The public runtime must obtain data from an explicit user-selected path or mounted data volume.

Release gate: inspect every package and container layer and reject the release if it contains retail PK4s, retail executables or libraries, CD keys, saves, profiles, or copied Steam installation data.

### Repository-authored content and third-party dependencies

The openQ4 runtime packs and each linked dependency have their own provenance and notice requirements. Build success does not establish that a combined binary or web bundle has a complete notice set.

Release gate: generate an inventory from the exact staged payload, map every engine/content/dependency component to its source and license, preserve required notices, and resolve any unknown or incompatible item before publication. Repeat this inventory when the dependency graph or generated runtime packs change.

## Evidence record (2026-08-14)

- The canonical companion repository is [openQ4-game](https://github.com/themuffinator/openQ4-game). Its README identifies the source as Quake4SDK-derived and identifies the repository license as the Quake 4 Software Development Kit Limited Use License Agreement.
- The repository currently publishes the associated [EULA.Development Kit.rtf](https://github.com/themuffinator/openQ4-game/blob/main/EULA.Development%20Kit.rtf). A read-only review records that its permitted-New-Creations section limits creations to operating with Quake 4 and discusses free distribution, while its distribution section discusses free-of-charge non-commercial copying, an accompanying-agreement condition, and a separate written agreement for commercial distribution.
- Those statements are an engineering evidence record, not a legal interpretation. In particular, this document does not decide whether these compiled WebAssembly game modules qualify as the EULA's permitted New Creations, whether a Docker Hub publication satisfies every condition, or whether any additional third-party notice is required.
- The exact local Emscripten staging manifest records GameLibs commit `0c9c121ff337b1c6df129ecedcfe569e7c50c332`, `gameLibsGitDirty: false`, `fileCount: 1361`, and the ignored source root `.tmp/pinned-gamelibs`. The selected checkout's `EULA.Development Kit.rtf` has SHA-256 `d1f76da23b9ea17dc27773ad183cab74344c299c071f9b6b58c2e337e440b1a2`. The content-preserving tracked delivery copy [`docs/QUAKE4-SDK-EULA.rtf`](QUAKE4-SDK-EULA.rtf) has SHA-256 `a32ff9062802586b962d9f6a582b2f7b407e61b27b4eb439c812b8955f9e9bfe` and is copied into the image at `/QUAKE4-SDK-EULA.rtf`. The browser build's Emscripten compatibility edits are generated only in the ignored staging tree and are not written back to that checkout.
- Owner distribution decision recorded 2026-08-14: the owner authorized publishing the compiled SP/MP GameLibs modules from the pinned revision in the intended Docker Hub image, with the accompanying EULA included and all retail `q4base` data kept outside Git, Docker layers, and release artifacts. This records the owner's decision and engineering constraints; it is not legal advice or a conclusion about any separate commercial-contract requirement.
- The current checkpoint image includes the compiled SP/MP modules, the engine license, the corresponding-source offer, and the accompanying SDK EULA. Renderer/audio parity and interactive browser testing remain separate product gates.

Decision status: OWNER-APPROVED FOR THE INTENDED DOCKER HUB IMAGE. Reopen this gate if the GameLibs revision, EULA, distribution scope, or retail-data boundary changes.

## Browser and container gates

- Keep retail data and SDK-derived source outside public Git and Docker build contexts.
- Do not embed retail PK4 bytes in JavaScript, WebAssembly, preload files, service-worker caches, or downloadable test fixtures.
- Keep writable browser saves/configuration separate from read-only user-provided data.
- The game-library gate is owner-approved for this exact staged payload; preserve the pinned revision, EULA, notices, and assetless boundary when publishing.
- Do not claim single-player, multiplayer, bots, or general browser playability until those paths have been exercised with the released artifact.

## Evidence required for a release decision

Record the downstream commit, compiler/toolchain versions, complete build command, staged-file inventory, dependency/license inventory, corresponding-source location, asset-ingestion method, and native/browser test results. The decision record must explicitly state whether game-library binaries are included and whether any retail-derived bytes were detected.
