#include "Renderer.h"
#include "RenderPolygon.h"
#include "TriangleRenderer.h"
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

template<bool PERSPECTIVE>
struct SurfaceSourceBase
{
   SurfaceSourceBase(SDL_Surface *inSurface,const Matrix &inMapper) :
     mSurface(inSurface), mMapper(inMapper)
   {
      Init();
      UpdateMapping();
   }
   SurfaceSourceBase(SDL_Surface *inSurface) : mSurface(inSurface)
   {
      Init();
   }
   void Init()
   {
      mWidth = mSurface->w;
      mHeight = mSurface->h;
      mW1 = mWidth-1;
      mH1 = mHeight-1;
      mBase = (Uint8 *)mSurface->pixels;
      mPtr = mBase;
      mPitch = mSurface->pitch;
   }

   void SetMapping(const TriPoint &inP0, const TriPoint &inP1, const TriPoint &inP2,
                          double inTX, double inTY)
   {

      // mMapper provides the mapping for "SetPos", which takes destination pixels and converts
      //  them to texture coordinates.  The destination pixels will be the mPos16 >> 16

      double x0 = inP0.mPos16.x * (1.0/65536.0);
      double y0 = inP0.mPos16.y * (1.0/65536.0);
      double x1 = inP1.mPos16.x * (1.0/65536.0);
      double y1 = inP1.mPos16.y * (1.0/65536.0);
      double x2 = inP2.mPos16.x * (1.0/65536.0);
      double y2 = inP2.mPos16.y * (1.0/65536.0);

      // mMapper.m00 * Xi + mMapper.m01*Yi + mMapper.mtx = TexX.i
      // (i=1) - (i=0),  (i-2)-(i-0)
      double dx1 = x1-x0;
      double dy1 = y1-y0;
      double dx2 = x2-x0;
      double dy2 = y2-y0;
      // m00*dx1 + m01*dy1 = du1
      // m00*dx2 + m01*dy2 = du2
      double det = dx1*dy2 - dx2*dy1;
      if (det==0.0)
      {
         mMapper.m00 = mMapper.m01 = mMapper.m10 = mMapper.m11 = 0.0;
         mMapper.mtx = inP0.mU;
         mMapper.mty = inP0.mV;
         if (PERSPECTIVE)
            mMapper.mty = 1;
      }
      else
      {
         det =1.0/det;
         double du1,du2,dv1,dv2;
         double p0uw,p0vw;
         if (PERSPECTIVE)
         {
            p0uw = inP0.mU*inP0.mW;
            du1 = inP1.mU*inP1.mW - p0uw;
            du2 = inP2.mU*inP2.mW - p0uw;
            p0vw = inP0.mV*inP0.mW;
            dv1 = inP1.mV*inP1.mW - p0vw;
            dv2 = inP2.mV*inP2.mW - p0vw;
         }
         else
         {
            du1 = inP1.mU - inP0.mU;
            du2 = inP2.mU - inP0.mU;
            dv1 = inP1.mV - inP0.mV;
            dv2 = inP2.mV - inP0.mV;
         }

         mMapper.m00 = (du1*dy2 - du2*dy1)*det;
         mMapper.m10 = (dv1*dy2 - dv2*dy1)*det;


         double dw1,dw2;
         if (PERSPECTIVE)
         {
            dw1 = inP1.mW - inP0.mW;
            dw2 = inP2.mW - inP0.mW;
            m30 = (dw1*dy2 - dw2*dy1)*det;
         }
         if (dy1!=0)
         {
            if (PERSPECTIVE)
               m31 = (dw1-m30*dx1)/dy1;
            mMapper.m01 = (du1-mMapper.m00*dx1)/dy1;
            mMapper.m11 = (dv1-mMapper.m10*dx1)/dy1;
         }
         else
         {
            if (PERSPECTIVE)
               m31 = 1;
            mMapper.m01 = 0;
            mMapper.m11 = 0;
         }

         x0 += inTX;
         y0 += inTY;
         if (PERSPECTIVE)
         {
            mMapper.mtx = p0uw - mMapper.m00*x0 - mMapper.m01*y0;
            mMapper.mty = p0vw - mMapper.m10*x0 - mMapper.m11*y0;
            mtw = inP0.mW - m30*x0 - m31*y0;

            // Verify texture coords at corners ...
            /*
            mTX = mMapper.m00*x0 + mMapper.m01*y0 + mMapper.mtx;
            mTY = mMapper.m10*x0 + mMapper.m11*y0 + mMapper.mty;
            mTW =         m30*x0 +         m31*y0 +         mtw;

            if (fabs(mTX/mTW - inP0.mU)>0.1)
               *(int *)0=0;
            */
         }
         else
         {
            mMapper.mtx = inP0.mU - mMapper.m00*x0 - mMapper.m01*y0;
            mMapper.mty = inP0.mV - mMapper.m10*x0 - mMapper.m11*y0;
         }
      }
      UpdateMapping();
   }

