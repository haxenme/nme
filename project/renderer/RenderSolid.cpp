#include "RenderPolygon.h"
#include "AA.h"
#include <math.h>
#include <algorithm>
#include <map>





template<int FLAGS_>
struct ConstantSource32
{
   enum { AlreadyRoundedAlpha = 1 };
   enum { AlphaBlend = FLAGS_ & NME_ALPHA_BLEND };

   inline ConstantSource32() { }

   inline ConstantSource32(int inRGB,double inA) :
      r(inRGB>>16), g(inRGB>>8), b(inRGB)
   {
      int val = (int)(inA*255);
      a =val<0 ? 0 : val>255 ? 255 : val;
      a+= a>>7;
   }



   inline void SetPos(int inX,int inY) { }
   inline void Inc() { }
   inline void Advance(int inX) { }


   inline Uint8 GetR() const { return r; }
   inline Uint8 GetG() const { return g; }
   inline Uint8 GetB() const { return b; }
   // TODO: does this need to be an int?
   inline Uint8 GetA() const { return a; }

   Uint8 r,g,b;
   int   a;
};





template<int FLAGS_> PolygonRenderer *TCreateSolidRenderer(const RenderArgs &inArgs,
                              int inColour, double inAlpha)
{
   typedef ConstantSource32<FLAGS_> Source;

   return new SourcePolygonRenderer<Source>(inArgs,Source(inColour,inAlpha) );
}



PolygonRenderer *PolygonRenderer::CreateSolidRenderer(
                              const RenderArgs &inArgs,
                              int inColour, double inAlpha)
{
   if (inAlpha < 1.0 )
      return TCreateSolidRenderer<NME_ALPHA_BLEND>(inArgs, inColour,inAlpha);
   else
      return TCreateSolidRenderer<0>(inArgs, inColour,inAlpha);
}
