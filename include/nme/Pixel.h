#ifndef NME_PIXEL_H
#define NME_PIXEL_H

#include "Rect.h"

#ifdef RGB
 #undef RGB
#endif

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

   pfLuma        = 4,
   pfLumaAlpha   = 5,
   pfRGB32f      = 6,
   pfRGBA32f     = 7,

   // These formats are only used to transfer data to the GPU on systems that do
   //  not support the preferred pfBGRPremA format
   pfRGBPremA   = 8,
   pfRGBA       = 9,

   pfARGB4444,
   pfRGB565,

   pfECT,
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
inline bool HasAlphaChannel(PixelFormat inFormat) { return GetPixelChannelOffset(inFormat, CHAN_ALPHA)>=0; }
inline bool IsPremultipliedAlpha(PixelFormat inFormat) { return inFormat==pfBGRPremA || inFormat==pfRGBPremA; }

typedef unsigned char Uint8;

extern Uint8 gPremAlphaLut[256][256];
extern Uint8 gUnPremAlphaLut[256][256];


template<bool PREM>
struct BGRA
{
   enum { pixelFormat = PREM ? pfBGRPremA : pfBGRA };

   inline BGRA() { }
   inline BGRA(int inRGBA) { ival = inRGBA; }
   inline BGRA(int inRGB,int inA) { ival = (inRGB & 0xffffff) | (inA<<24); }
   inline BGRA(int inRGB,float inA)
   {
      ival = (inRGB & 0xffffff);
      int alpha = 255.9 * inA;
      a = alpha<0 ? 0 : alpha >255 ? 255 : alpha;
   }

   inline int ToInt() const { return ival; }
   inline void Set(int inVal) { ival = inVal; }
   inline void SetRGB(int inVal) { ival = inVal | 0xff000000; }
   inline void SetRGBA(int inVal) { ival = inVal; }
   inline int luma() const { return (r + (g<<1) + b + 2) >> 8; }

   inline int getAlpha() const { return a; }
   inline int getRAlpha() const { return PREM ? r : gPremAlphaLut[a][r]; }
   inline int getGAlpha() const { return PREM ? g : gPremAlphaLut[a][g]; }
   inline int getBAlpha() const { return PREM ? b : gPremAlphaLut[a][b]; }
   inline int getR() const { return PREM ? gUnPremAlphaLut[a][r] : r; }
   inline int getG() const { return PREM ? gUnPremAlphaLut[a][g] : g; }
   inline int getB() const { return PREM ? gUnPremAlphaLut[a][b] : b; }
   inline int getLuma() const { return PREM ? gUnPremAlphaLut[a][(r+(g<<1)+b)>>2] : (r+(g<<1)+b)>>2; }

   union
   {
      struct { Uint8 b,g,r,a; };
      unsigned int  ival;
   };
};






template<bool PREM>
struct RGBA
{
   enum { pixelFormat = PREM ? pfBGRPremA : pfBGRA };

   inline RGBA() { }

   inline int luma() const { return (r + (g<<1) + b + 2) >> 8; }

   inline int getAlpha() const { return a; }
   inline int getRAlpha() const { return PREM ? r : gPremAlphaLut[a][r]; }
   inline int getGAlpha() const { return PREM ? g : gPremAlphaLut[a][g]; }
   inline int getBAlpha() const { return PREM ? b : gPremAlphaLut[a][b]; }
   inline int getR() const { return PREM ? gUnPremAlphaLut[a][r] : r; }
   inline int getG() const { return PREM ? gUnPremAlphaLut[a][g] : g; }
   inline int getB() const { return PREM ? gUnPremAlphaLut[a][b] : b; }
   inline int getLuma() const { return PREM ? gUnPremAlphaLut[a][(r+(g<<1)+b)>>2] : (r+(g<<1)+b)>>2; }

   union
   {
      struct { Uint8 r,g,b,a; };
      unsigned int  ival;
   };
};



typedef BGRA<false> ARGB;
typedef BGRA<true>  BGRPremA;


struct RGB
{
   enum { pixelFormat =pfRGB };

   inline RGB() { }
   inline RGB(int inRGBA)
   {
      r = (inRGBA>>16) & 0xff;
      g = (inRGBA>>8) & 0xff;
      b = inRGBA & 0xff;
   }
   inline int getLuma() const { return (r+(g<<1)+b)>>2; }
   inline int getAlpha() const { return 255; }
   inline int getRAlpha() const { return r; }
   inline int getGAlpha() const { return g; }
   inline int getBAlpha() const { return b; }
   inline int getR() const { return r; }
   inline int getG() const { return g; }
   inline int getB() const { return b; }

