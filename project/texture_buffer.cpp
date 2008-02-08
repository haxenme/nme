#include <string>
#include "texture_buffer.h"
#ifdef WIN32
#include <windows.h>
#endif
#include <GL/gl.h>
#include "nme.h"
#include "nsdl.h"
#include "ByteArray.h"


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


// --- TextureBuffer ----------------------------------------------------

TextureBuffer::TextureBuffer(SDL_Surface *inSurface)
{
   mSurface = inSurface;
   mTextureID = 0;
   mPixelWidth = inSurface->w;
   mPixelHeight = inSurface->h;
   SDL_SetAlpha(inSurface,SDL_SRCALPHA,255);
   mX1 = 0;
   mY1 = 0;

   mSW = mSH = 0;

   mRect.x = 0;
   mRect.y = 0;
   mRect.w = mPixelWidth;
   mRect.h = mPixelHeight;

   mRefCount = 1;

   mHardwareDirty = true;
   mDirtyX0 = 0;
   mDirtyY0 = 0;
   mDirtyX1 = mPixelWidth;
   mDirtyY1 = mPixelHeight;
}


TextureBuffer::~TextureBuffer()
{
   if (mTextureID>0)
      glDeleteTextures(1,&mTextureID);
   if (mSurface)
      SDL_FreeSurface(mSurface);
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
   if (mTextureID==0)
   {
      SDL_Surface *data = mSurface;
      SDL_Surface *cleanup = 0;
      int src_format = GL_BGRA;
      int store_format = 4;

      if (mSurface->format->BitsPerPixel==32 )
      {
         if (mSurface->format->Rmask == 0x0000ff)
            src_format = GL_RGBA;
         // Ok !
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
         glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, GL_BGRA, 
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

   return alloc_int(0);
}

value nme_texture_height( value texture_buffer )
{
   if ( val_is_kind( texture_buffer, k_texture_buffer ) )
   {
      TextureBuffer* t = TEXTURE_BUFFER(texture_buffer);
      return alloc_int(t->Height());
   }

   return alloc_int(0);
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
                            (f & HX_TRANSPARENT) ? 32 : 24,
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
   SDL_SetAlpha( surface, SDL_SRCALPHA, 255 );

   TextureBuffer *buffer = new TextureBuffer(surface);

   return buffer->ToValue();
}

ByteArray *TextureBuffer::GetPixels(int inX,int inY,int inW,int inH)
{
   int x1 = inX+inW;
   int y1 = inY+inH;
   if (inX<0 || inY<0 || x1>mPixelWidth || y1>mPixelHeight)
      return new ByteArray;

   bool alpha = mSurface->format->BitsPerPixel==32;
   bool bgr = mSurface->format->BitsPerPixel==24 &&
                  mSurface->format->Rmask != 0x0000ff;
   

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


value nme_load_texture(value inName)
{
   SDL_Surface *surface = nme_loadimage( inName );

   if (!surface)
      return val_null;

   TextureBuffer *buffer = new TextureBuffer(surface);

   return buffer->ToValue();

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

   int Width() { return mSrcRect.w; }
   int Height() { return mSrcRect.h; }

   ~TileRenderer()
   {
      mTexture->DecRef();
   }

   void Blit(int inX0,int inY0)
   {
      if (mOpenGL)
      {
         mTexture->BindOpenGL();
         glEnable(GL_BLEND);
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
         SDL_Rect    dest;
         dest.x = inX0;
         dest.y = inY0;
         dest.w = mSrcRect.w;
         dest.h = mSrcRect.h;
         SDL_BlitSurface(mTexture->GetSourceSurface(), &mSrcRect,
                         mDestSurface, &dest);
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

value nme_create_tile_renderer(value* arg, int nargs )
{
   enum { aTex, aSurface, aX0, aY0, aWidth, aHeight, aSIZE };
   if (nargs!=aSIZE)
      failure( "nme_create_tile_renderer - wrong number of args.\n" );

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
      t->Blit( val_int(x), val_int(y) );
   }

   return alloc_int(0);
}


// --- TextureReference -----------------------------------------

TextureReference *TextureReference::Create(value inVal)
{
   if (val_is_null(inVal))
      return 0;
   TextureBuffer *tex=TEXTURE_BUFFER(val_field(inVal,val_id("texture_buffer")));
   if (!tex)
      return 0;

   int flags = val_int((val_field(inVal,val_id("flags"))));
   Matrix matrix(val_field(inVal,val_id("matrix")));

   return new TextureReference(tex,matrix,flags);
}

DEFINE_PRIM_MULT(nme_create_tile_renderer);
DEFINE_PRIM(nme_blit_tile, 3);
    

DEFINE_PRIM(nme_create_texture_buffer, 5);
DEFINE_PRIM(nme_load_texture, 1);
DEFINE_PRIM(nme_texture_width, 1);
DEFINE_PRIM(nme_texture_height, 1);
DEFINE_PRIM(nme_tile_renderer_width, 1);
DEFINE_PRIM(nme_tile_renderer_height, 1);
DEFINE_PRIM(nme_texture_get_bytes, 2);
DEFINE_PRIM(nme_texture_set_bytes, 3);



