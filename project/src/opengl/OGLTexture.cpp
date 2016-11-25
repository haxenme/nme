#include "./OGL.h"

#define SWAP_RB 0

// 0xAARRGGBB
#if defined(ANDROID)
   #ifdef ANDROID_X86
      #undef SWAP_RB
      static bool SWAP_RB = false;
      static bool sFormatChecked = false;
   #endif
   static int ARGB_STORE = GL_BGRA_EXT;
   static int ARGB_PIXEL = GL_BGRA_EXT;
#elif defined(EMSCRIPTEN)
   #undef SWAP_RB
   #define SWAP_RB 1
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_RGBA
#elif defined(IPHONE)
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_BGRA
#elif defined(NME_GLES)
   #define ARGB_STORE GL_BGRA
   #define ARGB_PIXEL GL_BGRA
#else
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_BGRA
#endif

//Constant Value:  32993 

namespace nme
{

bool gC0IsRed = true;

bool gFullNPO2Support = false;
bool gPartialNPO2Support = false;

bool NonPO2Supported(bool inNotRepeating)
{
   static bool tried = false;
   
   //OpenGL 2.0 introduced non PO2 as standard, in 2004 - safe to assume it exists on PC
   #ifdef FORCE_NON_PO2
      return true;
   #endif

   if (!tried)
   {
      tried = true;
      const char* extensions = (char*) glGetString(GL_EXTENSIONS);
     
     gFullNPO2Support = strstr(extensions, "ARB_texture_non_power_of_two") != 0;
     
     if (!gFullNPO2Support)
     {
        gPartialNPO2Support = strstr(extensions, "GL_APPLE_texture_2D_limited_npot") != 0;
     }
      
     
      //printf("Full non-PO2 support : %d\n", gFullNPO2Support);
      //printf("Partial non-PO2 support : %d\n", gPartialNPO2Support);
   }

   return (gFullNPO2Support || (gPartialNPO2Support && inNotRepeating));
}


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

#ifdef ANDROID_X86
void checkRgbFormat()
{
   sFormatChecked = true;
   char data[4];
   glGetError();
   GLuint tid = 0;
   glGenTextures(1, &tid);
   glBindTexture(GL_TEXTURE_2D,tid);
   glTexImage2D(GL_TEXTURE_2D, 0, ARGB_STORE, 1, 1, 0, ARGB_PIXEL, GL_UNSIGNED_BYTE, data);
   int err = glGetError();
   if (err)
   {
      ELOG("Switching texture format for simulator");
      ARGB_STORE = GL_RGBA;
      ARGB_PIXEL = /*GL_BGRA*/ 0x80E1;

      glTexImage2D(GL_TEXTURE_2D, 0, ARGB_STORE, 1, 1, 0, ARGB_PIXEL, GL_UNSIGNED_BYTE, data);
      if (glGetError())
      {
         ELOG("Fall back to software colour transform");
         ARGB_STORE = GL_RGBA;
         ARGB_PIXEL = GL_RGBA;
         SWAP_RB = true;
      }
   }
   glDeleteTextures(1,&tid);
   //else ELOG("Using normal texture format in simulator");
}
#endif


class OGLTexture : public Texture
{
   Rect mDirtyRect;
   int  mContextVersion;
   GLuint mTextureID;
   bool mCanRepeat;
   bool mRepeat;
   bool mSmooth;
   bool mMultiplyAlphaOnLoad;
   int mPixelWidth;
   int mPixelHeight;
   int mTextureWidth;
   int mTextureHeight;
   Surface *mSurface;


public:
   OGLTexture(Surface *inSurface,unsigned int inFlags)
   {
      #ifdef ANDROID_X86
      if (!sFormatChecked)
         checkRgbFormat();
      #endif

      // No reference count since the surface should outlive us
      mSurface = inSurface;

      mPixelWidth = mSurface->Width();
      mPixelHeight = mSurface->Height();
      mDirtyRect = Rect(0,0);
      mContextVersion = gTextureContextVersion;

#ifdef HX_WINDOWS
      if( pfDDS == mSurface->GPUFormat())
      {
           mTextureWidth = mPixelWidth;
           mTextureHeight = mPixelHeight;
           mTextureID = 0;
           glGenTextures(1, &mTextureID);
           glBindTexture(GL_TEXTURE_2D,mTextureID);
           mRepeat = mCanRepeat;
           mSmooth = true;
           uint8 * buffer = (uint8 *)mSurface->Row(0);
           static int level = 0; //no mipmaps
           static int nBlockSize = 16; //8 if DXT1
           int size = ((mPixelWidth+3)/4) * ((mPixelHeight+3)/4) * nBlockSize;
           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0 );
           glCompressedTexImage2D(GL_TEXTURE_2D, level,  GL_COMPRESSED_RGBA_BPTC_UNORM_ARB /*GL_COMPRESSED_RGBA_S3TC_DXT5_EXT*/, mPixelWidth, mPixelHeight,0, size, buffer);
            return;
      }
#endif

