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
		mMask(inMask), mOx(-inMask.GetTX()), mOy(-inMask.GetTY())
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
		mRow = (mMask.Row(inY+mOy) + mComponentOffset) + mPixelStride*inX;
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

	TintSource(const uint8 *inBase, int inStride, int inCol)
	{
		mBase = inBase;
		mStride = inStride;
		mCol = ARGB(inCol);
	}

	inline void SetPos(int inX,int inY) const
	{
		mPos = ((const uint8 *)( mBase + mStride*inY)) + inX;
	}
	inline const ARGB &Next() const
	{
		mCol.a =  *mPos++;
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
			   int inX, int inY, const Rect &inSrcRect, BlendMode inMode)
{
	for(int y=0;y<inSrcRect.h;y++)
	{
		outDest.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
		inMask.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
		inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
	   for(int x=0;x<inSrcRect.w;x++)
			outDest.Next().Blend<SWAP_RB,DEST_ALPHA>(inMask.Mask(inSrc.Next()));
	}
}

template<typename DEST, typename SRC, typename MASK>
void TBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
			   int inX, int inY, const Rect &inSrcRect, BlendMode inMode)
{
   bool swap = inSrc.ShouldSwap(outDest.Format());
   bool dest_alpha = outDest.Format() & pfHasAlpha;

	if (inMode==bmNormal)
	{
		if (swap)
		{
			if (dest_alpha)
				TTBlit<true,true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect,inMode);
			else
				TTBlit<true,false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect,inMode);
		}
		else
		{
			if (dest_alpha)
				TTBlit<false,true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect,inMode);
			else
				TTBlit<false,false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect,inMode);
		}
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
			if (inMask)
			{
			   if (src_alpha)
				   TBlitAlpha(ImageDest<uint8>(outDest), ImageSource<uint8>(mBase,mStride,mPixelFormat),
						   ImageMask(*inMask), dx, dy, src_rect );
				else
				   TBlitAlpha(ImageDest<uint8>(outDest), ImageSource<ARGB>(mBase,mStride,mPixelFormat),
						   ImageMask(*inMask), dx, dy, src_rect );
			}
			else
			{
			   if (src_alpha)
				   TBlitAlpha(ImageDest<uint8>(outDest), ImageSource<uint8>(mBase,mStride,mPixelFormat),
						   NullMask(), dx, dy, src_rect );
				else
				   TBlitAlpha(ImageDest<uint8>(outDest), ImageSource<ARGB>(mBase,mStride,mPixelFormat),
						   NullMask(), dx, dy, src_rect );
			}
			return;
		}

		bool tint = inBlend==bmTinted;
		if (tint)
			inBlend = bmNormal;

		if (inMask)
		{
			if (tint)
			{
				TBlit( ImageDest<ARGB>(outDest), TintSource(mBase,mStride,inTint),
						ImageMask(*inMask), dx, dy, src_rect, inBlend );
			}
			else if (src_alpha)
			{
				TBlit( ImageDest<ARGB>(outDest), ImageSource<uint8>(mBase,mStride,mPixelFormat),
						ImageMask(*inMask), dx, dy, src_rect, inBlend );
			}
			else
			{
				TBlit( ImageDest<ARGB>(outDest), ImageSource<ARGB>(mBase,mStride,mPixelFormat),
							ImageMask(*inMask), dx, dy, src_rect, inBlend );
			}
		}
		else
		{
			if (tint)
			{
				TBlit( ImageDest<ARGB>(outDest), TintSource(mBase,mStride,inTint),
						NullMask(), dx, dy, src_rect, inBlend );
			}
			else if (src_alpha)
			{
				TBlit( ImageDest<ARGB>(outDest), ImageSource<uint8>(mBase,mStride,mPixelFormat),
						NullMask(), dx, dy, src_rect, inBlend );
			}
			else
			{
				TBlit( ImageDest<ARGB>(outDest), ImageSource<ARGB>(mBase,mStride,mPixelFormat),
						NullMask(), dx, dy, src_rect, inBlend );
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

