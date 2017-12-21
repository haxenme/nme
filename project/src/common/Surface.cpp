#include <Graphics.h>
#include <Surface.h>
#include <nme/Pixel.h>

namespace nme
{

int gTextureContextVersion = 1;


// --- Surface -------------------------------------------------------


Surface::~Surface()
{
   delete mTexture;
}

void Surface::Bind(HardwareContext &inHardware,int inSlot)
{
   if (mTexture && !mTexture->IsCurrentVersion())
   {
      delete mTexture;
      mTexture = 0;
   }
 
   if (!mTexture)
      mTexture = inHardware.CreateTexture(this,mFlags);

   mTexture->Bind(inSlot);
}

Texture *Surface::GetTexture(HardwareContext *inHardware,int inPlane)
{
   if (mTexture && !mTexture->IsCurrentVersion())
   {
      delete mTexture;
      mTexture = 0;
   }
   if (!mTexture && inHardware)
      mTexture = inHardware->CreateTexture(this,mFlags);
   return mTexture;
}




// --- SimpleSurface -------------------------------------------------------

SimpleSurface::SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign)
{
   mWidth = inWidth;
   mHeight = inHeight;
   mTexture = 0;
   mPixelFormat = inPixelFormat;

   int pix_size = BytesPerPixel(inPixelFormat);

   if (inByteAlign>1)
   {
      mStride = inWidth * pix_size + inByteAlign -1;
      mStride -= mStride % inByteAlign;
   }
   else
   {
      mStride = inWidth*pix_size;
   }

   mBase = new unsigned char[mStride * mHeight+1];
   mBase[mStride*mHeight] = 69;
}

SimpleSurface::~SimpleSurface()
{
   if (mBase)
   {
      if (mBase[mStride*mHeight]!=69)
      {
         ELOG("Image write overflow");
      }
      delete [] mBase;
   }
}


void SimpleSurface::destroyHardwareSurface() {

  if (mTexture )
   {
      delete mTexture;
      mTexture = 0;
   }
   
}


void SimpleSurface::createHardwareSurface() {

   if ( nme::HardwareRenderer::current == NULL )
      printf( "Null Hardware Context" );
   else
       GetTexture( nme::HardwareRenderer::current );
   
}

void SimpleSurface::MakeTextureOnly()
{ 
   if(mBase)
   {
       createHardwareSurface();
       delete [] mBase;
       mBase = NULL;
   }
}

bool SimpleSurface::ReinterpretPixelFormat(PixelFormat inNewFormat)
{
   if ( BytesPerPixel(inNewFormat) != BytesPerPixel(mPixelFormat) )
      return false;

   mPixelFormat = inNewFormat;

   return true;
}


void SimpleSurface::ChangeInternalFormat(PixelFormat inNewFormat, const Rect *inIgnore)
{
   if (!mBase || inNewFormat==mPixelFormat)
      return;

   PixelFormat newFormat = inNewFormat;
   // Convert to render target type...
   if (newFormat==pfNone)
      switch(mPixelFormat)
      {
         case pfLuma:  newFormat = pfRGB; break;
         case pfLumaAlpha:  newFormat = pfBGRA; break;
         case pfRGB32f:  newFormat = pfRGB; break;
         case pfRGBA32f:  newFormat = pfBGRA; break;
         case pfRGBA:  newFormat = pfBGRA; break;
         case pfRGBPremA:  newFormat = pfBGRPremA; break;
         case pfRGB565:  newFormat = pfRGB; break;
         case pfARGB4444:  newFormat = pfBGRA; break;
         default:
           newFormat = pfRGB;
     }

   // Convert in-situ
   if (newFormat==pfRGBPremA && mPixelFormat==pfBGRA)
   {
      int x1 = inIgnore ? std::min(mWidth,inIgnore->x) : mWidth;
      int x2 = inIgnore ? std::min(mWidth,inIgnore->x+inIgnore->w) : mWidth;
      for(int y=0;y<mHeight;y++)
      {
         if (inIgnore && (y>=inIgnore->y && y<inIgnore->y+inIgnore->h))
            continue;
         BGRPremA *bgra = (BGRPremA *)Row(y);
         for(int x=0;x<x1;x++)
         {
            const uint8 *prem = gPremAlphaLut[bgra->a];
            bgra->b = prem[bgra->b];
            bgra->g = prem[bgra->g];
            bgra->r = prem[bgra->r];
            bgra++;
         }

         bgra = (BGRPremA *)Row(y) + x2;
         for(int x=x2;x<mWidth;x++)
         {
            const uint8 *prem = gPremAlphaLut[bgra->a];
            bgra->b = prem[bgra->b];
            bgra->g = prem[bgra->g];
            bgra->r = prem[bgra->r];
            bgra++;
         }

      }
      mPixelFormat = newFormat;
      return;
   }

   if (newFormat==pfBGRA && mPixelFormat==pfBGRPremA)
   {
      int x1 = inIgnore ? std::min(mWidth,inIgnore->x) : mWidth;
      int x2 = inIgnore ? std::min(mWidth,inIgnore->x+inIgnore->w) : mWidth;
      for(int y=0;y<mHeight;y++)
      {
         if (inIgnore && (y>=inIgnore->y && y<inIgnore->y+inIgnore->h))
            continue;
         BGRPremA *bgra = (BGRPremA *)Row(y);
         for(int x=0;x<x1;x++)
         {
            const uint8 *unprem = gUnPremAlphaLut[bgra->a];
            bgra->b = unprem[bgra->b];
            bgra->g = unprem[bgra->g];
            bgra->r = unprem[bgra->r];
            bgra++;
         }
         bgra = (BGRPremA *)Row(y) + x2;
         for(int x=x2;x<mWidth;x++)
         {
            const uint8 *unprem = gUnPremAlphaLut[bgra->a];
            bgra->b = unprem[bgra->b];
            bgra->g = unprem[bgra->g];
            bgra->r = unprem[bgra->r];
            bgra++;
         }

      }
      mPixelFormat = newFormat;
      return;
   }


   int newSize = BytesPerPixel(newFormat);
   int newStride = mWidth * newSize;
   unsigned char *newBuffer = new unsigned char[newStride * mHeight+1];
   newBuffer[newStride*mHeight] = 69;

   if (inIgnore==0)
   {
     PixelConvert(mWidth, mHeight,
       mPixelFormat,  mBase, mStride, GetPlaneOffset(),
       newFormat, newBuffer, newStride, 0 );
   }
   else
   {
      /*
          TTTTTTT
          L  X  R
          BBBBBBB
      */
      Rect r = *inIgnore;
      if (r.y>0)
      {
         PixelConvert(mWidth, r.y,
           mPixelFormat,  mBase, mStride, GetPlaneOffset(),
           newFormat, newBuffer, newStride, 0 );
      }
      if (r.x>0)
      {
         PixelConvert(r.x, r.h,
           mPixelFormat,  mBase + mStride*r.y, mStride, GetPlaneOffset(),
           newFormat, newBuffer + newStride*r.y, newStride, 0 );
      }
      if (r.x1()<mWidth)
      {
         int oldPw = BytesPerPixel(mPixelFormat);
         PixelConvert(mWidth-r.x1(), r.h,
           mPixelFormat,  mBase + mStride*r.y + r.x1()*oldPw, mStride, GetPlaneOffset(),
           newFormat, newBuffer + newStride*r.y + r.x1()*newSize, newStride, 0 );
      }

      if (r.y1()<mHeight)
      {
         PixelConvert(mWidth, mHeight-r.y1(),
           mPixelFormat,  mBase + mStride*r.y1(), mStride, GetPlaneOffset(),
           newFormat, newBuffer + newStride*r.y1(), newStride, 0 );
      }
   }
   delete [] mBase;
   mBase = newBuffer;
   mStride = newStride;
   mPixelFormat = newFormat;
   if (mTexture)
      mTexture->Dirty(Rect(0,0,mWidth,mHeight));
}



