#ifndef RENDERER_RENDERER_H
#define RENDERER_RENDERER_H

#include <SDL.h>
#include <vector>

#define NME_ALPHA_BLEND      0x0001
#define NME_HIGH_QUALITY     0x0002

#define NME_EDGE_MASK        0x00f0
#define NME_EDGE_CLAMP       0x0000
#define NME_EDGE_REPEAT      0x0010
#define NME_EDGE_UNCHECKED   0x0020
#define NME_EDGE_REPEAT_POW2 0x0030

#define NME_END_NONE         0x0000
#define NME_END_ROUND        0x0100
#define NME_END_SQUARE       0x0200
#define NME_END_MASK         0x0300
#define NME_END_SHIFT        8

#define NME_CORNER_ROUND     0x0000
#define NME_CORNER_MITER     0x1000
#define NME_CORNER_BEVEL     0x2000
#define NME_CORNER_MASK      0x3000
#define NME_CORNER_SHIFT     12

#define NME_PIXEL_HINTING    0x4000

#define NME_GRADIENT_FOCAL0  0x8000

#define NME_BMP_LINEAR       0x10000


#define NME_clip_xmin(pnt) pnt->clip_rect.x
#define NME_clip_xmax(pnt) pnt->clip_rect.x + pnt->clip_rect.w-1
#define NME_clip_ymin(pnt) pnt->clip_rect.y
#define NME_clip_ymax(pnt) pnt->clip_rect.y + pnt->clip_rect.h-1



#include "Points.h"



typedef std::vector<int> IntVec;

struct PolyLine
{
   PolyLine() : mPointIndex0(-1), mPointIndex1(-1) { }
   int             mPointIndex0;
   int             mPointIndex1;
   double          mThickness;
   unsigned int    mJoints;
   unsigned int    mCaps;
   unsigned int    mPixelHinting;
   double          mMiterLimit;
};


struct RenderArgs
{
   int inN;
   const PointF16 *inPoints;
   const PolyLine *inLines;
   const char     *inConnect;
   Sint32 inMinY;
   Sint32 inMaxY;
   Uint32 inFlags;
};

class PolygonRenderer
{
public:
   virtual ~PolygonRenderer() {}
   virtual void Render(SDL_Surface *outDest,
                         Sint16 inOffsetX=0,Sint16 inOffsetY=0)=0;
   virtual bool HitTest(int inX,int inY)=0;

   static PolygonRenderer *CreateSolidRenderer(
                              const RenderArgs &inArgs,
                              int inColour, double inAlpha);


   static PolygonRenderer *CreateGradientRenderer(
                              const RenderArgs &inArgs,
                              class Gradient *inGradient );

   static PolygonRenderer *CreateBitmapRenderer(
                              const RenderArgs &inArgs,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource );
};



#endif
