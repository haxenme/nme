#ifndef ALPHA_MASK_H
#define ALPHA_MASK_H

#include <Geom.h>
#include <Graphics.h>
#include <QuickVec.h>
#include <vector>

namespace nme
{

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
   AlphaMask(const Rect &inRect,const Transform &inTrans) : mRect(inRect), mLines(inRect.h)
   {
      mMatrix = *inTrans.mMatrix;
      mScale9 = *inTrans.mScale9;
      mAAFactor = inTrans.mAAFactor;
   }

   void RenderBitmap(int inTX,int inTY,
                     const RenderTarget &inTarget,const RenderState &inState);

   // Given we were created with a certain transform and valid data rect, can we
   // cover the requested area for the requested transform?
   bool Compatible(const Transform &inTransform,const Rect &inExtent, const Rect &inVisiblePixels,
                   int &outTX, int &outTY);

   Rect      mRect;
   Lines     mLines;
   Matrix    mMatrix;
   Scale9    mScale9;
   int       mAAFactor;
};

class Filler
{
public:
   virtual ~Filler() { };
   virtual void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
               const RenderTarget &inTarget,const RenderState &inState) = 0;
   virtual void SetMapping(const UserPoint *inVertex, const float *inUVT,int inComponents) { }

   static Filler *Create(GraphicsSolidFill *inFill);
   static Filler *Create(GraphicsGradientFill *inFill);
   static Filler *Create(GraphicsBitmapFill *inFill);
   static Filler *CreatePerspective(GraphicsBitmapFill *inFil);
};

} // end namespace nme

#endif
