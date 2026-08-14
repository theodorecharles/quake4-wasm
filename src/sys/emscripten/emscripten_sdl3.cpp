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
#include "../../renderer/tr_local.h"
#include "../linux/linux_shared.h"

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
