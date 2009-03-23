#include <string>
#include "texture_buffer.h"
#ifdef WIN32
#include <windows.h>
#endif
#include <GL/gl.h>
#include "nme.h"
#include "nsdl.h"
#include "ByteArray.h"
#include "renderer/Renderer.h"


DEFINE_KIND( k_texture_buffer );


int UpToPower2(int inX)
{
   int result = 1;
   while(result<inX) result<<=1;
   return result;
}

#ifndef GL_BGR
#define GL_BGR 0x80E0
#endif

#ifndef GL_BGRA
#define GL_BGRA 0x80E1
#endif

#ifndef GL_CLAMP_TO_EDGE
  #define GL_CLAMP_TO_EDGE 0x812F
#endif

static int val_id_x = val_id("x");
static int val_id_y = val_id("y");
static int val_id_width = val_id("width");
static int val_id_height = val_id("height");

static int texture_count = 0;

// --- TextureBuffer ----------------------------------------------------

TextureBuffer::TextureBuffer(SDL_Surface *inSurface)
{
   mSurface = inSurface;
   mTextureID = 0;
   mPixelWidth = inSurface->w;
   mPixelHeight = inSurface->h;
   mX1 = 0;
   mY1 = 0;

   mSW = mSH = 0;

   mRect.x = 0;
   mRect.y = 0;
   mRect.w = mPixelWidth;
   mRect.h = mPixelHeight;

   mRefCount = 1;
   mResizeID = 0;

   mHardwareDirty = true;
   mDirtyX0 = 0;
   mDirtyY0 = 0;
   mDirtyX1 = mPixelWidth;
   mDirtyY1 = mPixelHeight;
   texture_count++;
   //printf("TextureCount: %d\n", texture_count);
}


TextureBuffer::~TextureBuffer()
{
   if (mTextureID>0 && nme_resize_id==mResizeID)
      glDeleteTextures(1,&mTextureID);
   if (mSurface)
      SDL_FreeSurface(mSurface);
   texture_count--;
}

void TextureBuffer::DecRef()
{
   mRefCount--;
   if (mRefCount<=0)
      delete this;
}

TextureBuffer *TextureBuffer::IncRef()
{
   mRefCount++;
   return this;
}



bool TextureBuffer::PrepareOpenGL()
{
   if (mTextureID==0 || mResizeID != nme_resize_id)
   {
      SDL_Surface *data = mSurface;
      SDL_Surface *cleanup = 0;
      int src_format = GL_BGRA;
      int store_format = 4;
      mResizeID = nme_resize_id;

      if (mSurface->format->BitsPerPixel==32 )
      {
         if (mSurface->flags & SDL_SRCALPHA)
         {
            if (mSurface->format->Rmask == 0x0000ff)
               src_format = GL_RGBA;
            // Ok !
         }
         else
         {
            if (mSurface->format->Rmask == 0x0000ff)
               src_format = GL_RGB;
            else
               src_format = GL_BGR;
            store_format = 3;
         }
      }
      else if (mSurface->format->BitsPerPixel==24 )
      {
         if (mSurface->format->Rmask == 0x0000ff)
            src_format = GL_RGB;
         else
            src_format = GL_BGR;
         store_format = 3;
      }
      else // convert!
      {
         data = SDL_CreateRGBSurface(SDL_SWSURFACE|SDL_SRCALPHA,
            mSurface->w, mSurface->h, 32, 
            0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
         SDL_BlitSurface(mSurface, 0, data, 0);
         cleanup = data;
      }

      glGenTextures(1, &mTextureID);
      glBindTexture(GL_TEXTURE_2D, mTextureID);

      int w = UpToPower2(mSurface->w);
      int h = UpToPower2(mSurface->h);
      //printf("LoadedTexture %dx%d\n",w,h);

      if ( mSurface->w != w || mSurface->h != h )
      {
         glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, src_format, 
            GL_UNSIGNED_BYTE, 0 );
         glTexSubImage2D(GL_TEXTURE_2D, 0, 0,0, mSurface->w, mSurface->h,
            src_format, GL_UNSIGNED_BYTE, data->pixels );
      }
      else
      {
         glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, src_format, 
            GL_UNSIGNED_BYTE, data->pixels );
      }

      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);   
      glTexEnvi(GL_TEXTURE_2D, GL_TEXTURE_ENV_MODE, GL_REPLACE);

      if (cleanup)
         SDL_FreeSurface(cleanup);

      mX1 = w>0 ? (float)mPixelWidth/w : 0.0f;
      mY1 = h>0 ? (float)mPixelHeight/h : 0.0f;
      mSW = (float)(w >0 ? 1.0/w : 0);
      mSH = (float)(h >0 ? 1.0/h : 0);
      mHardwareDirty = false;
   }
   else if (mHardwareDirty)
   {
      glBindTexture(GL_TEXTURE_2D, mTextureID);
      UpdateHardware();
   }
   else
   {
      glBindTexture(GL_TEXTURE_2D, mTextureID);
   }

   glEnable(GL_TEXTURE_2D);

   return true;
}

