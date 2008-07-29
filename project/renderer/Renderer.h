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
#define NME_clip_xmax(pnt) pnt->clip_rect.x + pnt->clip_rect.w
#define NME_clip_ymin(pnt) pnt->clip_rect.y
#define NME_clip_ymax(pnt) pnt->clip_rect.y + pnt->clip_rect.h



#include "Points.h"



typedef std::vector<int> IntVec;

// The rendering code will know what to do with this ...
class PolygonMask;

class MaskObject
{
public:
   virtual ~MaskObject() { }
   virtual PolygonMask *GetPolygonMask() = 0;
   virtual int GetID() = 0;
   virtual void ClipY(int &ioY) = 0;
   virtual void GetExtent(Extent2DI &ioExtent)=0;

   static MaskObject *Create();
};

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

struct Viewport
{
   Viewport(int inX0,int inY0,int inX1,int inY1) : x0(inX0), y0(inY0), x1(inX1), y1(inY1)
   {
   }
   bool IsWindow(int inW,int inH) const
   {
      return x0==0 && y0==0 && x1==inW && y1==inH;
   }
   int Width() const { return x1-x0; }
   int Height() const { return y1-y0; }

   void SetWindow(int inX0,int inY0,int inX1,int inY1)
   {
      if (x0<inX0) x0 = inX0;
      if (x1>inX1) x1 = inX1;
      if (y0<inY0) y0 = inY0;
      if (y1>inY1) y1 = inY1;
   }
   inline void ClipX(int &ioX0,int &ioX1) const
   {
      if (ioX0 < x0) ioX0 = x0;
      if (ioX1 > x1) ioX1 = x1;
   }
   inline void ClipY(int &ioY0,int &ioY1) const
   {
      if (ioY0 < y0) ioY0 = y0;
      if (ioY1 > y1) ioY1 = y1;
   }



   int x0,y0;
   int x1,y1;
};

class PolygonRenderer
{
public:
   virtual ~PolygonRenderer() {}
   virtual void Render(SDL_Surface *outDest,const Viewport &inViewport,int inTX,int inTY) = 0;
   virtual bool HitTest(int inX,int inY)=0;
   virtual void AddToMask(PolygonMask &ioMask,int inTX,int inTY)=0;
   virtual void Mask(const PolygonMask &inMask)=0;
   virtual void GetExtent(Extent2DI &ioExtent)=0;


   static PolygonRenderer *CreateSolidRenderer(
                              const RenderArgs &inArgs,
                              int inColour, double inAlpha);


   static PolygonRenderer *CreateGradientRenderer(
                              const RenderArgs &inArgs,
                              class Gradient *inGradient );

   static PolygonRenderer *CreateBitmapRenderer(
                              const RenderArgs &inArgs,
                              SDL_Surface *inSource,
                              const class Matrix &inMapper);
};



#endif
