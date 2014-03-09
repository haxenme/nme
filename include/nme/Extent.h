#ifndef NME_EXTENT_H
#define NME_EXTENT_H

namespace nme
{

   


template<typename T_>
struct Extent2D
{
   Extent2D() : mValidX(false), mValidY(false)
   {
      mMinX = mMinY = mMaxX = mMaxY = 0;
   }


   template<typename P_>
   inline void AddX(P_ inX)
   {
      if (mValidX)
      {
         if (inX<mMinX) mMinX = (T_)inX;
         else if (inX>mMaxX) mMaxX = (T_)inX;
      }
      else
      {
         mMinX = mMaxX = (T_)inX;
         mValidX = true;
      }

   }

   template<typename P_>
   inline void AddY(P_ inY)
   {
      if (mValidY)
      {
         if (inY<mMinY) mMinY = (T_)inY;
         else if (inY>mMaxY) mMaxY = (T_)inY;
      }
      else
      {
         mMinY = mMaxY = (T_)inY;
         mValidY = true;
      }
   }

   template<typename P_>
   inline void Add(P_ inX, P_ inY)
   {
      AddX(inX);
      AddY(inY);
   }


   template<typename P_>
   inline void Add(const P_ &inPoint)
   {
      AddX(inPoint.x);
      AddY(inPoint.y);
   }

   inline void Add(const Extent2D<T_> &inExtent)
   {
      if (inExtent.mValidX)
      {
         AddX(inExtent.mMinX);
         AddX(inExtent.mMaxX);
      }
      if (inExtent.mValidY)
      {
         AddY(inExtent.mMinY);
         AddY(inExtent.mMaxY);
      }
   }

   bool Intersect(T_ inX0,T_ inY0, T_ inX1, T_ inY1)
   {
      if (!mValidX)
      {
         mMinX = inX0;
         mMaxX = inX1;
         mValidX = true;
      }
      else
      {
         if (inX0 > mMinX) mMinX = inX0;
         if (inX1 < mMaxX) mMaxX = inX1;
      }
      if (!mValidY)
      {
         mMinY = inY0;
         mMaxY = inY1;
         mValidY = true;
      }
      else
      {
         if (inY0 > mMinY) mMinY = inY0;
         if (inY1 < mMaxY) mMaxY = inY1;
      }
      return mMinX<mMaxX && mMinY<mMaxY;
   }

   template<typename O_>
   bool Contains(const O_ &inOther) const
   {
      return mValidX && mValidY && inOther.x>=mMinX && inOther.x<mMaxX &&
             inOther.y>=mMinY && inOther.y<mMaxY;
   }


   void Translate(int inTX,int inTY)
   {
      mMinX += inTX;
      mMaxX += inTX;
      mMinY += inTY;
      mMaxY += inTY;
   }

   void Transform(double inSX, double inSY, double inTX, double inTY)
   {
      mMinX = inTX + inSX*(mMinX);
      mMaxX = inTX + inSX*(mMaxX);
      mMinY = inTY + inSY*(mMinY);
      mMaxY = inTY + inSY*(mMaxY);
   }

   TRect<T_> Rect() const
   {
      if (!Valid()) return TRect<T_>(0,0,0,0);
      return TRect<T_>(mMinX,mMinY,mMaxX,mMaxY,true);
   }

   template<typename RECT>
   bool GetRect(RECT &outRect,double inExtraX=0,double inExtraY=0)
   {
       if (!Valid())
       {
          outRect = RECT(0,0,0,0);
          return false;
       }

       outRect = RECT(mMinX,mMinY,mMaxX+inExtraX,mMaxY+inExtraY,true);
       return true;
   }



   inline bool Valid() const { return mValidX && mValidY; }
   void Invalidate() { mValidX = mValidY = false; }

   T_ Width() const { return mMaxX-mMinX; }
   T_ Height() const { return mMaxY-mMinY; }

   T_ mMinX,mMaxX;
   T_ mMinY,mMaxY;
   bool mValidX,mValidY;
};

typedef Extent2D<int> Extent2DI;
typedef Extent2D<float> Extent2DF;



} // end namespace nme

#endif



