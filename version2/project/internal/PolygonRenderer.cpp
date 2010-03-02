#include <Graphics.h>
#include <CachedExtent.h>
#include <Geom.h>
#include "AlphaMask.h"


#ifndef M_PI
#define M_PI 3.14159
#endif

namespace nme
{

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
      mAA =  inAA;
      mRect = inRect * inAA;

      mTransitions = new Transitions[mRect.h];
      mMinX = (mRect.x - 1)<<10;
      mMaxX = (mRect.x1())<<10;
      mLeftPos = mRect.x;
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
            mTransitions[y0].Change(mLeftPos,diff);
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

   AlphaMask *CreateMask(const Transform &inTransform)
   {
      Rect rect = mRect/mAA;
      AlphaMask *mask = new AlphaMask(rect,inTransform);
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
   int         mLeftPos;
   Rect        mRect;
};




class PolygonRender : public CachedExtentRenderer
{
public:
   enum IterateMode { itGetExtent, itCreateRenderer, itHitTest };


   PolygonRender(const GraphicsJob &inJob, const GraphicsPath &inPath,IGraphicsFill *inFill) :
      mCommands(inPath.commands), mData(inPath.data),
      mCommand0(inJob.mCommand0), mData0(inJob.mData0),
      mCommandCount(inJob.mCommandCount), mDataCount(inJob.mDataCount)
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
         case gdtBitmapFill:
            mFiller = Filler::Create(inFill->AsBitmapFill());
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

      Iterate(itGetExtent,*ioCache.mTransform.mMatrix);
      mBuildExtent = 0;
   }


   void SetTransform(const Transform &inTransform)
   {
      int points = mDataCount/2;
      if (points!=mTransformed.size() || inTransform!=mTransform)
      {
         mTransform = inTransform;
         mTransMat = *inTransform.mMatrix;
         mTransform.mMatrix = &mTransMat;
         mTransform.mMatrix3D = &mTransMat;
         mTransScale9 = *inTransform.mScale9;
         mTransform.mScale9 = &mTransScale9;
         mTransformed.resize(points);
         UserPoint *src= (UserPoint *)&mData[ mData0 ];
         for(int i=0;i<points;i++)
            mTransformed[i] = mTransform.Apply(src[i].x,src[i].y);
         AlignOrthogonal();
      }
   }

   void Align(UserPoint &ioP0, UserPoint &ioP1)
   {
      if (ioP0!=ioP1)
      {
         if (ioP0.x == ioP1.x)
         {
            ioP0.x = ioP1.x = floor(ioP0.x) + 0.5;
         }
         else if (ioP0.y == ioP1.y)
         {
            ioP0.y = ioP1.y = floor(ioP0.y) + 0.5;
         }
      }
   }


   bool Render(const RenderTarget &inTarget, const RenderState &inState)
   {
      Extent2DF extent;
      CachedExtentRenderer::GetExtent(inState.mTransform,extent);

      if (!extent.Valid())
         return true;

      // Get bounding pixel rect
      Rect rect = inState.mTransform.GetTargetRect(extent);

      // Intersect with clip rect ...
      Rect visible_pixels = rect.Intersect(inState.mClipRect);

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

         Iterate(itCreateRenderer,*inState.mTransform.mMatrix);

         mAlphaMask = mSpanRect->CreateMask(mTransform);
         delete mSpanRect;
      }

      if (inTarget.mPixelFormat==pfAlpha)
      {
         mAlphaMask->RenderBitmap(tx,ty,inTarget,inState);
      }
      else
         mFiller->Fill(*mAlphaMask,tx,ty,inTarget,inState);

