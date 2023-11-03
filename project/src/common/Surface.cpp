#include <Graphics.h>
#include <Surface.h>
#include <nme/Pixel.h>

namespace nme
{

int gTextureContextVersion = 1;

int gImageData = 0;

// --- Surface -------------------------------------------------------


Surface::~Surface()
{
   delete mTexture;
}

void Surface::Bind(HardwareContext &inHardware,int inSlot)
{
   if (mTexture && !mTexture->IsCurrentVersion())
   {
      delete mTexture;
      mTexture = 0;
   }
 
   if (!mTexture)
      mTexture = inHardware.CreateTexture(this,mFlags);

   mTexture->Bind(inSlot);
}

Texture *Surface::GetTexture(HardwareContext *inHardware,int inPlane)
{
   if (mTexture && !mTexture->IsCurrentVersion())
   {
      delete mTexture;
      mTexture = 0;
   }
   if (!mTexture && inHardware)
      mTexture = inHardware->CreateTexture(this,mFlags);
   return mTexture;
}




// --- SimpleSurface -------------------------------------------------------

SimpleSurface::SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign)
{
   mWidth = inWidth;
   mHeight = inHeight;
   mTexture = 0;
   mPixelFormat = inPixelFormat;

   int pix_size = BytesPerPixel(inPixelFormat);

   if (inByteAlign>1)
   {
      mStride = inWidth * pix_size + inByteAlign -1;
      mStride -= mStride % inByteAlign;
   }
   else
   {
      mStride = inWidth*pix_size;
   }

   mBase = new unsigned char[mStride * mHeight+1];
   mBase[mStride*mHeight] = 69;

   gImageData += mStride*mHeight;
}

SimpleSurface::~SimpleSurface()
{
   if (mBase)
   {
      if (mBase[mStride*mHeight]!=69)
      {
         ELOG("Image write overflow");
      }
      delete [] mBase;

      gImageData -= mStride*mHeight;
   }
}


void SimpleSurface::destroyHardwareSurface() {

  if (mTexture )
   {
      delete mTexture;
      mTexture = 0;
   }
   
}


void SimpleSurface::createHardwareSurface() {

   if ( nme::HardwareRenderer::current == NULL )
      printf( "Null Hardware Context" );
   else
       GetTexture( nme::HardwareRenderer::current );
   
}

void SimpleSurface::MakeTextureOnly()
{ 
   if(mBase)
   {
       createHardwareSurface();
       delete [] mBase;
       mBase = NULL;
   }
}

bool SimpleSurface::ReinterpretPixelFormat(PixelFormat inNewFormat)
{
   if ( BytesPerPixel(inNewFormat) != BytesPerPixel(mPixelFormat) )
      return false;

   mPixelFormat = inNewFormat;

   return true;
}

void SimpleSurface::SetFlags(unsigned int inFlags)
{
   bool wasMipmapped = mFlags & surfMipmaps;
   mFlags = inFlags;
   bool isMipmapped = mFlags & surfMipmaps;
   if (wasMipmapped!=isMipmapped)
   {
      mVersion++;
      destroyHardwareSurface();
   }
}

