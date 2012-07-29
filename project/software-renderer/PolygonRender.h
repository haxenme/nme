#ifndef POLYGON_RENDER_H
#define POLYGON_RENDER_H


#include <CachedExtent.h>
#include <vector>
#include "AlphaMask.h"


namespace nme
{

enum IterateMode { itGetExtent, itCreateRenderer, itHitTest };

typedef QuickVec<int> IQuickSet;


struct Transition
{
   
   int x;
   short val;
   
   Transition(int inX = 0, int inVal = 0) : x(inX), val(inVal) {}
   
   bool operator<(const Transition &inRHS) const
   {
      return x < inRHS.x;
   }
   
   void operator+=(int inDiff)
   {
      val += inDiff;
   }
   
};


struct Transitions
{
   
   int mLeft;
   QuickVec<Transition> mX;
   
   void Compact()
   {
      Transition *ptr = mX.begin();
      Transition *end = mX.end();
      
      if (ptr == end) return;
      
      std::sort(ptr, end);
      Transition *dest = ptr;
      ptr++;
      
      for(; ptr < end; ptr++)
      {
         if (dest->x == ptr->x)
         {
            dest->val += ptr->val;
         }
         else
         {
            ++dest;
            if (dest != ptr)
               *dest = *ptr;
         }
      }
      
      mX.resize(dest - mX.begin() + 1);
      
   }
   
};


extern Lines sLineBuffer;
extern AlphaRuns *sLines;
extern Transitions *sTransitions;
extern std::vector<Transitions> sTransitionsBuffer;


template<int BITS>   struct AlphaIterator
{
   
   enum { Size = (1 << BITS) };
   enum { Mask = ~((1 << BITS) - 1) };
   
   AlphaRun  *mEnd;
   AlphaRun  *mPtr;
   AlphaRuns mRuns;
   
   
   AlphaIterator()
   {
      mEnd = mPtr = 0;
   }
   
   
   void Reset()
   {
      mRuns.resize(0);
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
   inline int SetX(int inX, int &outNextX)
   {
      // zip along until we hit x
      do
      {
         if (mPtr == mEnd)
            return 0;
         if (mPtr->mX1 > inX)
            break;
         mPtr++;
         
      } while(1);
      
      int box = inX + Size;
      
      if (mPtr->mX0 >= box)
      {
         int next = mPtr->mX0 & Mask;
         if (outNextX > next)
            outNextX = next;
         return 0;
      }
      
      int next;
      
      if ( mPtr->mX0 > inX)
      {
         next = inX + Size;
      }
      else
      {
         next = mPtr->mX1 & Mask;
         if (next == inX)
            next += Size;
      }
      
      if (outNextX > next)
         outNextX = next;
      
      // Calculate number of pixels overlapping...
      int alpha = inX - mPtr->mX0;
      if (alpha > 0) alpha = 0;
      
      if (mPtr->mX1 < box)
      {
         alpha += mPtr->mX1 - inX;
         // Check next span too ...
         if (mPtr + 1 < mEnd)
         {
            AlphaRun &next = mPtr[1];
            if (next.mX0 < box)
            {
               if (next.mX1 < box)
                  alpha += next.mX1 - next.mX0;
               else
                  alpha += box - next.mX0;
            }
         }
      }
      else
      {
         alpha += Size;
      }
      
      return alpha;
   }
   
};


struct SpanRect
{
   
   int mAA;
   int mAAMask;
   int mLeftPos;
   int mMaxX;
   int mMinX;
   int mWinding;
   Rect   mRect;
   
   
   // dX/dY int fixed bits ...
   inline int FixedGrad(Fixed10 inVec, int inBits)
   {
      int denom = inVec.y;
      if (denom == 0)
         return 0;
      
      int64 ratio = (((int64)inVec.x) << inBits) / denom;
      if (ratio < -(1 << 21)) return -(1 << 21);
      if (ratio >  (1 << 21)) return  (1 << 21);
      return ratio;
   }
   
   
   template<bool MASK_AA_X, bool MASK_AA_Y>
   void Line(Fixed10 inP0, Fixed10 inP1)
   {
      // All right ...
      if (inP0.x > mMaxX && inP1.x > mMaxX)
         return;
      
      // Make p1.y numerically greater than inP0.y
      int y0 = inP0.Y() - mRect.y;
      int y1 = inP1.Y() - mRect.y;
      
      if (MASK_AA_Y)
      {
         y0 = y0 & mAAMask;
         y1 = y1 & mAAMask;
      }
      
      int dy = y1-y0;
      if (dy == 0)
         return;
      
      int diff = 1;
      
      if (dy < 0)
      {
         diff = -1;
         std::swap(y0, y1);
         std::swap(inP0, inP1);
      }
      
      // All up or all down ....
      if (y0 >= mRect.h || y1 <= 0)
         return;
      
      // Just draw a vertical line down the left...
      if (inP0.x <= mMinX && inP1.x <= mMinX)
      {
         y0 = std::max(y0, 0);
         y1 = std::min(y1, mRect.h);
         
         for(; y0 < y1; y0++)
            sTransitions[y0].mLeft += diff;
         
         return;
      }
      
      // dx_dy in 10 bit precision ...
      int dx_dy = FixedGrad(inP1 - inP0, 10);
      
      // (10 bit) fractional bit true position pokes up above the first line...
      int extra_y = ((y0 + (MASK_AA_Y ? mAA : 1) + mRect.y) << 10) - inP0.y;
      // We have already started down the gradient bt a bit, so adjust x.
      // x is 10 bits, dx_dy is 10 bits and extra_y is 10 bits ...
      int x = inP0.x + ((dx_dy * extra_y)>>10);
      
      if (y0 < 0)
      {
         x -= y0 * dx_dy;
         y0 = 0;
      }
      
      int last = std::min(y1, mRect.h);
      
      if (MASK_AA_X)
      {
         dx_dy *= mAA;
         
         for(; y0 < last; y0 += mAA)
         {
            // X is fixed-10, y is fixed-aa
            int x_val = (x >> 10) & mAAMask;
            
            if (x_val < mMaxX)
            {
               for (int a = 0; a < mAA; a++)
                  sTransitions[y0 + a].mX.push_back(Transition(x_val, diff));
            }
            
            x += dx_dy; 
         }
      }
      else
      {
         for(; y0 < last; y0++)
         {
            // X is fixed-10, y is fixed-aa
            if (x < mMaxX)
               sTransitions[y0].mX.push_back(Transition(x >> 10, diff));
            
            x += dx_dy; 
         }
      }
   }
   
   
   SpanRect(const Rect &inRect, int inAA)
   {
      mAA =  inAA;
      mAAMask = ~(mAA-1);
      mRect = inRect * inAA;
      mWinding = 0xffffffff;
      
      if (sTransitionsBuffer.size() < mRect.h)
      {
         sTransitionsBuffer.resize(mRect.h);
         sTransitions = &sTransitionsBuffer[0];
      }
      
      for (int y = 0; y < mRect.h; y++)
      {
         sTransitions[y].mLeft = 0;
         sTransitions[y].mX.resize(0);
      }
      
      mMinX = (mRect.x - 1) << 10;
      mMaxX = (mRect.x1()) << 10;
      mLeftPos = mRect.x;
   }
   
   
   void BuildAlphaRuns2(Transitions *inTrans, AlphaRuns &outRuns, int inFactor)
   {
      static AlphaIterator<1> a0,a1;
      a0.Reset();
      a1.Reset();
      
      BuildAlphaRuns(inTrans[0], a0.mRuns, 256);
      BuildAlphaRuns(inTrans[1], a1.mRuns, 256);
      
      enum { MAX_X = 0x7fffffff };
      
      int x = mRect.x;
      
      a0.Init(x);
      a1.Init(x);
      int f = inFactor >> 2;
      
      while(x < MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x, next_x) + a1.SetX(x, next_x);
         
         if (next_x == MAX_X)
            break;
         if (alpha > 0)
            outRuns.push_back(AlphaRun(x >> 1, next_x >> 1, alpha * f));
         
         x = next_x;
      }
   }
   
   
   void BuildAlphaRuns4(Transitions *inTrans, AlphaRuns &outRuns, int inFactor)
   {
      static AlphaIterator<2> a0,a1,a2,a3;
      a0.Reset();
      a1.Reset();
      a2.Reset();
      a3.Reset();
      
      BuildAlphaRuns(inTrans[0], a0.mRuns, 256);
      BuildAlphaRuns(inTrans[1], a1.mRuns, 256);
      BuildAlphaRuns(inTrans[2], a2.mRuns, 256);
      BuildAlphaRuns(inTrans[3], a3.mRuns, 256);
      
      enum { MAX_X = 0x7fffffff };
      
      int x = mRect.x;
      
      a0.Init(x);
      a1.Init(x);
      a2.Init(x);
      a3.Init(x);
      
      int f = inFactor >> 4;
      
      while(x < MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x, next_x) + a1.SetX(x, next_x) + a2.SetX(x, next_x) + a3.SetX(x, next_x);
         
         if (next_x == MAX_X)
            break;
         if (alpha > 0)
            outRuns.push_back(AlphaRun(x >> 2, next_x >> 2, alpha * f));
         
         x = next_x;
      }
   }
   
   
   void BuildAlphaRuns(Transitions &inTrans, AlphaRuns &outRuns, int inFactor)
   {
      int last_x = mRect.x;
      inTrans.Compact();
      int total = inTrans.mLeft;
      Transition *end = inTrans.mX.end();
      int alpha =  (total & mWinding) ? inFactor : 0;
      
      for (Transition *t = inTrans.mX.begin(); t != end; ++t)
      {
         if (t->val)
         {
            if (t->x >= mRect.x1())
            {
               if (alpha > 0 && last_x < t->x)
                  outRuns.push_back(AlphaRun(last_x, mRect.x1(), alpha));
               return;
            }
            
            if (alpha > 0 && last_x < t->x)
               outRuns.push_back(AlphaRun(last_x, t->x, alpha));
            
            last_x = std::max(t->x, mRect.x);
            
            total += t->val;
            alpha = (total & mWinding) ? inFactor : 0;
         }
      }
      
      
      if (alpha > 0)
        outRuns.push_back(AlphaRun(last_x, mRect.x1(), alpha));
   }
   
   
   AlphaMask *CreateMask(const Transform &inTransform, int inAlpha)
   {
      Rect rect = mRect / mAA;
      
      if (sLineBuffer.size() < rect.h)
      {
         sLineBuffer.resize(rect.h);
         sLines = &sLineBuffer[0];
      }
      
      AlphaMask *mask = AlphaMask::Create(rect, inTransform);
      Transitions *t = &sTransitions[0];
      int start = 0;
      
      for (int y = 0; y < rect.h; y++)
      {
         sLines[y].resize(0);
         mask->mLineStarts[y] = start;
         
         switch(mAA)
         {
            case 1:
               BuildAlphaRuns(*t, sLines[y], inAlpha);
               break;
            case 2:
               BuildAlphaRuns2(t, sLines[y], inAlpha);
               break;
            case 4:
               BuildAlphaRuns4(t, sLines[y], inAlpha);
               break;
         }
         start += sLines[y].size();
         t += mAA;
      }
      
      mask->mLineStarts[rect.h] = start;
      mask->mAlphaRuns.resize(start);
      
      for (int y = 0; y < rect.h; y++)
      {
         memcpy(&mask->mAlphaRuns[mask->mLineStarts[y]], &sLines[y][0], (mask->mLineStarts[y + 1] - mask->mLineStarts[y]) * sizeof(AlphaRun));
      }
      
      /*
      static int last_total = 0;
      int mem = 0;
      for(int i=0;i<sLineBuffer.size();i++)
         mem+=sLines[i].Mem();
      for(int i=0;i<sTransitionsBuffer.size();i++)
         mem+=sTransitionsBuffer[i].mX.Mem();
      if (mem>last_total)
      {
         last_total = mem;
         printf("Reserved(%d,%d) = %d\n", sLineBuffer.size(), sTransitionsBuffer.size(),last_total);
      }
      */
      
      return mask;
   }
   
};