void TextureBuffer::UpdateHardware()
{
   glBindTexture(GL_TEXTURE_2D, mTextureID);

   if (mDirtyX0<0) mDirtyX0 = 0;
   if (mDirtyY0<0) mDirtyY0 = 0;
   if (mDirtyX1>mPixelWidth)  mDirtyX1 = mPixelWidth;
   if (mDirtyY1>mPixelHeight) mDirtyY1 = mPixelHeight;

   glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
   glPixelStorei(GL_UNPACK_ROW_LENGTH, mSurface->w);
   glPixelStorei(GL_UNPACK_SKIP_PIXELS, mDirtyX0);
   glPixelStorei(GL_UNPACK_SKIP_ROWS,   mDirtyY0);

   glTexSubImage2D(GL_TEXTURE_2D, 0, mDirtyX0,mDirtyY0,
         mDirtyX1-mDirtyX0, mDirtyY1 - mDirtyY0,
         GL_BGRA, GL_UNSIGNED_BYTE, mSurface->pixels );

   glPopClientAttrib();

   mHardwareDirty = false;
}


void TextureBuffer::SetExtentDirty(int inX0,int inY0,int inX1,int inY1)
{
   if (!mHardwareDirty)
   {
      mHardwareDirty = true;
      mDirtyX0 = inX0;
      mDirtyY0 = inY0;
      mDirtyX1 = inX1;
      mDirtyY1 = inY1;
   }
   else
   {
      mHardwareDirty = true;
      if (inX0<mDirtyX0) mDirtyX0 = inX0;
      if (inY0<mDirtyY0) mDirtyY0 = inY0;
      if (inX1>mDirtyX1) mDirtyX1 = inX1;
      if (inY1>mDirtyY1) mDirtyY1 = inY1;
   }
}

void TextureBuffer::Scroll(int inDX, int inDY)
{
   if (inDX==0 && inDY==0)
      return;


   int sx0 = 0;
   int sx1 = Width();
   if (inDX<0)
      sx0 -= inDX;
   else
      sx1 -= inDX;

   int sy0 = 0;
   int sy1 = Height();
   if (inDY<0)
      sy0 -= inDY;
   else
      sy1 -= inDY;

   if (sx0<sx1 && sy0<sy1)
   {
      SDL_Surface *tmp = SDL_CreateRGBSurface(mSurface->flags, sx1-sx0,  sy1-sy0,
                    (mSurface->flags & SDL_SRCALPHA) ? 32 : 24,
                     mSurface->format->Rmask, mSurface->format->Gmask,
                     mSurface->format->Bmask, mSurface->format->Amask );

      // Do dumb compies
      SDL_SetAlpha(tmp,0,255);

      bool was_alpha = mSurface->flags & SDL_SRCALPHA;
      if (was_alpha)
         mSurface->flags &= ~SDL_SRCALPHA;

      SDL_Rect src;
      src.x = sx0;
      src.y = sy0;
      src.w = sx1 - sx0;
      src.h = sy1 - sy0;
      SDL_BlitSurface(mSurface, &src, tmp, 0);


      SDL_Rect dest;
      dest.x = inDX < 0 ? 0 : inDX;
      dest.y = inDY < 0 ? 0 : inDY;
      SDL_BlitSurface(tmp, 0, mSurface, &dest);

      SetExtentDirty(dest.x, dest.y, dest.x+dest.w, dest.y+dest.h);

      if (was_alpha)
         mSurface->flags |= SDL_SRCALPHA;

      SDL_FreeSurface(tmp);
   }
}



void TextureBuffer::ScaleTexture(int inX,int inY,float &outX,float &outY)
{
   outX = (float)(inX * mSW);
   outY = (float)(inY * mSH);
}


void TextureBuffer::BindOpenGL(bool inRepeat)
{
   PrepareOpenGL();
   glEnable(GL_TEXTURE_2D);
   glBindTexture(GL_TEXTURE_2D, mTextureID);

   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
     inRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
     inRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );

}

void TextureBuffer::UnBindOpenGL()
{
   glDisable(GL_TEXTURE_2D);
   // glBindTexture(GL_TEXTURE_2D, 0);
}




void TextureBuffer::DrawOpenGL(float inAlpha)
{
   if (!PrepareOpenGL())
      return;

   glColor4f(1,1,1,inAlpha);
   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   glBegin(GL_QUADS);
   glTexCoord2d(0,0);
   glVertex2i(0,0);
   glTexCoord2f(0,mY1);
   glVertex2i(0,mPixelHeight);
   glTexCoord2f(mX1,mY1);
   glVertex2i(mPixelWidth,mPixelHeight);
   glTexCoord2f(mX1,0);
   glVertex2i(mPixelWidth,0);
   glEnd();

   glDisable(GL_TEXTURE_2D);
   glDisable(GL_BLEND);
}

