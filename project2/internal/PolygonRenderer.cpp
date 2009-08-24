#include <Graphics.h>
#include <CachedExtent.h>
#include <Geom.h>
#include "AlphaRuns.h"

typedef QuickVec<int> IQuickSet;


struct Transition
{
	Transition(int inX=0,int inVal=0) : x(inX), val(inVal) { }
	bool operator==(int inRHS) const { return x==inRHS; }
	bool operator<(int inRHS) const { return x<inRHS; }
	bool operator>(int inRHS) const { return x>inRHS; }

	void operator+=(int inDiff)
	{
		val += inDiff;
	}

   int x;
   int val;
};

typedef QuickVec<Transition> Transitions;


struct SpanRect
{
   SpanRect(const Rect &inRect) : mRect(inRect)
   {
      mTransitions = new Transitions[mRect.h];
      mMinX = (inRect.x - 1)<<10;
      mMaxX = (inRect.x1())<<10;
   }
   ~SpanRect()
   {
      delete [] mTransitions;
   }

	// dX/dY int fixed bits ...
   inline int FixedGrad(Fixed10 inVec,int inBits)
   {
      int denom = inVec.y;
      if (denom==0)
         return 0;
      int64 ratio = (inVec.x<<inBits)/denom;
		if (ratio< -(1<<11)) return -(1<<11);
		if (ratio>  (1<<11)) return  (1<<11);
      return ratio;
   }

   void Line(Fixed10 inP0, Fixed10 inP1)
   {
		if (inP0.x>mMaxX && inP0.y>mMaxX)
			return;

      // Make p1.y numerically greater than inP0.y
      int y0 = inP0.Y() - mRect.y;
      int y1 = inP1.Y() - mRect.y;
      int dy = y0-y1;

      if (dy==0)
         return;
      int diff = 1;
      if (dy<0)
      {
         diff = -1;
         std::swap(y0,y1);
         std::swap(inP0,inP1);
      }

      // All up or all down ....
      if (y0 >= mRect.h || y1 <= 0)
         return;

		// Just draw a vertical line down the left...
		if (inP0.x<mMinX && inP0.y>mMinX)
		{
			y0 = std::min(y0,0);
			y1 = std::max(y1,mRect.h);
			for(int y=y0;y<y1;y++)
				mTransitions[y].Change(mRect.x-1,diff);
			return;
		}

		// dx_dy in 10 bit precision ...
      int dx_dy = FixedGrad(inP1 - inP0,10);

		// (10 bit) fractional bit true position pokes up above the first line...
      int extra_y = ((y0+1 + mRect.y)<<10) - inP0.y;
		// We have already started down the gradient bt a bit, so adjust x.
		// x is 10 bits, dx_dy is 10 bits and extra_y is 10 bits ...
      int x = inP0.x + ((dx_dy * extra_y)>>10);

      if (y0<0)
      {
         x-= y0 * dx_dy;
         y0 = 0;
      }
      int last = y1>mRect.h ? mRect.h : y1;

      for(; y0<last; y0++)
      {
         // X is fixed-10, y is fixed-aa
         mTransitions[y0].Change(x>>10,diff);

         x+=dx_dy; 
      }
   }

	AlphaMask *CreateMask()
	{
		AlphaMask *mask = new AlphaMask();
		return mask;
	}

 
   Transitions *mTransitions;
   int         mMinX;
   int         mMaxX;
   Rect        mRect;
};






class PolygonRender : public CachedExtentRenderer
{
public:
   enum IterateMode { itGetExtent, itCreateRenderer };

   PolygonRender()
   {
      mBuildExtent = 0;
      mTarget = 0;
      mAlphaMask = 0;
   }

   ~PolygonRender()
   {
      delete mAlphaMask;
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
      Extent2DF extent;
      CachedExtentRenderer::GetExtent(inState.mTransform,extent);

      if (!extent.Valid())
         return true;

      // Transform to AA-Pixels ...
      Rect rect = inState.mTransform.GetTargetRect(extent);

      // Intersect with clip rect ...
      Rect visible_pixels = rect.Intersect(inState.mAAClipRect);

      // Check to see if AlphaMask is invalid...
      if (mAlphaMask && !mAlphaMask->Compatible(inState.mTransform, rect,visible_pixels))
      {
         delete mAlphaMask;
         mAlphaMask = 0;
      }

      if (!mAlphaMask)
      {
         SetTransform(inState.mTransform);

         // TODO: make visible_pixels a bit bigger ?
         mSpanRect = new SpanRect(visible_pixels);

         mTarget = &inTarget;
         Iterate(itCreateRenderer,inState.mTransform.mMatrix);
         mTarget = 0;

         mAlphaMask = mSpanRect->CreateMask();

         delete mSpanRect;
      }

      return true;
   }

   virtual void Iterate(IterateMode inMode,const Matrix &m) = 0;
   virtual QuickVec<float> &GetData() = 0;
   virtual void AlignOrthogonal()  { }

   Transform           mTransform;
   QuickVec<UserPoint> mTransformed;
   Extent2DF           *mBuildExtent;
   const RenderTarget  *mTarget;
   SpanRect            *mSpanRect;
   AlphaMask           *mAlphaMask;
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
		mSpanRect->Line( mTransform.ToImageAA(inP0), mTransform.ToImageAA(inP1) );
   }


   inline void AddLinePart(UserPoint p0, UserPoint p1, UserPoint p2, UserPoint p3)
   {
      (*this.*ItLine)(p0,p1);
      (*this.*ItLine)(p2,p3);
   }

   inline void AddJoint(const UserPoint &p0, const UserPoint &perp1, const UserPoint &perp2)
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
                                     &LineRender::BuildSolid;
                                     //&LineRender::TestRender;

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
                  else
                     first_perp = perp;

                  // Add edges ...
                  AddLinePart(prev+perp,*point+perp,*point-perp,prev-perp);
                  prev = *point;
                  prev_perp = perp;
               }

               points++;
               // Implicit loop closing...
               if (points>2 && *point==first)
               {
                  AddJoint(first,prev_perp,first_perp);
                  points = 1;
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





