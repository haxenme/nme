#include "Pixel.h"
#include "Gradient.h"
#include <algorithm>
#include <map>

// --- AA traits classes ----------------------------------------------------

// The AA structures allow for the same code to be used for high-quality
//  and fast rendering.

struct AA0x
{
   enum { AlphaBits = 0 };
   enum { AABits = 1 };
   enum { AA = (1<<AABits) };

   typedef Uint8 State;
   static void InitState(State &outState)
      { outState = 0; }

   inline AA0x() : mVal(0) { }

   Uint8   mVal;

   static inline Uint8 SGetAlpha(State &inState)
      { return inState; }

   static inline Uint8 GetAlpha(State &inState)
      { return inState; }


   inline void Transition(Uint8 &ioDrawing) const
   {
      ioDrawing ^=  mVal;
   }
   inline void Add(int inX,int inY)
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

   inline Uint8 GetAlpha(Uint8 *inState) const // 5-bits fixed, [0,32] inclusive
   {
      return mAlpha[inState[0] | mPoints[0]] + 
             mAlpha[inState[1] | mPoints[1]] + 
             mAlpha[inState[2] | mPoints[2]] + 
             mAlpha[inState[3] | mPoints[3]];
   }
   static inline Uint8 SGetAlpha(Uint8 *inState)
   {
      return (inState[0] + inState[1] + inState[2] + inState[3]) >> 1;
   }

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
      //printf("%d,%d : %d -> %d\n", inY>>2, inX>>16, inY & 0x03, (inX>>14) & 0x03);
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
         LINE_::iterator i = line.begin();

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
                  outDest.SetIncBlend<Point::AlphaBits>(inSource,alpha);
               inSource.Inc();
               x++;
            }

            i->second.Transition(drawing);
            LINE_::iterator next = i;
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
                            outDest.SetIncBlend<Point::AlphaBits>
                               (inSource,alpha);
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
         TProcessLines( DestSurface8(outDest),inYMin,inYMax,inLines,inSource );
         break;
         // TODO : 2
      case 3:
         TProcessLines( DestSurface24(outDest),inYMin,inYMax,inLines,inSource );
         break;
      case 4:
         TProcessLines( DestSurface32(outDest),inYMin,inYMax,inLines,inSource );
         break;
   }
   
   if ( SDL_MUSTLOCK(outDest) && _SPG_lock )
      SDL_UnlockSurface(outDest);
}



template<typename AA_>
class BasePolygonRenderer : public PolygonRenderer
{
public:
   typedef std::map<int,AA_> LineInfo;

   BasePolygonRenderer(int inN,const Sint32 *inX,const Sint32 *inY,
            int inMinY,int inMaxY)
   {
      mMinY = inMinY;
      mMaxY = inMaxY;

      int min_y = inY[0]>>16;
      int max_y = min_y;
   
      for(int i=1;i<inN;i++)
      {
         int y = inY[i]>>16;
         if (y<min_y) min_y = y;
         else if (y>max_y) max_y = y;
      }
      // exclusive of last point
      max_y++;
   
      if (min_y > mMinY)
         mMinY = min_y;
   
      if (max_y < mMaxY)
         mMaxY = max_y;
      else
         max_y = mMaxY;
      
   
      mLines = new LineInfo [ mMaxY - mMinY ];
   
      min_y = mMinY << 16;
      // After offset ...
      max_y = (mMaxY-mMinY) << (AA_::AABits);
   
   
      // X is fixed-16
      int x0 = inX[inN-1];
      // Convert to AA grid ...
      int y0 = (inY[inN-1] - min_y) >> (16-AA_::AABits);
   
      int yprev = (inY[inN-2] - min_y) >> (16-AA_::AABits);
      bool prev_horiz = yprev == y0;
   
      for(int i=0;i<inN;i++)
      {
         int x1 = inX[i];
         int y1 = (inY[i] - min_y) >> (16-AA_::AABits);
   
         // clip whole line ?
         if (!(y0<0 && y1<0) && !(y0>=max_y && y1>=max_y) )
         {
            // Draw a line from first point up to (not including) last point
            int dy = y1-y0;
            if (dy==0)
            {
               // only put on first point of horizontal series ...
               if (!prev_horiz)
               {
                  // X is fixed-16, y is fixed-aa
                  mLines[y0>>AA_::AABits][x0>>16].Add(x0,y1);
               }
               prev_horiz = true;
            }
            else if (dy<0) // going up ...
            {
               int x = x0;
               int dx_dy = (x1-x0)/dy;
               int y = y0;
               if (y0>=max_y)
               {
                  y  = max_y - 1;
                  x-= (y0-y) * dx_dy;
               }
               int last =  (y1<0) ?  -1 : y1;
   
               for(; y>last; y--)
               {
                  // X is fixed-16, y is fixed-aa
                  mLines[y>>AA_::AABits][x>>16].Add(x,y);
                  // printf("%d %d\n", y>>AA_::AABits, x>>16);
                  x-=dx_dy;
               }
   
               prev_horiz = false;
            }
            else // going down ...
            {
               int x = x0;
               int dx_dy = (x1-x0)/dy;
               int y = y0;
               if (y0<0)
               {
                  y  = 0;
                  x+= y0 * dx_dy;
               }
               int last = y1>max_y ? max_y : y1;
   
               for(; y<last; y++)
               {
                  // X is fixed-16, y is fixed-aa
                  mLines[y>>AA_::AABits][x>>16].Add(x,y);
                  x+=dx_dy;
               }
               prev_horiz = false;
            }
         }
   
         x0 = x1;
         y0 = y1;
      }

   }

