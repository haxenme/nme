#include "Pixel.h"
#include "Gradient.h"
#include <math.h>
#include <algorithm>
#include <map>

#ifdef WIN32
typedef __int64 int64;
#else
typedef long long int64;
#endif


// --- AA traits classes ----------------------------------------------------

// The AA structures allow for the same code to be used for high-quality
//  and fast rendering.

struct AA0x
{
   enum { AlphaBits = 0 };
   enum { AABits = 0 };
   enum { AA = (1<<AABits) };

   typedef Uint8 State;
   static void InitState(State &outState)
      { outState = 0; }

   inline AA0x() : mVal(0) { }

   Uint8   mVal;

   void Debug() {}
   static inline int GetDVal(State &inState) { return 0; }

   static inline Uint8 SGetAlpha(State &inState)
      { return inState; }

   static inline Uint8 GetAlpha(State &inState)
      { return inState ^ 0x01; }

   int Value() const { return mVal; }

   inline void Transition(Uint8 &ioDrawing) const
   {
      ioDrawing ^=  mVal;
   }
   inline void Add(int inX,int inY)
   {
      mVal ^= 0x01;
   }
   inline void AddAA(int inX,int inY)
   {
      mVal ^= 0x01;
   }


};





struct AA4x
{
   enum { AlphaBits = 5 };
   enum { AABits = 2 };
   enum { AA = (1<<AABits) };
   typedef Uint8 State[4];

   inline AA4x() : mVal(0) { }

   union
   {
      Uint8 mPoints[4];
      int   mVal;
   };

   static void InitState(State &outState)
      { outState[0] = outState[1] = outState[2] = outState[3] = 0; }

   // This gets the value for alpha at at transition point
   inline Uint8 GetAlpha(Uint8 *inState) const // 5-bits fixed, [0,32] inclusive
   {
      return mAlpha[inState[0] | mPoints[0]] + 
             mAlpha[inState[1] | mPoints[1]] + 
             mAlpha[inState[2] | mPoints[2]] + 
             mAlpha[inState[3] | mPoints[3]];
   }
   inline int Value() const
   {
      return (mPoints[0]<< 12 ) |
             (mPoints[1]<< 8 ) |
             (mPoints[2]<< 4 ) |
             (mPoints[3]<< 0 );
   }

   static inline int GetDVal(State &inState)
   {
      return ( (inState[0]>>4) << 12) +
             ( (inState[1]>>4) << 8) +
             ( (inState[2]>>4) << 4) +
             ( (inState[3]>>4) << 0);
   }

   // This gets the value for alpha, which is constant for a given state
   //  (ie, no transotions going on at these points)

   static inline Uint8 SGetAlpha(Uint8 *inState)
   {
      return (inState[0] + inState[1] + inState[2] + inState[3]) >> 1;
   }
   void Debug() { printf("<%x%x%x%x>", mPoints[0], mPoints[1], mPoints[2], mPoints[3]); }

   inline void Transition(Uint8 *ioDrawing) const
   {
      ioDrawing[0] = mDrawing[ioDrawing[0] | mPoints[0]];
      ioDrawing[1] = mDrawing[ioDrawing[1] | mPoints[1]];
      ioDrawing[2] = mDrawing[ioDrawing[2] | mPoints[2]];
      ioDrawing[3] = mDrawing[ioDrawing[3] | mPoints[3]];
   }
   // x is fixed-16, y is fixed-aa
   inline void Add(int inX,int inY)
   {
      mPoints[inY & 0x03] ^= (1 << ( (inX>>14) & 0x03));
   }

   // x is fixed-aa, y is fixed-aa
   inline void AddAA(int inX,int inY)
   {
      mPoints[inY & 0x03] ^= (1 << ( inX & 0x03));
   }


   static void Init()
   {
      static bool init = false;
      if (!init)
      {
         init = true;
         for(int i=0;i<32;i++)
         {
            int  sum = 0;
            bool draw = (i&0x10) != 0;
            if (i&0x01) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x02) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x04) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x08) draw = !draw;
            if (draw) sum+= 2;

