// Emscripten's legacy-GL emulation replaces several WebGL entry points during
// GLImmediate.setupFuncs().  The replacement closures do not inherit the
// original `sig` metadata, but MAIN_MODULE's dynamic linker needs that metadata
// when it turns the closures into function-table entries for SIDE_MODULEs.
// Restore the ABI signatures after the GL library postsets have run and before
// asynchronous wasm instantiation can report unresolved GOT entries.
{
  const signatures = {
    _emscripten_glActiveTexture: 'vi',
    _glActiveTexture: 'vi',
    _emscripten_glEnable: 'vi',
    _glEnable: 'vi',
    _emscripten_glDisable: 'vi',
    _glDisable: 'vi',
    _emscripten_glTexEnvf: 'viif',
    _glTexEnvf: 'viif',
    _emscripten_glTexEnvi: 'viii',
    _glTexEnvi: 'viii',
    _emscripten_glTexEnvfv: 'viip',
    _glTexEnvfv: 'viip',
    _glGetTexEnviv: 'viip',
    _glGetTexEnvfv: 'viip',
    _emscripten_glGetIntegerv: 'vip',
    _glGetIntegerv: 'vip',
  };

  if (typeof _emscripten_glActiveTexture === 'function') _emscripten_glActiveTexture.sig = signatures._emscripten_glActiveTexture;
  if (typeof _glActiveTexture === 'function') _glActiveTexture.sig = signatures._glActiveTexture;
  if (typeof _emscripten_glEnable === 'function') _emscripten_glEnable.sig = signatures._emscripten_glEnable;
  if (typeof _glEnable === 'function') _glEnable.sig = signatures._glEnable;
  if (typeof _emscripten_glDisable === 'function') _emscripten_glDisable.sig = signatures._emscripten_glDisable;
  if (typeof _glDisable === 'function') _glDisable.sig = signatures._glDisable;
  if (typeof _emscripten_glTexEnvf === 'function') _emscripten_glTexEnvf.sig = signatures._emscripten_glTexEnvf;
  if (typeof _glTexEnvf === 'function') _glTexEnvf.sig = signatures._glTexEnvf;
  if (typeof _emscripten_glTexEnvi === 'function') _emscripten_glTexEnvi.sig = signatures._emscripten_glTexEnvi;
  if (typeof _glTexEnvi === 'function') _glTexEnvi.sig = signatures._glTexEnvi;
  if (typeof _emscripten_glTexEnvfv === 'function') _emscripten_glTexEnvfv.sig = signatures._emscripten_glTexEnvfv;
  if (typeof _glTexEnvfv === 'function') _glTexEnvfv.sig = signatures._glTexEnvfv;
  if (typeof _glGetTexEnviv === 'function') _glGetTexEnviv.sig = signatures._glGetTexEnviv;
  if (typeof _glGetTexEnvfv === 'function') _glGetTexEnvfv.sig = signatures._glGetTexEnvfv;
  if (typeof _emscripten_glGetIntegerv === 'function') _emscripten_glGetIntegerv.sig = signatures._emscripten_glGetIntegerv;
  if (typeof _glGetIntegerv === 'function') _glGetIntegerv.sig = signatures._glGetIntegerv;
}
