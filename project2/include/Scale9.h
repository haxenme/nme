#ifndef SCALE9_H
#define SCALE9_H

#include <Matrix.h>
#include <Points.h>

class Scale9
{
public:
   bool   mActive;
   double X0,Y0;
   double X1,Y1;
   double SX,SY;
   double X1Off,Y1Off;
   
   Scale9() : mActive(false) { }
   bool Active() const { return mActive; }
   void Activate(double inX0, double inY0, double inW, double inH,
                 double inSX, double inSY,
                 double inExtX0, double inExtY0, double inExtW, double inExtH )
   {
      mActive = true;
      X0 = inX0;
      Y0 = inY0;
      X1 = inW + X0;
      Y1 = inH + Y0;
      // Right of object before scaling
      double right = inExtX0 + inExtW;
      // Right of object after scaling
      double extra_x = right*(inSX - 1);
      // Size of central rect
      double middle_x = inW + extra_x;
      // Scaling of central rect
      SX = middle_x/inW;
      // For points > X1, add this on...
      X1Off = inW*(SX-1);

      // Same for Y:
      double bottom = inExtY0 + inExtH;
      double extra_y = bottom*(inSY - 1);
      double middle_y = inH + extra_y;
      SY = middle_y/inH;
      Y1Off = inH*(SY-1);
   }
   void Deactivate() { mActive = false; }
   bool operator==(const Scale9 &inRHS) const
   {
      if (mActive!=inRHS.mActive) return false;
      if (!mActive) return true;
      return X0==inRHS.X0 && X1==inRHS.X1 && Y0==inRHS.Y0 && Y1==inRHS.Y1 &&
             X1Off==inRHS.X1Off && Y1Off==inRHS.Y1Off;
   }
   double TransX(double inX)
   {
      if (inX<=X0) return inX;
      return inX>X1 ? inX + X1Off : X0 + (inX-X0)*SX;
   }
   double TransY(double inY)
   {
      if (inY<=Y0) return inY;
      return inY>Y1 ? inY + Y1Off : Y0 + (inY-Y0)*SY;
   }
   Matrix GetFillMatrix(const Extent2DF &inExtent)
   {
      // The mapping of the edges should remain unchanged ...
      double x0 = TransX(inExtent.mMinX);
      double x1 = TransX(inExtent.mMaxX);
      double y0 = TransY(inExtent.mMinY);
      double y1 = TransY(inExtent.mMaxY);
      double w = inExtent.Width();
      double h = inExtent.Height();
      Matrix result;
      result.mtx = -inExtent.mMinX;
      if (w!=0)
      {
         double s = (x1-x0)/w;
         result.m00 = s;
         result.mtx *= s;
      }
      result.mtx += x0;

      result.mty = -inExtent.mMinY;
      if (h!=0)
      {
         double s = (y1-y0)/h;
         result.m11 = s;
         result.mty *= s;
      }
      result.mty += y0;
      return result;
   }

};

#endif

