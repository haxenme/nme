#include <nme/Pixel.h>
#include <nme/Rect.h>

namespace nme
{

Uint8 gPremAlphaLut[256][256];
Uint8 gUnPremAlphaLut[256][256];


int pixelInit()
{
   for(int alpha=0; alpha<256; alpha++)
   {
      Uint8 *prem = gPremAlphaLut[alpha];
      Uint8 *unprem = gUnPremAlphaLut[alpha];
      int a256 = alpha + (alpha>>7);

      for(int r=0;r<256;r++)
      {
         prem[r] = (r*a256)>>8;
         unprem[r] = alpha==0 ? 0 : r>=alpha ? 255 : (r*255 + alpha/2)/alpha;
      }
   }

   return 1;
}

static int initMe = pixelInit();

int BytesPerPixel(PixelFormat pixelFormat)
{
   switch(pixelFormat)
   {
      case pfRGB:      return 3;
      case pfBGRA:     return 4;
      case pfBGRPremA: return 4;
      case pfRGBPremA: return 4;
      case pfRGBA:     return 4;
      case pfAlpha: return 1;
      case pfARGB4444: return 2;
      case pfRGB565: return 2;
      case pfLuma: return 1;
      case pfLumaAlpha: return 2;
      case pfUInt16: return 2;
      case pfUInt32: return 4;
      case pfRGB32f: return 12;
      case pfRGBA32f: return 16;
      default: ;
   }

   // hmmm
   return 1;
}


int GetPixelChannelOffset(PixelFormat inFormat, PixelChannel inChannel)
{
   if (inChannel==CHAN_ALPHA)
   {
      switch(inFormat)
      {
         case pfBGRPremA: case pfBGRA: return 3;
         case pfAlpha: return 0;
         case pfLumaAlpha: return 1;
         case pfRGBPremA: case pfRGBA: return 3;
         default: ;
      }
      return CHANNEL_OFFSET_VIRTUAL_ALPHA;
   }
   if (inChannel==CHAN_RED)
   {
      switch(inFormat)
      {
         case pfBGRA: case pfBGRPremA: return 2;
         case pfRGB: case pfRGBPremA: case pfRGBA: return 0;
         case pfLuma: case pfLumaAlpha: return 0;
         default: ;
      }
   }
   else if (inChannel==CHAN_GREEN)
   {
      switch(inFormat)
      {
         case pfBGRA: case pfBGRPremA: return 1;
         case pfRGB: case pfRGBPremA: case pfRGBA: return 1;
         case pfLuma: case pfLumaAlpha: return 0;
         default: ;
      }
   }
   else if (inChannel==CHAN_BLUE)
   {
      switch(inFormat)
      {
         case pfBGRA: case pfBGRPremA: return 0;
         case pfRGB: case pfRGBPremA: case pfRGBA: return 2;
         case pfLuma: case pfLumaAlpha: return 0;
         default: ;
      }
   }
   return CHANNEL_OFFSET_NONE;
}

struct PixelConvertJob
{
   PixelFormat destFormat;
   int width;
   int height;
   const Uint8 *srcPtr;
   int srcByteStride;
   int srcPlaneOffset;
   Uint8 *destPtr;
   int destByteStride;
   int destPlaneOffset;
};


template<typename SRC,typename DEST>
void TTPixelConvert(PixelConvertJob &job)
{
   int w = job.width;
   for(int y=0;y<job.height;y++)
   {
      const SRC *src = (const SRC *)(job.srcPtr + y*job.srcByteStride);
      DEST *dest = (DEST *)(job.destPtr + y*job.destByteStride);
      for(int x=0;x<w;x++)
         SetPixel(*dest++, *src++);
   }
}

template<typename SRC>
void TPixelConvert(PixelConvertJob &job)
{
   switch(job.destFormat)
   {
      case pfRGB: TTPixelConvert<SRC,RGB>(job); break;
      case pfBGRA: TTPixelConvert<SRC,ARGB>(job); break;
      case pfBGRPremA: TTPixelConvert<SRC,BGRPremA>(job); break;
      case pfAlpha: TTPixelConvert<SRC,AlphaPixel>(job); break;
      case pfLuma: TTPixelConvert<SRC,LumaPixel<unsigned char> >(job); break;
      case pfLumaAlpha: TTPixelConvert<SRC,LumaAlphaPixel>(job); break;
      case pfRGB32f: TTPixelConvert<SRC,RGB32f>(job); break;
      case pfRGBA32f: TTPixelConvert<SRC,RGBA32f>(job); break;
      case pfRGBA: TTPixelConvert<SRC,RGBA<false> >(job); break;
      case pfRGBPremA: TTPixelConvert<SRC,RGBA<true> >(job); break;
      case pfRGB565: TTPixelConvert<SRC,RGB565 >(job); break;
      case pfARGB4444: TTPixelConvert<SRC,ARGB4444 >(job); break;
      case pfUInt16: TTPixelConvert<SRC,LumaPixel<unsigned short> >(job); break;
      case pfUInt32: TTPixelConvert<SRC,LumaPixel<unsigned int> >(job); break;
      default: ; // TODO
   }
}

void PixelConvert(int inWidth, int inHeight,
       PixelFormat srcFormat,  const void *srcPtr, int srcByteStride, int srcPlaneOffset,
       PixelFormat destFormat, void *destPtr, int destByteStride, int destPlaneOffset )
{
   if (srcFormat==pfNone || destFormat==pfNone)
      return;

   if  (inWidth<=0 || inHeight<=0)
      return;

   PixelConvertJob job;
   job.destFormat = destFormat;
   job.width = inWidth;
   job.height = inHeight;
   job.srcPtr = (const Uint8 *)srcPtr;
   job.srcByteStride = srcByteStride;
   job.srcPlaneOffset = srcPlaneOffset;
   job.destPtr = (Uint8 *)destPtr;
   job.destByteStride = destByteStride;
   job.destPlaneOffset = destPlaneOffset;

   switch(srcFormat)
   {
      case pfRGB: TPixelConvert<RGB>(job); break;
      case pfBGRA: TPixelConvert<ARGB>(job); break;
      case pfBGRPremA: TPixelConvert<BGRPremA>(job); break;
      case pfAlpha: TPixelConvert<AlphaPixel>(job); break;
      case pfLuma: TPixelConvert<LumaPixel<unsigned char> >(job); break;
      case pfLumaAlpha: TPixelConvert<LumaAlphaPixel>(job); break;
      case pfRGB32f: TPixelConvert<RGB32f>(job); break;
      case pfRGBA32f: TPixelConvert<RGBA32f>(job); break;
      //case pfRGBA: TPixelConvert<RGBA<false> >(job); break;
      //case pfRGBPremA: TPixelConvert<RGBA<true> >(job); break;
      case pfRGB565: TPixelConvert<RGB565>(job); break;
      case pfARGB4444: TPixelConvert<ARGB4444>(job); break;
      case pfUInt16: TPixelConvert<LumaPixel<unsigned short> >(job); break;
      case pfUInt32: TPixelConvert<LumaPixel<unsigned int> >(job); break;
      default: ; // TODO
   }


   //pfECT
   //pfYUV420sp
   //pfOES
   //pfNV12
}

struct SetPixelRectJob
{
   int    argb;
   int    width;
   int    height;
   Uint8  *ptr;
   int    stride;
};

template<typename TYPE>
void TSetPixelRect(SetPixelRectJob job)
{
   TYPE src;
   ARGB argb(job.argb);
   SetPixel(src,argb);
   for(int y=0;y<job.height;y++)
   {
      TYPE *dest = (TYPE *)(job.ptr + job.stride*y);
      for(int x=0;x<job.width;x++)
         *dest++ = src;
   }
}


void SetPixelRect(unsigned int inRgb, const Rect &inRect,
                  PixelFormat inFormat, Uint8 *inPtr, int inStride)
{
   if (inRect.w<=0 || inRect.h<=0)
      return;

   SetPixelRectJob job;
   job.argb = inRgb;
   job.width = inRect.w;
   job.height = inRect.h;
   job.ptr = inPtr + inRect.y*inStride + inRect.x*BytesPerPixel(inFormat);
   job.stride = inStride;

   switch(inFormat)
   {
      case pfRGB: TSetPixelRect<RGB>(job); break;
      case pfBGRA: TSetPixelRect<ARGB>(job); break;
      case pfBGRPremA: TSetPixelRect<BGRPremA>(job); break;
      case pfAlpha: TSetPixelRect<AlphaPixel>(job); break;
      case pfLuma: TSetPixelRect<LumaPixel<Uint8> >(job); break;
      case pfLumaAlpha: TSetPixelRect<LumaAlphaPixel>(job); break;
      case pfRGB32f: TSetPixelRect<RGB32f>(job); break;
      case pfRGBA32f: TSetPixelRect<RGBA32f>(job); break;
      case pfRGBA: TSetPixelRect<RGBA<false> >(job); break;
      case pfRGBPremA: TSetPixelRect<RGBA<true> >(job); break;
      case pfRGB565: TSetPixelRect<RGB565>(job); break;
      case pfARGB4444: TSetPixelRect<ARGB4444>(job); break;
      case pfUInt16: TSetPixelRect<LumaPixel<unsigned short> >(job); break;
      case pfUInt32: TSetPixelRect<LumaPixel<unsigned int> >(job); break;
      default: ; // TODO
   }
}




}
