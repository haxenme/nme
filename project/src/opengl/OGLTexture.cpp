#include "./OGL.h"

#define SWAP_RB 0

#if ( defined(HX_ANDROID) && !( defined(HXCPP_ARM64) || defined(HXCPP_ARMV7) || defined(__arm__) || defined(__aarch64__) ) )
  #define ANDROID_SIM
#endif

// 0xAARRGGBB
#if defined(ANDROID)
   #ifdef ANDROID_SIM
      #undef SWAP_RB
      static bool SWAP_RB = false;
      static bool SWAP_RB_MIP = false;
      static bool sFormatChecked = false;
   #endif
   static int ARGB_STORE = GL_BGRA_EXT;
   static int ARGB_PIXEL = GL_BGRA_EXT;
   static int ARGB_STORE_MIP = GL_BGRA_EXT;
   static int ARGB_PIXEL_MIP = GL_BGRA_EXT;
#elif defined(EMSCRIPTEN) || defined(RASPBERRYPI) || defined(GCW0)
   #undef SWAP_RB
   #define SWAP_RB 1
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_RGBA
#elif defined(IPHONE)
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_BGRA
#elif defined(NME_ANGLE)
   #define ARGB_STORE GL_BGRA_EXT;
   #define ARGB_PIXEL GL_BGRA_EXT;
#elif defined(GCW0)
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_BGRA_EXT
#elif defined(NME_DYNAMIC_ANGLE)
   #define ARGB_STORE (nmeEglMode ? GL_BGRA : GL_RGBA)
   #define ARGB_PIXEL (GL_BGRA)
#elif defined(NME_GLES)
   #define ARGB_STORE GL_BGRA
   #define ARGB_PIXEL GL_BGRA
#else
   #define ARGB_STORE GL_RGBA
   #define ARGB_PIXEL GL_BGRA
#endif

#ifndef GL_UNPACK_ROW_LENGTH
#define GL_UNPACK_ROW_LENGTH 0x0CF2
#endif