void SimpleSurface::ChangeInternalFormat(PixelFormat inNewFormat, const Rect *inIgnore)
{
   if (!mBase || inNewFormat==mPixelFormat)
      return;

   PixelFormat newFormat = inNewFormat;
   // Convert to render target type...
   if (newFormat==pfNone)
      switch(mPixelFormat)
      {
         case pfLuma:  newFormat = pfRGB; break;
         case pfLumaAlpha:  newFormat = pfBGRA; break;
         case pfRGB32f:  newFormat = pfRGB; break;
         case pfRGBA32f:  newFormat = pfBGRA; break;
         case pfRGBA:  newFormat = pfBGRA; break;
         case pfRGBPremA:  newFormat = pfBGRPremA; break;
         case pfRGB565:  newFormat = pfRGB; break;
         case pfARGB4444:  newFormat = pfBGRA; break;
         default:
           newFormat = pfRGB;
     }

   // Convert in-situ
   if (newFormat==pfRGBPremA && mPixelFormat==pfBGRA)
   {
      int x1 = inIgnore ? std::min(mWidth,inIgnore->x) : mWidth;
      int x2 = inIgnore ? std::min(mWidth,inIgnore->x+inIgnore->w) : mWidth;
      for(int y=0;y<mHeight;y++)
      {
         if (inIgnore && (y>=inIgnore->y && y<inIgnore->y+inIgnore->h))
            continue;
         BGRPremA *bgra = (BGRPremA *)Row(y);
         for(int x=0;x<x1;x++)
         {
            const uint8 *prem = gPremAlphaLut[bgra->a];
            bgra->b = prem[bgra->b];
            bgra->g = prem[bgra->g];
            bgra->r = prem[bgra->r];
            bgra++;
         }

         bgra = (BGRPremA *)Row(y) + x2;
         for(int x=x2;x<mWidth;x++)
         {
            const uint8 *prem = gPremAlphaLut[bgra->a];
            bgra->b = prem[bgra->b];
            bgra->g = prem[bgra->g];
            bgra->r = prem[bgra->r];
            bgra++;
         }

      }
      mPixelFormat = newFormat;
      return;
   }

   if (newFormat==pfBGRA && mPixelFormat==pfBGRPremA)
   {
      int x1 = inIgnore ? std::min(mWidth,inIgnore->x) : mWidth;
      int x2 = inIgnore ? std::min(mWidth,inIgnore->x+inIgnore->w) : mWidth;
      for(int y=0;y<mHeight;y++)
      {
         if (inIgnore && (y>=inIgnore->y && y<inIgnore->y+inIgnore->h))
            continue;
         BGRPremA *bgra = (BGRPremA *)Row(y);
         for(int x=0;x<x1;x++)
         {
            const uint8 *unprem = gUnPremAlphaLut[bgra->a];
            bgra->b = unprem[bgra->b];
            bgra->g = unprem[bgra->g];
            bgra->r = unprem[bgra->r];
            bgra++;
         }
         bgra = (BGRPremA *)Row(y) + x2;
         for(int x=x2;x<mWidth;x++)
         {
            const uint8 *unprem = gUnPremAlphaLut[bgra->a];
            bgra->b = unprem[bgra->b];
            bgra->g = unprem[bgra->g];
            bgra->r = unprem[bgra->r];
            bgra++;
         }

      }
      mPixelFormat = newFormat;
      return;
   }


   int newSize = BytesPerPixel(newFormat);
   int newStride = mWidth * newSize;
   unsigned char *newBuffer = new unsigned char[newStride * mHeight+1];
   newBuffer[newStride*mHeight] = 69;

   if (inIgnore==0)
   {
     PixelConvert(mWidth, mHeight,
       mPixelFormat,  mBase, mStride, GetPlaneOffset(),
       newFormat, newBuffer, newStride, 0 );
   }
   else
   {
      /*
          TTTTTTT
          L  X  R
          BBBBBBB
      */
      Rect r = *inIgnore;
      if (r.y>0)
      {
         PixelConvert(mWidth, r.y,
           mPixelFormat,  mBase, mStride, GetPlaneOffset(),
           newFormat, newBuffer, newStride, 0 );
      }
      if (r.x>0)
      {
         PixelConvert(r.x, r.h,
           mPixelFormat,  mBase + mStride*r.y, mStride, GetPlaneOffset(),
           newFormat, newBuffer + newStride*r.y, newStride, 0 );
      }
      if (r.x1()<mWidth)
      {
         int oldPw = BytesPerPixel(mPixelFormat);
         PixelConvert(mWidth-r.x1(), r.h,
           mPixelFormat,  mBase + mStride*r.y + r.x1()*oldPw, mStride, GetPlaneOffset(),
           newFormat, newBuffer + newStride*r.y + r.x1()*newSize, newStride, 0 );
      }

      if (r.y1()<mHeight)
      {
         PixelConvert(mWidth, mHeight-r.y1(),
           mPixelFormat,  mBase + mStride*r.y1(), mStride, GetPlaneOffset(),
           newFormat, newBuffer + newStride*r.y1(), newStride, 0 );
      }
   }
   delete [] mBase;
   mBase = newBuffer;
   mStride = newStride;
   mPixelFormat = newFormat;
   if (mTexture)
      mTexture->Dirty(Rect(0,0,mWidth,mHeight));
}




void SimpleSurface::colorTransform(const Rect &inRect, ColorTransform &inTransform)
{
   if (mPixelFormat==pfAlpha || !mBase)
      return;

   ChangeInternalFormat(pfBGRA);

   const uint8 *ta = inTransform.GetAlphaLUT();
   const uint8 *tr = inTransform.GetRLUT();
   const uint8 *tg = inTransform.GetGLUT();
   const uint8 *tb = inTransform.GetBLUT();

   RenderTarget target = BeginRender(inRect,false);

   Rect r = target.mRect;
   for(int y=0;y<r.h;y++)
   {
      ARGB *rgb = ((ARGB *)target.Row(y+r.y)) + r.x;
      for(int x=0;x<r.w;x++)
      {
         rgb->r = tr[rgb->r];
         rgb->g = tg[rgb->g];
         rgb->b = tb[rgb->b];
         rgb->a = ta[rgb->a];
         rgb++;
      }
   }

   EndRender();
}




void SimpleSurface::BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                   int inPosX, int inPosY,
                   int inSrcChannel, int inDestChannel ) const
{
   PixelFormat destFmt = outTarget.mPixelFormat;
   int destPos = GetPixelChannelOffset(destFmt,(PixelChannel)inDestChannel);
   if (destPos<0)
      return;

   PixelFormat srcFmt = mPixelFormat;
   int srcPos =GetPixelChannelOffset(srcFmt,(PixelChannel)inSrcChannel);
   if (srcPos==CHANNEL_OFFSET_NONE)
      return;

   int srcPw = BytesPerPixel(srcFmt);
   int destPw = BytesPerPixel(destFmt);


   bool set_255 = srcPos==CHANNEL_OFFSET_VIRTUAL_ALPHA;

   Rect src_rect(inSrcRect.x,inSrcRect.y, inSrcRect.w, inSrcRect.h );
   src_rect = src_rect.Intersect( Rect(0,0,Width(),Height() ) );

   Rect dest_rect(inPosX,inPosY, inSrcRect.w, inSrcRect.h );
   dest_rect = dest_rect.Intersect(outTarget.mRect);


   int minW = src_rect.w;
   if(dest_rect.w < src_rect.w)
      minW = dest_rect.w;

   int minH = src_rect.h;
   if(dest_rect.h < src_rect.h)
      minH = dest_rect.h;

   for(int y=0;y<minH;y++)
   {
      uint8 *d = outTarget.Row(y+dest_rect.y) + dest_rect.x*destPw + destPos;
      if (set_255)
      {
         for(int x=0;x<minW;x++)
         {
            *d = 255;
            d+=destPw;
         }
      }
      else
      {
         const uint8 *s = Row(y+src_rect.y) + src_rect.x * srcPw + srcPos;

         for(int x=0;x<minW;x++)
         {
            *d = *s;
            d+=destPw;
            s+=srcPw;
         }
      }
   }
}


