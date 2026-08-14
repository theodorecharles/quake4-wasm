/*
===========================================================================

Emscripten SDL3 platform seam for openQ4.

The browser build uses Emscripten's SDL3 port, which provides the WebGL
canvas, browser event queue, and audio bridge. The shared SDL3 backend owns
the engine window and input policy; this translation unit supplies the small
platform surface that the Linux wrapper normally provides.

===========================================================================
*/

#include "../../idlib/precompiled.h"
#include "../../framework/Session_local.h"
#include "../../renderer/tr_local.h"
#include "../linux/linux_shared.h"

#include <emscripten/emscripten.h>
#include <emscripten/html5_webgl.h>

// Emscripten's selector-based context helpers consult `document`, which does
// not exist in the dedicated engine worker. Create and resize the transferred
// OffscreenCanvas directly through Module.canvas instead.
EM_JS(int, Q4WASM_CreateDirectWebGLContext, (int alpha, int depth, int stencil, int samples), {
	if (!Module.canvas || typeof GL === 'undefined') return 0;
	var context = GL.createContext(Module.canvas, {
		alpha: !!alpha,
		depth: !!depth,
		stencil: !!stencil,
		antialias: samples > 1,
		majorVersion: 2,
		minorVersion: 0,
		premultipliedAlpha: false,
		preserveDrawingBuffer: false,
		enableExtensionsByDefault: true
	});
	if (context) GL.makeContextCurrent(context);
	return context | 0;
});

EM_JS(int, Q4WASM_SetDirectCanvasSize, (int width, int height), {
	if (!Module.canvas || width < 1 || height < 1) return 0;
	Module.canvas.width = width;
	Module.canvas.height = height;
	return 1;
});

#define OPENQ4_SDL3_EMSCRIPTEN_HOST 1
#include "../sdl3/sdl3_backend.cpp"

static idCVar sys_videoRam(
	"sys_videoRam",
	"0",
	CVAR_SYSTEM | CVAR_ARCHIVE | CVAR_INTEGER,
	"Texture memory on the video card (in megabytes) - 0: browser default",
	0,
	OPENQ4_LINUX_MAX_CONFIGURED_VIDEO_RAM_MB
);

bool QGL_Init(const char *dllname) {
	(void)dllname;
	return true;
}

void QGL_Shutdown(void) {
}

void Sys_ShutdownSymbols(void) {
}

// The retained renderer still references a small set of desktop fixed
// function entry points that WebGL does not expose. Emscripten's legacy GL
// bridge covers the main compatibility surface; these diagnostic/legacy
// calls have no browser equivalent and remain explicit no-ops for now.
extern "C" {
void glArrayElement(GLint) {}
void glDrawPixels(GLsizei, GLsizei, GLenum, GLenum, const void *) {}
void glPopAttrib(void) {}
void glPushAttrib(GLbitfield) {}
void glRasterPos2f(GLfloat, GLfloat) {}
void glTexGenf(GLenum, GLenum, GLfloat) {}
}

bool Sys_GetDesktopResolution(int *width, int *height) {
	if (width == NULL || height == NULL) {
		return false;
	}

	*width = 1280;
	*height = 720;
	int displayCount = 0;
	SDL_DisplayID *displays = SDL_GetDisplays(&displayCount);
	if (displays == NULL || displayCount <= 0) {
		if (displays != NULL) {
			SDL_free(displays);
		}
		return true;
	}

	const SDL_DisplayMode *mode = SDL_GetDesktopDisplayMode(displays[0]);
	if (mode != NULL && mode->w > 0 && mode->h > 0) {
		*width = mode->w;
		*height = mode->h;
	}
	SDL_free(displays);
	return true;
}

int Sys_GetVideoRam(void) {
	if (sys_videoRam.GetInteger() > 0) {
		return sys_videoRam.GetInteger();
	}
	return OPENQ4_LINUX_UNKNOWN_VIDEO_RAM_MB;
}

extern "C" EMSCRIPTEN_KEEPALIVE void Q4WASM_BrowserOpenMenu( void ) {
	if ( sessLocal.IsMapSpawned() ) {
		sessLocal.StartMenu();
	}
}

extern "C" EMSCRIPTEN_KEEPALIVE void Q4WASM_BrowserCapture( int captured ) {
	Sys_GrabMouseCursor( captured != 0 );
}

extern "C" EMSCRIPTEN_KEEPALIVE void Q4WASM_BrowserPointer( int x, int y, int relative ) {
	const int eventTime = Sys_Milliseconds();
	if ( relative ) {
		SDL3_QueueMouseDelta( x, y, eventTime );
		return;
	}
	if ( console != NULL && console->Active() ) {
		console->SetMousePosition( x, y );
	} else {
		idUserInterface *activeGui = SDL3_GetActiveMenuGui();
		if ( activeGui != NULL ) {
			activeGui->SetCursor( x, y );
		}
	}
	SDL3_SetMenuMouseTrackingPosition( x, y );
}

extern "C" EMSCRIPTEN_KEEPALIVE void Q4WASM_BrowserPointerButton( int browserButton, int down ) {
	const int key = browserButton == 2 ? K_MOUSE2 : browserButton == 1 ? K_MOUSE3 : K_MOUSE1;
	SDL3_QueueMouseButtonEvent( key, down != 0, Sys_Milliseconds(), true );
}

extern "C" EMSCRIPTEN_KEEPALIVE void Q4WASM_BrowserKey( int scan, int keycode, int down, int repeat ) {
	SDL_Event event = {};
	event.type = down ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP;
	event.key.down = down != 0;
	event.key.repeat = repeat != 0;
	event.key.scancode = static_cast<SDL_Scancode>( scan );
	event.key.key = keycode ? static_cast<SDL_Keycode>( keycode ) : SDL_GetKeyFromScancode( event.key.scancode, SDL_KMOD_NONE, false );
	SDL_PushEvent( &event );
}

extern "C" EMSCRIPTEN_KEEPALIVE void Q4WASM_BrowserText( int codepoint ) {
	if ( codepoint > 0 && codepoint <= 0xff ) {
		Sys_QueEvent( Sys_Milliseconds(), SE_CHAR, codepoint, 0, 0, NULL );
	}
}

extern "C" EMSCRIPTEN_KEEPALIVE int Q4WASM_BrowserResize( int width, int height ) {
	if ( width < 320 || height < 200 ) {
		return 0;
	}
	if ( !Q4WASM_SetDirectCanvasSize( width, height ) ) {
		return 0;
	}
	SDL3_SetVidSize( width, height );
	SDL3_SetUIViewport( 0, 0, width, height );
	return 1;
}
