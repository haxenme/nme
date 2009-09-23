#include <Graphics.h>
#include <Surface.h>

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
	if (inByteAlign>1)
	{
	   mStride = inWidth * 4 + inByteAlign -1;
	   mStride -= mStride % inByteAlign;
	}
	else
	{
		mStride = inWidth*4;
	}

   mBase = new unsigned char[mStride * mHeight];
}

SimpleSurface::~SimpleSurface()
{
	delete [] mBase;
}

void SimpleSurface::BlitTo(const RenderTarget &outDest, const Rect &inSrcRect,
                           int inPosX, int inPosY, uint32 inTint,bool inUseSrcAlphaOnly)
{
   // Translate inSrcRect src_rect to dest ...
   Rect src_rect(inPosX,inPosY, inSrcRect.w, inSrcRect.h );
   // clip ...
   src_rect = src_rect.Intersect(outDest.mRect);

   // translate back to source-coordinates ...
   src_rect.Translate(inSrcRect.x-inPosX, inSrcRect.y-inPosY);
   // clip to origial rect...
   src_rect = src_rect.Intersect( inSrcRect );

	if (src_rect.HasPixels())
	{
      bool swap   = (mPixelFormat & pfSwapRB) != (outDest.format & pfSwapRB);
      bool do_memcpy = !(mPixelFormat & pfHasAlpha) && !swap;
      bool dest_alpha = (outDest.format & pfHasAlpha);
      int dx = inPosX + src_rect.x - inSrcRect.x;
      int dy = inPosY + src_rect.y - inSrcRect.y;
		for(int y=0;y<src_rect.h;y++)
      {
         ARGB *dest = (ARGB *)outDest.Row(y+dy) + dx;
         const ARGB *src = (const ARGB *)(mBase + (y+src_rect.y)*mStride) + src_rect.x;
			if (inUseSrcAlphaOnly)
			{
				ARGB col(inTint);
            if (outDest.format & pfSwapRB)
					std::swap(col.c0,col.c2);

            if (dest_alpha)
               for(int x=0;x<src_rect.w;x++)
					{
						col.a = src++ -> a;
                  (dest++)->Blend<false,true>(col);
					}
            else
               for(int x=0;x<src_rect.w;x++)
					{
						col.a = src++ -> a;
                  (dest++)->Blend<false,false>(col);
					}
			}
			else if (do_memcpy)
			   memcpy(dest,src, (src_rect.w)*4 );
         else if (swap)
         {
            if (dest_alpha)
               for(int x=0;x<src_rect.w;x++)
                  (dest++)->Blend<true,true>(*src++);
            else
               for(int x=0;x<src_rect.w;x++)
                  (dest++)->Blend<true,false>(*src++);
         }
         else
         {
            if (dest_alpha)
               for(int x=0;x<src_rect.w;x++)
                  (dest++)->Blend<false,true>(*src++);
            else
               for(int x=0;x<src_rect.w;x++)
                  (dest++)->Blend<false,false>(*src++);
         }
      }
	}
}

void SimpleSurface::Clear(uint32 inColour)
{
	ARGB rgb(inColour);
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