      return true;
   }
   void BuildSolid(const UserPoint &inP0, const UserPoint &inP1)
   {
      mSpanRect->Line( mTransform.ToImageAA(inP0), mTransform.ToImageAA(inP1) );
   }

   void BuildCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2)
   {
      // todo: calculate steps
      double len = (inP0-inP1).Norm() + (inP2-inP1).Norm();
      int steps = (int)len;
      if (steps<1) steps = 1;
      if (steps>100) steps = 100;
      double step = 1.0/(steps+1);
      Fixed10 last = mTransform.ToImageAA(inP0);
      double t = 0;

      for(int s=0;s<steps;s++)
      {
         t+=step;
         double t_ = 1.0-t;
         UserPoint p = inP0 * (t_*t_) + inP1 * (2.0*t*t_) + inP2 * (t*t);
         Fixed10 fixed = mTransform.ToImageAA(p);
         mSpanRect->Line(last,fixed);
         last = fixed;
      }
      mSpanRect->Line( last, mTransform.ToImageAA(inP2) );
   }

   void HitTestCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2)
   {
      if ( (inP0.y<=mHitTest.y && inP1.y<=mHitTest.y && inP2.y<=mHitTest.y) ||
           (inP0.y>=mHitTest.y && inP1.y>=mHitTest.y && inP2.y>=mHitTest.y) )
         return;

      // todo: calculate steps
      double len = (inP0-inP1).Norm() + (inP2-inP1).Norm();
      int steps = (int)(len * 0.5);
      if (steps<1) steps = 1;
      if (steps>100) steps = 100;
      double step = 1.0/(steps+1);
      double t = 0;
      UserPoint last = inP0;

      for(int s=0;s<steps;s++)
      {
         t+=step;
         double t_ = 1.0-t;
         UserPoint p = inP0 * (t_*t_) + inP1 * (2.0*t*t_) + inP2 * (t*t);
         BuildHitTest(last,p);
         last = p;
      }
      BuildHitTest(last,inP2);
   }



   void CurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2)
   {
      // B(t) = (1-t)^2p0 + 2(1-t)t p1 + t^2p2
      // Find maxima/minima : d/dt B(t) = 0
      //  d/dt x(t) = -2(1-t) p0.x + (2 -4t)p1.x + 2t p2.x = 0
      //
      //  -> t 2[  p2.x+p0.x - 2 p1.x ] = 2 p0.x - 2p1.x
      double denom = p2.x + p0.x - 2*p1.x;
      if (denom!=0)
      {
         double t = (p0.x-p1.x)/denom;
         if (t>0 && t<1)
            mBuildExtent->AddX( (1-t)*(1-t)*p0.x + 2*t*(1-t)*p1.x + t*t*p2.x );
      }
      denom = p2.y + p0.y - 2*p1.y;
      if (denom!=0)
      {
         double t = (p0.y-p1.y)/denom;
         if (t>0 && t<1)
            mBuildExtent->AddY( (1-t)*(1-t)*p0.y + 2*t*(1-t)*p1.y + t*t*p2.y );
      }
      mBuildExtent->Add( p0 );
      mBuildExtent->Add( p2 );
   }

	bool Hits(const RenderState &inState)
   {
		if (inState.mClipRect.w!=1 || inState.mClipRect.h!=1)
			return false;

	   UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);

		Extent2DF extent;
      CachedExtentRenderer::GetExtent(inState.mTransform,extent);
		if (!extent.Contains(screen))
			return false;

	   mHitTest = inState.mTransform.mMatrix->ApplyInverse(screen);

      mHitsLeft = 0;
      Iterate(itHitTest, Matrix());
      return mHitsLeft & 0x01;
   }

   void BuildHitTest(const UserPoint &inP0, const UserPoint &inP1)
   {
      if ( (inP0.y < mHitTest.y) != (inP1.y< mHitTest.y) )
      {
         double l1 = (mHitTest.y-inP0.y) / (inP1.y-inP0.y);
         double x = inP0.x  + l1 * (inP1.x - inP0.x);
         if (x<mHitTest.x)
            mHitsLeft++;
      }
   }


   virtual void Iterate(IterateMode inMode,const Matrix &m) = 0;
   virtual void AlignOrthogonal()  { }

   UserPoint           mHitTest;
   int                 mHitsLeft;
   Transform           mTransform;
   Matrix              mTransMat;
   Scale9              mTransScale9;
   QuickVec<UserPoint> mTransformed;
   Filler              *mFiller;
   Extent2DF           *mBuildExtent;
   SpanRect            *mSpanRect;
   AlphaMask           *mAlphaMask;

   const QuickVec<uint8> &mCommands;
   const QuickVec<float> &mData;

   int             mCommand0;
   int             mData0;
   int             mCommandCount;
   int             mDataCount;
};



