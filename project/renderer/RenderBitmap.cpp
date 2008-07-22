#include "Renderer.h"
#include "RenderPolygon.h"
#include "AA.h"
#include <math.h>
#include <algorithm>
#include <map>




#define GET_PIXEL_POINTERS \
         int frac_x = (mPos.x & 0xff00) >> 8; \
         int frac_nx = 0x100 - frac_x; \
         int frac_y = (mPos.y & 0xffff); \
         int frac_ny = 0x10000 - frac_y; \
 \
         if (EDGE == NME_EDGE_UNCHECKED) \
         { \
            Uint8 * ptr = mBase + (mPos.y >> 16)*mPitch + (mPos.x>>16)*4; \
            p00 = *(PIXEL_ *)ptr; \
            p01 = *(PIXEL_ *)(ptr + 4); \
            p10 = *(PIXEL_ *)(ptr + mPitch); \
            p11 = *(PIXEL_ *)(ptr + 4); \
         } \
         else \
         { \
            if (EDGE == NME_EDGE_CLAMP) \
            { \
               int x_step = 4; \
               int y_step = mPitch; \
 \
               if (x<0) {  x_step = x = 0; } \
               else if (x>=mW1) { x_step = 0; x = mW1; } \
 \
               if (y<0) {  y_step = y = 0; } \
               else if (y>=mH1) { y_step = 0; y = mH1; } \
 \
               Uint8 * ptr = mBase + y*mPitch + x*4; \
               p00 = *(PIXEL_ *)ptr; \
               p01 = *(PIXEL_ *)(ptr + x_step); \
               p10 = *(PIXEL_ *)(ptr + y_step); \
               p11 = *(PIXEL_ *)(ptr + y_step + x_step); \
            } \
            else if (EDGE==NME_EDGE_REPEAT_POW2) \
            { \
               Uint8 *p = mBase + (y&mH1)*mPitch; \
 \
               p00 = *(PIXEL_ *)(p+ (x & mW1)*4); \
               p01 = *(PIXEL_ *)(p+ ((x+1) & mW1)*4); \
 \
               p = mBase + ( (y+1) &mH1)*mPitch; \
               p10 = *(PIXEL_ *)(p+ (x & mW1)*4); \
               p11 = *(PIXEL_ *)(p+ ((x+1) & mW1)*4); \
            } \
            else \
            { \
               int x1 = ((x+1) % mWidth) * 4; \
               x = (x % mWidth)*4; \
 \
               Uint8 *p = mBase + (y%mHeight)*mPitch; \
 \
               p00 = *(PIXEL_ *)(p+ x); \
               p01 = *(PIXEL_ *)(p+ x1); \
 \
               p = mBase + ( (y+1) % mHeight )*mPitch; \
               p10 = *(PIXEL_ *)(p+ x); \
               p11 = *(PIXEL_ *)(p+ x1); \
            } \
 \
         } 



#define MODIFY_EDGE_XY \
         if (EDGE == NME_EDGE_CLAMP) \
         { \
            if (x<0) x = 0; \
            else if (x>=mWidth) x = mW1; \
 \
            if (y<0) y = 0; \
            else if (y>=mHeight) y = mH1; \
         } \
         else if (EDGE == NME_EDGE_REPEAT_POW2) \
         { \
            x &= mW1; \
            y &= mH1; \
         } \
         else if (EDGE == NME_EDGE_REPEAT) \
         { \
            x = x % mWidth; \
            y = y % mHeight; \
         }


// --- Sources ------------------------------------------------

struct SurfaceSourceBase
{
   SurfaceSourceBase(SDL_Surface *inSurface,const Matrix &inMapper) :
     mSurface(inSurface), mMapper(inMapper)
   {
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mW1 = mWidth-1;
      mH1 = mHeight-1;
      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;


      mDPDX.x = int((mMapper.m00)*65536);
      mDPDX.y = int((mMapper.m10)*65536);
   }

   inline void SetPos(int inX,int inY)
   {
      double x = inX+0.5;
      double y = inY+0.5;
      mPos.x = int((mMapper.m00 * x + mMapper.m01*y + mMapper.mtx)*65536) - 0x8000;
      mPos.y = int((mMapper.m10 * x + mMapper.m11*y + mMapper.mty)*65536) - 0x8000;
   }

   inline void Inc()
   {
      mPos.x += mDPDX.x;
      mPos.y += mDPDX.y;
   }



   PointF16 mPos;
   PointF16 mDPDX;

   Matrix      mMapper;
   SDL_Surface *mSurface;

   int         mWidth;
   int         mHeight;
   int         mPitch;
   int         mW1;
   int         mH1;
   Uint8       *mBase;
   Uint8       *mPtr;
};


template<int EDGE_>
struct SurfaceSource8 : public SurfaceSourceBase
{
   enum { EDGE = EDGE_ };

   SurfaceSource8(SDL_Surface *inSurface,const Matrix &inMapping)
      : SurfaceSourceBase(inSurface,inMapping)
   {
      int n  = inSurface->format->palette->ncolors;
      SDL_Color *col = inSurface->format->palette->colors;
      for(int i=0;i<n;i++)
      {
         mPalette[i].r = col[i].r;
         mPalette[i].g = col[i].g;
         mPalette[i].b = col[i].b;
         mPalette[i].a = 255;
      }
   }

   
   inline XRGB Value()
   {
      int x = mPos.x >> 16;
      int y = mPos.y >> 16;

      MODIFY_EDGE_XY;

      return mPalette[ mBase[ y*mPitch + x ] ];
   }