// --- Surface Blitting ------------------------------------------------------------------

struct NullMask
{
   inline void SetPos(int inX,int inY) const { }
   inline int MaskAlpha(int inAlpha) const { return inAlpha; }
   inline uint8 MaskAlpha(const ARGB &inRGB) const { return inRGB.a; }
   inline uint8 MaskAlpha(const BGRPremA &inRGB) const { return inRGB.a; }
   inline uint8 MaskAlpha(const RGB &inRGB) const { return 255; }
   template<typename T>
   T Mask(T inT) const { return inT; }
};


struct ImageMask
{
   ImageMask(const BitmapCache &inMask) :
      mMask(inMask), mOx(inMask.GetDestX()), mOy(inMask.GetDestY())
   {
      if (mMask.Format()==pfAlpha)
      {
         mComponentOffset = 0;
         mPixelStride = 1;
      }
      else
      {
         ARGB tmp;
         mComponentOffset = (uint8 *)&tmp.a - (uint8 *)&tmp;
         mPixelStride = 4;
      }
   }

   inline void SetPos(int inX,int inY) const
   {
      mRow = (mMask.Row(inY-mOy) + mComponentOffset) + mPixelStride*(inX-mOx);
   }

   inline uint8 MaskAlpha(uint8 inAlpha) const
   {
      inAlpha = (inAlpha * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return inAlpha;
   }
   inline uint8 MaskAlpha(ARGB inARGB) const
   {
      int a = (inARGB.a * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return a;
   }


   inline AlphaPixel Mask(const AlphaPixel &inA) const
   {
      AlphaPixel result;
      result.a = (inA.a * (*mRow + *mRow) )>>8;
      mRow += mPixelStride;
      return result;
   }
   inline BGRPremA Mask(const RGB &inRGB) const
   {
      BGRPremA result;
      Uint8 *lut = gPremAlphaLut[*mRow];
      result.r = lut[inRGB.r];
      result.g = lut[inRGB.g];
      result.b = lut[inRGB.b];
      result.a = *mRow;
      mRow += mPixelStride;
      return result;
   }

   template<bool PREM>
   inline BGRA<PREM> Mask(const BGRA<PREM> &inBgra) const
   {
      BGRA<PREM> result;
      if (PREM)
      {
         Uint8 *lut = gPremAlphaLut[*mRow];
         result.r = lut[inBgra.r];
         result.g = lut[inBgra.g];
         result.b = lut[inBgra.b];
         result.a = lut[inBgra.a];
      }
      else
      {
         result.ival = inBgra.ival;
         result.a = (inBgra.a * (*mRow) ) >> 8;
      }
      mRow += mPixelStride;
      return result;
   }




   const BitmapCache &mMask;
   mutable const uint8 *mRow;
   int mOx,mOy;
   int mComponentOffset;
   int mPixelStride;
};

template<typename PIXEL>
struct ImageSource
{
   typedef PIXEL Pixel;

   ImageSource(const uint8 *inBase, int inStride)
   {
      mBase = inBase;
      mStride = inStride;
   }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((const PIXEL *)( mBase + mStride*inY)) + inX;
   }
   inline const Pixel &Next() const { return *mPos++; }

   inline int getNextAlpha() const { return mPos++ -> a; }


   mutable const PIXEL *mPos;
   int   mStride;
   const uint8 *mBase;
};

struct FullAlpha
{
   inline void SetPos(int inX,int inY) const { }
   inline int getNextAlpha() const{ return 255; }
};



template<bool INNER,bool TINT_RGB=false>
struct TintSource
{
   typedef ARGB Pixel;

   TintSource(const uint8 *inBase, int inStride, int inCol,PixelFormat inFormat)
   {
      mBase = inBase;
      mStride = inStride;
      mCol = ARGB(inCol);
      a0 = mCol.a; if (a0>127) a0++;
      r = mCol.r; if (r>127) r++;
      g = mCol.g; if (g>127) g++;
      b = mCol.b; if (b>127) b++;
      mFormat = inFormat;

      if (inFormat==pfAlpha)
      {
         mComponentOffset = 0;
         mPixelStride = 1;
      }
      else
      {
         ARGB tmp;
         mComponentOffset = (uint8 *)&tmp.a - (uint8 *)&tmp;
         mPixelStride = 4;
      }
   }

   inline void SetPos(int inX,int inY) const
   {
      if (TINT_RGB)
         mPos = ((const uint8 *)( mBase + mStride*inY)) + inX*mPixelStride;
      else
         mPos = ((const uint8 *)( mBase + mStride*inY)) + inX*mPixelStride + mComponentOffset;
   }
   inline const ARGB &Next() const
   {
      if (INNER)
         mCol.a =  a0*(255 - *mPos)>>8;
      else if (TINT_RGB)
      {
         ARGB col = *(ARGB *)(mPos);
         mCol.a =   (a0*col.a)>>8;
         mCol.r =  (r*col.r)>>8;
         mCol.g =  (g*col.g)>>8;
         mCol.b =  (b*col.b)>>8;
      }
      else
      {
         mCol.a =  (a0 * *mPos)>>8;
      }
      mPos+=mPixelStride;
      return mCol;
   }

   int a0;
   int r;
   int g;
   int b;
   PixelFormat mFormat;
   mutable ARGB mCol;
   mutable const uint8 *mPos;
   int   mComponentOffset;
   int   mPixelStride;
   int   mStride;
   const uint8 *mBase;
};


template<typename PIXEL>
struct ImageDest
{
   typedef PIXEL Pixel;

   ImageDest(const RenderTarget &inTarget) : mTarget(inTarget) { }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((PIXEL *)mTarget.Row(inY)) + inX;
   }
   inline Pixel &Next() const { return *mPos++; }

   PixelFormat Format() const { return mTarget.mPixelFormat; }

   const RenderTarget &mTarget;
   mutable PIXEL *mPos;
};


template<typename DEST, typename SRC, typename MASK>
void TBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX , inY + y );
      inMask.SetPos(inX , inY + y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
         BlendPixel(outDest.Next(),inMask.Mask(inSrc.Next()));
   }
}



template<typename DEST, typename SRC, typename MASK>
void TBlitAlpha( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
      inMask.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
         BlendAlpha(outDest.Next(),inMask.MaskAlpha(inSrc.getNextAlpha()));
   }

}

static uint8 sgClamp0255Values[256*3];
static uint8 *sgClamp0255;
int InitClamp()
{
   sgClamp0255 = sgClamp0255Values + 256;
   for(int i=-255; i<=255+255;i++)
      sgClamp0255[i] = i<0 ? 0 : i>255 ? 255 : i;
   return 0;
}
static int init_clamp = InitClamp();

typedef void (*BlendFunc)(ARGB &ioDest, ARGB inSrc);


template<typename SRC, typename FUNC>
RGB ApplyComponent(const RGB &d, const SRC &s, const FUNC &)
{
   RGB result;
   result.r = FUNC::comp(d.r, s.getR() );
   result.g = FUNC::comp(d.g, s.getG() );
   result.b = FUNC::comp(d.b, s.getB() );
   return result;
}
template<typename SRC, typename FUNC>
void UpdateAlpha(RGB &d, const SRC &s, const FUNC &)
{
}



template<typename SRC, typename FUNC>
ARGB ApplyComponent(const ARGB &d, const SRC &s, const FUNC &)
{
   ARGB result;
   result.r = FUNC::comp(d.r, s.getR() );
   result.g = FUNC::comp(d.g, s.getG() );
   result.b = FUNC::comp(d.b, s.getB() );
   result.a = FUNC::alpha(d.a, s.getAlpha() );
   return result;
}

