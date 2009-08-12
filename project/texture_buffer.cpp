#include <string>
#include "texture_buffer.h"
#ifdef WIN32
#include <windows.h>
#endif
#include "nme.h"
#ifdef NME_ANY_GL
#include <SDL_opengl.h>
#endif
#include "nsdl.h"
#include "ByteArray.h"
#include "renderer/Renderer.h"
#include "OGLState.h"


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
/*
   SDL_Rect rect;
   rect.x = 0;
   rect.y = 0;
   rect.w = inSurface->w;
   rect.h = inSurface->h;
   SDL_FillRect(inSurface,&rect,0x00ff);
*/
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
   #ifdef NME_ANY_GL
   if (mTextureID>0 && nme_resize_id==mResizeID)
      glDeleteTextures(1,&mTextureID);
   #endif
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


// SDL seems to not work for palettes - mybe a 1.3 problem?
void MY_SDL_BlitSurface(SDL_Surface *inSrc, SDL_Rect *inSrcRect,
     SDL_Surface *inDest, SDL_Rect *inDestRect)
{
   int x0 = inSrcRect ? inSrcRect->x : 0;
   int y0 = inSrcRect ? inSrcRect->y : 0;
   int w = inSrcRect ? inSrcRect->w : inSrc->w;
   int h = inSrcRect ? inSrcRect->h : inSrc->h;
   int dx = inDestRect ? inDestRect->x : 0;
   int dy = inDestRect ? inDestRect->y : 0;

   if (inSrc->format->BitsPerPixel==8)
   {
      {
         SDL_Palette *pal = inSrc->format->palette;
         SDL_Color *col = pal->colors;
         SDL_Color col0 = *col;

         for(int y=0;y<h;y++)
         {
            unsigned char *dest = (unsigned char *)inDest->pixels +
                                          inDest->pitch*(y+dy) + 4*dx;
            unsigned char *src =  (unsigned char *)inSrc->pixels +
                       inSrc->pitch*(y+y0) + 4*x0;
            if (inDest->format->BitsPerPixel==32)
            {
               if (0) //inSrc->flags & SDL_SRCALPHA)
                  for(int x=0;x<w;x++)
                  {
                     *dest++ = col0.r;
                     *dest++ = col0.g;
                     *dest++ = col0.b;
                     *dest++ = *src++;
                  }
               else
                  for(int x=0;x<w;x++)
                  {
                     SDL_Color *c = col + (*src++);
                     *dest++ = c->r;
                     *dest++ = c->g;
                     *dest++ = c->b;
                     *dest++ = 0xff;
                  }
            }
            else
               for(int x=0;x<w;x++)
               {
                  SDL_Color *c = col + (*src++);
                  *dest++ = c->r;
                  *dest++ = c->g;
                  *dest++ = c->b;
               }
         }
      }
      /*
      else
         for(int y=0;y<h;y++)
            memcpy( (char *)inDest->pixels + inDest->pitch*(y+dy) + 4*dx,
                    (char *)inSrc->pixels +  inSrc->pitch*(y+y0) + 4*x0, 4*w );
       */
   }
   else
   {
#if 0
      SDL_BlitSurface(inSrc,inSrcRect,inDest,inDestRect);
#endif

      for(int y=0;y<h;y++)
      {
         int *dest = (int *)((unsigned char *)inDest->pixels +
                                          inDest->pitch*(y+dy) + 4*dx);
         unsigned char *src =  (unsigned char *)inSrc->pixels +
                       inSrc->pitch*(y+y0) + 4*x0;
         memcpy(dest,src,w*sizeof(int));
      }
   }
}

