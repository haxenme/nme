#include "config.h"
#ifdef WIN32
#include <windows.h>
#endif
#include <SDL_opengl.h>
#include "Matrix.h"
#include <stdio.h>

void Matrix::Transform(float inX,float inY,short &outX,short &outY) const
{
   outX = (short)( inX*m00 + inY*m01 + mtx + 0.5);
   outY = (short)( inX*m10 + inY*m11 + mty + 0.5);
}

void Matrix::TransformHQ(float inX,float inY,int &outX,int &outY) const
{
   outX = (int)( (inX*m00 + inY*m01 + mtx ) * 65536.0 + 0.5);
   outY = (int)( (inX*m10 + inY*m11 + mty ) * 65536.0 + 0.5);
}

void Matrix::TransformHQCorner(float inX,float inY,int &outX,int &outY) const
{
   outX = (int)( (inX*m00 + inY*m01 + mtx) * 65536.0 + 0.5);
   outY = (int)( (inX*m10 + inY*m11 + mty) * 65536.0 + 0.5);
}



#ifdef NME_ANY_GL
void Matrix::GLMult() const
{
   float matrix[] =
   {
      m00, m10, 0, 0,
      m01, m11, 0, 0,
      0,   0,   1, 0,
      mtx, mty, 0, 1
   };
   glMultMatrixf(matrix);
}
#endif

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

static void Dump(const char *inName,const Matrix &inMtx)
{
   printf("%s x: %f %f %f\n", inName, inMtx.m00, inMtx.m01,  inMtx.mtx);
   printf("%s y: %f %f %f\n", inName, inMtx.m10, inMtx.m11,  inMtx.mty);
}

void Matrix::ContravariantTrans(const Matrix &inMtx, Matrix &outTrans) const
{
   //Dump("This", *this);
   //Dump("In  ", inMtx);
   //outTrans = inMtx.Mult(Inverse());
   outTrans = inMtx.Mult(Inverse());
   //outTrans = inMtx.Mult(*this);
   //Dump("Out ", outTrans);
   //printf("===\n");
}

Matrix Matrix::Mult(const Matrix &inRHS) const
{
   Matrix t;
   t.m00 = m00*inRHS.m00 + m01*inRHS.m10;
   t.m01 = m00*inRHS.m01 + m01*inRHS.m11;
   t.mtx = m00*inRHS.mtx + m01*inRHS.mty + mtx;

   t.m10 = m10*inRHS.m00 + m11*inRHS.m10;
   t.m11 = m10*inRHS.m01 + m11*inRHS.m11;
   t.mty = m10*inRHS.mtx + m11*inRHS.mty + mty;

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