            mDrawing[i] = draw ? 0x10 : 0;
            mAlpha[i] = sum; // 3-bit fixed, [0,8] inclusive
         }
      }
   }
   static bool   mIsInit;
   static Uint8  mDrawing[32];
   static Uint8  mAlpha[32];
};

Uint8  AA4x::mDrawing[32];
Uint8  AA4x::mAlpha[32];




// --- Polygons ---------------------------------------------


template<typename LINE_,typename SOURCE_,typename DEST_>
void TProcessLines(DEST_ &outDest,int inYMin,int inYMax,LINE_ *inLines,
              SOURCE_ &inSource )
{
   if (!inLines)
      return;
   typedef typename LINE_::mapped_type Point;
   typedef typename Point::State State;

   for(int y=inYMin; y<inYMax; y++)
   {
      LINE_ &line = inLines[y-inYMin];
      if(line.size()>1)
      {
         typename LINE_::iterator i = line.begin();

         State  drawing;
         Point::InitState(drawing);

         while(1)
         {
            int x = i->first;
            if (x>=outDest.mMaxX)
               break;

            // Setup iterators ...
            outDest.SetPos(x,y);
            inSource.SetPos(x,y);

            Uint8 alpha = i->second.GetAlpha(drawing);

            if (x>=outDest.mMinX)
            {
               // Plot this point ...
               if (alpha==(1<<Point::AlphaBits))
                  outDest.SetInc(inSource);
               else if (alpha)
               #ifdef WIN32
                  outDest.SetIncBlend<Point::AlphaBits>(inSource,alpha);
               #else
                  outDest.SetIncBlend(inSource,alpha,(int)Point::AlphaBits);
               #endif
               inSource.Inc();
               x++;
            }

            i->second.Transition(drawing);
            typename LINE_::iterator next = i;
            ++next;
            if (next==line.end())
               break;


            int x1 = next->first;
            if (x1>x)
            {
               if (x1>outDest.mMinX)
               {
                  Uint8 alpha = Point::SGetAlpha(drawing);

                  if (x<outDest.mMinX)
                  {
                     inSource.Advance(outDest.mMinX-x);
                     outDest.Advance(outDest.mMinX-x);
                     x = outDest.mMinX;
                  }
      
                  if (alpha==0)
                  {
                     inSource.Advance(x1-x);
                     outDest.Advance(x1-x);
                  }
                  else
                  {
                     if (x1>outDest.mMaxX) x1 = outDest.mMaxX;
                     if (alpha==(1<<Point::AlphaBits))
                     {
                         for(;x<x1;x++)
                         {
                            outDest.SetInc(inSource);
                            inSource.Inc();
                         }
                     }
                     else
                     {
                         for(;x<x1;x++)
                         {
                            #ifdef WIN32
                               outDest.SetIncBlend<Point::AlphaBits>(inSource,alpha);
                            #else
                               outDest.SetIncBlend(inSource,alpha,(int)Point::AlphaBits);
                            #endif

                            inSource.Inc();
                         }
                     }
                  }
               }
               else
               {
                  inSource.Advance(x1-x);
                  outDest.Advance(x1-x);
               }
            }

            i = next;
         }
      }
   }
}



// Draw polygon after it is decomposed into lines ....
template<typename LINE_,typename SOURCE_>
void ProcessLines(SDL_Surface *outDest,int inYMin,int inYMax,LINE_ *inLines,
              SOURCE_ &inSource )
{
   if ( SDL_MUSTLOCK(outDest) && _SPG_lock )
      if ( SDL_LockSurface(outDest) < 0 )
         return;


   switch(outDest->format->BytesPerPixel)
   {
      case 1:
         {
         DestSurface8 dest(outDest);
         TProcessLines( dest,inYMin,inYMax,inLines,inSource );
         break;
         }
         // TODO : 2
      case 3:
         {
         DestSurface24 dest(outDest);
         TProcessLines( dest,inYMin,inYMax,inLines,inSource );
         break;
         }
      case 4:
         {
         DestSurface32 dest(outDest);
         TProcessLines( dest,inYMin,inYMax,inLines,inSource );
         break;
         }
   }
   
   if ( SDL_MUSTLOCK(outDest) && _SPG_lock )
      SDL_UnlockSurface(outDest);
}



