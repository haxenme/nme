#ifndef OGL_STATE_H
#define OGL_STATE_H

#include "config.h"

#ifdef NME_ANY_GL

#include <SDL_opengl.h>

void nmeSetTexture(int inID,bool inBindNow=false);
void nmeClearTexture(int inID);
void nmeEnableTexture(bool inEnable);
void nmeSetBlend(bool inEnable, GLenum inSrc=GL_SRC_ALPHA, GLenum inDest=GL_ONE_MINUS_SRC_ALPHA );

void nmeDrawArrays(GLenum inMode, int inN);

#endif

#endif
