#include "RenderPolygon.h"
#include "AA.h"

Uint8  AA4x::mDrawing[32];
Uint8  AA4x::mAlpha[32];



// Find y-extent of object, this is in pixels, and is the intersection
//  with the screen y-extent.
bool FindObjectYExtent(int &ioMinY, int &ioMaxY,int inN,
          const PointF16 *inPoints,const PolyLine *inLines)
{
   int min_y = 0;
   int max_y = 0;

   if (inN<2)
      return false;

   if (inLines)
   {
      int pid0 = inLines->mPointIndex0;
      double extra = 0.5;
      if (inLines->mJoints == NME_CORNER_MITER)
         extra += inLines->mMiterLimit;
      int w = int(inLines->mThickness*1.41*extra + 0.999);

      min_y = inPoints[pid0].Y();
      max_y = min_y;

      size_t n = inLines->mPointIndex1 - pid0 + 1;
      for(size_t i=1;i<n;i++)
      {
         int y = inPoints[ pid0 + i ].Y();
         if (y<min_y) min_y = y;
         else if (y>max_y) max_y = y;
      }
      min_y -= w;
      max_y += w;
   }
   else
   {
      min_y = inPoints[0].Y();
      max_y = min_y;
      for(int i=1;i<inN;i++)
      {
         int y = inPoints[i].Y();
         if (y<min_y) min_y = y;
         else if (y>max_y) max_y = y;
      }
   }

   // exclusive of last point
   max_y++;

   if (min_y >= ioMaxY || max_y<ioMinY)
   {
      ioMinY = ioMaxY = 0;
      return false;
   }

   if (min_y > ioMinY)
      ioMinY = min_y;

   if (max_y < ioMaxY)
      ioMaxY = max_y;

   return true;
}


