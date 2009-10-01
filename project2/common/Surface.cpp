#include <Graphics.h>
#include <Surface.h>
#include <Pixel.h>

bool sgColourOrderSet = false;

int sgC0Shift = 0;
int sgC1Shift = 8;
int sgC2Shift = 16;
bool sgC0IsRed = true;

void HintColourOrder(bool inRedFirst)
{
   if (!sgColourOrderSet)
   {
      sgColourOrderSet = true;
      sgC0IsRed = inRedFirst;
      if (inRedFirst)
      {
         sgC0Shift = 0;
         sgC2Shift = 16;
      }
      else
      {
         sgC0Shift = 16;
         sgC2Shift = 0;
      }
   }
}


// --- Surface -------------------------------------------------------


Surface::~Surface()
{
   if (mTexture)
      DestroyNativeTexture(mTexture);
}

void Surface::SetTexture(NativeTexture *inTexture)
{
   if (inTexture!=mTexture)
   {
      if (mTexture)
         DestroyNativeTexture(mTexture);
      mTexture = inTexture;
   }
}


// --- SimpleSurface -------------------------------------------------------

SimpleSurface::SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign)
{
   mWidth = inWidth;
   mHeight = inHeight;
   mPixelFormat = inPixelFormat;
   int pix_size = inPixelFormat == pfAlpha ? 1 : 4;
   if (inByteAlign>1)
   {
      mStride = inWidth * pix_size + inByteAlign -1;
      mStride -= mStride % inByteAlign;
   }
   else
   {
      mStride = inWidth*pix_size;
   }

   mBase = new unsigned char[mStride * mHeight];
}

SimpleSurface::~SimpleSurface()
{
   delete [] mBase;
}

// --- Surface Blitting ------------------------------------------------------------------

struct NullMask
{
   inline void SetPos(int inX,int inY) const { }
   inline const uint8 &Mask(const uint8 &inAlpha) const { return inAlpha; }
   inline const ARGB &Mask(const ARGB &inRGB) const { return inRGB; }
};


struct ImageMask
{
   ImageMask(const BitmapCache &inMask) :
      mMask(inMask), mOx(-inMask.GetTX()-mMask.GetRect().x), mOy(-inMask.GetTY()-mMask.GetRect().y)
   {
      if (mMask.Format()==pfAlpha)
      {
         mComponentOffset = 0;
         mPixelStride = 1;
      }
      else
      {
         ARGB tmp;
         mComponentOffset = (uint8 *)&tmp.a - (uint8 *)&tmp;
         mPixelStride = 4;
      }
   }

   inline void SetPos(int inX,int inY) const
   {
      mRow = (mMask.Row(inY) + mComponentOffset) + mPixelStride*(inX);
   }
   inline uint8 Mask(uint8 inAlpha) const
   {
      inAlpha = (inAlpha * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return inAlpha;
   }
   inline ARGB Mask(ARGB inRGB) const
   {
      inRGB.a = (inRGB.a * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return inRGB;
   }

   const BitmapCache &mMask;
   mutable const uint8 *mRow;
   int mOx,mOy;
   int mComponentOffset;
   int mPixelStride;
};

template<typename PIXEL>
struct ImageSource
{
   typedef PIXEL Pixel;

   ImageSource(const uint8 *inBase, int inStride, PixelFormat inFmt)
   {
      mBase = inBase;
      mStride = inStride;
      mFormat = inFmt;
   }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((const PIXEL *)( mBase + mStride*inY)) + inX;
   }
   inline const Pixel &Next() const { return *mPos++; }

   bool ShouldSwap(PixelFormat inFormat) const
   {
      return (inFormat & pfSwapRB) != (mFormat & pfSwapRB);
   }


   mutable const PIXEL *mPos;
   int   mStride;
   const uint8 *mBase;
   PixelFormat mFormat;
};



struct TintSource
{
   typedef ARGB Pixel;

