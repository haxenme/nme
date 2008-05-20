#ifdef WIN32
#include <windows.h>
#endif
#include <GL/gl.h>
#include "Matrix.h"
#include <neko.h>

void Matrix::Transform(float inX,float inY,short &outX,short &outY) const
{
   outX = (short)( inX*m00 + inY*m01 + mtx + 0.5);
   outY = (short)( inX*m10 + inY*m11 + mty + 0.5);
}

void Matrix::TransformHQ(float inX,float inY,int &outX,int &outY) const
{
   outX = (int)( (inX*m00 + inY*m01 + mtx) * 65536.0 + 0.5) + 0x8000;
   outY = (int)( (inX*m10 + inY*m11 + mty) * 65536.0 + 0.5) + 0x8000;
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
      // Note: change in meaning of "c" and "b"
      Set(m01,val_field(inMatrix,c_id));
      Set(m10,val_field(inMatrix,b_id));

      Set(m11,val_field(inMatrix,d_id));
      Set(mtx,val_field(inMatrix,tx_id));
      Set(mty,val_field(inMatrix,ty_id));
   }
}


void Matrix::ContravariantTrans(const Matrix &inMtx, Matrix &outTrans) const
{
   double det = m00*m11 - m01*m10;
   if (det==0)
   {
      outTrans = inMtx;
      return;
   }
   det = 1.0/det;
   double a = m11*det;
   double b = -m01*det;
   double c = -m10*det;
   double d = m00*det;
   double tx = -a*mtx - b*mty;
   double ty = -c*mtx - d*mty;
   outTrans.m00 = inMtx.m00*a + inMtx.m01*c;
   outTrans.m01 = inMtx.m00*b + inMtx.m01*d;
   outTrans.mtx = inMtx.m00*tx + inMtx.m01*ty+inMtx.mtx;

   outTrans.m10 = inMtx.m10*a + inMtx.m11*c;
   outTrans.m11 = inMtx.m10*b + inMtx.m11*d;
   outTrans.mty = inMtx.m10*tx + inMtx.m11*ty+inMtx.mty;
}

Matrix Matrix::Mult(const Matrix &inLHS) const
{
   Matrix t;
   t.m00 = inLHS.m00 * m00 + inLHS.m01*m10;
   t.m01 = inLHS.m00 * m01 + inLHS.m01*m11;
   t.mtx = inLHS.m00 * mtx + inLHS.m01*mty + inLHS.mtx;

   t.m10 = inLHS.m10 * m00 + inLHS.m11*m10;
   t.m11 = inLHS.m10 * m01 + inLHS.m11*m11;
   t.mty = inLHS.m10 * mtx + inLHS.m11*mty + inLHS.mty;

   return t;
}

Matrix Matrix::Invert2x2() const
{
   double det = m00*m11 - m01*m10;
   if (det==0)
      return Matrix();

   det = 1.0/det;
   Matrix result(m11*det, m00*det);
   result.m01 = -m01*det;
   result.m10 = -m10*det;
   return result;
}


Matrix Matrix::Inverse() const
{
   double det = m00*m11 - m01*m10;
   if (det==0)
      return Matrix();

   det = 1.0/det;
   Matrix result(m11*det, m00*det);
   result.m01 = -m01*det;
   result.m10 = -m10*det;

   result.mtx = - result.m00*mtx - result.m01*mty;
   result.mty = - result.m10*mtx - result.m11*mty;
   return result;
}

void Matrix::MatchTransform(double inX,double inY,
                            double inTargetX,double inTargetY)
{
   mtx = inTargetX-(m00*inX + m01*inY);
   mty = inTargetY-(m10*inX + m11*inY);
}