   Uint8 r,g,b;
};


struct RGB32f
{
   enum { pixelFormat =pfRGB32f };

   inline RGB32f() { }
   inline int getLuma() const { return (r+g*2.0+b)*(0.25*255); }
   inline int getAlpha() const { return 255; }
   inline int getRAlpha() const { return r*255.0; }
   inline int getGAlpha() const { return g*255.0; }
   inline int getBAlpha() const { return b*255.0; }
   inline int getR() const { return r*255.0; }
   inline int getG() const { return g*255.0; }
   inline int getB() const { return b*255.0; }

   float r,g,b;
};


struct RGBA32f
{
   enum { pixelFormat =pfRGBA32f };

   inline RGBA32f() { }
   inline int getLuma() const { return (r+g*2.0+b)*(0.25*255); }
   inline int getAlpha() const { return a*255.0; }
   inline int getRAlpha() const { return r*a*255.0; }
   inline int getGAlpha() const { return g*a*255.0; }
   inline int getBAlpha() const { return b*a*255.0; }
   inline int getR() const { return r*255.0; }
   inline int getG() const { return g*255.0; }
   inline int getB() const { return b*255.0; }

   float r,g,b,a;
};


struct AlphaPixel
{
   enum { pixelFormat =pfAlpha };

   inline AlphaPixel() { }

   inline int getAlpha() const { return a; }
   inline int getRAlpha() const { return a; }
   inline int getGAlpha() const { return a; }
   inline int getBAlpha() const { return a; }
   inline int getR() const { return 255; }
   inline int getG() const { return 255; }
   inline int getB() const { return 255; }
   inline int getLuma() const { return 255; }

   Uint8 a;
};


struct LumaPixel
{
   enum { pixelFormat =pfLuma };

   inline LumaPixel() { }

   inline int getLuma() const { return luma; }
   inline int getAlpha() const { return 255; }
   inline int getRAlpha() const { return luma; }
   inline int getGAlpha() const { return luma; }
   inline int getBAlpha() const { return luma; }
   inline int getR() const { return luma; }
   inline int getG() const { return luma; }
   inline int getB() const { return luma; }

   Uint8 luma;
};


struct LumaAlphaPixel
{
   enum { pixelFormat =pfLumaAlpha };

   inline LumaAlphaPixel() { }

   inline int getLuma() const { return luma; }
   inline int getAlpha() const { return a; }
   inline int getRAlpha() const { return gPremAlphaLut[a][luma]; }
   inline int getGAlpha() const { return gPremAlphaLut[a][luma]; }
   inline int getBAlpha() const { return gPremAlphaLut[a][luma]; }
   inline int getR() const { return luma; }
   inline int getG() const { return luma; }
   inline int getB() const { return luma; }

   Uint8 luma;
   Uint8 a;
};


struct RGB565
{
   enum { pixelFormat =pfLumaAlpha };

   inline RGB565() { }

   inline int getAlpha() const { return 255; }
   inline int getR() const { return (rgb>>8) & 0xf8; }
   inline int getG() const { return (rgb>>3) & 0xfc; }
   inline int getB() const { return (rgb<<3) & 0xf8; }
   inline int getRAlpha() const { return getR(); }
   inline int getGAlpha() const { return getG(); }
   inline int getBAlpha() const { return getB(); }
   inline int getLuma() const { return (getR() + (getG()<<1) + getB())>>2; }

   unsigned short rgb;
};


struct ARGB4444
{
   enum { pixelFormat =pfLumaAlpha };

   inline ARGB4444() { }

   inline int getAlpha() const { return (argb<<4) & 0xf0; }
   inline int getR() const { return (argb>>4) & 0xf0; }
   inline int getG() const { return (argb   ) & 0xf0; }
   inline int getB() const { return (argb<<4) & 0xf0; }
   inline int getRAlpha() const { return getR()*getAlpha()/0xf0; }
   inline int getGAlpha() const { return getG()*getAlpha()/0xf0; }
   inline int getBAlpha() const { return getB()*getAlpha()/0xf0; }
   inline int getLuma() const { return (getR() + (getG()<<1) + getB())>>2; }

   unsigned short argb;
};

// --- SetPixel ----

// --- Set BGRA ---
inline void SetPixel(BGRA<true> &outBgra, const AlphaPixel &inAlpha)
{
   outBgra.r = outBgra.g = outBgra.b = 255;
   outBgra.a = inAlpha.a;
}

inline void SetPixel(BGRA<false> &outBgra, const AlphaPixel &inAlpha)
{
   outBgra.a = outBgra.r = outBgra.g = outBgra.b = inAlpha.a;
}


