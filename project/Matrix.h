#ifndef MATRIX_H
#define MATRIX_H

#include <neko.h>

class Matrix
{
public:
   Matrix(double inSX=1,double inSY=1, double inTX=0, double inTY=0) :
       m00(inSX), m01(0), mtx(inTX),
       m10(0), m11(inSY), mty(inTY)
   {
   }

   Matrix(value inMatrix);

   bool IsIdentity() const
      { return m00==1.0 && m01==0.0 && mtx==0.0 &&
               m10==0.0 && m11==1.0 && mty==0.0; }

   inline bool operator==(const Matrix &inRHS) const
      { return !memcmp(this,&inRHS,sizeof(this)); }
   inline bool operator!=(const Matrix &inRHS) const
      { return memcmp(this,&inRHS,sizeof(this)); }

   void Transform(float inX,float inY,short &outX,short &outY) const;
   void TransformHQ(float inX,float inY,int &outX,int &outY) const;

   void GLMult() const;

   double m00, m01, mtx;
   double m10, m11, mty;
};


#endif