template<typename SRC, typename FUNC>
void UpdateAlpha(ARGB &d, const SRC &s, const FUNC &)
{
   d.a = FUNC::alpha(d.a,s.getAlpha());
}


template<typename SRC, typename FUNC>
BGRPremA ApplyComponent(const BGRPremA &d, const SRC &s, const FUNC &)
{
   BGRPremA result;
   if (FUNC::Unmultiplied)
   {
      result.a = FUNC::alpha(d.a, s.getAlpha() );
      const Uint8 *aLut = gPremAlphaLut[result.a];
      result.r = aLut[ FUNC::comp(d.getR(), s.getR() ) ];
      result.g = aLut[ FUNC::comp(d.getG(), s.getG() ) ];
      result.b = aLut[ FUNC::comp(d.getB(), s.getB() ) ];
   }
   else
   {
      result.r = FUNC::comp(d.r, s.getRAlpha() );
      result.g = FUNC::comp(d.g, s.getGAlpha() );
      result.b = FUNC::comp(d.b, s.getBAlpha() );
      result.a = FUNC::alpha(d.a, s.getAlpha() );
   }

   return result;
}

template<typename SRC, typename FUNC>
void UpdateAlpha(BGRPremA &d, const SRC &s, const FUNC &)
{
   int a = FUNC::alpha(d.a,s.getAlpha());
   if (a!=d.a)
   {
      if (a<2)
      {
         d.ival =0;
      }
      else if (a==255)
      {
         const Uint8 *from = gUnPremAlphaLut[d.a];
         d.r = from[d.r];
         d.g = from[d.g];
         d.b = from[d.b];
         d.a = 255;
      }
      else
      {
         const Uint8 *from = gUnPremAlphaLut[d.a];
         const Uint8 *to = gPremAlphaLut[a];
         d.r = to[from[d.r]];
         d.g = to[from[d.g]];
         d.b = to[from[d.b]];
         d.a = a;
      }
   }
}


template<typename SRC, typename FUNC>
AlphaPixel ApplyComponent(const AlphaPixel &d, const SRC &s, const FUNC &)
{
   AlphaPixel result;
   result.a = FUNC::alpha(d.a, s.getAlpha());
   return result;
}

template<typename SRC, typename FUNC>
void UpdateAlpha(AlphaPixel &d, const SRC &s, const FUNC &)
{
   d.a = FUNC::alpha(d.a,s.getAlpha());
}


// --- Multiply -----

struct MultiplyHandler
{
   enum { Unmultiplied = false, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return ( (a + (a>>7)) * b ) >> 8; }
   static inline uint8 alpha(uint8 a, uint8 b) { return ( (a + (a>>7)) * b ) >> 8; }
};



// --- Screen -----

struct ScreenHandler
{
   enum { Unmultiplied = false, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return 255 - (((255 - a) * ( 256 - b - (b>>7)))>>8); }
   static inline uint8 alpha(uint8 a, uint8 b) { return 255 - (((255 - a) * ( 256 - b - (b>>7)))>>8); }
};


// -- Copy --------
struct CopyHandler
{
   enum { Unmultiplied = false, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return b; }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};


struct AddHandler
{
   enum { Unmultiplied = false, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return sgClamp0255[a+b]; }
   static inline uint8 alpha(uint8 a, uint8 b) { return a; }
};



struct LightenHandler
{
   enum { Unmultiplied = true, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return b>a ? b:a; }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};


struct DarkenHandler
{
   enum { Unmultiplied = true, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return b<a ? b:a; }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};


struct DifferenceHandler
{
   enum { Unmultiplied = true, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return b<a ? a-b : b-a; }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};


struct SubtractHandler
{
   enum { Unmultiplied = false, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return sgClamp0255[(int)a-b]; }
   static inline uint8 alpha(uint8 a, uint8 b) { return a; }
};


struct HardLightHandler
{
   enum { Unmultiplied = true, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return b>127 ? ScreenHandler::comp(a,b) : MultiplyHandler::comp(a,b); }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};

struct OverlayHandler
{
   enum { Unmultiplied = true, AlphaOnly = false };

   // TODO - seems to match flash when i use 'b>127', not 'a>127'
   static inline uint8 comp(uint8 a, uint8 b) { return b>127 ? ScreenHandler::comp(a,b) : MultiplyHandler::comp(a,b); }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};



// Only depends on incoming alpha ...
struct InvertHandler
{
   enum { Unmultiplied = true, AlphaOnly = false };
   static inline uint8 comp(uint8 a, uint8 b) { return 255-a; }
   static inline uint8 alpha(uint8 a, uint8 b) { return b; }
};


struct AlphaHandler
{
   enum { Unmultiplied = true, AlphaOnly = true };
   static inline uint8 comp(uint8 a, uint8 b) { return a; }
   static inline uint8 alpha(uint8 a, uint8 b) { return gPremAlphaLut[b][a]; }
};


struct EraseHandler
{
   enum { Unmultiplied = true, AlphaOnly = true };
   static inline uint8 comp(uint8 a, uint8 b) { return a; }
   static inline uint8 alpha(uint8 a, uint8 b) { return gPremAlphaLut[255-b][a]; }
};


//
// Blend the colour, take the alpha - special case?
//
// -- Inner ---------
template<typename DEST, typename SRC> void ApplyInner(DEST &ioDest, SRC inSrc)
{
   int A = inSrc.getAlpha();
   if (A)
   {
      int r = ioDest.getR();
      int g = ioDest.getG();
      int b = ioDest.getB();
      ioDest.setR( r + (((inSrc.getR() - r)*A)>>8) );
      ioDest.setG( g + (((inSrc.getG() - g)*A)>>8) );
      ioDest.setB( b + (((inSrc.getB() - b)*A)>>8) );
   }
}





template<typename DEST, typename SOURCE, typename MASK>
void TBlitBlend( const DEST &outDest, SOURCE &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect, BlendMode inMode)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX , inY + y );
      inMask.SetPos(inX , inY + y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );

      #define BLEND_CASE(mode) \
         case bm##mode: \
            for(int x=0;x<inSrcRect.w;x++) \
            { \
               typename DEST::Pixel &dest = outDest.Next(); \
               if (mode##Handler::AlphaOnly) \
                  UpdateAlpha(dest,inMask.Mask(inSrc.Next()),mode##Handler() ); \
               else \
                  BlendPixel(dest,ApplyComponent(dest,inMask.Mask(inSrc.Next()),mode##Handler() ) ); \
            } \
            break;

      switch(inMode)
      {
         BLEND_CASE(Multiply)
         BLEND_CASE(Screen)
         BLEND_CASE(Add)
         BLEND_CASE(Lighten)
         BLEND_CASE(Darken)
         BLEND_CASE(Difference)
         BLEND_CASE(Subtract)
         BLEND_CASE(Invert)
         BLEND_CASE(Overlay)
         BLEND_CASE(HardLight)
         BLEND_CASE(Alpha)
         BLEND_CASE(Erase)

         case bmCopy:
            for(int x=0;x<inSrcRect.w;x++)
            {
               typename DEST::Pixel &dest = outDest.Next();
               SetPixel(dest,inMask.Mask(inSrc.Next()));
            }
            break;

         case bmInner:
            for(int x=0;x<inSrcRect.w;x++)
            {
               typename DEST::Pixel &dest = outDest.Next();
               ApplyInner(dest,inSrc.Next());
            }
            break;

         case bmNormal:
         case bmTinted:
         case bmTintedAdd:
         case bmTintedInner:
         case bmLayer:
            ;

      }
   }
}


template<typename DEST,typename SRC>
void TTBlitRgb(const DEST &dest, SRC &src, int dx, int dy, Rect src_rect, const BitmapCache *inMask, BlendMode inBlend )
{
   if (inBlend==bmNormal || inBlend==bmLayer)
   {
      if (inMask)
         TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
      else
         TBlit( dest, src, NullMask(), dx, dy, src_rect );
   }
   else
   {
      if (inMask)
         TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, inBlend );
      else
         TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, inBlend );
   }
}




