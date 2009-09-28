#ifndef INTERNAL_RENDER_H
#define INTERNAL_RENDER_H

#include "AlphaMask.h"
#include <Pixel.h>



template<typename SOURCE_, typename DEST_, typename BLEND_>
void DestRender(const AlphaMask &inAlpha, SOURCE_ &inSource, DEST_ &outDest, const BLEND_ &inBlend,
            const RenderState &inState, int inTX, int inTY)
{
   if (inAlpha.mLines.empty())
      return;
   int y = inAlpha.mRect.y + inTY;
   const AlphaRuns *lines = &inAlpha.mLines[0] - y;

   int y1 = inAlpha.mRect.y1() + inTY;

   Rect clip = inState.mClipRect.Intersect(outDest.GetRect());

   if (inState.mMask)
      clip = clip.Intersect(inState.mMask->GetRect());

   clip.ClipY(y,y1);

   for(; y<y1; y++)
   {
      int sy = y - inTY;
      const AlphaRuns &line = lines[y];
      AlphaRuns::const_iterator end = line.end();
      AlphaRuns::const_iterator run = line.begin();
      if (run!=end)
      {
         outDest.SetRow(y);
         while(run<end && run->mX1 + inTX<=clip.x)
            run++;

         if (inState.mMask)
         {
            const Uint8 *mask0 = inState.mMask->Row(y);
            while(run<end)
            {
               int x0 = run->mX0 + inTX;
               if (x0 >= clip.x1())
                  break;
               int x1 = run->mX1 + inTX;
               clip.ClipX(x0,x1);

               outDest.SetX(x0);
               inSource.SetPos(x0,sy);
               const Uint8 *m = mask0 + x0;
               while(x0++<x1)
               {
                  int alpha = (run->mAlpha * (*m++))>>8;

                  if (DEST_::HasAlpha)
                      inBlend.BlendAlpha( outDest,inSource,alpha );
                  else
                      inBlend.BlendNoAlpha( outDest,inSource,alpha );
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
               inSource.SetPos(x0,sy);
               int alpha = run->mAlpha;

               while(x0++<x1)
                  if (DEST_::HasAlpha)
                      inBlend.BlendAlpha( outDest,inSource,alpha );
                  else
                      inBlend.BlendNoAlpha( outDest,inSource,alpha );
               ++run;
            }
         }
      }
   }
};

template<bool HAS_ALPHA>
struct DestSurface32
{
   enum { HasAlpha = HAS_ALPHA };

   DestSurface32(const RenderTarget &inTarget) : mTarget(inTarget) { }

   void SetRow(int inY) { mRow = (ARGB *)( mTarget.data + mTarget.stride*inY ); }
   void SetX(int inX) { mPtr = mRow + inX; }
   const ARGB Get() { return *mPtr; }
   void SetInc( ARGB inCol ) { *mPtr++ = inCol; }
   const Rect &GetRect() const { return mTarget.mRect; }

   ARGB *mRow;
   ARGB *mPtr;
   const RenderTarget &mTarget;
};


// 1, 2 ro 3 of these
template<typename SOURCE_, typename BLEND_>
void Render(const AlphaMask &inAlpha, SOURCE_ &inSource, const RenderTarget &inDest, const BLEND_ &inBlend,
            const RenderState &inState, int inTX, int inTY)
{
   if (inDest.format & pfHasAlpha)
   {
      DestSurface32<true> dest(inDest);
      DestRender(inAlpha, inSource, dest, inBlend, inState, inTX, inTY);
   }
   else
   {
      DestSurface32<false> dest(inDest);
      DestRender(inAlpha, inSource, dest, inBlend, inState, inTX, inTY);
   }
}


template<bool SWAP_RB>
struct NormalBlender
{
   template<bool DEST_ALPHA,typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
      ARGB src = inSrc.GetInc();
      src.a = (src.a * inAlpha)>>8;
      ARGB dest = inDest.Get();
      dest.Blend<SWAP_RB,DEST_ALPHA>(src);
      inDest.SetInc(dest);
   }
   template<typename DEST, typename SRC>
   void BlendNoAlpha(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
       Blend<false>(inDest,inSrc,inAlpha);
   }
   template<typename DEST, typename SRC>
   void BlendAlpha(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
       Blend<true>(inDest,inSrc,inAlpha);
   }
};