   inline void UpdateMapping()
   {
      if (!PERSPECTIVE)
      {
         mDPDX.x = int((mMapper.m00)*65536);
         mDPDX.y = int((mMapper.m10)*65536);
      }
   }


   inline void SetPos(int inX,int inY)
   {
      if (PERSPECTIVE)
      {
         double x = inX;
         double y = inY;
         mTX = mMapper.m00*x + mMapper.m01*y + mMapper.mtx;
         mTY = mMapper.m10*x + mMapper.m11*y + mMapper.mty;
         mTW =         m30*x +         m31*y +         mtw;
      }
      else
      {
         double x = inX+0.5;
         double y = inY+0.5;
         mPos.x = int((mMapper.m00 * x + mMapper.m01*y + mMapper.mtx)*65536) - 0x8000;
         mPos.y = int((mMapper.m10 * x + mMapper.m11*y + mMapper.mty)*65536) - 0x8000;
      }
   }

   inline void Inc()
   {
      if (PERSPECTIVE)
      {
         mTX += mMapper.m00;
         mTY += mMapper.m10;
         mTW += m30;
      }
      else
      {
         mPos.x += mDPDX.x;
         mPos.y += mDPDX.y;
      }
   }



   PointF16 mPos;
   PointF16 mDPDX;
   double   mTX,mTY,mTW;

   bool        mMatrixMapping;
   Matrix      mMapper;
   double      m30,m31,mtw;

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
struct SurfaceSource8 : public SurfaceSourceBase<false>
{
   enum { EDGE = EDGE_ };

   SurfaceSource8(SDL_Surface *inSurface,const Matrix &inMapping)
      : SurfaceSourceBase(inSurface,inMapping)
   {
      Init();
   }


   SurfaceSource8(SDL_Surface *inSurface) : SurfaceSourceBase(inSurface)
   {
      Init();
   }


