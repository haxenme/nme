#include "RenderPolygon.h"
#include "AA.h"
#include "QuickVec.h"
#include <map>




// Find y-extent of object, this is in pixels, and is the intersection
//  with the screen y-extent.
bool FindObjectYExtent(int &ioMinY, int &ioMaxY,int inN,
          const PointF16 *inPoints,const PolyLine *inLines);




typedef QuickVec<int> IQuickSet;





struct Span
{
   inline Span() {}
   inline Span(int inX0,int inX1) : mX0(inX0), mX1(inX1) { }
   inline void Set(int inX0,int inX1) { mX0 = inX0; mX1 = inX1; }

   int mX0;
   int mX1;
};

typedef QuickVec<Span> SpanInfo;






// -------------------------- Build Fat Lines ----------------------------------


struct LineStart
{
   // This has the y_offset subtracted ...
   PointF16 mPos;
   // To the left, when looking down the line ..
   PointF16 mPerp;
   // Only applicable of mitre mode ...
   double mParaDX;
   double mParaDY;
};

typedef std::vector<LineStart> LineStarts;



class LineRasterizer
{
public:
   LineRasterizer(const PointF16 *inPoints,
                    const PolyLine *inLines, 
                    int inMinY, int inMaxY,
                    int inAABits,
                    SpanInfo *outSpan)
        : mSpans(outSpan), mMinY(inMinY), mMaxY(inMaxY), mAABits(inAABits)
   {
      mMinY = inMinY;
      mMaxY = inMaxY;
      mToAA = 16-mAABits;


      // For removing offset ...
      int y_offset = mMinY << 16;
      // Bottom of lines ...
      int y_max_aa = (mMaxY-mMinY) << mAABits;

      mCaps = inLines->mCaps;
      mJoints = inLines->mJoints;
      mMaxSpan = y_max_aa;

      double t = (inLines->mThickness*0.5)* 65536.0;
      int it = (int)(t + 0.5);

      // Convert hypotnuse into edge length
      if (mJoints==NME_CORNER_MITER)
      {
         mMiterLimit = inLines->mMiterLimit;
         if (mMiterLimit<=1)
            mJoints = NME_CORNER_BEVEL;
         else
            mMiterLimit = sqrt( mMiterLimit*mMiterLimit - 1.0 );
         mMiterLimit *= inLines->mThickness * 65536.0;
      }
 
      int pid0 = inLines->mPointIndex0;
      int pid1 = inLines->mPointIndex1;

      int n = pid1 - pid0 + 1;
      size_t plast = n-1;
      bool loop = n>2 && (inPoints[pid0]==inPoints[pid1]);

      LineStarts points(n);
      // Number of line segments is 1 fewer than points - so last
      //  point does not need a dx, and may have an square end.
      for(int p=0;p<n;p++)
      {
         LineStart &ap = points[p];
         ap.mPos = inPoints[pid0 + p];
         ap.mPos.y -= y_offset;
      }

      // Snap horizontal and vertical lines to be aligned with pixel grid for less blurry lines
      for(size_t p=0;p<plast;p++)
      {
         LineStart &ap = points[p];

         int dx = points[p+1].mPos.x - ap.mPos.x;
         int dy = points[p+1].mPos.y - ap.mPos.y;

         // Snap vertical line to AA grid ...
         if (dx==0)
         {
            ap.mPos.x = ((ap.mPos.x - it + 0x8000) & 0xffff0000 ) + it;
            LineStart &next = points[p+1];
            next.mPos.x = ((next.mPos.x - it + 0x8000) & 0xffff0000 ) + it;
            if (loop && p==0)
              points[plast].mPos.x = ap.mPos.x;
         }
         // Snap horizontal line to AA grid ...
         if (dy==0)
         {
            ap.mPos.y = ((ap.mPos.y - it + 0x8000) & 0xffff0000 ) + it;
            LineStart &next = points[p+1];
            next.mPos.y = ((next.mPos.y - it + 0x8000) & 0xffff0000 ) + it;
            if (loop && p==0)
               points[plast].mPos.y = ap.mPos.y;
         }
      }

      // Calculate perpendicular line for use with line widths.
      for(size_t p=0;p<plast;p++)
      {
         LineStart &ap = points[p];

         double dx = points[p+1].mPos.x - ap.mPos.x;
         double dy = points[p+1].mPos.y - ap.mPos.y;
         double norm = sqrt(dx*dx + dy*dy);

         if (mJoints==NME_CORNER_MITER || mJoints==NME_CORNER_BEVEL)
         {
            if (norm!=0)
            {
               ap.mParaDX = dx/norm;
               ap.mParaDY = dy/norm;
            }
            else
            {
               ap.mParaDX = 0;
               ap.mParaDY = 0;
            }
         }

         if (norm!=0)
            norm = t/norm;

         ap.mPerp.x = (int)(dy*norm);
         ap.mPerp.y = (int)(-dx*norm);
      }

      mCircleRad = 0;
      if ( (mCaps==NME_END_ROUND || mJoints==NME_CORNER_ROUND) )
         SetCircleRad(it);

      if (!loop)
      {
         if (mCaps==NME_END_SQUARE)
         {
            points[0].mPos.x += points[0].mPerp.y;
            points[0].mPos.y -= points[0].mPerp.x;

            points[plast].mPos.x -= points[plast-1].mPerp.y;
            points[plast].mPos.y += points[plast-1].mPerp.x;
         }
         else if (mCaps==NME_END_ROUND )
         {
            SpanCircle(points[0].mPos);
            SpanCircle(points[plast].mPos);
         }
      }
      else
      {
         points[plast] = points[0];
      }

      if (mJoints==NME_CORNER_ROUND && mCircleRad>0)
      {
         for(size_t i=loop?0:1;i<plast;i++)
            SpanCircle(points[i].mPos);
      }

      bool do_join = mJoints==NME_CORNER_BEVEL || mJoints==NME_CORNER_MITER;

      for(size_t i=0;i<plast;i++)
         DrawLineSeg( points[i], points[i+1], do_join && ( loop|| (i+1<plast)) );
   }

