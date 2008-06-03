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
         if (EDGE_ == NME_EDGE_UNCHECKED) \
         { \
            p00 = mBase + (mPos.y >> 16)*mPitch + (mPos.x>>16)*PixelSize; \
            p01 = p00 + PixelSize; \
            p10 = p00 + mPitch; \
            p11 = p10 + PixelSize; \
         } \
         else \
         { \
            if (EDGE_ == NME_EDGE_CLAMP) \
            { \
               int x_step = PixelSize; \
               int y_step = mPitch; \
 \
               if (x<0) {  x_step = x = 0; } \
               else if (x>=mW1) { x_step = 0; x = mW1; } \
 \
               if (y<0) {  y_step = y = 0; } \
               else if (y>=mH1) { y_step = 0; y = mH1; } \
 \
               p00 = mBase + y*mPitch + x*PixelSize; \
               p01 = p00 + x_step; \
               p10 = p00 + y_step; \
               p11 = p10 + x_step; \
            } \
            else if (EDGE_==NME_EDGE_REPEAT_POW2) \
            { \
               Uint8 *p = mBase + (y&mH1)*mPitch; \
 \
               p00 = p+ (x & mW1)*PixelSize; \
               p01 = p+ ((x+1) & mW1)*PixelSize; \
 \
               p = mBase + ( (y+1) &mH1)*mPitch; \
               p10 = p+ (x & mW1)*PixelSize; \
               p11 = p+ ((x+1) & mW1)*PixelSize; \
            } \
            else \
            { \
               int x1 = ((x+1) % mWidth) * PixelSize; \
               x = (x % mWidth)*PixelSize; \
 \
               Uint8 *p = mBase + (y%mHeight)*mPitch; \
 \
               p00 = p+ x; \
               p01 = p+ x1; \
 \
               p = mBase + ( (y+1) % mHeight )*mPitch; \
               p10 = p+ x; \
               p11 = p+ x1; \
            } \
 \
         } 



#define MODIFY_EDGE_XY \
         if (EDGE_ == NME_EDGE_CLAMP) \
         { \
            if (x<0) x = 0; \
            else if (x>=mWidth) x = mW1; \
 \
            if (y<0) y = 0; \
            else if (y>=mHeight) y = mH1; \
         } \
         else if (EDGE_ == NME_EDGE_REPEAT_POW2) \
         { \
            x &= mW1; \
            y &= mH1; \
         } \
         else if (EDGE_ == NME_EDGE_REPEAT) \
         { \
            x = x % mWidth; \
            y = y % mHeight; \
         }


// --- Sources ------------------------------------------------

