#include "Renderer.h"
#include "RenderPolygon.h"


int PolygonMask::sMaskID = 1;


void PolygonMask::GetExtent(Extent2DI &ioExtent)
{
   if (mExtent.Valid())
   {
      ioExtent.Add(mExtent);
      return;
   }

   for(int y=mMinY; y<mMaxY; y++)
   {
      AlphaRuns &line = mLines[y-mMinY];
      if (line.size())
      {
         ioExtent.AddY(y );
         ioExtent.AddX( line.begin()->mX0 );
         ioExtent.AddX( line.rbegin()->mX1 );
      }
   }
}






void PolygonMask::Add(const PolygonMask &inMask)
{
   // Nothing there yet?
   if (mMinY>=mMaxY)
   {
      mMinY = inMask.mMinY;
      mMaxY = inMask.mMaxY;
      mLines = inMask.mLines;
   }
   // Merge ...
   else
   {
   }
}

void PolygonMask::Mask(const PolygonMask &inMask)
{
   int min_y = std::max(inMask.mMinY,mMinY);
   int max_y = std::min(inMask.mMaxY,mMaxY);
   int n = max_y - min_y;
   if (n<=0)
   {
      mMinY = mMaxY = 0;
      mLines.resize(0);
      return;
   }

   //printf("Blend mask\n");

   const Lines lines0 = inMask.mLines;
   Lines lines(n);
   for(int l=0;l<n;l++)
   {
      const AlphaRuns &l0 = lines0[l+min_y-inMask.mMinY];
      const AlphaRuns &l1 = mLines[l+min_y-mMinY];
      AlphaRuns::const_iterator i0 = l0.begin();
      AlphaRuns::const_iterator i1 = l1.begin();
      AlphaRuns &target = lines[l];

      while(i0!=l0.end() && i1!=l1.end())
      {
         // i0 behind i1 ...
         if (i0->mX1 <= i1->mX0)
            i0++;
         // i1 behind i0 ...
         else if (i1->mX1 <= i0->mX0)
            i1++;
         // Overlapping ....
         else
         {
            int alpha = ( i0->mAlpha * i1->mAlpha ) >> 8;
            // i1 inside i0
            if (i0->mX0 <= i1->mX0  && i0->mX1>=i1->mX1)
            {
               if (alpha>0)
                  target.push_back( AlphaRun(i1->mX0, i1->mX1, alpha) );
               i1++;
            }
            // i1 inside i0
            else if (i1->mX0 <= i0->mX0  && i1->mX1>=i0->mX1)
            {
               if (alpha>0)
                  target.push_back( AlphaRun(i0->mX0, i0->mX1, alpha) );
               i0++;
            }
            // Partially overlapping - i0 is left-most
            else if (i0->mX0 <= i1->mX0)
            {
               if (alpha>0)
                  target.push_back( AlphaRun(i1->mX0, i0->mX1, alpha) );
               i0++;
            }
            // Partially overlapping - i1 is left-most
            else
            {
               if (alpha>0)
                  target.push_back( AlphaRun(i0->mX0, i1->mX1, alpha) );
               i0++;
            }
         }
      }
   }

   mLines.swap(lines);
   mMinY = min_y;
   mMaxY = max_y;
}



MaskObject *MaskObject::Create()
{
   return new PolygonMask;
}
