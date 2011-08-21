#include "AlphaMask.h"

namespace nme
{

QuickVec<AlphaMask *> sMaskCache;

//#define RECYCLE_ALPHA_MASK

AlphaMask *AlphaMask::Create(const Rect &inRect,const Transform &inTrans)
{
   #ifdef RECYCLE_ALPHA_MASK
   int need = inRect.h+1;
   for(int i=0;i<sMaskCache.size();i++)
   {
      AlphaMask *m = sMaskCache[i];
      if (m->mLineStarts.mAlloc >=need && m->mLineStarts.size() < need+10 )
      {
         sMaskCache[i] = sMaskCache[sMaskCache.size()-1];
         sMaskCache.resize(sMaskCache.size()-1);
         m->mRect = inRect;
         m->mLineStarts.resize(need);
         m->mMatrix = *inTrans.mMatrix;
         m->mScale9 = *inTrans.mScale9;
         m->mAAFactor = inTrans.mAAFactor;
         return m;
      }
   }
   #endif
   return new AlphaMask(inRect,inTrans);
}

void AlphaMask::Dispose()
{
   #ifdef RECYCLE_ALPHA_MASK
   sMaskCache.push_back(this);
   #else
   delete this;
   #endif
}

void AlphaMask::ClearCache()
{
   #ifdef RECYCLE_ALPHA_MASK
   for(int i=0;i<sMaskCache.size();i++)
      delete sMaskCache[i];
   sMaskCache.resize(0);
   #endif
}

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
   if (mLineStarts.size()<2)
      return;

   Rect clip = inState.mClipRect;
   int y = mRect.y + inTY;
   const int *start = &mLineStarts[0] - y;

   int y1 = mRect.y1() + inTY;
   clip.ClipY(y,y1);

   for(; y<y1; y++)
   {
      int sy = y - inTY;
      const AlphaRun *end = &mAlphaRuns[ start[y+1] ];
      const AlphaRun *run = &mAlphaRuns[ start[y] ];
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
