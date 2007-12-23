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
   inline void operator+=(const FImagePoint &inRHS)
      { x+=inRHS.x, y+=inRHS.y; }

   Sint32 x;
   Sint32 y;
};



struct SurfaceSource8
{
   SurfaceSource8(SDL_Surface *inSurface)
   {
      mSurface = inSurface;
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;
      mPalette = inSurface->format->palette->colors;
      r=g=b=a=255;
   }

   inline void SetPos(const FImagePoint &inPos)
   {
      mColor = mPalette[ mBase[ (inPos.y >> 16)*mPitch + (inPos.x>>16) ]  ];
   }

   inline Uint8 GetR() const { return mColor.r; }
   inline Uint8 GetG() const { return mColor.g; }
   inline Uint8 GetB() const { return mColor.b; }
   inline Uint8 GetA() const { return 255; }


   int         mWidth;
   int         mHeight;
   int         mPitch;

   Uint8       r,g,b,a;
   SDL_Surface *mSurface;
   SDL_Color   *mPalette;
   SDL_Color   mColor;

   Uint8       *mBase;
   Uint8       *mPtr;
   Uint8       mIndex;
};

struct SurfaceSource24
{
   SurfaceSource24(SDL_Surface *inSurface)
   {
      mSurface = inSurface;
      mWidth = inSurface->w;
      mHeight = inSurface->h;
      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;
      // TODO:
      mROff = 2;
      mGOff = 1;
      mBOff = 0;
   }

   inline void SetPos(const FImagePoint &inPos)
   {
      mPtr = mBase + (inPos.y >> 16)*mPitch + (inPos.x>>16)*3;
   }

   inline Uint8 GetR() const { return mPtr[mROff]; }
   inline Uint8 GetG() const { return mPtr[mGOff]; }
   inline Uint8 GetB() const { return mPtr[mBOff]; }
   inline Uint8 GetA() const { return 255; }

   
   int         mWidth;
   int         mHeight;

   int         mPitch;

   int         mROff;
   int         mGOff;
   int         mBOff;

   SDL_Surface *mSurface;
   Uint8       *mBase;
   Uint8       *mPtr;

};

struct SurfaceSource32 : public SurfaceSource24
{
   SurfaceSource32(SDL_Surface *inSurface): SurfaceSource24( inSurface )
   {
      mAOff = 3;
   }

   inline void SetPos(const FImagePoint &inPos)
   {
      mPtr = mBase + (inPos.y >> 16)*mPitch + (inPos.x>>16)*4;
   }


   inline Uint8 GetA() const { return mPtr[mAOff]; }

   int         mAOff;
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
