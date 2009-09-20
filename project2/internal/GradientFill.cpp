#include <Graphics.h>
#include "Render.h"



class GradientFillerBase : public Filler
{
public:
	GradientFillerBase(GraphicsGradientFill *inFill)
	{
		mGrad = inFill;
		int n = inFill->spreadMethod==smReflect ? 512 : 256;
      mColours = new ARGB[n];
      mMask =  n-1;
		mIsSwapped = false;
		mIsInit = false;
		mPad =  inFill->spreadMethod==smPad;
		mRadial = false;
	}
	~GradientFillerBase()
	{
		delete [] mColours;
	}


   void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
       const RenderTarget &inTarget,const RenderState &inState)
	{
		// Get combined mapping matrix...
		Matrix mapper = *inState.mTransform.mMatrix;
		mapper = mapper.Translate(inTX,inTY).Mult(mGrad->matrix);
		/*
        The flash matrix transforms the "nominal gradient box",
          (-819.2,-819.2) ... (819.2,819.2).  The gradient values (0,0)...(1,1)
          are then "drawn" in this box.  We want the inverse of this.
          First we invert the transform, then we invert the +-819.2 -> 0..1 mapping.
      
        It is slightly different for the radial case.
      */
		mMapper = mapper.Inverse();
		mMapper *= mRadial ? (1.0/819.2) : (1.0/1638.4);
		if (!mRadial)
		   mMapper.Translate(0.5,0.5);

		if (mPad)
		   mDGXDX = (int)(mMapper.m00 * (1<<16)+ 0.5);
		else
		   mDGXDX = (int)(mMapper.m00 * (1<<23)+ 0.5);

		bool want_swapped =  inTarget.format & pfSwapRB;
		if (!mIsInit)
			InitArray(want_swapped);
		else if (want_swapped!=mIsSwapped)
			SwapArray();

		DoRender( mAlphaMask, inTarget, inState, inTX,inTY );
	}

	void SwapArray()
	{
		int n = mMask+1;
		for(int i=0;i<n;i++)
		{
			ARGB &col = mColours[i];
			std::swap( col.c0, col.c1 );
		}
		mIsSwapped = !mIsSwapped;
	}
	void InitArray(bool inSwap)
	{
		mIsSwapped = inSwap;
      Stops &stops = mGrad->mStops;
		int n = stops.size();
		if (n==0)
			memset(mGrad,0,sizeof(ARGB)*(mMask+1));
		else
		{
			int i;
			int last = stops[0].mPos;
			if (last>255) last = 255;

			for(i=0;i<=last;i++)
				mColours[i] = stops[0].mARGB;
			for(int k=0;k<n-1;k++)
			{
				ARGB c0 = stops[k].mARGB;
				int p0 = stops[k].mPos;
				int p1 = stops[k+1].mPos;
				int diff = p1 - p0;
				if (diff>0)
				{
					if (p0<0) p0 = 0;
					if (p1>256) p1 = 256;
					int dc0 = stops[k+1].mARGB.c0 - c0.c0;
					int dc1 = stops[k+1].mARGB.c1 - c0.c1;
					int dc2 = stops[k+1].mARGB.c2 - c0.c2;
					int da = stops[k+1].mARGB.a - c0.a;
					for(i=p0;i<p1;i++)
					{
						mColours[i].c1 = c0.c1 + dc1*(i-p0)/diff;
						if (inSwap)
						{
							mColours[i].c2 = c0.c0 + dc0*(i-p0)/diff;
							mColours[i].c0 = c0.c2 + dc2*(i-p0)/diff;
						}
						else
						{
							mColours[i].c0 = c0.c0 + dc0*(i-p0)/diff;
							mColours[i].c2 = c0.c2 + dc2*(i-p0)/diff;
						}
						mColours[i].a = c0.a + da*(i-p0)/diff;
					}
				}
			}
			for(;i<256;i++)
				mColours[i] = stops[n-1].mARGB;

			if (mGrad->spreadMethod==smReflect)
			{
			   for(;i<512;i++)
				   mColours[i] = mColours[511-i];
			}
		}
	}

	virtual void DoRender(const AlphaMask &inMask, const RenderTarget &inTarget, const RenderState &inState, int inTX,int inTY) = 0;

	int  mPos;
	int  mDGXDX;
	int  mDGYDX;
	bool mIsSwapped;
	bool mIsInit;
	int  mMask;
	bool mPad;
	bool mRadial;
	Matrix mMapper;
	ARGB *mColours;
	GraphicsGradientFill *mGrad;
};