#ifdef NME_ANY_GL
bool TextureBuffer::PrepareOpenGL()
{
   if (mTextureID==0 || mResizeID != nme_resize_id)
   {
      // int err = glGetError(); if (err) printf("Error before PrepareOpenGL\n");

      SDL_Surface *data = mSurface;
      SDL_Surface *cleanup = 0;
      int src_format = GL_BGRA;
      int store_format = 4;
      mResizeID = nme_resize_id;
      bool convert = false;

      int w = UpToPower2(mSurface->w);
      int h = UpToPower2(mSurface->h);
      bool is_pow2 = w==mSurface->w && h==mSurface->h;


      if (mSurface->format->BitsPerPixel==32 )
      {
         if (mSurface->flags & SDL_SRCALPHA)
         {
            if (mSurface->format->Rmask == 0x0000ff)
               src_format = GL_RGBA;
            else
               src_format = GL_BGRA;
            // Ok !
         }
         else
         {
            if (mSurface->format->Rmask == 0x0000ff)
               src_format = GL_RGBA;
            else
               src_format = GL_BGRA;
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
      else
         convert = true;

      //err = glGetError(); if (err) printf("Error loading texture 0 : %d\n",err);

      #ifdef NME_OPENGLES
      if (!is_pow2 || (src_format!=GL_RGB && src_format!=GL_RGBA) )
         convert = true;
      else
         store_format = src_format;
      #endif

      if (convert)
      {
         #ifdef NME_OPENGLES
         int target_w = w;
         int target_h = h;
         is_pow2 = true;
         #else
         int target_w = mSurface->w;
         int target_h = mSurface->h;
         #endif

         bool alpha =  (mSurface->flags & SDL_SRCALPHA);
         data = CreateRGB(target_w, target_h, alpha);

         MY_SDL_BlitSurface(mSurface, 0, data, 0);

         if (mSurface->h < target_h)
         {
             // Double last row...
             SDL_Rect src;
             src.x = 0;
             src.y = mSurface->h-1;
             src.w = mSurface->w;
             src.h = 1;
             SDL_Rect dest;
             dest.x = 0;
             dest.y = mSurface->h;
             MY_SDL_BlitSurface(mSurface, &src, data, &dest);
             if (mSurface->w < w)
             {
                 src.x = src.w-1;
                 src.w = 1;
                 dest.x = mSurface->w;
                 dest.y = mSurface->h;
                 MY_SDL_BlitSurface(mSurface, &src, data, &dest);
             }
         }
         if (mSurface->h < target_h)
         {
             // Double last col...
             SDL_Rect src;
             src.x = mSurface->w-1;
             src.y = 0;
             src.w = 1;
             src.h = mSurface->h;
             SDL_Rect dest;
             dest.x = mSurface->w;
             dest.y = 0;
             MY_SDL_BlitSurface(mSurface, &src, data, &dest);
         }
         cleanup = data;
         src_format = store_format = alpha ? GL_RGBA : GL_RGB;
      }

      //err = glGetError(); if (err) printf("Error loading texture 0a : %d\n",err);

      glGenTextures(1, &mTextureID);
      nmeSetTexture(mTextureID,true);
      mRepeat = false;
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

      //printf("Creating texture %d %dx%d\n",mTextureID, mPixelWidth, mPixelHeight);
      //err = glGetError(); if (err) printf("Error loading texture 1 : %d\n",err);

      if ( !is_pow2 )
      {
         #ifdef NME_OPENGLES
         store_format = src_format;
         #endif
         glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, src_format,
            GL_UNSIGNED_BYTE, 0 );

         glTexSubImage2D(GL_TEXTURE_2D, 0, 0,0, mSurface->w, mSurface->h,
            src_format, GL_UNSIGNED_BYTE, data->pixels );

         // Double the last row for linear filtering ...
         if ( mSurface->h != h )
         {
             glTexSubImage2D(GL_TEXTURE_2D, 0, 0,mSurface->h, mSurface->w, 1,
               src_format, GL_UNSIGNED_BYTE,
              (char *)data->pixels + mSurface->pitch*(mSurface->h-1) );
         }
         // Double the last col for linear filtering ...
         if ( mSurface->w != w )
         {
            glPixelStorei(GL_UNPACK_ROW_LENGTH, mSurface->w);
            glTexSubImage2D(GL_TEXTURE_2D, 0, mSurface->w,0, 1, mSurface->h,
              src_format, GL_UNSIGNED_BYTE,
              (char *)data->pixels + (mSurface->w-1)*mSurface->format->BitsPerPixel/8 );
            glPixelStorei(GL_UNPACK_ROW_LENGTH,0);

            // Quadrupal the corner pixel!
            if ( mSurface->h != h )
             glTexSubImage2D(GL_TEXTURE_2D, 0, mSurface->w,mSurface->h, 1, 1,
              src_format, GL_UNSIGNED_BYTE,
              (char *)data->pixels + (mSurface->h-1)*mSurface->pitch +
                                     (mSurface->w-1)*mSurface->format->BitsPerPixel/8 );
         }
      }
      else
      {
         glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, src_format,
            GL_UNSIGNED_BYTE, data->pixels );
      }

      //err = glGetError(); if (err) printf("Error loading texture 2 : %d\n",err);

      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

      if (cleanup)
         SDL_FreeSurface(cleanup);

      mX1 = w>0 ? (float)mPixelWidth/w : 0.0f;
      mY1 = h>0 ? (float)mPixelHeight/h : 0.0f;
      mSW = (float)(w >0 ? 1.0/w : 0);
      mSH = (float)(h >0 ? 1.0/h : 0);
      mHardwareDirty = false;

      //err = glGetError(); if (err) printf("Error loading texture 3 : %d\n",err);
   }
   else if (mHardwareDirty)
   {
      nmeSetTexture(GL_TEXTURE_2D);
      UpdateHardware();
   }
   else
   {
      nmeSetTexture(GL_TEXTURE_2D);
   }

   nmeEnableTexture(true);

   return true;
}