// Find y-extent of object, this is in pixels, and is the intersection
//  with the screen y-extent.
static bool FindObjectYExtent(int &ioMinY, int &ioMaxY,int inN,
          const PointF16 *inPoints,const PolyLine *inLines)
{
   int min_y = 0;
   int max_y = 0;

   if (inN<2)
      return false;

   if (inLines)
   {
      const IntVec &pids = inLines->mPointIndex;
      double extra = 0.5;
      if (inLines->mJoints == SPG_CORNER_MITER)
         extra += inLines->mMiterLimit;
      int w = int(inLines->mThickness*extra + 0.999);

      min_y = inPoints[pids[0]].Y();
      max_y = min_y;

      for(size_t i=1;i<pids.size();i++)
      {
         int y = inPoints[ pids[i] ].Y();
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


template<typename AA_>
class BasePolygonRenderer : public PolygonRenderer
{
public:
   enum { AABits = AA_::AABits };
   enum { ToAA = (16-AABits) };
   enum { AAMask = ~((1<<ToAA)-1) };
   enum { AAFact = 1<<AABits };

   typedef std::map<int,AA_>  LineInfo;
   typedef std::map<int,bool> SpanInfo;
   typedef AA_ Point;
   typedef typename Point::State State;


   BasePolygonRenderer(int inN,const PointF16 *inPoints,
            int inMinY,int inMaxY,const PolyLine *inLines)
   {
      mLines = 0;
      mMinY = inMinY;
      mMaxY = inMaxY;

      if (FindObjectYExtent(mMinY,mMaxY,inN,inPoints,inLines))
      {
         mLineCount = mMaxY - mMinY;
         mLines = new LineInfo [ mLineCount ];


         // Draw line or solid ?
         if (inLines)
         {
            DrawLines(inPoints,inLines);
         }
         else
         {
            // For removing offset ...
            int y_offset = mMinY << 16;
            // Bottom of lines ...
            int y_max_aa = (mMaxY-mMinY) << AABits;
            int y_max_val = (mMaxY-mMinY) << 16;

            PointF16 p0(inPoints[inN-1]);
            p0.y -= y_offset;
         
            for(int i=0;i<inN;i++)
            {
               PointF16 p1(inPoints[i]);
               p1.y -= y_offset;
               PointF16 p_next = p1;

               // clip whole line ?
               if (!(p0.y<0 && p1.y<0) && !(p0.y>=y_max_val && p1.y>=y_max_val))
               {
                  int y0 = p0.y>>ToAA;
                  int y1 = p1.y>>ToAA;
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

                     int dx_dy = Grad(p1 - p0);
                     int extra_y = ((y0+1)<<ToAA) - p0.y;
                     int x = p0.x + (dx_dy>>(ToAA-8)) * (extra_y>>8);

                     if (y0<0)
                     {
                        x-= y0 * dx_dy;
                        y0 = 0;
                     }
                     int last = y1>y_max_aa ? y_max_aa : y1;
   
                     for(; y0<last; y0++)
                     {
                        // X is fixed-16, y is fixed-aa
                        mLines[y0>>AA_::AABits][x>>16].Add(x,y0);
                        x+=dx_dy;
                     }
                  }
               }
         
               p0 = p_next;
            }
   
            // VerifyLines();
         }
      }
   }


   void DrawLines(const PointF16 *inPoints,const PolyLine *inLines)
   {
      // For removing offset ...
      int y_offset = mMinY << 16;
      // Bottom of lines ...
      int y_max_aa = (mMaxY-mMinY) << AABits;

      mCaps = inLines->mCaps;
      mJoints = inLines->mJoints;
      mMaxSpan = y_max_aa;

      double t = (inLines->mThickness*0.5)* 65536.0;
      int it = (int)t;

      // Convert hypotnuse into edge length
      if (mJoints==SPG_CORNER_MITER)
      {
         mMiterLimit = inLines->mMiterLimit;
         if (mMiterLimit<=1)
            mJoints = SPG_CORNER_BEVEL;
         else
            mMiterLimit = sqrt( mMiterLimit*mMiterLimit - 1.0 );
         mMiterLimit *= inLines->mThickness * 65536.0;
      }
 
      mSpans = new SpanInfo [ mMaxSpan ];

      const IntVec &pids = inLines->mPointIndex;
      int n = (int)pids.size();
      size_t plast = n-1;
      bool loop = n>2 && (inPoints[pids[0]]==inPoints[pids[plast]]);


      LineStarts points(n);
      // Number of line segments is 1 fewer than points - so last
      //  point does not need a dx, and may have an square end.
      LineStart &end = points[plast];
      end.mPos = inPoints[pids[plast]];
      end.mPos.y -= y_offset;

      for(size_t p=0;p<plast;p++)
      {
         LineStart &ap = points[p];
         ap.mPos = inPoints[pids[p]];
         ap.mPos.y -= y_offset;

         double dx = inPoints[pids[p+1]].x - inPoints[pids[p]].x;
         double dy = inPoints[pids[p+1]].y - inPoints[pids[p]].y;
         double norm = sqrt(dx*dx + dy*dy);

         if (mJoints==SPG_CORNER_MITER || mJoints==SPG_CORNER_BEVEL)
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
      if ( (mCaps==SPG_END_ROUND || mJoints==SPG_CORNER_ROUND) )
         SetCircleRad(it);

      if (!loop)
      {
         if (mCaps==SPG_END_SQUARE)
         {
            points[0].mPos.x += points[0].mPerp.y;
            points[0].mPos.y -= points[0].mPerp.x;

            points[plast].mPos.x -= points[plast-1].mPerp.y;
            points[plast].mPos.y += points[plast-1].mPerp.x;
         }
         else if (mCaps==SPG_END_ROUND )
         {
            SpanCircle(points[0].mPos);
            SpanCircle(points[plast].mPos);
         }
      }
      else
         points[plast] = points[0];

      if (mJoints==SPG_CORNER_ROUND && mCircleRad>0)
      {
         for(size_t i=loop?0:1;i<plast;i++)
            SpanCircle(points[i].mPos);
      }

      bool do_join = mJoints==SPG_CORNER_BEVEL || mJoints==SPG_CORNER_MITER;

      for(size_t i=0;i<plast;i++)
         DrawLineSeg( points[i], points[i+1], do_join && (loop||i+1<plast) );


      // Convert spans to lines ....
      for(int y=0;y<y_max_aa;y++)
      {
         LineInfo &line = mLines[y>>AA_::AABits];
         SpanInfo &span = mSpans[ y ];
         for(SpanInfo::iterator i=span.begin();i!=span.end();++i)
         {
            int x = i->first;
            line[x>>AA_::AABits].AddAA(x,y);
         }
      }

      delete [] mSpans;
      mSpans = 0;
   }



   void DumpLine(int inLine)
   {
         LineInfo &line = mLines[inLine];
         typename Point::State drawing;

            Point::InitState(drawing);
            for(typename LineInfo::iterator j=line.begin();j!=line.end();++j)
            {
               j->second.Transition(drawing);
               printf("  %d(%04x)", j->first,j->second.Value());
               printf("[%04x]", Point::GetDVal(drawing));
            }
            printf("\n");
   }

   void VerifyLines()
   {
      if (!mLines)
         return;

      typedef typename LineInfo::mapped_type Point;
      typedef typename Point::State State;

      
      for(int y=0; y<mLineCount; y++)
      {
         LineInfo &line = mLines[y];
         if(line.size()==0)
            continue;

         State  drawing;
         Point::InitState(drawing);

         typename LineInfo::iterator i;
         for(i=line.begin();i!=line.end();++i)
            i->second.Transition(drawing);

         if (Point::SGetAlpha(drawing)>0)
         {
            printf("Unmatched scan line : %d\n  ",y+mMinY);
            DumpLine(y);
         }
      }
   }

   inline void HLine(int inY,int inX0,int inX1)
   {
      if (inY>=0 && inY<mMaxSpan)
      {

         //inX0 = inX0 >> ToAA;
         //inX1 = (inX1>>ToAA);
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
      inRad >>= ToAA;
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
         int x = inPos.X(AABits);
         int y = inPos.Y(AABits);
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
      num<<=ToAA;
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

      int y0 = inP0.Y(AABits);
      int y1 = inP1.Y(AABits);
      int y2 = inP2.Y(AABits);

      if (y2==y0) return;

      int dxa_dy0 = Grad(inP1-inP0);
      int dxa_dy2 = Grad(inP2-inP1);
      int dxb_dy1 = Grad(inP2-inP0);

      // F16 fractional row ...
      int y = y0;
      int extra_y = (((y+1)<<ToAA)-inP0.y)>>8;
      int xa = inP0.x + (dxa_dy0>>(ToAA-8)) * extra_y;
      int xb = inP0.x + (dxb_dy1>>(ToAA-8)) * extra_y;

      // Top triangle ...
      while(y<y1)
      {
         if (xa<xb)
            HLine(y,xa>>ToAA,xb>>ToAA);
         else
            HLine(y,xb>>ToAA,xa>>ToAA);
         xa+=dxa_dy0;
         xb+=dxb_dy1;
         y++;
      }

      // middle bit
      extra_y = (((y+1)<<ToAA)-inP1.y)>>8;
      xa = inP1.x + (dxa_dy2>>(ToAA-8)) * extra_y;
      while(y<y2)
      {
         if (xa<xb)
            HLine(y,xa>>ToAA,xb>>ToAA);
         else
            HLine(y,xb>>ToAA,xa>>ToAA);
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
      int y0 = inP0.Y(AABits);
      int y1 = inP1.Y(AABits);
      int y2 = inP2.Y(AABits);
      int y3 = inP3.Y(AABits);

      if (y3==y0) return;

      int dxa_dy0 = Grad(inP1-inP0);
      int dxa_dy2 = Grad(inP3-inP1);
      int dxb_dy1 = Grad(inP2-inP0);

      // F16 fractional row ...
      int y = y0;
      int extra_y = (((y+1)<<ToAA)-inP0.y)>>8;
      int xa = inP0.x + (dxa_dy0>>(ToAA-8)) * extra_y;
      int xb = inP0.x + (dxb_dy1>>(ToAA-8)) * extra_y;

      // Top triangle ...
      while(y<y1)
      {
         if (xa<xb)
            HLine(y,xa>>ToAA,xb>>ToAA);
         else
            HLine(y,xb>>ToAA,xa>>ToAA);
         xa+=dxa_dy0;
         xb+=dxb_dy1;
         y++;
      }

      // middle bit
      extra_y = (((y+1)<<ToAA)-inP1.y)>>8;
      xa = inP1.x + (dxa_dy2>>(ToAA-8)) * extra_y;
      while(y<y2)
      {
         if (xa<xb)
            HLine(y,xa>>ToAA,xb>>ToAA);
         else
            HLine(y,xb>>ToAA,xa>>ToAA);
         xa+=dxa_dy2;
         xb+=dxb_dy1;
         y++;
      }

      // last bit ...
      if (y<=y3)
      {
         int dxb_dy3 = Grad(inP3-inP2);
         extra_y = ((y+1)<<ToAA) - inP2.y;
         xb = inP2.x + (dxb_dy3>>(ToAA-8)) * (extra_y>>8);

         while(y<y3)
         {
            if (xa<xb)
               HLine(y,xa>>ToAA,xb>>ToAA);
            else
               HLine(y,xb>>ToAA,xa>>ToAA);
            xa+=dxa_dy2;
            xb+=dxb_dy3;
            y++;
         }
      }
   }

   void SpanAlignRectRectangle(int inX0,int inY0,int inX1,int inY1)
   {
      int x0 = inX0>>ToAA;
      int y0 = inY0>>ToAA;
      int x1 = inX1>>ToAA;
      int y1 = inY1>>ToAA;
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
      if (inP0.mPos.Y(AABits) == inP1.mPos.Y(AABits))
      {
         if (inP0.mPos.x<inP1.mPos.x)
            SpanAlignRectRectangle(inP0.mPos.x,inP0.mPos.y+inP0.mPerp.y,
                                   inP1.mPos.x,inP0.mPos.y-inP0.mPerp.y );
         else
            SpanAlignRectRectangle(inP1.mPos.x,inP0.mPos.y-inP0.mPerp.y,
                                   inP0.mPos.x,inP0.mPos.y+inP0.mPerp.y );
      }
      if (inP0.mPos.X(AABits) == inP1.mPos.X(AABits))
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
         if (dot==0.0 && (mJoints!=SPG_CORNER_MITER || // check 180 deg case...
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

         if (mJoints==SPG_CORNER_MITER)
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

   bool HitTest(int inX,int inY)
   {
      if (mMinY<=inY && mMaxY>inY)
      {
         LineInfo &line = mLines[inY-mMinY];
         if(line.size()>1)
         {
            typedef typename Point::State State;

            typename LineInfo::iterator i = line.begin();

            State  drawing;
            Point::InitState(drawing);

            while(1)
            {
               int x = i->first;
               if (x>inX)
                  return false;

               Uint8 alpha = i->second.GetAlpha(drawing);
               if (x==inX)
                  return alpha>0;

               x++;

               i->second.Transition(drawing);
               typename LineInfo::iterator next = i;
               ++next;
               if (next==line.end())
                  return false;

               int x1 = next->first;
               if (x1>=inX)
                  return Point::SGetAlpha(drawing)>0;

               i = next;
            }
         }
      }
      return false;
   }


   ~BasePolygonRenderer()
   {
      delete [] mLines;
   }

   Uint32   mCaps;
   Uint32   mJoints;

   int      mPrevADX,mPrevADY;
   double   mPrevDX, mPrevDY;
   double   mMiterLimit;

   LineInfo *mLines;
   int      mLineCount;
   SpanInfo *mSpans;
   int      mMaxSpan;
   int      mMinY;
   int      mMaxY;

private: // Disable
   BasePolygonRenderer(const BasePolygonRenderer &inRHS);
   void operator =(const BasePolygonRenderer &inRHS);
};




template<typename AA_,typename SOURCE_>
class SourcePolygonRenderer : public BasePolygonRenderer<AA_>
{
   typedef BasePolygonRenderer<AA_> Base;
public:
   SourcePolygonRenderer(int inN,const PointF16 *inPts,
            int inMinY,int inMaxY, const PolyLine *inLines,const SOURCE_ &inSource)
      : BasePolygonRenderer<AA_>(inN,inPts,inMinY,inMaxY,inLines),
         mSource(inSource)
   {
      // mSource is copy-constructed, so yo ubetter be sure this will
      //  work (rule of three)
   }

   void Render(SDL_Surface *outDest, Sint16 inOffsetX,Sint16 inOffsetY)
   {
      // TODO: Offset (change dest pointers ?)
      ProcessLines(outDest,Base::mMinY,Base::mMaxY,Base::mLines,mSource);
   }


   SOURCE_ mSource;
};


// --- Create Renderers --------------------------------------

template<typename AA_,int FLAGS_,int SIZE_>
PolygonRenderer *TCreateGradientRenderer(int inN,
                        const PointF16 *inPts,
                        Sint32 inYMin, Sint32 inYMax,
                        Uint32 inFlags,
                        Gradient *inGradient,
                        const PolyLine *inLines)
{
   if (inGradient->Is2D())
   {
      if (inGradient->IsFocal0())
      {
         typedef GradientSource2D<SIZE_,FLAGS_ + SPG_GRADIENT_FOCAL0> Source;

         return new SourcePolygonRenderer<AA_,Source>(
             inN, inPts, inYMin, inYMax, inLines, Source(inGradient) );
      }
      else
      {
         typedef GradientSource2D<SIZE_,FLAGS_> Source;

         return new SourcePolygonRenderer<AA_,Source>(
             inN, inPts, inYMin, inYMax, inLines, Source(inGradient) );
      }

   }
   else
   {
      typedef GradientSource1D<SIZE_,FLAGS_> Source;

      return new SourcePolygonRenderer<AA_,Source>(
          inN, inPts, inYMin, inYMax, inLines, Source(inGradient) );
   }
}



PolygonRenderer *PolygonRenderer::CreateGradientRenderer(int inN,
                        const PointF16 *inPts,
                        Sint32 inYMin, Sint32 inYMax,
                        Uint32 inFlags,
                        class Gradient *inGradient,
                        const PolyLine *inLines)
{
   if (inN<3)
      return 0;

#define ARGS inN,inPts,inYMin,inYMax,inFlags,inGradient,inLines

   if (inFlags & SPG_HIGH_QUALITY)
   {
      AA4x::Init();
      if (inGradient->mColours.size()==256)
      {
         if (inGradient->mUsesAlpha)
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA4x,SPG_ALPHA_BLEND+SPG_EDGE_REPEAT,256>(ARGS);
            else
               return TCreateGradientRenderer<AA4x,SPG_ALPHA_BLEND,256>(ARGS);
         }
         else
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA4x,SPG_EDGE_REPEAT,256>(ARGS);
            else
               return TCreateGradientRenderer<AA4x,0,256>(ARGS);
         }
      }
      else
      {
         if (inGradient->mUsesAlpha)
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA4x,SPG_ALPHA_BLEND+SPG_EDGE_REPEAT,512>(ARGS);
            else
               return TCreateGradientRenderer<AA4x,SPG_ALPHA_BLEND,512>(ARGS);
         }
         else
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA4x,SPG_EDGE_REPEAT,512>(ARGS);
            else
               return TCreateGradientRenderer<AA4x,0,512>(ARGS);
         }
      }
  }
  else
  {
      if (inGradient->mColours.size()==256)
      {
         if (inGradient->mUsesAlpha)
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA0x,SPG_ALPHA_BLEND+SPG_EDGE_REPEAT,256>(ARGS);
            else
               return TCreateGradientRenderer<AA0x,SPG_ALPHA_BLEND,256>(ARGS);
         }
         else
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA0x,SPG_EDGE_REPEAT,256>(ARGS);
            else
               return TCreateGradientRenderer<AA0x,0,256>(ARGS);
         }
      }
      else
      {
         if (inGradient->mUsesAlpha)
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA0x,SPG_ALPHA_BLEND+SPG_EDGE_REPEAT,512>(ARGS);
            else
               return TCreateGradientRenderer<AA0x,SPG_ALPHA_BLEND,512>(ARGS);
         }
         else
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer
                          <AA0x,SPG_EDGE_REPEAT,512>(ARGS);
            else
               return TCreateGradientRenderer<AA0x,0,512>(ARGS);
         }
      }
  }
#undef ARGS

   // should not get here ...
   return 0;
}

