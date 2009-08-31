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

void SimpleSurface::Blit(Surface *inSrc, const Rect &inSrcRect,int inDX, int inDY)
{
	int sx0 = std::max( std::max(inSrcRect.x,-inDX) , 0);
	int sy0 = std::max( std::max(inSrcRect.y,-inDY) , 0);
	int sx1 = std::min(inSrcRect.x1(),inSrc->Width());
	if (sx1+inDX > mWidth)
		sx1 = mWidth - inDX;
	int sy1 = std::min(inSrcRect.y1(),inSrc->Height());
	if (sy1+inDY > mHeight)
		sx1 = mWidth - inDX;
	if (sx1>sx0 && sy1>sy0)
	{
		for(int y=sy0;y<sy1;y++)
			memcpy(mBase + (y+inDY)*mStride + (sx0+inDX)*4,
			       mBase + y*mStride + sx0*4,
					 (sx1-sx0)*4 );
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