   bool NotSpanned(SpanInfo &span,int x0,int x1)
   {
      for(int i=0;i<span.size();i++)
      {
         Span &s = span[i];
         if (s.mX0<=x0 && s.mX1>=x1)
            return false;
      }
      return true;
   }

   bool VerifySpan(SpanInfo &ospan, SpanInfo &span,int inX0, int inX1)
   {
      for(int i=0;i<span.size()-1;i++)
         if (span[i+1].mX0 <= span[i].mX1)
         {
            *(int *)0=0;
            return false;
         }

      if (NotSpanned(span,inX0,inX1))
      {
         *(int *)0=0;
         return false;
      }

      for(int i=0;i<ospan.size();i++)
      {
         Span s = ospan[i];
         if (NotSpanned(span,s.mX0,s.mX1))
         {
            *(int *)0=0;
            return false;
         }
      }
      return true;
   }


   inline void HLine(int inY,int inX0,int inX1)
   {
      if (inY>=0 && inY<mMaxSpan)
      {
         //inX0 = inX0 >> mToAA;
         //inX1 = (inX1>>mToAA);
         if (inX0==inX1) return;
         SpanInfo &span = mSpans[inY];
         int n = (int)span.size();

         #ifdef VERIFY
         SpanInfo ospan = span;
         #endif

         if (n==0 || inX0 >span[n-1].mX1)
         {
            span.push_back(Span(inX0,inX1));
         }
         else if (inX1<span[0].mX0)
         {
            span.InsertAt(0,Span(inX0,inX1));
         }
         else
         {
            for(int i=0;i<n;i++)
            {
               Span &s = span[i];

               // touching ?
               if (inX1>=s.mX0 && inX0<=s.mX1)
               {
                  if (inX0<s.mX0)
                     s.mX0 = inX0;
                  // Covers the span - and then some ?
                  if (inX1>s.mX1)
                  {
                     int k = i+1;
                     // eat up spans in our range ...
                     while(k<n && span[k].mX0<=inX1)
                        ++k;
                     --k;
                     s.mX1 = std::max(inX1,span[k].mX1);
                     if (i!=k)
                     {
                        span.EraseAt(i+1,k+1);
                     }
                  }
                  break;
               }
               // gone past, insert before
               else if (inX0 < s.mX0)
               {
                 span.InsertAt(i,Span(inX0,inX1));
                 break;
               }
            }
         }

         #ifdef VERIFY
         if (!VerifySpan(ospan,span,inX0,inX1))
            span = ospan;
         #endif
      }
   }