struct SurfaceSourceBase
{
   enum { AlreadyRoundedAlpha = 0 };

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
      mPos.x = int((mMapper.m00 * x + mMapper.m01*y + mMapper.mtx)*65536);
      mPos.y = int((mMapper.m10 * x + mMapper.m11*y + mMapper.mty)*65536);
   }

   inline void Inc()
   {
      mPos.x += mDPDX.x;
      mPos.y += mDPDX.y;
   }

   inline void Advance(int inX)
   {
      mPos.x += mDPDX.x * inX;
      mPos.y += mDPDX.y * inX;
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


template<int FLAGS_,int EDGE_>
struct SurfaceSource8 : public SurfaceSourceBase
{
   enum { PixelSize = 1 } ;
   enum { AlphaBlend = FLAGS_ & NME_ALPHA_BLEND };
   enum { HighQuality = FLAGS_ & NME_BMP_LINEAR };


   SurfaceSource8(SDL_Surface *inSurface,const Matrix &inMapping)
      : SurfaceSourceBase(inSurface,inMapping)
   {
      mPalette = inSurface->format->palette->colors;
      r=g=b=a=255;
   }

   inline void DoSetPos()
   {
      int x = mPos.x >> 16;
      int y = mPos.y >> 16;

      if ( HighQuality )
      {
         Uint8 *p00,*p01,*p10,*p11;

         GET_PIXEL_POINTERS

         SDL_Color c00 = mPalette[*p00];
         SDL_Color c01 = mPalette[*p01];
         SDL_Color c10 = mPalette[*p10];
         SDL_Color c11 = mPalette[*p11];

         mColor.r = ( (c00.r*frac_nx + c01.r*frac_x)*frac_ny +
                    (  c10.r*frac_nx + c11.r*frac_x)*frac_y ) >> 24;
         mColor.g = ( (c00.g*frac_nx + c01.g*frac_x)*frac_ny +
                    (  c10.g*frac_nx + c11.g*frac_x)*frac_y ) >> 24;
         mColor.b = ( (c00.b*frac_nx + c01.b*frac_x)*frac_ny +
                    (  c10.b*frac_nx + c11.b*frac_x)*frac_y ) >> 24;

      }
      else
      {
         MODIFY_EDGE_XY;

         mColor = mPalette[ mBase[ y*mPitch + x ] ];
      }
   }

   inline void SetPos(int inX,int inY)
   {
      SurfaceSourceBase::SetPos(inX,inY);
      DoSetPos();
   }
   inline void Inc()
   {
      SurfaceSourceBase::Inc();
      DoSetPos();
   }
   inline void Advance(int inX)
   {
      SurfaceSourceBase::Advance(inX);
      DoSetPos();
   }



   inline Uint8 GetR() const { return mColor.r; }
   inline Uint8 GetG() const { return mColor.g; }
   inline Uint8 GetB() const { return mColor.b; }
   inline Uint8 GetA() const { return 255; }


   Uint8       r,g,b,a;
   SDL_Color   *mPalette;
   SDL_Color   mColor;

   Uint8       mIndex;
};

template<int FLAGS_,int EDGE_,bool DO_ALPHA_ = false>
struct SurfaceSource24 : public SurfaceSourceBase
{
   enum { PixelSize = DO_ALPHA_ ? 4 : 3 };
   enum { AlphaBlend = FLAGS_ & NME_ALPHA_BLEND };
   enum { HighQuality = FLAGS_ & NME_BMP_LINEAR };

   SurfaceSource24(SDL_Surface *inSurface,const Matrix &inMapper)
      : SurfaceSourceBase(inSurface,inMapper)
   {
      // TODO:
      mROff = mSurface->format->Rshift/8;
      mGOff = mSurface->format->Gshift/8;
      mBOff = mSurface->format->Bshift/8;

      mAOff = 3;

      mA = 255;
   }

   inline void DoSetPos()
   {
      int x = mPos.x >> 16;
      int y = mPos.y >> 16;

      if ( HighQuality )
      {
         Uint8 *p00,*p01,*p10,*p11;

         GET_PIXEL_POINTERS

         mR = ( (p00[mROff]*frac_nx + p01[mROff]*frac_x)*frac_ny +
                (p10[mROff]*frac_nx + p11[mROff]*frac_x)*frac_y ) >> 24;
         mG = ( (p00[mGOff]*frac_nx + p01[mGOff]*frac_x)*frac_ny +
                (p10[mGOff]*frac_nx + p11[mGOff]*frac_x)*frac_y ) >> 24;
         mB = ( (p00[mBOff]*frac_nx + p01[mBOff]*frac_x)*frac_ny +
                (p10[mBOff]*frac_nx + p11[mBOff]*frac_x)*frac_y ) >> 24;
         if (DO_ALPHA_)
         {
            mA = ( (p00[mAOff]*frac_nx + p01[mAOff]*frac_x)*frac_ny +
                   (p10[mAOff]*frac_nx + p11[mAOff]*frac_x)*frac_y ) >> 24;
         }
      }
      else
      {
         MODIFY_EDGE_XY;
         mPtr = mBase + y*mPitch + x*PixelSize;
      }
   }
   inline void SetPos(int inX,int inY)
   {
      SurfaceSourceBase::SetPos(inX,inY);
      DoSetPos();
   }
   inline void Inc()
   {
      SurfaceSourceBase::Inc();
      DoSetPos();
   }
   inline void Advance(int inX)
   {
      SurfaceSourceBase::Advance(inX);
      DoSetPos();
   }



   inline Uint8 GetR() const { return HighQuality ? mR:mPtr[mROff]; }
   inline Uint8 GetG() const { return HighQuality ? mG:mPtr[mGOff]; }
   inline Uint8 GetB() const { return HighQuality ? mB:mPtr[mBOff]; }
   inline Uint8 GetA() const { return 255; }

   
   int         mROff;
   int         mGOff;
   int         mBOff;
   int         mAOff;


   // High quality values
   Uint8       mR;
   Uint8       mG;
   Uint8       mB;
   Uint8       mA;
};

template<int FLAGS_,int EDGE_>
struct SurfaceSource32 : public SurfaceSource24<FLAGS_,EDGE_,true>
{
   typedef SurfaceSource24<FLAGS_,EDGE_,true> Base;

   enum { AlphaBlend = FLAGS_ & NME_ALPHA_BLEND };
   enum { HighQuality = FLAGS_ & NME_BMP_LINEAR };

   SurfaceSource32(SDL_Surface *inSurface,const Matrix &inMapper):
      Base( inSurface, inMapper )
   {
   }

   inline Uint8 GetA() const
      { return HighQuality ?Base::mA : Base::mPtr[Base::mAOff]; }
};






// --- Bitmap renderer --------------------------------------------


bool IsPOW2(int inX)
{
   return (inX & (inX-1)) == 0;
}



template<typename AA_,typename SOURCE_>
PolygonRenderer *CreateBitmapRenderer( const RenderArgs &inArgs,
                              const SOURCE_ &inSource )
{
   return new SourcePolygonRenderer<AA_,SOURCE_>(inArgs,inSource );
}



template<typename AA_,int FLAGS_>
PolygonRenderer *CreateBitmapRendererSource(
                              const RenderArgs &inArgs,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource)
{
   int edge = inArgs.inFlags & NME_EDGE_MASK;
   if (edge==NME_EDGE_REPEAT && IsPOW2(inSource->w) && IsPOW2(inSource->h) )
      edge = NME_EDGE_REPEAT_POW2;

   PolygonRenderer *r = 0;

#define SOURCE_EDGE(source) \
     if (edge == NME_EDGE_REPEAT_POW2) \
       r = CreateBitmapRenderer<AA_>( \
          inArgs, \
          source<FLAGS_,NME_EDGE_REPEAT_POW2>(inSource,inMapper));  \
     else if (edge == NME_EDGE_REPEAT) \
       r = CreateBitmapRenderer<AA_>( \
          inArgs, \
          source<FLAGS_,NME_EDGE_REPEAT>(inSource,inMapper));  \
     else if (edge == NME_EDGE_UNCHECKED) \
       r = CreateBitmapRenderer<AA_>( \
          inArgs, \
          source<FLAGS_,NME_EDGE_UNCHECKED>(inSource,inMapper));  \
     else \
       r = CreateBitmapRenderer<AA_>( \
          inArgs, \
          source<FLAGS_,NME_EDGE_CLAMP>(inSource,inMapper));


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
PolygonRenderer *AACreateBitmapRendererSource(
                              const RenderArgs &inArgs,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource )
{
   if (inArgs.inFlags & NME_BMP_LINEAR)
   {
      if (inArgs.inFlags & NME_ALPHA_BLEND)
          return CreateBitmapRendererSource
              <AA_,NME_BMP_LINEAR+NME_ALPHA_BLEND>(
                inArgs,inMapper,inSource);
      else
          return CreateBitmapRendererSource<AA_,NME_BMP_LINEAR>(
                inArgs,inMapper,inSource);
   }
   else
   {
      if (inArgs.inFlags & NME_ALPHA_BLEND)
          return CreateBitmapRendererSource<AA_,NME_ALPHA_BLEND>(
                inArgs,inMapper,inSource);
      else
          return CreateBitmapRendererSource<AA_,0>(
                inArgs,inMapper,inSource);

   }
}



PolygonRenderer *PolygonRenderer::CreateBitmapRenderer(
                              const RenderArgs &inArgs,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource)
{
   if (inArgs.inN<3)
      return 0;

   if (inArgs.inFlags & NME_HIGH_QUALITY)
   {
      AA4x::Init();
      return AACreateBitmapRendererSource<AA4x>
               (inArgs, inMapper,inSource);
   }
   else
   {
      return AACreateBitmapRendererSource<AA0x>
               (inArgs, inMapper,inSource);
   }
}