// --- Bitmap renderer --------------------------------------------


bool IsPOW2(int inX)
{
   return (inX & (inX-1)) == 0;
}



template<typename AA_,typename SOURCE_>
PolygonRenderer *CreateBitmapRenderer(int inN,
                              const PointF16 *inPts,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              const PolyLine *inLines,
                              const SOURCE_ &inSource )
{
   return new SourcePolygonRenderer<AA_,SOURCE_>(inN,inPts,inYMin,inYMax,
                                           inLines,inSource );
}



template<typename AA_,int FLAGS_>
PolygonRenderer *CreateBitmapRendererSource(int inN,
                              const PointF16 *inPts,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource,
                              const PolyLine *inLines)
{
   int edge = inFlags & SPG_EDGE_MASK;
   if (edge==SPG_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = SPG_EDGE_REPEAT_POW2;

   PolygonRenderer *r = 0;

#define SOURCE_EDGE(source) \
     if (edge == SPG_EDGE_REPEAT_POW2) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inPts, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_REPEAT_POW2>(inSource,inMapper));  \
     else if (edge == SPG_EDGE_REPEAT) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inPts, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_REPEAT>(inSource,inMapper));  \
     else if (edge == SPG_EDGE_UNCHECKED) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inPts, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_UNCHECKED>(inSource,inMapper));  \
     else \
       r = CreateBitmapRenderer<AA_>( \
          inN, inPts, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_CLAMP>(inSource,inMapper));


   switch(inSource->format->BytesPerPixel)
   {
      case 1:
         SOURCE_EDGE(SurfaceSource8);
         break;
      case 3:
         SOURCE_EDGE(SurfaceSource24);
         break;
      case 4:
         SOURCE_EDGE(SurfaceSource32);
         break;
   }