   TintSource(const uint8 *inBase, int inStride, int inCol,PixelFormat inFormat)
   {
      mBase = inBase;
      mStride = inStride;
      mCol = ARGB(inCol);
      if (inFormat==pfAlpha)
      {
         mComponentOffset = 0;
         mPixelStride = 1;
      }
      else
      {
         ARGB tmp;
         mComponentOffset = (uint8 *)&tmp.a - (uint8 *)&tmp;
         mPixelStride = 4;
      }
   }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((const uint8 *)( mBase + mStride*inY)) + inX*mPixelStride + mComponentOffset;
   }
   inline const ARGB &Next() const
   {
      mCol.a =  *mPos;
      mPos+=mPixelStride;
      return mCol;
   }
   bool ShouldSwap(PixelFormat inFormat) const
   {
      if (inFormat & pfSwapRB)
         mCol.SwapRB();
      return false;
   }

   mutable ARGB mCol;
   mutable const uint8 *mPos;
   int   mComponentOffset;
   int   mPixelStride;
   int   mStride;
   const uint8 *mBase;
};


template<typename PIXEL>
struct ImageDest
{
   typedef PIXEL Pixel;

   ImageDest(const RenderTarget &inTarget) : mTarget(inTarget) { }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((PIXEL *)mTarget.Row(inY)) + inX;
   }
   inline Pixel &Next() const { return *mPos++; }

   PixelFormat Format() const { return mTarget.format; }

   const RenderTarget &mTarget;
   mutable PIXEL *mPos;
};


template<bool SWAP_RB, bool DEST_ALPHA, typename DEST, typename SRC, typename MASK>
void TTBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX , inY + y );
      inMask.SetPos(inX , inX + y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
      #ifdef HX_WINDOWS
         outDest.Next().Blend<SWAP_RB,DEST_ALPHA>(inMask.Mask(inSrc.Next()));
      #else
         if (!SWAP_RB && !DEST_ALPHA)
            outDest.Next().TBlend_00(inMask.Mask(inSrc.Next()));
         else if (!SWAP_RB && DEST_ALPHA)
            outDest.Next().TBlend_01(inMask.Mask(inSrc.Next()));
         else if (SWAP_RB && !DEST_ALPHA)
            outDest.Next().TBlend_10(inMask.Mask(inSrc.Next()));
         else
            outDest.Next().TBlend_11(inMask.Mask(inSrc.Next()));
      #endif
   }
}

template<typename DEST, typename SRC, typename MASK>
void TBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   bool swap = inSrc.ShouldSwap(outDest.Format());
   bool dest_alpha = outDest.Format() & pfHasAlpha;

      if (swap)
      {
         if (dest_alpha)
            TTBlit<true,true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
         else
            TTBlit<true,false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
      }
      else
      {
         if (dest_alpha)
            TTBlit<false,true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
         else
            TTBlit<false,false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
      }
}



template<typename DEST, typename SRC, typename MASK>
void TBlitAlpha( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
      inMask.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
         BlendAlpha(outDest.Next(),inMask.Mask(inSrc.Next()));
   }

}

typedef void (*BlendFunc)(ARGB &ioDest, ARGB inSrc);

template<bool SWAP, bool DEST_ALPHA,typename FUNC>
inline void BlendFuncWithAlpha(ARGB &ioDest, ARGB &inSrc,FUNC F)
{
   if (inSrc.a==0)
      return;
   if (SWAP) inSrc.SwapRB();
   ARGB val = inSrc;
   if (!DEST_ALPHA || ioDest.a>0)
   {
      F(val,ioDest);
   }
   if (DEST_ALPHA || ioDest.a<255)
   {
      int A = ioDest.a + (ioDest.a>>7);
      int A_ = 256-A;
      val.c0 = (val.c0 *A + inSrc.c2*A_)>>8;
      val.c1 = (val.c1 *A + inSrc.c1*A_)>>8;
      val.c2 = (val.c2 *A + inSrc.c0*A_)>>8;
   }
   if (inSrc.a==255)
   {
      ioDest = val;
      return;
   }

   if (DEST_ALPHA)
      ioDest.QBlendA(val);
   else
      ioDest.QBlend(val);
}



