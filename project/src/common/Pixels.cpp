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

      for(int r=0;r<256;r++)
      {
         prem[r] = (r*alpha+127)/255;
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
      case pfAlpha: return 1;
      case pfARGB4444: return 2;
      case pfRGB565: return 2;
      case pfLuma: return 1;
      case pfLumaAlpha: return 2;
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
      }
   }
   else if (inChannel==CHAN_GREEN)
   {
      switch(inFormat)
      {
         case pfBGRA: case pfBGRPremA: return 1;
         case pfRGB: case pfRGBPremA: case pfRGBA: return 1;
         case pfLuma: case pfLumaAlpha: return 0;
      }
   }
   else if (inChannel==CHAN_BLUE)
   {
      switch(inFormat)
      {
         case pfBGRA: case pfBGRPremA: return 0;
         case pfRGB: case pfRGBPremA: case pfRGBA: return 2;
         case pfLuma: case pfLumaAlpha: return 0;
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
      case pfLuma: TTPixelConvert<SRC,LumaPixel>(job); break;
      case pfLumaAlpha: TTPixelConvert<SRC,LumaAlphaPixel>(job); break;
      case pfRGB32f: TTPixelConvert<SRC,RGB32f>(job); break;
      case pfRGBA32f: TTPixelConvert<SRC,RGBA32f>(job); break;
      case pfRGBA: TTPixelConvert<SRC,RGBA<false> >(job); break;
      case pfRGBPremA: TTPixelConvert<SRC,RGBA<true> >(job); break;
      case pfRGB565: TTPixelConvert<SRC,RGB565 >(job); break;
      case pfARGB4444: TTPixelConvert<SRC,ARGB4444 >(job); break;
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
      case pfLuma: TPixelConvert<LumaPixel>(job); break;
      case pfLumaAlpha: TPixelConvert<LumaAlphaPixel>(job); break;
      case pfRGB32f: TPixelConvert<RGB32f>(job); break;
      case pfRGBA32f: TPixelConvert<RGBA32f>(job); break;
      //case pfRGBA: TPixelConvert<RGBA<false> >(job); break;
      //case pfRGBPremA: TPixelConvert<RGBA<true> >(job); break;
      case pfRGB565: TPixelConvert<RGB565>(job); break;
      case pfARGB4444: TPixelConvert<ARGB4444>(job); break;
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
      case pfLuma: TSetPixelRect<LumaPixel>(job); break;
      case pfLumaAlpha: TSetPixelRect<LumaAlphaPixel>(job); break;
      case pfRGB32f: TSetPixelRect<RGB32f>(job); break;
      case pfRGBA32f: TSetPixelRect<RGBA32f>(job); break;
      case pfRGBA: TSetPixelRect<RGBA<false> >(job); break;
      case pfRGBPremA: TSetPixelRect<RGBA<true> >(job); break;
      case pfRGB565: TSetPixelRect<RGB565>(job); break;
      case pfARGB4444: TSetPixelRect<ARGB4444>(job); break;
   }

}


#if 0
void RGBX_to_RGB565(uint8 *outDest, const uint8 *inSrc, int inPixels)
{
   unsigned short *dest = (unsigned short *)outDest;
   const uint8 *src = inSrc;
   for(int x=0;x<inPixels;x++)
   {
       *dest++ = ( (src[0]<<8) & 0xf800 ) |
                 ( (src[1]<<3) & 0x07e0 ) |
                 ( (src[2]>>3)          );
       src += 4;
   }
}
 
 
void RGBA_to_RGBA4444(uint8 *outDest, const uint8 *inSrc, int inPixels)
{
   unsigned short *dest = (unsigned short *)outDest;
   const uint8 *src = inSrc;
   for(int x=0;x<inPixels;x++)
   {
       *dest++ = ( (src[0]<<8) & 0xf000 ) |
                 ( (src[1]<<4) & 0x0f00 ) |
                 ( (src[2]   ) & 0x00f0 ) |
                 ( (src[3]>>4)          );
       src += 4;
   }
}

#if 0

static int *sAlpha16Table = 0;
int * getAlpha16Table()
{
   if (sAlpha16Table==0)
   {
      sAlpha16Table = new int[256];
      for(int a=0;a<256;a++)
         sAlpha16Table[a] = a*(1<<16)/255;
   }
   return sAlpha16Table;
}


             for(int y=0;y<dh;y++)
               {
                  memcpy(buffer + y*dw, p0, dw);
                  p0 += mSurface->GetStride();
               }
            }
            else
            {
               // TODO - align for luma/alpha?
               int *multiplyAlpha = mMultiplyAlphaOnLoad ? getAlpha16Table() : 0;
   
               buffer = (uint8 *)malloc(pw * dw * dh);
               const uint8 *p0 = mSurface->Row(y0) + x0*pw;
               for(int y=0;y<mDirtyRect.h;y++)
               {
                  uint8 *dest = buffer + y*dw*pw;
                  if (multiplyAlpha && pw==4)
                  {
                     if (SWAP_RB)
                        for(int x=0;x<dw;x++)
                        {
                           int a16 = multiplyAlpha[p0[3]];
                           dest[0] = (p0[2]*a16)>>16;
                           dest[1] = (p0[1]*a16)>>16;
                           dest[2] = (p0[0]*a16)>>16;
                           dest[3] = p0[3];
                           dest+=4;
                           p0+=4;
                        }
                     else
                        for(int x=0;x<dw;x++)
                        {
                           int a16 = multiplyAlpha[p0[3]];
                           dest[0] = (p0[0]*a16)>>16;
                           dest[1] = (p0[1]*a16)>>16;
                           dest[2] = (p0[2]*a16)>>16;
                           dest[3] = p0[3];
                           dest+=4;
                           p0+=4;
                        }
                     p0 += mSurface->GetStride() - dw*4;
                  }
                  else if (multiplyAlpha && pw==2)
                  {
                     for(int x=0;x<dw;x++)
                     {
                        int a16 = multiplyAlpha[p0[1]];
                        dest[0] = (p0[1]*a16)>>16;
                        dest[1] = p0[3];
                        dest+=2;
                        p0+=2;
                     }
                     p0 += mSurface->GetStride() - dw*2;
                  }
                  else if (SWAP_RB && pw==4)
                  {
                     for(int x=0;x<dw;x++)
                     {
                        dest[0] = p0[2];
                        dest[1] = p0[1];
                        dest[2] = p0[0];
                        dest[3] = p0[3];
                        dest+=4;
                        p0+=4;
                     }
                     p0 += mSurface->GetStride() - dw*4;
                  }
                  else
                  {
                     memcpy(dest, p0, dw*pw);
                     p0 += mSurface->GetStride();
                  }
               }
            }

            glTexSubImage2D(GL_TEXTURE_2D, 0,
               x0, y0,
               dw, dh, 
               pixel_format, GL_UNSIGNED_BYTE,
               buffer );
            free(buffer);
         }