template<bool PAD>
class GradientLinearFiller : public GradientFillerBase
{
public:
	GradientLinearFiller(GraphicsGradientFill *inFill) : GradientFillerBase(inFill)
	{
   }

   inline void SetPos(int inSX,int inSY)
	{
		if (PAD)
		   mPos = (int)( (mMapper.m00*inSX + mMapper.m01*inSY + mMapper.mtx) * (1<<16) + 0.5);
		else
		   mPos = (int)( (mMapper.m00*inSX + mMapper.m01*inSY + mMapper.mtx) * (1<<23) + 0.5);
	}
   ARGB GetInc( )
	{
		if (PAD)
		{
		   int p = mPos>>8;
		   mPos += mDGXDX;
			if (p<0)
		      return mColours[0];
			if (p>255)
		      return mColours[255];
		   return mColours[p];
		}
		else
		{
		   int p = mPos;
		   mPos += mDGXDX;
		   return mColours[ (p>>15) & mMask];
		}
	}


	void DoRender(const AlphaMask &inMask,
					const RenderTarget &inTarget, const RenderState &inState, int inTX,int inTY)
	{
		Render( inMask, *this, inTarget, NormalBlender<false>(), inState.mClipRect, inTX,inTY );
	}
};


template<bool PAD,bool GRADIENT_FOCAL0>
class GradientRadialFiller : public GradientFillerBase
{
public:
	GradientRadialFiller(GraphicsGradientFill *inFill) : GradientFillerBase(inFill)
	{
		mRadial = true;
		// CX,CY are assumed to be zero, and the radius 1.0
      // - since these can be compensated for  with the matrix.
      mFX = inFill->focalPointRatio;
      if (mFX<-0.99) mFX = -0.99;
      else if (mFX>0.99) mFX = 0.99;

      // mFY = 0;   mFY can be set to zero, since rotating the matrix
      //  can also compensate for this.

      mA = (mFX*mFX - 1.0);
      mOn2A = 1.0/(2.0*mA);
      mA *= 4.0;
   }

   inline void SetPos(int inSX,int inSY)
	{
		if (GRADIENT_FOCAL0)
         mGX = mMapper.m00 * inSX + mMapper.m01*inSY + mMapper.mtx;
      else
         mGX = mMapper.m00 * inSX + mMapper.m01*inSY + mMapper.mtx - mFX;

      mGY = mMapper.m10 * inSX + mMapper.m11*inSY + mMapper.mty;
	}


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
      //                +  test point, (mGX,mGY)
      //                 \
      //                  \
      //                   * Focus (fx,fy)
      //                  /
      //                 /
      //                /
      //    -----------+-------------------------
      //        Centre (cx,cy) = 0,0
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

   ARGB GetInc( )
	{
      double alpha;
      double C = mGX*mGX + mGY*mGY;

      if (GRADIENT_FOCAL0)
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

		mGX += mMapper.m00;
		mGY += mMapper.m10;

      if (PAD)
      {
         if (alpha <=0)
           return *mColours;
         else if (alpha>=1.0)
           return mColours[mMask];
         else
           return  mColours[ ((int)(alpha*mMask)) ];
      }
		else
		{
          return mColours[ ((int)(alpha*(mMask))) & (mMask) ];
		}
   }

	void DoRender(const AlphaMask &inMask,
					const RenderTarget &inTarget, const RenderState &inState, int inTX,int inTY)
	{
		Render( inMask, *this, inTarget, NormalBlender<false>(), inState.mClipRect, inTX,inTY );
	}


	double mFX;

   double mA;
   double mOn2A;

   double mGX;
   double mGY;
};



Filler *Filler::Create(GraphicsGradientFill *inFill)
{
	if (inFill->isLinear)
	{
		if (inFill->spreadMethod==smPad)
			return new GradientLinearFiller<true>(inFill);
		else
			return new GradientLinearFiller<false>(inFill);
	}
	else
	{
		if (inFill->focalPointRatio==0)
		{
		   if (inFill->spreadMethod==smPad)
			   return new GradientRadialFiller<true,true>(inFill);
		   else
			   return new GradientRadialFiller<false,true>(inFill);
		}
		else
		{
		   if (inFill->spreadMethod==smPad)
			   return new GradientRadialFiller<true,false>(inFill);
		   else
			   return new GradientRadialFiller<false,false>(inFill);
		}
	}
}