template<typename DEST>
void TBlitRgb(const DEST &dest, int dx, int dy, const SimpleSurface *inSrc, Rect src_rect, const BitmapCache *inMask, BlendMode inBlend, uint32 inTint )
{
      bool tint = inBlend==bmTinted;
      bool tint_inner = inBlend==bmTintedInner;
      bool tint_add = inBlend==bmTintedAdd;

      bool src_alpha = inSrc->Format()==pfAlpha;

      // Blitting tint, we can ignore blend mode too (this is used for rendering text)
      if (tint)
      {
         if (src_alpha)
         {
            TintSource<false> src(inSrc->GetBase(),inSrc->GetStride(),inTint,inSrc->Format());
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
         else
         {
            TintSource<false,true> src(inSrc->GetBase(),inSrc->GetStride(),inTint,inSrc->Format());
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
      }
      else if (tint_inner)
      {
         TintSource<true> src(inSrc->GetBase(),inSrc->GetStride(),inTint,inSrc->Format());

         if (inMask)
            TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, bmInner );
         else
            TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, bmInner );
      }
      else if (tint_add)
      {
         TintSource<false,true> src(inSrc->GetBase(),inSrc->GetStride(),inTint,inSrc->Format());

         if (inMask)
            TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, bmAdd );
         else
            TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, bmAdd );
      }
      else
      {
         switch(inSrc->Format())
         {
            case pfAlpha:
               {
               ImageSource<AlphaPixel> src(inSrc->GetBase(),inSrc->GetStride());
               TTBlitRgb(dest, src, dx, dy, src_rect,inMask,inBlend);
               }
               return;
            case pfRGB:
               {
               ImageSource<RGB> src(inSrc->GetBase(),inSrc->GetStride());
               TTBlitRgb(dest, src, dx, dy, src_rect,inMask,inBlend);
               }
               return;
            case pfBGRA:
               {
               ImageSource<ARGB> src(inSrc->GetBase(),inSrc->GetStride());
               TTBlitRgb(dest, src, dx, dy, src_rect,inMask,inBlend);
               }
               return;
            case pfBGRPremA:
               {
               ImageSource<BGRPremA> src(inSrc->GetBase(),inSrc->GetStride());
               TTBlitRgb(dest, src, dx, dy, src_rect,inMask,inBlend);
               }
               return;
            default:
               ;
         }
      }
}


void SimpleSurface::BlitTo(const RenderTarget &outDest,
                     const Rect &inSrcRect,int inPosX, int inPosY,
                     BlendMode inBlend, const BitmapCache *inMask,
                     uint32 inTint ) const
{
   if (!mBase)
      return;

   // Translate inSrcRect src_rect to dest ...
   Rect src_rect(inPosX,inPosY, inSrcRect.w, inSrcRect.h );
   // clip ...
   src_rect = src_rect.Intersect(outDest.mRect);

   if (inMask)
      src_rect = src_rect.Intersect(inMask->GetRect());

   // translate back to source-coordinates ...
   src_rect.Translate(inSrcRect.x-inPosX, inSrcRect.y-inPosY);
   // clip to origial rect...
   src_rect = src_rect.Intersect( inSrcRect );


   if (src_rect.HasPixels())
   {
      if (mPixelFormat>=pfRenderToCount)
         const_cast<SimpleSurface *>(this)->ChangeInternalFormat();


      bool src_alpha = mPixelFormat==pfAlpha;
      bool dest_alpha = outDest.mPixelFormat==pfAlpha;



      int dx = inPosX + src_rect.x - inSrcRect.x;
      int dy = inPosY + src_rect.y - inSrcRect.y;

      // Check for rendering same-surface to same-surface
      if (mPixelFormat == outDest.mPixelFormat)
      {
          int pw = BytesPerPixel(mPixelFormat);
          // If these are the same surface, then difference in pointers will be small enough,
          //  otherwise x_off and y_off could be greatly different
          int d_base = (outDest.mSoftPtr-mBase);
          int y_off = d_base/mStride;
          int x_off = (d_base-y_off*mStride)/pw;
          Rect dr(dx + x_off, dy + y_off, src_rect.w, src_rect.h);
          if (src_rect.Intersect(dr).HasPixels())
          {
              SimpleSurface sub(src_rect.w, src_rect.h, mPixelFormat);
              Rect sub_dest(0,0,src_rect.w, src_rect.h);

              for(int y=0;y<src_rect.h;y++)
                 memcpy((void *)sub.Row(y), Row(src_rect.y+y) + (src_rect.x*pw), src_rect.w*pw );

              sub.BlitTo(outDest, sub_dest, dx, dy, inBlend, 0, inTint);
              return;
          }
      }


      // Blitting to alpha image - can ignore blend mode
      if (dest_alpha)
      {
         ImageDest<AlphaPixel> dest(outDest);
         if (inMask)
         {
            if (src_alpha)
               TBlitAlpha(dest, ImageSource<AlphaPixel>(mBase,mStride), ImageMask(*inMask), dx, dy, src_rect );
            else if (mPixelFormat==pfBGRA || mPixelFormat==pfRGBPremA)
               TBlitAlpha(dest, ImageSource<ARGB>(mBase,mStride), ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlitAlpha(dest, FullAlpha(), ImageMask(*inMask), dx, dy, src_rect );
         }
         else
         {
            if (src_alpha)
               TBlitAlpha(dest, ImageSource<AlphaPixel>(mBase,mStride), NullMask(), dx, dy, src_rect );
            else if (mPixelFormat==pfBGRA || mPixelFormat==pfRGBPremA)
               TBlitAlpha(dest, ImageSource<ARGB>(mBase,mStride), NullMask(), dx, dy, src_rect );
            else
               TBlitAlpha(dest, FullAlpha(), NullMask(), dx, dy, src_rect );
         }
      }
      else if (outDest.Format()==pfBGRPremA)
         TBlitRgb( ImageDest<BGRPremA>(outDest), dx, dy, this, src_rect, inMask, inBlend, inTint );
      else if (outDest.Format()==pfBGRA)
         TBlitRgb( ImageDest<ARGB>(outDest), dx, dy, this, src_rect, inMask, inBlend, inTint );
      else if (outDest.Format()==pfRGB)
         TBlitRgb( ImageDest<RGB>(outDest), dx, dy, this, src_rect, inMask, inBlend, inTint );
   }
}

void SimpleSurface::colorTransform(const Rect &inRect, ColorTransform &inTransform)
{
   if (mPixelFormat==pfAlpha || !mBase)
      return;

   ChangeInternalFormat(pfBGRA);

   const uint8 *ta = inTransform.GetAlphaLUT();
   const uint8 *tr = inTransform.GetRLUT();
   const uint8 *tg = inTransform.GetGLUT();
   const uint8 *tb = inTransform.GetBLUT();

   RenderTarget target = BeginRender(inRect,false);

   Rect r = target.mRect;
   for(int y=0;y<r.h;y++)
   {
      ARGB *rgb = ((ARGB *)target.Row(y+r.y)) + r.x;
      for(int x=0;x<r.w;x++)
      {
         rgb->r = tr[rgb->r];
         rgb->g = tg[rgb->g];
         rgb->b = tb[rgb->b];
         rgb->a = ta[rgb->a];
         rgb++;
      }
   }

   EndRender();
}




void SimpleSurface::BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                   int inPosX, int inPosY,
                   int inSrcChannel, int inDestChannel ) const
{
   PixelFormat destFmt = outTarget.mPixelFormat;
   int destPos = GetPixelChannelOffset(destFmt,(PixelChannel)inDestChannel);
   if (destPos<0)
      return;

   PixelFormat srcFmt = mPixelFormat;
   int srcPos =GetPixelChannelOffset(srcFmt,(PixelChannel)inSrcChannel);
   if (srcPos==CHANNEL_OFFSET_NONE)
      return;

   int srcPw = BytesPerPixel(srcFmt);
   int destPw = BytesPerPixel(destFmt);


   bool set_255 = srcPos==CHANNEL_OFFSET_VIRTUAL_ALPHA;

   Rect src_rect(inSrcRect.x,inSrcRect.y, inSrcRect.w, inSrcRect.h );
   src_rect = src_rect.Intersect( Rect(0,0,Width(),Height() ) );

   Rect dest_rect(inPosX,inPosY, inSrcRect.w, inSrcRect.h );
   dest_rect = dest_rect.Intersect(outTarget.mRect);


   int minW = src_rect.w;
   if(dest_rect.w < src_rect.w)
      minW = dest_rect.w;

   int minH = src_rect.h;
   if(dest_rect.h < src_rect.h)
      minH = dest_rect.h;

   for(int y=0;y<minH;y++)
   {
      uint8 *d = outTarget.Row(y+dest_rect.y) + dest_rect.x*destPw + destPos;
      if (set_255)
      {
         for(int x=0;x<minW;x++)
         {
            *d = 255;
            d+=destPw;
         }
      }
      else
      {
         const uint8 *s = Row(y+src_rect.y) + src_rect.x * srcPw + srcPos;

         for(int x=0;x<minW;x++)
         {
            *d = *s;
            d+=destPw;
            s+=srcPw;
         }
      }
   }
}


