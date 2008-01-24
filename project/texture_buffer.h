#ifndef TEXTURE_BUFFER_H
#define TEXTURE_BUFFER_H

#include <neko.h>
#include <SDL.h>
#include "Matrix.h"

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

   static TextureBuffer *Create(value inValue);


   // SDL ...
   SDL_Surface *GetSourceSurface() { return mSurface; }
   SDL_Rect    *GetRect() { return &mRect; }

   // OpenGL ...
   void DrawOpenGL(float inAlpha=1.0);
   bool PrepareOpenGL();
   void BindOpenGL();
   void UnBindOpenGL();
   void ScaleTexture(int inX,int inY,float &outX,float &outY);

   void SetExtentDirty(int inX0,int inY0,int inX1,int inY1);
   void UpdateHardware();

   void TexCoord(float inX,float inY);
   TextureBuffer *IncRef();
   void DecRef();

protected:
   // Call "DecRef" instead;
   ~TextureBuffer();
   
   SDL_Surface   *mSurface;
   unsigned int mTextureID;  

   int          mPixelWidth,mPixelHeight;
   float        mX1,mY1;
   float        mSW,mSH;

   SDL_Rect     mRect;
   bool         mHardwareDirty;
   int          mDirtyX0;
   int          mDirtyX1;
   int          mDirtyY0;
   int          mDirtyY1;

   int          mRefCount;

private: // hide
   TextureBuffer(const TextureBuffer &inRHS);
   void operator=(const TextureBuffer &inRHS);

};

struct TextureReference
{
    TextureReference(TextureBuffer *inTexture,Matrix &inMtx,int inFlags)
      : mTexture(inTexture->IncRef()), mMatrix(inMtx), mFlags(inFlags) { }

    ~TextureReference() { mTexture->DecRef(); }

    static TextureReference *Create(value inValue);

    TextureBuffer *mTexture;
    Matrix        mMatrix;
    int           mFlags;
};


#endif