   IntVec mCircleArc;
   int    mCircleRad;

   void SetCircleRad(int inRad)
   {
      inRad >>= mToAA;
      if (inRad<1)
      {
         mCircleRad = 0;
         return;
      }
      mCircleRad = inRad;
      int n = 2*mCircleRad+1;
      mCircleArc.resize(n);
      for(int y=0;y<=mCircleRad;y++)
      {
         double yr = mCircleRad-y;
         double r =  inRad;
         int dx = (int)( sqrt(r*r - yr*yr ) );
         mCircleArc[y] = dx;
         mCircleArc[n-1-y] = dx;
      }
   }

   void SpanCircle(PointF16 inPos)
   {
      if (mCircleRad>0)
      {
         int x = inPos.X(mAABits);
         int y = inPos.Y(mAABits);
         int *ptr = &mCircleArc[mCircleRad];
         for(int i=-mCircleRad;i<mCircleRad;i++)
            HLine(i + y, x-ptr[i], x+ptr[i] );
      }
   }


   // finds D16-bit X/ D AA bit Y
   inline int Grad(PointF16 inVec)
   {
      int denom = inVec.y;
      if (inVec.y==0)
         return 0;
      int64 num = inVec.x;
      num<<=mToAA;
      return (int)(num/denom);
   }



   /*


       |     +0      |
     dy0    / \  xb  |      top triangle
       |   /   \     dy1
         1+.....\    |
     |      \    \   |      bottom triangle
     |         \  \  |     
    dy2  xa      \+2
     |        

   */


   // In this case, numbers have already been converted to aa coordinates
   void SpanTriangle(PointF16 inP0,PointF16 inP1, PointF16 inP2)
   {
      // Sort
      if (inP2.y<inP1.y)
          std::swap(inP1,inP2);
      if (inP1.y<inP0.y)
          std::swap(inP0,inP1);
      if (inP2.y<inP1.y)
          std::swap(inP1,inP2);

      int y0 = inP0.Y(mAABits);
      int y1 = inP1.Y(mAABits);
      int y2 = inP2.Y(mAABits);

      if (y2==y0) return;

      int dxa_dy0 = Grad(inP1-inP0);
      int dxa_dy2 = Grad(inP2-inP1);
      int dxb_dy1 = Grad(inP2-inP0);

      // F16 fractional row ...
      int y = y0;
      int extra_y = (((y+1)<<mToAA)-inP0.y)>>8;
      int xa = inP0.x + (dxa_dy0>>(mToAA-8)) * extra_y;
      int xb = inP0.x + (dxb_dy1>>(mToAA-8)) * extra_y;

      // Top triangle ...
      while(y<y1)
      {
         if (xa<xb)
            HLine(y,xa>>mToAA,xb>>mToAA);
         else
            HLine(y,xb>>mToAA,xa>>mToAA);
         xa+=dxa_dy0;
         xb+=dxb_dy1;
         y++;
      }

      // middle bit
      extra_y = (((y+1)<<mToAA)-inP1.y)>>8;
      xa = inP1.x + (dxa_dy2>>(mToAA-8)) * extra_y;
      while(y<y2)
      {
         if (xa<xb)
            HLine(y,xa>>mToAA,xb>>mToAA);
         else
            HLine(y,xb>>mToAA,xa>>mToAA);
         xa+=dxa_dy2;
         xb+=dxb_dy1;
         y++;
      }

   }