template<typename SRC,typename DEST>
void TStretchTo(const SimpleSurface *inSrc,const RenderTarget &outTarget,
                const Rect &inSrcRect, const DRect &inDestRect, int inFlags)
{
   Rect irect( inDestRect.x+0.5, inDestRect.y+0.5, inDestRect.x1()+0.5, inDestRect.y1()+0.5, true);
   Rect out = irect.Intersect(outTarget.mRect);
   if (!out.Area())
      return;

   int dsx_dx = (inSrcRect.w << 16)/inDestRect.w;
   int dsy_dy = (inSrcRect.h << 16)/inDestRect.h;

   if (!inFlags)
   {
      // (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
      // Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
      //
      // Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5

      //int sx0 = (int)((out.x-inDestRect.x*inSrcRect.w/inDestRect.w)*65536) +(inSrcRect.x<<16);
      //int sy0 = (int)((out.y-inDestRect.y*inSrcRect.h/inDestRect.h)*65536) +(inSrcRect.y<<16);
      int sx0 = (int)((out.x+0.5-inDestRect.x)*dsx_dx + (inSrcRect.x<<16) );
      int sy0 = (int)((out.y+0.5-inDestRect.y)*dsy_dy + (inSrcRect.y<<16) );

      for(int y=0;y<out.h;y++)
      {
         DEST *dest= (DEST *)outTarget.Row(y+out.y) + out.x;
         int y_ = (sy0>>16);
         const SRC *src = (const SRC *)inSrc->Row(y_);
         sy0+=dsy_dy;

         int sx = sx0;
         for(int x=0;x<out.w;x++)
         {
            BlendPixel(*dest++, src[sx>>16]);
            sx+=dsx_dx;
         }
      }
   }
   else
   {
      // todo - overflow testing
      // (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
      // Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
      //
      // Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5
      int sx0 = (int)((out.x+0.5-inDestRect.x)*dsx_dx + (inSrcRect.x<<16) ) - 0x8000;
      int sy0 = (int)((out.y+0.5-inDestRect.y)*dsy_dy + (inSrcRect.y<<16) ) - 0x8000;
      //int sx0 = (((((out.x-inDestRect.x)<<8) + 0x80) * inSrcRect.w/inDestRect.w) << 8) +(inSrcRect.x<<16) - 0x8000;
      //int sy0 = (((((out.y-inDestRect.y)<<8) + 0x80) * inSrcRect.h/inDestRect.h) << 8) +(inSrcRect.y<<16) - 0x8000;
      int last_y = inSrcRect.y1()-1;
      SRC s;
      for(int y=0;y<out.h;y++)
      {
         DEST *dest= (DEST *)outTarget.Row(y+out.y) + out.x;
         int y_ = (sy0>>16);
         int y_frac = sy0 & 0xffff;
         const SRC *src0 = (const SRC *)inSrc->Row(y_);
         const SRC *src1 = (const SRC *)inSrc->Row(y_<last_y ? y_+1 : y_);
         sy0+=dsy_dy;

         int sx = sx0;
         for(int x=0;x<out.w;x++)
         {
            int x_ = sx>>16;
            int x_frac = sx & 0xffff;

            SRC s = BilinearInterp( src0[x_], src0[x_+1], src1[x_], src1[x_+1], x_frac, y_frac);

            BlendPixel(*dest, s);
            dest++;
            sx+=dsx_dx;
         }
      }
   }
}