void TextureBuffer::TexCoord(float inX,float inY)
{
   glTexCoord2f(inX*mX1,inY*mY1);
}

void TextureBuffer::TexCoordScaled(float inX,float inY)
{
   glTexCoord2f(inX*mSW,inY*mSH);
}


void delete_texture_buffer( value texture_buffer )
{
   if ( val_is_kind( texture_buffer, k_texture_buffer ) )
   {
      val_gc( texture_buffer, NULL );

      TextureBuffer* t = TEXTURE_BUFFER(texture_buffer);
      t->DecRef();
   }
}

value TextureBuffer::ToValue()
{
   value v = alloc_abstract( k_texture_buffer, this );
   val_gc( v, delete_texture_buffer );
   return v;
}

value nme_texture_width( value texture_buffer )
{
   if ( val_is_kind( texture_buffer, k_texture_buffer ) )
   {
      TextureBuffer* t = TEXTURE_BUFFER(texture_buffer);
      return alloc_int(t->Width());
   }

   return val_null;
}

value nme_texture_height( value texture_buffer )
{
   if ( val_is_kind( texture_buffer, k_texture_buffer ) )
   {
      TextureBuffer* t = TEXTURE_BUFFER(texture_buffer);
      return alloc_int(t->Height());
   }

   return val_null;
}

value nme_scroll_texture( value texture_buffer, value inDX, value inDY)
{
   if ( val_is_kind( texture_buffer, k_texture_buffer ) )
   {
      TextureBuffer* t = TEXTURE_BUFFER(texture_buffer);
      int dx = val_int(inDX);
      int dy = val_int(inDY);
      t->Scroll(dx,dy);
   }

   return val_null;
}



value nme_create_texture_buffer(value width, value height,value in_flags,
                                value colour, value alpha)
{
   enum { HX_TRANSPARENT = 0x0001, HX_HARDWARE = 0x0002 };

   val_check( width, int );
   val_check( height, int );
   val_check( in_flags, int );
   val_check( colour, int );
   val_check( alpha, int );

   unsigned int f = val_int(in_flags);
   int flags =0;

   if  (f & HX_TRANSPARENT )
      flags |= SDL_SRCALPHA;

   if  (f & HX_HARDWARE )
      flags |= SDL_HWSURFACE;
   else
      flags |= SDL_SWSURFACE;

   SDL_Surface *surface = SDL_CreateRGBSurface(flags,
                            val_int(width),
                            val_int(height),
                            32,
                            0xff0000,0x00ff00,0x0000ff, 0xff000000);

 
   int icol = val_int(colour);
   int r = (icol>>16) & 0xff;
   int g = (icol>>8) & 0xff;
   int b = (icol) & 0xff;
   int a = val_int(alpha);

   //memset(surface->pixels,0,val_int(width)*val_int(height)*4);

   //SDL_SetAlpha( surface, 0, 255 );
   //Uint32 c1 = icol | (a<<24);
   Uint32 c2 = SDL_MapRGBA( surface->format, r, g, b, a );
   // printf("C2 : %x\n",c2);
   SDL_FillRect( surface, NULL, c2 );
   //SDL_SetAlpha( surface, SDL_SRCALPHA, 255 );

   TextureBuffer *buffer = new TextureBuffer(surface);

   return buffer->ToValue();
}

ByteArray *TextureBuffer::GetPixels(int inX,int inY,int inW,int inH)
{
   int x1 = inX+inW;
   int y1 = inY+inH;
   if (inX<0 || inY<0 || x1>mPixelWidth || y1>mPixelHeight)
      return new ByteArray;

   bool alpha = mSurface->format->Amask && (mSurface->flags & SDL_SRCALPHA);
   bool bgr = mSurface->format->BitsPerPixel==24 &&
                  mSurface->format->Rmask == 0x0000ff;
   

   ByteArray *array = new ByteArray(inW*inH*4);

   unsigned char *ptr = array->mPtr;
   for(int y=inY;y<y1;y++)
   {
      const unsigned char *pix =
         (const unsigned char *)mSurface->pixels + y*mSurface->pitch + inX*4;

      if (alpha) // ARGB = RGBA
      {
         for(int x=inX;x<x1;x++)
         {
            ptr[0] = pix[3];
            ptr[1] = pix[0];
            ptr[2] = pix[1];
            ptr[3] = pix[2];
            ptr+=4;
            pix+=4;
         }
      }
      else if (bgr)
         for(int x=inX;x<x1;x++)
         {
            ptr[0] = 255;
            ptr[1] = pix[2];
            ptr[2] = pix[1];
            ptr[3] = pix[0];
            ptr+=4;
            pix+=3;
         }
      else
         for(int x=inX;x<x1;x++)
         {
            ptr[0] = 255;
            ptr[1] = pix[0];
            ptr[2] = pix[1];
            ptr[3] = pix[2];
            ptr+=4;
            pix+=3;
         }
   }

   return array;
}


