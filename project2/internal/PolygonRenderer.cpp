#include <Graphics.h>
#include <CachedExtent.h>
#include <Geom.h>
#include "AlphaMask.h"

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

template<int BITS>
struct AlphaIterator
{
   enum { Size = (1<<BITS) };
   enum { Mask = ~((1<<BITS) - 1) };

   AlphaIterator()
   {
      mEnd = mPtr = 0;
   }

   void Init(int &outXMin)
   {
      if (!mRuns.empty())
      {
         mPtr = &mRuns[0];
         mEnd = mPtr + mRuns.size();

         int x = mPtr->mX0 & Mask;
         if (x<outXMin) outXMin = x;
      }
   }

   // Move along until we hit x, calcualte alpha and update whn next change occurs
   int SetX(int inX, int &outNextX)
   {
      // zip along until we hit x
      do
      {
         if (mPtr==mEnd)
            return 0;
         if (mPtr->mX1 > inX)
            break;
         mPtr++;
      } while(1);

      int box = inX + Size;
      if (mPtr->mX0>=box)
      {
         int next = mPtr->mX0 & Mask;
         if (outNextX>next)
            outNextX = next;
         return 0;
      }


      int next;
      if ( mPtr->mX0 > inX)
         next = inX + Size;
      else
      {
         next = mPtr->mX1 & Mask;
         if (next==inX)
           next += Size;
      }
      if (outNextX>next)
         outNextX = next;

      // Calculate number of pixels overlapping...
      int alpha = inX - mPtr->mX0;
      if (alpha>0) alpha = 0;


      if (mPtr->mX1 < box)
      {
         alpha += mPtr->mX1  - inX;
         // Check next span too ...
         if (mPtr+1<mEnd)
         {
            AlphaRun &next = mPtr[1];
            if (next.mX0<box)
            {
               if (next.mX1 < box)
                  alpha += next.mX1 - next.mX0;
               else
                  alpha += box - next.mX0;
            }
         }
      }
      else
         alpha += Size;

      return alpha;
   }

   AlphaRuns mRuns;
   AlphaRun  *mPtr;
   AlphaRun  *mEnd;
};




struct SpanRect
{
   SpanRect(const Rect &inRect,int inAA)
   {
      // Round rect to non aa-boundary ...
      mAA =  inAA;
      int mask = inAA-1;
      mRect.x = inRect.x & ~mask;
      mRect.y = inRect.y & ~mask;
      mRect.w = (( inRect.x1() + mask) & ~mask) - mRect.x;
      mRect.h = (( inRect.y1() + mask) & ~mask) - mRect.y;

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
		if (ratio< -(1<<21)) return -(1<<21);
		if (ratio>  (1<<21)) return  (1<<21);
      return ratio;
   }

   void Line(Fixed10 inP0, Fixed10 inP1)
   {
      // All right ...
		if (inP0.x>mMaxX && inP1.x>mMaxX)
         return;

      // Make p1.y numerically greater than inP0.y
      int y0 = inP0.Y() - mRect.y;
      int y1 = inP1.Y() - mRect.y;
      int dy = y1-y0;

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
		if (inP0.x<=mMinX && inP1.x<=mMinX)
		{
			y0 = std::max(y0,0);
			y1 = std::min(y1,mRect.h);
			for(;y0<y1;y0++)
				mTransitions[y0].Change(mMinX,diff);
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
      int last = std::min(y1,mRect.h);

      for(; y0<last; y0++)
      {
         // X is fixed-10, y is fixed-aa
         mTransitions[y0].Change(x>>10,diff);

         x+=dx_dy; 
      }
   }

   void BuildAlphaRuns4(Transitions *inTrans, AlphaRuns &outRuns)
   {
      AlphaIterator<2> a0,a1,a2,a3;

      BuildAlphaRuns(inTrans[0],a0.mRuns);
      BuildAlphaRuns(inTrans[1],a1.mRuns);
      BuildAlphaRuns(inTrans[2],a2.mRuns);
      BuildAlphaRuns(inTrans[3],a3.mRuns);

      enum { MAX_X = 0x7fffffff };

      int x = mRect.x;

      a0.Init(x);
      a1.Init(x);
      a2.Init(x);
      a3.Init(x);

      while(x<MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x,next_x) + a1.SetX(x,next_x) + a2.SetX(x,next_x) + a3.SetX(x,next_x);
         if (next_x == MAX_X)
            break;
         if (alpha>0)
            outRuns.push_back( AlphaRun(x>>2,next_x>>2,alpha<<4) );
         x = next_x;
      }
   }


   void BuildAlphaRuns(Transitions &inTrans, AlphaRuns &outRuns)
   {
      int alpha = 0;
      int last_x = mRect.x;
      Transition *end = inTrans.end();
      int total = 0;
      for(Transition *t = inTrans.begin();t!=end;++t)
      {
         if (t->val)
         {
            if (t->x>=mRect.x1())
            {
               if (alpha>0 && last_x < t->x)
                  outRuns.push_back( AlphaRun(last_x,mRect.x1(),alpha) );
               return;
            }

            if (alpha>0 && last_x < t->x)
               outRuns.push_back( AlphaRun(last_x,t->x,alpha) );

            last_x = std::max(t->x,mRect.x);

            total+=t->val;
            // Winding rule ..
            alpha = (total) ? 256 : 0;
         }
      }
      if (alpha>0)
        outRuns.push_back( AlphaRun(last_x,mRect.x1(),alpha) );
   }

