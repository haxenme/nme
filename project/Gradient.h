#ifndef GRADIENT_H
#define GRADIENT_H

#include <neko.h>
#include <vector>
#include "SDL.h"
#include <math.h>

#include "Matrix.h"

struct GradColour
{
   Uint8 r,g,b,a;
};

typedef std::vector<GradColour> GradColours;


class Gradient
{
public:
   Gradient(value inFlags,value inPoints,value inMatrix, value mFocalX);

   ~Gradient();

   bool Is2D();
   bool IsFocal0();

   void BeginOpenGL();
   void OpenGLTexture(double inX,double inY);
   void EndOpenGL();

   int  MapHQ(int inX,int inY);
   int  DGDX();
   int  DGDY();

   void Transform(const Matrix &inMtx)
      { inMtx.ContravariantTrans(mOrigMatrix,mTransMatrix); }
   void IdentityTransform()
      { mTransMatrix = mOrigMatrix; }

   bool            mIsRadial;
   Matrix          mOrigMatrix;
   Matrix          mTransMatrix;

   unsigned int    mTextureID;
   unsigned int    mFlags;
   bool            mUsesAlpha;
   bool            mRepeat;
   GradColours     mColours;

   double          mFX;

protected:
   bool InitOpenGL();

private:
   Gradient(const Gradient &inRHS);
   void operator=(const Gradient &inRHS);
};

Gradient *CreateGradient(value inValue);



#endif
