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



class PolygonRenderer
{
public:
   virtual ~PolygonRenderer() {}
   virtual void Render(SDL_Surface *outDest,
                         Sint16 inOffsetX=0,Sint16 inOffsetY=0)=0;


   static PolygonRenderer *CreateGradientRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              class Gradient *inGradient );

   static PolygonRenderer *CreateBitmapRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource );
};



#endif
