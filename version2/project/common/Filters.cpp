#include <Graphics.h>
#include <Display.h>
#include <Surface.h>

namespace nme
{

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


      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}



void BlurFilter::Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const
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
      ARGB *dest = (ARGB *)target.Row(y);
      const ARGB *src = ((ARGB *)inSrc->Row(y));
      BlurRow(src,1,sw,ox,dest,1,tmp->Width(),mBlurX+1);
   }
   sw = tmp->Width();
   }

	if (0)
	{
   	AutoSurfaceRender dest_render(outDest);
   	const RenderTarget &target = dest_render.Target();
		for(int y=0;y<sh;y++)
			memcpy(target.Row(y),tmp->Row(y),sw*sizeof(ARGB));
	}
	else
   {
   AutoSurfaceRender dest_render(outDest);
   const RenderTarget &target = dest_render.Target();
   int s_stride = tmp->GetStride()/sizeof(ARGB);
   int d_stride = target.mSoftStride/sizeof(ARGB);
   // Blur cols ...
   for(int x=0;x<w;x++)
   {
      int src_x = x - inDiff.x - ox;
      if (src_x>=0 && src_x<sw)
      {
         ARGB *dest = (ARGB *)target.Row(0) + x;
         const ARGB *src = ((ARGB *)tmp->Row(0)) + src_x;

         BlurRow(src,s_stride,sh,oy-inDiff.y,dest,d_stride,h,mBlurY+1);
      }
   }
   }

   tmp->DecRef();
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
}


void DropShadowFilter::Apply(const Surface *inSrc,Surface *outDest, ImagePoint inDiff,int inPass) const
{
}

void DropShadowFilter::ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const
{
}

void DropShadowFilter::GetFilteredObjectRect(Rect &ioRect,int inPass) const
{
   if (!mInner)
   {
		int bx = mBlurX-1;
		int by = mBlurY-1;
      int dx = mTX-bx*mQuality/2;
      int dy = mTY-by*mQuality/2;
      int x0 = std::min(0,dx);
      int y0 = std::min(0,dy);

      //ioDX += x0;
      //ioDY += y0;
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

			f->Apply(bmp,filtered, ImagePoint(dest_rect.x-src_rect.x,
														dest_rect.y-src_rect.y), q );

			bmp->DecRef();
			bmp = filtered;
			src_rect = dest_rect;
		}
   }

   return bmp;
}

 
} // end namespace nme


