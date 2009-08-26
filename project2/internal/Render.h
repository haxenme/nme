#ifndef INTERNAL_RENDER_H
#define INTERNAL_RENDER_H

#include "AlphaMask.h"
#include <Pixel.h>

/*
Dest:
  HasAlpha

  SetRow(int)
  SetX(int)
  Get()
  SetInc( XRGB )

Src:
   SetRow(int)
   SetX(int)
   GetInc( )


RenderState:
   mClip
   ColourTransform
   Alpha?
   BlendFunc

Blender
   Blend(dest,src,alpha)


*/




template<typename SOURCE_, typename DEST_, typename BLEND_>
void DestRender(const AlphaMask &inMask, SOURCE_ &inSource, DEST_ &outDest, BLEND_ &inBlend,
            const Rect &inClip, int inTX, int inTY)
{
   int y = inMask.mRect.y + inTY;
   const AlphaRuns *lines = &inMask.mLines[0] - y;

   int y1 = inMask.mRect.y1() + inTY;
   inClip.ClipY(y,y1);

   for(; y<y1; y++)
   {
      int sy = y - inTY;
      const AlphaRuns &line = lines[y];
      AlphaRuns::const_iterator end = line.end();
      AlphaRuns::const_iterator run = line.begin();
      if (run!=end)
      {
         outDest.SetRow(y);
         while(run<end)
         {
            int x0 = run->mX0 + inTX;
            if (x0 >= inClip.x1())
               break;
            int x1 = run->mX1 + inTX;
            if (x1 <= inClip.x)
               continue;

            inClip.ClipX(x0,x1);

            outDest.SetX(x0);
            inSource.SetPos(x0-inTX,sy);
            int alpha = run->mAlpha;

            while(x0++<x1)
               inBlend.Blend<DEST_::HasAlpha>(outDest,inSource,alpha);
            ++run;
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

	ARGB *mRow;
	ARGB *mPtr;
	const RenderTarget &mTarget;
};


// 1, 2 ro 3 of these
template<typename SOURCE_, typename BLEND_>
void Render(const AlphaMask &inMask, SOURCE_ &inSource, const RenderTarget &inDest, BLEND_ &inBlend,
            const Rect &inClipRect, int inTX, int inTY)
{
	if (inDest.format & pfHasAlpha)
      DestRender(inMask, inSource, DestSurface32<true>(inDest), inBlend, inClipRect, inTX, inTY);
	else
      DestRender(inMask, inSource, DestSurface32<false>(inDest), inBlend, inClipRect, inTX, inTY);
}


template<bool SWAP_RB>
struct NormalBlender
{
	template<bool DEST_ALPHA,typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha)
   {
		ARGB src = inSrc.GetInc();
		src.a = inAlpha;
		ARGB dest = inDest.Get();
		dest.Blend<SWAP_RGB,DEST_ALPHA>(src);
		inDest.SetInc(dest);
	}
};

template<bool SWAP_RB>
struct NormalBlenderAlphaLut
{
	NormalBlenderAlphaLut(const Uint8 *inLUT) : mAlphaLut(inLUT) { }
	const Uint8 *mAlphaLut;

	template<bool DEST_ALPHA,typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha)
   {
		ARGB src = inSrc.GetInc();
		src.a = mAlphaLut[inAlpha];
		ARGB dest = inDest.Get();
		dest.Blend<SWAP_RGB,DEST_ALPHA>(src);
		inDest.SetInc(dest);
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


class SolidFillRenderer
{
   void Render(AlphaMask *inMask, RenderTarget *inTarget, RenderState &inState)
   {
      if (inTarget->IsMainRGBORder())
         mMatchingColour = mColour;

      mColour.a = inState.GetAlphaRamp()[mColour.a];
      switch(inState.mBlendMode)
      {
         case bmCopy : Render(inMask, *this, inTarget, CopyBlender() ); break;
         case bmNormal :
               if (dest_has_alpha)
                  Render(inMask, *this, inTarget, NormalBlender<false,true>() ); break;
               else
                  Render(inMask, *this, inTarget, NormalBlender<false,false>() ); break;
         default:
             Render(inMask, *this, inTarget, SpecialBlender(inState.mBlendMode,outDest.HasAlpha(),false) );
      }
   }

   ARGB mColour;
   ARGB mMatchingColour;
};






class BitmapFillRenderer
{
   void Render(AlphaMask *inMask, RenderTarget *inTarget, RenderState &inState)
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
            case bmCopy : Render(inMask, *this, inTarget, CopyBlender() ); break;
            case bmNormal : Render(inMask, *this, inTarget, NormalBlender<false>() ); break;
            default:
                Render(inMask, *this, inTarget, SpecialBlender(inState.mBlendMode,outDest.HasAlpha(),false) );
         }
      }
      else
      {
         switch(inState.mBlendMode)
         {
            case bmCopy : Render(inMask, *this, inTarget, CopyBlender() ); break;
            case bmNormal : Render(inMask, *this, inTarget, NormalBlender<false>() ); break;
            default:
                Render(inMask, *this, inTarget, SpecialBlender(inState.mBlendMode,outDest.HasAlpha(),false) );
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