      bool non_po2 = NonPO2Supported(inFlags & surfNotRepeatIfNonPO2);
      //printf("Using non-power-of-2 texture %d\n",non_po2);

      int w = non_po2 ? mPixelWidth : UpToPower2(mPixelWidth);
      int h = non_po2 ? mPixelHeight : UpToPower2(mPixelHeight);
      mCanRepeat = IsPower2(w) && IsPower2(h);

      //__android_log_print(ANDROID_LOG_ERROR, "NME",  "NewTexure %d %d", w, h);

      mTextureWidth = w;
      mTextureHeight = h;
      bool usePreAlpha = inFlags & surfUsePremultipliedAlpha;
      bool hasPreAlpha = inFlags & surfHasPremultipliedAlpha;
      mMultiplyAlphaOnLoad = usePreAlpha && !hasPreAlpha;
      int *multiplyAlpha = mMultiplyAlphaOnLoad ? getAlpha16Table() : 0;

      bool copy_required = mSurface->GetBase() &&
           (w!=mPixelWidth || h!=mPixelHeight || multiplyAlpha || SWAP_RB );

      Surface *load = mSurface;

      uint8 *buffer = 0;
      PixelFormat fmt = mSurface->Format();
      GLuint store_format = fmt==pfAlpha ? GL_ALPHA : ARGB_STORE;
      GLuint pixel_format = fmt==pfAlpha ? GL_ALPHA : ARGB_PIXEL;
      int pixels = GL_UNSIGNED_BYTE;
      int gpuFormat = mSurface->GPUFormat();

      if (!mSurface->GetBase() )
      {
         if (gpuFormat!=fmt)
            switch(gpuFormat)
            {
               case pfARGB4444: pixels = GL_UNSIGNED_SHORT_4_4_4_4; break;
               case pfRGB565: pixels = GL_UNSIGNED_SHORT_5_6_5; break;
               default:
                 pixels = gpuFormat;
            }
      }
      else if ( gpuFormat == pfARGB4444 )
      {
         pixels = GL_UNSIGNED_SHORT_4_4_4_4;
         buffer = (uint8 *)malloc( mTextureWidth * mTextureHeight * 2 );
         for(int y=0;y<mPixelHeight;y++)
            RGBA_to_RGBA4444(buffer+y*mTextureWidth*2, mSurface->Row(y),mPixelWidth);
      }
      else if ( gpuFormat == pfRGB565 )
      {
         pixels = GL_UNSIGNED_SHORT_5_6_5;
         buffer = (uint8 *)malloc( mTextureWidth * mTextureHeight * 2 );
         for(int y=0;y<mPixelHeight;y++)
            RGBX_to_RGB565(buffer+y*mTextureWidth*2, mSurface->Row(y),mPixelWidth);
      }
      else if (copy_required)
      {
         int pw = mSurface->Format()==pfAlpha ? 1 : 4;
         buffer = (uint8 *)malloc(pw * mTextureWidth * mTextureHeight);

         for(int y=0;y<mPixelHeight;y++)
         {
             const uint8 *src = mSurface->Row(y);
             uint8 *b= buffer + mTextureWidth*pw*y;
             if (multiplyAlpha)
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


      mTextureID = 0;
      glGenTextures(1, &mTextureID);
      // __android_log_print(ANDROID_LOG_ERROR, "NME", "CreateTexture %d (%dx%d)",
      //  mTextureID, mPixelWidth, mPixelHeight);
      glBindTexture(GL_TEXTURE_2D,mTextureID);
      mRepeat = mCanRepeat;
      mSmooth = true;
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

      glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, pixel_format, pixels, buffer);

      if (buffer && buffer!=mSurface->Row(0))
         free(buffer);


      //int err = glGetError();
      //printf ("GL texture error: %i\n", err);
   }
   ~OGLTexture()
   {
      if (mTextureID && mContextVersion==gTextureContextVersion && HardwareRenderer::current)
      {
         //__android_log_print(ANDROID_LOG_ERROR, "NME", "DeleteTexture %d (%dx%d)",
           //mTextureID, mPixelWidth, mPixelHeight);
         HardwareRenderer::current->DestroyNativeTexture((void *)(size_t)mTextureID);
      }
   }