namespace nme
{

#ifdef NME_ANGLE
bool gOglAllowRgb = false;
#else
bool gOglAllowRgb = true;
#endif

bool gC0IsRed = true;

#if defined(NME_ANGLE) || defined(EMSCRIPTEN)
#define FORCE_NON_PO2
#endif

bool gFullNPO2Support = false;
bool gPartialNPO2Support = false;


bool NonPO2Supported(bool inNotRepeating)
{
   static bool tried = false;
   
   //OpenGL 2.0 introduced non PO2 as standard, in 2004 - safe to assume it exists on PC
   #ifdef FORCE_NON_PO2
      return true;
   #endif
   #ifdef NME_DYNAMIC_ANGLE
   if (nmeEglMode)
      return true;
   #endif

   if (!tried)
   {
      tried = true;
      const char* extensions = (char*) glGetString(GL_EXTENSIONS);
     
     gFullNPO2Support = extensions && strstr(extensions, "ARB_texture_non_power_of_two") != 0;
     
     if (!gFullNPO2Support)
     {
        gPartialNPO2Support = extensions && strstr(extensions, "GL_APPLE_texture_2D_limited_npot") != 0;
     }
      
     
      //printf("Full non-PO2 support : %d\n", gFullNPO2Support);
      //printf("Partial non-PO2 support : %d\n", gPartialNPO2Support);
   }

   return (gFullNPO2Support || (gPartialNPO2Support && inNotRepeating));
}


#ifdef ANDROID_SIM
void checkRgbFormat()
{
   sFormatChecked = true;
   char data[4*16*16];
   glGetError();
   GLuint tid = 0;
   glGenTextures(1, &tid);
   glBindTexture(GL_TEXTURE_2D,tid);


   glTexImage2D(GL_TEXTURE_2D, 0, ARGB_STORE, 4, 4, 0, ARGB_PIXEL, GL_UNSIGNED_BYTE, data);
   int err = glGetError();
   if (err)
   {
      ELOG("Switching texture format for simulator");
      ARGB_STORE = GL_RGBA;
      ARGB_PIXEL = /*GL_BGRA*/ 0x80E1;

      glTexImage2D(GL_TEXTURE_2D, 0, ARGB_STORE, 1, 1, 0, ARGB_PIXEL, GL_UNSIGNED_BYTE, data);

      if (glGetError())
      {
         ELOG("Fall back to software texture colour transform");
         ARGB_STORE = GL_RGBA;
         ARGB_PIXEL = GL_RGBA;
         SWAP_RB = true;
      }
   }

   ARGB_STORE_MIP = ARGB_STORE;
   ARGB_PIXEL_MIP = ARGB_PIXEL;
   SWAP_RB_MIP = SWAP_RB;


   glTexImage2D(GL_TEXTURE_2D, 0, ARGB_STORE, 4, 4, 0, ARGB_PIXEL, GL_UNSIGNED_BYTE, data);
   glGenerateMipmap(GL_TEXTURE_2D);
   err = glGetError();
   if (err)
   {
      ELOG("Fall back to software texture colour transform for mipmaps");
      ARGB_STORE_MIP = GL_RGBA;
      ARGB_PIXEL_MIP = GL_RGBA;
      SWAP_RB_MIP = true;
   }

   glDeleteTextures(1,&tid);
   //else ELOG("Using normal texture format in simulator");
}
#endif



// Type of storage.
// OGLES says this should match the pixel transfer type, but extensions allow
// the RGBA/BGRA swizzel to match the little-endian 4-byte layout
GLenum getTextureStorage(PixelFormat pixelFormat, bool mips)
{
   switch(pixelFormat)
   {
      #ifdef ANDROID_SIM
      case pfRGB:  return gOglAllowRgb ? GL_RGB : mips ? ARGB_STORE_MIP : ARGB_STORE;
      case pfBGRA:     return mips ? ARGB_STORE_MIP : ARGB_STORE;
      case pfBGRPremA: return mips ? ARGB_STORE_MIP : ARGB_STORE;
      #else
      case pfRGB:  return gOglAllowRgb ? GL_RGB : ARGB_STORE;
      case pfBGRA:     return ARGB_STORE;
      case pfBGRPremA: return ARGB_STORE;
      #endif

      case pfAlpha: return GL_ALPHA;
      case pfARGB4444: return GL_RGBA; // GL_RGBA4
      case pfRGB565: return GL_RGB;
      case pfLuma: return GL_LUMINANCE;
      case pfLumaAlpha: return GL_LUMINANCE_ALPHA;
      default: ;
   }
   return 0;
}

GLenum getOglChannelType(PixelFormat pixelFormat)
{
   switch(pixelFormat)
   {
      case pfARGB4444: return GL_UNSIGNED_SHORT_4_4_4_4; // GL_RGBA4
      case pfRGB565: return GL_UNSIGNED_SHORT_5_6_5;
      default:
         return GL_UNSIGNED_BYTE;
   }
}



// Transfer memory layout - in opengl enum
GLenum getTransferOgl(PixelFormat pixelFormat, bool mips)
{
   switch(pixelFormat)
   {
      #ifdef ANDROID_SIM
      case pfRGB:  return gOglAllowRgb ? GL_RGB : mips ? ARGB_PIXEL_MIP : ARGB_PIXEL;
      case pfBGRA:     return mips ? ARGB_PIXEL_MIP : ARGB_PIXEL;
      case pfBGRPremA: return mips ? ARGB_PIXEL_MIP : ARGB_PIXEL;
      #else
      case pfRGB:  return gOglAllowRgb ? GL_RGB : ARGB_PIXEL;
      case pfBGRA:     return ARGB_PIXEL;
      case pfBGRPremA: return ARGB_PIXEL;
      #endif

      case pfAlpha: return GL_ALPHA;
      case pfARGB4444: return GL_UNSIGNED_SHORT_4_4_4_4;
      case pfRGB565: return GL_UNSIGNED_SHORT_5_6_5;
      case pfLuma: return GL_LUMINANCE;
      case pfLumaAlpha: return GL_LUMINANCE_ALPHA;
      default: ;
   }
   return 0;
}

// Gpu memory layout - in our enum, may need to swizzle
PixelFormat getTransferFormat(PixelFormat pixelFormat, bool mips)
{
   switch(pixelFormat)
   {
      case pfRGB:
         if (gOglAllowRgb)
           return pfRGB;
         // Fallthough

      case pfBGRA:
         #ifdef ANDROID_SIM
         return (mips ? SWAP_RB_MIP : SWAP_RB) ? pfRGBA :pfBGRA;
         #else
         return SWAP_RB ? pfRGBA :pfBGRA;
         #endif

      case pfLuma:
      case pfAlpha:
      case pfLumaAlpha:
      case pfARGB4444:
      case pfRGB565:
         return pixelFormat;


      case pfBGRPremA:
         #ifdef ANDROID_SIM
         return (mips ? SWAP_RB_MIP : SWAP_RB) ? pfRGBPremA :pfBGRPremA;
         #else
         return SWAP_RB ? pfRGBPremA :pfBGRPremA;
         #endif

      default: ;
   }
   return pfRGB;
}




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
   GLuint mUploadedFormat;
   bool mMipmaps;


public:
   OGLTexture(Surface *inSurface,unsigned int inFlags)
   {
      #ifdef ANDROID_SIM
      if (!sFormatChecked)
         checkRgbFormat();
      #endif

      // No reference count since the surface should outlive us
      mSurface = inSurface;
      mUploadedFormat = 0;
      mMipmaps = inFlags & surfMipmaps;

      mPixelWidth = mSurface->Width();
      mPixelHeight = mSurface->Height();
      bool non_po2 = NonPO2Supported(inFlags & surfNotRepeatIfNonPO2) && !mMipmaps;
      //printf("Using non-power-of-2 texture %d\n",non_po2);

      mTextureWidth = non_po2 ? mPixelWidth : UpToPower2(mPixelWidth);
      mTextureHeight = non_po2 ? mPixelHeight : UpToPower2(mPixelHeight);
      mCanRepeat = IsPower2(mTextureWidth) && IsPower2(mTextureHeight);

      mTextureID = 0;
      glGenTextures(1, &mTextureID);
      CreateTexture();
   }

