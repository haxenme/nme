#include <Graphics.h>
#include "Render.h"

class SolidFiller : public Filler
{
public:
	SolidFiller(GraphicsSolidFill *inFill)
	{
		mRGB.SetRGB(inFill->rgb);
		int alpha = inFill->alpha*255.9;
		if (alpha<0) alpha = 0;
		if (alpha>255) alpha = 255;
		mRGB.a = alpha;
	}

   inline void SetPos(int,int) {}
   ARGB GetInc( ) { return mFillRGB; }


   void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
       const RenderTarget &inTarget,const RenderState &inState)
	{
		if (inTarget.format & pfSwapRB)
			mFillRGB.SetSwapRGBA(mRGB);
		else
			mFillRGB = mRGB;

		Render( mAlphaMask, *this, inTarget, NormalBlender<false>(), inState.mClipRect, inTX,inTY );
	}

	ARGB mRGB;
	ARGB mFillRGB;

};


Filler *Filler::Create(GraphicsSolidFill *inFill)
{
	return new SolidFiller(inFill);
}

