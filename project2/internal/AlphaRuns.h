#ifndef ALPHA_RUNS_H
#define ALPHA_RUNS_H

#include <Geom.h>
#include <Graphics.h>
#include <QuickVec.h>
#include <vector>


struct AlphaRun
{
   inline AlphaRun() { }
   inline AlphaRun(int inX0,int inX1,short inAlpha) : mX0(inX0), mX1(inX1), mAlpha(inAlpha) { }
   inline bool Contains(int inX) const { return inX >= mX0 && inX<mX1; }
   inline void Set(int inX0,int inX1,int inAlpha)
      { mX0 = inX0; mX1 = inX1; mAlpha = inAlpha; }

   short mX0,mX1;
   // mAlpha is 0 ... 256 inclusive
   short mAlpha;
};


typedef QuickVec<AlphaRun> AlphaRuns;
typedef std::vector<AlphaRuns> Lines;


struct AlphaMask
{
   AlphaMask(const Rect &inRect) : mRect(inRect), mLines(inRect.h) { }

   Rect      mRect;
	Lines     mLines;

	/*
	                Screen
	          +-----------------
		 Pos   |                 |
        +....|@@@@             |
		  .    |@@@@=valid rect  |
		  .    |@@@@             |
		  .....|@@@@             |
		       |                 |
		       |                 |
	          +-----------------

	  All values below are integerized to the AA grid (by multiplying the the AA factor)
      and are used to determine if the mask can be reused.

     Pos (mOx,mOy) is the position of the (unclipped) extent when these alpha run
	   were calculated.  The valid rect coordinates are with respect to the position;

     The valid rect is something like the intersection of the extent and the screen rect.
	  (although a bigger valid rect may be calculated to allow for some scrolling)

	  The alpha-run can be reused if the required screen rect is contained in the valid rect,
	   and the Pos and required position are anti-alias-sub-pixel aligned, and the
		transform has the same (except for translation).

	  To reuse the alpha-run at a different position, the destination can be adjusted
	   by the difference in positions of the extents.

	*/

   void SetValidArea(const ImagePoint &inPos, const Rect &inRect, const Transform &inTrans)
   {
      mAAPos = inPos;
      mAAValidRect = inRect;
      mTransform = inTrans;
   }
	bool Compatible(const Transform &inTransform,const Rect &inExtent, const Rect &inVisiblePixels );

	ImagePoint mAAPos;
	Rect       mAAValidRect;
	Transform  mTransform;

};


#endif
