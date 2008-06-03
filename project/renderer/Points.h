#ifndef POINTS_H
#define POINTS_H


struct ImagePoint
{
   Sint16 x;
   Sint16 y;
};

struct PointF16
{
   inline PointF16() {}
   inline PointF16(int inX,int inY) :x(inX), y(inY) {}
   inline PointF16(double inX,double inY)
   {
      x =  (int)(inX * 65536.0 + 0.5);
      y =  (int)(inY * 65536.0 + 0.5);
   }

   inline int X() const { return x>>16; };
   inline int Y() const { return y>>16; };
   inline int X(int inAABits) const { return x>>(16-inAABits); };
   inline int Y(int inAABits) const { return y>>(16-inAABits); };

   inline PointF16(const PointF16 &inRHS) :x(inRHS.x), y(inRHS.y) {}
   inline PointF16(const ImagePoint &inRHS) :
                x(inRHS.x<<16), y(inRHS.y<<16) { }
   
   inline bool operator==(const PointF16 inRHS) const
      { return x==inRHS.x && y==inRHS.y; }

   inline bool operator!=(const PointF16 inRHS) const
      { return x!=inRHS.x && y!=inRHS.y; }


   inline PointF16 operator-(const PointF16 inRHS) const
      { return PointF16(x-inRHS.x,y-inRHS.y); }

   inline PointF16 operator+(const PointF16 inRHS) const
      { return PointF16(x+inRHS.x,y+inRHS.y); }

   inline PointF16 operator*(int inScalar) const
      { return PointF16(x*inScalar,y*inScalar); }

   inline PointF16 operator/(int inDivisor) const
      { return PointF16(x/inDivisor,y/inDivisor); }

   inline PointF16 operator>>(int inShift) const
      { return PointF16(x>>inShift,y>>inShift); }

   inline PointF16 operator<<(int inShift) const
      { return PointF16(x<<inShift,y<<inShift); }

   inline void operator+=(const PointF16 &inRHS)
      { x+=inRHS.x, y+=inRHS.y; }

   int x;
   int y;
};


template<int AA_BITS_>
struct PointAA
{
   enum { AABits = AA_BITS_ };
   enum { ToAA = 16-AA_BITS_ };

   inline PointAA() {}
   inline PointAA(int inX,int inY) :x(inX), y(inY) {}

   inline PointAA(const PointAA &inRHS) :x(inRHS.x), y(inRHS.y) {}

   inline PointAA(const PointF16 &inRHS) :
                x(inRHS.x>>ToAA), y(inRHS.y>>ToAA) { }
   
   inline PointAA operator-(const PointAA inRHS) const
      { return PointAA(x-inRHS.x,y-inRHS.y); }

   inline PointAA operator+(const PointAA inRHS) const
      { return PointAA(x+inRHS.x,y+inRHS.y); }

   inline PointAA operator*(int inScalar) const
      { return PointAA(x*inScalar,y*inScalar); }

   inline PointAA operator/(int inDivisor) const
      { return PointAA(x/inDivisor,y/inDivisor); }

   inline PointAA operator>>(int inShift) const
      { return PointAA(x>>inShift,y>>inShift); }

   inline PointAA operator<<(int inShift) const
      { return PointAA(x<<inShift,y<<inShift); }

   inline void operator+=(const PointAA &inRHS)
      { x+=inRHS.x, y+=inRHS.y; }

   int x;
   int y;
};

template<typename T_>
struct Extent2D
{
   Extent2D() : mValid(false)
   {
      mMinX = mMinY = mMaxX = mMaxY = 0;
   }

   template<typename P_>
   inline void Add(P_ inX, P_ inY)
   {
      if (mValid)
      {
         if (inX<mMinX) mMinX = (T_)inX;
         else if (inX>mMaxX) mMaxX = (T_)inX;

         if (inY<mMinY) mMinY = (T_)inY;
         else if (inY>mMaxY) mMaxY = (T_)inY;
      }
      else
      {
         mMinX = mMaxX = (T_)inX;
         mMinY = mMaxY = (T_)inY;
         mValid = true;
      }
   }


   template<typename P_>
   inline void Add(const P_ &inPoint)
   {
      Add(inPoint.x,inPoint.y);
   }

   T_ Width() const { return mMaxX-mMinX; }
   T_ Height() const { return mMaxY-mMinY; }

   T_ mMinX,mMaxX;
   T_ mMinY,mMaxY;
   bool mValid;
};

typedef Extent2D<int> Extent2DI;
typedef Extent2D<float> Extent2DF;




#endif
