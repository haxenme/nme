#include <Graphics.h>
#include <CachedExtent.h>
#include <Geom.h>


class PolygonRender : public CachedExtentRenderer
{
public:
   enum IterateMode { itGetExtent, itCreateRenderer };

   PolygonRender()
   {
      mBuildExtent = 0;
		mTarget = 0;
   }

   void GetExtent(CachedExtent &ioCache)
   {
      mBuildExtent = &ioCache.mExtent;
		*mBuildExtent = Extent2DF();

      SetTransform(ioCache.mTransform);

      Iterate(itGetExtent,ioCache.mTransform.mMatrix);
		mBuildExtent = 0;
   }

	void SetTransform(const Transform &inTransform)
	{
		QuickVec<float> &data = GetData();
		int points = data.size()/2;
		if (points!=mTransformed.size() || inTransform!=mTransform)
		{
			mTransform = inTransform;
			mTransformed.resize(points);
			for(int i=0;i<points;i++)
				mTransformed[i] = mTransform.Apply(data[i*2],data[i*2+1]);
		}
	}

   bool Render(const RenderTarget &inTarget, const RenderState &inState)
   {
      SetTransform(inState.mTransform);

		mTarget = &inTarget;
      Iterate(itCreateRenderer,inState.mTransform.mMatrix);
		mTarget = 0;

		return true;
   }

   virtual void Iterate(IterateMode inMode,const Matrix &m) = 0;
   virtual QuickVec<float> &GetData() = 0;
   virtual void AlignOrthogonal()  { }

	Transform           mTransform;
   QuickVec<UserPoint> mTransformed;
   Extent2DF           *mBuildExtent;
	const RenderTarget  *mTarget;
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

	void TestRender(const UserPoint &inP0, const UserPoint &inP1)
   {
		int *data = (int *)( mTarget->data + (int)(inP0.y)*mTarget->stride +
							        (int)(inP0.x)*sizeof(int) );
		*data = 0xff00ff00;
		data = (int *)( mTarget->data + (int)(inP1.y)*mTarget->stride +
							        (int)(inP1.x)*sizeof(int) );
		*data = 0xff00ff00;
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

   void Iterate(IterateMode inMode,const Matrix &m)
   {
      ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
                                     //&LineRender::BuildSolid;
                                     &LineRender::TestRender;

      // Convert line data to solid data
      GraphicsStroke &stroke = *mLineData->mStroke;

		double perp_len = stroke.thickness*0.5;
		switch(stroke.scaleMode)
		{
			case ssmNone:
				// Done!
				break;
			case ssmNormal:
				perp_len *= sqrt( 0.5*(m.m00*m.m00 + m.m01*m.m01 + m.m10*m.m10 + m.m11*m.m11) );
				break;
			case ssmVertical:
				perp_len *= sqrt( m.m00*m.m00 + m.m01*m.m01 );
				break;
			case ssmHorizontal:
				perp_len *= sqrt( m.m10*m.m10 + m.m11*m.m11 );
				break;
		}

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
               prev = *point;
               first = *point++;
               points = 1;
               break;

            case pcWideLineTo:
               point++;
            case pcLineTo:
               {
               if (points>0)
               {
                  UserPoint perp = (*point - prev).Perp(perp_len);
                  if (points>1)
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





