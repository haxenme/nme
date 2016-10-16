#ifndef NME_PIXEL_H
#define NME_PIXEL_H

#include "Rect.h"

// The order or RGB or BGR is determined to the primary surface's
//  native order - this allows most transfers to be donw without swapping R & B
// When rendering from a source to a dest, the source is swapped to match in
//  the blending code.

namespace nme
{


// Component order refers to byte-layout in memory
enum PixelFormat
{
   pfNone       = -1,

   // 3 Bytes per pixel
   pfRGB        = 0,
   // 0xAARRGGBB on little-endian = flash native format
   // This can generally be loaded right into the GPU (android simulator - maybe not)
   pfBGRA       = 1,
   // Has the B,G,R components multiplied by A
   pfBGRPremA   = 2,

   // 8-bit alpha
   pfAlpha      = 3,

   // The first 4 pixel formats are supported as render sources/ render distinations
   pfRenderToCount = 4,

   // These formats are only used to transfer data to the GPU on systems that do
   //  not support the preferred pfBGRPremA format
   pfRGBPremA   = 4,
   pfRGBA       = 5,

   pfARGB4444   = 7,
   pfRGB565,
   pfLuma,
   pfLumaAlpha,
   pfECT,
   pfRGB32f,
   pfRGBA32f,
   pfYUV420sp,
   pfNV12,
   pfOES,
   pfRenderBuffer,
};

enum PixelChannel
{
   CHAN_ALPHA = 0x0008,
   CHAN_BLUE  = 0x0004,
   CHAN_GREEN = 0x0002,
   CHAN_RED   = 0x0001,
};

enum { CHANNEL_OFFSET_VIRTUAL_ALPHA = -1, CHANNEL_OFFSET_NONE = -2 };
int GetPixelChannelOffset(PixelFormat inFormat, PixelChannel inChannel);

typedef unsigned char Uint8;

extern Uint8 gPremAlphaLut[256][256];
extern Uint8 gUnPremAlphaLut[256][256];


template<bool PREM>
struct BGRA
{
   inline BGRA() { }
   inline BGRA(int inRGBA) { ival = inRGBA; }
   inline BGRA(int inRGB,int inA) { ival = (inRGB & 0xffffff) | (inA<<24); }
   inline BGRA(int inRGB,float inA)
   {
      ival = (inRGB & 0xffffff);
      int alpha = 255.9 * inA;
      a = alpha<0 ? 0 : alpha >255 ? 255 : alpha;
   }

   inline float getRedFloat() { return r/255.0; }
   inline float getGreenFloat() { return g/255.0; }
   inline float getBlueFloat() { return b/255.0; }
   inline float getAlphaFloat() { return a/255.0; }

   inline int ToInt() const { return ival; }
   inline void Set(int inVal) { ival = inVal; }
   inline void SetRGB(int inVal) { ival = inVal | 0xff000000; }
   inline void SetRGBA(int inVal) { ival = inVal; }
   inline int luma() { return (r + (g<<1) + b + 2) >> 8; }

   inline int getAlpha() { return a; }
   inline int getRAlpha() { return PREM ? r : gPremAlphaLut[a][r]; }
   inline int getGAlpha() { return PREM ? g : gPremAlphaLut[a][g]; }
   inline int getBAlpha() { return PREM ? b : gPremAlphaLut[a][b]; }
   inline int getR() { return r; }
   inline int getG() { return g; }
   inline int getB() { return b; }

   template<bool DEST_ALPHA>
   inline void Blend(const BGRA &inVal)
   {
      int A = inVal.a + (inVal.a>>7);
      if (A>5)
      {
         // Replace if input is full, or we are empty
         if (A>250 || (DEST_ALPHA && a<5) )
         {
            ival = inVal.ival;
         }
         // Our alpha is implicitly 256 ...
         else if (!DEST_ALPHA)
         {
            int f = 256-A;
            r = (A*inVal.r + f*r)>>8;
            g = (A*inVal.g + f*g)>>8;
            b = (A*inVal.b + f*b)>>8;
         }
         else
         {
            int alpha16 = ((a + A)<<8) - a*A;
            int f = (256-A) * a;
            A<<=8;
            r = (A*inVal.r + f*r)/alpha16;
            g = (A*inVal.g + f*g)/alpha16;
            b = (A*inVal.b + f*b)/alpha16;
            a = alpha16>>8;
         }
      }
   }


