#include "RenderPolygon.h"
#include "AA.h"
#include <math.h>
#include <algorithm>
#include <map>





template<typename PIXEL_>
struct ConstantSource32
{
   inline ConstantSource32() { }
   inline ConstantSource32(int inRGB,double inA)
   {
      int val = PIXEL_::HasAlpha ? (int)(inA*255) : 255;
      int a =val<0 ? 0 : val>255 ? 255 : val;
      mVal.ival = inRGB | (a<<24);
      mValA.ival = inRGB;
   }

   inline PIXEL_ Value() const { return mVal; }
   inline ARGB Value(Uint8 inAlpha)
   {
      if (PIXEL_::HasAlpha)
         mValA.a = (mVal.a * inAlpha)>>8;
      else
         mValA.a = inAlpha;
      return mValA;
   }

   inline void SetPos(int inX,int inY) { }
   inline void Inc() { }
   inline void Advance(int inX) { }

   PIXEL_ mVal;
   ARGB mValA;
};



template<typename PIXEL_> PolygonRenderer *TCreateSolidRenderer(const RenderArgs &inArgs,
                              int inColour, double inAlpha)
{
   typedef ConstantSource32<PIXEL_> Source;

   return new SourcePolygonRenderer<Source>(inArgs,Source(inColour,inAlpha) );
}



PolygonRenderer *PolygonRenderer::CreateSolidRenderer(
                              const RenderArgs &inArgs,
                              int inColour, double inAlpha)
{
   if (inAlpha < 1.0 )
      return TCreateSolidRenderer<ARGB>(inArgs, inColour,inAlpha);
   else
      return TCreateSolidRenderer<XRGB>(inArgs, inColour,inAlpha);
}