   /*
       |     +0      |
     dy0    / \  xb  |      top triangle
       |   /   \     dy1
         1+.....\    |
     |     \     \   |      middle parallelogram
    dy2  xa \.....+2
     |       \   / |        bottom triangle
     |        \ /  dy3
     |        3+   |

   */

   void SpanQuad(PointF16 inP0, PointF16 inP1, PointF16 inP2, PointF16 inP3)
   {
      int y0 = inP0.Y(mAABits);
      int y1 = inP1.Y(mAABits);
      int y2 = inP2.Y(mAABits);
      int y3 = inP3.Y(mAABits);

      if (y3==y0) return;

      int dxa_dy0 = Grad(inP1-inP0);
      int dxa_dy2 = Grad(inP3-inP1);
      int dxb_dy1 = Grad(inP2-inP0);

      // F16 fractional row ...
      int y = y0;
      int extra_y = (((y+1)<<mToAA)-inP0.y)>>8;
      int xa = inP0.x + (dxa_dy0>>(mToAA-8)) * extra_y;
      int xb = inP0.x + (dxb_dy1>>(mToAA-8)) * extra_y;

      // Top triangle ...
      while(y<y1)
      {
         if (xa<xb)
            HLine(y,xa>>mToAA,xb>>mToAA);
         else
            HLine(y,xb>>mToAA,xa>>mToAA);
         xa+=dxa_dy0;
         xb+=dxb_dy1;
         y++;
      }

      // middle bit
      extra_y = (((y+1)<<mToAA)-inP1.y)>>8;
      xa = inP1.x + (dxa_dy2>>(mToAA-8)) * extra_y;
      while(y<y2)
      {
         if (xa<xb)
            HLine(y,xa>>mToAA,xb>>mToAA);
         else
            HLine(y,xb>>mToAA,xa>>mToAA);
         xa+=dxa_dy2;
         xb+=dxb_dy1;
         y++;
      }

      // last bit ...
      if (y<=y3)
      {
         int dxb_dy3 = Grad(inP3-inP2);
         extra_y = ((y+1)<<mToAA) - inP2.y;
         xb = inP2.x + (dxb_dy3>>(mToAA-8)) * (extra_y>>8);

         while(y<y3)
         {
            if (xa<xb)
               HLine(y,xa>>mToAA,xb>>mToAA);
            else
               HLine(y,xb>>mToAA,xa>>mToAA);
            xa+=dxa_dy2;
            xb+=dxb_dy3;
            y++;
         }
      }
   }

   void SpanAlignRectRectangle(int inX0,int inY0,int inX1,int inY1)
   {
      int x0 = inX0>>mToAA;
      int y0 = inY0>>mToAA;
      int x1 = inX1>>mToAA;
      int y1 = inY1>>mToAA;
      for(int y=y0;y<y1;y++)
         HLine(y,x0,x1);
   }


   /*

            *
     adx,ady \
               * x0,y0
              /
             /
            /
           /
          * x1,y1


   */