void TextureBuffer::SetPixels(int inX,int inY,int inW,int inH,ByteArray &inArray)
{
   int x1 = inX+inW;
   int y1 = inY+inH;
   if (inX<0 || inY<0 || x1>mPixelWidth || y1>mPixelHeight)
      return;

   if (inArray.mSize<inW*inH*4)
      return;

   bool alpha = mSurface->format->BitsPerPixel==32;
   bool bgr = mSurface->format->BitsPerPixel==24 &&
                  mSurface->format->Rmask != 0x0000ff;


   const unsigned char *ptr = inArray.mPtr;
   for(int y=inY;y<y1;y++)
   {
      unsigned char *pix =
         (unsigned char *)mSurface->pixels + y*mSurface->pitch + inX*4;

      if (alpha) // RGBA = ARGB
      {
         for(int x=inX;x<x1;x++)
         {
            pix[0 /* r */ ] = ptr[1];
            pix[1 /* g */ ] = ptr[2];
            pix[2 /* b */ ] = ptr[3];
            pix[3 /* a */ ] = ptr[0];

            ptr+=4;
            pix+=4;
         }
      }
      else if (bgr)
         for(int x=inX;x<x1;x++)
         {
            pix[0] = ptr[3];
            pix[1] = ptr[2];
            pix[2] = ptr[1];
            pix+=3;
            ptr+=4;
         }
      else
         for(int x=inX;x<x1;x++)
         {
            pix[0] = ptr[1];
            pix[1] = ptr[2];
            pix[2] = ptr[3];
            pix+=3;
            ptr+=4;
         }
   }

   SetExtentDirty(inX,inY,x1,y1);
}

void TextureBuffer::SetPixel(int inX,int inY,int inCol)
{
   if (inX<0 || inY<0 || inX>=Width() || inY>=Height())
      return;

   unsigned char *pix =
         (unsigned char *)mSurface->pixels + inY*mSurface->pitch + inX*4;

   int a = (inCol>>24) & 0xff;
   int r = (inCol>>16) & 0xff;
   int g = (inCol>>8) & 0xff;
   int b = (inCol) & 0xff;
   if (mSurface->format->BitsPerPixel==32)
   {
      if ( mSurface->format->Rmask == 0x0000ff)
      {
         *pix++ = r;
         *pix++ = g;
         *pix++ = b;
         *pix++ = a;
      }
      else
      {
         *pix++ = b;
         *pix++ = g;
         *pix++ = r;
         *pix++ = a;
      }
   }
   else if ( mSurface->format->BitsPerPixel==24 && mSurface->format->Rmask != 0x0000ff)
   {
      *pix++ = b;
      *pix++ = g;
      *pix++ = r;
   }
   else
   {
      *pix++ = r;
      *pix++ = g;
      *pix++ = b;
   }


   SetExtentDirty(inX,inY,inX+1,inY+1);
}

/*
 Format:

    1 = RGBA index
    2 = 32-bit RGB
    3 = RGB index
    4 = 15-bit RGB
    5 = 24-bit RGB
*/

int TextureBuffer::SetPixels(const unsigned char *inData, int inDataLen,
       int inFormat, int inTableLen)
{
   int w = mPixelWidth;
   int h = mPixelHeight;

   bool alpha = inFormat<3;

   // alpha mismatch
   if (alpha != (mSurface->format->BitsPerPixel==32) )
      return 0;

   bool bgr = mSurface->format->BitsPerPixel==24 &&
                  mSurface->format->Rmask != 0x0000ff;

   bool use_table = inFormat==1 || inFormat==3;

   static int src_sizes[] = { 0, 4, 4, 3, 2, 3 };
   int src_size = src_sizes[inFormat];

   const unsigned char *table = inData;
   const unsigned char *src_base = use_table ? inData + inTableLen*src_size : inData;
   int src_bbr = ((use_table ? w : src_size*w ) + 3 ) & ~3;

   int src_red = bgr ? 1 : 3;
   int src_blue = bgr ? 3 : 1;

   for(int y=0;y<h;y++)
   {
      const unsigned char *src = src_base + src_bbr * y;
      unsigned char *dest =
         (unsigned char *)mSurface->pixels + y*mSurface->pitch;

      if (inFormat==2)
      {
         for(int x=0;x<w;x++)
         {
            dest[0] = src[src_red];
            dest[1] = src[2];
            dest[2] = src[src_blue];
            dest[3] = src[0];
            dest+=4;
            src+=4;
         }
      }
   }


   SetExtentDirty(0,0,w,h);
   return 1;
}