void TextureBuffer::UpdateHardware()
{
   if (!mHardwareDirty)
      return;

   if (!mTextureID)
   {
      //printf("No textureID?\n");
      return;
   }

   glGetError();

   nmeSetTexture(mTextureID,true);


   if (mDirtyX0<0) mDirtyX0 = 0;
   if (mDirtyY0<0) mDirtyY0 = 0;
   if (mDirtyX1>mPixelWidth)  mDirtyX1 = mPixelWidth;
   if (mDirtyY1>mPixelHeight) mDirtyY1 = mPixelHeight;

   //printf("Update %d,%d %dx%d\n",mDirtyX0, mDirtyY0, mDirtyX1, mDirtyY1);

   glPixelStorei(GL_UNPACK_ROW_LENGTH, mSurface->w);
   glPixelStorei(GL_UNPACK_SKIP_PIXELS, mDirtyX0);
   glPixelStorei(GL_UNPACK_SKIP_ROWS,   mDirtyY0);

   glTexSubImage2D(GL_TEXTURE_2D, 0, mDirtyX0,mDirtyY0,
         mDirtyX1-mDirtyX0, mDirtyY1 - mDirtyY0,
         GL_RGBA, GL_UNSIGNED_BYTE, mSurface->pixels );

   /// TODO: duplicate pixel rows?
   glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
   glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
   glPixelStorei(GL_UNPACK_SKIP_ROWS,   0);

   int err = glGetError();
   //if (err) printf("UpdateHardware : error %d\n", err);

   mHardwareDirty = false;
}



void TextureBuffer::TexCoord(float *outCoord,float inX,float inY)
{
   outCoord[0] = inX*mX1;
   outCoord[1] = inY*mY1;
}

void TextureBuffer::TexCoordScaled(float *outCoord,float inX,float inY)
{
   outCoord[0] = inX*mSW;
   outCoord[1] = inY*mSH;
}


#endif


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
      SDL_Surface *tmp = CreateRGB(sx1-sx0,  sy1-sy0,
                    (mSurface->flags & SDL_SRCALPHA), false);

      // Do dumb compies
      SDL_SetAlpha(tmp,0,255);

      int was_alpha = mSurface->flags & SDL_SRCALPHA;
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


