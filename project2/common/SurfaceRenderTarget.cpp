#include <Graphics.h>


class SoftwareRenderer
{
public:
   virtual ~SoftwareRenderer() { }
   virtual void Render(Surface *inSurface, const Rect &inRect, const Transform &inTransform)=0;
};



class PolygonRender : public SoftwareRenderer
{
public:
	PolygonRender()
	{
	}

   void Render(Surface *inSurface, const Rect &inRect, const Transform &inTransform)
	{
		TransformToImage();
		Iterate();
	}

	virtual void Iterate() = 0;
	virtual void AlignOrthogonal()  { }

	QuickVec<UserPoint> mTransformed;
};



class LineRender : public PolygonRender
{
	LineData *mLineData;

public:
	LineRender(LineData *inLine) : mLineData(inLine) { }

	void Iterate()
	{
		// Convert line data to solid data
		GraphicsStroke &stroke = *inLine->mStroke;
		mConvertedLine.mFill = stroke.fill;
		mDrawOnMove = false;

		int n = inLine->command.size();
		ImagePoint *point = &mTransformed[0];

		// It is a loop if the path has no breaks, it has more than 2 points
		//  and it finishes where it starts...
		UserPoint first;
		UserPoint first_dir;

		UserPoint prev;
		UserPoint prev_perp;

		for(int i=0;i<n;i++)
		{
			switch(inLine->command[i])
			{
				case pcWideMoveTo:
					point++;
				case pcMoveTo:
					if (points>0)
					{
						EndCap(first,-first_perp);
						EndCap(prev,prev_perp);
					}
					first = *point;
					prev = *point;
					points = 1;
				   break;

				case pcWideDrawTo:
					point++;
				case pcDrawTo:
					{
					if (points>1)
					{
						UserPoint perp = (*point - prev).Perp();
						AddJoint(prev,prev_perp,perp);

						// Add edges ...
						AddLinePart(prev+perp,*point+perp,*point-perp,prev-perp);
						prev = *point;
					}

					points++;
					// Implicit loop closing...
					if (points>2 && *point==first)
					{
						AddJoint(first,prev_perp,first_perp);
						points = 1;
						first_perp = prev_perp;
						first_dir = prev_perp;
					}
					point++;
					}
				   break;

				case pcCurveTo:
				   break;
			}
		}
	}
};






class SoftwareRenderCache : public IRenderCache
{
public:
	SoftwareRenderCache() { }
	~SoftwareRenderCache()
	{
		mObjs.DeleteAll();
	}
	void Render(const RenderData &inData,Surface *inSurface,
				   const Rect &inRect, const Transform &inTransform)
	{
		int n = inData.size();
		for(int i=0;i<n;i++)
		{
			IRenderData *data = inData[i];
			if (mObjs.size()<=i)
			{
				if (data->AsSolid())
					mObjs.push_back( new PolygonRender(data->AsSolid()) );
				else
					mObjs.push_back( 0 );
			}
		}

		for(int i=0;i<n;i++)
		{
			SoftwareRenderer *obj = mObjs[i];
			if (obj)
				obj->Render(inSurface,inRect,inTransform);
		}
	}


	QuickVec<SoftwareRenderer *> mObjs;
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

		cache->Render( inGraphics.CreateRenderData(), mSurface, mClipRect, inTransform);
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
