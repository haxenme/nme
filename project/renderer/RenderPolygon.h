#ifndef RENDERER_RENDER_POLYGON_H
#define RENDERER_RENDER_POLYGON_H

#include <math.h>
#include <algorithm>
#include <map>
#include "Renderer.h"
#include "Pixel.h"

#ifdef WIN32
typedef __int64 int64;
#else
typedef long long int64;
#endif


typedef std::map<int,bool> SpanInfo;

void RasterizeLines(const PointF16 *inPoints,
                    const PolyLine *inLines, 
                    int inMinY, int inMaxY,
                    int inAABits,
                    SpanInfo *outSpans);



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




// Find y-extent of object, this is in pixels, and is the intersection
//  with the screen y-extent.
bool FindObjectYExtent(int &ioMinY, int &ioMaxY,int inN,
          const PointF16 *inPoints,const PolyLine *inLines);


template<typename AA_>
class BasePolygonRenderer : public PolygonRenderer
{
public:
   enum { AABits = AA_::AABits };
   enum { ToAA = (16-AABits) };
   enum { AAMask = ~((1<<ToAA)-1) };
   enum { AAFact = 1<<AABits };

   typedef std::map<int,AA_>  LineInfo;
   typedef AA_ Point;
   typedef typename Point::State State;


   BasePolygonRenderer(const RenderArgs &inArgs)
   {
      mLines = 0;
      mMinY = inArgs.inMinY;
      mMaxY = inArgs.inMaxY;

      if (FindObjectYExtent(mMinY,mMaxY,inArgs.inN,inArgs.inPoints,inArgs.inLines))
      {
         mLineCount = mMaxY - mMinY;
         mLines = new LineInfo [ mLineCount ];


         // Draw line or solid ?
         if (inArgs.inLines)
         {
            // Bottom of lines ...
            int y_max_aa = (mMaxY-mMinY) << AABits;
            SpanInfo *spans = new SpanInfo[y_max_aa];

            RasterizeLines(inArgs.inPoints,inArgs.inLines,mMinY,mMaxY,AABits,spans);

            // Convert spans to lines ....
            for(int y=0;y<y_max_aa;y++)
            {
               LineInfo &line = mLines[y>>AA_::AABits];
               SpanInfo &span = spans[ y ];
               for(SpanInfo::iterator i=span.begin();i!=span.end();++i)
               {
                  int x = i->first;
                  line[x>>AA_::AABits].AddAA(x,y);
               }
            }

            delete [] spans;
         }
         else
         {
            // For removing offset ...
            int y_offset = mMinY << 16;
            // Bottom of lines ...
            int y_max_aa = (mMaxY-mMinY) << AABits;
            int y_max_val = (mMaxY-mMinY) << 16;

            int n = inArgs.inN;
            PointF16 p0(inArgs.inPoints[0]);
            p0.y -= y_offset;
         
            for(int i=1;i<n;i++)
            {
               PointF16 p1(inArgs.inPoints[i]);
               p1.y -= y_offset;
               PointF16 p_next = p1;

               // clip whole line ?
               if ( (inArgs.inConnect[i]!=0) &&
                 (!(p0.y<0 && p1.y<0) && !(p0.y>=y_max_val && p1.y>=y_max_val)))
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
   
#ifdef VERIFY
            VerifyLines();
#endif
         }
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



#ifdef VERIFY
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
#endif

   bool HitTest(int inX,int inY)
   {
      if (mMinY<=inY && mMaxY>inY && mLines)
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

   LineInfo *mLines;
   int      mLineCount;
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
   SourcePolygonRenderer(const RenderArgs &inArgs, const SOURCE_ &inSource)
      : BasePolygonRenderer<AA_>(inArgs), mSource(inSource)
   {
      // mSource is copy-constructed, so yo ubetter be sure this will
      //  work (rule of three)
   }

   void Render(SDL_Surface *outDest, Sint16 inOffsetX,Sint16 inOffsetY)
   {
      if ( SDL_MUSTLOCK(outDest) )
         if ( SDL_LockSurface(outDest) < 0 )
            return;

      // TODO: Offset (change dest pointers ?)

      switch(outDest->format->BytesPerPixel)
      {
         case 1:
            {
            DestSurface8 dest(outDest);
            TProcessLines( dest,Base::mMinY,Base::mMaxY,Base::mLines,mSource );
            break;
            }
            // TODO : 2
         case 3:
            {
            DestSurface24 dest(outDest);
            TProcessLines( dest,Base::mMinY,Base::mMaxY,Base::mLines,mSource );
            break;
            }
         case 4:
            {
            DestSurface32 dest(outDest);
            TProcessLines( dest,Base::mMinY,Base::mMaxY,Base::mLines,mSource );
            break;
            }
      }

      if ( SDL_MUSTLOCK(outDest)  )
         SDL_UnlockSurface(outDest);
   }


   SOURCE_ mSource;
};


#endif

