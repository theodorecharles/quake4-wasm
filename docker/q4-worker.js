'use strict';

self.onmessage = async event => {
  const { canvas, files = [], localUrls = [], mode } = event.data;
  self.onmessage = null;
  const post = (type, text) => self.postMessage({ type, text: String(text) });
  try {
    post('status', 'Loading Quake 4 engine and game module…');
    const moduleName = mode === 'mp' ? 'game-mp_wasm32.wasm' : 'game-sp_wasm32.wasm';
    const [enginePak, gameModule] = await Promise.all([
      fetch('baseoq4/pak0.pk4').then(response => {
        if (!response.ok) throw new Error(`baseoq4/pak0.pk4: HTTP ${response.status}`);
        return response.arrayBuffer();
      }),
      fetch(`baseoq4/${moduleName}`).then(response => {
        if (!response.ok) throw new Error(`${moduleName}: HTTP ${response.status}`);
        return response.arrayBuffer();
      })
    ]);

    self.Module = {
      canvas,
      arguments: [
        '+set', 'fs_basepath', '/owner-data',
        '+set', 'fs_cdpath', '/',
        '+set', 'fs_homepath', '/save',
        '+set', 'fs_savepath', '/save',
        '+set', 'fs_game', 'baseoq4',
        '+set', 'fs_game_base', 'q4base',
        '+set', 'com_nextGameModule', mode === 'mp' ? 'game_mp' : 'game_sp'
      ],
      locateFile: path => new URL(path, self.location.href).href,
      preRun: [() => {
        FS.mkdir('/owner-data');
        if (localUrls.length) {
          FS.mkdir('/owner-data/q4base');
          for (const entry of localUrls) {
            FS.createLazyFile('/owner-data/q4base', entry.name, entry.url, true, false);
          }
        } else {
          FS.mount(WORKERFS, {
            blobs: files.map(file => ({ name: `q4base/${file.name}`, data: file }))
          }, '/owner-data');
        }
        FS.mkdir('/baseoq4');
        FS.mkdir('/save');
        FS.writeFile('/baseoq4/pak0.pk4', new Uint8Array(enginePak), { canOwn: true });
        FS.writeFile(`/baseoq4/${moduleName}`, new Uint8Array(gameModule), { canOwn: true });
      }],
      print: line => post('log', line),
      printErr: line => post('log', `ERR: ${line}`),
      onRuntimeInitialized: () => post('status', `Quake 4 ${mode === 'mp' ? 'multiplayer' : 'single-player'} runtime initialized`),
      onAbort: reason => post('error', reason)
    };
    importScripts('openQ4-client_wasm32.js');
  } catch (reason) {
    post('error', reason instanceof Error ? reason.stack || reason.message : reason);
  }
};
