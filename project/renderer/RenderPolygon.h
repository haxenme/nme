#ifndef RENDERER_RENDER_POLYGON_H
#define RENDERER_RENDER_POLYGON_H

#include <math.h>
#include <algorithm>
#include <map>
#include "Renderer.h"
#include "Pixel.h"
#include "Points.h"


struct AlphaRun
{
   inline AlphaRun() { }
   inline AlphaRun(int inX0,int inX1,short inAlpha) : mX0(inX0), mX1(inX1), mAlpha(inAlpha) { }
   inline bool Contains(int inX) const { return inX >= mX0 && inX<mX1; }

   short mX0,mX1;
   // mAlpha is 0 ... 256 inclusive
   short mAlpha;
};
typedef std::vector<AlphaRun> AlphaRuns;
typedef std::vector<AlphaRuns> Lines;



// --- Polygon ---------------------------------------------

class PolygonMask : public MaskObject
{
public:
   PolygonMask() : mMinY(0), mMaxY(-1) { mID = sMaskID++; }
   void Add(const PolygonMask &inMask);
   void Mask(const PolygonMask &inMask);
   int GetID() { return mID; }
   void GetExtent(Extent2DI &ioExtent);
   void ClipY(int &ioY)
   {
      if (ioY<mMinY) ioY = mMinY;
      else if (ioY>mMaxY) ioY = mMaxY;
   }

   PolygonMask *GetPolygonMask() { return this; }

   int mID;
   int mMinY;
   int mMaxY;
   Lines mLines;
   Extent2DI mExtent;

   static int sMaskID;
};


class BasePolygonRenderer :public PolygonMask, public PolygonRenderer
{
public:
   BasePolygonRenderer(const RenderArgs &inArgs);
   bool HitTest(int inX,int inY);
   void AddToMask(PolygonMask &ioMask) { ioMask.Add(*this); }
   void Mask(const PolygonMask &inMask) { PolygonMask::Mask(inMask); }
   void GetExtent(Extent2DI &ioExtent) { PolygonMask::GetExtent(ioExtent); }



   ~BasePolygonRenderer() { }


private: // Disable
   BasePolygonRenderer(const BasePolygonRenderer &inRHS);
   void operator =(const BasePolygonRenderer &inRHS);
};




template<typename SOURCE_>
class SourcePolygonRenderer : public BasePolygonRenderer
{
public:
   SourcePolygonRenderer(const RenderArgs &inArgs, const SOURCE_ &inSource)
      : BasePolygonRenderer(inArgs), mSource(inSource)
   {
      // mSource is copy-constructed, so yo ubetter be sure this will
      //  work (rule of three)
   }

   template<typename DEST_>
   void RenderDest(DEST_ &outDest,const Viewport &inViewport,int inTX,int inTY)
   {
      int y0 = mMinY + inTY;
      int y1 = mMaxY + inTY;
      inViewport.ClipY(y0,y1);
      for(int y=y0; y<y1; y++)
      {
         int sy = y - inTY;
         const AlphaRuns &line = mLines[y-mMinY-inTY];
         AlphaRuns::const_iterator end = line.end();
         AlphaRuns::const_iterator run = line.begin();
         if (run!=end)
         {
            outDest.SetRow(y);
            while(run<end)
            {
               int x0 = run->mX0 + inTX;
               if (x0 >= inViewport.x1)
                  break;
               int x1 = run->mX1 + inTX;
               if (x1>inViewport.x0)
               {
                  inViewport.ClipX(x0,x1);
                  outDest.SetX(x0);
                  mSource.SetPos(x0-inTX,sy);
                  int alpha = run->mAlpha;
                  if (alpha<255)
                     while(x0<x1)
                     {
                        ++x0;
                        outDest.SetIncBlend(mSource.Value(alpha));
                        mSource.Inc();
                     }
                  else
                     while(x0<x1)
                     {
                        ++x0;
                        outDest.SetIncBlend(mSource.Value());
                        mSource.Inc();
                     }
               }
               ++run;
            }
         }
      }
   }

   void Render(SDL_Surface *outDest,const Viewport &inViewport,int inTX,int inTY)
   {
      if ( SDL_MUSTLOCK(outDest) )
         if ( SDL_LockSurface(outDest) < 0 )
            return;

      switch(outDest->format->BytesPerPixel)
      {
         // Slow methods...
         case 1: case 3:
         {
            DestSurfaceFallback d(outDest); RenderDest(d,inViewport,inTX,inTY);
            break;
         }

         case 4:
         {
            if (outDest->format->Amask)
            {
               DestSurface32<ARGB> d(outDest);
               RenderDest(d,inViewport,inTX,inTY);
            }
            else
            {
               DestSurface32<XRGB> d(outDest);
               RenderDest(d,inViewport,inTX,inTY);
            }
            break;
         }
      }

      if ( SDL_MUSTLOCK(outDest)  )
         SDL_UnlockSurface(outDest);
   }


   SOURCE_ mSource;
};


#endif