value nme_load_texture(value inName)
{
   SDL_Surface *surface = nme_loadimage( inName );

   if (!surface)
      return val_null;

   TextureBuffer *buffer = new TextureBuffer(surface);

   return buffer->ToValue();

}

value nme_load_texture_from_bytes(value inBytes,value inLen, value inType,
   value inAlpha, value inAlphaLen)
{
   SDL_Surface *surface = nme_loadimage_from_bytes( inBytes, inLen, inType,
                              inAlpha, inAlphaLen);

   if (!surface)
      return val_null;

   TextureBuffer *buffer = new TextureBuffer(surface);

   return buffer->ToValue();

}


value nme_set_pixel_data(value inTexture,
           value inBuffer, value inBufferLen,
           value inFormat, value inTableLen )
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTexture);
   unsigned char *data = (unsigned char *)val_string(inBuffer);
   int len = val_int(inBufferLen);
   int format = val_int(inFormat);
   int table_len = val_int(inTableLen);

   return alloc_int(tex->SetPixels(data,len,format,table_len));
}

value nme_set_pixel(value inTexture, value inX, value inY, value inColour)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTexture);

   tex->SetPixel(val_int(inX), val_int(inY), val_int(inColour) | 0xff000000 );
   return alloc_int(0);
}


#ifdef HXCPP
value nme_set_pixel32(value inTexture, value inX, value inY, value inColour)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTexture);

   tex->SetPixel(val_int(inX), val_int(inY), val_int(inColour) );
   return alloc_int(0);
}
#else
value nme_set_pixel32(value inTexture, value inX, value inY, value inAlpha,value inRGB)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTexture);

   tex->SetPixel(val_int(inX), val_int(inY), (val_int(inAlpha)<<24) | val_int(inRGB) );
   return alloc_int(0);
}
#endif



value nme_texture_get_bytes(value inTex,value inRect)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTex);
   int x = (int)val_number( val_field( inRect, val_id( "x" ) ) );
   int y = (int)val_number( val_field( inRect, val_id( "y" ) ) );
   int w = (int)val_number( val_field( inRect, val_id( "width" ) ) );
   int h = (int)val_number( val_field( inRect, val_id( "height" ) ) );

   return tex->GetPixels(x,y,w,h)->ToValue();
}

value nme_texture_set_bytes(value inTex,value inRect,value inBytes)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTex);
   int x = (int)val_number( val_field( inRect, val_id( "x" ) ) );
   int y = (int)val_number( val_field( inRect, val_id( "y" ) ) );
   int w = (int)val_number( val_field( inRect, val_id( "width" ) ) );
   int h = (int)val_number( val_field( inRect, val_id( "height" ) ) );

   ByteArray *ba = BYTEARRAY(inBytes);

   tex->SetPixels(x,y,w,h,*ba);
   return alloc_int(0);
}



// --- Simple renderer -----------------------

DECLARE_KIND( k_tile_renderer );
DEFINE_KIND( k_tile_renderer );
#define TILE_RENDERER(v) ( (TileRenderer *)(val_data(v)) )


class TileRenderer
{
public:
   TileRenderer(TextureBuffer *inTexture,
                SDL_Surface *inDestSurface,
                int inX0,int inY0,
                int inWidth,int inHeight)
   {
      mTexture = inTexture->IncRef();
      mDestSurface = inDestSurface;
      mOpenGL =  IsOpenGLScreen(mDestSurface);

      mSrcRect.x = inX0;
      mSrcRect.y = inY0;
      mSrcRect.w = inWidth;
      mSrcRect.h = inHeight;

      if (mOpenGL)
      {
         mTexture->PrepareOpenGL();
         mTexture->UnBindOpenGL();
         mTexture->ScaleTexture(inX0,inY0,mT00[0],mT00[1]);
         mTexture->ScaleTexture(inX0+inWidth,inY0,mT10[0],mT10[1]);
         mTexture->ScaleTexture(inX0+inWidth,inY0+inHeight,mT11[0],mT11[1]);
         mTexture->ScaleTexture(inX0,inY0+inHeight,mT01[0],mT01[1]);
      }
      else
      {
         // TODO: convert to hardware surface?
      }
   }

   static Viewport mViewport;

   int Width() { return mSrcRect.w; }
   int Height() { return mSrcRect.h; }

   ~TileRenderer()
   {
      mTexture->DecRef();
   }

   void BlitTo(int inX0,int inY0,SDL_Surface *inDestSurface)
   {
      SDL_Rect    dest;
      dest.x = inX0;
      dest.y = inY0;
      SDL_BlitSurface(mTexture->GetSourceSurface(), &mSrcRect,
                      inDestSurface, &dest);
   }


