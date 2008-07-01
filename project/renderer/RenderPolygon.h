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


class BasePolygonRenderer : public PolygonRenderer
{
public:
   BasePolygonRenderer(const RenderArgs &inArgs);
   bool HitTest(int inX,int inY);
   void GetExtent(Extent2DI &ioExtent);
   ~BasePolygonRenderer() { }

   int mMinY;
   int mMaxY;
   Lines mLines;

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
   void RenderDest(DEST_ &outDest)
   {
      for(int y=mMinY; y<mMaxY; y++)
      {
         const AlphaRuns &line = mLines[y-mMinY];
         AlphaRuns::const_iterator end = line.end();
         AlphaRuns::const_iterator run = line.begin();
         if (run!=end)
         {
            outDest.SetRow(y);
            while(run<end)
            {
               int x0 = run->mX0;
               if (x0 >= outDest.mMaxX)
                  break;
               int x1 = run->mX1;
               if (x1>outDest.mMinX)
               {
                  if (x0<outDest.mMinX) x0 = outDest.mMinX;
                  if (x1>outDest.mMaxX) x1 = outDest.mMaxX;
                  outDest.SetX(x0);
                  mSource.SetPos(x0,y);
                  int alpha = run->mAlpha;
                  if (alpha<256)
                     while(x0<x1)
                     {
                        ++x0;
                        outDest.SetIncBlend(mSource,alpha);
                        mSource.Inc();
                     }
                  else
                     while(x0<x1)
                     {
                        ++x0;
                        outDest.SetInc(mSource);
                        mSource.Inc();
                     }
               }
               ++run;
            }
         }
      }
   }

   void Render(SDL_Surface *outDest)
   {
      if ( SDL_MUSTLOCK(outDest) )
         if ( SDL_LockSurface(outDest) < 0 )
            return;

      // TODO : 2
      switch(outDest->format->BytesPerPixel)
      {
         case 1: { DestSurface8 d(outDest); RenderDest(d); } break;
         case 3: { DestSurface24 d(outDest); RenderDest(d); } break;
         case 4: { DestSurface32 d(outDest); RenderDest(d); } break;
      }

      if ( SDL_MUSTLOCK(outDest)  )
         SDL_UnlockSurface(outDest);
   }


   SOURCE_ mSource;
};


#endif