template<typename SRC,typename DEST>
void TStretchTo(const SimpleSurface *inSrc,const RenderTarget &outTarget,
                const Rect &inSrcRect, const DRect &inDestRect, int inFlags)
{
   Rect irect( inDestRect.x+0.5, inDestRect.y+0.5, inDestRect.x1()+0.5, inDestRect.y1()+0.5, true);
   Rect out = irect.Intersect(outTarget.mRect);
   if (!out.Area())
      return;

   int dsx_dx = (inSrcRect.w << 16)/inDestRect.w;
   int dsy_dy = (inSrcRect.h << 16)/inDestRect.h;

   if (!inFlags)
   {
      // (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
      // Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
      //
      // Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5

      //int sx0 = (int)((out.x-inDestRect.x*inSrcRect.w/inDestRect.w)*65536) +(inSrcRect.x<<16);
      //int sy0 = (int)((out.y-inDestRect.y*inSrcRect.h/inDestRect.h)*65536) +(inSrcRect.y<<16);
      int sx0 = (int)((out.x+0.5-inDestRect.x)*dsx_dx + (inSrcRect.x<<16) );
      int sy0 = (int)((out.y+0.5-inDestRect.y)*dsy_dy + (inSrcRect.y<<16) );

      for(int y=0;y<out.h;y++)
      {
         DEST *dest= (DEST *)outTarget.Row(y+out.y) + out.x;
         int y_ = (sy0>>16);
         const SRC *src = (const SRC *)inSrc->Row(y_);
         sy0+=dsy_dy;

         int sx = sx0;
         for(int x=0;x<out.w;x++)
         {
            BlendPixel(*dest++, src[sx>>16]);
            sx+=dsx_dx;
         }
      }
   }
   else
   {
      // todo - overflow testing
      // (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
      // Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
      //
      // Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5
      int sx0 = (int)((out.x+0.5-inDestRect.x)*dsx_dx + (inSrcRect.x<<16) ) - 0x8000;
      int sy0 = (int)((out.y+0.5-inDestRect.y)*dsy_dy + (inSrcRect.y<<16) ) - 0x8000;
      //int sx0 = (((((out.x-inDestRect.x)<<8) + 0x80) * inSrcRect.w/inDestRect.w) << 8) +(inSrcRect.x<<16) - 0x8000;
      //int sy0 = (((((out.y-inDestRect.y)<<8) + 0x80) * inSrcRect.h/inDestRect.h) << 8) +(inSrcRect.y<<16) - 0x8000;
      int last_y = inSrcRect.y1()-1;
      SRC s;
      for(int y=0;y<out.h;y++)
      {
         DEST *dest= (DEST *)outTarget.Row(y+out.y) + out.x;
         int y_ = (sy0>>16);
         int y_frac = sy0 & 0xffff;
         const SRC *src0 = (const SRC *)inSrc->Row(y_);
         const SRC *src1 = (const SRC *)inSrc->Row(y_<last_y ? y_+1 : y_);
         sy0+=dsy_dy;

         int sx = sx0;
         for(int x=0;x<out.w;x++)
         {
            int x_ = sx>>16;
            int x_frac = sx & 0xffff;

            SRC s = BilinearInterp( src0[x_], src0[x_+1], src1[x_], src1[x_+1], x_frac, y_frac);

            BlendPixel(*dest, s);
            dest++;
            sx+=dsx_dx;
         }
      }
   }
}


template<typename PIXEL>
void TStretchSuraceTo(const SimpleSurface *inSurface, const RenderTarget &outTarget,
                     const Rect &inSrcRect, const DRect &inDestRect, unsigned int inFlags)
{
   switch(outTarget.Format())
   {
      case pfRGB:
         TStretchTo<PIXEL,RGB>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfBGRA:
         TStretchTo<PIXEL,ARGB>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfBGRPremA:
         TStretchTo<PIXEL,BGRPremA>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfAlpha:
         TStretchTo<PIXEL,RGB>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      default: ;
   }
}

