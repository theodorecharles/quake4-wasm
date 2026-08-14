# Redistribution gates

This document records release gates for the downstream Quake 4 browser port. It is an engineering checklist, not legal advice or a conclusion that any particular distribution is permitted.

## Component boundaries

### openQ4 engine

The engine checkout is covered by the repository-root `LICENSE` (GNU GPL version 3). Any published engine binary, including a WebAssembly build, must ship with the required notices and an offer or delivery mechanism for the corresponding source for that exact build. Downstream modifications and reproducible build inputs must remain available for the distributed version.

Release gate: verify the source commit, build configuration, dependency versions, license text, notices, and corresponding-source delivery before publishing an engine binary or container image.

### Quake 4 game library

The build expects game-library sources from a separate checkout selected through `OPENQ4_GAMELIBS_REPO`. Project documentation identifies those sources as derived from the Quake 4 SDK and subject to terms separate from the engine GPL. They are not vendored into this downstream repository.

Release gate: review and retain the exact license/EULA that accompanies the selected game-library source revision. Do not publish native game modules, WebAssembly game code, or container layers containing that code until the owner has recorded the permitted distribution scope and all required notices and restrictions. A successful local build is not redistribution clearance.

### Retail Quake 4 data

Retail `q4base` files are user-supplied runtime data. They must remain outside Git history, source archives, release artifacts, web images, and Docker build layers. Validation may read an existing installation in place, and local manifests must remain ignored. The public runtime must obtain data from an explicit user-selected path or mounted data volume.

Release gate: inspect every package and container layer and reject the release if it contains retail PK4s, retail executables or libraries, CD keys, saves, profiles, or copied Steam installation data.

### Repository-authored content and third-party dependencies

The openQ4 runtime packs and each linked dependency have their own provenance and notice requirements. Build success does not establish that a combined binary or web bundle has a complete notice set.

Release gate: generate an inventory from the exact staged payload, map every engine/content/dependency component to its source and license, preserve required notices, and resolve any unknown or incompatible item before publication. Repeat this inventory when the dependency graph or generated runtime packs change.

## Browser and container gates

- Keep retail data and SDK-derived source outside public Git and Docker build contexts.
- Do not embed retail PK4 bytes in JavaScript, WebAssembly, preload files, service-worker caches, or downloadable test fixtures.
- Keep writable browser saves/configuration separate from read-only user-provided data.
- Do not publish a public browser image until the game-library gate and exact staged-payload inventory are complete.
- Do not claim single-player, multiplayer, bots, or general browser playability until those paths have been exercised with the released artifact.

## Evidence required for a release decision

Record the downstream commit, compiler/toolchain versions, complete build command, staged-file inventory, dependency/license inventory, corresponding-source location, asset-ingestion method, and native/browser test results. The decision record must explicitly state whether game-library binaries are included and whether any retail-derived bytes were detected.
