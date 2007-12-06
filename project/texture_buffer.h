#ifndef TEXTURE_BUFFER_H
#define TEXTURE_BUFFER_H

#include <neko.h>
#include <SDL.h>

class LoadedTexture
{
public:
   LoadedTexture(SDL_Surface *inSurface);
   LoadedTexture(int inWidth=0,int inHeight=0);
   void Bind();

   LoadedTexture *AddRef();
   void DecRef();

   void Alloc(int inWidth,int inHeight);
   void Clean();

   unsigned int mTextureID;
   int mWidth;
   int mHeight;
   int mRefCount;

private: // Call DecRef instead ...
   ~LoadedTexture();

private: // hide
   LoadedTexture(const LoadedTexture &inRHS);
   void operator=(const LoadedTexture &inRHS);
};


class TextureRect
{
public:
   TextureRect(SDL_Surface *inSurface);
   TextureRect();
   value ToValue();
   static value Null();

   ~TextureRect();

   LoadedTexture *mTexture;
   void Quad();
   void Quad(double inOX,double inOY);

   int   mPixelWidth,mPixelHeight;
   double mX0,mY0;
   double mX1,mY1;
};


#endif