class LineRender : public PolygonRender
{
   typedef void (LineRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
   ItFunc ItLine;
   double mDTheta;
   GraphicsStroke *mStroke;

public:
   LineRender(const GraphicsJob &inJob, const GraphicsPath &inPath) :
       PolygonRender(inJob, inPath, inJob.mStroke->fill)
   {
      mStroke = inJob.mStroke;
   }

   void BuildExtent(const UserPoint &inP0, const UserPoint &inP1)
   {
      mBuildExtent->Add(inP0);
   }


   inline void AddLinePart(UserPoint p0, UserPoint p1, UserPoint p2, UserPoint p3)
   {
      (*this.*ItLine)(p0,p1);
      (*this.*ItLine)(p2,p3);
   }

   void IterateCircle(const UserPoint &inP0, const UserPoint &inPerp, double inTheta,
                      const UserPoint &inPerp2 )
   {
      UserPoint other(inPerp.CWPerp());
      UserPoint last = inP0+inPerp;
      for(double t=mDTheta; t<inTheta; t+=mDTheta)
      {
         double c = cos(t);
         double s = sin(t);
         UserPoint p = inP0+inPerp*c + other*s;
         (*this.*ItLine)(last,p);
         last = p;
      }
      (*this.*ItLine)(last,inP0+inPerp2);
   }


   inline void AddJoint(const UserPoint &p0, const UserPoint &perp1, const UserPoint &perp2)
   {
      bool miter = false;
      switch(mStroke->joints)
      {
         case sjMiter:
            miter = true;
         case sjRound:
         {
            double acw_rot = perp2.Cross(perp1);
            // One side is easy since it is covered by the fat bits of the lines, so
            //  just join up with simple line...
            UserPoint p1,p2;
            if (acw_rot==0)
               return;
            if (acw_rot>0)
            {
               (*this.*ItLine)(p0-perp2,p0-perp1);
               p1 = perp1;
               p2 = perp2;
            }
            else
            {
               (*this.*ItLine)(p0+perp1,p0+perp2);
               p1 = -perp2;
               p2 = -perp1;
            }
            // The other size, we must treat properly...
            if (miter)
            {
               UserPoint dir1 = p1.CWPerp();
               UserPoint dir2 = p2.Perp();
               // Find point where:
               //   p0+p1 + a * dir1 = p0+p2 + a * dir2
               //   a [ dir1.x-dir2.x] = p0.x+p2.x - p0.x - p1.x;
               //
               //    also (which ever is better conditioned)
               //
               //   a [ dir1.y-dir2.y] = p0.y+p2.y - p0.x - p1.y;
               double ml = mStroke->miterLimit;
               double denom_x = dir1.x-dir2.x;
               double denom_y = dir1.y-dir2.y;
               double a = (denom_x==0 && denom_y==0) ? ml :
                          fabs(denom_x)>fabs(denom_y) ? std::min(ml,(p2.x-p1.x)/denom_x) :
                                                        std::min(ml,(p2.y-p1.y)/denom_y);
               if (a<ml)
               {
                  UserPoint point = p0+p1 + dir1*a;
                  (*this.*ItLine)(p0+p1,point);
                  (*this.*ItLine)(point, p0+p2);
               }
               else
               {
                  UserPoint point1 = p0+p1 + dir1*a;
                  UserPoint point2 = p0+p2 + dir2*a;
                  (*this.*ItLine)(p0+p1,point1);
                  (*this.*ItLine)(point1,point2);
                  (*this.*ItLine)(point2, p0+p2);
               }
            }
            else
            {
               // Find angle ...
               double dot = perp1.Dot(perp2) / sqrt( perp1.Norm2() * perp2.Norm2() );
               double theta = acos(dot);
               IterateCircle(p0,p1,theta,p2);
            }
            break;
         }
         default:
            (*this.*ItLine)(p0+perp1,p0+perp2);
            (*this.*ItLine)(p0-perp2,p0-perp1);
      }
   }

   inline void EndCap(UserPoint p0, UserPoint perp)
   {
      switch(mStroke->caps)
      {
         case  scSquare:
            {
               UserPoint edge(perp.y,-perp.x);
               (*this.*ItLine)(p0+perp,p0+perp+edge);
               (*this.*ItLine)(p0+perp+edge,p0-perp+edge);
               (*this.*ItLine)(p0-perp+edge,p0-perp);
            break;
            }
         case  scRound:
            IterateCircle(p0,perp,M_PI,-perp);
            break;

         default:
            (*this.*ItLine)(p0+perp,p0-perp);
      }
   }

   void Iterate(IterateMode inMode,const Matrix &m)
   {
      ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
               inMode==itCreateRenderer ? &LineRender::BuildSolid :
                       &LineRender::BuildHitTest;

      // Convert line data to solid data
      double perp_len = mStroke->thickness*0.5;
      switch(mStroke->scaleMode)
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

      // This may be too fine ....
      mDTheta = M_PI/perp_len;

      int n = mCommandCount;
      UserPoint *point = 0;

      if (inMode==itHitTest)
      {
         point = (UserPoint *)&mData[ mData0 ];
      }
      else
         point = &mTransformed[0];

      // It is a loop if the path has no breaks, it has more than 2 points
      //  and it finishes where it starts...
      UserPoint first;
      UserPoint first_perp;

      UserPoint prev;
      UserPoint prev_perp;

      int points = 0;

      for(int i=0;i<n;i++)
      {
         switch(mCommands[mCommand0 + i])
            {
            case pcWideMoveTo:
               point++;
            case pcBeginAt:
            case pcMoveTo:
               if (points==1 && prev==*point)
               {
                  point++;
                  continue;
               }
               if (points>1)
               {
                  if (points>2 && *point==first)
                  {
                     AddJoint(first,prev_perp,first_perp);
                     points = 1;
                  }
                  else
                  {
                     EndCap(first,-first_perp);
                     EndCap(prev,prev_perp);
                  }
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
                  if (*point==prev)
                  {
                     point++;
                     continue;
                  }
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
               {
                  // Gradients pointing from end-point to control point - trajectory
                  //  is initially parallel to these, end cap perpendicular...
                  UserPoint g0 = point[0]-prev;
                  UserPoint g2 = point[1]-point[0];

                  UserPoint perp = g0.Perp(perp_len);
                  UserPoint perp_end = g2.Perp(perp_len);


                  if (points>0)
                  {
                     if (points>1)
                        AddJoint(prev,prev_perp,perp);
                     else
                        first_perp = perp;
                  }

                  // Add curvy bits

                  UserPoint p0_top = prev+perp;
                  UserPoint p2_top = point[1]+perp_end;

                  UserPoint p0_bot = prev-perp;
                  UserPoint p2_bot = point[1]-perp_end;
                  // Solve for control point - it goes though the points perp_len from
                  //  the end control points.  At each end, the gradient of the trajectory
                  //  will point to the control point, and these gradients are parallel
                  //  to the original gradients, g0, g2
                  //
                  //  p0 + a*g0 = ctrl
                  //  p2 + b*g2 = ctrl
                  //
                  //  a g0.x  + p0.x = ctrl.x = p2.x + b *g2.x
                  //  -> a g0.x - b g2.x = p2.x-p0.x
                  //  -> a g0.y - b g2.y = p2.y-p0.y
                  //
                  //  HMM, this does not appear to completely work - I guess my assumption that the
                  //   inner and outer curves are also quadratic beziers is wrong.
                  //   Might have to do it the hard way...
                  double det = g2.y*g0.x - g2.x*g0.y;
                  if (det==0) // degenerate - just use line ...
                  {
                     AddLinePart(p0_top,p2_top,p2_bot,p0_bot);
                  }
                  else
                  {
                     double b_top = ((p2_top.x-p0_top.x)*g0.y - (p2_top.y-p0_top.y)*g0.x) / det;
                     UserPoint ctrl_top = p2_top + g2*b_top;
                     double b_bot = ((p2_bot.x-p0_bot.x)*g0.y - (p2_bot.y-p0_bot.y)*g0.x) / det;
                     UserPoint ctrl_bot = p2_bot + g2*b_bot;

                     if (inMode==itGetExtent)
                     {
                        CurveExtent(p0_top,ctrl_top,p2_top);

                        CurveExtent(p2_bot,ctrl_bot,p0_bot);
                     }
                     else if (inMode==itHitTest)
                     {
                        HitTestCurve(p0_top,ctrl_top,p2_top);

                        HitTestCurve(p2_bot,ctrl_bot,p0_bot);
                     }
                     else
                     {
                        BuildCurve(p0_top,ctrl_top,p2_top);

                        BuildCurve(p2_bot,ctrl_bot,p0_bot);
                     }
                  }

                  prev = point[1];
                  prev_perp = perp_end;
                  point +=2;
                  points++;
                  // Implicit loop closing...
                  if (points>2 && prev==first)
                  {
                     AddJoint(first,perp_end,first_perp);
                     points = 1;
                  }
               }
               break;
         }
      }

      if (points>1)
      {
         EndCap(first,-first_perp);
         EndCap(prev,prev_perp);
      }
   }

   void AlignOrthogonal()
   {
      int n = mCommandCount;
      UserPoint *point = &mTransformed[0];

      if (mStroke->pixelHinting)
      {
         n = mTransformed.size();
         for(int i=0;i<n;i++)
         {
            UserPoint &p = mTransformed[i];
            p.x = floor(p.x) + 0.5;
            p.y = floor(p.y) + 0.5;
         }
         return;
      }

      UserPoint *first = 0;
      UserPoint *prev = 0;
      for(int i=0;i<n;i++)
      {
         switch(mCommands[mCommand0 + i])
         {
            case pcWideMoveTo:
               point++;
            case pcBeginAt:
            case pcMoveTo:
               if (first)
                  Align(*first,*point);
               first = point;
               break;

            case pcWideLineTo:
               point++;
            case pcLineTo:
               if (prev)
                  Align(*prev,*point);
               break;

            case pcCurveTo:
               point++;
               break;
         }
         prev = point++;
      }
   }


};


class SolidRender :public PolygonRender
{

public:
   SolidRender(const GraphicsJob &inJob, const GraphicsPath &inPath) :
       PolygonRender(inJob, inPath, inJob.mFill)
   {
   }



   void Iterate(IterateMode inMode,const Matrix &)
   {
      int n = mCommandCount;
      const UserPoint *point = 0;

      if (inMode==itHitTest)
         point = (const UserPoint *)&mData[ mData0 ];
      else
         point = &mTransformed[0];


      if (inMode==itGetExtent)
      {
         UserPoint last;
         for(int i=0;i<n;i++)
         {
            switch(mCommands[ mCommand0 + i])
            {
               case pcWideLineTo:
               case pcWideMoveTo:
                  point++;
               case pcLineTo:
               case pcMoveTo:
               case pcBeginAt:
                  last = *point;
                  mBuildExtent->Add(last);
                  point++;
                  break;
               case pcCurveTo:
                  CurveExtent(last, point[0], point[1]);
                  last = point[1];
                  mBuildExtent->Add(last);
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

         typedef void (PolygonRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
         ItFunc func = inMode==itCreateRenderer ? &PolygonRender::BuildSolid :
                  &PolygonRender::BuildHitTest;

         for(int i=0;i<n;i++)
         {
            switch(mCommands[ mCommand0 + i])
            {
               case pcWideMoveTo:
                  point++;
               case pcMoveTo:
               case pcBeginAt:
                  if (points>1)
                     (*this.*func)(last_point,last_move);
                  points = 1;
                  last_point = *point++;
                  last_move = last_point;
                  break;

               case pcWideLineTo:
                  point++;
               case pcLineTo:
                  if (points>0)
                     (*this.*func)(last_point,*point);
                  last_point = *point++;
                  points++;
                  break;

               case pcCurveTo:
                  if (inMode==itHitTest)
                     HitTestCurve(last_point, point[0], point[1]);
                  else
                     BuildCurve(last_point, point[0], point[1]);
                  last_point = point[1];
                  point += 2;
                  points++;
                  break;
            }
         }
      }
   }
};



Renderer *Renderer::CreateSoftware(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   if (inJob.mStroke)
      return new LineRender(inJob,inPath);
   else
      return new SolidRender(inJob,inPath);
}


}