   void Blit(int inX0,int inY0)
   {
      if (mOpenGL)
      {
         mTexture->BindOpenGL();
         glEnable(GL_BLEND);
         glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
         glColor3f(1,1,1);
         glBegin(GL_QUADS);
         glTexCoord2fv(mT00);
         glVertex2i(inX0,inY0);
         glTexCoord2fv(mT01);
         glVertex2i(inX0,inY0+mSrcRect.h);
         glTexCoord2fv(mT11);
         glVertex2i(inX0+mSrcRect.w,inY0+mSrcRect.h);
         glTexCoord2fv(mT10);
         glVertex2i(inX0+mSrcRect.w,inY0);
         glEnd();
      }
      else
      {
         BlitTo(inX0,inY0,mDestSurface);
      }
   }

   bool mOpenGL;
   TextureBuffer *mTexture;
   // SDL
   SDL_Surface *mDestSurface;
   SDL_Rect    mSrcRect;
   // Opengl
   float mT00[2];
   float mT10[2];
   float mT01[2];
   float mT11[2];
};

Viewport TileRenderer::mViewport(0,0,100,100);
static int sBlitOffsetX = 0;
static int sBlitOffsetY = 0;
static int sUseOffscreen = false;
static SDL_Surface *sOffscreen = 0;
static int sOffscreenAlpha = 0;
static double sDestX0 = 0;
static double sDestY0 = 0;
static double sDestWidth = 0;
static double sDestHeight = 0;


static void PasteOffscreen(SDL_Surface *inDest)
{
   /*
   SDL_Rect dest;
   dest.x = (int)sDestX0;
   dest.y = (int)sDestY0;
   printf("PasteOffscreen %d,%d   %dx%d\n", dest.x, dest.y, sOffscreen->w, sOffscreen->h);
   SDL_BlitSurface(sOffscreen, 0, inDest, &dest);
   */

      Matrix mapper(sOffscreen->w/sDestWidth, sOffscreen->h/sDestHeight);
      RenderArgs args;

      args.inN = 5;
      args.inLines = 0;
      char connect[] = { 0, 1, 1, 1, 1};
      args.inConnect = connect;
      PointF16 points[] = { PointF16(0.0,0.0),
                            PointF16(sDestWidth,0.0),
                            PointF16(sDestWidth,sDestHeight),
                            PointF16(0.0,sDestHeight),
                            PointF16(0.0,0.0) };
      args.inPoints = points;
      args.inMinY = points[0].y;
      args.inMaxY = points[2].y;
      args.inFlags = NME_HIGH_QUALITY | NME_ALPHA_BLEND | NME_EDGE_CLAMP;

      // This could be pretty slow...
      PolygonRenderer *renderer = PolygonRenderer::CreateBitmapRenderer(args,sOffscreen, mapper);
      Viewport vp(0,0,inDest->w,inDest->h);
      renderer->Render(inDest,vp,(int)sDestX0,(int)sDestY0);
      delete renderer;
}




void delete_tile_renderer( value tile_renderer )
{
   if ( val_is_kind( tile_renderer, k_tile_renderer ) )
   {
      val_gc( tile_renderer, NULL );

      delete TILE_RENDERER(tile_renderer);
   }
}

value nme_tile_renderer_width( value tile_renderer )
{
   if ( val_is_kind( tile_renderer, k_tile_renderer ) )
   {
      TileRenderer* t = TILE_RENDERER(tile_renderer);
      return alloc_int(t->Width());
   }

   return alloc_int(0);
}

value nme_tile_renderer_height( value tile_renderer )
{
   if ( val_is_kind( tile_renderer, k_tile_renderer ) )
   {
      TileRenderer* t = TILE_RENDERER(tile_renderer);
      return alloc_int(t->Height());
   }

   return alloc_int(0);
}

value nme_create_blitter(value* arg, int nargs )
{
   enum { aTex, aSurface, aX0, aY0, aWidth, aHeight, aSIZE };
   if (nargs!=aSIZE)
      failure( "nme_create_blitter - wrong number of args.\n" );

   val_check_kind( arg[aTex], k_texture_buffer );
   val_check_kind( arg[aSurface], k_surf );
   val_check( arg[aX0], int );
   val_check( arg[aY0], int );
   val_check( arg[aWidth], int );
   val_check( arg[aHeight], int );

   TileRenderer *result = new TileRenderer( TEXTURE_BUFFER(arg[aTex]),
                                            SURFACE(arg[aSurface]),
                                            val_int(arg[aX0]),
                                            val_int(arg[aY0]),
                                            val_int(arg[aWidth]),
                                            val_int(arg[aHeight]) );
   value v = alloc_abstract( k_tile_renderer, result );
   val_gc( v, delete_tile_renderer );
   return v;
}

value nme_blit_tile( value tile_renderer, value x, value y )
{
   if ( val_is_kind( tile_renderer, k_tile_renderer ) )
   {
      TileRenderer* t = TILE_RENDERER(tile_renderer);
      if (sOffscreen && sUseOffscreen)
      {
         t->BlitTo( val_int(x), val_int(y),sOffscreen );
      }
      else
         t->Blit( val_int(x) + sBlitOffsetX, val_int(y) + sBlitOffsetY );
   }

   return alloc_int(0);
}