template<typename PIXEL>
void TStretchSuraceTo(const SimpleSurface *inSurface, const RenderTarget &outTarget,
                     const Rect &inSrcRect, const DRect &inDestRect, unsigned int inFlags)
{
   switch(outTarget.Format())
   {
      case pfRGB:
         TStretchTo<PIXEL,RGB>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfBGRA:
         TStretchTo<PIXEL,ARGB>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfBGRPremA:
         TStretchTo<PIXEL,BGRPremA>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfAlpha:
         TStretchTo<PIXEL,RGB>(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfLuma:
         TStretchTo<PIXEL, LumaPixel<Uint8> >(inSurface, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      default: ;
   }
}

void SimpleSurface::StretchTo(const RenderTarget &outTarget,
                     const Rect &inSrcRect, const DRect &inDestRect, unsigned int inFlags) const
{
   switch(mPixelFormat)
   {
      case pfRGB:
         TStretchSuraceTo<RGB>(this, outTarget, inSrcRect, inDestRect, inFlags);
         break;
      case pfBGRA:
         TStretchSuraceTo<ARGB>(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      case pfBGRPremA:
         TStretchSuraceTo<BGRPremA>(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      case pfAlpha:
         TStretchSuraceTo<RGB>(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      case pfLuma:
         TStretchSuraceTo< LumaPixel<Uint8> >(this, outTarget, inSrcRect, inDestRect,inFlags);
         break;
      default: ;
   }
}



void SimpleSurface::Clear(uint32 inColour,const Rect *inRect)
{
   if (!mBase)
      return;
   if (mPixelFormat==pfLuma)
   {
      memset(mBase, inColour & 0xff,mStride*mHeight);
      return;
   }

   ARGB rgb(inColour);
   if (mPixelFormat==pfAlpha)
   {
      memset(mBase, rgb.a,mStride*mHeight);
      return;
   }

   int x0 = inRect ? inRect->x  : 0;
   int x1 = inRect ? inRect->x1()  : Width();
   int y0 = inRect ? inRect->y  : 0;
   int y1 = inRect ? inRect->y1()  : Height();
   if( x0 < 0 ) x0 = 0;
   if( x1 > Width() ) x1 = Width();
   if( y0 < 0 ) y0 = 0;
   if( y1 > Height() ) y1 = Height();
   if (x1<=x0 || y1<=y0)
      return;

   int pix_size = BytesPerPixel(mPixelFormat);

   if (mPixelFormat==pfLumaAlpha)
   {
      for(int y=y0;y<y1;y++)
      {
         int luma = rgb.luma();
         uint8 *ptr = (mBase + y*mStride) + x0*2;
         for(int x=x0;x<x1;x++)
         {
            *ptr++ = luma;
            *ptr++ = rgb.a;
         }
      }

   }
   else if (mPixelFormat==pfRGB)
   {
      for(int y=y0;y<y1;y++)
      {
         uint8 *ptr = (mBase + y*mStride) + x0*3;
         for(int x=x0;x<x1;x++)
         {
            *ptr++ = rgb.r;
            *ptr++ = rgb.g;
            *ptr++ = rgb.b;
         }
      }
   }
   else if (pix_size==4)
   {
      if (mPixelFormat==pfBGRPremA)
      {
         BGRPremA prem;
         SetPixel(prem,rgb);
         rgb.ival = prem.ival;
      }
      for(int y=y0;y<y1;y++)
      {
         uint32 *ptr = (uint32 *)(mBase + y*mStride) + x0;
         for(int x=x0;x<x1;x++)
            *ptr++ = rgb.ival;
      }
   }
   else
   {
      for(int y=y0;y<y1;y++)
      {
         uint8 *ptr = (uint8 *)(mBase + y*mStride) + x0*pix_size;
         memset(ptr, 0, (x1-x0)*pix_size);
      }
   }

   if (mTexture)
      mTexture->Dirty( Rect(x0,y0,x1-x0,y1-y0) );
}

void SimpleSurface::Zero()
{
   if (mBase)
      memset(mBase,0,mStride * mHeight);
}

void SimpleSurface::dispose()
{
   destroyHardwareSurface();
   if (mBase)
   {
      if (mBase[mStride * mHeight] != 69)
      {
         ELOG("Image write overflow");
      }
      delete [] mBase;
      mBase = NULL;
   }
}

uint8  *SimpleSurface::Edit(const Rect *inRect)
{
   if (!mBase)
      return 0;

   Rect r = inRect ? inRect->Intersect( Rect(0,0,mWidth,mHeight) ) : Rect(0,0,mWidth,mHeight);
   if (mTexture)
      mTexture->Dirty(r);
   mVersion++;
      return mBase;
}



RenderTarget SimpleSurface::BeginRender(const Rect &inRect,bool inForHitTest)
{
   if (!mBase)
      return RenderTarget();

   Rect r =  inRect.Intersect( Rect(0,0,mWidth,mHeight) );
   if (mTexture)
      mTexture->Dirty(r);
   mVersion++;
   return RenderTarget(r, mPixelFormat,mBase,mStride);
}

void SimpleSurface::EndRender()
{
}

Surface *SimpleSurface::clone()
{
   SimpleSurface *copy = new SimpleSurface(mWidth,mHeight,mPixelFormat);
   int pix_size = BytesPerPixel( mPixelFormat );
   if (mBase)
      for(int y=0;y<mHeight;y++)
         memcpy(copy->mBase + copy->mStride*y, mBase+mStride*y, mWidth*pix_size);
   
   copy->IncRef();
   return copy;
}

void SimpleSurface::getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder, bool inLittleEndian)
{
   if (!mBase)
      return;

   // PixelConvert

   Rect r = inRect.Intersect(Rect(0,0,Width(),Height()));
   if (r.w<1 || r.h<1)
      return;

   ARGB *argb = (ARGB *)outPixels;
   for(int y=0;y<r.h;y++)
   {
      if (mPixelFormat==pfAlpha)
      {
         AlphaPixel *src = (AlphaPixel *)(mBase + (r.y+y)*mStride) + r.x;

         for(int x=0;x<r.w;x++)
            SetPixel(*argb++, *src++);
      }
      else if (mPixelFormat==pfRGB)
      {
         RGB *src = (RGB *)(mBase + (r.y+y)*mStride) + r.x;

         for(int x=0;x<r.w;x++)
            SetPixel(*argb++, *src++);
      }
      else if (mPixelFormat==pfBGRA)
      {
         ARGB *src = (ARGB *)(mBase + (r.y+y)*mStride) + r.x;
         memcpy(argb,src,r.w*4);
         argb+=r.w;
      }
      else if (mPixelFormat==pfBGRPremA)
      {
         BGRPremA *src = (BGRPremA *)(mBase + (r.y+y)*mStride) + r.x;
         for(int x=0;x<r.w;x++)
            SetPixel(*argb++, *src++);
      }
   }

   // Make big-endian...
   if (!inIgnoreOrder && !inLittleEndian)
   {
      unsigned int *argb = (unsigned int *)outPixels;
      int n = r.w*r.h;
      for(int i=0;i<n;i++)
      {
         unsigned int v = argb[i];
         argb[i] =   (v>>24) | ((v>>8)&0x0000ff00) | ((v<<8)&0x00ff0000) | (v<<24);
      }
   }
}

void SimpleSurface::getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect)
{
   outRect = Rect();
   if (!mBase)
      return;

   int w = Width();
   int h = Height();

   if (w==0 || h==0 || mPixelFormat==pfAlpha || mPixelFormat>=pfRenderToCount)
      return;

   if (mPixelFormat==pfRGB && (inMask&0xff000000) && (inCol&0xff000000)!=0xff000000)
      return;

   int min_x = w + 1;
   int max_x = -1;
   int min_y = h + 1;
   int max_y = -1;

   ARGB argb(inCol);
   if (mPixelFormat==pfBGRPremA)
   {
      BGRPremA bgra;
      SetPixel(bgra, argb);
      argb.ival = bgra.ival;
   }
   argb.ival &= inMask;

   for(int y=0;y<h;y++)
   {
      if (mPixelFormat==pfRGB)
      {
         ARGB test;
         RGB *rgb = (RGB *)( mBase + y*mStride);
         for(int x=0;x<w;x++)
         {
            SetPixel(test,*rgb++);
            if ( ((test.ival&inMask)==inCol)==inFind )
            {
               if (x<min_x) min_x=x;
               if (x>max_x) max_x=x;
               if (y<min_y) min_y=y;
               if (y>max_y) max_y=y;
            }
         }

      }
      else
      {
         int *pixel = (int *)( mBase + y*mStride);
         for(int x=0;x<w;x++)
         {
            if ( (((*pixel++)&inMask)==inCol)==inFind )
            {
               if (x<min_x) min_x=x;
               if (x>max_x) max_x=x;
               if (y<min_y) min_y=y;
               if (y>max_y) max_y=y;
            }
         }
      }
   }

   if (min_x>max_x)
      outRect = Rect(0,0,0,0);
   else
      outRect = Rect(min_x,min_y,max_x-min_x+1,max_y-min_y+1);
}


void SimpleSurface::setPixels(const Rect &inRect,const uint32 *inPixels,bool inIgnoreOrder, bool inLittleEndian)
{

   if (!mBase)
      return;
   Rect r = inRect.Intersect(Rect(0,0,Width(),Height()));
   mVersion++;
   if (mTexture)
      mTexture->Dirty(r);

   PixelFormat convert = pfNone;
   if ( !(mFlags & surfFixedPixelFormat) && !HasAlphaChannel(mPixelFormat))
   {
      int n = inRect.w * inRect.h;
      for(int i=0;i<n;i++)
         if ((inPixels[i]&0xff000000) != 0xff000000)
         {
            convert = pfBGRA;
            break;
         }
      if (convert==pfNone && mPixelFormat>=pfRenderToCount)
         convert = pfRGB;
   }
   else if (mPixelFormat>=pfRenderToCount)
      convert = pfBGRA;

   if (convert!=pfNone)
   {
      ChangeInternalFormat(convert, &r);
   }

   const ARGB *src = (const ARGB *)inPixels;
   bool bigEndian = !inIgnoreOrder && !inLittleEndian;

   for(int y=0;y<r.h;y++)
   {
      if (mPixelFormat==pfBGRA)
      {
         ARGB *dest = (ARGB *)(mBase + (r.y+y)*mStride) + r.x;
         if (bigEndian)
         {
            for(int x=0;x<r.w;x++)
            {
               dest->a = src->b;
               dest->r = src->g;
               dest->g = src->r;
               dest->b = src->a;
               dest++;
               src++;
            }
         }
         else
         {
            memcpy(dest, src, r.w*sizeof(ARGB));
            src+=r.w;
         }
      }
      else if (mPixelFormat==pfAlpha)
      {
         AlphaPixel *dest = (AlphaPixel *)(mBase + (r.y+y)*mStride) + r.x;
         if (!bigEndian)
            dest += 3;
         for(int x=0;x<r.w;x++)
         {
            SetPixel(*dest,*src++);
            dest+=4;
         }
      }
      else if (mPixelFormat==pfRGB)
      {
         RGB *dest = (RGB *)(mBase + (r.y+y)*mStride) + r.x;
         if (bigEndian)
         {
            for(int x=0;x<r.w;x++)
            {
               dest->r = src->g;
               dest->g = src->r;
               dest->b = src->a;
               src++;
               dest++;
            }
         }
         else
            for(int x=0;x<r.w;x++)
               SetPixel(*dest++,*src++);
      }
      else if (mPixelFormat==pfBGRPremA)
      {
         BGRPremA *dest = (BGRPremA *)(mBase + (r.y+y)*mStride) + r.x;
         if (bigEndian)
         {
            for(int x=0;x<r.w;x++)
            {
               const Uint8 *aLut = gPremAlphaLut[dest->a = src->b];
               dest->r = aLut[src->g];
               dest->g = aLut[src->r];
               dest->b = aLut[src->a];
               dest++;
               src++;
            }
         }
         else
            for(int x=0;x<r.w;x++)
               SetPixel(*dest++,*src++);
      }
   }
}

uint32 SimpleSurface::getPixel(int inX,int inY)
{
   if (inX<0 || inY<0 || inX>=mWidth || inY>=mHeight || !mBase)
      return 0;

   ARGB result(0xff000000);
   void *ptr = mBase + inY*mStride;
   switch(mPixelFormat)
   {
      case pfRGB: SetPixel(result, ((RGB *)ptr)[inX]); break;
      case pfBGRA: SetPixel(result, ((ARGB *)ptr)[inX]); break;
      case pfBGRPremA: SetPixel(result, ((BGRPremA *)ptr)[inX]); break;
      case pfAlpha: SetPixel(result, ((AlphaPixel *)ptr)[inX]); break;

      default: ;
      /* TODO
      case pfARGB4444:
      case pfRGB565:
      case pfLuma:
      case pfLumaAlpha:
      case pfECT:
      case pfRGB32f:
      case pfRGBA32f:
      case pfYUV420sp:
      case pfNV12:
      case pfOES:
      */
   }


   return result.ival;
}

void SimpleSurface::setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo)
{
   if (inX<0 || inY<0 || inX>=mWidth || inY>=mHeight || !mBase)
      return;

   mVersion++;
   if (mTexture)
      mTexture->Dirty(Rect(inX,inY,1,1));

   if (inAlphaToo && ((inRGBA&0xff000000)!=0xff000000) && !HasAlphaChannel(mPixelFormat) )
      ChangeInternalFormat(pfBGRA);

   ARGB value(inRGBA);
   void *ptr = mBase + inY*mStride;
   switch(mPixelFormat)
   {
      case pfRGB: SetPixel(((RGB *)ptr)[inX],value); break;
      case pfBGRA: SetPixel(((ARGB *)ptr)[inX],value); break;
      case pfBGRPremA: SetPixel(((BGRPremA *)ptr)[inX],value); break;
      case pfAlpha: SetPixel(((AlphaPixel *)ptr)[inX],value); break;

      default: ;
      /* TODO
      case pfARGB4444:
      case pfRGB565:
      case pfLuma:
      case pfLumaAlpha:
      case pfECT:
      case pfRGB32f:
      case pfRGBA32f:
      case pfYUV420sp:
      case pfNV12:
      case pfOES:
      */
   }
}

void SimpleSurface::scroll(int inDX,int inDY)
{
   if ((inDX==0 && inDY==0) || !mBase) return;

   Rect src(0,0,mWidth,mHeight);
   src = src.Intersect( src.Translated(inDX,inDY) ).Translated(-inDX,-inDY);
   int pixels = src.Area();
   if (!pixels)
      return;

   uint32 *buffer = (uint32 *)malloc( pixels * sizeof(int) );
   getPixels(src,buffer,true);
   src.Translate(inDX,inDY);
   setPixels(src,buffer,true);
   free(buffer);
   mVersion++;
   if (mTexture)
      mTexture->Dirty(src);
}

void SimpleSurface::applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter)
{
   if (!mBase) return;
   FilterList f;
   f.push_back(inFilter);

   Rect src_rect(inRect.w,inRect.h);
   Rect dest = GetFilteredObjectRect(f,src_rect);

   inSrc->IncRef();
   Surface *result = FilterBitmap(f, inSrc, src_rect, dest, false, false, ImagePoint(inRect.x,inRect.y) );

   dest.Translate(inOffset.x, inOffset.y);

   src_rect = Rect(0,0,result->Width(),result->Height());
   int dx = dest.x;
   int dy = dest.y;
   dest = dest.Intersect( Rect(0,0,mWidth,mHeight) );
   dest.Translate(-dx,-dy);
   dest = dest.Intersect( src_rect );
   dest.Translate(dx,dy);

   int bpp = BytesPP();

   RenderTarget t = BeginRender(dest,false);
   //printf("Copy back @ %d,%d %dx%d  + (%d,%d)\n", dest.x, dest.y, t.Width(), t.Height(), dx, dy);
   for(int y=0;y<t.Height();y++)
      memcpy((void *)(t.Row(y+dest.y)+(dest.x)*bpp), result->Row(y-dy)-dx*bpp, dest.w*bpp);

   EndRender();

   result->DecRef();
}

/* A MINSTD pseudo-random number generator.
 *
 * This generates a pseudo-random number sequence equivalent to std::minstd_rand0 from the C++11 standard library, which
 * is the generator that Flash uses to generate noise for BitmapData.noise().
 *
 * It is reimplemented here because std::minstd_rand0 is not available in earlier versions of C++.
 *
 * MINSTD was originally suggested in "A pseudo-random number generator for the System/360", P.A. Lewis, A.S. Goodman,
 * J.M. Miller, IBM Systems Journal, Vol. 8, No. 2, 1969, pp. 136-146 */
class MinstdGenerator
{
public:
   MinstdGenerator(unsigned int seed)
   {
      if (seed == 0) {
         x = 1U;
      } else {
         x = seed;
      }
   }

   unsigned int operator () ()
   {
      const unsigned int a = 16807U;
      const unsigned int m = (1U << 31) - 1;

      unsigned int lo = a * (x & 0xffffU);
      unsigned int hi = a * (x >> 16);
      lo += (hi & 0x7fffU) << 16;

      if (lo > m)
      {
         lo &= m;
         ++lo;
      }

      lo += hi >> 15;

      if (lo > m)
      {
         lo &= m;
         ++lo;
      }

      x = lo;

      return x;
   }

private:
   unsigned int x;
};

void SimpleSurface::noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale)
{
   if (!mBase)
      return;

   MinstdGenerator generator(randomSeed);

   RenderTarget target = BeginRender(Rect(0,0,mWidth,mHeight),false);
   ARGB tmpRgb;

   int range = high - low + 1;

   for (int y=0;y<mHeight;y++)
   {
      ARGB *rgb = ((ARGB *)target.Row(y));
      for(int x=0;x<mWidth;x++)
      {
         if (grayScale)
         {
            tmpRgb.r = tmpRgb.g = tmpRgb.b = low + generator() % (high - low + 1);
         }
         else
         {
            if (channelOptions & CHAN_RED)
               tmpRgb.r = low + generator() % range;
            else
               tmpRgb.r = 0;

            if (channelOptions & CHAN_GREEN)
               tmpRgb.g = low + generator() % range;
            else
               tmpRgb.g = 0;

            if (channelOptions & CHAN_BLUE)
               tmpRgb.b = low + generator() % range;
            else
               tmpRgb.b = 0;
         }

         if (channelOptions & CHAN_ALPHA)
            tmpRgb.a = low + generator() % range;
         else
            tmpRgb.a = 255;

         *rgb = tmpRgb;

         rgb++;
      }
   }
   
   EndRender();
}

