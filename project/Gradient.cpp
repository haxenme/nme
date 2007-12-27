#include "Gradient.h"
#include <windows.h>
#include <gl/GL.h>
#include <vector>


struct RGBA
{
   unsigned char r,b,g,a;
};

typedef std::vector<RGBA> RGBAs;



struct GradPoint
{
   void FromValue(value &inVal)
   {
      int col = val_int(val_field(inVal,val_id("col")));
      mColour.r = (col>>16) & 0xff;
      mColour.g = (col>>8) & 0xff;
      mColour.b = (col) & 0xff;
      double a = val_number(val_field(inVal,val_id("alpha")));
      mColour.a = (a<0 ? 0 : a>=1.0 ? 255 : (int)(a*255) );

      mPos = val_int(val_field(inVal,val_id("ratio")));
   }

   RGBA   mColour;
   int    mPos;
};

typedef std::vector<GradPoint> GradPoints;

Gradient::Gradient(value inIsLinear,value inPoints,value inMatrix)
  : mMatrix(inMatrix)
{
   mLinear = val_bool(inIsLinear);
   mTextureID = 0;

   int n = val_array_size(inPoints);
   value *items = val_array_ptr(inPoints);

   GradPoints points(n);
   for(int i=0;i<n;i++)
   {
      points[i].FromValue(items[i]);
   }

   RGBAs col(256);
   if (n==0)
      memset(&col[0],0,256*sizeof(RGBA));
   else
   {
      int i;
      for(i=0;i<=points[0].mPos;i++)
         col[i] = points[0].mColour;
      for(int k=0;k<n-1;k++)
      {
         RGBA c0 = points[k].mColour;
         int p0 = points[k].mPos;
         int p1 = points[k+1].mPos;
         int diff = p1 - p0;
         if (diff>0)
         {
            int dr = points[k+1].mColour.r - c0.r;
            int dg = points[k+1].mColour.g - c0.g;
            int db = points[k+1].mColour.b - c0.b;
            int da = points[k+1].mColour.a - c0.a;
            for(i=p0;i<p1;i++)
            {
               col[i].r = c0.r + dr*(i-p0)/diff;
               col[i].g = c0.g + dg*(i-p0)/diff;
               col[i].b = c0.b + db*(i-p0)/diff;
               col[i].a = c0.a + da*(i-p0)/diff;
            }
         }
      }
      for(;i<256;i++)
         col[i] = points[n-1].mColour;

      // TODO: clamp vs repeat (& reflect ) ?
      glGenTextures(1, &mTextureID);
      glBindTexture(GL_TEXTURE_1D, mTextureID);
      glTexImage1D(GL_TEXTURE_1D, 0, 4,  256, 0,
         GL_RGBA, GL_UNSIGNED_BYTE, &col[0] );
      glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);   
      glTexEnvi(GL_TEXTURE_1D, GL_TEXTURE_ENV_MODE, GL_REPLACE);   
   }
}

Gradient::~Gradient()
{
   glDeleteTextures(1,&mTextureID);
}


void Gradient::BeginOpenGL()
{
   glBindTexture(GL_TEXTURE_1D, mTextureID);
   glEnable(GL_TEXTURE_1D);
}

void Gradient::OpenGLTexture(double inX,double inY)
{
   glTexCoord1d( mMatrix.m00*inX + mMatrix.m01*inY + mMatrix.mtx);
}

void Gradient::EndOpenGL()
{
   glDisable(GL_TEXTURE_1D);
}