struct DoMult
{
   inline void operator()(ARGB &ioVal,ARGB inDest) const
   {
    ioVal.c0 = (inDest.c0 * ( ioVal.c0 + (ioVal.c0>>7)))>>8;
    ioVal.c1 = (inDest.c1 * ( ioVal.c1 + (ioVal.c1>>7)))>>8;
    ioVal.c2 = (inDest.c2 * ( ioVal.c2 + (ioVal.c2>>7)))>>8;
   }
};

template<bool SWAP, bool DEST_ALPHA> void MultiplyFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoMult()); }

struct DoScreen
{
   inline void operator()(ARGB &ioVal,ARGB inDest) const
   {
    ioVal.c0 = 255 - ((255 - inDest.c0) * ( 256 - ioVal.c0 - (ioVal.c0>>7)))>>8;
    ioVal.c1 = 255 - ((255 - inDest.c1) * ( 256 - ioVal.c1 - (ioVal.c1>>7)))>>8;
    ioVal.c2 = 255 - ((255 - inDest.c2) * ( 256 - ioVal.c2 - (ioVal.c2>>7)))>>8;
   }
};


template<bool SWAP, bool DEST_ALPHA> void ScreenFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoScreen()); }

template<bool SWAP, bool DEST_ALPHA> void LightenFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void DarkenFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void DifferenceFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void AddFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void SubtractFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void InvertFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void AlphaFunc(ARGB &ioDest, ARGB inSrc)
{
   if (DEST_ALPHA)
      ioDest.a = (ioDest.a * ( inSrc.a + (inSrc.a>>7))) >> 8;
}

template<bool SWAP, bool DEST_ALPHA> void EraseFunc(ARGB &ioDest, ARGB inSrc)
{
   if (DEST_ALPHA)
      ioDest.a = (ioDest.a * ( 256-inSrc.a - (inSrc.a>>7))) >> 8;
}

template<bool SWAP, bool DEST_ALPHA> void OverlayFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

template<bool SWAP, bool DEST_ALPHA> void HardLightFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}


#define BLEND_METHOD(blend) blend<false,false>, blend<false,true>, blend<true,false>, blend<true,true>,

BlendFunc sgBlendFuncs[] = 
{
   0, 0, 0, 0, // Normal
   0, 0, 0, 0, // Layer
   BLEND_METHOD(MultiplyFunc)
   BLEND_METHOD(ScreenFunc)
   BLEND_METHOD(LightenFunc)
   BLEND_METHOD(DarkenFunc)
   BLEND_METHOD(DifferenceFunc)
   BLEND_METHOD(AddFunc)
   BLEND_METHOD(SubtractFunc)
   BLEND_METHOD(InvertFunc)
   BLEND_METHOD(AlphaFunc)
   BLEND_METHOD(EraseFunc)
   BLEND_METHOD(OverlayFunc)
   BLEND_METHOD(HardLightFunc)
};

template<typename MASK>
void TBlitBlend( const ImageDest<ARGB> &outDest, const ImageSource<ARGB> &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect, BlendMode inMode)
{
   bool swap = inSrc.ShouldSwap(outDest.Format());
   bool dest_alpha = outDest.Format() & pfHasAlpha;

   BlendFunc blend = sgBlendFuncs[inMode*4 + ( swap ? 2 : 0) + (dest_alpha?1:0)];

   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX , inY + y );
      inMask.SetPos(inX , inX + y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
         blend(outDest.Next(),inMask.Mask(inSrc.Next()));
   }
}




