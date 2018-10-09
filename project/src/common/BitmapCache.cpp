#include <Display.h>
#include <Surface.h>
#include <math.h>

#ifdef ANDROID
#include <android/log.h>
#endif

namespace nme
{

// --- BitmapCache ---------------------------------------------------------

static int sBitmapVersion = 1;

BitmapCache::BitmapCache(Surface *inSurface,const Transform &inTrans,
                         const Rect &inRect,bool inMaskOnly, BitmapCache *inMask)
{
   mBitmap = inSurface->IncRef();
   mMatrix = *inTrans.mMatrix;
   mScale9 = *inTrans.mScale9;
   mRect = inRect;
   mLastHardwareSrc = Rect(-1,-1,-1,-1);
   mVersion = sBitmapVersion++;
   if (!mVersion)
      mVersion = sBitmapVersion++;
   mMaskVersion = inMask ? inMask->mVersion : 0;
   mMaskOffset = inMask ? ImagePoint(inMask->mTX,inMask->mTY) : ImagePoint(0,0);
   mTX = mTY = 0;
   mHardwareBuffer = 0;
}

BitmapCache::~BitmapCache()
{
   delete mHardwareBuffer;
   mBitmap->DecRef();
}


bool BitmapCache::StillGood(const Transform &inTransform, const Rect &inVisiblePixels, BitmapCache *inMask)
{
   if  (!mMatrix.IsIntTranslation(*inTransform.mMatrix,mTX,mTY) || mScale9!=*inTransform.mScale9)
      return false;

   if (inMask)
   {
      if (inMask->mVersion!=mMaskVersion)
         return false;
      if (mMaskOffset != ImagePoint(inMask->mTX, inMask->mTY) )
         return false;
   }
   else if (mMaskVersion)
      return false;

   // Translate our cached pixels to this new position ...
   Rect translated = mRect.Translated(mTX,mTY);
   if (translated.Contains(inVisiblePixels))
      return true;

   return false;
}


void BitmapCache::Render(const RenderTarget &inTarget,const Rect &inClipRect, const BitmapCache *inMask,BlendMode inBlend)
{
   if (mBitmap)
   {
      int tint = 0xffffffff;
      if (inTarget.mPixelFormat!=pfAlpha && mBitmap->Format()==pfAlpha)
         tint = 0xff000000;


      // mRect = rectangle that was captured (target pixel coordinates)
      // mTX,mTY = how much it has moved

      Rect src( mRect.x+mTX, mRect.y+mTY, mRect.w, mRect.h);
      int ox = src.x;
      int oy = src.y;
      src = src.Intersect(inClipRect);
      if (!src.HasPixels())
         return;
      // offset due to clipping
      ox -= src.x;
      oy -= src.y;
      // src pixels rectangle, realtive to captured surface
      src.Translate(-mRect.x - mTX,-mRect.y-mTY);


      if (inTarget.IsHardware())
      {
         if (!mHardwareBuffer)
         {
            mHardwareBuffer = new HardwareData();
            mHardwareBuffer->mElements.resize(1);
            DrawElement &e = mHardwareBuffer->mElements[0];
            memset(&e,0,sizeof(DrawElement));
            e.mCount = 4;
            e.mFlags = DRAW_HAS_TEX;
            e.mPrimType = ptTriangleStrip;
            e.mVertexOffset = 0;
            e.mColour = tint;
            e.mTexOffset = sizeof(float)*2;
            e.mStride = sizeof(float)*4;

            e.mSurface = mBitmap;
            e.mSurface->IncRef();
            e.mBlendMode = bmNormal;

            // for off-pixel caches?
            e.mFlags |= DRAW_BMP_SMOOTH;

            mHardwareBuffer->mArray.resize( e.mCount * e.mStride );
         }

         if (src!=mLastHardwareSrc)
         {
            mLastHardwareSrc = src;
            UserPoint *p = (UserPoint *)&mHardwareBuffer->mArray[0];

            Texture *tex = mBitmap->GetTexture(inTarget.mHardware);
            for(int i=0;i<4;i++)
            {
               p[0] = UserPoint(src.x + ((i&1)?src.w:0), src.y + ((i>1)?src.h:0) ); 
               p[1] = tex->PixelToTex( p[0] );
               p+=2;
            }
            mHardwareBuffer->releaseVbo();
         }

         int destX = mRect.x+mTX;
         int destY = mRect.y+mTY;

         const Rect vp = inTarget.mRect;
         inTarget.mHardware->SetViewport(vp);
         // Pixel co-ordinates...
         Trans4x4 trans;
         memset(&trans,0,sizeof(trans));


         int x0 = vp.x;
         int x1 = vp.x1();
         // upside-down
         int y0 = vp.y1();
         int y1 = vp.y;
         double mScaleX = 2.0/(x1-x0);
         double mScaleY = 2.0/(y1-y0);
         double mOffsetX = (x0+x1)/(x0-x1);
         double mOffsetY = (y0+y1)/(y0-y1);

         trans[0][0] = mScaleX;
         trans[0][3] = mOffsetX + destX*mScaleX;
         trans[1][1] = mScaleY;
         trans[1][3] = mOffsetY + destY*mScaleY;
         trans[2][2] = 1;
         trans[3][3] = 1;

         inTarget.mHardware->RenderData(*mHardwareBuffer,0,trans);
      }
      else
      {
         // TX,TX is set in StillGood function
         mBitmap->BlitTo(inTarget, src, mRect.x+mTX-ox, mRect.y+mTY-oy,inBlend,inMask,tint);
      }
   }
}

void BitmapCache::PushTargetOffset(const ImagePoint &inOffset, ImagePoint &outBuffer)
{
   outBuffer = ImagePoint(mTX,mTY);
   mTX -= inOffset.x;
   mTY -= inOffset.y;
}

void BitmapCache::PopTargetOffset(ImagePoint &inBuffer)
{
   mTX = inBuffer.x;
   mTY = inBuffer.y;
}


bool BitmapCache::HitTest(double inX, double inY)
{
   double x0 = mRect.x+mTX;
   double y0 = mRect.y+mTY;
   //printf("BMP hit %f,%f    %f,%f ... %d,%d\n", inX, inY, x0,y0, mRect.w, mRect.h );
   return x0<=inX && y0<=inY && (inX<=x0+mRect.w) && (inY<=y0+mRect.h);
}



} // end namespace nme

