#include "AlphaMask.h"

namespace nme
{

bool AlphaMask::Compatible(const Transform &inTransform,
                           const Rect &inExtent, const Rect &inVisiblePixels,
                           int &outTX, int &outTY )
{
   int tx,ty;
   if  ( (!mMatrix.IsIntTranslation(*inTransform.mMatrix,tx,ty)) || (mScale9!=*inTransform.mScale9) )
      return false;

   if (mAAFactor!=inTransform.mAAFactor)
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

void AlphaMask::RenderBitmap(int inTX,int inTY,
         const RenderTarget &inTarget,const RenderState &inState)
{
   if (mLines.empty())
      return;

   Rect clip = inState.mClipRect;
   int y = mRect.y + inTY;
   const AlphaRuns *lines = &mLines[0] - y;

   int y1 = mRect.y1() + inTY;
   clip.ClipY(y,y1);

   for(; y<y1; y++)
   {
      int sy = y - inTY;
      const AlphaRuns &line = lines[y];
      AlphaRuns::const_iterator end = line.end();
      AlphaRuns::const_iterator run = line.begin();
      if (run!=end)
      {
         Uint8 *dest0 = inTarget.Row(y);
         while(run<end && run->mX1 + inTX<=clip.x)
            run++;

         while(run<end)
         {
            int x0 = run->mX0 + inTX;
            if (x0 >= clip.x1())
               break;
            int x1 = run->mX1 + inTX;
            clip.ClipX(x0,x1);

            Uint8 *dest = dest0 + x0;
            int alpha = run->mAlpha;

            if (alpha>0)
            {
               if (alpha>=255)
                  while(x0++<x1)
                     *dest++ = 255;
               else
                  while(x0++<x1)
                     QBlendAlpha( *dest++, alpha );
            }
            ++run;
         }
      }
   }

}

}
