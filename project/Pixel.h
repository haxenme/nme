#ifndef PIXEL_H
#define PIXEL_H

#include "SDL.h"
#include "spg/SPriG.h"
#include "Extras.h"
#include "Matrix.h"


struct ImagePoint
{
   Sint16 x;
   Sint16 y;
};

struct FImagePoint2D
{
   inline FImagePoint2D() {}
   inline FImagePoint2D(Sint32 inX,Sint32 inY) :x(inX), y(inY) {}
   inline FImagePoint2D(const FImagePoint2D &inRHS) :x(inRHS.x), y(inRHS.y) {}
   inline FImagePoint2D(const ImagePoint &inRHS) :
                x(inRHS.x<<16), y(inRHS.y<<16) { }
   
   inline FImagePoint2D operator-(const FImagePoint2D inRHS) const
      { return FImagePoint2D(x-inRHS.x,y-inRHS.y); }
   inline FImagePoint2D operator+(const FImagePoint2D inRHS) const
      { return FImagePoint2D(x+inRHS.x,y+inRHS.y); }
   inline FImagePoint2D operator*(int inScalar) const
      { return FImagePoint2D(x*inScalar,y*inScalar); }
   inline FImagePoint2D operator/(int inDivisor) const
      { return FImagePoint2D(x/inDivisor,y/inDivisor); }
   inline FImagePoint2D operator>>(int inShift) const
      { return FImagePoint2D(x>>inShift,y>>inShift); }
   inline FImagePoint2D operator<<(int inShift) const
      { return FImagePoint2D(x<<inShift,y<<inShift); }
   inline void operator+=(const FImagePoint2D &inRHS)
      { x+=inRHS.x, y+=inRHS.y; }

   Sint32 x;
   Sint32 y;
};




#define GET_PIXEL_POINTERS \
         int frac_x = (mPos.x & 0xff00) >> 8; \
         int frac_nx = 0x100 - frac_x; \
         int frac_y = (mPos.y & 0xffff); \
         int frac_ny = 0x10000 - frac_y; \
 \
         if (EDGE_ == SPG_EDGE_UNCHECKED) \
         { \
            p00 = mBase + (mPos.y >> 16)*mPitch + (mPos.x>>16)*PixelSize; \
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
      mPos.x = int((mMapper.m00 * inX + mMapper.m01*inY + mMapper.mtx)*65536);
      mPos.y = int((mMapper.m10 * inX + mMapper.m11*inY + mMapper.mty)*65536);
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


   FImagePoint2D mPos;
   FImagePoint2D mDPDX;

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
   enum { AlphaBlend = FLAGS_ & SPG_ALPHA_BLEND };


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

      if (FLAGS_ & SPG_HIGH_QUALITY)
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
   typedef FImagePoint2D iterator;
   enum { PixelSize = DO_ALPHA_ ? 4 : 3 };
   enum { AlphaBlend = FLAGS_ & SPG_ALPHA_BLEND };

   SurfaceSource24(SDL_Surface *inSurface,const Matrix &inMapper)
      : SurfaceSourceBase(inSurface,inMapper)
   {
      // TODO:
      mROff = 2;
      mGOff = 1;
      mBOff = 0;
      mAOff = 3;

      mA = 255;
   }

   inline void DoSetPos()
   {
      int x = mPos.x >> 16;
      int y = mPos.y >> 16;

      if (FLAGS_ & SPG_HIGH_QUALITY)
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



   inline Uint8 GetR() const { return (FLAGS_&SPG_HIGH_QUALITY)?mR:mPtr[mROff]; }
   inline Uint8 GetG() const { return (FLAGS_&SPG_HIGH_QUALITY)?mG:mPtr[mGOff]; }
   inline Uint8 GetB() const { return (FLAGS_&SPG_HIGH_QUALITY)?mB:mPtr[mBOff]; }
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
   enum { AlphaBlend = FLAGS_ & SPG_ALPHA_BLEND };

   SurfaceSource32(SDL_Surface *inSurface,const Matrix &inMapper):
      SurfaceSource24( inSurface, inMapper )
   {
   }

   inline Uint8 GetA() const { return (FLAGS_&SPG_HIGH_QUALITY)?mA:mPtr[mAOff]; }
};


template<int FLAGS_>
struct ConstantSource32
{
   enum { AlreadyRoundedAlpha = 1 };
   enum { AlphaBlend = FLAGS_ & SPG_ALPHA_BLEND };

   inline ConstantSource32() { }

   inline ConstantSource32(int inRGB,double inA) :
      r(inRGB>>16), g(inRGB>>8), b(inRGB)
   {
      int val = (int)(inA*255);
      a =val<0 ? 0 : val>255 ? 255 : val;
      a+= a>>7;
   }

   inline void SetPos(int inX,int inY) { }
   inline void Inc() { }
   inline void Advance(int inX) { }


   inline Uint8 GetR() const { return r; }
   inline Uint8 GetG() const { return g; }
   inline Uint8 GetB() const { return b; }
   inline Uint8 GetA() const { return a; }

   Uint8 r,g,b;
   int   a;
};


// --- Destinations -----------------------------------------------------


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

   template<typename SOURCE_>
   void SetInc(SOURCE_ &inSource)
   {
      *mPtr++= SDL_MapRGB(mSurface->format,inSource.GetR(), inSource.GetG(), inSource.GetB());
   }
   inline void Advance(int inX) { mPtr += inX; }

   template<int ALPHA_BITS_,typename SOURCE_>
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

   template<int ALPHA_BITS_,typename SOURCE_>
   void SetIncBlend(SOURCE_ &inSource,int inAlpha)
   {
      if (SOURCE_::AlphaBlend)
      {
         int a = inSource.GetA();
         a+=a>>7;
         a*=inAlpha;

         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*a)>>(8+ALPHA_BITS_);
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*a)>>(8+ALPHA_BITS_);
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*a)>>(8+ALPHA_BITS_);
      }
      else
      {
         mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*inAlpha)>>(ALPHA_BITS_);
         mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*inAlpha)>>(ALPHA_BITS_);
         mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*inAlpha)>>(ALPHA_BITS_);
      }
      mPtr += 3;
   }

   inline void Advance(int inX) { mPtr += inX*3; }



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

   template<typename SOURCE_>
   void SetInc(SOURCE_ &inSource)
   {
      // todo - if (SOURCE_::AlphaBlend)
      mPtr[mROff] = inSource.GetR();
      mPtr[mGOff] = inSource.GetG();
      mPtr[mBOff] = inSource.GetB();
      mPtr += 4;
   }

   template<int ALPHA_BITS_,typename SOURCE_>
   void SetIncBlend(SOURCE_ &inSource,int inAlpha)
   {
      mPtr[mROff] += ((inSource.GetR()-mPtr[mROff])*inAlpha)>>(ALPHA_BITS_);
      mPtr[mGOff] += ((inSource.GetG()-mPtr[mGOff])*inAlpha)>>(ALPHA_BITS_);
      mPtr[mBOff] += ((inSource.GetB()-mPtr[mBOff])*inAlpha)>>(ALPHA_BITS_);
      mPtr += 4;
   }

   inline void Advance(int inX) { mPtr += inX*4; }


   int mAOff;
};



#endif
