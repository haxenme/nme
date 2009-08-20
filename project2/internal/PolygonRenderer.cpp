#include <Graphics.h>
#include <CachedExtent.h>
#include <Geom.h>


class PolygonRender : public CachedExtentRenderer
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

   bool Render(Surface *inSurface, const Rect &inRect, const Transform &inTransform)
   {
      SetTransform(inTransform.mMatrix, inTransform.mScale9);
      Iterate(itCreateRenderer);

		return true;
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

	void Destroy() { delete this; }

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



Renderer *Renderer::CreateSoftware(LineData *inLineData)
{
	return new LineRender(inLineData);
}

Renderer *Renderer::CreateSoftware(SolidData *inSolidData)
{
	return 0;
}

Renderer *Renderer::CreateSoftware(TriangleData *inTriangleData)
{
	return 0;
}





