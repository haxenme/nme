#include "RenderPolygon.h"
#include "../Gradient.h"
#include <math.h>
#include <algorithm>
#include <map>

template<int SIZE_,int FLAGS_>
struct GradientSource1D
{
   enum { AlphaBlend = FLAGS_ & NME_ALPHA_BLEND };
   // TODO: make this one...
   enum { AlreadyRoundedAlpha = 0 };


   GradientSource1D(Gradient *inGradient)
   {
      mMapper = inGradient->mTransMatrix;
      mColour = &inGradient->mColours[0];
      mDGDX = int(mMapper.m00  * (SIZE_<<8) + 0.5);
   }

   inline void SetPtr()
   {
      if (FLAGS_ & NME_EDGE_REPEAT)
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
           mPtr = mColour + ( (mG >> 8)  );
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

template<int SIZE_,int FLAGS_>
struct GradientSource2D
{
   enum { AlphaBlend = FLAGS_ & NME_ALPHA_BLEND };
   // TODO: make this one...
   enum { AlreadyRoundedAlpha = 0 };


   GradientSource2D(Gradient *inGradient)
   {
      mMapper = inGradient->mTransMatrix;
      mColour = &inGradient->mColours[0];
      mDGXDX = mMapper.m00;
      mDGYDX = mMapper.m10;

      // CX,CY are assumed to be zero, and the radius 1.0
      // - since these can be compensated for  with the matrix.
      mFX = inGradient->mFX;
      if (mFX<-0.99) mFX = -0.99;
      else if (mFX>0.99) mFX = 0.99;

      // mFY = 0;   mFY can be set to zero, since rotating the matrix
      //  can also compensate for this.

      mA = (mFX*mFX - 1.0);
      mOn2A = 1.0/(2.0*mA);
      mA *= 4.0;
   }

   void SetPtr()
   {
      //
      //  This whole calculation is compicated by the "focus"
      //  To find the gradient position ratio, which will be 1 at the
      //   edge of a unit circle, and 0 at the focus, we must cast a ray
      //   from the focal point though the test point to the unit circle.
      // 
      // 
      //            i
      //           o*oooo
      //        ooo  \   ooo = unit circle
      //      oo      \
      //    oo         \
      //                +  test point, (mGX,mGY) fixed 16
      //                 \
      //                  \
      //                   * Focus (fx,fy) fixed,16
      //                  /
      //                 /
      //                /
      //    -----------+-------------------------
      //        Centre (cx,cy), fixed-16 coords
      //
      //   We are after "what % of the way to the unit circle is the test point"
      //  
      //
      //  The line joining focus to test point is in terms of "alpha" = a.
      //    P(a) = F + a * (mG-F),
      //  This intersects circle at || P(a) - Centre || = unit
      //  
      //  Since everything is in converted to normalised doubles, unit = 1
      //
      //  So,
      //    [ Fx + a*(mGx-Fx) -Cx ] ^2 + [ Fy + a*(mGy-Fy) -Cy ] ^2 = 1^2
      //
      //    dx = mGx-Fx
      //    dy = mGy
      //    fx = Fx-Cx
      //    fy = Fy-Cy
      //
      //   a^2 (dx^2 + dy^2) + 2a(dx*fx+dy*fy) + (fx*fx - 1) =0
      //
      //  Solve using quadratic equation.
      //   A =dx^2 + dy^2
      //   B = 2*(dx*fx + dy*fy)
      //   C = fx*fx - 1
      //  However, we are after 1/a, not a - so swap values of A and C
      //  
      // Implementations:
      //  Convert everything to doubles, since terms as written will overflow.
      //  Work in terms of dx,dy - ie, subtract off F as early as possible
      //    - this means unit is 1.0
      //  A (C as it is written above) is constant - also include a factor
      //    of 4.0 for the quadratic equation


      double alpha;
      double C = mGX*mGX + mGY*mGY;

      if (FLAGS_ & NME_GRADIENT_FOCAL0)
      {
         alpha = sqrt(C);
      }
      else
      {
         double B = 2.0*(mGX*mFX);

         double det = B*B - mA*C;
         if (det<=0)
            alpha = -B * mOn2A;
            // TODO: what exactly is this condition ?
         else if (1)
            alpha = (-B-sqrt(det))*mOn2A;
         else
            alpha = (-B+sqrt(det))*mOn2A;
      }

      if ( (FLAGS_ & NME_EDGE_REPEAT) )
      {
          mPtr = mColour + ( ((int)(alpha*(SIZE_-1))) & (SIZE_-1) );
      }
      else
      {
         if (alpha <=0)
           mPtr = mColour;
         else if (alpha>=1.0)
           mPtr = mColour + SIZE_-1;
         else
           mPtr = mColour +  ( ((int)(alpha*(SIZE_-1))) );
       }
   }

   inline void SetPos(int inX,int inY)
   {
      if (FLAGS_ & NME_GRADIENT_FOCAL0)
         mGX = mMapper.m00 * inX + mMapper.m01*inY + mMapper.mtx;
      else
         mGX = mMapper.m00 * inX + mMapper.m01*inY + mMapper.mtx - mFX;

      mGY = mMapper.m10 * inX + mMapper.m11*inY + mMapper.mty;
      SetPtr();
   }

   inline void Inc()
   {
      mGX += mDGXDX;
      mGY += mDGYDX;
      SetPtr();
   }

   inline void Advance(double inX)
   {
      mGX += mDGXDX * inX;
      mGY += mDGYDX * inX;
      SetPtr();
   }

   // TODO: interp ?
   Uint8 GetR() const { return mPtr->r; }
   Uint8 GetG() const { return mPtr->g; }
   Uint8 GetB() const { return mPtr->b; }
   Uint8 GetA() const { return mPtr->a; }

   double mFX;

   double mA;
   double mOn2A;

   double mGX;
   double mGY;
   double mDGXDX;
   double mDGYDX;

   GradColour *mPtr;
   GradColour *mColour;
   Matrix     mMapper;
};






// --- Create Renderers --------------------------------------

template<int FLAGS_,int SIZE_>
PolygonRenderer *TCreateGradientRenderer( const RenderArgs &inArgs, Gradient *inGradient)
{
   if (inGradient->Is2D())
   {
      if (inGradient->IsFocal0())
      {
         typedef GradientSource2D<SIZE_,FLAGS_ + NME_GRADIENT_FOCAL0> Source;

         return new SourcePolygonRenderer<Source>(inArgs, Source(inGradient) );
      }
      else
      {
         typedef GradientSource2D<SIZE_,FLAGS_> Source;

         return new SourcePolygonRenderer<Source>(inArgs, Source(inGradient) );
      }

   }
   else
   {
      typedef GradientSource1D<SIZE_,FLAGS_> Source;

      return new SourcePolygonRenderer<Source>( inArgs, Source(inGradient) );
   }
}



PolygonRenderer *PolygonRenderer::CreateGradientRenderer(
                        const RenderArgs &inArgs,
                        class Gradient *inGradient )
{
#define ARGS inArgs,inGradient

      if (inGradient->mColours.size()==256)
      {
         if (inGradient->mUsesAlpha)
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer<NME_ALPHA_BLEND+NME_EDGE_REPEAT,256>(ARGS);
            else
               return TCreateGradientRenderer<NME_ALPHA_BLEND,256>(ARGS);
         }
         else
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer<NME_EDGE_REPEAT,256>(ARGS);
            else
               return TCreateGradientRenderer<0,256>(ARGS);
         }
      }
      else
      {
         if (inGradient->mUsesAlpha)
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer<NME_ALPHA_BLEND+NME_EDGE_REPEAT,512>(ARGS);
            else
               return TCreateGradientRenderer<NME_ALPHA_BLEND,512>(ARGS);
         }
         else
         {
            if (inGradient->mRepeat)
               return TCreateGradientRenderer<NME_EDGE_REPEAT,512>(ARGS);
            else
               return TCreateGradientRenderer<0,512>(ARGS);
         }
      }

#undef ARGS

   // should not get here ...
   return 0;
}