template<bool SWAP_RB>
struct NormalBlenderAlphaLut
{
   NormalBlenderAlphaLut(const Uint8 *inLUT) : mAlphaLut(inLUT) { }
   const Uint8 *mAlphaLut;

   template<bool DEST_ALPHA,typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
      ARGB src = inSrc.GetInc();
      src.a = mAlphaLut[inAlpha];
      ARGB dest = inDest.Get();
      dest.Blend<SWAP_RB,DEST_ALPHA>(src);
      inDest.SetInc(dest);
   }
   template<typename DEST, typename SRC>
   void BlendNoAlpha(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
      Blend<false>(inDest,inSrc);
   }
   template<typename DEST, typename SRC>
   void BlendAlpha(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
      Blend<true>(inDest,inSrc);
   }
};


# if 0
// 4 of these
template<bool ALPHA_LUT, bool DEST_HAS_ALPHA>
struct NormalBlender
{
   int *mAlphaLut;
   template<typename DEST, typename SRC>

   void Blend(DEST &inDest, SRC &inSrc,int inAlpha)
   {
      ARGB col = ALPHA_LUT ? inSrc.GetInc(mAlphaLut[inAlpha]) : inSrc.GetInc(inAlpha);
      if (col.a>250)
         inDest.SetInc(col);
      else
      {
         ARGB dest = inDest.Get();
         if (dest.a<5)
            inDest.SetInc(col);
         else
         {
            // Alpha blend...
            inDest.SetInc(col);
         }
      }
   }
};


// 2 of these
template<bool AlphaLUT>
struct CopyBlender
{
   template<typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha)
   {
      inDest.SetInc( inSrc.GetInc(inAlpha) );
   }
};


// 1 of these
struct SpecialBlender
{
   SpecialBlender(inBlendMode, inDestHasAlpha, bool inReverseRGB );
   BlendFunc *mFunc;
   template<typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha)
   {
      inDest.SetInc( mFunc(inSrc.GetInc(inAlpha), inDest.Get(in)) );
   }
};

// 3 types of these ...
template<bool ALPHA_LUT, bool COLOUR_TRANS>
struct SpecialTransformBlender
{
   BlendFunc *mFunc;
   AlphaLUT  *mAlphaLUT;
   ColourTransform mTransform;

   template<typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha)
   {
   }
};

// 10 different blenders - too many?



class BitmapFillRenderer
{
   void Render(AlphaMask *inAlpha, RenderTarget *inTarget, RenderState &inState)
   {
      // 4 * renderes
      if (!inTarget->IsMainRGBORder() || inState.HasColourTransform())
      {
         if (inState.HasAlphaTransform())
            if (inState.HasColourTransform())
            else (inState.HasColourTransform())
        else (inState.HasAlphaTransform())
            if (inState.HasColourTransform())
            else (inState.HasColourTransform())
      }

      if (alpha)
      {
         switch(inState.mBlendMode)
         {
            case bmCopy : Render(inAlpha, *this, inTarget, CopyBlender() ); break;
            case bmNormal : Render(inAlpha, *this, inTarget, NormalBlender<false>() ); break;
            default:
                Render(inAlpha, *this, inTarget, SpecialBlender(inState.mBlendMode,outDest.HasAlpha(),false) );
         }
      }
      else
      {
         switch(inState.mBlendMode)
         {
            case bmCopy : Render(inAlpha, *this, inTarget, CopyBlender() ); break;
            case bmNormal : Render(inAlpha, *this, inTarget, NormalBlender<false>() ); break;
            default:
                Render(inAlpha, *this, inTarget, SpecialBlender(inState.mBlendMode,outDest.HasAlpha(),false) );
         }
      }
   }

   ARGB GetPixel()
   {
      DoGetPixel();
   }

   ARGB mColour;
   ARGB mMatchingColour;
};


#endif


#endif



