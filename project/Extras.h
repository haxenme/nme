#ifndef EXTRAS_H
#define EXTRAS_H

#include "SDL.h"


#define SPG_ALPHA_BLEND  0x0001
// Not implemented yet ...
#define SPG_BILINEAR     0x0002

void SPG_QuadTex2(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Sint16 x4,Sint16 y4,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2,Sint16 sx3,Sint16 sy3,Sint16 sx4,Sint16 sy4,Uint32 inMode);


#endif