void SimpleSurface::encodeStream(ObjectStreamOut &stream)
{
   stream.addInt(mWidth);
   stream.addInt(mHeight);
   stream.addInt((int)mPixelFormat);
   stream.data.append(mBase,GetBufferSize());
}


SimpleSurface *SimpleSurface::fromStream(ObjectStreamIn &inStream)
{
   int w = inStream.getInt();
   int h = inStream.getInt();
   PixelFormat pf = (PixelFormat)inStream.getInt();

   SimpleSurface *result = new SimpleSurface(w,h,pf);
   inStream.linkAbstract(result);
   int bytes = result->GetBufferSize();
   memcpy(result->mBase, inStream.getBytes( bytes ), bytes);
   return result;
}

enum
{
   FloatZeroMean   = 0x0001,
   Float128Mean    = 0x0002,
   FloatUnitScale  = 0x0004,
   FloatStdScale   = 0x0008,
   FloatSwizzeRgb  = 0x0010,
   Float100Scale  = 0x0020,
};


void SimpleSurface::getFloats32(float *outData, int inStride, PixelFormat inFormat, int inTransform, int inSubsample,const Rect &bounds)
{
   int pixelSize = BytesPerPixel(inFormat);

   std::vector<unsigned char> buffer;
   const unsigned char *ptr = mBase + mStride*bounds.y + bounds.x*BytesPerPixel(mPixelFormat);
   int w = bounds.w;
   int h = bounds.h;
   // TODO - inSubsample
   int stride = mStride;
   if (inFormat!=mPixelFormat)
   {
      stride = w * pixelSize;
      buffer.resize( stride * h );
      PixelConvert(w, h,
          mPixelFormat,  ptr, mStride, GetPlaneOffset(),
          inFormat, &buffer[0], stride, 0 );
      ptr = &buffer[0];
   }
   bool swizzleRgb = (inTransform & FloatSwizzeRgb );

   int histo[256];
   int ppr = w * pixelSize;
   int count = ppr*h;

   if ( inTransform & (FloatZeroMean | FloatStdScale) )
   {
      memset(histo, 0, sizeof(histo));
      for(int y=0;y<h;y++)
      {
         const Uint8 *p = ptr + y*stride;
         for(int x=0;x<ppr;x++)
            histo[p[x]]++;
      }
   }
   float lut[256];

   if (!inTransform)
   {
      for(int i=0;i<256;i++)
         lut[i] = i;
   }
   else if ( (inTransform & FloatUnitScale) && !(inTransform & FloatZeroMean) )
   {
      if (inTransform & Float128Mean)
         for(int i=0;i<256;i++)
            lut[i] = (double)(i-128)/255.0;
      else
         for(int i=0;i<256;i++)
            lut[i] = (double)i/255.0;
   }
   else
   {
      double mean = 0;
      if (inTransform & Float128Mean)
      {
         mean = 128.0;
      }
      else if (inTransform & FloatZeroMean)
      {
         double sum = 0;
         for(int i=0;i<256;i++)
            sum+=histo[i]*i;
         mean = (double)sum/count;
      }

      double scale = 1;
      if (inTransform & FloatUnitScale)
      {
         scale = 1.0/255;
      }
      else if (inTransform & Float100Scale)
      {
         scale = 0.01;
      }
      else if (inTransform & FloatStdScale)
      {
         double sumSig2 = 0;
         for(int i=0;i<256;i++)
            sumSig2 += (i-mean)*(i-mean)*histo[i];
         if (sumSig2>0)
            scale = sqrt(count/sumSig2);
      }


      for(int i=0;i<256;i++)
         lut[i] = (i-mean)*scale;
   }

   float *dest = outData;
   for(int y=0;y<h;y++)
   {
      const Uint8 *src = ptr + y*stride;
      if (inStride)
         dest = (float *)( (char *)outData + inStride*y );

      if (swizzleRgb && inFormat==pfRGB)
      {
        for(int x=0;x<w;x++)
        {
           *dest++ = lut[src[2]];
           *dest++ = lut[src[1]];
           *dest++ = lut[src[0]];
           src+=3;
        }
      }
      else
        for(int x=0;x<ppr;x++)
           *dest++ = lut[*src++];
   }
}