   inline ARGB Value(int inValue)
   {
      int x = mPos.x >> 16;
      int y = mPos.y >> 16;

      MODIFY_EDGE_XY;

      ARGB result;
      result.ival = mPalette[ mBase[ y*mPitch + x ] ].ival;
      result.a = inValue;
      return result;
   }


   XRGB       mPalette[256];
};

template<typename PIXEL_,int FLAGS_>
struct SurfaceSource32 : public SurfaceSourceBase
{
   enum { HighQuality = FLAGS_ & NME_BMP_LINEAR };
   enum { HasAlpha = PIXEL_::HasAlpha };
   enum { EDGE = FLAGS_ & NME_EDGE_MASK };

   SurfaceSource32(SDL_Surface *inSurface,const Matrix &inMapper)
      : SurfaceSourceBase(inSurface,inMapper)
   {
   }

   inline PIXEL_ Value()
   {
      int x = mPos.x >> 16;
      int y = mPos.y >> 16;

      if ( HighQuality )
      {
         PIXEL_ result;

         PIXEL_ p00,p01,p10,p11;

         GET_PIXEL_POINTERS

         result.r = ( (p00.r*frac_nx + p01.r*frac_x)*frac_ny +
                    (  p10.r*frac_nx + p11.r*frac_x)*frac_y ) >> 24;
         result.g = ( (p00.g*frac_nx + p01.g*frac_x)*frac_ny +
                    (  p10.g*frac_nx + p11.g*frac_x)*frac_y ) >> 24;
         result.b = ( (p00.b*frac_nx + p01.b*frac_x)*frac_ny +
                    (  p10.b*frac_nx + p11.b*frac_x)*frac_y ) >> 24;

         if (PIXEL_::HasAlpha)
         {
            result.a = ( (p00.a*frac_nx + p01.a*frac_x)*frac_ny +
                         (p10.a*frac_nx + p11.a*frac_x)*frac_y ) >> 24;
         }
         return result;
      }
      else
      {
         MODIFY_EDGE_XY;
         return *(PIXEL_ *)( mBase + y*mPitch + x*4);
      }
   }
   inline ARGB Value(Uint8 inAlpha)
   {
      ARGB val;
      val.ival = Value().ival;
      val.a = HasAlpha ? (val.a * inAlpha)>>8 : inAlpha;
      return val;
   }


};






// --- Bitmap renderer --------------------------------------------


bool IsPOW2(int inX)
{
   return (inX & (inX-1)) == 0;
}



template<typename SOURCE_>
PolygonRenderer *TCreateBitmapRenderer( const RenderArgs &inArgs, const SOURCE_ &inSource )
{
   return new SourcePolygonRenderer<SOURCE_>(inArgs,inSource );
}




template<int FLAGS_>
PolygonRenderer *CreateBitmapRendererSource(
                              const RenderArgs &inArgs,
                              SDL_Surface *inSource,
                              const class Matrix &inMapper)
{
    if (inSource->flags & SDL_SRCALPHA)
       return TCreateBitmapRenderer(inArgs, SurfaceSource32<ARGB,FLAGS_>(inSource,inMapper));

    return TCreateBitmapRenderer(inArgs, SurfaceSource32<XRGB,FLAGS_>(inSource,inMapper));
}





template<int EDGES_>
PolygonRenderer *CreateBitmapRendererFlags(
                              const RenderArgs &inArgs,
                              SDL_Surface *inSource,
                              const class Matrix &inMapper)
{
   if (inSource->format->BytesPerPixel==1)
   {
      typedef SurfaceSource8<EDGES_> source;
      return new SourcePolygonRenderer<source>(inArgs,source(inSource,inMapper) );
   }


   if (inArgs.inFlags & NME_BMP_LINEAR)
   {
      return CreateBitmapRendererSource<EDGES_ + NME_BMP_LINEAR>( inArgs,inSource,inMapper);
   }
   else
   {
      return CreateBitmapRendererSource<EDGES_>( inArgs,inSource,inMapper);
   }

}


PolygonRenderer *PolygonRenderer::CreateBitmapRenderer(
                              const RenderArgs &inArgs,
                              SDL_Surface *inSource,
                              const class Matrix &inMapper)
{
   if (inArgs.inN<3)
      return 0;

   int edge = inArgs.inFlags & NME_EDGE_MASK;
   if (edge==NME_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = NME_EDGE_REPEAT_POW2;

   PolygonRenderer *r = 0;

   if (edge == NME_EDGE_REPEAT_POW2) 
       r = CreateBitmapRendererFlags<NME_EDGE_REPEAT_POW2>(inArgs,inSource,inMapper);
   else if (edge == NME_EDGE_REPEAT) 
       r = CreateBitmapRendererFlags<NME_EDGE_REPEAT>(inArgs,inSource,inMapper);
   else if (edge == NME_EDGE_UNCHECKED) 
       r = CreateBitmapRendererFlags<NME_EDGE_UNCHECKED>(inArgs,inSource,inMapper);
   else
       r = CreateBitmapRendererFlags<NME_EDGE_CLAMP>(inArgs,inSource,inMapper);

   return r;
}





