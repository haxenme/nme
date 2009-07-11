#ifndef PIXEL_H
#define PIXEL_H

#include "Renderer.h"
#include "../Matrix.h"

struct XRGB
{
   enum { HasAlpha = 0 };
   inline void Set(int inVal) { ival = inVal;  }

   template<typename SRC_>
   inline void Blend(const SRC_ &inVal)
   {
      int A = inVal.a;
      if (A>5)
      {
         if (A<250)
         {
             r += ((inVal.r-r) * A) >> 8;
             g += ((inVal.g-g) * A) >> 8;
             b += ((inVal.b-b) * A) >> 8;
         }
         else
            ival = inVal.ival;
      }
   }

   union
   {
      struct { Uint8 r,g,b,a; };
      int  ival;
   };
};


// This matches the GL_RGBA format.

struct ARGB
{
   enum { HasAlpha = 1 };

   inline void Set(int inVal) { ival = inVal; }

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
               int c1 = (255-A) * a;
               A<<=8;
               r = (A*inVal.r + c1*r)/alpha16;
               g = (A*inVal.g + c1*g)/alpha16;
               b = (A*inVal.b + c1*b)/alpha16;
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
      struct { Uint8 r,g,b,a; };
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
        *mPtr++ = SDL_MapRGB(mSurface->format,inRGB.r,inRGB.g,inRGB.b);
      else
      {
        *mPtr++ = inRGB.b;
        *mPtr++ = inRGB.g;
        *mPtr++ = inRGB.r;
      }
   }


   SDL_PixelFormat *mFormat;
   Uint8 *mPtr;
   int r,g,b;
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