   // Quantities are 16-bit fixed, with y-min removed.
   void DrawLineSeg(LineStart &inP0,const LineStart &inP1,bool inJoin)
   {
      // Draw rectangle, is possible
      if (inP0.mPos.Y(mAABits) == inP1.mPos.Y(mAABits))
      {
         if (inP0.mPos.x<inP1.mPos.x)
            SpanAlignRectRectangle(inP0.mPos.x,inP0.mPos.y+inP0.mPerp.y,
                                   inP1.mPos.x,inP0.mPos.y-inP0.mPerp.y );
         else
            SpanAlignRectRectangle(inP1.mPos.x,inP0.mPos.y-inP0.mPerp.y,
                                   inP0.mPos.x,inP0.mPos.y+inP0.mPerp.y );
      }
      else if (inP0.mPos.X(mAABits) == inP1.mPos.X(mAABits))
      {
         if (inP0.mPos.y<inP1.mPos.y)
            SpanAlignRectRectangle(inP0.mPos.x-inP0.mPerp.x,inP0.mPos.y,
                                   inP0.mPos.x+inP0.mPerp.x,inP1.mPos.y );
         else
            SpanAlignRectRectangle(inP0.mPos.x+inP0.mPerp.x,inP1.mPos.y,
                                   inP0.mPos.x-inP0.mPerp.x,inP0.mPos.y );
      }
      else
      {
         PointF16 p0;
         PointF16 p1;

         if (inP0.mPos.y<inP1.mPos.y)
         {
            p0 = inP0.mPos;
            p1 = inP1.mPos;
         }
         else
         {
            p0 = inP1.mPos;
            p1 = inP0.mPos;
         }
         PointF16 perp = inP0.mPerp;
         if (perp.y>0)
         {
            perp.y*=-1;
            perp.x*=-1;
         }

         PointF16 c0 = p0 + perp;
         PointF16 c1 = p0 - perp;
         PointF16 c2 = p1 + perp;
         PointF16 c3 = p1 - perp;
         if (c1.y<c2.y)
            SpanQuad(c0,c1,c2,c3);
         else
            SpanQuad(c0,c2,c1,c3);
      }

      if (inJoin)
      {
         // Find out angle between lines - our (anti-clockwise)perpendicular to
         // the next ones axis...
         double dot = inP0.mPerp.x*inP1.mParaDX+ inP0.mPerp.y*inP1.mParaDY;
         if (dot==0.0 && (mJoints!=NME_CORNER_MITER || // check 180 deg case...
                 inP0.mPerp.x*inP1.mPerp.x + inP0.mPerp.y*inP1.mPerp.y >0 ) )
            return;

         PointF16 c0 = inP1.mPos;
         PointF16 c1,c2;
         if (dot>0)
         {
            c1 = c0 - inP0.mPerp;
            c2 = c0 - inP1.mPerp;
         }
         else
         {
            c1 = c0 + inP0.mPerp;
            c2 = c0 + inP1.mPerp;
         }


         SpanTriangle(c0,c1,c2);

         if (mJoints==NME_CORNER_MITER)
         {
             // Intersect ray from c1 + alpha*(P0.para) ==
             //                    c2 - alpha*(P1.para)
             //  c1.x + a * inP0.mParaDX = c2.x - a*inP1.mParaDX
             //    OR
             //  c1.y + a * inP0.mParaDY = c2.y - a*inP1.mParaDY
             // whichever is better conditioned.

             double a;
             if (dot==0)
                a = mMiterLimit;
             else
             {
                double denom_x = (inP0.mParaDX+inP1.mParaDX);
                double denom_y = (inP0.mParaDY+inP1.mParaDY);
                if (fabs(denom_x)>fabs(denom_y))
                   a = (c2.x-c1.x)/denom_x;
                else
                   a = (c2.y-c1.y)/denom_y;
                if (a>mMiterLimit)
                   a = mMiterLimit;
             }

             PointF16 c1a;
             c1a.x = c1.x + (int)(a*inP0.mParaDX);
             c1a.y = c1.y + (int)(a*inP0.mParaDY);
             SpanTriangle(c1,c2,c1a);

             if (a==mMiterLimit)
             {
                PointF16 c2a;
                c2a.x = c2.x - (int)(a*inP1.mParaDX);
                c2a.y = c2.y - (int)(a*inP1.mParaDY);
                SpanTriangle(c2,c1a,c2a);
             }
         }
      }
   }


   Uint32   mCaps;
   Uint32   mJoints;

   int      mPrevADX,mPrevADY;
   double   mPrevDX, mPrevDY;
   double   mMiterLimit;

   SpanInfo *mSpans;
   int      mMaxSpan;
   int      mMinY;
   int      mMaxY;
   int      mAABits;
   int      mToAA;
};


template<int BITS>
struct SpanIterator
{
   enum { Size = (1<<BITS) };
   enum { Mask = ~((1<<BITS) - 1) };

