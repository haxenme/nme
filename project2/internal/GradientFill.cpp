#include <Graphics.h>
#include "Render.h"



template<bool PAD>
class GradientFiller : public Filler
{
public:
	GradientFiller(GraphicsGradientFill *inFill)
	{
		mGrad = inFill;
		int n = inFill->spreadMethod==smReflect ? 512 : 256;
      mColours = new ARGB[n];
      mMask =  n-1;
		mIsSwapped = false;
		mIsInit = false;
	}
	~GradientFiller()
	{
		delete [] mColours;
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
		   mPos += mDPDX;
			if (p<0)
		      return mColours[0];
			if (p>255)
		      return mColours[255];
		   return mColours[p];
		}
		else
		{
		   int p = mPos;
		   mPos += mDPDX;
		   return mColours[ (p>>15) & mMask];
		}
	}

   void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
       const RenderTarget &inTarget,const RenderState &inState)
	{
		// Get combined mapping matrix...
		Matrix mapper = inState.mTransform.mMatrix;
		mapper = mapper.Translate(inTX,inTY).Mult(mGrad->matrix);
		mMapper = mapper.Inverse();
		mMapper *= (1.0/1638.4);
		mMapper.Translate(0.5,0.5);

		if (PAD)
		   mDPDX = (int)(mMapper.m00 * (1<<16)+ 0.5);
		else
		   mDPDX = (int)(mMapper.m00 * (1<<23)+ 0.5);

		bool want_swapped =  inTarget.format & pfSwapRB;
		if (!mIsInit)
			InitArray(want_swapped);
		else if (want_swapped!=mIsSwapped)
			SwapArray();


		Render( mAlphaMask, *this, inTarget, NormalBlender<false>(), inState.mClipRect, inTX,inTY );
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

	int  mPos;
	int  mDPDX;
	bool mIsSwapped;
	bool mIsInit;
	int  mMask;
	Matrix mMapper;
	ARGB *mColours;
	GraphicsGradientFill *mGrad;
};


Filler *Filler::Create(GraphicsGradientFill *inFill)
{
	if (inFill->spreadMethod==smPad)
		return new GradientFiller<true>(inFill);
	else
		return new GradientFiller<false>(inFill);
}

