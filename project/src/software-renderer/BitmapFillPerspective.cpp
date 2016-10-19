#include "BitmapFill.h"


namespace nme
{
   
   template<int EDGE, bool SMOOTH>
   static Filler *CreateAlphaPersp(GraphicsBitmapFill *inFill)
   {
      if (inFill->bitmapData->Format() == pfAlpha)
         return new BitmapFiller<EDGE, SMOOTH, AlphaPixel, true>(inFill);
      else if (inFill->bitmapData->Format()==pfBGRA)
         return new BitmapFiller<EDGE, SMOOTH, ARGB, true>(inFill);
      else if (inFill->bitmapData->Format()==pfBGRPremA)
         return new BitmapFiller<EDGE, SMOOTH, BGRPremA, true>(inFill);
      else
         return new BitmapFiller<EDGE, SMOOTH, RGB, true>(inFill);
   }
   
   
   template<int EDGE>
   static Filler *CreateSmoothPersp(GraphicsBitmapFill *inFill)
   {
      if (inFill->smooth)
         return CreateAlphaPersp<EDGE, true>(inFill);
      else
         return CreateAlphaPersp<EDGE, false>(inFill);
   }
   
   
   Filler *Filler::CreatePerspective(GraphicsBitmapFill *inFill)
   {
      if (inFill->repeat)
      {
         if (IsPOW2(inFill->bitmapData->Width()) && IsPOW2(inFill->bitmapData->Height()))
            return CreateSmoothPersp<EDGE_POW2>(inFill);
         else
            return CreateSmoothPersp<EDGE_REPEAT>(inFill);
      }
      else
      {
         return CreateSmoothPersp<EDGE_CLAMP>(inFill);
      }
   }
   
   
}