   SpanIterator(SpanInfo &inSpanInfo,int &outXMin, int &ioTotalElems)
   {
      ioTotalElems += (int)inSpanInfo.size();
      if (!inSpanInfo.empty())
      {
         mPtr = &inSpanInfo[0];
         mEnd = mPtr + inSpanInfo.size();

         int x = mPtr->mX0 & Mask;
         if (x<outXMin) outXMin = x;
      }
      else
         mEnd = mPtr = 0;
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
            Span &next = mPtr[1];
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

   Span *mPtr;
   Span *mEnd;
};


void ConvertSpansToAlpha4(SpanInfo *inSpans, AlphaRuns &outLine)
{
   int size = 0;
   int xmax = 0x80000;
   int x = xmax;
   SpanIterator<2> s0(inSpans[0],x,size);
   SpanIterator<2> s1(inSpans[1],x,size);
   SpanIterator<2> s2(inSpans[2],x,size);
   SpanIterator<2> s3(inSpans[3],x,size);

   outLine.reserve(size);

   while(x<xmax)
   {
      int next_x = xmax;
      int alpha = s0.SetX(x,next_x) + s1.SetX(x,next_x) + s2.SetX(x,next_x) + s3.SetX(x,next_x);
      if (next_x == xmax)
         break;
      if (alpha>0)
         outLine.push_back( AlphaRun(x>>2,next_x>>2,alpha*255/16) );
      x = next_x;
   }
}


void ConvertSpansToAlpha1(const SpanInfo &inSpans, AlphaRuns &outLine)
{
   int n = (int)inSpans.size();
   outLine.resize(inSpans.size());
   for(int i=0;i<n;i++)
   {
      const Span &s = inSpans[i];
      outLine[i].Set(s.mX0, s.mX1, 255 );
   }
}





class SolidRasterizer
{
   // finds D16-bit X/ D AA bit Y
   inline int Grad(PointF16 inVec,int inToAA)
   {
      int denom = inVec.y;
      if (inVec.y==0)
         return 0;
      int64 num = inVec.x;
      num<<=inToAA;
      return (int)(num/denom);
   }



public:
   SolidRasterizer(int inAABits,const RenderArgs &inArgs, int inMinY, int inMaxY, Lines &outLines)
   {
      // For removing offset ...
      int y_offset = inMinY << 16;
      // Bottom of lines ...
      int y_max_aa = (inMaxY-inMinY) << inAABits;
      int y_max_val = (inMaxY-inMinY) << 16;

      int n = inArgs.inN;
      PointF16 p0(inArgs.inPoints[0]);
      p0.y -= y_offset;

      int to_aa = 16-inAABits;

      int line_count = (int)outLines.size();
      IQuickSet *line_info = new IQuickSet[ line_count << inAABits ];

      for(int i=1;i<n;i++)
      {
         PointF16 p1(inArgs.inPoints[i]);
         p1.y -= y_offset;
         PointF16 p_next = p1;

         // clip whole line ?
         if ( (inArgs.inConnect[i]!=0) &&
           (!(p0.y<0 && p1.y<0) && !(p0.y>=y_max_val && p1.y>=y_max_val)))
         {
            int y0 = p0.y>>to_aa;
            int y1 = p1.y>>to_aa;
            int dy = y1-y0;
            if (dy==0)
            {
               // No need to do anything..
            }
            else
            {
               if (dy<0)
               {
                  std::swap(p0,p1);
                  std::swap(y0,y1);
               }

               int dx_dy = Grad(p1 - p0,to_aa);
               int extra_y = ((y0+1)<<to_aa) - p0.y;
               int x = p0.x + (dx_dy>>(to_aa-8)) * (extra_y>>8);

               if (y0<0)
               {
                  x-= y0 * dx_dy;
                  y0 = 0;
               }
               int last = y1>y_max_aa ? y_max_aa : y1;

               for(; y0<last; y0++)
               {
                  #ifdef VERIFY
                  IQuickSet oset = line_info[y0];
                  #endif

                  // X is fixed-16, y is fixed-aa
                  line_info[y0].Toggle(x>>to_aa);

                  #ifdef VERIFY
                  if (!VerifyOrder(line_info[y0]))
                  {
                     printf("Inset %d into ",x>>to_aa);
                     for(int i=0;i<oset.size();i++)
                        printf("%d ",oset[i]);
                     printf("\n");
                     oset.Toggle(x>>to_aa);
                  }
                  #endif

                  x+=dx_dy; 
               }
            }
         }
         p0 = p_next;
      }

      if (inAABits<2)
      {
         for(int y=0;y<line_count;y++)
         {
            AlphaRuns &alphas = outLines[y];

            IQuickSet &points = line_info[y];
            int n = points.size()/2;
            alphas.resize(n);

            for(int p=0;p<n;p++)
               alphas[p].Set( points[p*2], points[p*2+1], 255 );
         }
      }
      else
      {
         // line_info now contains information about the alpha runs - convert them...
         SpanInfo spans[4];
         for(int y=0;y<line_count;y++)
         {
            // Convert points representing start and stop points to spans with begin/end...
            for(int a=0;a<4;a++)
            {
               IQuickSet &points = line_info[y*4 + a];
               int n = points.size()/2;
               SpanInfo &span = spans[a];
               span.resize(n);
               for(int p=0;p<n;p++)
                  span[p].Set( points[p*2], points[p*2+1] );
            }

            ConvertSpansToAlpha4(&spans[0], outLines[y]);
         }
      }

      delete [] line_info;
   }

