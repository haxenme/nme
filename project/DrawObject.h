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


void delete_drawable( value drawable );

DECLARE_KIND( k_drawable );

#endif