class PolygonRender : public CachedExtentRenderer
{
public:
   PolygonRender(const GraphicsJob &inJob, const GraphicsPath &inPath, IGraphicsFill *inFill);


   static PolygonRender *CreateLines(const GraphicsJob &inJob, const GraphicsPath &inPath);
   static PolygonRender *CreateTriangleLines(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid);
   
   ~PolygonRender();
   void Destroy();
   
   void GetExtent(CachedExtent &ioCache);
   virtual void SetTransform(const Transform &inTransform);
   void Align(const UserPoint &t0, const UserPoint &t1, UserPoint &ioP0, UserPoint &ioP1);
   bool Render(const RenderTarget &inTarget, const RenderState &inState);
   void BuildSolid(const UserPoint &inP0, const UserPoint &inP1);
   void BuildCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2);
   void BuildFatCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2, double perp_len, const UserPoint &perp0, const UserPoint perp1);
   void HitTestCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2);
   void HitTestFatCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2, double perp_len, const UserPoint &perp0, const UserPoint &perp1);
   void CurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2);
   void FatCurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2, double perp_len);
   bool Hits(const RenderState &inState);
   void BuildHitTest(const UserPoint &inP0, const UserPoint &inP1);
   virtual int  GetWinding() { return 0xffffffff; }
   
   virtual int Iterate(IterateMode inMode,const Matrix &m) = 0;
   virtual void AlignOrthogonal() {}
   
   UserPoint mHitTest;
   int mHitsLeft;
   Transform mTransform;
   Matrix mTransMat;
   Scale9 mTransScale9;
   QuickVec<UserPoint> mTransformed;
   Filler *mFiller;
   Extent2DF *mBuildExtent;
   SpanRect *mSpanRect;
   AlphaMask *mAlphaMask;
   
   const QuickVec<uint8> &mCommands;
   const QuickVec<float> &mData;
   
   int mCommand0;
   int mData0;
   int mCommandCount;
   int mDataCount;
   
};


} // end namespace nme


#endif