   inline void QBlend(BGRA inVal)
   {
      int A = inVal.a + (inVal.a>>7);
      int f = (256-A);
      b = (A*inVal.b + f*b)>>8;
      g = (A*inVal.g + f*g)>>8;
      r = (A*inVal.r + f*r)>>8;
   }

   inline void QBlendA(BGRA inVal)
   {
      int A = inVal.a + (inVal.a>>7);
      int alpha16 = ((a + A)<<8) - a*A;
      int f = (256-A) * a;
      A<<=8;
      b = (A*inVal.b + f*b)/alpha16;
      g = (A*inVal.g + f*g)/alpha16;
      r = (A*inVal.r + f*r)/alpha16;
      a = alpha16>>8;
   }

   inline void TBlend_0(const BGRA &inVal) { Blend<false>(inVal); }
   inline void TBlend_1(const BGRA &inVal) { Blend<true >(inVal); }

   union
   {
      struct { Uint8 b,g,r,a; };
      unsigned int  ival;
   };
};


typedef BGRA<false> ARGB;
typedef BGRA<true>  BGRPrem;


struct RGB
{
   inline RGB() { }
   inline RGB(int inRGBA)
   {
      r = (inRGBA>>16) & 0xff;
      g = (inRGBA>>8) & 0xff;
      b = inRGBA & 0xff;
   }
   inline int getAlpha() { return 255; }
   inline int getRAlpha() { return r; }
   inline int getGAlpha() { return g; }
   inline int getBAlpha() { return b; }
   inline int getR() { return r; }
   inline int getG() { return g; }
   inline int getB() { return b; }

   Uint8 r,g,b;
};


struct AlphaPixel
{
   inline AlphaPixel() { }

   inline int getAlpha() { return a; }
   inline int getRAlpha() { return a; }
   inline int getGAlpha() { return a; }
   inline int getBAlpha() { return a; }
   inline int getR() { return 255; }
   inline int getG() { return 255; }
   inline int getB() { return 255; }

