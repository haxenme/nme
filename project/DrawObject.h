#ifndef DRAW_OBJECT_H
#define DRAW_OBJECT_H

#include <SDL.h>
#include <neko.h>
#include "Matrix.h"
#include "renderer/Renderer.h"
#include "texture_buffer.h"
#include "Gradient.h"
#include "renderer/Points.h"


// --- Base class -----------------------------------------------------

class Drawable
{
public:
   virtual ~Drawable() { }
   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty,MaskObject *inMask,const Viewport &inVP)=0;
   virtual bool HitTest(int inX,int inY) = 0;

   virtual void GetExtent(Extent2DI &ioExtent, const Matrix &inMat,
                  bool inExtent)=0;

   virtual void AddToMask(SDL_Surface *inSurf,PolygonMask &ioMask,const Matrix &inMatrix)=0;

   virtual bool IsGrad() { return false; }
};


#define BLEND_ADD  0
#define BLEND_ALPHA  1
#define BLEND_DARKEN  2
#define BLEND_DIFFERENCE  3
#define BLEND_ERASE  4
#define BLEND_HARDLIGHT  5
#define BLEND_INVERT  6
#define BLEND_LAYER  7
#define BLEND_LIGHTEN  8
#define BLEND_MULTIPLY  9
#define BLEND_NORMAL  10
#define BLEND_OVERLAY  11
#define BLEND_SCREEN  12
#define BLEND_SUBTRACT  13
#define BLEND_SHADER  14



void BlendSurface(SDL_Surface *inSrc, SDL_Rect *inSrcRect,
                  SDL_Surface *inDest, SDL_Rect *inDestOffset,
                  int inMode);


void delete_drawable( value drawable );

DECLARE_KIND( k_drawable );

#endif
