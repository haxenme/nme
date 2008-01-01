#include "Gradient.h"
#include <windows.h>
#include <gl/GL.h>
#include <vector>

#ifndef GL_CLAMP_TO_EDGE
  #define GL_CLAMP_TO_EDGE 0x812F
#endif


// These should match Graphics.hx
enum GradFlags
{
   gfRadial  = 0x0001,
   gfRepeat  = 0x0002,
   gfReflect = 0x0004,
};



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

   GradColour   mColour;
   int    mPos;
};

typedef std::vector<GradPoint> GradPoints;

Gradient *CreateGradient(value inVal)
{
   if (val_is_null(inVal))
      return 0;

   return new Gradient( val_field(inVal,val_id("flags")),
                        val_field(inVal,val_id("points")),
                        val_field(inVal,val_id("matrix")) );
}

Gradient::Gradient(value inFlags,value inHxPoints,value inMatrix)
  : mMatrix(inMatrix)
{
   mFlags = (unsigned int)val_int(inFlags);
   mTextureID = 0;

   value inPoints = val_field(inHxPoints,val_id("__a"));
   int n =  val_int( val_field(inHxPoints,val_id("length")));

   value *items = val_array_ptr(inPoints);

   GradPoints points(n);

   mRepeat = (mFlags & gfRepeat) != 0;

   mUsesAlpha = false;
   for(int i=0;i<n;i++)
   {
      points[i].FromValue(items[i]);
      if (points[i].mColour.a<255)
         mUsesAlpha = true;
   }


   mColours.resize(256);
   if (n==0)
      memset(&mColours[0],0,256*sizeof(GradColour));
   else
   {
      int i;
      for(i=0;i<=points[0].mPos;i++)
         mColours[i] = points[0].mColour;
      for(int k=0;k<n-1;k++)
      {
         GradColour c0 = points[k].mColour;
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
               mColours[i].r = c0.r + dr*(i-p0)/diff;
               mColours[i].g = c0.g + dg*(i-p0)/diff;
               mColours[i].b = c0.b + db*(i-p0)/diff;
               mColours[i].a = c0.a + da*(i-p0)/diff;
            }
         }
      }
      for(;i<256;i++)
         mColours[i] = points[n-1].mColour;

      glGenTextures(1, &mTextureID);
      glBindTexture(GL_TEXTURE_1D, mTextureID);
      glTexImage1D(GL_TEXTURE_1D, 0, 4,  256, 0,
         GL_RGBA, GL_UNSIGNED_BYTE, &mColours[0] );
      glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);   
      glTexEnvi(GL_TEXTURE_1D, GL_TEXTURE_ENV_MODE, GL_REPLACE);   
      // TODO: reflect = double up?
      if (mFlags & gfRepeat)
         glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S,GL_REPEAT);
      else
         glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
   }
}

int Gradient::MapHQ(int inX,int inY)
{
   return (int)(mMatrix.m00*inX + mMatrix.m01*inY + mMatrix.mtx*65536.0);
}

int Gradient::DGDX()
{
   return (int)(mMatrix.m00*65536.0);
}

int Gradient::DGDY()
{
   return (int)(mMatrix.m01*65536.0);
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