   ~BasePolygonRenderer()
   {
      delete [] mLines;
   }

   LineInfo *mLines;
   int      mMinY;
   int      mMaxY;

private: // Disable
   BasePolygonRenderer(const BasePolygonRenderer &inRHS);
   void operator =(const BasePolygonRenderer &inRHS);
};




template<typename AA_,typename SOURCE_>
class SourcePolygonRenderer : public BasePolygonRenderer<AA_>
{
public:
   SourcePolygonRenderer(int inN,const Sint32 *inX,const Sint32 *inY,
            int inMinY,int inMaxY, SOURCE_ &inSource)
      : BasePolygonRenderer(inN,inX,inY,inMinY,inMaxY),
         mSource(inSource)
   {
      // mSource is copy-constructed, so yo ubetter be sure this will
      //  work (rule of three)
   }

   void Render(SDL_Surface *outDest, Sint16 inOffsetX,Sint16 inOffsetY)
   {
      // TODO: Offset (change dest pointers ?)
      ProcessLines(outDest,mMinY,mMaxY,mLines,mSource);
   }


   SOURCE_ mSource;
};


// --- Create Renderers --------------------------------------

template<typename AA_,int FLAGS_,int SIZE_>
PolygonRenderer *TCreateGradientRenderer(int inN,
                        Sint32 *inX,Sint32 *inY,
                        Sint32 inYMin, Sint32 inYMax,
                        Uint32 inFlags,
                        Gradient *inGradient )
{
   typedef GradientSource1D<SIZE_,FLAGS_> Source;

   return new SourcePolygonRenderer<AA_,Source>(
       inN, inX, inY, inYMin, inYMax, Source(inGradient) );
}



PolygonRenderer *PolygonRenderer::CreateGradientRenderer(int inN,
                        Sint32 *inX,Sint32 *inY,
                        Sint32 inYMin, Sint32 inYMax,
                        Uint32 inFlags,
                        class Gradient *inGradient )
{
   if (inN<3)
      return 0;

#define ARGS inN,inX,inY,inYMin,inYMax,inFlags,inGradient

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
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SOURCE_ &inSource )
{
   return new SourcePolygonRenderer<AA_,SOURCE_>(inN,inX,inY,inYMin,inYMax,
                                           inSource );
}



template<typename AA_,int FLAGS_>
PolygonRenderer *CreateBitmapRendererSource(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource )
{
   int edge = inFlags & SPG_EDGE_MASK;
   if (edge==SPG_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = SPG_EDGE_REPEAT_POW2;

   PolygonRenderer *r = 0;

#define SOURCE_EDGE(source) \
     if (edge == SPG_EDGE_REPEAT_POW2) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper, \
          source<FLAGS_,SPG_EDGE_REPEAT_POW2>(inSource,inMapper));  \
     else if (edge == SPG_EDGE_REPEAT) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper, \
          source<FLAGS_,SPG_EDGE_REPEAT>(inSource,inMapper));  \
     else if (edge == SPG_EDGE_UNCHECKED) \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper, \
          source<FLAGS_,SPG_EDGE_UNCHECKED>(inSource,inMapper));  \
     else \
       r = CreateBitmapRenderer<AA_>( \
          inN, inX,inY, inYMin,inYMax,inFlags,inMapper, \
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
                              SDL_Surface *inSource )
{
   if (inFlags & SPG_HIGH_QUALITY)
   {
      if (inFlags & SPG_ALPHA_BLEND)
          return CreateBitmapRendererSource
              <AA4x,SPG_HIGH_QUALITY+SPG_ALPHA_BLEND>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource);
      else
          return CreateBitmapRendererSource<AA4x,SPG_HIGH_QUALITY>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource);
   }
   else
   {
      if (inFlags & SPG_ALPHA_BLEND)
          return CreateBitmapRendererSource<AA0x,SPG_ALPHA_BLEND>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource);
      else
          return CreateBitmapRendererSource<AA0x,0>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inMapper,inSource);

   }
}

// --- Solids -------------------------------------------------------

template<typename AA_,int FLAGS_>
PolygonRenderer *TCreateSolidRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              int inColour, double inAlpha=1.0)
{
   typedef ConstantSource32<FLAGS_> Source;

   return new SourcePolygonRenderer<AA_,Source>(inN,inX,inY,inYMin,inYMax,
                               Source(inColour,inAlpha) );
}



PolygonRenderer *PolygonRenderer::CreateSolidRenderer(int inN,
                              Sint32 *inX,Sint32 *inY,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              int inColour, double inAlpha)
{
   if (inFlags & SPG_HIGH_QUALITY)
   {
      if (inAlpha < 1.0 )
          return TCreateSolidRenderer<AA4x,SPG_ALPHA_BLEND>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inColour,inAlpha);
      else
          return TCreateSolidRenderer<AA4x,0>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inColour);
   }
   else
   {
      if (inAlpha < 1.0 )
          return TCreateSolidRenderer<AA0x,SPG_ALPHA_BLEND>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inColour,inAlpha);
      else
          return TCreateSolidRenderer<AA0x,0>(
                   inN,inX,inY,inYMin,inYMax, inFlags, inColour);
   }
}
