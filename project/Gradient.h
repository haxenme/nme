#ifndef GRADIENT_H
#define GRADIENT_H

#include <neko.h>
#include <vector>
#include "SDL.h"

#include "Matrix.h"

struct GradColour
{
   Uint8 r,g,b,a;
};

typedef std::vector<GradColour> GradColours;


class Gradient
{
public:
   Gradient(value inFlags,value inPoints,value inMatrix);

   ~Gradient();

   void BeginOpenGL();
   void OpenGLTexture(double inX,double inY);
   void EndOpenGL();

   int  MapHQ(int inX,int inY);
   int  DGDX();
   int  DGDY();

   Matrix mMatrix;
   unsigned int    mTextureID;
   unsigned int    mFlags;
   bool            mUsesAlpha;
   bool            mRepeat;
   GradColours     mColours;

private:
   Gradient(const Gradient &inRHS);
   void operator=(const Gradient &inRHS);
};

Gradient *CreateGradient(value inValue);


template<int SIZE_,int FLAGS_>
struct GradientSource1D
{
   enum { AlphaBlend = FLAGS_ & SPG_ALPHA_BLEND };
   // TODO: make this one...
   enum { AlreadyRoundedAlpha = 0 };


   GradientSource1D(Gradient *inGradient)
   {
      mMapper = inGradient->mMatrix;
      mColour = &inGradient->mColours[0];
      mDGDX = int(mMapper.m00  * (SIZE_<<8) + 0.5);
   }

   inline void SetPtr()
   {
      if (FLAGS_ & SPG_EDGE_REPEAT)
      {
          mPtr = mColour + ( (mG >> 8) & (SIZE_-1) );
      }
      else
      {
         if (mG <=0)
           mPtr = mColour;
         else if (mG >= (SIZE_<<8))
           mPtr = mColour + SIZE_-1;
         else
           mPtr = mColour + ( (mG >> 8) & (SIZE_-1) );
       }
   }

   inline void SetPos(int inX,int inY)
   {
      mG = int((mMapper.m00 * inX + mMapper.m01*inY + mMapper.mtx)*(SIZE_<<8));
      SetPtr();
   }

   inline void Inc()
   {
      mG += mDGDX;
      SetPtr();
   }

   inline void Advance(int inX)
   {
      mG += mDGDX * inX;
      SetPtr();
   }

   // TODO: interp ?
   Uint8 GetR() const { return mPtr->r; }
   Uint8 GetG() const { return mPtr->g; }
   Uint8 GetB() const { return mPtr->b; }
   Uint8 GetA() const { return mPtr->a; }

   int mG;
   int mDGDX;

   GradColour *mPtr;
   GradColour *mColour;
   Matrix     mMapper;
};


#endif
