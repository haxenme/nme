#include <Graphics.h>
#include <Display.h>
#include <Surface.h>

namespace nme
{

// --- BlurFilter --------------------------------------------------------------

BlurFilter::BlurFilter(int inQuality, int inBlurX, int inBlurY)
  : Filter(inQuality), mBlurX(inBlurX), mBlurY(inBlurY)
{
}

void BlurFilter::ExpandVisibleFilterDomain(Rect &ioRect) const
{
   ioRect.x -= mBlurX;
   ioRect.w += mBlurX*2;
   ioRect.y -= mBlurY;
   ioRect.h += mBlurY*2;
}

void BlurFilter::GetFilteredObjectRect(Rect &ioRect) const
{
   ExpandVisibleFilterDomain(ioRect);
}




void BlurFilter::Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff) const
{
}


// --- FilterList --------------------------------------------------------------


Rect ExpandVisibleFilterDomain( const FilterList &inList, const Rect &inRect )
{
   Rect r = inRect;
   for(int i=0;i<inList.size();i++)
      inList[i]->ExpandVisibleFilterDomain(r);
   return r;
}

// Given the intial pixel rect, calculate the filtered pixels...
Rect GetFilteredObjectRect( const FilterList &inList, const Rect &inRect)
{
   Rect r = inRect;
   for(int i=0;i<inList.size();i++)
      inList[i]->GetFilteredObjectRect(r);
   return r;
}


Surface *FilterBitmap( const FilterList &inFilters, Surface *inBitmap,
                       const Rect &inSrcRect, const Rect &inDestRect, bool inMakePOW2)
{
   int n = inFilters.size();
   if (n==0)
      return inBitmap;

   Rect src_rect = inSrcRect;

   Surface *bmp = inBitmap;

   for(int i=0;i<n;i++)
   {
      Rect dest_rect(src_rect);
      if (i==n-1)
      {
         dest_rect = inDestRect;
         if (inMakePOW2)
         {
           dest_rect.w = UpToPower2(dest_rect.w);
           dest_rect.h = UpToPower2(dest_rect.h);
         }
      }
      else
      {
         inFilters[i]->GetFilteredObjectRect(dest_rect);
      }

      Surface *filtered = new SimpleSurface(dest_rect.w,dest_rect.h,bmp->Format());

      filtered->Zero();
  
      inFilters[i]->Apply(bmp,filtered, ImagePoint(dest_rect.x-src_rect.x,
                                                   dest_rect.y-src_rect.y) );

      filtered->IncRef();
      bmp->DecRef();
      bmp = filtered;
      src_rect = dest_rect;
   }

   return bmp;
}

 
} // end namespace nme


