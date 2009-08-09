#include <Graphics.h>

class SoftwareRenderCache : public IRenderCache
{
public:
	SoftwareRenderCache() { }
	~SoftwareRenderCache()
	{
		mObjs.DeleteAll();
	}
	void Render(const RenderData &inData,Surface *inSurface,
				   const ClipRect &inRect, Transform &inTransform)
	{
		int n = inData.size();
		for(int i=0;i<n;i++)
		{
			IRenderData *data = inData[i];
			if (mObjs.size()<=i)
			{
				if (data->AsSolid())
					mObjs.push_back( new SolidRenderer(data->AsSolid(),inRect,inTransform) );
				else
					mObjs.push_back( 0 );
			}
			else
				mObjs[i]->Update(inRect,inTransform);
		}

		for(int i=0;i<n;i++)
		{
			DrawObject *obj = mObjs[i];
			if (obj)
				obj->Render(inSurface,inRect,inTransform);
		}
	}


	QuickVec<DrawObject *> mObjs;
};


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
		mClipRect = Rect(Width(),Height());
	}

   void Render(Graphics &inGraphics, const Transform &inTransform)
	{
		SoftwareRenderCache *cache = 0;
		if (inGraphics.mSoftwareCache)
		{
			cache = dynamic_cast<SoftwareRenderCache *>(inGraphics.mSoftwareCache);
			if (!cache)
				*(int *)0=0;
		}
		else
			inGraphics.mSoftwareCache = cache = new SoftwareRenderCache();

		cache->Render( inGraphics.CreateRenderData(), mSurface,  );
	}

   void Render(TextList &inTextList, const Transform &inTransform)
	{
	}

   void Blit(Tile &inBitmap, int inOX, int inOY, double inScale, int Rotation)
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