   int GetWidth() { return mTextureWidth; }
   int GetHeight() { return mTextureHeight; }


   void Bind(int inSlot)
   {
      if (inSlot>=0 && CHECK_EXT(glActiveTexture))
      {
         glActiveTexture(GL_TEXTURE0 + inSlot);
      }
      glBindTexture(GL_TEXTURE_2D,mTextureID);

      if (gTextureContextVersion!=mContextVersion)
      {
         ELOG("######## Error stale texture");
         mContextVersion = gTextureContextVersion;
         mDirtyRect = Rect(mSurface->Width(),mSurface->Height());
      }
      if (mSurface->GetBase() && mDirtyRect.HasPixels())
      {
         //__android_log_print(ANDROID_LOG_INFO, "NME", "UpdateDirtyRect! %d %d",
             //mPixelWidth, mPixelHeight);


         PixelFormat fmt = mSurface->Format();
         int pw = fmt == pfAlpha ? 1 : 4;

         int x0 = mDirtyRect.x;
         int y0 = mDirtyRect.y;
         int dw = mDirtyRect.w;
         int dh = mDirtyRect.h;

         
         bool needsCopy = mMultiplyAlphaOnLoad;
         #if defined(NME_GLES)
         needsCopy = true;
         #endif
         if (SWAP_RB && pw==4)
            needsCopy = true;


         if (needsCopy)
         {
            GLuint pixel_format = fmt==pfAlpha ? GL_ALPHA : ARGB_PIXEL;
   
            uint8 *buffer = 0;
            if (pw==1)
            {
               // Make unpack align a multiple of 4 ...
               if (mSurface->Width()>3)
               {
                  dw = (dw + 3) & ~3;
                  if (x0+dw>mSurface->Width())
                     x0 = mSurface->Width()-dw;
               }
   
               const uint8 *p0 = mSurface->Row(y0) + x0*pw;
               buffer = (uint8 *)malloc(pw * dw * dh);
               for(int y=0;y<dh;y++)
               {
                  memcpy(buffer + y*dw, p0, dw);
                  p0 += mSurface->GetStride();
               }
            }
            else
            {
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
         else
         {
            #ifndef NME_GLES
            GLuint pixel_format = fmt==pfAlpha ? GL_ALPHA : ARGB_PIXEL;
   
            const uint8 *p0 = mSurface->Row(y0) + x0*pw;
            glPixelStorei(GL_UNPACK_ROW_LENGTH, mSurface->Width());
            glTexSubImage2D(GL_TEXTURE_2D, 0,
               x0, y0,
               dw, dh,
               pixel_format, GL_UNSIGNED_BYTE,
               p0);
            glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
            #endif
         }

         int err = glGetError();
         if (err != GL_NO_ERROR)
            ELOG("GL Error: %d %dx%d", err, mDirtyRect.w, mDirtyRect.h);
         mDirtyRect = Rect();
      }
   }

   void BindFlags(bool inRepeat,bool inSmooth)
   {
      if (!mCanRepeat) inRepeat = false;
      if (mRepeat!=inRepeat)
      {
         mRepeat = inRepeat;
         if (mRepeat)
         {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
         }
         else
         {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
         }
      }

      if (mSmooth!=inSmooth)
      {
         mSmooth = inSmooth;
         if (mSmooth)
         {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
         }
         else
         {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
         }
      }

   }


   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/mTextureWidth, inPixels.y/mTextureHeight);
   }

   UserPoint TexToPaddedTex(const UserPoint &inTex)
   {
      return UserPoint(inTex.x*mPixelWidth/mTextureWidth, inTex.y*mPixelHeight/mTextureHeight);
   }

   void Dirty(const Rect &inRect)
   {
      if (!mDirtyRect.HasPixels())
         mDirtyRect = inRect;
      else
         mDirtyRect = mDirtyRect.Union(inRect);
   }

   bool IsCurrentVersion() { return mContextVersion==gTextureContextVersion; }
};


Texture *OGLCreateTexture(Surface *inSurface,unsigned int inFlags)
{
   return new OGLTexture(inSurface,inFlags);
}


} // end namespace nme