inline void SetPixel(BGRA<true> &outBgra, const BGRA<true> &inBgra)
{
  outBgra.ival = inBgra.ival;
}

inline void SetPixel(BGRA<false> &outBgra, const BGRA<false> &inBgra)
{
  outBgra.ival = inBgra.ival;
}

inline void SetPixel(BGRA<false> &outBgra, const BGRA<true> &inBgra)
{
   const Uint8 *aLut = gUnPremAlphaLut[inBgra.a];
   outBgra.r = aLut[inBgra.r];
   outBgra.g = aLut[inBgra.g];
   outBgra.b = aLut[inBgra.b];
   outBgra.a = inBgra.a;
}


inline void SetPixel(BGRA<true> &outBgra, const BGRA<false> &inBgra)
{
   const Uint8 *aLut = gPremAlphaLut[inBgra.a];
   outBgra.r = aLut[inBgra.r];
   outBgra.g = aLut[inBgra.g];
   outBgra.b = aLut[inBgra.b];
   outBgra.a = inBgra.a;
}


template<typename SRC>
inline void SetPixel(BGRA<false> &outBgra, const SRC &inBgra)
{
   outBgra.r = inBgra.getR();
   outBgra.g = inBgra.getG();
   outBgra.b = inBgra.getB();
   outBgra.a = inBgra.getAlpha();
}

template<typename SRC>
inline void SetPixel(BGRA<true> &outBgra, const SRC &inBgra)
{
   outBgra.r = inBgra.getRAlpha();
   outBgra.g = inBgra.getGAlpha();
   outBgra.b = inBgra.getBAlpha();
   outBgra.a = inBgra.getAlpha();
}

// --- Set RGBA ---

template<bool PREM>
inline void SetPixel(RGBA<PREM> &outRGBA, const RGBA<PREM> &inRGBA)
{
   outRGBA.ival = inRGBA.ival;
}

template<typename SRC>
inline void SetPixel(RGBA<true> &outRGBA, const SRC &inSRC)
{
   outRGBA.r = inSRC.getRAlpha();
   outRGBA.g = inSRC.getGAlpha();
   outRGBA.b = inSRC.getBAlpha();
   outRGBA.a = inSRC.getAlpha();
}


template<typename SRC>
inline void SetPixel(RGBA<false> &outRGBA, const SRC &inSRC)
{
   outRGBA.r = inSRC.getR();
   outRGBA.g = inSRC.getG();
   outRGBA.b = inSRC.getB();
   outRGBA.a = inSRC.getAlpha();
}

// --- Set AlphaPixel ---
template<typename SRC>
inline void SetPixel(AlphaPixel &outA, const SRC &inSrc)
{
   outA.a = inSrc.getAlpha();
}

template<typename SRC>
inline void SetPixel(LumaPixel &outLuma, const SRC &inSrc)
{
   outLuma.luma = inSrc.getLuma();
}

// --- LumaAlphaPixel ---

template<typename SRC>
inline void SetPixel(LumaAlphaPixel &outLumaA, const SRC &inSrc)
{
   outLumaA.luma = inSrc.getLuma();
   outLumaA.a = inSrc.getAlpha();
}

// --- RGB32f ---

inline void SetPixel(RGB32f &outRGB, const RGB32f &inSrc)
{
   outRGB = inSrc;
}

inline void SetPixel(RGB32f &outRGB, const RGBA32f &inSrc)
{
   outRGB.r = inSrc.r;
   outRGB.g = inSrc.g;
   outRGB.b = inSrc.b;
}

template<typename SRC>
inline void SetPixel(RGB32f &outRGB, const SRC &inSrc)
{
   outRGB.r = inSrc.getR()*(1.0/255.0);
   outRGB.g = inSrc.getG()*(1.0/255.0);
   outRGB.b = inSrc.getB()*(1.0/255.0);
}


// --- RGBA32f ---

inline void SetPixel(RGBA32f &outRGB, const RGBA32f &inSrc)
{
   outRGB = inSrc;
}

inline void SetPixel(RGBA32f &outRGB, const RGB32f &inSrc)
{
   outRGB.r = inSrc.r;
   outRGB.g = inSrc.g;
   outRGB.b = inSrc.b;
   outRGB.a = 1.0;
}