   Uint8 a;
};


// --- SetPixel ----

// --- Set BGRA ---
template<bool Prem>
inline void SetPixel(BGRA<Prem> &outBgra, const RGB &inRgb)
{
   outBgra.r = inRgb.r;
   outBgra.g = inRgb.g;
   outBgra.b = inRgb.b;
   outBgra.a = 255;
}


template<bool Prem>
inline void SetPixel(BGRA<Prem> &outBgra, const AlphaPixel &inAlpha)
{
   if (Prem)
      outBgra.r = outBgra.g = outBgra.b = 255;
   else
      outBgra.r = outBgra.g = outBgra.b = inAlpha.a;

   outBgra.a = inAlpha.a;
}


template<bool Prem0, bool Prem1>
inline void SetPixel(BGRA<Prem0> &outBgra, const BGRA<Prem1> &inBgra)
{
   if (Prem0==Prem1)
      outBgra.i = inBgra.i;
   else
   {
      const Uint8 *aLut = Prem0 ? gPremAlphaLut[inBgra.a] : gUnPremAlphaLut[inBgra.a];
      outBgra.r = aLut[inBgra.r];
      outBgra.g = aLut[inBgra.g];
      outBgra.b = aLut[inBgra.b];
      outBgra.a = inBgra.a;
   }
}

// --- Set AlphaPixel ---
template<bool Prem>
inline void SetPixel(AlphaPixel &outA, const BGRA<Prem> &inBgra)
{
   outA.a = inBgra.a;
}

template<bool Prem>
inline void SetPixel(AlphaPixel &outA, const RGB &)
{
   outA.a = 255;
}


inline void SetPixel(AlphaPixel &outA, const AlphaPixel &inA)
{
   outA.a = inA.a;
}

// --- Set RGB ---

template<bool Prem>
inline void SetPixel(RGB &outRgb, const BGRA<Prem> &inBgra)
{
   if (Prem)
   {
      const Uint8 *aLut = gUnPremAlphaLut[inBgra.a];
      outRgb.r = aLut[inBgra.r];
      outRgb.g = aLut[inBgra.g];
      outRgb.b = aLut[inBgra.b];
   }
   else
   {
      outRgb.r = inBgra.r;
      outRgb.g = inBgra.g;
      outRgb.b = inBgra.b;
   }
}

template<bool Prem>
inline void SetPixel(RGB &outRgb, const RGB &inRgb)
{
   outRgb = inRgb;
}


inline void SetPixel(RGB &outRgb, const AlphaPixel &inA)
{
   outRgb.r = 255;
   outRgb.g = 255;
   outRgb.b = 255;
}

// --- BlendPixel ---
// --- BGRA ---
template<bool Prem0, typename T>
inline void BlendPixel(BGRA<Prem0> &outBgra, const T &inPixel)
{
   if (inPixel.getAlpha()==0)
   {
      // nothing
   }
   else if (inPixel.getAlpha()==255)
   {
      SetPixel(outBgra,inPixel);
   }
   else
   {
      int notA= 256-inPixel.getAlpha();
      outBgra.a = inPixel.getAlpha()+ ((outBgra.a*notA)>>8);
      outBgra.r = ((outBgra.r*notA)>>8) + inPixel.getRAlpha();
      outBgra.g = ((outBgra.g*notA)>>8) + inPixel.getGAlpha();
      outBgra.b = ((outBgra.b*notA)>>8) + inPixel.getBAlpha();
   }
}

template<typename T>
inline void BlendPixel(AlphaPixel &outA, const T &inPixel)
{
   int notA= 256-inPixel.getAlpha();
   outA.a = inPixel.getAlpha() + ((outA.a*notA)>>8);
}

inline void BlendPixel(AlphaPixel &outA, const RGB &)
{
   outA.a = 255;
}


template<typename T>
inline void BlendPixel(RGB &outRgb, const T &inPixel)
{
   if (!inPixel.getAlpha())
   {
   }
   else if (inPixel.getAlpha()==255)
   {
      outRgb.r = inPixel.getR();
      outRgb.g = inPixel.getG();
      outRgb.b = inPixel.getB();
   }
   else
   {
      int notA= 256-inPixel.getAlpha();
      outRgb.r = ((outRgb.r*notA)>>8) + inPixel.getRAlpha();
      outRgb.g = ((outRgb.g*notA)>>8) + inPixel.getGAlpha();
      outRgb.b = ((outRgb.b*notA)>>8) + inPixel.getBAlpha();
   }
}

template<bool Prem>
inline void BlendPixel(RGB &outRgb, const RGB &inRgb)
{
   outRgb = inRgb;
}


inline void BlendPixel(RGB &outRgb, const AlphaPixel &inA)
{
   outRgb.r = 255;
   outRgb.g = 255;
   outRgb.b = 255;
}











inline void BlendAlpha(Uint8 &ioDest, Uint8 inSrc)
{
   if (inSrc)
   {
      if (inSrc==255)
         ioDest = 255;
      else
         ioDest = 255 - ((255 - inSrc) * (255-ioDest) >> 8);
   }
}

inline void BlendAlpha(Uint8 &ioDest, const ARGB &inSrc)
{
   if (inSrc.a)
   {
      if (inSrc.a==255)
         ioDest = 255;
      else
         ioDest = 255 - ((255 - inSrc.a) * (255-ioDest) >> 8);
   }
}


inline void QBlendAlpha(Uint8 &ioDest, Uint8 inSrc)
{
   ioDest = 255 - ((255 - inSrc) * (255-ioDest) >> 8);
}


void PixelConvert(int inWidth, int inHeight,
       PixelFormat srcFormat,  const void *srcPtr, int srcByteStride, int srcPlaneOffset,
       PixelFormat destFormat, void *destPtr, int destByteStride, int destPlaneOffset );

int BytesPerPixel(PixelFormat inFormat);

   void SetPixelRect(unsigned int inRgb, const Rect &inRect,
                  PixelFormat inFormat, Uint8 *inPtr, int inStride);


} // end namespace nme

#endif