void SimpleSurface::StretchTo(const RenderTarget &outTarget,
                     const Rect &inSrcRect, const DRect &inDestRect, unsigned int inFlags) const
{
   switch(mPixelFormat)
   {
      case pfRGB:
         TStretchSuraceTo<RGB>(this, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfBGRA:
         TStretchSuraceTo<ARGB>(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      case pfBGRPremA:
         TStretchSuraceTo<BGRPremA>(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      case pfAlpha:
         TStretchSuraceTo<RGB>(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      default: ;
   }
}



void SimpleSurface::Clear(uint32 inColour,const Rect *inRect)
{
   if (!mBase)
      return;
   if (mPixelFormat==pfLuma)
   {
      memset(mBase, inColour & 0xff,mStride*mHeight);
      return;
   }

   ARGB rgb(inColour);
   if (mPixelFormat==pfAlpha)
   {
      memset(mBase, rgb.a,mStride*mHeight);
      return;
   }

   int x0 = inRect ? inRect->x  : 0;
   int x1 = inRect ? inRect->x1()  : Width();
   int y0 = inRect ? inRect->y  : 0;
   int y1 = inRect ? inRect->y1()  : Height();
   if( x0 < 0 ) x0 = 0;
   if( x1 > Width() ) x1 = Width();
   if( y0 < 0 ) y0 = 0;
   if( y1 > Height() ) y1 = Height();
   if (x1<=x0 || y1<=y0)
      return;

   int pix_size = BytesPerPixel(mPixelFormat);

   if (mPixelFormat==pfLumaAlpha)
   {
      for(int y=y0;y<y1;y++)
      {
         int luma = rgb.luma();
         uint8 *ptr = (mBase + y*mStride) + x0*2;
         for(int x=x0;x<x1;x++)
         {
            *ptr++ = luma;
            *ptr++ = rgb.a;
         }
      }

   }
   else if (mPixelFormat==pfRGB)
   {
      for(int y=y0;y<y1;y++)
      {
         uint8 *ptr = (mBase + y*mStride) + x0*3;
         for(int x=x0;x<x1;x++)
         {
            *ptr++ = rgb.r;
            *ptr++ = rgb.g;
            *ptr++ = rgb.b;
         }
      }
   }
   else if (pix_size==4)
   {
      if (mPixelFormat==pfBGRPremA)
      {
         BGRPremA prem;
         SetPixel(prem,rgb);
         rgb.ival = prem.ival;
      }
      for(int y=y0;y<y1;y++)
      {
         uint32 *ptr = (uint32 *)(mBase + y*mStride) + x0;
         for(int x=x0;x<x1;x++)
            *ptr++ = rgb.ival;
      }
   }
   else
   {
      for(int y=y0;y<y1;y++)
      {
         uint8 *ptr = (uint8 *)(mBase + y*mStride) + x0*pix_size;
         memset(ptr, 0, (x1-x0)*pix_size);
      }
   }

   if (mTexture)
      mTexture->Dirty( Rect(x0,y0,x1-x0,y1-y0) );
}

void SimpleSurface::Zero()
{
   if (mBase)
      memset(mBase,0,mStride * mHeight);
}

void SimpleSurface::dispose()
{
   destroyHardwareSurface();
   if (mBase)
   {
      if (mBase[mStride * mHeight] != 69)
      {
         ELOG("Image write overflow");
      }
      delete [] mBase;
      mBase = NULL;
   }
}

uint8  *SimpleSurface::Edit(const Rect *inRect)
{
   if (!mBase)
      return 0;

   Rect r = inRect ? inRect->Intersect( Rect(0,0,mWidth,mHeight) ) : Rect(0,0,mWidth,mHeight);
   if (mTexture)
      mTexture->Dirty(r);
   mVersion++;
      return mBase;
}



RenderTarget SimpleSurface::BeginRender(const Rect &inRect,bool inForHitTest)
{
   if (!mBase)
      return RenderTarget();

   Rect r =  inRect.Intersect( Rect(0,0,mWidth,mHeight) );
   if (mTexture)
      mTexture->Dirty(r);
   mVersion++;
   return RenderTarget(r, mPixelFormat,mBase,mStride);
}

void SimpleSurface::EndRender()
{
}

Surface *SimpleSurface::clone()
{
   SimpleSurface *copy = new SimpleSurface(mWidth,mHeight,mPixelFormat,1);
   int pix_size = BytesPerPixel( mPixelFormat );
   if (mBase)
      for(int y=0;y<mHeight;y++)
         memcpy(copy->mBase + copy->mStride*y, mBase+mStride*y, mWidth*pix_size);
   
   copy->IncRef();
   return copy;
}

void SimpleSurface::getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder, bool inLittleEndian)
{
   if (!mBase)
      return;

   // PixelConvert

   Rect r = inRect.Intersect(Rect(0,0,Width(),Height()));
   if (r.w<1 || r.h<1)
      return;

   ARGB *argb = (ARGB *)outPixels;
   for(int y=0;y<r.h;y++)
   {
      if (mPixelFormat==pfAlpha)
      {
         AlphaPixel *src = (AlphaPixel *)(mBase + (r.y+y)*mStride) + r.x;

         for(int x=0;x<r.w;x++)
            SetPixel(*argb++, *src++);
      }
      else if (mPixelFormat==pfRGB)
      {
         RGB *src = (RGB *)(mBase + (r.y+y)*mStride) + r.x;

         for(int x=0;x<r.w;x++)
            SetPixel(*argb++, *src++);
      }
      else if (mPixelFormat==pfBGRA)
      {
         ARGB *src = (ARGB *)(mBase + (r.y+y)*mStride) + r.x;
         memcpy(argb,src,r.w*4);
         argb+=r.w;
      }
      else if (mPixelFormat==pfBGRPremA)
      {
         BGRPremA *src = (BGRPremA *)(mBase + (r.y+y)*mStride) + r.x;
         for(int x=0;x<r.w;x++)
            SetPixel(*argb++, *src++);
      }
   }

   // Make big-endian...
   if (!inIgnoreOrder && !inLittleEndian)
   {
      unsigned int *argb = (unsigned int *)outPixels;
      int n = r.w*r.h;
      for(int i=0;i<n;i++)
      {
         unsigned int v = argb[i];
         argb[i] =   (v>>24) | ((v>>8)&0x0000ff00) | ((v<<8)&0x00ff0000) | (v<<24);
      }
   }
}

void SimpleSurface::getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect)
{
   outRect = Rect();
   if (!mBase)
      return;

   int w = Width();
   int h = Height();

   if (w==0 || h==0 || mPixelFormat==pfAlpha || mPixelFormat>=pfRenderToCount)
      return;

   if (mPixelFormat==pfRGB && (inMask&0xff000000) && (inCol&0xff000000)!=0xff000000)
      return;

   int min_x = w + 1;
   int max_x = -1;
   int min_y = h + 1;
   int max_y = -1;

   ARGB argb(inCol);
   if (mPixelFormat==pfBGRPremA)
   {
      BGRPremA bgra;
      SetPixel(bgra, argb);
      argb.ival = bgra.ival;
   }
   argb.ival &= inMask;

   for(int y=0;y<h;y++)
   {
      if (mPixelFormat==pfRGB)
      {
         ARGB test;
         RGB *rgb = (RGB *)( mBase + y*mStride);
         for(int x=0;x<w;x++)
         {
            SetPixel(test,*rgb++);
            if ( ((test.ival&inMask)==inCol)==inFind )
            {
               if (x<min_x) min_x=x;
               if (x>max_x) max_x=x;
               if (y<min_y) min_y=y;
               if (y>max_y) max_y=y;
            }
         }

      }
      else
      {
         int *pixel = (int *)( mBase + y*mStride);
         for(int x=0;x<w;x++)
         {
            if ( (((*pixel++)&inMask)==inCol)==inFind )
            {
               if (x<min_x) min_x=x;
               if (x>max_x) max_x=x;
               if (y<min_y) min_y=y;
               if (y>max_y) max_y=y;
            }
         }
      }
   }

   if (min_x>max_x)
      outRect = Rect(0,0,0,0);
   else
      outRect = Rect(min_x,min_y,max_x-min_x+1,max_y-min_y+1);
}


void SimpleSurface::setPixels(const Rect &inRect,const uint32 *inPixels,bool inIgnoreOrder, bool inLittleEndian)
{

   if (!mBase)
      return;
   Rect r = inRect.Intersect(Rect(0,0,Width(),Height()));
   mVersion++;
   if (mTexture)
      mTexture->Dirty(r);

   PixelFormat convert = pfNone;
   if ( !(mFlags & surfFixedPixelFormat) && !HasAlphaChannel(mPixelFormat))
   {
      int n = inRect.w * inRect.h;
      for(int i=0;i<n;i++)
         if ((inPixels[i]&0xff000000) != 0xff000000)
         {
            convert = pfBGRA;
            break;
         }
      if (convert==pfNone && mPixelFormat>=pfRenderToCount)
         convert = pfRGB;
   }
   else if (mPixelFormat>=pfRenderToCount)
      convert = pfBGRA;

   if (convert!=pfNone)
   {
      ChangeInternalFormat(convert, &r);
   }

   const ARGB *src = (const ARGB *)inPixels;
   bool bigEndian = !inIgnoreOrder && !inLittleEndian;

   for(int y=0;y<r.h;y++)
   {
      if (mPixelFormat==pfBGRA)
      {
         ARGB *dest = (ARGB *)(mBase + (r.y+y)*mStride) + r.x;
         if (bigEndian)
         {
            for(int x=0;x<r.w;x++)
            {
               dest->a = src->b;
               dest->r = src->g;
               dest->g = src->r;
               dest->b = src->a;
               dest++;
               src++;
            }
         }
         else
         {
            memcpy(dest, src, r.w*sizeof(ARGB));
            src+=r.w;
         }
      }
      else if (mPixelFormat==pfAlpha)
      {
         AlphaPixel *dest = (AlphaPixel *)(mBase + (r.y+y)*mStride) + r.x;
         if (!bigEndian)
            dest += 3;
         for(int x=0;x<r.w;x++)
         {
            SetPixel(*dest,*src++);
            dest+=4;
         }
      }
      else if (mPixelFormat==pfRGB)
      {
         RGB *dest = (RGB *)(mBase + (r.y+y)*mStride) + r.x;
         if (bigEndian)
         {
            for(int x=0;x<r.w;x++)
            {
               dest->r = src->g;
               dest->g = src->r;
               dest->b = src->a;
               src++;
               dest++;
            }
         }
         else
            for(int x=0;x<r.w;x++)
               SetPixel(*dest++,*src++);
      }
      else if (mPixelFormat==pfBGRPremA)
      {
         BGRPremA *dest = (BGRPremA *)(mBase + (r.y+y)*mStride) + r.x;
         if (bigEndian)
         {
            for(int x=0;x<r.w;x++)
            {
               const Uint8 *aLut = gPremAlphaLut[dest->a = src->b];
               dest->r = aLut[src->g];
               dest->g = aLut[src->r];
               dest->b = aLut[src->a];
               dest++;
               src++;
            }
         }
         else
            for(int x=0;x<r.w;x++)
               SetPixel(*dest++,*src++);
      }
   }
}

uint32 SimpleSurface::getPixel(int inX,int inY)
{
   if (inX<0 || inY<0 || inX>=mWidth || inY>=mHeight || !mBase)
      return 0;

   ARGB result(0xff000000);
   void *ptr = mBase + inY*mStride;
   switch(mPixelFormat)
   {
      case pfRGB: SetPixel(result, ((RGB *)ptr)[inX]); break;
      case pfBGRA: SetPixel(result, ((ARGB *)ptr)[inX]); break;
      case pfBGRPremA: SetPixel(result, ((BGRPremA *)ptr)[inX]); break;
      case pfAlpha: SetPixel(result, ((AlphaPixel *)ptr)[inX]); break;

      default: ;
      /* TODO
      case pfARGB4444:
      case pfRGB565:
      case pfLuma:
      case pfLumaAlpha:
      case pfECT:
      case pfRGB32f:
      case pfRGBA32f:
      case pfYUV420sp:
      case pfNV12:
      case pfOES:
      */
   }


   return result.ival;
}

void SimpleSurface::setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo)
{
   if (inX<0 || inY<0 || inX>=mWidth || inY>=mHeight || !mBase)
      return;

   mVersion++;
   if (mTexture)
      mTexture->Dirty(Rect(inX,inY,1,1));

   if (inAlphaToo && ((inRGBA&0xff000000)!=0xff000000) && !HasAlphaChannel(mPixelFormat) )
      ChangeInternalFormat(pfBGRA);

   ARGB value(inRGBA);
   void *ptr = mBase + inY*mStride;
   switch(mPixelFormat)
   {
      case pfRGB: SetPixel(((RGB *)ptr)[inX],value); break;
      case pfBGRA: SetPixel(((ARGB *)ptr)[inX],value); break;
      case pfBGRPremA: SetPixel(((BGRPremA *)ptr)[inX],value); break;
      case pfAlpha: SetPixel(((AlphaPixel *)ptr)[inX],value); break;

      default: ;
      /* TODO
      case pfARGB4444:
      case pfRGB565:
      case pfLuma:
      case pfLumaAlpha:
      case pfECT:
      case pfRGB32f:
      case pfRGBA32f:
      case pfYUV420sp:
      case pfNV12:
      case pfOES:
      */
   }
}

void SimpleSurface::scroll(int inDX,int inDY)
{
   if ((inDX==0 && inDY==0) || !mBase) return;

   Rect src(0,0,mWidth,mHeight);
   src = src.Intersect( src.Translated(inDX,inDY) ).Translated(-inDX,-inDY);
   int pixels = src.Area();
   if (!pixels)
      return;

   uint32 *buffer = (uint32 *)malloc( pixels * sizeof(int) );
   getPixels(src,buffer,true);
   src.Translate(inDX,inDY);
   setPixels(src,buffer,true);
   free(buffer);
   mVersion++;
   if (mTexture)
      mTexture->Dirty(src);
}

void SimpleSurface::applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter)
{
   if (!mBase) return;
   FilterList f;
   f.push_back(inFilter);

   Rect src_rect(inRect.w,inRect.h);
   Rect dest = GetFilteredObjectRect(f,src_rect);

   inSrc->IncRef();
   Surface *result = FilterBitmap(f, inSrc, src_rect, dest, false, false, ImagePoint(inRect.x,inRect.y) );

   dest.Translate(inOffset.x, inOffset.y);

   src_rect = Rect(0,0,result->Width(),result->Height());
   int dx = dest.x;
   int dy = dest.y;
   dest = dest.Intersect( Rect(0,0,mWidth,mHeight) );
   dest.Translate(-dx,-dy);
   dest = dest.Intersect( src_rect );
   dest.Translate(dx,dy);

   int bpp = BytesPP();

   RenderTarget t = BeginRender(dest,false);
   //printf("Copy back @ %d,%d %dx%d  + (%d,%d)\n", dest.x, dest.y, t.Width(), t.Height(), dx, dy);
   for(int y=0;y<t.Height();y++)
      memcpy((void *)(t.Row(y+dest.y)+(dest.x)*bpp), result->Row(y-dy)-dx*bpp, dest.w*bpp);

   EndRender();

   result->DecRef();
}

