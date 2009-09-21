#include "AlphaMask.h"



bool AlphaMask::Compatible(const Transform &inTransform,
									const Rect &inExtent, const Rect &inVisiblePixels,
									int &outTX, int &outTY )
{
   int tx,ty;
   if  (!mMatrix.IsIntTranslation(*inTransform.mMatrix,tx,ty) && mScale9!=*inTransform.mScale9)
      return false;

   // Translate our cached pixels to this new position ...
   Rect translated = mRect.Translated(tx,ty);
   if (translated.Contains(inVisiblePixels))
   {
      outTX = tx;
      outTY = ty;
      return true;
   }

   return false;
}


