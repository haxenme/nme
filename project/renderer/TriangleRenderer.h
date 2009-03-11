#ifndef TRIANGLE_RENDERER_H
#define TRIANGLE_RENDERER_H

#include "RenderPolygon.h"
#include <algorithm>

void SetTextureMapping( Matrix &outMatrix, const TriPoint &inP0, const TriPoint &inP1, const TriPoint &inP2, int inTX, int inTY );


template<typename SOURCE_,bool DO_TEXTURE=false>
class TTriangleRenderer : public PolygonRenderer
{
   enum { AABits = 0 };
   enum { mToAA = 16 };
public:
   TTriangleRenderer( const TriPoints &inPoints, const Tris &inTriangles, const SOURCE_ &inSrc)
       : mSrc(inSrc)
   {
      mTriangleCount = inTriangles.size();
      if (mTriangleCount>0)
      {
         mTriangles = &inTriangles[0];
         mPoints = &inPoints[0];
      }
      else
      {
         mTriangles = 0;
         mPoints = 0;
      }
   }

   ~TTriangleRenderer() {}

   inline int Grad(PointF16 inVec)
   {
      int denom = inVec.y;
      if (inVec.y==0)
         return 0;
      int64 num = inVec.x;
      num<<=mToAA;
      return (int)(num/denom);
   }

   template<typename DEST_>
   inline void HLine(DEST_ &outDest,const Viewport &inVp, int y,int inX0,int inX1)
   {
      int x = std::max(inVp.x0, inX0);
      int x1 = std::min(inVp.x1, inX1);
      mSrc.SetPos(x,y);
      outDest.SetX(x);
      while(x<x1)
      {
         outDest.SetIncBlend(mSrc.Value());
         mSrc.Inc();
         x++;
      }
   }


   template<typename DEST_>
   void RenderDest(DEST_ &outDest,const Viewport &inViewport,int inTX,int inTY)
   {
      int tx16 = inTX<<16;
      for(size_t t=0;t<mTriangleCount;t++)
      {
         const Tri &tri = mTriangles[t];
         int idx0 = tri.mIndex[0];
         int idx1 = tri.mIndex[1];
         int idx2 = tri.mIndex[2];
         // Sort on y ...
         if (mPoints[idx1].mPos16.y < mPoints[idx0].mPos16.y) std::swap(idx0,idx1);
         if (mPoints[idx2].mPos16.y < mPoints[idx0].mPos16.y) std::swap(idx0,idx2);
         if (mPoints[idx2].mPos16.y < mPoints[idx1].mPos16.y) std::swap(idx1,idx2);


   /*


       |     +0      |
     dy0    / \  xb  |      top triangle
       |   /   \     dy1
         1+.....\    |
     |      \    \   |      bottom triangle
     |         \  \  |     
    dy2  xa      \+2
     |        

   */


         PointF16 p0 = mPoints[idx0].mPos16;
         PointF16 p1 = mPoints[idx1].mPos16;
         PointF16 p2 = mPoints[idx2].mPos16;


         int y0 = p0.Y(AABits) + inTY;
         int y1 = p1.Y(AABits) + inTY;
         int y2 = p2.Y(AABits) + inTY;

         if (y2==y0 || inViewport.y0>=y2 || inViewport.y1<y0) continue;

         int dxa_dy0 = Grad(p1-p0);
         int dxa_dy2 = Grad(p2-p1);
         int dxb_dy1 = Grad(p2-p0);

         if (DO_TEXTURE)
            mSrc.SetMapping(mPoints[idx0], mPoints[idx1], mPoints[idx2], inTX, inTY);

         // F16 fractional row ...
         int y = y0;
         int extra_y = (((y+1-inTY)<<mToAA)-p0.y)>>8;
         int xa = p0.x + tx16 + (dxa_dy0>>(mToAA-8)) * extra_y;
         int xb = p0.x + tx16 + (dxb_dy1>>(mToAA-8)) * extra_y;


         // Top triangle ...
         //
         // Skip top until we hit the viewport
         int skip = inViewport.y0 - y;
         if (skip>0)
         {
            if (y+skip>y1)  skip = y1-y;
            xa+= dxa_dy0*skip;
            xb+= dxb_dy1*skip;
            y+= skip;
         }
         if (y1>inViewport.y1)
            y1 = inViewport.y1;

         while(y<y1)
         {
            outDest.SetRow(y);
            if (xa<xb)
               HLine(outDest,inViewport, y,xa>>mToAA,xb>>mToAA);
            else
               HLine(outDest,inViewport, y,xb>>mToAA,xa>>mToAA);
            xa+=dxa_dy0;
            xb+=dxb_dy1;
            y++;
         }

         // middle bit
         extra_y = (((y+1-inTY)<<mToAA)-p1.y)>>8;
         xa = p1.x + tx16 + (dxa_dy2>>(mToAA-8)) * extra_y;

         if (y2>inViewport.y1)
            y2 = inViewport.y1;
         // skip until we hit viewport?
         skip = inViewport.y0 - y;
         if (skip>0)
         {
            xa+= dxa_dy2*skip;
            xb+= dxb_dy1*skip;
            y+= skip;
         }

         while(y<y2)
         {
            outDest.SetRow(y);
            if (xa<xb)
               HLine(outDest,inViewport, y,xa>>mToAA,xb>>mToAA);
            else
               HLine(outDest,inViewport, y,xb>>mToAA,xa>>mToAA);
            xa+=dxa_dy2;
            xb+=dxb_dy1;
            y++;
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

   bool HitTest(int inX,int inY) { return false; }
   void AddToMask(PolygonMask &ioMask,int inTX,int inTY) { }
   void Mask(const PolygonMask &inMask) { }
   void GetExtent(Extent2DI &ioExtent)
   {
      for(size_t t=0;t<mTriangleCount;t++)
      {
         const Tri &tri = mTriangles[t];
         for(int i=0;i<3;i++)
         {
            const TriPoint &p = mPoints[tri.mIndex[i]];
            ioExtent.Add(p.mPos16.x>>16, p.mPos16.y>>16);
         }
      }
   }

   SOURCE_ mSrc;
   size_t  mTriangleCount;
   const TriPoint *mPoints;
   const Tri *mTriangles;
};

#endif