   void Init()
   {
      int n  = mSurface->format->palette->ncolors;
      SDL_Color *col = mSurface->format->palette->colors;
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

template<typename PIXEL_,int FLAGS_,bool PERSPECTIVE>
struct SurfaceSource32 : public SurfaceSourceBase<PERSPECTIVE>
{
   enum { HighQuality = FLAGS_ & NME_BMP_LINEAR };
   enum { HasAlpha = PIXEL_::HasAlpha };
   enum { EDGE = FLAGS_ & NME_EDGE_MASK };

   SurfaceSource32(SDL_Surface *inSurface,const Matrix &inMapper)
      : SurfaceSourceBase(inSurface,inMapper)
   {
   }

   SurfaceSource32(SDL_Surface *inSurface) : SurfaceSourceBase(inSurface)
   {
   }


   inline PIXEL_ Value()
   {
      if (PERSPECTIVE)
      {
         double w = 65536.0/mTW;
         mPos.x = (int)(mTX*w);
         mPos.y = (int)(mTY*w);
      }
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
         else
            result.a = 255;
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
       return TCreateBitmapRenderer(inArgs, SurfaceSource32<ARGB,FLAGS_,false>(inSource,inMapper));

    return TCreateBitmapRenderer(inArgs, SurfaceSource32<XRGB,FLAGS_,false>(inSource,inMapper));
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



// --- Triangles ---------------------------------------------------------------



void SetTextureMapping( Matrix &outMatrix, const TriPoint &inP0,
                                           const TriPoint &inP1,
                                           const TriPoint &inP2,
                                           int inTX, int inTY)
{

}


template<typename SOURCE_>
PolygonRenderer *TCreateBitmapTrianglesRenderer(
                              const TriPoints &inPoints,
                              const Tris &inTriangles,
                              const SOURCE_ &inSource )
{
   return new TTriangleRenderer<SOURCE_,true>(inPoints,inTriangles,inSource );
}




template<int FLAGS_,bool PERSPECTIVE>
PolygonRenderer *CreateBitmapTrianglesRendererSource(
                              const TriPoints &inPoints,
                              const Tris &inTriangles,
                              SDL_Surface *inSource)
{
    if (inSource->flags & SDL_SRCALPHA)
       return TCreateBitmapTrianglesRenderer(inPoints,inTriangles, SurfaceSource32<ARGB,FLAGS_,PERSPECTIVE>(inSource));

    return TCreateBitmapTrianglesRenderer(inPoints,inTriangles, SurfaceSource32<XRGB,FLAGS_,PERSPECTIVE>(inSource));
}




template<int EDGES_>
PolygonRenderer *CreateBitmapTrianglesFlags(
                              const TriPoints &inPoints,
                              const Tris &inTriangles,
                              SDL_Surface *inSource,
                              int inFlags)
{
   if (inFlags & NME_TEX_PERSPECTIVE)
   {
      if (inFlags & NME_BMP_LINEAR)
      {
         return CreateBitmapTrianglesRendererSource<EDGES_ + NME_BMP_LINEAR,true>( inPoints,inTriangles,inSource);
      }
      else
      {
         return CreateBitmapTrianglesRendererSource<EDGES_,true>( inPoints,inTriangles,inSource);
      }
   }
   else
   {
      if (inFlags & NME_BMP_LINEAR)
      {
         return CreateBitmapTrianglesRendererSource<EDGES_ + NME_BMP_LINEAR,false>( inPoints,inTriangles,inSource);
      }
      else
      {
         return CreateBitmapTrianglesRendererSource<EDGES_,false>( inPoints,inTriangles,inSource);
      }
   }

}



PolygonRenderer *PolygonRenderer::CreateBitmapTriangles(
                              const TriPoints &inPoints,
                              const Tris &inTriangles,
                              SDL_Surface *inSource, unsigned int inFlags)
{
   if (inTriangles.empty())
      return 0;

   int edge = inFlags & NME_EDGE_MASK;
   if (edge==NME_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = NME_EDGE_REPEAT_POW2;

   PolygonRenderer *r = 0;

   if (edge == NME_EDGE_REPEAT_POW2) 
       r = CreateBitmapTrianglesFlags<NME_EDGE_REPEAT_POW2>(inPoints,inTriangles,inSource,inFlags);
   else if (edge == NME_EDGE_REPEAT) 
       r = CreateBitmapTrianglesFlags<NME_EDGE_REPEAT>(inPoints,inTriangles,inSource,inFlags);
   else if (edge == NME_EDGE_UNCHECKED) 
       r = CreateBitmapTrianglesFlags<NME_EDGE_UNCHECKED>(inPoints,inTriangles,inSource,inFlags);
   else
       r = CreateBitmapTrianglesFlags<NME_EDGE_CLAMP>(inPoints,inTriangles,inSource,inFlags);

   return r;



   return 0;
}



