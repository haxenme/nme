#include "RenderPolygon.h"



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
      int it = (int)t;

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
      bool loop = n>2 && (inPoints[pid0]==inPoints[pid0 + plast]);


      LineStarts points(n);
      // Number of line segments is 1 fewer than points - so last
      //  point does not need a dx, and may have an square end.
      LineStart &end = points[plast];
      end.mPos = inPoints[pid0 + plast];
      end.mPos.y -= y_offset;

      for(size_t p=0;p<plast;p++)
      {
         LineStart &ap = points[p];
         ap.mPos = inPoints[pid0 + p];
         ap.mPos.y -= y_offset;

         double dx = inPoints[pid0 + p+1].x - inPoints[pid0 + p].x;
         double dy = inPoints[pid0 + p+1].y - inPoints[pid0 + p].y;
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
         points[plast] = points[0];

      if (mJoints==NME_CORNER_ROUND && mCircleRad>0)
      {
         for(size_t i=loop?0:1;i<plast;i++)
            SpanCircle(points[i].mPos);
      }

      bool do_join = mJoints==NME_CORNER_BEVEL || mJoints==NME_CORNER_MITER;

      for(size_t i=0;i<plast;i++)
         DrawLineSeg( points[i], points[i+1], do_join && (loop||i+1<plast) );
   }


   inline void HLine(int inY,int inX0,int inX1)
   {
      if (inY>=0 && inY<mMaxSpan)
      {

         //inX0 = inX0 >> mToAA;
         //inX1 = (inX1>>mToAA);
         if (inX0==inX1) return;
         SpanInfo &span = mSpans[inY];

         /*
         printf("Inserting (%d,%d) into : ", inX0,inX1);
         for(SpanInfo::iterator i=span.begin();i!=span.end();++i)
            printf("%d%c ", i->first,i->second ? '*' : ' ');
         printf("\n");
         */

         // find element greater than, or equal to inX0 ...
         SpanInfo::iterator i = span.lower_bound(inX0);
         // insert span at end ...
         if (i==span.end())
         {
            span[inX0] = true;
            span[inX1] = false;
         }
         else
         {
            if (i->first == inX0)
            {
               // Previous range finished at this point - delete the ending
               if (!i->second)
               {
                  SpanInfo::iterator p = i;
                  --p;
                  span.erase(i);
                  i = p;
               }
               // Previous range starts here too - do nothing
            }
            else if (i==span.begin())
            {
               // insert new bit at beginning
               span[inX0] = true;
               i = span.begin();
            }
            else
            {
               SpanInfo::iterator prev = i;
               --prev;
               if (!prev->second)
                  i = span.insert( span.end(), std::make_pair(inX0,true) );
               else
                  i = prev;
            }

            // find element greater than, or equal to inX1 ...
            SpanInfo::iterator end = span.lower_bound(inX1);

            if (end==span.end())
            {
               ++i;
               span.erase(i,end);
               span[inX1] = false;
            }
            else if (end->first == inX1)
            {
               // Delete the last on
               if (end->second)
                  end++;
               // otherwise, already in place..
               ++i;
               span.erase(i,end);
            }
            else
            {
               SpanInfo::iterator prev = end;
               --prev;
               if (prev==i)
               {
                  if (end->second)
                     span[inX1] = false;
               }
               else if (prev->second)
               {
                  ++i;
                  span.erase(i,end);
               }
               else
               {
                  ++i;
                  span.erase(i,end);
                  span[inX1] = false;
               }
            }
         }

         /*
         printf("GOT  :");
         for(SpanInfo::iterator i=span.begin();i!=span.end();++i)
            printf("%d%c ", i->first,i->second ? '*' : ' ');
         printf("\n");
         */


         // if (span.size() & 1) *(int *)0=0;
      }
   }

   IntVec mCircleArc;
   int    mCircleRad;

   void SetCircleRad(int inRad)
   {
      inRad >>= mToAA;
      if (inRad<2)
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
      if (inP0.mPos.X(mAABits) == inP1.mPos.X(mAABits))
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



void RasterizeLines(const PointF16 *inPoints,
                    const PolyLine *inLines, 
                    int inMinY, int inMaxY,
                    int inAABits,
                    SpanInfo *outSpans)
{
   LineRasterizer rasterer(inPoints,inLines,inMinY,inMaxY,inAABits,outSpans);
}


