#ifndef PIXEL_H
#define PIXEL_H

#include "Renderer.h"
#include "../Matrix.h"

extern int sgC0Shift;
extern int sgC1Shift;
extern int sgC2Shift;
extern bool sgC0IsRed;
 
struct XRGB
{
   enum { HasAlpha = 0 };
   inline void Set(int inVal) { ival = inVal;  }
   inline void SetRGB(int inVal)
   {
      c0 = (inVal>>sgC0Shift) & 0xff;
      c1 = (inVal>>sgC1Shift) & 0xff;
      c2 = (inVal>>sgC2Shift) & 0xff;
   }
   inline int red() const { return sgC0IsRed ? c0 : c2; }
   inline int green() const { return c0; }
   inline int blue() const { return sgC0IsRed ? c2 : c0; }

   template<typename SRC_>
   inline void Blend(const SRC_ &inVal)
   {
      int A = inVal.a;
      if (A>5)
      {
         if (A<250)
         {
             c0 += ((inVal.c0-c0) * A) >> 8;
             c1 += ((inVal.c1-c1) * A) >> 8;
             c2 += ((inVal.c2-c2) * A) >> 8;
         }
         else
            ival = inVal.ival;
      }
   }

   union
   {
      struct { Uint8 c0,c1,c2,a; };
      int  ival;
   };
};


// This matches the GL_RGBA format.

struct ARGB
{
   enum { HasAlpha = 1 };

   inline void Set(int inVal) { ival = inVal; }

   inline void SetRGB(int inVal)
   {
      c0 = (inVal>>sgC0Shift) & 0xff;
      c1 = (inVal>>sgC1Shift) & 0xff;
      c2 = (inVal>>sgC2Shift) & 0xff;
   }

   template<typename SRC_>
   inline void Blend(const SRC_ &inVal)
   {
      if (SRC_::HasAlpha)
      {
         int A = inVal.a;
         if (A>5)
         {
            // Are we practically blank ?
            if (a<5)
            {
               ival = inVal.ival;
            }
            // Ok, merge alphas ...
            else
            {
               int alpha16 = ((a + A)<<8) - a*A;
               int f = (255-A) * a;
               A<<=8;
               c0 = (A*inVal.c0 + f*c0)/alpha16;
               c1 = (A*inVal.c1 + f*c1)/alpha16;
               c2 = (A*inVal.c2 + f*c2)/alpha16;
               a = alpha16>>8;
            }
         }
      }
      else
      {
         ival = inVal.ival | 0xff000000;
      }
   }


   union
   {
      struct { Uint8 c0,c1,c2,a; };
      int  ival;
   };
};




// --- Destinations -----------------------------------------------------


struct DestBase
{
   DestBase(SDL_Surface *inSurface)
   {
      mSurface = inSurface;
      mMinX = NME_clip_xmin(mSurface);
      mMinY = NME_clip_ymin(mSurface);
      mMaxX = NME_clip_xmax(mSurface);
      mMaxY = NME_clip_ymax(mSurface);

      mBase = (Uint8 *)inSurface->pixels;
      mPitch = inSurface->pitch;
      mPixelSize = inSurface->format->BytesPerPixel;
   }

   inline void SetRow(Sint16 inY)
   {
      mRowBase = mBase + inY*mPitch;
   }


   int         mMinX;
   int         mMinY;
   int         mMaxX;
   int         mMaxY;
   int         mPitch;
   int         mPixelSize;
   SDL_Surface *mSurface;
   Uint8       *mBase;
   Uint8       *mRowBase;
};


// 8 or 24 bits ...
struct DestSurfaceFallback : public DestBase
{
   DestSurfaceFallback(SDL_Surface *inSurface) : DestBase(inSurface)
   {
      mFormat = inSurface->format;
   }

   inline void SetX(Sint16 inX)
   {
      mPtr = mRowBase + inX*mPixelSize;
   }

   template<typename SOURCE_>
   void SetIncBlend(const SOURCE_ &inRGB)
   {
      // Work out if the code gets run ...
      *(int *)0=0;
      if (mPixelSize==1)
        *mPtr++ = SDL_MapRGB(mSurface->format,inRGB.c0,inRGB.c1,inRGB.c2);
      else
      {
        *mPtr++ = inRGB.c2;
        *mPtr++ = inRGB.c1;
        *mPtr++ = inRGB.c0;
      }
   }


   SDL_PixelFormat *mFormat;
   Uint8 *mPtr;
   int c0,c1,c2;
};

// 32 bits, either ARGB or XRGB
template<typename PIXEL_>
struct DestSurface32 : public DestBase
{
   DestSurface32(SDL_Surface *inSurface) : DestBase(inSurface)
   {
   }

   template<typename SOURCE_>
   void SetIncBlend(const SOURCE_ &inSource)
   {
      if (SOURCE_::HasAlpha)
         mPtr->Blend(inSource);
      else if (PIXEL_::HasAlpha)
         mPtr->Set(inSource.ival | 0xff000000);
      else
         mPtr->Set(inSource.ival);
      mPtr++;
   }

   inline void SetX(Sint16 inX)
   {
      mPtr = (PIXEL_ *)(mRowBase + inX*mPixelSize);
   }


   PIXEL_ *mPtr;

};



#endif
