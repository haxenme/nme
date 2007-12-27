#ifndef GRADIENT_H
#define GRADIENT_H

#include <neko.h>

#include "Matrix.h"

class Gradient
{
public:
   Gradient(value inIsLinear,value inPoints,value inMatrix);

   ~Gradient();

   void BeginOpenGL();
   void OpenGLTexture(double inX,double inY);
   void EndOpenGL();

   Matrix mMatrix;
   unsigned int    mTextureID;
   bool   mLinear;

private:
   Gradient(const Gradient &inRHS);
   void operator=(const Gradient &inRHS);
};


#endif