void SimpleSurface::getUInts8(uint8 *outData, int inStride, PixelFormat inFormat, int inSubsample)
{
   // TODO - inSubsample
   int pixelSize = BytesPerPixel(inFormat);
   int stride = inStride==0 ? pixelSize*mWidth : inStride;
   if (inFormat!=mPixelFormat)
   {
      PixelConvert(mWidth, mHeight,
          mPixelFormat,  mBase, mStride, GetPlaneOffset(),
          inFormat, outData, stride, 0 );
   }
   else if (stride==mStride)
   {
      memcpy(outData, mBase, mWidth*mHeight*pixelSize );
   }
   else
   {
      for(int y=0;y<mHeight;y++)
         memcpy(outData+stride*y, mBase+mStride*y, mWidth*pixelSize );
   }
}


void SimpleSurface::setUInts8(const uint8 *inData, int inStride, PixelFormat inFormat, int inExpand)
{
   // TODO - inExpand
   int pixelSize = BytesPerPixel(inFormat);
   int stride = inStride==0 ? pixelSize*mWidth : inStride;

   if (inFormat!=mPixelFormat)
   {
      PixelConvert(mWidth, mHeight,
          inFormat, inData, stride, 0,
          mPixelFormat,  mBase, mStride, GetPlaneOffset());
   }
   else if (stride==mStride)
   {
      memcpy(mBase, inData, mWidth*mHeight*pixelSize );
   }
   else
   {
      for(int y=0;y<mHeight;y++)
         memcpy(mBase+mStride*y, inData+stride*y, mWidth*pixelSize );
   }

   if (mTexture)
      mTexture->Dirty(Rect(0,0,mWidth,mHeight));
}




