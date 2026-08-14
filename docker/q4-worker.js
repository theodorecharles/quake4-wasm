'use strict';

let runtime = null;
let persist = null;
let started = false;
let failed = false;

function post(type, text, extra) {
  self.postMessage({ type, text: text == null ? undefined : String(text), ...(extra || {}) });
}

function call(name, ...arguments_) {
  const fn = runtime && runtime[`_${name}`];
  if (typeof fn === 'function') return fn(...arguments_);
  return 0;
}

async function launch(message) {
  if (started) return;
  started = true;
  failed = false;
  const { canvas, entries = [], variant, width, height, playerName, engineArguments = [] } = message;
  const multiplayer = variant === 'quake4-mp';
  try {
    post('status', 'Loading Quake 4 engine and game module…');
    const moduleName = multiplayer ? 'game-mp_wasm32.wasm' : 'game-sp_wasm32.wasm';
    const [enginePak0, enginePak1, gameModule, modManifest] = await Promise.all([
      fetch('/baseoq4/pak0.pk4').then(response => {
        if (!response.ok) throw new Error(`baseoq4/pak0.pk4: HTTP ${response.status}`);
        return response.arrayBuffer();
      }),
      fetch('/baseoq4/pak1.pk4').then(response => {
        if (!response.ok) throw new Error(`baseoq4/pak1.pk4: HTTP ${response.status}`);
        return response.arrayBuffer();
      }),
      fetch(`/baseoq4/${moduleName}`).then(response => {
        if (!response.ok) throw new Error(`${moduleName}: HTTP ${response.status}`);
        return response.arrayBuffer();
      }),
      fetch('/baseoq4/mod.json').then(response => {
        if (!response.ok) throw new Error(`baseoq4/mod.json: HTTP ${response.status}`);
        return response.text();
      })
    ]);

    self.Module = runtime = {
      canvas,
      arguments: [
        '+set', 'fs_basepath', '/owner-data',
        '+set', 'fs_cdpath', '/',
        '+set', 'fs_homepath', '/save',
        '+set', 'fs_savepath', '/save',
        '+set', 'fs_game', 'baseoq4',
        '+set', 'fs_game_base', 'q4base',
        '+set', 'com_nextGameModule', multiplayer ? 'game_mp' : 'game_sp',
        '+set', 'r_fullscreen', '0',
        '+set', 'r_mode', '-1',
        '+set', 'r_customWidth', String(width || 1280),
        '+set', 'r_customHeight', String(height || 720),
        '+set', 'ui_name', String(playerName || 'Kane').slice(0, 32),
        ...engineArguments
      ],
      locateFile: path => new URL(path, self.location.href).href,
      preRun: [() => {
        FS.mkdir('/owner-data');
        FS.mount(WORKERFS, { blobs: entries.map(entry => ({ name: entry.path, data: entry.file })) }, '/owner-data');
        FS.mkdir('/baseoq4');
        FS.mkdir('/save');
        FS.mount(IDBFS, {}, '/save');
        FS.writeFile('/baseoq4/pak0.pk4', new Uint8Array(enginePak0), { canOwn: true });
        FS.writeFile('/baseoq4/pak1.pk4', new Uint8Array(enginePak1), { canOwn: true });
        FS.writeFile(`/baseoq4/${moduleName}`, new Uint8Array(gameModule), { canOwn: true });
        FS.writeFile('/baseoq4/mod.json', modManifest);
        addRunDependency('quake4-save-restore');
        FS.syncfs(true, error => {
          if (error) post('log', `Save restore warning: ${error}`);
          removeRunDependency('quake4-save-restore');
        });
      }],
      print: line => post('log', line),
      printErr: line => post('log', `ERR: ${line}`),
      onRuntimeInitialized: () => {
        post('status', 'Initializing the Quake 4 renderer and menus…');
        let syncing = false;
        persist = () => {
          if (syncing) return;
          syncing = true;
          FS.syncfs(false, error => {
            syncing = false;
            if (error) post('log', `Save persistence warning: ${error}`);
          });
        };
        setInterval(persist, 10000);
      },
      onExit: status => {
        if (status !== 0) {
          failed = true;
          post('error', `Quake 4 exited during initialization (status ${status}).`);
        }
      },
      onAbort: reason => {
        failed = true;
        post('error', reason);
      }
    };
    importScripts('/openQ4-client_wasm32.js');
  } catch (reason) {
    started = false;
    failed = true;
    post('error', reason instanceof Error ? reason.stack || reason.message : reason);
  }
}

self.onerror = event => {
  failed = true;
  const location = event.filename ? ` (${event.filename}:${event.lineno || 0}:${event.colno || 0})` : '';
  post('error', `${event.message || 'Uncaught worker error'}${location}`);
  return true;
};

self.onmessage = event => {
  const message = event.data || {};
  if (message.type === 'start') { void launch(message); return; }
  if (message.type === 'persist') { persist?.(); return; }
  if (!runtime || failed) return;
  if (message.type === 'resize') call('Q4WASM_BrowserResize', message.width | 0, message.height | 0);
  if (message.type === 'open-menu') call('Q4WASM_BrowserOpenMenu');
  if (message.type === 'capture') call('Q4WASM_BrowserCapture', message.captured ? 1 : 0);
  if (message.type === 'pointer-absolute') call('Q4WASM_BrowserPointer', message.x | 0, message.y | 0, 0);
  if (message.type === 'pointer-relative') call('Q4WASM_BrowserPointer', message.dx | 0, message.dy | 0, 1);
  if (message.type === 'pointer-button') call('Q4WASM_BrowserPointerButton', message.button | 0, message.down ? 1 : 0);
  if (message.type === 'key') call('Q4WASM_BrowserKey', message.scan | 0, message.key | 0, message.down ? 1 : 0, message.repeat ? 1 : 0);
  if (message.type === 'text') call('Q4WASM_BrowserText', message.codepoint | 0);
};