void SimpleSurface::BlitTo(const RenderTarget &outDest,
                     const Rect &inSrcRect,int inPosX, int inPosY,
                     BlendMode inBlend, const BitmapCache *inMask,
                     uint32 inTint )
{
   // Translate inSrcRect src_rect to dest ...
   Rect src_rect(inPosX,inPosY, inSrcRect.w, inSrcRect.h );
   // clip ...
   src_rect = src_rect.Intersect(outDest.mRect);

   if (inMask)
      src_rect = src_rect.Intersect(inMask->GetRect());

   // translate back to source-coordinates ...
   src_rect.Translate(inSrcRect.x-inPosX, inSrcRect.y-inPosY);
   // clip to origial rect...
   src_rect = src_rect.Intersect( inSrcRect );

   if (src_rect.HasPixels())
   {
      int dx = inPosX + src_rect.x - inSrcRect.x;
      int dy = inPosY + src_rect.y - inSrcRect.y;

      bool src_alpha = mPixelFormat==pfAlpha;
      bool dest_alpha = outDest.format==pfAlpha;

      // Blitting to alpha image - can ignore blend mode
      if (dest_alpha)
      {
         ImageDest<uint8> dest(outDest);
         if (inMask)
         {
            if (src_alpha)
               TBlitAlpha(dest, ImageSource<uint8>(mBase,mStride,mPixelFormat),
                     ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlitAlpha(dest, ImageSource<ARGB>(mBase,mStride,mPixelFormat),
                     ImageMask(*inMask), dx, dy, src_rect );
         }
         else
         {
            if (src_alpha)
               TBlitAlpha(dest, ImageSource<uint8>(mBase,mStride,mPixelFormat),
                     NullMask(), dx, dy, src_rect );
            else
               TBlitAlpha(dest, ImageSource<ARGB>(mBase,mStride,mPixelFormat),
                     NullMask(), dx, dy, src_rect );
         }
         return;
      }

      ImageDest<ARGB> dest(outDest);
      bool tint = inBlend==bmTinted;

      // Blitting tint, we can ignore blend mode too (this is used for rendering text)
      if (tint)
      {
         TintSource src(mBase,mStride,inTint,mPixelFormat);
         if (inMask)
            TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
         else
            TBlit( dest, src, NullMask(), dx, dy, src_rect );
      }
      else if (src_alpha)
      {
         ImageSource<uint8> src(mBase,mStride,mPixelFormat);
         if (inMask)
            TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
         else
            TBlit( dest, src, NullMask(), dx, dy, src_rect );
      }
      else
      {
         ImageSource<ARGB> src(mBase,mStride,mPixelFormat);
         if (inBlend==bmNormal || inBlend==bmLayer)
         {
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
         else
         {
            if (inMask)
               TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, inBlend );
            else
               TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, inBlend );
         }
      }
   }
}





void SimpleSurface::Clear(uint32 inColour)
{
   ARGB rgb(inColour);
   if (mPixelFormat==pfAlpha)
   {
      memset(mBase, rgb.a,mStride*mHeight);
      return;
   }

   if (mPixelFormat & pfSwapRB)
      rgb.SwapRB();

   for(int y=0;y<mHeight;y++)
   {
      uint32 *ptr = (uint32 *)(mBase + y*mStride);
      for(int x=0;x<mWidth;x++)
         *ptr++ = rgb.ival;
   }
}

void SimpleSurface::Zero()
{
   memset(mBase,0,mStride * mHeight);
}

RenderTarget SimpleSurface::BeginRender(const Rect &inRect)
{
   RenderTarget result;
   memset(&result,0,sizeof(result));

   result.mRect = inRect.Intersect( Rect(0,0,mWidth,mHeight) );
   result.is_hardware = false;
   result.stride = mStride;
   result.data = mBase;
   result.format = mPixelFormat;

   return result;
}

void SimpleSurface::EndRender()
{
}

// --- BitmapCache -----------------------------------------------------------------

const uint8 *BitmapCache::Row(int inRow) const
{
   return mBitmap->Row(inRow-(mRect.y+mTY)) - mBitmap->BytesPP()*(mRect.x+mTX);
}


PixelFormat BitmapCache::Format() const
{
   return mBitmap->Format();
}