#undef SOURCE_EDGE

   return r;
}


template<typename AA_>
PolygonRenderer *AACreateBitmapRendererSource(int inN,
                              const PointF16 *inPts,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource,
                              const PolyLine *inLines)
{
   if (inFlags & SPG_BMP_LINEAR)
   {
      if (inFlags & SPG_ALPHA_BLEND)
          return CreateBitmapRendererSource
              <AA_,SPG_BMP_LINEAR+SPG_ALPHA_BLEND>(
                inN,inPts,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
      else
          return CreateBitmapRendererSource<AA_,SPG_BMP_LINEAR>(
                inN,inPts,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
   }
   else
   {
      if (inFlags & SPG_ALPHA_BLEND)
          return CreateBitmapRendererSource<AA_,SPG_ALPHA_BLEND>(
                inN,inPts,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
      else
          return CreateBitmapRendererSource<AA_,0>(
                inN,inPts,inYMin,inYMax, inFlags, inMapper,inSource,inLines);

   }
}



PolygonRenderer *PolygonRenderer::CreateBitmapRenderer(int inN,
                              const PointF16 *inPts,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource,
                              const PolyLine *inLines)
{
   if (inFlags & SPG_HIGH_QUALITY)
   {
      AA4x::Init();
      return AACreateBitmapRendererSource<AA4x>
               (inN,inPts,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
   }
   else
   {
      return AACreateBitmapRendererSource<AA0x>
               (inN,inPts,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
   }
}

// --- Solids -------------------------------------------------------

template<typename AA_,int FLAGS_>
PolygonRenderer *TCreateSolidRenderer(int inN,
                              const PointF16 *inPts,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              int inColour, double inAlpha,
                              const PolyLine *inLines)
{
   typedef ConstantSource32<FLAGS_> Source;

   return new SourcePolygonRenderer<AA_,Source>(inN,inPts,inYMin,inYMax,
                               inLines,Source(inColour,inAlpha) );
}



PolygonRenderer *PolygonRenderer::CreateSolidRenderer(int inN,
                              const PointF16 *inPts,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              int inColour, double inAlpha,
                              const PolyLine *inLines)
{
   if (inFlags & SPG_HIGH_QUALITY)
   {
      AA4x::Init();
      if (inAlpha < 1.0 )
          return TCreateSolidRenderer<AA4x,SPG_ALPHA_BLEND>(
                  inN,inPts,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
      else
          return TCreateSolidRenderer<AA4x,0>(
                  inN,inPts,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
   }
   else
   {
      if (inAlpha < 1.0 )
          return TCreateSolidRenderer<AA0x,SPG_ALPHA_BLEND>(
                  inN,inPts,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
      else
          return TCreateSolidRenderer<AA0x,0>(
                  inN,inPts,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
   }
}
