#ifndef TEXTURE_BUFFER_H
#define TEXTURE_BUFFER_H

#include <neko.h>
#include <SDL.h>

DECLARE_KIND( k_texture_buffer );

#define TEXTURE_BUFFER(v) ( (TextureBuffer *)(val_data(v)) )



class TextureBuffer
{
public:
   TextureBuffer(SDL_Surface *inSurface);
   value ToValue();
   static value Null();

   inline int Width() { return mPixelWidth; }
   inline int Height() { return mPixelHeight; }

   ~TextureBuffer();

   // SDL ...
   SDL_Surface *GetSourceSurface() { return mSurface; }
   SDL_Rect    *GetRect() { return &mRect; }

   // OpenGL ...
   void DrawOpenGL(float inAlpha=1.0);
   bool PrepareOpenGL();

   void TexCoord(float inX,float inY);

protected:
   
   SDL_Surface   *mSurface;
   unsigned int mTextureID;  

   int          mPixelWidth,mPixelHeight;
   float        mX1,mY1;

   SDL_Rect     mRect;
   SDL_Rect     mDirtyRect;

private: // hide
   TextureBuffer(const TextureBuffer &inRHS);
   void operator=(const TextureBuffer &inRHS);

};


#endif
