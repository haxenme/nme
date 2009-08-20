#include <Graphics.h>
#include "Geom.h"

static int sgCachedExtentID = 1;


class SoftwareRenderer
{
public:
   virtual ~SoftwareRenderer() { }

   virtual void Render(Surface *inSurface, const Rect &inRect, const Transform &inTransform)=0;

   virtual void GetExtent(CachedExtent &ioCache) = 0;

   virtual Extent2DF GetExtent(const Transform &inTransform)
	{
		Matrix test = inTransform.mMatrix;
		double norm = test.m00*test.m00 + test.m01*test.m01 +
		              test.m10*test.m10 + test.m11*test.m11;
		if (norm<=0)
			return Extent2DF();
		test = 1.0/sqrt(norm);
		test.m00 *= norm;
		test.m01 *= norm;
		test.m10 *= norm;
		test.m11 *= norm;
		test.mtx = 0;
		test.mty = 0;

		int smallest = mExtentCache[0].mID;
		int slot = 0;
		for(int i=0;i<3;i++)
		{
			CachedExtent &cache = mExtentCache[i];
			if (test==cache.mMatrix && inTransform.mScale9==cache.mScale9)
				return cache.Get(inTransform.mMatrix);
			if (cache.mID<smallest)
			{
				smallest = cache.mID;
				slot = i;
			}
		}

		// Not in cache - fill slot
		CachedExtent &cache = mExtentCache[slot];
		cache.mMatrix = inTransform.mMatrix;
		cache.mScale9 = inTransform.mScale9;
		GetExtent(cache);
		return cache.Get(inTransform.mMatrix);
	}

	CachedExtent mExtentCache[3];
};



class PolygonRender : public SoftwareRenderer
{
public:
   enum IterateMode { itGetExtent, itCreateRenderer };

   PolygonRender()
   {

   }

   void GetExtent(CachedExtent &ioCache)
   {
      mBuildExtent = &ioCache.mExtent;
		*mBuildExtent = Extent2DF();

      SetTransform(ioCache.mMatrix, ioCache.mScale9);

      Iterate(itGetExtent);
   }

	void SetTransform(const Matrix &inMatrix, const Scale9 &inScale9)
	{
		if (inMatrix!=mTransMatrix || inScale9!=mTransScale9)
		{
			mTransMatrix = inMatrix;
			mTransScale9 = inScale9;

			QuickVec<float> &data = GetData();
			mTransformed.resize(data.size()/2);
			for(int i=0;i<mTransformed.size();i++)
			{
				if (mTransScale9.Active())
				   mTransformed[i] = mTransMatrix.Apply(mTransScale9.TransX(data[i*2]),
														        mTransScale9.TransY(data[i*2+1]) );
				else
				   mTransformed[i] = mTransMatrix.Apply(data[i*2],data[i*2+1]);
			}
		}
	}

   void Render(Surface *inSurface, const Rect &inRect, const Transform &inTransform)
   {
      SetTransform(inTransform.mMatrix, inTransform.mScale9);
      Iterate(itCreateRenderer);
   }

   virtual void Iterate(IterateMode inMode) = 0;
   virtual QuickVec<float> &GetData() = 0;
   virtual void AlignOrthogonal()  { }

   Matrix              mTransMatrix;
	Scale9              mTransScale9;
   QuickVec<UserPoint> mTransformed;
   Extent2DF           *mBuildExtent;
};



class LineRender : public PolygonRender
{
   LineData *mLineData;
   typedef void (LineRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
   ItFunc ItLine;

public:
   LineRender(LineData *inLine) : mLineData(inLine) { }

   void BuildExtent(const UserPoint &inP0, const UserPoint &inP1)
   {
      mBuildExtent->Add(inP0);
   }

   void BuildSolid(const UserPoint &inP0, const UserPoint &inP1)
   {
   }

   inline void AddLinePart(UserPoint p0, UserPoint p1, UserPoint p2, UserPoint p3)
   {
      (*this.*ItLine)(p0,p1);
      (*this.*ItLine)(p2,p3);
   }

   inline void AddJoint(UserPoint p0, UserPoint perp1, UserPoint perp2)
   {
      (*this.*ItLine)(p0+perp1,p0+perp2);
      (*this.*ItLine)(p0-perp1,p0-perp2);
   }

   inline void EndCap(UserPoint p0, UserPoint perp)
   {
      (*this.*ItLine)(p0+perp,p0-perp);
   }

   void Iterate(IterateMode inMode)
   {
      ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
                                     &LineRender::BuildSolid;

      // Convert line data to solid data
      GraphicsStroke &stroke = *mLineData->mStroke;

      int n = mLineData->command.size();
      UserPoint *point = &mTransformed[0];

      // It is a loop if the path has no breaks, it has more than 2 points
      //  and it finishes where it starts...
      UserPoint first;
      UserPoint first_perp;

      UserPoint prev;
      UserPoint prev_perp;

		int points = 0;

      for(int i=0;i<n;i++)
      {
         switch(mLineData->command[i])
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

            case pcWideLineTo:
               point++;
            case pcLineTo:
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
                  first_perp = prev_perp;
               }
               point++;
               }
               break;

            case pcCurveTo:
               break;
         }
      }
   }

   QuickVec<float> &GetData()
	{
		return mLineData->data;
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
            if (data->AsLine())
               mObjs.push_back( new LineRender(data->AsLine()) );
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

