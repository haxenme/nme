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

   virtual void Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff) const = 0;
   virtual void ExpandVisibleFilterDomain(Rect &ioRect) const = 0;
   virtual void GetFilteredObjectRect(Rect &ioRect) const = 0;

   int        mQuality;
   ImagePoint mOrigin;
};

class BlurFilter : public Filter
{
public:
   BlurFilter(int inQuality, int inBlurX, int inBlurY);

   void Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff) const;
   void ExpandVisibleFilterDomain(Rect &ioRect) const;
   void GetFilteredObjectRect(Rect &ioRect) const;

   int mBlurX,mBlurY;
};


class DropShadowFilter : public BlurFilter
{
public:
   DropShadowFilter(int inQuality, int inBlurX, int inBlurY,
      double inTheta, double inDistance, int inColour, int inStrength,
      double inAlpha, bool inHide, bool inKnockout, bool inInner );

   // We will do the blur-iterations ourselves.
   int GetQuality() { return 1; }

   Surface * Apply(Surface *inSurface,bool inToPOW2) const;
   virtual void ExpandVisibleFilterDomain(Rect &ioRect) const;
   void GetFilteredObjectRect(Rect &ioRect) const;

   int mTX;
   int mTY;
   int mCol;
   int mStrength;
   int mAlpha;
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