/* A MINSTD pseudo-random number generator.
 *
 * This generates a pseudo-random number sequence equivalent to std::minstd_rand0 from the C++11 standard library, which
 * is the generator that Flash uses to generate noise for BitmapData.noise().
 *
 * It is reimplemented here because std::minstd_rand0 is not available in earlier versions of C++.
 *
 * MINSTD was originally suggested in "A pseudo-random number generator for the System/360", P.A. Lewis, A.S. Goodman,
 * J.M. Miller, IBM Systems Journal, Vol. 8, No. 2, 1969, pp. 136-146 */
class MinstdGenerator
{
public:
   MinstdGenerator(unsigned int seed)
   {
      if (seed == 0) {
         x = 1U;
      } else {
         x = seed;
      }
   }

   unsigned int operator () ()
   {
      const unsigned int a = 16807U;
      const unsigned int m = (1U << 31) - 1;

      unsigned int lo = a * (x & 0xffffU);
      unsigned int hi = a * (x >> 16);
      lo += (hi & 0x7fffU) << 16;

      if (lo > m)
      {
         lo &= m;
         ++lo;
      }

      lo += hi >> 15;

      if (lo > m)
      {
         lo &= m;
         ++lo;
      }

      x = lo;

      return x;
   }

private:
   unsigned int x;
};