#ifdef NME_ANY_GL
void TextureBuffer::BindOpenGL(bool inRepeat)
{
   PrepareOpenGL();
   nmeEnableTexture(true);
   if (inRepeat!=mRepeat)
   {
      nmeSetTexture(mTextureID,true);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, inRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, inRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE );
      mRepeat = inRepeat;
   }
   else
      nmeSetTexture(mTextureID);
}

void TextureBuffer::UnBindOpenGL()
{
   nmeSetTexture(0);
}




void TextureBuffer::DrawOpenGL(float inAlpha)
{
//printf("DrawOpenGL %d %d %dx%d\n", mTextureID, mHardwareDirty, mSurface->w, mSurface->h);
   if (!PrepareOpenGL())
      return;

   glColor4f(1,1,1,inAlpha);
   nmeSetBlend(true,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

   float verts[][2] = { {0,0}, {0,mPixelHeight}, {mPixelWidth,mPixelHeight}, {mPixelWidth,0} };
   float tex[][2] = { {0,0}, {0,mY1}, {mX1,mY1}, {mX1,0} };
   glVertexPointer(2, GL_FLOAT, 0, &verts[0][0] );
   glTexCoordPointer(2, GL_FLOAT, 0, &tex[0][0] );

   nmeDrawArrays(GL_TRIANGLE_FAN, 4);
}

#endif


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

   SDL_Surface *surface = CreateRGB( val_int(width), val_int(height),
                            f&HX_TRANSPARENT, f&HX_HARDWARE );

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

/**
* Returns 32 bit ARGB value for pixel at inX,inY
*
* @param inX X coordinate
* @param inY Y coordinate
* @return 32 bit color ARGB value
**/
Uint32 TextureBuffer::GetPixel(int inX, int inY)
{
	Uint8 r, g, b, a;

	if (inX<0 || inY<0 || inX > mPixelWidth || inY > mPixelHeight)
		return 0;

	SDL_PixelFormat *fmt = mSurface->format;
	Uint32 color = 0;

	//--
	SDL_LockSurface(mSurface);
	//--
	if(fmt->BitsPerPixel == 8) {
		Uint8 index = *(Uint8 *)mSurface->pixels + inY*mSurface->w + inX;
		SDL_Color colorEntry = fmt->palette->colors[index];
		a = 0xFF;
		r = colorEntry.r;
		g = colorEntry.g;
		b = colorEntry.b;
	}
	else {
		Uint32 val, pixel = 0;

		switch(fmt->BitsPerPixel) {
		case 16:
			pixel = (Uint32)((Uint16 *)mSurface->pixels)[inY*mSurface->w + inX];
			break;
		case 24:
		case 32:
			pixel = ((Uint32 *)mSurface->pixels)[inY*mSurface->w + inX];
			break;
		}
		// Alpha
		val = pixel & fmt->Amask;
		val = val >> fmt->Ashift;
		val = val << fmt->Aloss;
		a = (Uint8)val;
		// Red
		val = pixel & fmt->Rmask;
		val = val >> fmt->Rshift;
		val = val << fmt->Rloss;
		r = (Uint8)val;
		// Green
		val = pixel & fmt->Gmask;
		val = val >> fmt->Gshift;
		val = val << fmt->Gloss;
		g = (Uint8)val;

		// Blue
		val = pixel & fmt->Bmask;
		val = val >> fmt->Bshift;
		val = val << fmt->Bloss;
		b = (Uint8)val;
	}
	//--
	SDL_UnlockSurface(mSurface);
	//--
	color = (a << 24) | (r << 16) | (g << 8) | b;
	//--
	return color;
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

/**
* Clones the srcTexture TextureBuffer and it's SDL_Surface
* @param srcTexture Source to copy from
* @return Handle value to TextureBuffer instance
*/
value nme_clone_texture_buffer(value srcTexture) {
	TextureBuffer *src = TEXTURE_BUFFER(srcTexture);

	if(!src)
		return val_null;

	SDL_Surface *surface = ConvertToPreferredFormat(src->GetSourceSurface());

	//--
	TextureBuffer *buffer = new TextureBuffer(surface);
	return buffer->ToValue();
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

/**
* Return a 24 bit RGB color value of the pixel at inX,inY
* @return Int value
**/
value nme_get_pixel(value inTexture, value inX, value inY) {
	TextureBuffer *tex = TEXTURE_BUFFER(inTexture);
	Uint32 color = tex->GetPixel(val_int(inX), val_int(inY));
	color &= 0xFFFFFF;
	return alloc_int(color);
}

/**
* Return a 32 bit ARGB color value of the pixel at inX,inY
* @return Int32 value
**/
value nme_get_pixel32(value inTexture, value inX, value inY) {
	TextureBuffer *tex = TEXTURE_BUFFER(inTexture);
	Uint32 color = tex->GetPixel(val_int(inX), val_int(inY));
	return alloc_best_int((int)color);
	return alloc_int32(color);
}

/**
* Returns whether or not the surface has it's transparency bit set
* @return bool
**/
value nme_get_transparent(value inTexture) {
	TextureBuffer *tex = TEXTURE_BUFFER(inTexture);
	return alloc_bool(tex->GetSourceSurface()->format->Amask | tex->GetSourceSurface()->flags & SDL_SRCCOLORKEY);
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

value nme_set_pixel32(value inTexture, value inX, value inY, value inColour)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTexture);

   tex->SetPixel(val_int(inX), val_int(inY), val_int(inColour) );
   return alloc_int(0);
}

value nme_set_pixel32_ex(value inTexture, value inX, value inY, value inAlpha, value inRGB)
{
   TextureBuffer *tex = TEXTURE_BUFFER(inTexture);

   tex->SetPixel(val_int(inX), val_int(inY), (val_int(inAlpha)<<24) | val_int(inRGB) );
   return alloc_int(0);
}

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

std::vector<Tri> sQuadTris;

class TileRenderer
{
public:
   TileRenderer(TextureBuffer *inTexture,
                SDL_Surface *inDestSurface,
                int inX0,int inY0,
                int inWidth,int inHeight,
                double inHotX, double inHotY)
   {
      mTexture = inTexture->IncRef();
      mDestSurface = inDestSurface;
      mOpenGL =  IsOpenGLScreen(mDestSurface);

      mSrcRect.x = inX0;
      mSrcRect.y = inY0;
      mSrcRect.w = inWidth;
      mSrcRect.h = inHeight;
      mHotX = inHotX;
      mHotY = inHotY;

      mPoints.resize(4);
      for(int i=0;i<4;i++)
      {
         TriPoint &p = mPoints[i];
         p.SetUVW( inX0 + (i==1||i==2) * inWidth, inY0 + (i==2||i==3) * inHeight);
      }

      #ifdef NME_ANY_GL
      if (mOpenGL)
      {
         mTexture->PrepareOpenGL();
         mTexture->UnBindOpenGL();
         mTexture->ScaleTexture(inX0,inY0,mTex[0][0],mTex[0][1]);
         mTexture->ScaleTexture(inX0,inY0+inHeight,mTex[1][0],mTex[1][1]);
         mTexture->ScaleTexture(inX0+inWidth,inY0+inHeight,mTex[2][0],mTex[2][1]);
         mTexture->ScaleTexture(inX0+inWidth,inY0,mTex[3][0],mTex[3][1]);
      }
      else
      #endif
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

   void BlitTo(double inX0,double inY0,SDL_Surface *inDestSurface,double inTheta,double inScale)
   {
      if (inTheta ==0 && inScale==1)
      {
         SDL_Rect    dest;
         dest.x = (int)(inX0-mHotX);
         dest.y = (int)(inY0-mHotY);
         SDL_BlitSurface(mTexture->GetSourceSurface(), &mSrcRect, inDestSurface, &dest);
      }
      else
      {
         if (sQuadTris.empty())
         {
            sQuadTris.push_back( Tri(0,1,2) );
            sQuadTris.push_back( Tri(0,2,3) );
         }
         inTheta *= (3.14159265358979323846/180.0);
         double c = cos(inTheta)*inScale;
         double s = sin(inTheta)*inScale;
         for(int i=0;i<4;i++)
         {
            TriPoint &p = mPoints[i];
            double x = (i==1||i==2)*mSrcRect.w - mHotX;
            double y = (i==2||i==3)*mSrcRect.h - mHotY;
            p.mPos16 = PointF16( x*c + y*s + inX0, -x*s + y*c + inY0);
         }


         PolygonRenderer *renderer = PolygonRenderer::CreateBitmapTriangles(mPoints,sQuadTris,
                             mTexture->GetSourceSurface(),
                             NME_EDGE_CLAMP|NME_BMP_LINEAR );

         SDL_Rect r;
         SDL_GetClipRect(inDestSurface,&r);
         Viewport vp(r.x,r.y,r.w,r.h);
         renderer->Render(inDestSurface,vp,0,0);
         delete renderer;
      }
   }


   void Blit(double inX0,double inY0,double inTheta,double inScale)
   {
      #ifdef NME_ANY_GL
      if (mOpenGL)
      {
         mTexture->BindOpenGL();
         nmeSetBlend(true);
         glColor4f(1,1,1,1);

         if (inTheta==0.0)
         {
            inX0 -= mHotX;
            inY0 -= mHotY;

            float verts[][2] = {
                     {inX0,inY0},
                     {inX0,inY0+mSrcRect.h},
                     {inX0+mSrcRect.w,inY0+mSrcRect.h},
                     {inX0+mSrcRect.w,inY0} };
            glVertexPointer(2, GL_FLOAT, 0, &verts[0][0] );
            glTexCoordPointer(2, GL_FLOAT, 0, &mTex[0][0] );

            nmeDrawArrays(GL_TRIANGLE_FAN,4);
         }
         else
         {
            glPushMatrix();

            glTranslatef(inX0,inY0,0);
            glRotatef(inTheta,0.0,0.0,-1.0);
            glScalef(inScale,inScale,1);
            glTranslatef(-mHotX,-mHotY,0);

            float verts[][2] = {
                   { 0, 0 },
                   { 0, mSrcRect.h },
                   { mSrcRect.w , mSrcRect.h },
                   { mSrcRect.w , 0}
            };

            glVertexPointer(2, GL_FLOAT, 0, &verts[0][0] );
            glTexCoordPointer(2, GL_FLOAT, 0, &mTex[0][0] );

 
            nmeDrawArrays(GL_TRIANGLE_FAN,4);

            glPopMatrix();
         }
      }
      else
      #endif
      {
         BlitTo(inX0,inY0,mDestSurface,inTheta,inScale);
      }
   }

   bool mOpenGL;
   TextureBuffer *mTexture;
   // SDL
   SDL_Surface *mDestSurface;
   SDL_Rect    mSrcRect;
   // Opengl
   float mTex[4][2];

   double mHotX,mHotY;
   TriPoints mPoints;
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
   enum { aTex, aSurface, aX0, aY0, aWidth, aHeight, aHotX, aHotY, aSIZE };
   if (nargs!=aSIZE)
   {
      hx_failure( "nme_create_blitter - wrong number of args.\n" );
   }

   if( val_is_null(arg[aTex]))
   {
      //printf("Null texture?\n");
      return alloc_null();
   }

   val_check_kind( arg[aTex], k_texture_buffer );
   val_check_kind( arg[aSurface], k_surf );
   val_check( arg[aX0], int );
   val_check( arg[aY0], int );
   val_check( arg[aWidth], int );
   val_check( arg[aHeight], int );
   val_check( arg[aHotX], number );
   val_check( arg[aHotY], number );

   TileRenderer *result = new TileRenderer( TEXTURE_BUFFER(arg[aTex]),
                                            SURFACE(arg[aSurface]),
                                            val_int(arg[aX0]),
                                            val_int(arg[aY0]),
                                            val_int(arg[aWidth]),
                                            val_int(arg[aHeight]),
                                            val_number(arg[aHotX]),
                                            val_number(arg[aHotY]) );
   value v = alloc_abstract( k_tile_renderer, result );
   val_gc( v, delete_tile_renderer );
   return v;
}

value nme_blit_tile( value tile_renderer, value x, value y, value theta, value scale )
{
   if ( val_is_kind( tile_renderer, k_tile_renderer ) )
   {
      TileRenderer* t = TILE_RENDERER(tile_renderer);
      if (sOffscreen && sUseOffscreen)
      {
         t->BlitTo( val_number(x), val_number(y),sOffscreen, val_number(theta), val_number(scale) );
      }
      else
         t->Blit( val_number(x) + sBlitOffsetX, val_number(y) + sBlitOffsetY, val_number(theta), val_number(scale) );
   }

   return alloc_null();
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
       #ifdef NME_ANY_GL
       if (s && IsOpenGLScreen(s))
       {
          int w = s->w;
          int h = s->h;
          glViewport(0,0,w,h);
          glMatrixMode(GL_PROJECTION);
          nmeOrtho(w,h);
          glMatrixMode(GL_MODELVIEW);
          glLoadIdentity();
          sUseOffscreen = false;
       }
       else
       #endif
       if (s)
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
          #ifdef NME_ANY_GL
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
             nmeOrtho(w,h);
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
                nmeEnableTexture(false);
                nmeSetBlend(true);
                glColor4ub(r,g,b,a);

                float verts[][2] = { {0,0}, {0,h}, {w,h}, {w,0} };
                glVertexPointer(2, GL_FLOAT, 0, &verts[0][0] );

                nmeDrawArrays(GL_TRIANGLE_FAN,4);
             }
          }
          else
          #endif
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
                if (sOffscreen==0 || sOffscreen->w!=ow || sOffscreen->h!=oh || a!=sOffscreenAlpha)
                {
                   if (sOffscreen)
                      SDL_FreeSurface(sOffscreen);
                   sOffscreenAlpha = a;
                   if (a!=255)
                   {
                      sOffscreen = CreateRGB(ow, oh, true, true );
                   }
                   else
                   {
                      sOffscreen = CreateRGB(ow, oh, false, true );
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
      hx_failure( "nme_copy_pixels - wrong number of args.\n" );

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


DEFINE_PRIM(nme_blit_tile, 5);
DEFINE_PRIM_MULT(nme_copy_pixels);
DEFINE_PRIM_MULT(nme_create_blitter);
DEFINE_PRIM(nme_clone_texture_buffer, 1);
DEFINE_PRIM(nme_create_texture_buffer, 5);
DEFINE_PRIM(nme_get_pixel, 3);
DEFINE_PRIM(nme_get_pixel32, 3);
DEFINE_PRIM(nme_get_transparent, 1);
DEFINE_PRIM(nme_load_texture, 1);
DEFINE_PRIM(nme_load_texture_from_bytes, 5);
DEFINE_PRIM(nme_scroll_texture, 3);
DEFINE_PRIM(nme_set_blit_area, 5);
DEFINE_PRIM(nme_set_pixel_data, 5);
DEFINE_PRIM(nme_set_pixel, 4);
DEFINE_PRIM(nme_set_pixel32, 4);
DEFINE_PRIM(nme_set_pixel32_ex, 5);
DEFINE_PRIM(nme_tex_fill_rect,4);
DEFINE_PRIM(nme_texture_get_bytes, 2);
DEFINE_PRIM(nme_texture_height, 1);
DEFINE_PRIM(nme_texture_set_bytes, 3);
DEFINE_PRIM(nme_texture_width, 1);
DEFINE_PRIM(nme_tile_renderer_width, 1);
DEFINE_PRIM(nme_tile_renderer_height, 1);


int __force_texture_buffer = 0;
