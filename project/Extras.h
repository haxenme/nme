#ifndef EXTRAS_H
#define EXTRAS_H

#include "SDL.h"


#define SPG_ALPHA_BLEND      0x0001
#define SPG_HIGH_QUALITY     0x0002

#define SPG_EDGE_MASK        0x00f0
#define SPG_EDGE_CLAMP       0x0000
#define SPG_EDGE_REPEAT      0x0010
#define SPG_EDGE_UNCHECKED   0x0020
#define SPG_EDGE_REPEAT_POW2 0x0030

void SPG_QuadTex2(SDL_Surface *dest,Sint16 x1,Sint16 y1,
                                    Sint16 x2,Sint16 y2,
                                    Sint16 x3,Sint16 y3,
                                    Sint16 x4,Sint16 y4,
                                    SDL_Surface *source,
                                    Sint16 sx1,Sint16 sy1,
                                    Sint16 sx2,Sint16 sy2,
                                    Sint16 sx3,Sint16 sy3,
                                    Sint16 sx4,Sint16 sy4,
                                    Uint32 inMode);

// This takes 16-bit fixed-point coordinates for destination cooridinates
void SPG_QuadTexHQ(SDL_Surface *dest,Sint32 x1,Sint32 y1,
                                     Sint32 x2,Sint32 y2,
                                     Sint32 x3,Sint32 y3,
                                     Sint32 x4,Sint32 y4,
                                     SDL_Surface *source,
                                     Sint16 sx1,Sint16 sy1,
                                     Sint16 sx2,Sint16 sy2,
                                     Sint16 sx3,Sint16 sy3,
                                     Sint16 sx4,Sint16 sy4,
                                     Uint32 inMode);


#endif