void SimpleSurface::noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale)
{
   if (!mBase)
      return;

   MinstdGenerator generator(randomSeed);

   RenderTarget target = BeginRender(Rect(0,0,mWidth,mHeight),false);
   ARGB tmpRgb;

   int range = high - low + 1;

   for (int y=0;y<mHeight;y++)
   {
      ARGB *rgb = ((ARGB *)target.Row(y));
      for(int x=0;x<mWidth;x++)
      {
         if (grayScale)
         {
            tmpRgb.r = tmpRgb.g = tmpRgb.b = low + generator() % (high - low + 1);
         }
         else
         {
            if (channelOptions & CHAN_RED)
               tmpRgb.r = low + generator() % range;
            else
               tmpRgb.r = 0;

            if (channelOptions & CHAN_GREEN)
               tmpRgb.g = low + generator() % range;
            else
               tmpRgb.g = 0;

            if (channelOptions & CHAN_BLUE)
               tmpRgb.b = low + generator() % range;
            else
               tmpRgb.b = 0;
         }

         if (channelOptions & CHAN_ALPHA)
            tmpRgb.a = low + generator() % range;
         else
            tmpRgb.a = 255;

         *rgb = tmpRgb;

         rgb++;
      }
   }
   
   EndRender();
}

void SimpleSurface::encodeStream(ObjectStreamOut &stream)
{
   stream.addInt(mWidth);
   stream.addInt(mHeight);
   stream.addInt((int)mPixelFormat);
   stream.data.append(mBase,GetBufferSize());
}


SimpleSurface *SimpleSurface::fromStream(ObjectStreamIn &inStream)
{
   int w = inStream.getInt();
   int h = inStream.getInt();
   PixelFormat pf = (PixelFormat)inStream.getInt();

   SimpleSurface *result = new SimpleSurface(w,h,pf);
   inStream.linkAbstract(result);
   int bytes = result->GetBufferSize();
   memcpy(result->mBase, inStream.getBytes( bytes ), bytes);
   return result;
}

enum
{
   FloatZeroMean   = 0x0001,
   Float128Mean    = 0x0002,
   FloatUnitScale  = 0x0004,
   FloatStdScale   = 0x0008,
   FloatSwizzeRgb  = 0x0010,
};


void SimpleSurface::getFloats32(float *outData, int inStride, PixelFormat inFormat, int inTransform, int inSubsample)
{
   std::vector<unsigned char> buffer;
   const unsigned char *ptr = mBase;
   // TODO - inSubsample
   int stride = mStride;
   int pixelSize = BytesPerPixel(inFormat);
   if (inFormat!=mPixelFormat)
   {
      stride = mWidth * pixelSize;
      buffer.resize( stride * mHeight );
      PixelConvert(mWidth, mHeight,
          mPixelFormat,  mBase, mStride, GetPlaneOffset(),
          inFormat, &buffer[0], stride, 0 );
      ptr = &buffer[0];
   }
   bool swizzleRgb = (inTransform & FloatSwizzeRgb );

   int histo[256];
   int ppr = mWidth * pixelSize;
   int count = ppr*mHeight;
   memset(histo, 0, sizeof(histo));
   for(int y=0;y<mHeight;y++)
   {
      const Uint8 *p = ptr + y*stride;
      for(int x=0;x<ppr;x++)
         histo[p[x]]++;
   }
   int n = 0;
   int sumX = 0;
   double sumX2 = 0;
   for(int i=0;i<256;i++)
   {
      n += histo[i];
      sumX += i*histo[i];
      sumX2 += i*i*histo[i];
   }
   if (!n)
      return;
   float lut[256];

   if (!inTransform)
   {
      for(int i=0;i<256;i++)
         lut[i] = i;
   }
   else if ( (inTransform & FloatUnitScale) && !(inTransform & FloatZeroMean) )
   {
      if (inTransform & Float128Mean)
         for(int i=0;i<256;i++)
            lut[i] = (double)(i-128)/255.0;
      else
         for(int i=0;i<256;i++)
            lut[i] = (double)i/255.0;
   }
   else
   {
      double mean = 0;
      if (inTransform & Float128Mean)
      {
         mean = 128.0;
      }
      else if (inTransform & FloatZeroMean)
      {
         double sum = 0;
         for(int i=0;i<256;i++)
            sum+=histo[i]*i;
         mean = (double)sum/count;
      }

      double scale = 1;
      if (inTransform & FloatUnitScale)
      {
         scale = 1.0/255;
      }
      else if (inTransform & FloatStdScale)
      {
         double sumSig2 = 0;
         for(int i=0;i<256;i++)
            sumSig2 += (i-mean)*(i-mean)*histo[i];
         if (sumSig2>0)
            scale = sqrt(count/sumSig2);
      }


      for(int i=0;i<256;i++)
         lut[i] = (i-mean)*scale;
   }

   float *dest = outData;
   for(int y=0;y<mHeight;y++)
   {
      const Uint8 *src = ptr + y*stride;
      if (inStride)
         dest = (float *)( (char *)outData + inStride*mHeight );

      if (swizzleRgb && inFormat==pfRGB)
      {
        for(int x=0;x<mWidth;x++)
        {
           *dest++ = lut[src[2]];
           *dest++ = lut[src[1]];
           *dest++ = lut[src[0]];
           src+=3;
        }
      }
      else
        for(int x=0;x<ppr;x++)
           *dest++ = lut[*src++];
   }
}

void SimpleSurface::setFloats32(const float *inData, int inStride, PixelFormat inFormat, int inTransform, int inExpand)
{
   std::vector<unsigned char> buffer;
   Uint8 *ptr = mBase;
   // TODO - inExpand

   int stride = mStride;
   int pixelSize = BytesPerPixel(inFormat);

   if (inFormat!=mPixelFormat)
   {
      stride = mWidth * pixelSize;
      buffer.resize( stride * mHeight );
      ptr = &buffer[0];
   }
   int ppr = mWidth * pixelSize;

   const float *src = inData;
   #define GET_FLOAT( EXPR ) { \
         for(int y=0;y<mHeight;y++) \
         { \
            Uint8 *dest = ptr + y*stride; \
            if (inStride) \
               src = (const float *)( (char *)inData + y*inStride ); \
            for(int x=0;x<ppr;x++) \
            { \
               float fval = EXPR ; \
               *dest++ = fval < 0.0f ? 0 : fval>=255.0f ? 255 : (int)fval; \
            } \
         } \
      }




   if (inTransform & Float128Mean)
   {
      if (inTransform & FloatUnitScale)
         GET_FLOAT( *src++ * 128.0f + 128.0f )
      else
         GET_FLOAT( *src++ + 128.0f )
   }
   else
   {
      if (inTransform & FloatUnitScale)
         GET_FLOAT( *src++ * 255.0f  )
      else
         GET_FLOAT( *src++  )
   }


   if (inFormat!=mPixelFormat)
   {
      PixelConvert(mWidth, mHeight,
          inFormat,  &buffer[0], stride, 0,
          mPixelFormat, mBase, mStride, 0 );
   }
}





// --- HardwareSurface -------------------------------------------------------------

HardwareSurface::HardwareSurface(HardwareRenderer *inContext)
{
   mHardware = inContext;
   mHardware->IncRef();
}

HardwareSurface::~HardwareSurface()
{
   mHardware->DecRef();
}

Surface *HardwareSurface::clone()
{
   // This is not really a clone...
   Surface *copy = new HardwareSurface(mHardware);
   copy->IncRef();
   return copy;

}

void HardwareSurface::getPixels(const Rect &inRect, uint32 *outPixels,bool inIgnoreOrder)
{
   memset(outPixels,0,Width()*Height()*4);
}

void HardwareSurface::setPixels(const Rect &inRect,const uint32 *outPixels,bool inIgnoreOrder)
{
}



// --- BitmapCache -----------------------------------------------------------------

const uint8 *BitmapCache::Row(int inRow) const
{
   return mBitmap->Row(inRow);
}


const uint8 *BitmapCache::DestRow(int inRow) const
{
   return mBitmap->Row(inRow-(mRect.y+mTY)) - mBitmap->BytesPP()*(mRect.x+mTX);
}


PixelFormat BitmapCache::Format() const
{
   return mBitmap->Format();
}

} // end namespace nme

