#ifndef PIXEL_H
#define PIXEL_H

#include "SDL.h"
#include "spg/SPriG.h"
#include "Extras.h"


struct ImagePoint
{
   Sint16 x;
   Sint16 y;
};

struct FImagePoint
{
   inline FImagePoint() {}
   inline FImagePoint(Sint32 inX,Sint32 inY) :x(inX), y(inY) {}
   inline FImagePoint(const FImagePoint &inRHS) :x(inRHS.x), y(inRHS.y) {}
   inline FImagePoint(const ImagePoint &inRHS) :
                x(inRHS.x<<16), y(inRHS.y<<16) { }
   
   inline FImagePoint operator-(const FImagePoint inRHS) const
      { return FImagePoint(x-inRHS.x,y-inRHS.y); }
   inline FImagePoint operator+(const FImagePoint inRHS) const
      { return FImagePoint(x+inRHS.x,y+inRHS.y); }
   inline FImagePoint operator*(int inScalar) const
      { return FImagePoint(x*inScalar,y*inScalar); }
   inline FImagePoint operator/(int inDivisor) const
      { return FImagePoint(x/inDivisor,y/inDivisor); }
   inline FImagePoint operator>>(int inShift) const
      { return FImagePoint(x>>inShift,y>>inShift); }
   inline FImagePoint operator<<(int inShift) const
      { return FImagePoint(x<<inShift,y<<inShift); }
   inline void operator+=(const FImagePoint &inRHS)
      { x+=inRHS.x, y+=inRHS.y; }

   Sint32 x;
   Sint32 y;
};



