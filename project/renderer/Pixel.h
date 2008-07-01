#ifndef PIXEL_H
#define PIXEL_H

#include "Renderer.h"
#include "../Matrix.h"


// --- Destinations -----------------------------------------------------


struct DestBase
{
   DestBase(SDL_Surface *inSurface,int inPixelSize)
   {
      mSurface = inSurface;
      mMinX = NME_clip_xmin(mSurface);
      mMinY = NME_clip_ymin(mSurface);
      mMaxX = NME_clip_xmax(mSurface);
      mMaxY = NME_clip_ymax(mSurface);

      mBase = (Uint8 *)inSurface->pixels;
      mPtr = mBase;
      mPitch = inSurface->pitch;
      mPixelSize = inPixelSize;
   }

   inline void SetRow(Sint16 inY)
   {
      mRowBase = mBase + inY*mPitch;
   }

   inline void SetX(Sint16 inX)
   {
      mPtr = mRowBase + inX*mPixelSize;
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
   Uint8       *mPtr;
};

struct DestSurface8 : public DestBase
{
   DestSurface8(SDL_Surface *inSurface) : DestBase(inSurface,1)
   {
   }

   template<typename SOURCE_>
   void SetInc(SOURCE_ &inSource)
   {
      *mPtr++= SDL_MapRGB(mSurface->format,inSource.GetR(), inSource.GetG(), inSource.GetB());
   }

   template<typename SOURCE_>
   void SetIncBlend(SOURCE_ &inSource,int inAlpha)
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

   template<typename SOURCE_>
   void SetInc(SOURCE_ &inSource)
   {
      if (SOURCE_::AlphaBlend)
      {
         int a = inSource.GetA();
         if (!SOURCE_::AlreadyRoundedAlpha)
            a += (a>>7);

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

   template<typename SOURCE_>
   void SetIncBlend(SOURCE_ &inSource,int inAlpha)
   {
      if (SOURCE_::AlphaBlend)
      {
         int a = inSource.GetA();
         if (!SOURCE_::AlreadyRoundedAlpha)
            a += (a>>7);
         a*= inAlpha;

         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*a)>>16;
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*a)>>16;
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*a)>>16;
      }
      else
      {
         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*inAlpha)>>8;
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*inAlpha)>>8;
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*inAlpha)>>8;
      }
      mPtr += 3;
   }


   int mROff;
   int mGOff;
   int mBOff;
};

struct DestSurface32 : public DestSurface24
{
   int mAOff;

   DestSurface32(SDL_Surface *inSurface) : DestSurface24(inSurface,4)
   {
      mAOff = 3;
   }

   template<typename SOURCE_>
   void SetInc(SOURCE_ &inSource)
   {
      if (SOURCE_::AlphaBlend)
      {
         int a = inSource.GetA();
         if (!SOURCE_::AlreadyRoundedAlpha)
            a += (a>>7);

         // todo: do this properly
         mPtr[mAOff] = a-1;

         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*a)>>8;
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*a)>>8;
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*a)>>8;
      }
      else
      {
         mPtr[mROff] = inSource.GetR();
         mPtr[mGOff] = inSource.GetG();
         mPtr[mBOff] = inSource.GetB();
         mPtr[mAOff] = 255;
      }
      mPtr += 4;
   }


   template<typename SOURCE_>
   void SetIncBlend(SOURCE_ &inSource,int inAlpha)
   {
      if (SOURCE_::AlphaBlend)
      {
         int a = inSource.GetA();
         if (!SOURCE_::AlreadyRoundedAlpha)
            a += (a>>7);

         // todo: do this properly
         mPtr[mAOff] = a-1;

         a*=inAlpha;

         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*a)>>16;
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*a)>>16;
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*a)>>16;
      }
      else
      {
         // todo: do this properly
         mPtr[mAOff] = inAlpha-1;

         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*inAlpha)>>8;
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*inAlpha)>>8;
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*inAlpha)>>8;
      }

      mPtr += 4;
   }


};



#endif