	AlphaMask *CreateMask()
	{
      Rect rect = mRect/mAA;
		AlphaMask *mask = new AlphaMask(rect);
      Transitions *t = mTransitions;
      for(int y=0;y<rect.h;y++)
      {
         switch(mAA)
         {
            case 1:
               BuildAlphaRuns(*t,mask->mLines[y]);
               break;
            case 4:
               BuildAlphaRuns4(t,mask->mLines[y]);
               break;
         }
         t+=mAA;
      }
		return mask;
	}

 
   Transitions *mTransitions;
   int         mAA;
   int         mMinX;
   int         mMaxX;
   Rect        mRect;
};




class PolygonRender : public CachedExtentRenderer
{
public:
   enum IterateMode { itGetExtent, itCreateRenderer };

   PolygonRender(IGraphicsFill *inFill)
   {
      mBuildExtent = 0;
      mAlphaMask = 0;
		switch(inFill->GetType())
		{
			case gdtSolidFill:
				mFiller = Filler::Create(inFill->AsSolidFill());
				break;
			case gdtGradientFill:
				mFiller = Filler::Create(inFill->AsGradientFill());
				break;
			default:
				printf("Fill type not implemented\n");
				mFiller = 0;
		}
   }

   ~PolygonRender()
   {
      delete mAlphaMask;
		delete mFiller;
   }

   void Destroy() { delete this; }

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
		int tx=0;
		int ty=0;
      if (mAlphaMask && !mAlphaMask->Compatible(inState.mTransform, rect,visible_pixels,tx,ty))
      {
         delete mAlphaMask;
         mAlphaMask = 0;
      }

      if (!mAlphaMask)
      {
         SetTransform(inState.mTransform);

         // TODO: make visible_pixels a bit bigger ?
         mSpanRect = new SpanRect(visible_pixels,inState.mTransform.mAAFactor);

         Iterate(itCreateRenderer,inState.mTransform.mMatrix);

         mAlphaMask = mSpanRect->CreateMask();
         mAlphaMask->SetValidArea( ImagePoint(rect.x,rect.y), visible_pixels, mTransform);
         delete mSpanRect;
      }

      mFiller->Fill(*mAlphaMask,tx,ty,inTarget,inState);

      return true;
   }
   void BuildSolid(const UserPoint &inP0, const UserPoint &inP1)
   {
		mSpanRect->Line( mTransform.ToImageAA(inP0), mTransform.ToImageAA(inP1) );
   }

   virtual void Iterate(IterateMode inMode,const Matrix &m) = 0;
   virtual QuickVec<float> &GetData() = 0;
   virtual void AlignOrthogonal()  { }

   Transform           mTransform;
   QuickVec<UserPoint> mTransformed;
	Filler              *mFiller;
   Extent2DF           *mBuildExtent;
   SpanRect            *mSpanRect;
   AlphaMask           *mAlphaMask;
};



class LineRender : public PolygonRender
{
   LineData *mLineData;
   typedef void (LineRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
   ItFunc ItLine;

public:
   LineRender(LineData *inLine) : PolygonRender(inLine->mStroke->fill ), mLineData(inLine) { }

   void BuildExtent(const UserPoint &inP0, const UserPoint &inP1)
   {
      mBuildExtent->Add(inP0);
   }




   inline void AddLinePart(UserPoint p0, UserPoint p1, UserPoint p2, UserPoint p3)
   {
      (*this.*ItLine)(p0,p1);
      (*this.*ItLine)(p2,p3);
   }

   inline void AddJoint(const UserPoint &p0, const UserPoint &perp1, const UserPoint &perp2)
   {
      (*this.*ItLine)(p0+perp1,p0+perp2);
      (*this.*ItLine)(p0-perp2,p0-perp1);
   }

   inline void EndCap(UserPoint p0, UserPoint perp)
   {
      (*this.*ItLine)(p0+perp,p0-perp);
   }

   void Iterate(IterateMode inMode,const Matrix &m)
   {
      ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
                                     &LineRender::BuildSolid;

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
               point += 2;
               break;
         }
      }
   }

   QuickVec<float> &GetData()
   {
      return mLineData->data;
   }
};


class SolidRender :public PolygonRender
{
   SolidData *mSolidData;

public:
   SolidRender(SolidData *inSolid) : PolygonRender(inSolid->mFill ), mSolidData(inSolid) { }


   void Iterate(IterateMode inMode,const Matrix &)
   {
      int n = mSolidData->command.size();
      UserPoint *point = &mTransformed[0];

      if (inMode==itGetExtent)
      {
         for(int i=0;i<n;i++)
         {
            switch(mSolidData->command[i])
            {
               case pcWideLineTo:
               case pcWideMoveTo:
                  point++;
               case pcLineTo:
               case pcMoveTo:
                  mBuildExtent->Add(*point);
                  point++;
                  break;
               case pcCurveTo:
                  point += 2;
                  break;
            }
         }
      }
      else
      {
         UserPoint last_move;
         UserPoint last_point;
         int points = 0;

         for(int i=0;i<n;i++)
         {
            switch(mSolidData->command[i])
            {
               case pcWideMoveTo:
                  point++;
               case pcMoveTo:
                  if (points>1)
                     BuildSolid(last_point,last_move);
                  points = 1;
                  last_point = *point++;
                  last_move = last_point;
                  break;

               case pcWideLineTo:
                  point++;
               case pcLineTo:
                  if (points>0)
                     BuildSolid(last_point,*point);
                  last_point = *point++;
                  points++;
                  break;

               case pcCurveTo:
                  break;
            }
         }
      }
   }

   QuickVec<float> &GetData()
   {
      return mSolidData->data;
   }
};



Renderer *Renderer::CreateSoftware(LineData *inLineData)
{
   return new LineRender(inLineData);
}

Renderer *Renderer::CreateSoftware(SolidData *inSolidData)
{
   return new SolidRender(inSolidData);
}

Renderer *Renderer::CreateSoftware(TriangleData *inTriangleData)
{
   return 0;
}





