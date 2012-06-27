#include "./OGL.h"

namespace nme
{



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




class OGLTexture : public Texture
{
public:
   OGLTexture(Surface *inSurface,unsigned int inFlags)
   {
      
      mPixelWidth = inSurface->Width();
      mPixelHeight = inSurface->Height();
      mDirtyRect = Rect(0,0);
      mContextVersion = gTextureContextVersion;

      bool non_po2 = NonPO2Supported(true && (inFlags & SURF_FLAGS_NOT_REPEAT_IF_NON_PO2));
      //printf("Using non-power-of-2 texture %d\n",non_po2);
            
      int w = non_po2 ? mPixelWidth : UpToPower2(mPixelWidth);
      int h = non_po2 ? mPixelHeight : UpToPower2(mPixelHeight);
      mCanRepeat = IsPower2(w) && IsPower2(h);
      
      //__android_log_print(ANDROID_LOG_ERROR, "NME",  "NewTexure %d %d", w, h);

      mTextureWidth = w;
      mTextureHeight = h;
      bool copy_required = w!=mPixelWidth || h!=mPixelHeight;

      Surface *load = inSurface;
      if (copy_required)
      {
         int pw = inSurface->Format()==pfAlpha ? 1 : 4;
         load = new SimpleSurface(w,h,inSurface->Format());
         load->IncRef();
         for(int y=0;y<mPixelHeight;y++)
         {
             const uint8 *src = inSurface->Row(y);
             uint8 *dest= (uint8 *)load->Row(y);
             memcpy(dest,src,mPixelWidth*pw);
             if (w>mPixelWidth)
                memcpy(dest+mPixelWidth*pw,dest+(mPixelWidth-1)*pw,pw);
         }
         if (h!=mPixelHeight)
         {
            memcpy((void *)load->Row(mPixelHeight),load->Row(mPixelHeight-1),
                   (mPixelWidth + (w!=mPixelWidth))*pw);
         }
      }

     #ifdef IPHONE
      uint8 *dest;
      
      if ( inSurface->Format() == pfARGB4444 ) {
           int size = mTextureWidth * mTextureHeight;
           dest = (uint8 *)malloc( size * 2 );
            
           const uint8 *src = (uint8 *)load->Row( 0 );
                
           for ( int c = 0; c < size; c++ ) {

             uint8 srca = src[ c * 4 ] / 16;
             uint8 srcb = src[ c * 4 + 1 ] / 16;
             uint8 srcc = src[ c * 4 + 2 ] / 16;
             uint8 srcd = src[ c * 4 + 3 ] / 16;

             dest[ c * 2 ] = ( srcc << 4 | srcd );
             dest[ c * 2 + 1 ] = ( srca << 4 | srcb );
           }
      } else if ( inSurface->Format() == pfRGB565 ) {
           int size = mTextureWidth * mTextureHeight;
           dest = (uint8 *)malloc( size * 2 );
            
           const uint8 *src = (uint8 *)load->Row( 0 );
                
           for ( int c = 0; c < size; c++ ) {
             uint8 srca = src[ c * 4 ] / 8;
             uint8 srcb = src[ c * 4 + 1 ] / 4;
             uint8 srcc = src[ c * 4 + 2 ] / 8;
             
             //pack into 565
             unsigned int combined = (srca << 11) | (srcb << 5) | (srcc << 0);

            //write to the buffer
             dest[ c * 2 +1] = combined >> 8;
             dest[ c * 2  ] = combined & 0x00FF;
           }
      }
      #endif


      glGenTextures(1, &mTextureID);
      // __android_log_print(ANDROID_LOG_ERROR, "NME", "CreateTexture %d (%dx%d)",
      //  mTextureID, mPixelWidth, mPixelHeight);
      glBindTexture(GL_TEXTURE_2D,mTextureID);
      mRepeat = mCanRepeat;
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );

      PixelFormat fmt = load->Format();
      GLuint src_format = fmt==pfAlpha ? GL_ALPHA : GL_RGBA;
      GLuint store_format = src_format;
      
      
      #ifdef IPHONE
        if ( inSurface->Format() == pfARGB4444 ) {
                glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, src_format,
                    GL_UNSIGNED_SHORT_4_4_4_4, dest  );
                
                free( dest );
        } else if ( inSurface->Format() == pfRGB565 ) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB,
                    GL_UNSIGNED_SHORT_5_6_5, dest  );
                
                free( dest );
        } else
      #endif
      
      glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, src_format,
            GL_UNSIGNED_BYTE, load->Row(0) );

      mSmooth = true;
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      #ifdef GPH
      glTexEnvx(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
      #else
      glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
      #endif


      if (copy_required)
      {
         load->DecRef();
      }

      //int err = glGetError();
	  //printf ("GL texture error: %i", err);
   }
   ~OGLTexture()
   {
      if (mTextureID && mContextVersion==gTextureContextVersion)
      {
         //__android_log_print(ANDROID_LOG_ERROR, "NME", "DeleteTexture %d (%dx%d)",
           //mTextureID, mPixelWidth, mPixelHeight);
         glDeleteTextures(1,&mTextureID);
      }
   }

   void Bind(class Surface *inSurface,int inSlot)
   {
      glBindTexture(GL_TEXTURE_2D,mTextureID);
      if (gTextureContextVersion!=mContextVersion)
      {
         mContextVersion = gTextureContextVersion;
         mDirtyRect = Rect(inSurface->Width(),inSurface->Height());
      }
      if (mDirtyRect.HasPixels())
      {
         //__android_log_print(ANDROID_LOG_INFO, "NME", "UpdateDirtyRect! %d %d",
             //mPixelWidth, mPixelHeight);

         PixelFormat fmt = inSurface->Format();
         GLuint src_format = fmt==pfAlpha ? GL_ALPHA : GL_RGBA;
         glGetError();
         const uint8 *p0 = 
            inSurface->Row(mDirtyRect.y) + mDirtyRect.x*inSurface->BytesPP();
         #if defined(NME_GLES)
         for(int y=0;y<mDirtyRect.h;y++)
         {
            glTexSubImage2D(GL_TEXTURE_2D, 0, mDirtyRect.x,mDirtyRect.y + y,
               mDirtyRect.w, 1,
               src_format, GL_UNSIGNED_BYTE,
               p0 + y*inSurface->GetStride());
         }
         #else
         glPixelStorei(GL_UNPACK_ROW_LENGTH, inSurface->Width());
         glTexSubImage2D(GL_TEXTURE_2D, 0, mDirtyRect.x,mDirtyRect.y,
            mDirtyRect.w, mDirtyRect.h,
            src_format, GL_UNSIGNED_BYTE,
            p0);
         glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
         #endif
         int err = glGetError();
         if (err != GL_NO_ERROR) {
          ELOG("GL Error: %d", err);
         }
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



   GLuint mTextureID;
   bool mCanRepeat;
   bool mRepeat;
   bool mSmooth;
   int mPixelWidth;
   int mPixelHeight;
   int mTextureWidth;
   int mTextureHeight;
};


Texture *OGLCreateTexture(Surface *inSurface,unsigned int inFlags)
{
   return new OGLTexture(inSurface,inFlags);
}


} // end namespace nme
