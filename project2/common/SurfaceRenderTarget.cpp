#include <Graphics.h>

class SurfaceRenderTarget : public IRenderTarget
{
public:
	SurfaceRenderTarget(Surface *inSurface) : mSurface(inSurface)
	{
	}

	~SurfaceRenderTarget()
	{
	}

	// IRenderTarget interface ...
   int  Width() const { return mSurface->Width(); }
   int  Height() const { return mSurface->Width(); }

   void ViewPort(int inOX,int inOY, int inW,int inH)
	{
		mClipRect = Rect(inOX,inOY,inW,inH).Intersect( Rect(mSurface->Width(),mSurface->Height()) );
	}

   void BeginRender()
	{
	}

   void Render(DisplayList &inDisplayList, const Transform &inTransform)
	{
	}

   void Render(TextList &inTextList, const Transform &inTransform)
	{
	}

   void Blit(BlitData &inBitmap, int inOX, int inOY, double inScale, int Rotation)
	{
	}

   void EndRender()
	{
	}


	Surface *mSurface;
	Rect    mClipRect;
};



IRenderTarget *CreateSurfaceRenderTarget(Surface *inSurface)
{
	return new SurfaceRenderTarget(inSurface);
}