template<typename SRC>
inline void SetPixel(RGBA32f &outRGB, const SRC &inSrc)
{
   outRGB.r = inSrc.getR()*(1.0/255.0);
   outRGB.g = inSrc.getG()*(1.0/255.0);
   outRGB.b = inSrc.getB()*(1.0/255.0);
   outRGB.a = inSrc.getAlpha()*(1.0/255.0);
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

inline void SetPixel(RGB &outRgb, const RGB &inRgb)
{
   outRgb = inRgb;
}


template<typename SRC>
inline void SetPixel(RGB &outRgb, const SRC &inSrc)
{
   outRgb.r = inSrc.getR();
   outRgb.g = inSrc.getG();
   outRgb.b = inSrc.getB();
}


// --- RGB565 ----

inline void SetPixel(RGB565 &outRgb, const RGB565 &inSrc)
{
   outRgb.rgb = inSrc.rgb;
}

template<typename SRC>
inline void SetPixel(RGB565 &outRgb, const SRC &inSrc)
{
   outRgb.rgb = ( (inSrc.getR() & 0xf8) << 8 ) |
                ( (inSrc.getG() & 0xfc) << 3 ) |
                ( (inSrc.getB()       ) >> 3 );
}


// --- ARGB4444 ----

inline void SetPixel(ARGB4444 &outRgb, const ARGB4444 &inSrc)
{
   outRgb.argb = inSrc.argb;
}

template<typename SRC>
inline void SetPixel(ARGB4444 &outRgba, const SRC &inSrc)
{
   outRgba.argb = ( (inSrc.getAlpha() & 0xf0) << 8 ) |
                  ( (inSrc.getR() & 0xf0) << 4 ) |
                  ( (inSrc.getG() & 0xf0)      ) |
                  ( (inSrc.getB()       ) >> 4 );
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



template<bool Prem>
inline BGRA<Prem> BilinearInterp( BGRA<Prem> s00, BGRA<Prem> s01, BGRA<Prem> s10, BGRA<Prem> s11, int x_frac, int y_frac)
{
   BGRA<Prem> s;

   int c0_0 = s00.r + (((s01.r-s00.r)*x_frac) >> 16);
   int c0_1 = s10.r + (((s11.r-s10.r)*x_frac) >> 16);
   s.r = c0_0 + (((c0_1-c0_0)*y_frac) >> 16);

   int c1_0 = s00.g + (((s01.g-s00.g)*x_frac) >> 16);
   int c1_1 = s10.g + (((s11.g-s10.g)*x_frac) >> 16);
   s.g = c1_0 + (((c1_1-c1_0)*y_frac) >> 16);

   int c2_0 = s00.b + (((s01.b-s00.b)*x_frac) >> 16);
   int c2_1 = s10.b + (((s11.b-s10.b)*x_frac) >> 16);
   s.b = c2_0 + (((c2_1-c2_0)*y_frac) >> 16);


   int ca_0 = s00.a + (((s01.a-s00.a)*x_frac) >> 16);
   int ca_1 = s10.a + (((s11.a-s10.a)*x_frac) >> 16);
   s.a = ca_0 + (((ca_1-ca_0)*y_frac) >> 16);

   return s;
}


inline RGB BilinearInterp( RGB s00, RGB s01, RGB s10, RGB s11, int x_frac, int y_frac)
{
   RGB s;

   int c0_0 = s00.r + (((s01.r-s00.r)*x_frac) >> 16);
   int c0_1 = s10.r + (((s11.r-s10.r)*x_frac) >> 16);
   s.r = c0_0 + (((c0_1-c0_0)*y_frac) >> 16);

   int c1_0 = s00.g + (((s01.g-s00.g)*x_frac) >> 16);
   int c1_1 = s10.g + (((s11.g-s10.g)*x_frac) >> 16);
   s.g = c1_0 + (((c1_1-c1_0)*y_frac) >> 16);

   int c2_0 = s00.b + (((s01.b-s00.b)*x_frac) >> 16);
   int c2_1 = s10.b + (((s11.b-s10.b)*x_frac) >> 16);
   s.b = c2_0 + (((c2_1-c2_0)*y_frac) >> 16);

   return s;
}


inline AlphaPixel BilinearInterp( AlphaPixel s00, AlphaPixel s01, AlphaPixel s10, AlphaPixel s11, int x_frac, int y_frac)
{
   AlphaPixel s;

   int ca_0 = s00.a + (((s01.a-s00.a)*x_frac) >> 16);
   int ca_1 = s10.a + (((s11.a-s10.a)*x_frac) >> 16);
   s.a = ca_0 + (((ca_1-ca_0)*y_frac) >> 16);
   return s;
}










inline void BlendAlpha(Uint8 &ioDest, int inSrc)
{
   if (inSrc==255)
      ioDest = 255;
   else if (inSrc)
      ioDest = 255 - ((255 - inSrc) * (255-ioDest) >> 8);
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
