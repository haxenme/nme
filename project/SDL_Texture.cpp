#include "Pixel.h"
#include "Gradient.h"
#include <math.h>
#include <algorithm>
#include <map>


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
      { return inState; }

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
            if (draw) sum+= 1;
            if (i&0x01) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x02) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x04) draw = !draw;
            if (draw) sum+= 2;
            if (i&0x08) draw = !draw;
            if (draw) sum+= 1;

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

struct XY
{
   int x,y;
};


template<typename AA_>
class BasePolygonRenderer : public PolygonRenderer
{
public:
   enum { ToAA = (16-AA_::AABits) };

   typedef std::map<int,AA_>  LineInfo;
   typedef std::map<int,bool> SpanInfo;
   typedef AA_ Point;
   typedef typename Point::State State;


   BasePolygonRenderer(int inN,const Sint32 *inX,const Sint32 *inY,
            int inMinY,int inMaxY,const PolyLine *inLines)
   {
      mMinY = inMinY;
      mMaxY = inMaxY;

      int min_y = inY[0]>>16;
      int max_y = min_y;
      mLines = 0;

      if (inLines)
      {
         const IntVec &pids = inLines->mPointIndex;
         double extra = 0.5;
         if (inLines->mJoints == SPG_CORNER_MITER)
            extra += inLines->mMiterLimit;
         int w = int(inLines->mThickness*extra + 0.999);

         for(size_t i=0;i<pids.size();i++)
         {
            int y = inY[ pids[i] ]>>16;
            if (y<min_y) min_y = y;
            else if (y>max_y) max_y = y;
         }
         min_y -= w;
         max_y += w;
      }
      else
      {
         for(int i=1;i<inN;i++)
         {
            int y = inY[i]>>16;
            if (y<min_y) min_y = y;
            else if (y>max_y) max_y = y;
         }
      }

      // exclusive of last point
      max_y++;

      if (min_y >= inMaxY || max_y<inMinY)
      {
         mMinY = mMaxY = 0;
         return;
      }
   
      if (min_y > mMinY)
         mMinY = min_y;
   
      if (max_y < mMaxY)
         mMaxY = max_y;
      else
         max_y = mMaxY;
      
   
      mLineCount = mMaxY - mMinY;
      mLines = new LineInfo [ mLineCount ];
   
      min_y = mMinY << 16;
      // After offset ...
      max_y = (mMaxY-mMinY) << (AA_::AABits);

      if (inLines)
      {
         mMaxSpan = max_y;
         mSpans = new SpanInfo [ mMaxSpan ];
         int thickness = (int)(inLines->mThickness * 0.5 * 65536);

         const IntVec &pids = inLines->mPointIndex;
         int n = (int)pids.size();
         bool loop = n>2 && (inX[pids[0]]==inX[pids[n-1]]) &&
                            (inY[pids[0]]==inY[pids[n-1]]);
         int x1,y1;

         int x0 = inX[ pids[0] ];
         int y0 = (inY[ pids[0] ]-min_y);

         mCaps = inLines->mCaps;
         mJoints = inLines->mJoints;
         mCircleRad = 0;

         if (!loop && mCaps==SPG_END_ROUND)
            SpanCircle(x0,y0,thickness);

         // Convert hypotnuse into edge length
         if (mJoints==SPG_CORNER_MITER)
         {
            mMiterLimit = inLines->mMiterLimit;
            if (mMiterLimit<=1)
               mJoints = SPG_CORNER_BEVEL;
            else
               mMiterLimit = sqrt( mMiterLimit*mMiterLimit - 1.0 );
         }

         if (loop && mJoints!=SPG_CORNER_ROUND)
         {
            int dx = inX[pids[0]]-inX[pids[n-2]];
            int dy = inY[pids[0]]-inY[pids[n-2]];
            double dub_x = dx;
            double dub_y = dy;
            double len = sqrt(dub_x*dub_x + dub_y*dub_y);
            if (len==0)
            {
               mPrevADX = mPrevADY = 0;
               mPrevDX = 0;
               mPrevDY = 0;
            }
            else
            {
               double norm = (thickness/len);
               // Perpendicular line, dx=dy, dy=-dx
               mPrevADY = ((int)(-dx*norm))>>ToAA;
               mPrevADX = ((int)(dy*norm))>>ToAA;
               if (mJoints==SPG_CORNER_MITER)
               {
                  mPrevDX = dx * norm / (1<<ToAA);
                  mPrevDY = dy * norm / (1<<ToAA);
               }
            }
         }
         
         for(size_t i=1;i<pids.size();i++)
         {
             x1 = inX[ pids[i] ];
             y1 = (inY[ pids[i] ]-min_y);
             SpanLine( x0, y0, x1, y1, thickness,
                           !loop && i==1, !loop && i==n-1 );
             x0 = x1;
             y0 = y1;
         }

         if (!loop && mCaps==SPG_END_ROUND)
            SpanCircle(x1,y1,thickness);

         // Convert spans to lines ....
         for(int y=0;y<max_y;y++)
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
      else
      {
         int x0 = inX[inN-1];
         int y0 = (inY[inN-1]-min_y)>>ToAA;
      
         for(int i=0;i<inN;i++)
         {
            int x1 = inX[i];
            int y1 = (inY[i]-min_y)>>ToAA;
      
            // clip whole line ?
            if (!(y0<0 && y1<0) && !(y0>=max_y && y1>=max_y) )
            {
               // Draw a line from first point up to (not including) last point
               int dy = y1-y0;
               if (dy==0)
               {
                  // No need to do anything..
               }
               // going up - include last point, but not first...
               else if (dy<0)
               {
                  int x = x0;
                  int dx_dy = (x1-x0)/dy;
                  int y = y0;

                  // skip lower point on a line
                  y--;
                  x-=dx_dy;

                  if (y>=max_y)
                  {
                     x -= (y-max_y) * dx_dy;
                     y  = max_y - 1;
                  }
                  int last =  (y1<0) ? 0 : y1;

                  for(; y>=last; y--)
                  {
                     // X is fixed-16, y is fixed-aa
                     mLines[y>>AA_::AABits][x>>16].Add(x,y);
                     x-=dx_dy;
                  }
               }
               else // going down - include first point, but not last
               {
                  int x = x0;
                  int dx_dy = (x1-x0)/dy;
                  int y = y0;

                  if (y<0)
                  {
                     x-= y * dx_dy;
                     y = 0;
                  }
                  int last = y1>max_y ? max_y : y1;

                  for(; y<last; y++)
                  {
                     // X is fixed-16, y is fixed-aa
                     mLines[y>>AA_::AABits][x>>16].Add(x,y);
                     x+=dx_dy;
                  }
               }
            }
      
            x0 = x1;
            y0 = y1;
         }

         // VerifyLines();
      }
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

   inline void SpanLine(int inY,int inX0,int inX1)
   {
      if (inY>=0 && inY<mMaxSpan)
      {

         inX0 = inX0 >> ToAA;
         inX1 = (inX1>>ToAA) + 1;
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
   int    mCircleOff;
   int    mCircleRad;

   // X is fixed16, y is fixed16-min, inRad is fixed16
   void SpanCircle(int inX,int inY,int inRad)
   {
      if (inRad < (2<<16))
         return;

      if (inRad != mCircleRad)
      {
         mCircleRad = inRad;
         mCircleOff = (inRad>>ToAA);
         int n = 2*mCircleOff+1;
         mCircleArc.resize(n);
         for(int y=0;y<=mCircleOff;y++)
         {
            double yr = ((mCircleOff-y) << ToAA);
            double r =  inRad;
            int dx = (int)( sqrt(r*r - yr*yr ) );
            mCircleArc[y] = dx;
            mCircleArc[n-1-y] = dx;
         }
      }

      int *ptr = &mCircleArc[mCircleOff];
      int y0 = inY>>ToAA;
      for(int y=1-mCircleOff;y<mCircleOff;y++)
         SpanLine(y0 + y, inX-ptr[y], inX+ptr[y] );
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
   void SpanTriangle(int inX0,int inY0,
                     int inX1,int inY1,
                     int inX2,int inY2 )
   {
       // Sort
       if (inY2<inY1)
          { std::swap(inY1,inY2); std::swap(inX1,inX2); }
       if (inY1<inY0)
          { std::swap(inY0,inY1); std::swap(inX0,inX1); }
       if (inY2<inY1)
          { std::swap(inY1,inY2); std::swap(inX1,inX2); }

       int dy1 =  inY2-inY0;
       if (!dy1) return;
       int dxb_dy1 = ((inX2-inX0)<<ToAA)/dy1;
       int xa = (inX0<<ToAA);
       int xb = xa;
       int dy0 = inY1-inY0;
       if (dy0)
       {
          int dxa_dy0 = ( (inX1-inX0) << ToAA ) / dy0;
          for(int y=inY0;y<inY1;y++)
          {
             if (xa<xb)
                SpanLine(y,xa,xb);
             else
                SpanLine(y,xb,xa);
             xa += dxa_dy0;
             xb += dxb_dy1;
          }
       }
       int dy2 = inY2-inY1;
       if (dy2)
       {
          xa = inX1<<ToAA;
          int dxa_dy2 = ( (inX2-inX1) << ToAA ) / dy2;
          for(int y=inY1;y<inY2;y++)
          {
             if (xa<xb)
                SpanLine(y,xa,xb);
             else
                SpanLine(y,xb,xa);
             xa += dxa_dy2;
             xb += dxb_dy1;
          }
       }


   }


   /*
       |     +0      |
     dy0    / \  xb  |      top triangle
       |   /   \     dy1
         1+.....\    |
     |     \     \   |      middle parralelogram
    dy2  xa \.....+2
     |       \   / |        bottom triangle
     |        \ /  dy3
     |        3+   |

   */


   void SpanQuad(int inX0,int inY0,
                 int inX1,int inY1,
                 int inX2,int inY2,
                 int inX3,int inY3 )
   {
      int y0 = inY0 >> ToAA;
      int y1 = inY1 >> ToAA;
      int y2 = inY2 >> ToAA;
      int y3 = inY3 >> ToAA;

      if (y3==y0) return;

      int dy0 = y1-y0;
      int dy1 = y2-y0;
      int dy2 = y3-y1;
      int dy3 = y3-y2;

      int dxa_dy2 = dy2==0 ? 0 : (inX3-inX1)/dy2;
      int dxb_dy1 = dy1==0 ? 0 : (inX2-inX0)/dy1;

      int xa = inX0;
      int xb = inX0;

      int y = y0;
      // Top triangle ...
      if (dy0>0)
      {
         int dxa_dy0 = (inX1-inX0)/dy0;
         while(y<y1)
         {
            if (xa<xb)
               SpanLine(y,xa,xb);
            else
               SpanLine(y,xb,xa);
            xa+=dxa_dy0;
            xb+=dxb_dy1;
            y++;
         }
      }
      // middle bit
      xa = inX1;
      while(y<y2)
      {
         if (xa<xb)
            SpanLine(y,xa,xb);
         else
            SpanLine(y,xb,xa);
         xa+=dxa_dy2;
         xb+=dxb_dy1;
         y++;
      }
      // last bit ...
      if (dy3>0)
      {
         xb = inX2;
         int dxb_dy3 = (inX3-inX2)/dy3;
         while(y<y3)
         {
            if (xa<xb)
               SpanLine(y,xa,xb);
            else
               SpanLine(y,xb,xa);
            xa+=dxa_dy2;
            xb+=dxb_dy3;
            y++;
         }
      }
   }

   void SpanAlignRectRectangle(int inX0,int inY0,int inX1,int inY1)
   {
      int y0 = inY0>>ToAA;
      int y1 = inY1>>ToAA;
      for(int y=y0;y<y1;y++)
         SpanLine(y,inX0,inX1);
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
   void SpanLine(int inX0,int inY0,int inX1,int inY1,int inT,
           bool inEnd0,bool inEnd1)
   {
      int dx  = inX1-inX0;
      int dy = inY1-inY0;
      double dub_x = dx;
      double dub_y = dy;
      double len = sqrt(dub_x*dub_x + dub_y*dub_y);
      double norm = (inT/len);
      // Perpendicular line, dx=dy, dy=-dx
      int ady = (int)(-dx*norm);
      int adx = (int)(dy*norm);
      int adx_aa = adx>>ToAA;
      int ady_aa = ady>>ToAA;

      double norm_dx;
      double norm_dy;
      if (mJoints==SPG_CORNER_MITER)
      {
         norm_dx = dx * norm / (1<<ToAA);
         norm_dy = dy * norm / (1<<ToAA);
      }

      if (!inEnd0)
      {
         if (mJoints==SPG_CORNER_ROUND)
            SpanCircle(inX0,inY0,inT);
         else if (mJoints==SPG_CORNER_BEVEL || mJoints==SPG_CORNER_MITER)
         {
            int dot = (dx>>ToAA)*mPrevADX + (dy>>ToAA)*mPrevADY;
            if (dot!=0 || (mJoints==SPG_CORNER_MITER &&
                 (norm_dx*mPrevDX + norm_dy*mPrevDY) < 0 ) )
            {
               int sign = dot>0 ? - 1 : 1;
               int x0 = inX0 >> ToAA;
               int y0 = inY0 >> ToAA;
               int x1 = x0+sign*adx_aa;
               int y1 = y0+sign*ady_aa;
               int x2 = x0+sign*mPrevADX;
               int y2 = y0+sign*mPrevADY;
               if (mJoints==SPG_CORNER_BEVEL)
                  SpanTriangle( x0, y0, x1, y1, x2, y2 );
               else
               {
                  // Solve:
                  //  (x1,y1) - a*(norm_dx,norm_dy) =
                  //        (x2,y2) + a*(mPrevDX,mPrevDY)
                  // x1 - a *norm_dx = x2 + a*mPrevDX
                  // a ( mPrevDX + norm_dx) = x1+x2

                  double a;
                  double ddx = mPrevDX + norm_dx;
                  double ddy = mPrevDY + norm_dy;

                  if (dot==0)
                     a = mMiterLimit;
                  else if (fabs(ddx)>fabs(ddy))
                  {
                     a = (double)(x1-x2)/ddx;
                     if (a>mMiterLimit) a = mMiterLimit;
                  }
                  else if (ddy != 0)
                  {
                     a = (double)(y1-y2)/ddy;
                     if (a>mMiterLimit) a = mMiterLimit;
                  }
                  else 
                     a = mMiterLimit;

                  if (a<mMiterLimit)
                  {
                     int cx = int(x1 - a*norm_dx);
                     int cy = int(y1 - a*norm_dy);
                     SpanTriangle( x0, y0, x1, y1, cx, cy );
                     SpanTriangle( x0, y0, cx, cy, x2, y2 );
                  }
                  else
                  {
                     int cx1 = int(x1 - a*norm_dx);
                     int cy1 = int(y1 - a*norm_dy);
                     int cx2 = int(x2 + a*mPrevDX);
                     int cy2 = int(y2 + a*mPrevDY);
                     SpanTriangle( x0, y0, x1, y1, cx1, cy1 );
                     SpanTriangle( x0, y0, cx2, cy2, cx1, cy1 );
                     SpanTriangle( x0, y0, cx2, cy2, x2, y2 );
                  }
               }
            }
         }
      }

      if (mJoints==SPG_CORNER_MITER)
      {
         mPrevDX = norm_dx;
         mPrevDY = norm_dy;
      }
      mPrevADX = adx_aa;
      mPrevADY = ady_aa;

      if (mCaps==SPG_END_SQUARE)
      {
         if (inEnd0)
         {
            inX0 -= (int)(dx*norm);
            inY0 -= (int)(dy*norm);
         }
         if (inEnd1)
         {
            inX1 += (int)(dx*norm);
            inY1 += (int)(dy*norm);
         }
      }


      // Draw aligned quad, is possible
      if ((inY1>>ToAA) == (inY0>>ToAA))
      {
         if (inX0<inX1)
            SpanAlignRectRectangle(inX0,inY0-inT,inX1,inY0+inT);
         else
            SpanAlignRectRectangle(inX1,inY0-inT,inX0,inY0+inT);
         return;
      }

      // Sort and draw non-aligned quad ...
      if (dy<0)
      {
         std::swap(inX0,inX1);
         std::swap(inY0,inY1);
      }
      if (ady<0)
      {
         ady=-ady;
         adx=-adx;
      }

      // ady >0 and y0<y1
      // So y0-ady is min and y1+ady is max. 1 and 2 may be reversed...
      int x0 = inX0 - adx;
      int y0 = inY0 - ady;

      int x1 = inX0 + adx;
      int y1 = inY0 + ady;

      int x2 = inX1 - adx;
      int y2 = inY1 - ady;

      int x3 = inX1 + adx;
      int y3 = inY1 + ady;

      if (y1>y2)
      {
         std::swap(x1,x2);
         std::swap(y1,y2);
      }
      SpanQuad(x0,y0,x1,y1,x2,y2,x3,y3);
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
   SourcePolygonRenderer(int inN,const Sint32 *inX,const Sint32 *inY,
            int inMinY,int inMaxY, const PolyLine *inLines,const SOURCE_ &inSource)
      : BasePolygonRenderer<AA_>(inN,inX,inY,inMinY,inMaxY,inLines),
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
                        Sint32 *inX,Sint32 *inY,
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
             inN, inX, inY, inYMin, inYMax, inLines, Source(inGradient) );
      }
      else
      {
         typedef GradientSource2D<SIZE_,FLAGS_> Source;

         return new SourcePolygonRenderer<AA_,Source>(
             inN, inX, inY, inYMin, inYMax, inLines, Source(inGradient) );
      }

   }
   else
   {
      typedef GradientSource1D<SIZE_,FLAGS_> Source;

      return new SourcePolygonRenderer<AA_,Source>(
          inN, inX, inY, inYMin, inYMax, inLines, Source(inGradient) );
   }
}



PolygonRenderer *PolygonRenderer::CreateGradientRenderer(int inN,
                        Sint32 *inX,Sint32 *inY,
                        Sint32 inYMin, Sint32 inYMax,
                        Uint32 inFlags,
                        class Gradient *inGradient,
                        const PolyLine *inLines)
{
   if (inN<3)
      return 0;

#define ARGS inN,inX,inY,inYMin,inYMax,inFlags,inGradient,inLines

   if (inFlags & SPG_HIGH_QUALITY)
   {
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
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              const PolyLine *inLines,
                              const SOURCE_ &inSource )
{
   return new SourcePolygonRenderer<AA_,SOURCE_>(inN,inX,inY,inYMin,inYMax,
                                           inLines,inSource );
}



template<typename AA_,int FLAGS_>
PolygonRenderer *CreateBitmapRendererSource(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource,
                              const PolyLine *inLines)
{
   if (inFlags & SPG_HIGH_QUALITY)
      AA4x::Init();

   int edge = inFlags & SPG_EDGE_MASK;
   if (edge==SPG_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = SPG_EDGE_REPEAT_POW2;

   PolygonRenderer *r = 0;

#define SOURCE_EDGE(source) \
     if (edge == SPG_EDGE_REPEAT_POW2) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_REPEAT_POW2>(inSource,inMapper));  \
     else if (edge == SPG_EDGE_REPEAT) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_REPEAT>(inSource,inMapper));  \
     else if (edge == SPG_EDGE_UNCHECKED) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper,inLines, \
          source<FLAGS_,SPG_EDGE_UNCHECKED>(inSource,inMapper));  \
     else \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper,inLines, \
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



PolygonRenderer *PolygonRenderer::CreateBitmapRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource,
                              const PolyLine *inLines)
{
   if (inFlags & SPG_HIGH_QUALITY)
   {
      if (inFlags & SPG_ALPHA_BLEND)
          return CreateBitmapRendererSource
              <AA4x,SPG_HIGH_QUALITY+SPG_ALPHA_BLEND>(
                inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
      else
          return CreateBitmapRendererSource<AA4x,SPG_HIGH_QUALITY>(
                inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
   }
   else
   {
      if (inFlags & SPG_ALPHA_BLEND)
          return CreateBitmapRendererSource<AA0x,SPG_ALPHA_BLEND>(
                inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource,inLines);
      else
          return CreateBitmapRendererSource<AA0x,0>(
                inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource,inLines);

   }
}

// --- Solids -------------------------------------------------------

template<typename AA_,int FLAGS_>
PolygonRenderer *TCreateSolidRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              int inColour, double inAlpha,
                              const PolyLine *inLines)
{
   typedef ConstantSource32<FLAGS_> Source;

   return new SourcePolygonRenderer<AA_,Source>(inN,inX,inY,inYMin,inYMax,
                               inLines,Source(inColour,inAlpha) );
}



PolygonRenderer *PolygonRenderer::CreateSolidRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
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
                  inN,inX,inY,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
      else
          return TCreateSolidRenderer<AA4x,0>(
                  inN,inX,inY,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
   }
   else
   {
      if (inAlpha < 1.0 )
          return TCreateSolidRenderer<AA0x,SPG_ALPHA_BLEND>(
                  inN,inX,inY,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
      else
          return TCreateSolidRenderer<AA0x,0>(
                  inN,inX,inY,inYMin,inYMax, inFlags, inColour,inAlpha,inLines);
   }
}
