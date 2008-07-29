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


void TranslateLine(AlphaRuns &ioLine,int inTX)
{
   for(int x=0;x<ioLine.size();x++)
   {
      AlphaRun &a = ioLine[x];
      a.mX0 += inTX;
      a.mX1 += inTX;
   }

}

void Verify(const AlphaRuns &inLine)
{
   for(int x=1;x<inLine.size();x++)
   {
      const AlphaRun &a0 = inLine[x-1];
      const AlphaRun &a1 = inLine[x];
      if (a0.mX0 >= a0.mX1) *(int *)0=0;
      if (a1.mX0 >= a1.mX1) *(int *)0=0;
      if (a0.mX1>a1.mX0) *(int *)0=0;
   }

}


void PolygonMask::Translate(int inTX,int inTY)
{
   mMinY += inTY;
   mMaxY += inTY;
   if (inTX!=0)
   {
      for(size_t y=0;y<mLines.size();y++)
         TranslateLine(mLines[y],inTX);
   }

   if (mExtent.Valid())
      mExtent.Translate(inTX,inTY);
   mID = sMaskID++;
}

inline void PushRun(AlphaRuns &ioRuns, const AlphaRun &inRun)
{
   if (ioRuns.size())
   {
      AlphaRun &last = ioRuns[ ioRuns.size()-1 ];
      if (last.mX1==inRun.mX0 && abs(last.mAlpha-inRun.mAlpha)<3)
      {
         last.mX1 = inRun.mX1;
         return;
      }
   }
   ioRuns.push_back(inRun);
}


void PolygonMask::Add(const PolygonMask &inMask,int inTX,int inTY)
{
   // Nothing there yet?
   if (mMinY>=mMaxY)
   {
      mMinY = inMask.mMinY;
      mMaxY = inMask.mMaxY;
      mLines = inMask.mLines;
      Translate(inTX,inTY);
   }
   // Merge ...
   else
   {
      int min_y = std::min(inMask.mMinY+inTY,mMinY);
      int max_y = std::max(inMask.mMaxY+inTY,mMaxY);
      int n = max_y - min_y;
      Lines lines(n);

      const Lines lines0 = inMask.mLines;
      for(int i=0;i<n;i++)
      {
         int y = i+min_y;
         int untrans_y = y-inTY;
         bool in_me = y>=mMinY && y<mMaxY;
         bool in_mask = untrans_y>=inMask.mMinY && untrans_y<inMask.mMaxY;

         if (in_me && !in_mask)
            lines[i].swap( mLines[y-mMinY] );
         else if (in_mask && !in_me)
         {
            lines[i] = lines0[untrans_y-inMask.mMinY];
            TranslateLine(lines[i],inTX);
         }
         else if (!in_mask && !in_me)
            ; // nothing to do
         else
         {
            // TODO: arrrrrrghhhhhh
            const AlphaRuns &l0 = lines0[untrans_y-inMask.mMinY];
            const AlphaRuns &l1 = mLines[y-mMinY];
            AlphaRuns::const_iterator i0 = l0.begin();
            AlphaRuns::const_iterator i1 = l1.begin();
            AlphaRuns &target = lines[i];

            if (l0.empty())
            {
               target = l1;
               continue;
            }
            if (l1.empty())
            {
               target = l0;
               TranslateLine(target,inTX);
               continue;
            }

            int x=std::min(i0->mX0+inTX, (int)i1->mX0);

            while(1)
            {
               AlphaRun t0 = *i0;
               t0.mX0 += inTX;
               t0.mX1 += inTX;
               if (t0.mX0<x) t0.mX0 = x;
               AlphaRun t1 = *i1;
               if (t1.mX0<x) t1.mX0 = x;

               // Overlap ...
               if (t0.mX0 == x && t1.mX0 == x)
               {
                  int alpha = 255 - (( (255-t0.mAlpha) * (255-t1.mAlpha) ) >> 8);
                  if (t0.mX1 < t1.mX1)
                  {
                     PushRun(target,AlphaRun(x, t0.mX1, alpha ));
                     i0++;
                     if (i0==l0.end())
                     {
                        x = t0.mX1;
                        break;
                     }
                     x=std::min(i0->mX0+inTX, (int)t1.mX1);
                  }
                  else if (t0.mX1 > t1.mX1)
                  {
                     PushRun(target, AlphaRun(x, t1.mX1, alpha ));
                     i1++;
                     if (i1==l1.end())
                     {
                        x = t1.mX1;
                        break;
                     }
                     x=std::min(t0.mX1, i1->mX0);
                  }
                  // both end at same time
                  else
                  {
                     PushRun( target, AlphaRun(x, t1.mX1, alpha) );
                     i0++;
                     i1++;
                        if (i0==l0.end() || i1==l1.end())
                        break;
                     x = std::min( i0->mX0+inTX, (int)i1->mX0 );
                  }
               }
               // continue with t0, until it ends or t1 starts
               else if (t1.mX0>x)
               {
                  // Last bit of t0
                  if (t1.mX0>=t0.mX1)
                  {
                     PushRun( target, AlphaRun(x, t0.mX1, t0.mAlpha ));
                     i0++;
                     if (i0==l0.end()) break;
                     x = std::min( i0->mX0+inTX, (int)i1->mX0 );
                  }
                  // Last bit of t0 intil t1 starts
                  else
                  {
                     PushRun(target, AlphaRun(x, t1.mX0, t0.mAlpha) );
                     x = t1.mX0;
                  }
               }
               // continue with t1, until it ends or t0 starts
               else
               {
                  // Last bit of t1
                  if (t0.mX0>=t1.mX1)
                  {
                     PushRun(target, AlphaRun(x, t1.mX1, t1.mAlpha) );
                     i1++;
                     if (i1==l1.end()) break;
                     x = std::min( t0.mX0, i1->mX0 );
                  }
                  // Last bit of t1 intil t0 starts
                  else
                  {
                     PushRun(target, AlphaRun(x, t0.mX0, t1.mAlpha) );
                     x = t0.mX0;
                  }
               }
            }

            // Gobble up the end of the line ...
            if (i0==l0.end())
            {
               PushRun(target, AlphaRun(x, i1->mX1, i1->mAlpha) );
               i1++;
               while(i1!=l1.end())
                  PushRun(target,*i1++);
            }
            else if (i1==l1.end())
            {
               PushRun(target, AlphaRun(x, i0->mX1+inTX, i0->mAlpha) );
               i0++;
               while(i0!=l0.end())
               {
                  const AlphaRun &a = *i0++;
                  PushRun(target, AlphaRun(a.mX0+inTX, a.mX1+inTX, a.mAlpha) );
               }
            }
         }
         //Verify(lines[i]);
      }

      mLines.swap(lines);
      mMinY = min_y;
      mMaxY = max_y;
      mExtent = Extent2DI();
   }

   #ifdef VERIFY
   Extent2DI ex;
   GetExtent(ex);
   for(int i=0;i<mLines.size();i++)
   {
      Verify(mLines[i]);
      if (mLines[i].size() && mLines[i][0].mX0 < ex.mMinX)
         *(int *)0=0;
   }
   #endif
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