void SimpleSurface::setFloats32(const float *inData, int inStride, PixelFormat inFormat, int inTransform, int inExpand,const Rect &bounds)
{
   Uint8 *ptr = mBase + mStride*bounds.y + bounds.x*BytesPerPixel(mPixelFormat);
   int w = bounds.w;
   int h = bounds.h;

   std::vector<unsigned char> buffer;
   // TODO - inExpand

   int stride = mStride;
   int pixelSize = BytesPerPixel(inFormat);

   if (inFormat!=mPixelFormat)
   {
      stride = w * pixelSize;
      buffer.resize( stride * h );
      ptr = &buffer[0];
   }
   int ppr = w * pixelSize;

   const float *src = inData;
   #define GET_FLOAT( EXPR ) { \
         for(int y=0;y<h;y++) \
         { \
            Uint8 *dest = ptr + y*stride; \
            if (inStride) \
               src = (const float *)( (char *)inData + y*inStride ); \
            for(int x=0;x<ppr;x++) \
            { \
               float fval = EXPR ; \
               *dest++ = fval < 0.0f ? 0 : fval>=255.0f ? 255 : (int)fval; \
            } \
         } \
      }




   if (inTransform & Float128Mean)
   {
      if (inTransform & FloatUnitScale)
         GET_FLOAT( *src++ * 255.0f + 128.0f )
      else
         GET_FLOAT( *src++ + 128.0f )
   }
   else
   {
      if (inTransform & FloatUnitScale)
         GET_FLOAT( *src++ * 255.0f  )
      else
         GET_FLOAT( *src++  )
   }


   if (inFormat!=mPixelFormat)
   {
      PixelConvert(w, h,
          inFormat,  &buffer[0], stride, 0,
          mPixelFormat, ptr, mStride, 0 );
   }

   if (mTexture)
      mTexture->Dirty(bounds);
}





// --- HardwareSurface -------------------------------------------------------------

HardwareSurface::HardwareSurface(HardwareRenderer *inContext)
{
   mHardware = inContext;
   mHardware->IncRef();
}

HardwareSurface::~HardwareSurface()
{
   mHardware->DecRef();
}

Surface *HardwareSurface::clone()
{
   // This is not really a clone...
   Surface *copy = new HardwareSurface(mHardware);
   copy->IncRef();
   return copy;

}

void HardwareSurface::getPixels(const Rect &inRect, uint32 *outPixels,bool inIgnoreOrder)
{
   memset(outPixels,0,Width()*Height()*4);
}

void HardwareSurface::setPixels(const Rect &inRect,const uint32 *outPixels,bool inIgnoreOrder)
{
}



// --- BitmapCache -----------------------------------------------------------------

const uint8 *BitmapCache::Row(int inRow) const
{
   return mBitmap->Row(inRow);
}


const uint8 *BitmapCache::DestRow(int inRow) const
{
   return mBitmap->Row(inRow-(mRect.y+mTY)) - mBitmap->BytesPP()*(mRect.x+mTX);
}


PixelFormat BitmapCache::Format() const
{
   return mBitmap->Format();
}

} // end namespace nme

