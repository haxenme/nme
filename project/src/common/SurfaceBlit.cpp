#include <Graphics.h>
#include <Surface.h>
#include <nme/Pixel.h>

namespace nme
{

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
   #if defined(__clang__) && defined(HXCPP_ARM64)
   static inline uint8 comp(uint8 a, uint8 b) { return (a  * b ) / 255; }
   static inline uint8 alpha(uint8 a, uint8 b) { return (a  * b )/ 255; }
   #else
   static inline uint8 comp(uint8 a, uint8 b) { return ( ( a + (a>>7)) * b ) >> 8; }
   static inline uint8 alpha(uint8 a, uint8 b) { return ( ( a + (a>>7)) * b ) >> 8; }
   #endif
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



} // end namespace nme

