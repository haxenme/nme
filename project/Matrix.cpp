#include <windows.h>
#include <gl/GL.h>
#include "Matrix.h"
#include <neko.h>

void Matrix::Transform(float inX,float inY,short &outX,short &outY) const
{
   outX = (short)( inX*m00 + inY*m01 + mtx + 0.5);
   outY = (short)( inX*m10 + inY*m11 + mty + 0.5);
}


void Matrix::GLMult() const
{
   double matrix[] =
   {
      m00, m10, 0, 0,
      m01, m11, 0, 0,
      0,   0,   1, 0,
      mtx, mty, 0, 1
   };
   glMultMatrixd(matrix);
}

inline static void Set(double &outVal, value inValue)
{
   //if ( val_is_float(inValue) )
      outVal = val_number(inValue);
}

Matrix::Matrix(value inMatrix)
{
   m01 = m10 = mtx = mty = 0.0;
   m00 = m11 = 1.0;

   static int a_id = val_id("a");
   static int b_id = val_id("b");
   static int c_id = val_id("c");
   static int d_id = val_id("d");
   static int tx_id = val_id("tx");
   static int ty_id = val_id("ty");

   if (val_is_object( inMatrix ) )
   {
      Set(m00,val_field(inMatrix,a_id));
      Set(m01,val_field(inMatrix,b_id));
      Set(m10,val_field(inMatrix,c_id));
      Set(m11,val_field(inMatrix,d_id));
      Set(mtx,val_field(inMatrix,tx_id));
      Set(mty,val_field(inMatrix,ty_id));
   }
}

