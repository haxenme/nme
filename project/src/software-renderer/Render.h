#ifndef INTERNAL_RENDER_H
#define INTERNAL_RENDER_H

#include "AlphaMask.h"
#include <nme/Pixel.h>



namespace nme
{


template<typename SOURCE_, typename DEST_, typename BLEND_>
void DestRender(const AlphaMask &inAlpha, SOURCE_ &inSource, DEST_ &outDest, const BLEND_ &inBlend,
            const RenderState &inState, int inTX, int inTY)
{
   if (inAlpha.mLineStarts.size()<2)
      return;
   int y = inAlpha.mRect.y + inTY;
   const int *lines = &inAlpha.mLineStarts[0] - y;

   int y1 = inAlpha.mRect.y1() + inTY;

   Rect clip = inState.mClipRect.Intersect(outDest.GetRect());

   if (inState.mMask)
      clip = clip.Intersect(inState.mMask->GetRect().Translated(-inState.mTargetOffset));

   clip.ClipY(y,y1);

   for(; y<y1; y++)
   {
      const AlphaRun *run = &inAlpha.mAlphaRuns[ lines[y] ];
      const AlphaRun *end = &inAlpha.mAlphaRuns[ lines[y+1] ];
      if (run!=end)
      {
         outDest.SetRow(y);
         while(run<end && run->mX1 + inTX<=clip.x)
            run++;

         if (inState.mMask)
         {
            const Uint8 *mask0 = inState.mMask->DestRow(y+inState.mTargetOffset.y) +
                                    inState.mTargetOffset.x;
            while(run<end)
            {
               int x0 = run->mX0 + inTX;
               if (x0 >= clip.x1())
                  break;
               int x1 = run->mX1 + inTX;
               clip.ClipX(x0,x1);

               outDest.SetX(x0);
               inSource.SetPos(x0,y);
               const Uint8 *m = mask0 + x0;
               while(x0++<x1)
               {
                  int alpha = (run->mAlpha * (*m++))>>8;
                  inBlend.blend( outDest.GetInc(),inSource.GetInc(),alpha );
               }
               ++run;
            }
         }
         else
         {
            while(run<end)
            {
               int x0 = run->mX0 + inTX;
               if (x0 >= clip.x1())
                  break;
               int x1 = run->mX1 + inTX;
               clip.ClipX(x0,x1);

               outDest.SetX(x0);
               inSource.SetPos(x0,y);
               int alpha = run->mAlpha;
               if (alpha==256)
               {
                  while(x0++<x1)
                     inBlend.blend( outDest.GetInc(),inSource.GetInc() );
               }
               else
               {
                  while(x0++<x1)
                     inBlend.blend( outDest.GetInc(),inSource.GetInc(),alpha );
               }

               ++run;
            }
         }
      }
   }
};

template<typename DEST>
struct DestSurface
{
   DestSurface(const RenderTarget &inTarget) : mTarget(inTarget) { }

   void SetRow(int inY) { mRow = (DEST *) mTarget.Row(inY); }
   void SetX(int inX) { mPtr = mRow + inX; }
   const DEST Get() { return *mPtr; }
   DEST &GetInc( ) { return *mPtr++; }
   const Rect &GetRect() const { return mTarget.mRect; }

   DEST *mRow;
   DEST *mPtr;
   const RenderTarget &mTarget;
};


struct NoTransform
{
   inline void apply(AlphaPixel &ioPixel) const { }
   inline void apply(BGRPremA &ioPixel) const { }
   inline void apply(ARGB  &ioPixel) const { }
   inline void apply(RGB &ioPixel) const { }
};


struct TransformRGBA
{
   const uint8 *mAlpha_LUT;
   const uint8 *mR_LUT;
   const uint8 *mG_LUT;
   const uint8 *mB_LUT;

   TransformRGBA(const RenderState &inState)
   {
      mAlpha_LUT = inState.mAlpha_LUT;
      mR_LUT = inState.mR_LUT;
      mG_LUT = inState.mG_LUT;
      mB_LUT = inState.mB_LUT;
   }
 
   inline void apply(AlphaPixel &ioPixel) const
   {
      ioPixel.a = mAlpha_LUT[ioPixel.a];
   }
   inline void apply(BGRPremA &ioPixel) const
   {
      int transA = mAlpha_LUT[ioPixel.a];
      ioPixel.a = transA;
      if (transA==255)
      {
         ioPixel.r = mAlpha_LUT[ioPixel.getR()];
         ioPixel.g = mAlpha_LUT[ioPixel.getG()];
         ioPixel.b = mAlpha_LUT[ioPixel.getB()];
      }
      else
      {
         Uint8 *lut = gPremAlphaLut[transA];
         ioPixel.r = lut[mR_LUT[ioPixel.getR()]];
         ioPixel.g = lut[mG_LUT[ioPixel.getG()]];
         ioPixel.b = lut[mB_LUT[ioPixel.getB()]];
      }
   }
   inline void apply(ARGB  &ioPixel) const
   {
      ioPixel.a = mAlpha_LUT[ioPixel.a];
      ioPixel.r = mR_LUT[ioPixel.getR()];
      ioPixel.g = mG_LUT[ioPixel.getG()];
      ioPixel.b = mB_LUT[ioPixel.getB()];
   }
   inline void apply(RGB &ioPixel) const
   {
      ioPixel.r = mR_LUT[ioPixel.getR()];
      ioPixel.g = mG_LUT[ioPixel.getG()];
      ioPixel.b = mB_LUT[ioPixel.getB()];
   }
};


struct TransformRGB
{
   const uint8 *mR_LUT;
   const uint8 *mG_LUT;
   const uint8 *mB_LUT;