value nme_set_blit_area(value surface, value inRect,value inColour,value inAlpha,value matrix)
{
   SDL_Surface *s = 0;
   TextureBuffer *tex=0;


   if ( val_is_kind( surface, k_surf )  )
   {
      s = SURFACE(surface);
   }
   else if ( val_is_kind( surface, k_texture_buffer )  )
   {
      tex = TEXTURE_BUFFER(surface);
      s = tex->GetSourceSurface();
   }

   sBlitOffsetX = 0;
   sBlitOffsetY = 0;

   // Unset ...
   if (val_is_null(inRect))
   {
       if (s && IsOpenGLScreen(s))
       {
          int w = s->w;
          int h = s->h;
          glViewport(0,0,w,h);
          glMatrixMode(GL_PROJECTION);
          glLoadIdentity();
          glOrtho(0,w, h,0, -1000,1000);
          glMatrixMode(GL_MODELVIEW);
          glLoadIdentity();
          sUseOffscreen = false;
       }
       else if (s)
       {
         SDL_SetClipRect(s,0);
         if (sUseOffscreen)
         {
            PasteOffscreen(s);
            sUseOffscreen = false;
         }
       }
       return val_null;
   }

   sUseOffscreen = false;

   if (s)
   {
      Viewport vp( 0,0, s->w, s->h );

      Matrix mtx(matrix);
      int x0 = (int)mtx.mtx;
      int y0 = (int)mtx.mty;
      //int x1 = x0 + (int)(val_number( val_field(inRect,val_id_width) ) * mtx.m00);
      //int y1 = y0 + (int)(val_number( val_field(inRect,val_id_height) ) * mtx.m11);
      int x1 = x0 + (int)(val_number( val_field(inRect,val_id_width) ));
      int y1 = y0 + (int)(val_number( val_field(inRect,val_id_height) ));
      if (x0>x1) std::swap(x0,x1);
      if (y0>y1) std::swap(y0,y1);
      vp.SetWindow(x0,y0,x1,y1);

      int c = val_int(inColour);
      int r = (c>>16) & 0xff;
      int g = (c>>8) & 0xff;
      int b = (c) & 0xff;
      int a = val_int(inAlpha);
      {
          if (IsOpenGLScreen(s))
          {
             int pixel_w = (int)((x1-x0)*mtx.m00);
             int pixel_h = (int)((y1-y0)*mtx.m11);
             glViewport(vp.x0,s->h-vp.y0-pixel_h, pixel_w, pixel_h);
             glMatrixMode(GL_PROJECTION);
             glLoadIdentity();

             int w = (int)val_number(val_field(inRect,val_id_width));
             int h = (int)val_number(val_field(inRect,val_id_height));

             // By setting origin to 0,0 we make coords relative to blit area.
             glOrtho(0,w, h,0, -1000,1000);
             glMatrixMode(GL_MODELVIEW);
             glLoadIdentity();

             // Clear screen ..
             if (a==255)
             {
               glClearColor((float)(r/255.0),(float)(g/255.0),(float)(b/255.0),(float)(a/255.0));
               glClear(GL_COLOR_BUFFER_BIT);
             }
             else if (a>0)
             {
                glDisable(GL_TEXTURE_2D);
                glEnable(GL_BLEND);
                glColor4ub(r,g,b,a);
                glBegin(GL_QUADS);
                  glVertex2i(0,0);
                  glVertex2i(0,h);
                  glVertex2i(w,h);
                glVertex2i(w,0);
                glEnd();
             }
          }
          else
          {
             // Blit to offscren surface and then paste it ...
             if (mtx.m00!=1.0 || mtx.m11!=1.0)
             {
                int ow = vp.Width();
                int oh = vp.Height();
                sDestX0 =  vp.x0;
                sDestY0 =  vp.y0;
                sDestWidth =  vp.Width() * mtx.m00;
                sDestHeight =  vp.Height() * mtx.m11;
                sUseOffscreen = true;
                // Create surface if different ...
                int flags = SDL_HWSURFACE;
                if (sOffscreen==0 || sOffscreen->w!=ow || sOffscreen->h!=oh || a!=sOffscreenAlpha)
                {
                   if (sOffscreen)
                      SDL_FreeSurface(sOffscreen);
                   sOffscreenAlpha = a;
                   if (a!=255)
                   {
                      sOffscreen = SDL_CreateRGBSurface(flags, ow, oh, 32,
                                  0xff0000, 0xff00, 0xff, 0xff000000 );
                   }
                   else
                   {
                      sOffscreen = SDL_CreateRGBSurface(flags, ow, oh, 32,
                                  0xff0000, 0xff00, 0xff, 0 );
                   }
                }
             }
             else
             {
                // Since coords are relative to clip area, add the offset
                sBlitOffsetX = vp.x0;
                sBlitOffsetY = vp.y0;

                SDL_Rect rect;
                rect.x = vp.x0;
                rect.y = vp.y0;
                rect.w = vp.Width();
                rect.h = vp.Height();
                SDL_SetClipRect(s,&rect);
             }

             SDL_FillRect( sUseOffscreen ? sOffscreen : s, NULL, SDL_MapRGBA( s->format, r, g, b,a ) );
          }
      }
   }
   
   return val_null;
}


