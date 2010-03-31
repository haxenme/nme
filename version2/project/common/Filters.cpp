#include <Graphics.h>
#include <Display.h>
#include <Surface.h>

namespace nme
{


Surface *ExtractAlpha(const Surface *inSurface)
{
   if (inSurface->Format()!=pfXRGB && inSurface->Format()!=pfARGB)
      return 0;

   int w =  inSurface->Width();
   int h = inSurface->Height();
   Surface *result = new SimpleSurface(w,h,pfAlpha);
   result->IncRef();

   AutoSurfaceRender render(result);
   const RenderTarget &target = render.Target();
   for(int y=0;y<h;y++)
   {
      const uint8 *src = &((const ARGB *)inSurface->Row(y))->a;
      uint8 *dest = target.Row(y);
      for(int x=0;x<w;x++)
      {
         *dest = *src;
         dest++;
         src+=4;
      }
   }
   return result;
}

/*
 
   The BlurFilter has its size, mBlurX, mBlurY.  These are the "extra" pixels
    that get blended together. So Blur of 0 = original image, 1 = 1 extra, 2 = 2 extra.

   The even blends are easy: central pixel + Blur/2 either size.

   The Odd blends takes *source* pixels from the *right* first, at quality 1, and then from
    the left first for the second quality pass.  This means the destination will be
    bigger on the *left* first.  (flip the convolution filter)

*/



// --- BlurFilter --------------------------------------------------------------

BlurFilter::BlurFilter(int inQuality, int inBlurX, int inBlurY)
  : Filter(inQuality), mBlurX(inBlurX), mBlurY(inBlurY)
{
   mBlurX = std::max(0, std::min(256, mBlurX) );
   mBlurY = std::max(0, std::min(256, mBlurY) );
}

void BlurFilter::ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const
{
   // This is about the source rect, so we have to add pixels to the right first,
   //  from where they will be taken first.
   int extra_x0 = mBlurX/2;
   int extra_x1 = mBlurX - extra_x0;
   int extra_y0 = mBlurY/2;
   int extra_y1 = mBlurY - extra_y0;

   if (inPass & 1)
   {
      std::swap(extra_x0, extra_x1);
      std::swap(extra_y0, extra_y1);
   }

   ioRect.x -= extra_x0;
   ioRect.y -= extra_y0;
   ioRect.w += mBlurX;
   ioRect.h += mBlurY;

}

void BlurFilter::GetFilteredObjectRect(Rect &ioRect,int inPass) const
{
   // Distination pixels can "move" more left, as these left pixels can take extra from the right
   int extra_x1 = mBlurX/2;
   int extra_x0 = mBlurX - extra_x1;
   int extra_y1 = mBlurY/2;
   int extra_y0 = mBlurY - extra_y1;

   if (inPass & 1)
   {
      std::swap(extra_x0, extra_x1);
      std::swap(extra_y0, extra_y1);
   }

   ioRect.x -= extra_x0;
   ioRect.y -= extra_y0;
   ioRect.w += mBlurX;
   ioRect.h += mBlurY;
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
   const ARGB *prev = inSrc - inOffX*inDS;
   const ARGB *src = prev + inFilterSize*inDS;
   const ARGB *src_end = inSrc + inSrcW*inDS;
   ARGB *dest = inDest;
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
      if (prev>=src_end)
      {
         for( ; x<inDestW; x++ )
         {
            dest->ival = 0;
            dest+=inDD;
         }
         return;
      }

      if (sa==0)
         dest->ival = 0;
      else
      {
         dest->c0 = sc0/sa;
         dest->c1 = sc1/sa;
         dest->c2 = sc2/sa;
         dest->a = sa/inFilterSize;
      }

      if (src>=inSrc && src<src_end)
      {
         int a = src->a;
         sa+=a;
         sc0+= src->c0 * a;
         sc1+= src->c1 * a;
         sc2+= src->c2 * a;
      }

      if (prev>=inSrc)
      {
         int a = prev->a;
         sa-=a;
         sc0-= prev->c0 * a;
         sc1-= prev->c1 * a;
         sc2-= prev->c2 * a;
      }


      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}

// Alpha version
void BlurRow(const uint8 *inSrc, int inDS, int inSrcW, int inOffX,
             uint8 *inDest, int inDD, int inDestW, int inFilterSize)
{
   int sa = 0;

   // loop over destination pixels with kernel    -xxx+
   // At each pixel, we - the trailing pixel and + the leading pixel
   const uint8 *prev = inSrc - inOffX*inDS;
   const uint8 *src = prev + inFilterSize*inDS;
   const uint8 *src_end = inSrc + inSrcW*inDS;
   uint8 *dest = inDest;
   for(const uint8 *s=inSrc;s<src;s+=inDS)
      sa+=*s;

   int x=0;
   for(x=0;x<inDestW; x++)
   {
      if (prev>=src_end)
      {
         return;
         for( ; x<inDestW; x++ )
         {
            *dest = 0;
            dest+=inDD;
         }
      }

      *dest = sa/inFilterSize;

      if (src>=inSrc && src<src_end)
         sa+=*src;

      if (prev>=inSrc)
         sa-= *prev;

      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}



template<typename PIXEL>
void BlurFilter::DoApply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const
{
   int w = outDest->Width();
   int h = outDest->Height();
   int sw = inSrc->Width();
   int sh = inSrc->Height();

   outDest->Zero();

   Surface *tmp = new SimpleSurface(sw+mBlurX,sh,outDest->Format());
   tmp->IncRef();

   int ox = mBlurX/2;
   int oy = mBlurY/2;
   if ( (inPass & 1) == 0)
   {
      ox = mBlurX - ox;
      oy = mBlurY - oy;
   }

   {
   AutoSurfaceRender tmp_render(tmp);
   const RenderTarget &target = tmp_render.Target();
   // Blur rows ...
   for(int y=0;y<sh;y++)
   {
      PIXEL *dest = (PIXEL *)target.Row(y);
      const PIXEL *src = ((PIXEL *)inSrc->Row(y));
      BlurRow(src,1,sw,mBlurX,dest,1,w,mBlurX+1);
   }
   sw = tmp->Width();
   }

   if (0)
   {
      AutoSurfaceRender dest_render(outDest);
      const RenderTarget &target = dest_render.Target();
      for(int y=0;y<sh;y++)
         memcpy(target.Row(y),tmp->Row(y),sw*sizeof(PIXEL));
   }
   else
   {
   AutoSurfaceRender dest_render(outDest);
   const RenderTarget &target = dest_render.Target();
   int s_stride = tmp->GetStride()/sizeof(PIXEL);
   int d_stride = target.mSoftStride/sizeof(PIXEL);
   // Blur cols ...
   for(int x=0;x<w;x++)
   {
      int src_x = x - inDiff.x - ox;
      if (src_x>=0 && src_x<sw)
      {
         PIXEL *dest = (PIXEL *)target.Row(0) + x;
         const PIXEL *src = ((PIXEL *)tmp->Row(0)) + src_x;

         BlurRow(src,s_stride,sh,oy-inDiff.y,dest,d_stride,h,mBlurY+1);
      }
   }
   }

   tmp->DecRef();
}

void BlurFilter::Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const
{
   DoApply<ARGB>(inSrc,outDest,inDiff,inPass);
}

// --- DropShadowFilter --------------------------------------------------------------

DropShadowFilter::DropShadowFilter(int inQuality, int inBlurX, int inBlurY,
      double inTheta, double inDistance, int inColour, double inStrength,
      double inAlpha, bool inHide, bool inKnockout, bool inInner )
  : BlurFilter(inQuality, inBlurX, inBlurY),
     mCol(inColour), mAlpha(inAlpha),
     mHideObject(inHide), mKnockout(inKnockout), mInner(inInner)
{
   double theta = inTheta * M_PI/180.0;
   if (inDistance>255) inDistance = 255;
   if (inDistance<0) inDistance = 0;
   mTX = (int)( cos(theta) * inDistance );
   mTY = (int)( sin(theta) * inDistance );

   mStrength  = (int)(inStrength* 256);
   if ((unsigned int)mStrength>0x10000)
      mStrength = 0x10000;

   mAlpha  = (int)(inAlpha*256);
   if ((unsigned int)mAlpha > 256) mAlpha = 256;

   mAlpha255  = (int)(inAlpha*255);
   if ((unsigned int)mAlpha255 > 255) mAlpha255 = 255;

}


void DropShadowFilter::Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const
{
   Surface *alpha = ExtractAlpha(inSrc);

   // Blur alpha..
   ImagePoint offset(0,0);
   for(int q=0;q<mQuality;q++)
   {
      Rect src_rect(alpha->Width(),alpha->Height());
      BlurFilter::GetFilteredObjectRect(src_rect,q);
      Surface *blur = new SimpleSurface(src_rect.w, src_rect.h, pfAlpha);
      blur->IncRef();

      ImagePoint diff(src_rect.x, src_rect.y);

      DoApply<uint8>(alpha,blur,diff,q);
      alpha->DecRef();
      alpha = blur;
      offset += diff;
   }


   AutoSurfaceRender render(outDest);
   const RenderTarget &target = render.Target();

   // Copy it into the destination rect...
   ImagePoint blur_pos = offset + ImagePoint(mTX,mTY) - inDiff;
   int dy0 = std::max(0,blur_pos.y);
   int dy1 = std::min(outDest->Height(),blur_pos.y+alpha->Height());
   int dx0 = std::max(0,blur_pos.x);
   int dx1 = std::min(outDest->Width(),blur_pos.x+alpha->Width());
   int a = mAlpha;


   if (mInner)
   {
      // Copy source ...
      inSrc->BlitTo(target, Rect(inSrc->Width(),inSrc->Height()), inDiff.x, inDiff.y,
                 bmCopy, 0, 0xffffff );
      // And overlay shadow...
      Rect rect(alpha->Width(), alpha->Height() );
		if (a>127) a--;
      alpha->BlitTo(target, rect, blur_pos.x, blur_pos.y, bmTintedInner, 0, mCol | (a<<24));
   }
   else
   {
      if (dx1>dx0)
      {
         // TODO: Swap to match dest
         int col = mCol & 0x00ffffff;
         for(int y=dy0;y<dy1;y++)
         {
            ARGB *dest = ((ARGB *)target.Row(y)) + dx0;
            const uint8 *src = alpha->Row(y-blur_pos.y) + dx0 - blur_pos.x;
            for(int x=dx0;x<dx1;x++)
            {
               dest++->ival = col | ( (((*src++)*a)>>8) << 24 );
            }
         }
      }

      if (mKnockout)
      {
         inSrc->BlitTo(target, Rect(inSrc->Width(),inSrc->Height()), inDiff.x, inDiff.y,
                   bmErase, 0, 0xffffff );
      }
      else if (!mHideObject)
      {
         inSrc->BlitTo(target, Rect(inSrc->Width(),inSrc->Height()), -inDiff.x, -inDiff.y,
                   bmNormal, 0, 0xffffff );
              
      }
   }
   
   alpha->DecRef();

}

void DropShadowFilter::ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const
{
   if (!mInner)
   {
      Rect orig = ioRect;

      // Handle the quality ourselves, so iterate here.
      // Work out blur component...
      for(int q=0;q<mQuality;q++)
         BlurFilter::ExpandVisibleFilterDomain(ioRect,q);

      ioRect.Translate(-mTX,-mTY);

      if (!mKnockout)
         ioRect = ioRect.Union(orig);
   }

}

void DropShadowFilter::GetFilteredObjectRect(Rect &ioRect,int inPass) const
{
   if (!mInner)
   {
      Rect orig = ioRect;

      // Handle the quality ourselves, so iterate here.
      // Work out blur component...
      for(int q=0;q<mQuality;q++)
         BlurFilter::GetFilteredObjectRect(ioRect,q);

      ioRect.Translate(mTX,mTY);

      if (!mKnockout && !mHideObject)
         ioRect = ioRect.Union(orig);

      //ioRect.x--;
      //ioRect.y--;
      //ioRect.w+=2;
      //ioRect.h+=2;
   }
}



// --- FilterList --------------------------------------------------------------


Rect ExpandVisibleFilterDomain( const FilterList &inList, const Rect &inRect )
{
   Rect r = inRect;
   for(int i=0;i<inList.size();i++)
   {
      Filter *f = inList[i];
      int quality = f->GetQuality();
      for(int q=0;q<quality;q++)
         f->ExpandVisibleFilterDomain(r, q);
   }
   return r;
}

// Given the intial pixel rect, calculate the filtered pixels...
Rect GetFilteredObjectRect( const FilterList &inList, const Rect &inRect)
{
   Rect r = inRect;
   for(int i=0;i<inList.size();i++)
   {
      Filter *f = inList[i];
      int quality = f->GetQuality();
      for(int q=0;q<quality;q++)
         f->GetFilteredObjectRect(r, q);
   }
   return r;
}

void HighlightZeroAlpha(Surface *ioBMP)
{
   AutoSurfaceRender render(ioBMP);
   const RenderTarget &target = render.Target();

   for(int y=0;y<target.Height();y++)
   {
      ARGB *pixel = (ARGB *)target.Row(y);
      for(int x=0; x<target.Width(); x++)
      {
         if (pixel[x].a==0)
            pixel[x] = 0xff00ff00;
      }
   }
}


Surface *FilterBitmap( const FilterList &inFilters, Surface *inBitmap,
                       const Rect &inSrcRect, const Rect &inDestRect, bool inMakePOW2)
{
   int n = inFilters.size();
   if (n==0)
      return inBitmap;

   Rect src_rect = inSrcRect;

   Surface *bmp = inBitmap;

   bool do_clear = false;
   for(int i=0;i<n;i++)
   {
      Filter *f = inFilters[i];

      int quality = f->GetQuality();
      for(int q=0;q<quality;q++)
      {
         Rect dest_rect(src_rect);
         if (i==n-1 && q==quality-1)
         {
            dest_rect = inDestRect;
            if (inMakePOW2)
            {
              do_clear = true;
              dest_rect.w = UpToPower2(dest_rect.w);
              dest_rect.h = UpToPower2(dest_rect.h);
            }
         }
         else
         {
            f->GetFilteredObjectRect(dest_rect, q);
         }

         Surface *filtered = new SimpleSurface(dest_rect.w,dest_rect.h,bmp->Format());
         filtered->IncRef();

         if (do_clear)
            filtered->Zero();

         f->Apply(bmp,filtered, ImagePoint(dest_rect.x-src_rect.x,
                                          dest_rect.y-src_rect.y), q );

         bmp->DecRef();
         bmp = filtered;
         src_rect = dest_rect;
      }
   }

   //HighlightZeroAlpha(bmp);

   return bmp;
}

 
} // end namespace nme