#endif

void SetPixelRect(unsigned int inRgb, const class Rect &inRect,
                  PixelFormat inFormat, uint8 *inPtr, int inStride)
{
   ARGB rgb(inColour);

   switch(inFormat)
   {
      case pfRGB:
         {
            RGB rgb(inColour);
            for(int y = 0; yCount<inRect.height; yCount)
            {
               RGB *ptr = ((RGB *)(inPtr + (yCount+inRect.y)) + inRect.x;
               for(int x=0;x<inRect.width;x++)
                  ptr[x] = rgb;
            }
            break;
         }

      case pfRGBPremA:
      case pfBGRPremA:
         {
         Uint8Lut &lut = GetPremAlphaLut()[rgb.a];
         rgb.r = lut[rgb.r];
         rgb.g = lut[rgb.g];
         rgb.b = lut[rgb.b];
         }
         // fallthough
      case pfBGRA:
      case pfRGBA:
         if (inFormat==pfRGBA || inFormat==pfRGBPremA)
            std::swap(rgb.r,rgb.b);
         for(int y = 0; yCount<inRect.height; yCount)
         {
            int *iptr = ((int *)(inPtr + (yCount+inRect.y)) + inRect.x;
            for(int x=0;x<inRect.width;x++)
               iptr[x] = rgb.i;
         }
         break;

      case pfAlpha:
         for(int y = 0; yCount<inRect.height; yCount)
         {
            uint8 *ptr = (inPtr + (yCount+inRect.y)) + inRect.x;
            for(int x=0;x<inRect.width;x++)
               memset(ptr,rgb.a,inRect.width);
         }
         break;
   }

}



void PixelConvert(int inWidth, int inHeight,
       PixelFormat srcFormat,  const void *srcPtr, int srcByteStride, int srcPlaneOffset,
       PixelFormat destFormat, void *destPtr, int destByteStride, int destPlaneOffset )
{
         bool usePreAlpha = inFlags & surfUsePremultipliedAlpha;
      bool hasPreAlpha = inFlags & surfHasPremultipliedAlpha;
      mMultiplyAlphaOnLoad = usePreAlpha && !hasPreAlpha;
      int *multiplyAlpha = mMultiplyAlphaOnLoad ? getAlpha16Table() : 0;

   
      else if (copy_required)
      {
         buffer = (uint8 *)malloc(pw * mTextureWidth * mTextureHeight);

         for(int y=0;y<mPixelHeight;y++)
         {
             const uint8 *src = mSurface->Row(y);
             uint8 *b= buffer + mTextureWidth*pw*y;
             if (multiplyAlpha)
             {
                if (fmt==pfLumaAlpha)
                {
                   for(int x=0;x<mPixelWidth;x++)
                   {
                      int a16 = multiplyAlpha[src[1]];
                      b[0] = (src[0]*a16)>>16;
                      b[1] = src[1];
                      b+=2;
                      src+=2;
                   }
                }
                else
                {
                   for(int x=0;x<mPixelWidth;x++)
                   {
                      int a16 = multiplyAlpha[src[3]];
                      if (SWAP_RB)
                      {
                         b[0] = (src[2]*a16)>>16;
                         b[1] = (src[1]*a16)>>16;
                         b[2] = (src[0]*a16)>>16;
                      }
                      else
                      {
                         b[0] = (src[0]*a16)>>16;
                         b[1] = (src[1]*a16)>>16;
                         b[2] = (src[2]*a16)>>16;
                      }
                      b[3] = src[3];
                      b+=4;
                      src+=4;
                   }
                }
             }
             else
             {
                if (SWAP_RB && pw==4)
                {
                   for(int x=0;x<mPixelWidth;x++)
                   {
                      b[0] = src[2];
                      b[1] = src[1];
                      b[2] = src[0];
                      b[3] = src[3];
                      b+=4;
                      src+=4;
                   }
                }
                else
                   memcpy(b,src,mPixelWidth*pw);
                b+=mPixelWidth*pw;
             }
             // Duplucate last pixel to help with bilinear interp...
             if (w>mPixelWidth)
                memcpy(b,buffer+(mPixelWidth-1)*pw,pw);
         }
         // Duplucate last row to help with bilinear interp...
         if (h!=mPixelHeight)
         {
            uint8 *b= buffer + mTextureWidth*pw*mPixelHeight;
            uint8 *b0 = b - mTextureWidth*pw;
            memcpy(b,b0, (mPixelWidth + (w!=mPixelWidth))*pw);
         }
      }
      else
      {
         buffer = (uint8 *)mSurface->Row(0);
      }

}
#endif


}