   TransformRGB(const RenderState &inState)
   {
      mR_LUT = inState.mR_LUT;
      mG_LUT = inState.mG_LUT;
      mB_LUT = inState.mB_LUT;
   }
 
   inline void apply(AlphaPixel &ioPixel) const
   {
   }
   inline void apply(BGRPremA &ioPixel) const
   {
      Uint8 *lut = gPremAlphaLut[ioPixel.a];
      ioPixel.r = lut[mR_LUT[ioPixel.getR()]];
      ioPixel.g = lut[mG_LUT[ioPixel.getG()]];
      ioPixel.b = lut[mB_LUT[ioPixel.getB()]];
   }
   inline void apply(ARGB  &ioPixel) const
   {
      ioPixel.r = mR_LUT[ioPixel.getR()];
      ioPixel.g = mG_LUT[ioPixel.getG()];
      ioPixel.b = mB_LUT[ioPixel.getB()];
   }
   inline void apply(RGB &ioPixel) const
   {
      ioPixel.r = mR_LUT[ioPixel.getR()];
      ioPixel.g = mG_LUT[ioPixel.getG()];
      ioPixel.b = mB_LUT[ioPixel.getB()];
   }
};


struct TransformA
{
   const uint8 *mAlpha_LUT;

   TransformA(const RenderState &inState)
   {
      mAlpha_LUT = inState.mAlpha_LUT;
   }
 
   inline void apply(AlphaPixel &ioPixel) const
   {
      ioPixel.a = mAlpha_LUT[ioPixel.a];
   }
   inline void apply(BGRPremA &ioPixel) const
   {
      int transA = mAlpha_LUT[ioPixel.a];
      if (ioPixel.a!=0)
      {
         ioPixel.r = ioPixel.r * transA/ioPixel.a;
         ioPixel.g = ioPixel.g * transA/ioPixel.a;
         ioPixel.b = ioPixel.b * transA/ioPixel.a;
      }
      ioPixel.a = transA;
   }
   inline void apply(ARGB  &ioPixel) const
   {
      ioPixel.a = mAlpha_LUT[ioPixel.a];
   }
   inline void apply(RGB &ioPixel) const
   {
   }
};



template<typename TRANSFORM>
struct Blender
{
   TRANSFORM transform;

   Blender(const TRANSFORM &inTransform) : transform(inTransform) { }

   template<typename DEST, typename SRC>
   void blend(DEST &ioDest, SRC inSrc) const
   {
      transform.apply(inSrc);
      BlendPixel(ioDest, inSrc);
   }

   template<typename DEST, bool PREM>
   void blend(DEST &ioDest, BGRA<PREM> inSrc,int inAlpha256) const
   {
      if (PREM)
      {
         inSrc.r = (inSrc.r*inAlpha256)>>8;
         inSrc.g = (inSrc.g*inAlpha256)>>8;
         inSrc.b = (inSrc.b*inAlpha256)>>8;
      }
      inSrc.a = (inSrc.a*inAlpha256)>>8;
      transform.apply(inSrc);
      BlendPixel(ioDest, inSrc);
   }

   template<typename DEST>
   void blend(DEST &ioDest, RGB inSrc,int inAlpha256) const
   {
      ARGB argb;
      argb.r = inSrc.r;
      argb.g = inSrc.g;
      argb.b = inSrc.b;
      argb.a = inAlpha256 - (inAlpha256>>7);
      transform.apply(argb);
      BlendPixel(ioDest, argb);
   }

   template<typename DEST>
   void blend(DEST &ioDest, AlphaPixel src,int inAlpha256) const
   {
      src.a = (src.a * inAlpha256) >> 8;
      transform.apply(src);
      BlendPixel(ioDest, src);
   }
};



template<typename SOURCE_,typename BLEND_>
void RenderBlend(const AlphaMask &inAlpha, SOURCE_ &inSource, const RenderTarget &inDest,
            const BLEND_ &inBlend, const RenderState &inState, int inTX, int inTY)
{
   switch(inDest.mPixelFormat)
   {
      case pfAlpha:
         DestRender(inAlpha, inSource, DestSurface<AlphaPixel>(inDest), inBlend, inState, inTX, inTY);
         break;
      case pfBGRA:
         DestRender(inAlpha, inSource, DestSurface<ARGB>(inDest), inBlend, inState, inTX, inTY);
         break;
      case pfBGRPremA:
         DestRender(inAlpha, inSource, DestSurface<BGRPremA>(inDest), inBlend, inState, inTX, inTY);
         break;
      case pfRGB:
         DestRender(inAlpha, inSource, DestSurface<RGB>(inDest), inBlend, inState, inTX, inTY);
         break;
   }
}


#define RENDER( BLENDER ) \
   RenderBlend(inAlpha,inSource, inDest, BLENDER, inState, inTX, inTY)



template<typename SOURCE_>
void Render(const AlphaMask &inAlpha, SOURCE_ &inSource, const RenderTarget &inDest,
            const RenderState &inState, int inTX, int inTY)
{
   if (inState.HasAlphaLUT() && inState.HasColourLUT())
      RENDER( Blender<TransformRGBA>( TransformRGBA(inState) ) );
   else if (inState.HasAlphaLUT() && !inState.HasColourLUT())
      RENDER( Blender<TransformA>( TransformA(inState) ));
   else if (inState.HasAlphaLUT() && inState.HasColourLUT())
      RENDER( Blender<TransformRGB>( TransformRGB(inState) ));
   else
      RENDER( Blender<NoTransform>( NoTransform() ));
}

} // end namespace nme

#endif
