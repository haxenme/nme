#include "Gradient.h"
#ifdef WIN32
#include <windows.h>
#endif

#include "OGLState.h"

#include <SDL_opengl.h>

#include <vector>

#include "nme.h"

#ifndef GL_BGR
#define GL_BGR 0x80E0
#endif

#ifndef GL_BGRA
#define GL_BGRA 0x80E1
#endif


#ifndef GL_CLAMP_TO_EDGE
  #define GL_CLAMP_TO_EDGE 0x812F
#endif

#ifndef HXCPP
typedef value *array_ptr;
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
   void FromValue(const value &inVal)
   {
      int col = val_int(val_field(inVal,val_id("col")));
      mColour.SetRGB(col);
      double a = val_number(val_field(inVal,val_id("alpha")));
      mColour.a = (a<0 ? 0 : a>=1.0 ? 255 : (int)(a*255) );

      mPos = val_int(val_field(inVal,val_id("ratio")));
   }

   ARGB   mColour;
   int    mPos;
};

typedef std::vector<GradPoint> GradPoints;

Gradient *CreateGradient(value inVal)
{
   if (val_is_null(inVal))
      return 0;

   if (val_is_null(val_field(inVal,val_id("points"))))
      return 0;

   return new Gradient( val_field(inVal,val_id("flags")),
                        val_field(inVal,val_id("points")),
                        val_field(inVal,val_id("matrix")),
                        val_field(inVal,val_id("focal")) );
}


/*
  The flash matrix transforms the "nominal gradient box",
    (-819.2,-819.2) ... (819.2,819.2).  The gradient values (0,0)...(1,1)
    are then "drawn" in this box.  We want the inverse of this.
    First we invert the transform, then we invert the +-819.2 -> 0..1 mapping.

  It is slightly different for the radial case.
*/

static void FlashMatrix2NME(const Matrix &inFlash, Matrix &outNME,bool inRadial)
{
   outNME = inFlash.Inverse();
   double fact = inRadial ? (1.0/819.2) : (1.0/1638.4);
   outNME.m00 *= fact;
   outNME.m01 *= fact;
   outNME.m10 *= fact;
   outNME.m11 *= fact;
   outNME.mtx *= fact;
   outNME.mty *= fact;
   if (!inRadial)
   {
      outNME.mtx += 0.5;
      outNME.mty += 0.5;
   }
}

Gradient::Gradient(value inFlags,value inPoints,value inMatrix,value inFocal)
{
   mFlags = (unsigned int)val_int(inFlags);

   FlashMatrix2NME(inMatrix,mOrigMatrix,mFlags & gfRadial);

   IdentityTransform();

   mTextureID = 0;
   mResizeID = 0;

	val_check(inPoints,array);
	int n = val_array_size(inPoints);

   GradPoints points(n);

   mRepeat = (mFlags & gfRepeat) != 0;

   mFX = val_number(inFocal);

   mUsesAlpha = false;
   for(int i=0;i<n;i++)
   {
      points[i].FromValue(val_array_i(inPoints,i));
      if (points[i].mColour.a<255)
         mUsesAlpha = true;
   }


   mColours.resize(256);
   if (n==0)
      memset(&mColours[0],0,256*sizeof(ARGB));
   else
   {
      int i;
      int last = points[0].mPos;
      if (last>255) last = 255;

      for(i=0;i<=last;i++)
         mColours[i] = points[0].mColour;
      for(int k=0;k<n-1;k++)
      {
         ARGB c0 = points[k].mColour;
         int p0 = points[k].mPos;
         int p1 = points[k+1].mPos;
         int diff = p1 - p0;
         if (diff>0)
         {
            if (p0<0) p0 = 0;
            if (p1>256) p1 = 256;
            int dc0 = points[k+1].mColour.c0 - c0.c0;
            int dc1 = points[k+1].mColour.c1 - c0.c1;
            int dc2 = points[k+1].mColour.c2 - c0.c2;
            int da = points[k+1].mColour.a - c0.a;
            for(i=p0;i<p1;i++)
            {
               mColours[i].c0 = c0.c0 + dc0*(i-p0)/diff;
               mColours[i].c1 = c0.c1 + dc1*(i-p0)/diff;
               mColours[i].c2 = c0.c2 + dc2*(i-p0)/diff;
               mColours[i].a = c0.a + da*(i-p0)/diff;
            }
         }
      }
      for(;i<256;i++)
         mColours[i] = points[n-1].mColour;
   }
}

#ifdef NME_ANY_GL
bool Gradient::InitOpenGL()
{
   mResizeID = nme_resize_id;
   glGenTextures(1, &mTextureID);
   nmeSetTexture(mTextureID,true);
#ifdef NME_OPENGL
   int src = 4;
#else
   int src = GL_RGBA;
#endif
   glTexImage2D(GL_TEXTURE_2D, 0, src,  256, 1, 0,
      GL_RGBA, GL_UNSIGNED_BYTE, &mColours[0] );
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);   
   glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);   
   // TODO: reflect = double up?
   if (mFlags & gfRepeat)
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_REPEAT);
   else
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_REPEAT);

   return true;
}
#endif

bool Gradient::Is2D()
{
   return (mFlags & gfRadial) != 0;
}

bool Gradient::IsFocal0()
{
   return mFX == 0.0;
}




int Gradient::MapHQ(int inX,int inY)
{
   return (int)(mTransMatrix.m00*inX + mTransMatrix.m01*inY + mTransMatrix.mtx*65536.0);
}

int Gradient::DGDX()
{
   return (int)(mTransMatrix.m00*65536.0);
}

int Gradient::DGDY()
{
   return (int)(mTransMatrix.m01*65536.0);
}


Gradient::~Gradient()
{
#ifdef NME_ANY_GL
   if (mTextureID && mResizeID==nme_resize_id)
      glDeleteTextures(1,&mTextureID);
#endif
}


#ifdef NME_ANY_GL
void Gradient::BeginOpenGL()
{
   if ( (mTextureID>0 && mResizeID==nme_resize_id)  || InitOpenGL())
   {
      glColor4f(1,1,1,1);
      nmeSetTexture(mTextureID);
      nmeEnableTexture(true);
   }
}

void Gradient::OpenGLTexture(float *outTex,float inX,float inY)
{
   *outTex = (float)( mTransMatrix.m00*inX + mTransMatrix.m01*inY + mTransMatrix.mtx);
}

void Gradient::EndOpenGL()
{
   nmeEnableTexture(false);
}

#endif