value nme_copy_pixels(value* arg, int nargs )
{
   enum { aSrc, aSX0, aSY0, aWidth, aHeight, aDest, aDestX, aDestY, aSIZE };
   if (nargs!=aSIZE)
      failure( "nme_copy_pixels - wrong number of args.\n" );

   TextureBuffer *src = TEXTURE_BUFFER(arg[aSrc]);
   TextureBuffer *dest = TEXTURE_BUFFER(arg[aDest]);

   SDL_Rect src_rect;
   src_rect.x = (int)val_number(arg[aSX0]);
   src_rect.y = (int)val_number(arg[aSY0]);
   src_rect.w = (int)val_number(arg[aWidth]);
   src_rect.h = (int)val_number(arg[aHeight]);

   SDL_Rect dest_rect = src_rect;
   dest_rect.x = (int)val_number(arg[aDestX]);
   dest_rect.y = (int)val_number(arg[aDestY]);

   SDL_BlitSurface(src->GetSourceSurface(), &src_rect,
                         dest->GetSourceSurface(), &dest_rect);
   dest->SetExtentDirty(dest_rect.x,dest_rect.y, dest_rect.x+dest_rect.w, dest_rect.y+dest_rect.h);

   return val_null;
}

static int x_id = val_id("x");
static int y_id = val_id("y");
static int width_id = val_id("width");
static int height_id = val_id("height");


value nme_tex_fill_rect(value inTex,value inRect,value inCol,value inAlpha)
{
   TextureBuffer *dest = TEXTURE_BUFFER(inTex);
   SDL_Surface *surf = dest->GetSourceSurface();

   SDL_Rect rect;
   rect.x = (int)val_number( val_field(inRect, x_id ) );
   rect.y = (int)val_number( val_field(inRect, y_id ) );
   rect.w = (int)val_number( val_field(inRect, width_id ) );
   rect.h = (int)val_number( val_field(inRect, height_id ) );

   int rgb = val_int(inCol);
   int alpha = val_int(inAlpha);
   unsigned int col = SDL_MapRGBA( surf->format, rgb>>16, (rgb>>8)&0xff, rgb&0xff, alpha );
   SDL_FillRect( surf, &rect, col );

   dest->SetExtentDirty(rect.x,rect.y, rect.x+rect.w, rect.y+rect.h);

   return val_null;
}


// --- TextureReference -----------------------------------------

TextureReference *TextureReference::Create(value inVal)
{
   if (val_is_null(inVal))
      return 0;
   value  tb= val_field(inVal,val_id("texture_buffer"));
   if (val_is_null(tb))
      return 0;
   TextureBuffer  *tex=TEXTURE_BUFFER(tb);
   if (!tex)
      return 0;

   int flags = val_int((val_field(inVal,val_id("flags"))));
   if (tex->GetSourceSurface()->format->BitsPerPixel==32)
      flags |= NME_ALPHA_BLEND;

   Matrix matrix(val_field(inVal,val_id("matrix")));

   return new TextureReference(tex,matrix,flags);
}

DEFINE_PRIM_MULT(nme_create_blitter);
DEFINE_PRIM(nme_blit_tile, 3);
    
DEFINE_PRIM_MULT(nme_copy_pixels);
DEFINE_PRIM(nme_tex_fill_rect,4);

DEFINE_PRIM(nme_create_texture_buffer, 5);
DEFINE_PRIM(nme_load_texture, 1);
DEFINE_PRIM(nme_load_texture_from_bytes, 5);
DEFINE_PRIM(nme_set_pixel_data, 5);
DEFINE_PRIM(nme_set_pixel, 4);
#ifdef HXCPP
DEFINE_PRIM(nme_set_pixel32, 4);
#else
DEFINE_PRIM(nme_set_pixel32, 5);
#endif
DEFINE_PRIM(nme_texture_width, 1);
DEFINE_PRIM(nme_texture_height, 1);
DEFINE_PRIM(nme_scroll_texture, 3);
DEFINE_PRIM(nme_tile_renderer_width, 1);
DEFINE_PRIM(nme_tile_renderer_height, 1);
DEFINE_PRIM(nme_texture_get_bytes, 2);
DEFINE_PRIM(nme_texture_set_bytes, 3);
DEFINE_PRIM(nme_set_blit_area, 5);



