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

/*
   Mask of size 4 looks like:  x+xx where + is the centre
   The blurreed image is then 2 pixel bigger in the left and one on the right
*/

void BlurRow(const ARGB *inSrc, int inDS, int inSrcW, int inOffX,
             ARGB *inDest, int inDD, int inDestW, int inFilterSize)
{
   int sc0 = 0;
   int sc1 = 0;
   int sc2 = 0;
   int sa = 0;

   // loop over destination pixels with kernel    -xxx+
   // At each pixel, we - the trailing pixel and + the leading pixel
   const ARGB *prev = inSrc + inOffX*inDS - inFilterSize*inDS;
   const ARGB *src = inSrc + inOffX*inDS + inFilterSize*inDS;
   const ARGB *src_end = inSrc + inSrcW*inDS;
   ARGB *dest = inDest;
   int fs = inFilterSize*2+1;
   for(const ARGB *s=inSrc;s<src;s+=inDS)
   {
      int a = s->a;
      sa+=a;
      sc0+= s->c0 * a;
      sc1+= s->c1 * a;
      sc2+= s->c2 * a;
   }
   for(int x=0;x<inDestW; x++)
   {
      if (src>=inSrc && src<src_end)
      {
         int a = src->a;
         sa+=a;
         sc0+= src->c0 * a;
         sc1+= src->c1 * a;
         sc2+= src->c2 * a;
      }
      if (prev>=src_end)
         return;

      if (prev>=inSrc)
      {
         int a = prev->a;
         sa-=a;
         sc0-= prev->c0 * a;
         sc1-= prev->c1 * a;
         sc2-= prev->c2 * a;
      }

      if (sa==0)
         dest->ival = 0;
      else
      {
         dest->c0 = sc0/sa;
         dest->c1 = sc1/sa;
         dest->c2 = sc2/sa;
         dest->a = sa/fs;
      }

      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}



void BlurFilter::Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff) const
{
   int w = outDest->Width();
   int h = outDest->Height();
   int sw = inSrc->Width();
   int sh = inSrc->Height();

   outDest->Zero();

   Surface *tmp = new SimpleSurface(sw+2*mBlurX,sh,outDest->Format());
   tmp->IncRef();

   {
   AutoSurfaceRender tmp_render(tmp);
   const RenderTarget &target = tmp_render.Target();
   // Blur rows ...
   for(int y=0;y<sh;y++)
   {
      ARGB *dest = (ARGB *)target.Row(y);
      const ARGB *src = ((ARGB *)inSrc->Row(y));
      BlurRow(src,1,sw,-mBlurX,dest,1,tmp->Width(),mBlurX);
   }
   inDiff.x += mBlurX;
   sw = tmp->Width();
   }

   {
   AutoSurfaceRender dest_render(outDest);
   const RenderTarget &target = dest_render.Target();
   int s_stride = tmp->GetStride()/sizeof(ARGB);
   int d_stride = target.mSoftStride/sizeof(ARGB);
   // Blur cols ...
   for(int x=0;x<w;x++)
   {
      int src_x = x - inDiff.x;
      if (src_x>=0 && src_x<sw)
      {
         ARGB *dest = (ARGB *)target.Row(0) + x;
         const ARGB *src = ((ARGB *)tmp->Row(0)) + src_x;

         BlurRow(src,s_stride,sh,inDiff.y,dest,d_stride,h,mBlurY);
      }
   }
   }

   tmp->DecRef();
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