   bool VerifyOrder(IQuickSet &inSet)
   {
      for(int i=1;i<inSet.size();i++)
         if (inSet[i]<=inSet[i-1])
            return false;
      return true;
   }
};




// ---------   BasePolygonRenderer   -----------------------------------------


BasePolygonRenderer::BasePolygonRenderer(const RenderArgs &inArgs)
{
   mMinY = inArgs.inMinY;
   mMaxY = inArgs.inMaxY;
   int aa_bits = 0;
   
   if (inArgs.inFlags & NME_HIGH_QUALITY)
   {
      aa_bits = 2;
      AA4x::Init();
   }

   if (FindObjectYExtent(mMinY,mMaxY,inArgs.inN,inArgs.inPoints,inArgs.inLines))
   {
      int line_count = mMaxY - mMinY;
      mLines.resize( line_count );

      // Draw line or solid ?
      if (inArgs.inLines)
      {
         // Bottom of lines ...
         int y_max_aa = (mMaxY-mMinY) << aa_bits;
         SpanInfo *spans = new SpanInfo[y_max_aa];

         LineRasterizer rasterer(inArgs.inPoints,inArgs.inLines,mMinY,mMaxY,aa_bits,spans);

         // Convert spans to alpha_runs ....
         for(int y=mMinY;y<mMaxY;y++)
         {
            int y0 = (y-mMinY);
            if (aa_bits==2)
               ConvertSpansToAlpha4(spans + (y0<<2), mLines[y0]);
            else
               ConvertSpansToAlpha1(spans[y0], mLines[y0]);
         }

         delete [] spans;
      }
      else
      {
         SolidRasterizer solid(aa_bits,inArgs,mMinY,mMaxY,mLines);
      }
   }
}


bool BasePolygonRenderer::HitTest(int inX,int inY)
{
   if (mMinY<=inY && mMaxY>inY)
   {
      AlphaRuns &line = mLines[inY-mMinY];
      int s1 = ((int)line.size())-1;
      if (s1<0)
         return false;
      if (s1==0)
         return line[0].Contains(inX);
      if (inX>=line[s1].mX0)
         return inX < line[s1].mX1;
      if (inX < line[0].mX0)
         return false;

      // Ok, somewhere between s0 and s1 ...
      int s0 = 0;
      while(s0+1<s1)
      {
         int t = (s0+s1)/2;
         if (line[t].mX0 < inX)
            s0 = t;
         else
            s1 = t;
      }

      return inX < line[s0].mX1;
   }
   return false;
}