   void CreateTexture()
   {
      mDirtyRect = Rect(0,0);
      mContextVersion = gTextureContextVersion;

      //__android_log_print(ANDROID_LOG_ERROR, "NME",  "NewTexure %d %d", mTextureWidth, mTextureHeight);

      uint8 *buffer = 0;
      PixelFormat fmt = mSurface->Format();

      GLuint store_format = getTextureStorage(fmt,mMipmaps);
      GLuint pixel_format = getTransferOgl(fmt,mMipmaps);
      PixelFormat buffer_format = getTransferFormat(fmt,mMipmaps);
      GLenum channel= getOglChannelType(fmt);


      int pw = BytesPerPixel(fmt);
      int destPw = BytesPerPixel(buffer_format);

      bool copy_required = mSurface->GetBase() && (mTextureWidth!=mPixelWidth || mTextureHeight!=mPixelHeight || buffer_format!=fmt);

      #if defined(__APPLE__)
      // Minimum unpack on apple?
      int unpackAlign = !nmeEglMode ? 4 : 1;
      #else
      int unpackAlign = 1;
      #endif

      if (!nmeEglMode)
      {
         int texStride = (mTextureWidth*pw+unpackAlign-1)/unpackAlign*unpackAlign;
         int srcStride = mSurface->GetStride();
         if (texStride!=srcStride && !copy_required)
         {
            copy_required = true;
            for(int i=1;i<4;i++)
            {
               int align = 1<<i;
               if (align>=unpackAlign && srcStride == ((texStride+align-1)/align)*align)
               {
                  copy_required = false;
                  unpackAlign = align;
                  break;
               }
            }
         }
      }

      if (copy_required)
      {
         int copyStride = (mTextureWidth*destPw+unpackAlign-1)/unpackAlign*unpackAlign;

         buffer = (uint8 *)malloc(copyStride * mTextureHeight);

         PixelConvert( mPixelWidth, mPixelHeight,
              fmt, mSurface->GetBase(), mSurface->GetStride(), mSurface->GetPlaneOffset(),
              buffer_format, buffer, copyStride, copyStride*mTextureHeight );

         int extraX = copyStride - mPixelWidth*destPw;
         if (extraX)
            for(int y=0;y<mPixelHeight;y++)
               memset( buffer + y*copyStride + mPixelWidth*destPw, 0, extraX);
         int extraY = mTextureHeight-mPixelHeight;
         if (extraY)
            memset( buffer + copyStride*mPixelHeight, 0, copyStride*extraY);
      }

      // __android_log_print(ANDROID_LOG_ERROR, "NME", "CreateTexture %d (%dx%d)",
      //  mTextureID, mPixelWidth, mPixelHeight);
      glBindTexture(GL_TEXTURE_2D,mTextureID);
      mRepeat = mCanRepeat;
      mSmooth = true;
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, mMipmaps ? GL_LINEAR_MIPMAP_NEAREST : GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

      if (!nmeEglMode)
         glPixelStorei(GL_UNPACK_ALIGNMENT, unpackAlign);

      glTexImage2D(GL_TEXTURE_2D, 0, store_format, mTextureWidth, mTextureHeight, 0, pixel_format, channel, buffer ? buffer : mSurface->GetBase());

      if (mMipmaps)
      {
         #if (!defined(EMSCRIPTEN) || !defined(NME_NO_GETERROR))
         glGetError();
         glGenerateMipmap(GL_TEXTURE_2D);
         int err = glGetError();
         if (err)
         {
            ELOG("Error creating mipmaps @ %dx%d,%d/%d : %d\n", mTextureWidth, mTextureHeight, store_format,pixel_format,  err);
            mMipmaps = false;
         }
         #endif
      }

      mUploadedFormat = store_format;

      if (buffer)
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

      if (gTextureContextVersion!=mContextVersion)
      {
         ELOG("######## Error stale texture");
         CreateTexture();
      }
      else if (mSurface->GetBase() && mDirtyRect.HasPixels())
      {
         //__android_log_print(ANDROID_LOG_INFO, "NME", "UpdateDirtyRect! %d %d",
             //mPixelWidth, mPixelHeight);

         uint8 *buffer = 0;
         PixelFormat fmt = mSurface->Format();

         GLuint store_format = getTextureStorage(fmt,mMipmaps);
         if (store_format!=mUploadedFormat)
         {
            CreateTexture();
         }
         else
         {
            glBindTexture(GL_TEXTURE_2D,mTextureID);

            GLuint pixel_format = getTransferOgl(fmt,mMipmaps);
            PixelFormat buffer_format = getTransferFormat(fmt,mMipmaps);
            GLenum channel= getOglChannelType(fmt);

            int pw = BytesPerPixel(fmt);
            int destPw = BytesPerPixel(buffer_format);


            int x0 = mDirtyRect.x;
            int y0 = mDirtyRect.y;
            int dw = mDirtyRect.w;
            int dh = mDirtyRect.h;

            bool copy_required = buffer_format!=fmt;
            if (nmeEglMode && (!copy_required && dw!=mPixelWidth))
            {
               // Formats match but width does not. Can't use GL_UNPACK_ROW_LENGTH.
               //  Do we do the whole row, or copy?
               if (dw>mPixelWidth/2)
               {
                  x0 = 0;
                  if ( (mPixelWidth*pw) & 0x03 )
                     copy_required = true;
                  else
                     dw = mPixelWidth;
               }
               else
                  copy_required = true;
            }

            if (copy_required)
            {
               uint8 *buffer = 0;
               // Make unpack align a multiple of 4 ...
               if (destPw<4)
               {
                  dw = (dw + 3) & ~3;
                  if (x0+dw > mPixelWidth)
                  {
                     x0 = mPixelWidth-dw;
                     if (x0<0)
                     {
                        x0 = 0;
                        dw = mPixelWidth;
                     }
                  }
               }

               const uint8 *p0 = mSurface->Row(y0) + x0*pw;
               buffer = (uint8 *)malloc(destPw * dw * dh);
               PixelConvert(dw,dh,
                            fmt, p0, mSurface->GetStride(), mSurface->GetPlaneOffset(),
                            buffer_format, buffer, dw*destPw, dw*dh*destPw );

               glTexSubImage2D(GL_TEXTURE_2D, 0,
                  x0, y0,
                  dw, dh, 
                  pixel_format, channel,
                  buffer );
               free(buffer);
            }
            else
            {
               if (!nmeEglMode)
                  glPixelStorei(GL_UNPACK_ROW_LENGTH, mSurface->Width());

               glTexSubImage2D(GL_TEXTURE_2D, 0,
                  x0, y0,
                  dw, dh,
                  pixel_format, channel,
                  mSurface->Row(y0) + x0*pw );

               if (!nmeEglMode)
                  glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
            }

            if (mMipmaps)
               glGenerateMipmap(GL_TEXTURE_2D);

            #ifndef NME_NO_GETERROR
            int err = glGetError();
            if (err != GL_NO_ERROR)
               ELOG("GL Error: %d %dx%d", err, mDirtyRect.w, mDirtyRect.h);
            #endif
            mDirtyRect = Rect();
         }
      }
      else
         glBindTexture(GL_TEXTURE_2D,mTextureID);
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
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, mMipmaps ? GL_LINEAR_MIPMAP_NEAREST : GL_LINEAR);
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
