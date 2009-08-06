#include <Graphics.h>

SimpleSurface::SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign)
{
	mWidth = inWidth;
	mHeight = inHeight;
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

SurfaceData SimpleSurface::Lock(const Rect &inRect,uint32 inFlags)
{
	SurfaceData result;
	memset(&result,0,sizeof(result));

	Rect r = inRect.Intersect( Rect(0,0,mWidth,mHeight) );
	if (r.w>1 && r.h>1)
	{
       result.width = r.w;
       result.height = r.h;
       result.stride = mStride;
       result.data = mBase + mStride*r.y +r.x*4;
	}

	return result;
}

void SimpleSurface::Unlock()
{
}


