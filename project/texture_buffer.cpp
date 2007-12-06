#include "texture_buffer.h"
#ifdef __WIN32__
#include <windows.h>
#endif
#include <gl/GL.H>


DECLARE_KIND( k_texture_rect );
DEFINE_KIND( k_texture_rect );

#define TEXTURE_RECT(v) ( (TextureRect *)(val_data(v)) )


int UpToPower2(int inX)
{
   int result = 1;
   while(result<inX) result<<=1;
   return result;
}

#ifndef GL_BGRA
#define GL_BGRA 0x80E1
#endif

LoadedTexture::LoadedTexture(SDL_Surface *inSurface)
{
   SDL_Surface *data = inSurface;
   SDL_Surface *cleanup = 0;

   if (inSurface->format->BitsPerPixel!=32 ||
       inSurface->format->BytesPerPixel!=4 )
   {
      //printf("blit to rgb surface (%d/%d)\n",
         //inSurface->format->BitsPerPixel,
         //inSurface->format->BytesPerPixel);
      data = SDL_CreateRGBSurface(SDL_SWSURFACE|SDL_SRCALPHA,
         inSurface->w, inSurface->h, 32, 
         0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
      SDL_BlitSurface(inSurface, 0, data, 0);
      cleanup = data;
   }

   glGenTextures(1, &mTextureID);
   glBindTexture(GL_TEXTURE_2D, mTextureID);

   int w = UpToPower2(inSurface->w);
   int h = UpToPower2(inSurface->h);
   //printf("LoadedTexture %dx%d\n",w,h);

   if ( inSurface->w != w || inSurface->h != h )
   {
      glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, GL_BGRA, 
         GL_UNSIGNED_BYTE, 0 );
      glTexSubImage2D(GL_TEXTURE_2D, 0, 0,0, inSurface->w, inSurface->h,
         GL_BGRA, GL_UNSIGNED_BYTE, data->pixels );
   }
   else
   {
      glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, GL_BGRA, 
         GL_UNSIGNED_BYTE, data->pixels );
   }

   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);   
   glTexEnvi(GL_TEXTURE_2D, GL_TEXTURE_ENV_MODE, GL_REPLACE);   

   if (cleanup)
      SDL_FreeSurface(cleanup);

   mWidth = w;
   mHeight = h;
   mRefCount = 1;
}

LoadedTexture::~LoadedTexture()
{
   //printf("~LoadedTexture %d\n",mTextureID);
   if (mTextureID>0)
      glDeleteTextures(1,&mTextureID);
}

void LoadedTexture::DecRef()
{
   mRefCount--;
   if (mRefCount==0)
      delete this;
}

void LoadedTexture::Bind()
{
   glEnable(GL_TEXTURE_2D);
   glBindTexture(GL_TEXTURE_2D, mTextureID);
   glColor3f(1.0f, 1.0f, 1.0f);
}


// --- TextureRect ----------------------------------------------------

TextureRect::TextureRect(SDL_Surface *inSurface)
{
   mTexture = new LoadedTexture(inSurface);
   mPixelWidth = inSurface->w;
   mPixelHeight = inSurface->h;
   mX0 = mY0 = 0;
   mX1 = mTexture->mWidth>0 ? (float)mPixelWidth/mTexture->mWidth : 0.0;
   mY1 = mTexture->mHeight>0 ? (float)mPixelHeight/mTexture->mHeight : 0.0;
   //printf("TextureRect %f,%f  %f,%f\n", mX0,mY0,mX1,mY1);
}

void TextureRect::Quad()
{
   if (!mTexture)
      return;
   mTexture->Bind();

   glColor4f(1,1,1,1);
   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   glBegin(GL_QUADS);
   glTexCoord2d(mX0,mY0);
   glVertex2i(0,0);
   glTexCoord2d(mX0,mY1);
   glVertex2i(0,mPixelHeight);
   glTexCoord2d(mX1,mY1);
   glVertex2i(mPixelWidth,mPixelHeight);
   glTexCoord2d(mX1,mY0);
   glVertex2i(mPixelWidth,0);
   glEnd();

   glDisable(GL_TEXTURE_2D);
   glDisable(GL_BLEND);
}

TextureRect::~TextureRect()
{
   if (mTexture)
      mTexture->DecRef();
}

void delete_texture_rect( value texture_rect )
{
   if ( val_is_kind( texture_rect, k_texture_rect ) )
   {
      val_gc( texture_rect, NULL );

      TextureRect* t = TEXTURE_RECT(texture_rect);
      delete t;
   }
}

value TextureRect::ToValue()
{
   value v = alloc_abstract( k_texture_rect, this );
   val_gc( v, delete_texture_rect );
   return v;
}


value nme_texture_quad(value texture)
{
   val_check_kind( texture, k_texture_rect );
   TextureRect* t = TEXTURE_RECT(texture);
   t->Quad();

   return alloc_int( 0 );
}

DEFINE_PRIM(nme_texture_quad, 1);

