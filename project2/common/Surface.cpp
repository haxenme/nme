#include <Graphics.h>

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

void SimpleSurface::BlitTo(const RenderTarget &outDest, const Rect &inSrcRect,int inDX, int inDY,
                           uint32 inTint)
{
	int sx0 = std::max( std::max(inSrcRect.x,-inDX) , 0);
	int sy0 = std::max( std::max(inSrcRect.y,-inDY) , 0);
	int sx1 = std::min(inSrcRect.x1(),Width());
	if (sx1+inDX > outDest.width)
		sx1 = outDest.width - inDX;
	int sy1 = std::min(inSrcRect.y1(),Height());
	if (sy1+inDY > outDest.height)
		sy1 = outDest.height - inDY;

   bool swap   = (mPixelFormat & pfSwapRB) != (outDest.format & pfSwapRB);
   bool do_memcpy = !(mPixelFormat & pfHasAlpha) && !swap;
   bool dest_alpha = (outDest.format & pfHasAlpha);
	if (sx1>sx0 && sy1>sy0)
	{
		for(int y=sy0;y<sy1;y++)
      {
         ARGB *dest = (ARGB *)outDest.Row(y+inDY) + (sx0+inDX);
         const ARGB *src = (const ARGB *)(mBase + y*mStride) + sx0;
         if (do_memcpy)
			   memcpy(dest,src, (sx1-sx0)*4 );
         else if (swap)
         {
            if (dest_alpha)
               for(int x=sx0;x<sx1;x++)
                  (dest++)->Blend<true,true>(*src++);
            else
               for(int x=sx0;x<sx1;x++)
                  (dest++)->Blend<true,false>(*src++);
         }
         else
         {
            if (dest_alpha)
               for(int x=sx0;x<sx1;x++)
                  (dest++)->Blend<false,true>(*src++);
            else
               for(int x=sx0;x<sx1;x++)
                  (dest++)->Blend<false,false>(*src++);
         }
      }
	}
}

void SimpleSurface::Clear(uint32 inColour)
{
	for(int y=0;y<mHeight;y++)
	{
		uint32 *ptr = (uint32 *)(mBase + y*mStride);
		for(int x=0;x<mWidth;x++)
			*ptr++ = inColour;
	}
}


RenderTarget SimpleSurface::BeginRender(const Rect &inRect)
{
	RenderTarget result;
	memset(&result,0,sizeof(result));

	Rect r = inRect.Intersect( Rect(0,0,mWidth,mHeight) );
	result.is_hardware = false;
	if (r.w>0 && r.h>0)
	{
       result.width = r.w;
       result.height = r.h;
       result.stride = mStride;
       result.data = mBase + mStride*r.y +r.x*4;
	}

	return result;
}

void SimpleSurface::EndRender()
{
}


