#ifndef FILTERS_H
#define FILTERS_H

#include "QuickVec.h"
#include "Geom.h"

namespace nme
{

class Surface;

class Filter
{
public:
   Filter(int inQuality) : mQuality(inQuality) { }
   virtual ~Filter() { };

   ImagePoint GetOrigin() const { return mOrigin; }
   virtual int GetQuality() { return mQuality; }

   virtual void Apply(const Surface *inSrc,Surface *outDest,ImagePoint inDiff,int inPass) const = 0;
   virtual void ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const = 0;
   virtual void GetFilteredObjectRect(Rect &ioRect,int inPass) const = 0;

   int        mQuality;
   ImagePoint mOrigin;
};

class BlurFilter : public Filter
{
public:
   BlurFilter(int inQuality, int inBlurX, int inBlurY);

   void Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const;
   void ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const;
   void GetFilteredObjectRect(Rect &ioRect,int inPass) const;

   int mBlurX,mBlurY;
};


class DropShadowFilter : public BlurFilter
{
public:
   DropShadowFilter(int inQuality, int inBlurX, int inBlurY,
      double inTheta, double inDistance, int inColour, double inStrength,
      double inAlpha, bool inHide, bool inKnockout, bool inInner );

   // We will do the blur-iterations ourselves.
   int GetQuality() { return 1; }

   void Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const;
   virtual void ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const;
   void GetFilteredObjectRect(Rect &ioRect,int inPass) const;

   int mTX;
   int mTY;
   int mCol;
   int mStrength; /* Fixed-8 */
   int mAlpha; /* 0...256 */
   bool mHideObject;
   bool mKnockout;
   bool mInner;
};

typedef QuickVec<Filter *> FilterList;



Rect ExpandVisibleFilterDomain( const FilterList &inList, const Rect &inRect );

Surface *FilterBitmap(const FilterList &inList, Surface *inBitmap,
                       const Rect &inSrcRect, const Rect &inDestRect, bool inMakePOW2);

Rect GetFilteredObjectRect(const FilterList &inList,const Rect &inRect);

} // end namespace nme

#endif