#define GET_PIXEL_POINTERS \
         int frac_x = (inPos.x & 0xff00) >> 8; \
         int frac_nx = 0x100 - frac_x; \
         int frac_y = (inPos.y & 0xffff); \
         int frac_ny = 0x10000 - frac_y; \
 \
         if (EDGE_ == SPG_EDGE_UNCHECKED) \
         { \
            p00 = mBase + (inPos.y >> 16)*mPitch + (inPos.x>>16)*PixelSize; \
            p01 = p00 + PixelSize; \
            p10 = p00 + mPitch; \
            p11 = p10 + PixelSize; \
         } \
         else \
         { \
            if (EDGE_ == SPG_EDGE_CLAMP) \
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
            else if (EDGE_==SPG_EDGE_REPEAT_POW2) \
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
         if (EDGE_ == SPG_EDGE_CLAMP) \
         { \
            if (x<0) x = 0; \
            else if (x>=mWidth) x = mW1; \
 \
            if (y<0) y = 0; \
            else if (y>=mHeight) y = mH1; \
         } \
         else if (EDGE_ == SPG_EDGE_REPEAT_POW2) \
         { \
            x &= mW1; \
            y &= mH1; \
         } \
         else if (EDGE_ == SPG_EDGE_REPEAT) \
         { \
            x = x % mW1; \
            y = y % mH1; \
         }


template<int MODE_,int EDGE_>
struct SurfaceSource8
{
   enum { PixelSize = 1 } ;

   SurfaceSource8(SDL_Surface *inSurface)
   {
      mSurface = inSurface;
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mW1 = mWidth-1;
      mH1 = mHeight-1;
      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;
      mPalette = inSurface->format->palette->colors;
      r=g=b=a=255;
   }

   inline void SetPos(const FImagePoint &inPos)
   {
      int x = inPos.x >> 16;
      int y = inPos.y >> 16;

      if (MODE_ & SPG_HIGH_QUALITY)
      {
         Uint8 *p00,*p01,*p10,*p11;

         GET_PIXEL_POINTERS

         int idx = ((*p00*frac_nx + *p01*frac_x)*frac_ny +
                    (*p10*frac_nx + *p11*frac_x)*frac_y ) >> 24;
         mColor = mPalette[ idx & 0xff ];
      }
      else
      {
         MODIFY_EDGE_XY;

         mColor = mPalette[ mBase[ y*mPitch + x ] ];
      }
   }

   inline Uint8 GetR() const { return mColor.r; }
   inline Uint8 GetG() const { return mColor.g; }
   inline Uint8 GetB() const { return mColor.b; }
   inline Uint8 GetA() const { return 255; }


   int         mWidth;
   int         mHeight;
   int         mPitch;
   int         mW1;
   int         mH1;

   Uint8       r,g,b,a;
   SDL_Surface *mSurface;
   SDL_Color   *mPalette;
   SDL_Color   mColor;

   Uint8       *mBase;
   Uint8       *mPtr;
   Uint8       mIndex;
};

template<int MODE_,int EDGE_,bool DO_ALPHA_ = false>
struct SurfaceSource24
{
   enum { PixelSize = DO_ALPHA_ ? 4 : 3 };

   SurfaceSource24(SDL_Surface *inSurface)
   {
      mSurface = inSurface;
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mW1 = mWidth-1;
      mH1 = mHeight-1;

      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;
      // TODO:
      mROff = 2;
      mGOff = 1;
      mBOff = 0;
      mAOff = 3;

      mA = 255;
   }

   inline void SetPos(const FImagePoint &inPos)
   {
      int x = inPos.x >> 16;
      int y = inPos.y >> 16;

      if (MODE_ & SPG_HIGH_QUALITY)
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

   inline Uint8 GetR() const { return (MODE_&SPG_HIGH_QUALITY)?mR:mPtr[mROff]; }
   inline Uint8 GetG() const { return (MODE_&SPG_HIGH_QUALITY)?mG:mPtr[mGOff]; }
   inline Uint8 GetB() const { return (MODE_&SPG_HIGH_QUALITY)?mB:mPtr[mBOff]; }
   inline Uint8 GetA() const { return 255; }

   
   int         mWidth;
   int         mHeight;
   int         mW1;
   int         mH1;

   int         mPitch;

   int         mROff;
   int         mGOff;
   int         mBOff;
   int         mAOff;


   // High quality values
   Uint8       mR;
   Uint8       mG;
   Uint8       mB;
   Uint8       mA;

   SDL_Surface *mSurface;
   Uint8       *mBase;
   Uint8       *mPtr;

};

template<int MODE_,int EDGE_>
struct SurfaceSource32 : public SurfaceSource24<MODE_,EDGE_,true>
{
   SurfaceSource32(SDL_Surface *inSurface):
      SurfaceSource24( inSurface )
   {
   }

   inline Uint8 GetA() const { return (MODE_&SPG_HIGH_QUALITY)?mA:mPtr[mAOff]; }
};


struct CounstantSource32
{
   inline CounstantSource32() { }
   inline CounstantSource32(int inRGBA) :
      r(inRGBA>>16), g(inRGBA>>8), b(inRGBA), a(inRGBA>>24) { }
   inline CounstantSource32(int inRGB,Uint8 inA) :
      r(inRGB>>16), g(inRGB>>8), b(inRGB), a(inA) { }

   inline void SetPos(const FImagePoint &inPos) { }

   inline Uint8 GetR() const { return r; }
   inline Uint8 GetG() const { return g; }
   inline Uint8 GetB() const { return b; }
   inline Uint8 GetA() const { return a; }

   Uint8 r,g,b,a;
};


struct DestBase
{
   DestBase(SDL_Surface *inSurface,int inPixelSize)
   {
      mSurface = inSurface;
      mMinX = SPG_clip_xmin(mSurface);
      mMinY = SPG_clip_ymin(mSurface);
      mMaxX = SPG_clip_xmax(mSurface);
      mMaxY = SPG_clip_ymax(mSurface);

      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;
      mPixelSize = inPixelSize;
   }

   inline void SetPos(Sint16 inX,Sint16 inY)
   {
      mPtr = mBase + inY*mPitch + inX*mPixelSize;
   }


   int         mMinX;
   int         mMinY;
   int         mMaxX;
   int         mMaxY;
   int         mPitch;
   int         mPixelSize;
   SDL_Surface *mSurface;
   Uint8       *mBase;
   Uint8       *mPtr;
};

struct DestSurface8 : public DestBase
{
   DestSurface8(SDL_Surface *inSurface) : DestBase(inSurface,1)
   {
   }

   template<int MODE_,typename SOURCE_>
   void SetAdvance(SOURCE_ &inSource)
   {
      *mPtr++= SDL_MapRGB(mSurface->format,inSource.GetR(), inSource.GetG(), inSource.GetB());
   }


};

struct DestSurface24 : public DestBase
{
   DestSurface24(SDL_Surface *inSurface,int inPS=3) : DestBase(inSurface,inPS)
   {
      // TODO:
      mROff = 2;
      mGOff = 1;
      mBOff = 0;
   }

   template<int MODE_,typename SOURCE_>
   void SetAdvance(SOURCE_ &inSource)
   {
      if (MODE_ & SPG_ALPHA_BLEND)
      {
         int a = inSource.GetA();
         a+=a>>7;

         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*a)>>8;
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*a)>>8;
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*a)>>8;
      }
      else
      {
         mPtr[mROff] = inSource.GetR();
         mPtr[mGOff] = inSource.GetG();
         mPtr[mBOff] = inSource.GetB();
      }
      mPtr += 3;
   }


   int mROff;
   int mGOff;
   int mBOff;
};

struct DestSurface32 : public DestSurface24
{
   DestSurface32(SDL_Surface *inSurface) : DestSurface24(inSurface,4)
   {
      mAOff = 3;
   }

   template<int MODE_,typename SOURCE_>
   void SetAdvance(SOURCE_ &inSource)
   {
      mPtr[mROff] = inSource.GetR();
      mPtr[mGOff] = inSource.GetG();
      mPtr[mBOff] = inSource.GetB();
      mPtr += 4;
   }


   int mAOff;
};



#endif
