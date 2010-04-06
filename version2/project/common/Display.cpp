#include <Display.h>
#include <Surface.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.1415926535897932385
#endif

namespace nme
{

unsigned int gDisplayRefCounting = drDisplayChildRefs;
static int sgDisplayObjID = 0;

bool gMouseShowCursor = true;

// --- DisplayObject ------------------------------------------------

DisplayObject::DisplayObject(bool inInitRef) : Object(inInitRef)
{
   mParent = 0;
   mGfx = 0;
   mDirtyFlags = 0;
   x = y = 0;
   scaleX = scaleY = 1.0;
   rotation = 0;
   visible = true;
   mBitmapCache = 0;
   cacheAsBitmap = false;
   blendMode = bmNormal;
   opaqueBackground = 0;
   mouseEnabled = true;
   mMask = 0;
   mIsMaskCount = 0;
   mBitmapGfx = 0;
   id = sgDisplayObjID++ & 0x7fffffff;
   if (id==0)
      id = sgDisplayObjID++;
}

DisplayObject::~DisplayObject()
{
   if (mGfx)
      mGfx->DecRef();
   delete mBitmapCache;
   if (mMask)
      setMask(0);
   ClearFilters();
}

Graphics &DisplayObject::GetGraphics()
{
   if (!mGfx)
   {
      mGfx = new Graphics(true);
   }
   return *mGfx;
}

bool DisplayObject::IsCacheDirty()
{
   if (mDirtyFlags & dirtCache)
      return true;
   return mGfx && mGfx->Version() != mBitmapGfx;
}

void DisplayObject::ClearCacheDirty()
{
   mDirtyFlags &= ~dirtCache;
}



void DisplayObject::SetParent(DisplayObjectContainer *inParent)
{
   IncRef();

   if (gDisplayRefCounting &drDisplayChildRefs)
   {
      if (mParent && !inParent)
         DecRef();
      else if (!mParent && inParent)
         IncRef();
   }

   if (mParent)
   {
      Stage *stage = getStage();
      if (stage)
         stage->RemovingFromStage(this);
      mParent->RemoveChildFromList(this);
      mParent->DirtyCache();
   }
   DirtyUp(dirtCache);

   mParent = inParent;

   DecRef();
}

DisplayObject *DisplayObject::getParent()
{
   return mParent;
}

Stage  *DisplayObject::getStage()
{
   if (!mParent)
      return 0;
   return mParent->getStage();
}



UserPoint DisplayObject::GlobalToLocal(const UserPoint &inPoint)
{
   // TODO:
   return inPoint;
}

void DisplayObject::setCacheAsBitmap(bool inVal)
{
   cacheAsBitmap = inVal;
}

void DisplayObject::setVisible(bool inVal)
{
   visible = inVal;
   DirtyCache(!visible);
}




void DisplayObject::CheckCacheDirty()
{
   if (IsCacheDirty())
   {
      if (mBitmapCache)
      {
         delete mBitmapCache;
         mBitmapCache = 0;
      }
   }

   if (!IsBitmapRender() && !IsMask() && mBitmapCache)
   {
      delete mBitmapCache;
      mBitmapCache = 0;
   }
}

bool DisplayObject::IsBitmapRender()
{
   return cacheAsBitmap || blendMode!=bmNormal || NonNormalBlendChild() || filters.size();
}

void DisplayObject::SetBitmapCache(BitmapCache *inCache)
{
   delete mBitmapCache;
   mBitmapCache = inCache;
}




void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (mGfx && inState.mPhase!=rpBitmap)
   {
      bool hit = false;
      if (scale9Grid.HasPixels())
      {
         RenderState state(inState);

         const Extent2DF &ext0 = mGfx->GetExtent0(0);
         Scale9 s9;
         s9.Activate(scale9Grid,ext0,scaleX,scaleY);
         state.mTransform.mScale9 = &s9;

         Matrix unscaled = state.mTransform.mMatrix->Mult( Matrix(1.0/scaleX,1.0/scaleY) );
         state.mTransform.mMatrix = &unscaled;

         hit = mGfx->Render(inTarget,state);
         inState.mHitResult = state.mHitResult;
      }
      else
      {
         hit = mGfx->Render(inTarget,inState);
      }

      if (hit)
         inState.mHitResult = this;
   }
}


bool DisplayObject::HitBitmap( const RenderTarget &inTarget, const RenderState &inState )
{
   if (!mBitmapCache)
      return false;
   return mBitmapCache->HitTest(inState.mClipRect.x, inState.mClipRect.y);
}

void DisplayObject::RenderBitmap( const RenderTarget &inTarget, const RenderState &inState )
{
   if (!mBitmapCache)
      return;

   RenderTarget t = inTarget.ClipRect( inState.mClipRect );
   mBitmapCache->Render(inTarget,inState.mMask,blendMode);
   mBitmapGfx = mGfx ? mGfx->Version() : 0;
}

void DisplayObject::DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState )
{
   if (mMask)
      mMask->RenderBitmap(inTarget,inState);
}



void DisplayObject::DirtyUp(uint32 inFlags)
{
   mDirtyFlags |= inFlags;
}


void DisplayObject::DirtyCache(bool inParentOnly)
{
   if (!inParentOnly)
      mDirtyFlags |= dirtCache;
   else if (mParent)
      mParent->DirtyCache(false);
}

Matrix DisplayObject::GetFullMatrix()
{
  if (mParent)
     return mParent->GetFullMatrix().Mult(GetLocalMatrix());
  return GetLocalMatrix();
}

Matrix &DisplayObject::GetLocalMatrix()
{
   if (mDirtyFlags & dirtLocalMatrix)
   {
      mDirtyFlags ^= dirtLocalMatrix;
      double r = rotation*M_PI/-180.0;
      double c = cos(r);
      double s = sin(r);
      mLocalMatrix.m00 = c*scaleX;
      mLocalMatrix.m01 = s*scaleY;
      mLocalMatrix.m10 = -s*scaleX;
      mLocalMatrix.m11 = c*scaleY;
      mLocalMatrix.mtx = x;
      mLocalMatrix.mty = y;
   }
   return mLocalMatrix;
}

void DisplayObject::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen)
{
   if (mGfx)
      outExt.Add(mGfx->GetSoftwareExtent(inTrans));
}




void DisplayObject::UpdateDecomp()
{
   if (mDirtyFlags & dirtDecomp)
   {
      mDirtyFlags ^= dirtDecomp;
      x = mLocalMatrix.mtx;
      y = mLocalMatrix.mty;
      scaleX = sqrt( mLocalMatrix.m00*mLocalMatrix.m00 +
                     mLocalMatrix.m10*mLocalMatrix.m10 );
      scaleY = sqrt( mLocalMatrix.m01*mLocalMatrix.m01 +
                     mLocalMatrix.m11*mLocalMatrix.m11 );
      rotation = scaleX>0 ? atan2( mLocalMatrix.m01, mLocalMatrix.m00 ) :
                 scaleY>0 ? atan2( mLocalMatrix.m11, mLocalMatrix.m10 ) : 0.0;
      //printf("Rotation = %f\n",rotation);
      /*
      scaleX = cos(rotation) * mLocalMatrix.m00 +
               -sin(rotation) * mLocalMatrix.m10;
      scaleY = sin(rotation) * mLocalMatrix.m01 + 
               cos(rotation) * mLocalMatrix.m11;
               */
      //printf("scale = %f,%f\n", scaleX, scaleY );
      rotation *= 180.0/-M_PI;
   }
}

double DisplayObject::getMouseX()
{
	Stage *s = getStage();
	if (!s)
		return 0;
	UserPoint p = s->getMousePos();
	UserPoint result = GetFullMatrix().ApplyInverse(p);
   return result.x;
}

double DisplayObject::getMouseY()
{
	Stage *s = getStage();
	if (!s)
		return 0;
	UserPoint p = s->getMousePos();
	UserPoint result = GetFullMatrix().ApplyInverse(p);
   return result.y;
}




double DisplayObject::getX()
{
   UpdateDecomp();
   return x;
}

void DisplayObject::setX(double inValue)
{
   UpdateDecomp();
   if (x!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      x = inValue;
      DirtyCache(true);
   }
}


void DisplayObject::setScaleX(double inValue)
{
   UpdateDecomp();
   if (scaleX!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      scaleX = inValue;
      DirtyCache();
   }
}

double DisplayObject::getScaleX()
{
   UpdateDecomp();
   return scaleX;
}


void DisplayObject::setWidth(double inValue)
{
   Transform trans0;
   Matrix rot;
   if (rotation)
      rot.Rotate(rotation);
   trans0.mMatrix = &rot;
   Extent2DF ext0;
   GetExtent(trans0,ext0,false);

   if (!ext0.Valid())
      return;
   if (ext0.Width()==0)
      return;

   scaleX = inValue/ext0.Width();
   scaleY = ext0.Height()==0.0 ? 1.0 : getHeight() / ext0.Height();
   mDirtyFlags |= dirtLocalMatrix;
}

double DisplayObject::getWidth()
{
   Transform trans;
   trans.mMatrix = &GetLocalMatrix();
   Extent2DF ext;
   GetExtent(trans,ext,false);

   if (!ext.Valid())
   {
      return 0;
   }

   return ext.Width();
}


void DisplayObject::setHeight(double inValue)
{
   Transform trans0;
   Matrix rot;
   if (rotation)
      rot.Rotate(rotation);
   trans0.mMatrix = &rot;
   Extent2DF ext0;
   GetExtent(trans0,ext0,false);

   if (!ext0.Valid())
      return;
   if (ext0.Height()==0)
      return;

   scaleX = ext0.Width()==0.0 ? 1.0 : getWidth() / ext0.Width();
   scaleY = inValue/ext0.Height();
   mDirtyFlags |= dirtLocalMatrix;
}

double DisplayObject::getHeight()
{
   Transform trans;
   trans.mMatrix = &GetLocalMatrix();
   Extent2DF ext;
   GetExtent(trans,ext,false);
   if (!ext.Valid())
      return 0;

   return ext.Height();
}


double DisplayObject::getScaleY()
{
   UpdateDecomp();
   return scaleY;
}



double DisplayObject::getY()
{
   UpdateDecomp();
   return y;
}

void DisplayObject::setY(double inValue)
{
   UpdateDecomp();
   if (y!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      y = inValue;
      DirtyCache(true);
   }
}

void DisplayObject::setScaleY(double inValue)
{
   UpdateDecomp();
   if (scaleY!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      scaleY = inValue;
      DirtyCache();
   }
}

void DisplayObject::setScale9Grid(const DRect &inRect)
{
   scale9Grid = inRect;
   DirtyCache();
}

void DisplayObject::setScrollRect(const DRect &inRect)
{
   scrollRect = inRect;
   UpdateDecomp();
   mDirtyFlags |= dirtLocalMatrix;
   DirtyCache();
}



double DisplayObject::getRotation()
{
   UpdateDecomp();
   return rotation;
}

void DisplayObject::setRotation(double inValue)
{
   UpdateDecomp();
   if (rotation!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      rotation = inValue;
      DirtyCache();
   }
}


void DisplayObject::ChangeIsMaskCount(int inDelta)
{
   if (inDelta>0)
   {
      IncRef();
      mIsMaskCount++;
   }
   else
   {
      mIsMaskCount--;
      if (!mIsMaskCount)
         SetBitmapCache(0);
      DecRef();
   }
}


void DisplayObject::setMask(DisplayObject *inMask)
{
   if (inMask)
      inMask->ChangeIsMaskCount(1);
   if (mMask)
      mMask->ChangeIsMaskCount(-1);

   mMask = inMask;
   DirtyCache();
}

void DisplayObject::setAlpha(double inAlpha)
{
   colorTransform.alphaScale = inAlpha;
   colorTransform.alphaOffset = 0;
   DirtyCache();
}

void DisplayObject::setFilters(FilterList &inFilters)
{
   ClearFilters();
   filters = inFilters;
   DirtyCache();
}

void DisplayObject::setOpaqueBackground(uint32 inBG)
{
   opaqueBackground = inBG;
   DirtyCache();
}


void DisplayObject::ClearFilters()
{
   for(int i=0;i<filters.size();i++)
      delete filters[i];
   filters.resize(0);
}

// --- DisplayObjectContainer ------------------------------------------------

DisplayObjectContainer::~DisplayObjectContainer()
{
   // asset mChildren.size()==0
}

void DisplayObjectContainer::RemoveChildFromList(DisplayObject *inChild)
{
   for(int i=0;i<mChildren.size();i++)
      if (inChild==mChildren[i])
      {
         if (gDisplayRefCounting & drDisplayParentRefs)
            DecRef();
         mChildren.EraseAt(i);
         return;
      }
   // This is an error, I think.
   return;
}

void DisplayObjectContainer::setChildIndex(DisplayObject *inChild,int inNewIndex)
{
   for(int i=0;i<mChildren.size();i++)
      if (inChild==mChildren[i])
      {
         if (inNewIndex<i)
         {
            while(i > inNewIndex)
            {
               mChildren[i] = mChildren[i-1];
               i--;
            }
         }
         // move up ...
         else if (i<inNewIndex)
         {
            while(i < inNewIndex)
            {
               mChildren[i] = mChildren[i+1];
               i++;
            }
         }
         mChildren[inNewIndex] = inChild;
         DirtyCache();
         return;
      }
   // This is an error, I think.
   return;

}


void DisplayObjectContainer::removeChild(DisplayObject *inChild)
{
   IncRef();
   inChild->SetParent(0);
   DecRef();
}

void DisplayObjectContainer::removeChildAt(int inIndex)
{
   if (inIndex>=0 && inIndex<mChildren.size())
      removeChild( mChildren[inIndex] );
}


void DisplayObjectContainer::addChild(DisplayObject *inChild,bool inTakeRef)
{
   //printf("DisplayObjectContainer::addChild\n");
   IncRef();
   inChild->SetParent(this);

   mChildren.push_back(inChild);
   if (gDisplayRefCounting & drDisplayParentRefs)
      IncRef();

   if (!inTakeRef)
      DecRef();
}

void DisplayObjectContainer::DirtyUp(uint32 inFlags)
{
   mDirtyFlags |= inFlags;
   for(int i=0;i<mChildren.size();i++)
      mChildren[i]->DirtyUp(inFlags);
}


void DisplayObjectContainer::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   Rect visible_bitmap;

   // Render parent first (or at the end) ?
   if (inState.mPhase==rpRender)
      DisplayObject::Render(inTarget,inState);

   // Render children/build child bitmaps ...
   Matrix full;
   ColorTransform col_trans;
   RenderState state(inState);
   state.mTransform.mMatrix = &full;
   RenderState clip_state(state);

   int first = 0;
   int last = mChildren.size();
   int dir = 1;
   // Build top first when making bitmaps and masks, or doing hit test...
   if (inState.mPhase!=rpRender)
   {
      first = last - 1;
      last = -1;
      dir = -1;
   }
   for(int i=first; i!=last; i+=dir)
   {
      DisplayObject *obj = mChildren[i];
      //printf("Render phase = %d, parent = %d, child = %d\n", inState.mPhase, id, obj->id);
      if (!obj->visible || (inState.mPhase!=rpBitmap && obj->IsMask()) ||
         (inState.mPhase==rpHitTest && !obj->mouseEnabled) )
      {
         continue;
      }

      RenderState *obj_state = &state;
      full = inState.mTransform.mMatrix->Mult( obj->GetLocalMatrix() );

      if (obj->scrollRect.HasPixels())
      {
         Extent2DF extent;
         DRect rect = obj->scrollRect;
         for(int c=0;c<4;c++)
            extent.Add( full.Apply( rect.x + (((c&1)>0) ? rect.w :0),
                                      rect.y + (((c&2)>0) ? rect.h :0) ) );



         Rect screen_rect(extent.mMinX,extent.mMinY, extent.mMaxX, extent.mMaxY, true );

         full.TranslateData(-obj->scrollRect.x, -obj->scrollRect.y );

         clip_state.mClipRect = clip_state.mClipRect.Intersect(screen_rect);

         if (!clip_state.mClipRect.HasPixels())
            continue;
      
         obj_state = &clip_state;
      }


      if (inState.mPhase==rpBitmap)
      {
         //printf("Bitmap phase %d\n", obj->id);
         obj->CheckCacheDirty();

         if (obj->IsBitmapRender() || obj->IsMask())
         {
            Extent2DF screen_extent;
            obj->GetExtent(obj_state->mTransform,screen_extent,true);

            // Get bounding pixel rect
            Rect rect = obj_state->mTransform.GetTargetRect(screen_extent);

            const FilterList &filters = obj->getFilters();

            // Move rect to include filtered pixels...
            Rect filtered = GetFilteredObjectRect(filters,rect);

            // Expand clip rect to account for pixels that must be rendered so the
            //  filtered image remains valid in the original clip region.
            Rect expanded = ExpandVisibleFilterDomain( filters, obj_state->mClipRect );

            // Must render to this ...
            Rect render_to  = rect.Intersect(expanded);
            // In order to get this ...
            visible_bitmap  = filtered.Intersect(obj_state->mClipRect);


            if (obj->GetBitmapCache())
            {
               // Done - our bitmap is good!
               if (obj->GetBitmapCache()->StillGood(obj_state->mTransform, visible_bitmap))
                  continue;
               else
               {
                  obj->SetBitmapCache(0);
               }
            }

            // Ok, build bitmap cache...
            if (visible_bitmap.HasPixels())
            {
               //printf("Build bitmap cache (%d,%d %dx%d)\n", visible_bitmap.x, visible_bitmap.y,
               //   visible_bitmap.w, visible_bitmap.h );

               int w = render_to.w;
               int h = render_to.h;
               if (inState.mRoundSizeToPOW2 && filters.size()==0)
               {
                  w = UpToPower2(w);
                  h = UpToPower2(h);
               }

               uint32 bg = obj->opaqueBackground;
               if (bg && filters.size())
                   bg = 0;
               Surface *bitmap = new SimpleSurface(w, h, obj->IsBitmapRender() ?
                         (bg ? pfXRGB : pfARGB) : pfAlpha );
               bitmap->IncRef();

               if (bg && obj->IsBitmapRender())
                  bitmap->Clear(obj->opaqueBackground | 0xff000000,0);
               else
                  bitmap->Zero();
               // debug ...
               //bitmap->Clear(0xff333333);

               bool old_pow2 = obj_state->mRoundSizeToPOW2;
               Matrix orig = full;
               {
               AutoSurfaceRender render(bitmap,Rect(render_to.w,render_to.h));
               full.Translate(-render_to.x, -render_to.y );

               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);

               obj_state->mPhase = rpBitmap;
               obj->Render(render.Target(), *obj_state);

               obj_state->mPhase = rpRender;
               obj_state->mRoundSizeToPOW2 = false;

               obj->Render(render.Target(), *obj_state);
               obj->ClearCacheDirty();
               }

               bitmap = FilterBitmap(filters,bitmap,render_to,visible_bitmap,old_pow2);

               full = orig;
               obj->SetBitmapCache(
                      new BitmapCache(bitmap, obj_state->mTransform, visible_bitmap, false));
               obj_state->mRoundSizeToPOW2 = old_pow2;
               bitmap->DecRef();
            }
         }
         else
         {
            obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);
            obj->Render(inTarget,*obj_state);
         }
      }
      else
      {
         BitmapCache *old_mask = obj_state->mMask;

         if (obj->getMask())
         {
            // todo: combine masks ?
            //obj->DebugRenderMask(inTarget,*obj_state);

            // Mask not made yet?
            // TODO: Create mask on demand in this case - or make known limitation of system
            // This could be the case if the mask is lower in the Z-order, or not parented.
            if (!obj->getMask()->GetBitmapCache())
               continue;
            obj_state->mMask = obj->getMask()->GetBitmapCache();
         }

         if ( (obj->IsBitmapRender() && inState.mPhase!=rpHitTest) || obj->IsMask())
         {
            if (inState.mPhase==rpRender)
               obj->RenderBitmap(inTarget,*obj_state);
				/* HitTest is done on vector, not bitmap
            else if (inState.mPhase==rpHitTest && obj->IsBitmapRender() )
            {
                if (obj->HitBitmap(inTarget,*obj_state))
                {
                   inState.mHitResult = obj;
                   return;
                }
            }
				*/
         }
         else
         {
            if (obj->opaqueBackground)
            {
               // TODO: this should actually be a rectangle rotated like the object?
               Extent2DF screen_extent;
               obj->GetExtent(obj_state->mTransform,screen_extent,true);
               // Get bounding pixel rect
               Rect rect = obj_state->mTransform.GetTargetRect(screen_extent);

               // Intersect with clip rect ...
               rect = rect.Intersect(obj_state->mClipRect);
               if (rect.HasPixels())
               {
                  if (inState.mPhase == rpHitTest)
                  {
                     inState.mHitResult = this;
                     return;
                  }
                  inTarget.Clear(obj->opaqueBackground,rect);
               }
               else if (inState.mPhase == rpHitTest)
               {
                  obj_state->mMask = old_mask;
                  continue;
               }
            }

            if (inState.mPhase==rpRender)
               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);
            obj->Render(inTarget,*obj_state);
         }

         obj_state->mMask = old_mask;

         if (obj_state->mHitResult)
         {
            inState.mHitResult = obj_state->mHitResult;
            return;
         }
      }
   }

   // Render parent at beginning or end...
   if (inState.mPhase!=rpRender)
      DisplayObject::Render(inTarget,inState);
}

void DisplayObjectContainer::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen)
{
   DisplayObject::GetExtent(inTrans,outExt,inForScreen);

   Matrix full;
   Transform trans(inTrans);
   trans.mMatrix = &full;

   for(int i=0;i<mChildren.size();i++)
   {
      DisplayObject *obj = mChildren[i];

      full = inTrans.mMatrix->Mult( obj->GetLocalMatrix() );
      if (inForScreen && obj->scrollRect.HasPixels())
      {
         for(int corner=0;corner<4;corner++)
         {
            double x = (corner & 1) ? obj->scrollRect.w : 0;
            double y = (corner & 2) ? obj->scrollRect.h : 0;
            outExt.Add( full.Apply(x,y) );
         }
      }
      else
         // Seems scroll rects are ignored when calculating extent...
         obj->GetExtent(trans,outExt,inForScreen);
   }
}


DisplayObject *DisplayObjectContainer::getChildAt(int index)
{
   if (index<0 || index>=mChildren.size())
      return 0;
   return mChildren[index];
}

bool DisplayObjectContainer::NonNormalBlendChild()
{
   for(int i=0;i<mChildren.size();i++)
      if (mChildren[i]->blendMode!=bmNormal)
         return true;
   return false;
}

bool DisplayObjectContainer::IsCacheDirty()
{
   for(int i=0;i<mChildren.size();i++)
      if (mChildren[i]->visible && mChildren[i]->IsCacheDirty())
         return true;
   return DisplayObject::IsCacheDirty();
}

void DisplayObjectContainer::ClearCacheDirty()
{
   for(int i=0;i<mChildren.size();i++)
      mChildren[i]->ClearCacheDirty();

   DisplayObject::ClearCacheDirty();
}


// --- BitmapCache ---------------------------------------------------------

BitmapCache::BitmapCache(Surface *inSurface,const Transform &inTrans, const Rect &inRect,bool inMaskOnly)
{
   mBitmap = inSurface->IncRef();
   mMatrix = *inTrans.mMatrix;
   mScale9 = *inTrans.mScale9;
   mRect = inRect;
   mTX = mTY = 0;
}

BitmapCache::~BitmapCache()
{
   mBitmap->DecRef();
}


bool BitmapCache::StillGood(const Transform &inTransform, const Rect &inVisiblePixels)
{
   if  (!mMatrix.IsIntTranslation(*inTransform.mMatrix,mTX,mTY) || mScale9!=*inTransform.mScale9)
      return false;

   // Translate our cached pixels to this new position ...
   Rect translated = mRect.Translated(mTX,mTY);
   if (translated.Contains(inVisiblePixels))
      return true;

   return false;
}


void BitmapCache::Render(const RenderTarget &inTarget,const BitmapCache *inMask,BlendMode inBlend)
{
   if (mBitmap)
   {
      int tint = 0xffffffff;
      if (inTarget.mPixelFormat!=pfAlpha && mBitmap->Format()==pfAlpha)
         tint = 0xff000000;

      if (inTarget.IsHardware())
      {
         inTarget.mHardware->BeginBitmapRender(mBitmap,tint);
         inTarget.mHardware->RenderBitmap(Rect(mRect.w, mRect.h), mRect.x+mTX, mRect.y+mTY);
         inTarget.mHardware->EndBitmapRender();
      }
      else
      {
 
         // TX,TX is se in StillGood function
         mBitmap->BlitTo(inTarget, Rect(mRect.w, mRect.h), mRect.x+mTX, mRect.y+mTY,inBlend,inMask,tint);
      }
   }
}

bool BitmapCache::HitTest(double inX, double inY)
{
   double x0 = mRect.x+mTX;
   double y0 = mRect.y+mTY;
   //printf("BMP hit %f,%f    %f,%f ... %d,%d\n", inX, inY, x0,y0, mRect.w, mRect.h );
   return x0<=inX && y0<=inY && (inX<=x0+mRect.w) && (inY<=y0+mRect.h);
}



// --- Stage ---------------------------------------------------------------


// Helper class....
class AutoStageRender
{
   Surface *mSurface;
   Stage   *mToFlip;
   RenderTarget mTarget;
public:
   AutoStageRender(Stage *inStage,int inRGB)
   {
      mSurface = inStage->GetPrimarySurface();
      mToFlip = inStage;
      mTarget = mSurface->BeginRender( Rect(mSurface->Width(),mSurface->Height()) );
      mSurface->Clear(inRGB | 0xff000000 );
   }
   int Width() const { return mSurface->Width(); }
   int Height() const { return mSurface->Height(); }
   ~AutoStageRender()
   {
      mSurface->EndRender();
      mToFlip->Flip();
   }
   const RenderTarget &Target() { return mTarget; }
};

Stage::Stage(bool inInitRef) : DisplayObjectContainer(inInitRef)
{
   mHandler = 0;
   mHandlerData = 0;
   opaqueBackground = 0xffffffff;
   mQuality = 4;
   mFocusObject = 0;
   mMouseDownObject = 0;
   focusRect = true;
}

Stage::~Stage()
{
   if (mFocusObject)
      mFocusObject->DecRef();
   if (mMouseDownObject)
      mMouseDownObject->DecRef();
}

void Stage::SetFocusObject(DisplayObject *inObj,FocusSource inSource,int inKey)
{
   if (inObj==mFocusObject)
      return;

   if (mHandler)
   {
      Event focus(etFocus);
      focus.id = inObj ? inObj->id : 0;
      focus.value = inSource;
      focus.code = inKey;
   
      mHandler(focus,mHandlerData);

      if (inSource!=fsProgram && focus.result==erCancel)
         return;
   }


   if (!inObj || inObj->getStage()!=this)
   {
      if (mFocusObject)
      {
         mFocusObject->Unfocus();
         mFocusObject->DecRef();
      }
      mFocusObject = 0;
   }
   else
   {
      inObj->IncRef();
      if (mFocusObject)
      {
         mFocusObject->Unfocus();
         mFocusObject->DecRef();
      }
      mFocusObject = inObj;
      inObj->Focus();
   }

}


void Stage::SetEventHandler(EventHandler inHander,void *inUserData)
{
   mHandler = inHander;
   mHandlerData = inUserData;
}

void Stage::HandleEvent(Event &inEvent)
{
   DisplayObject *hit_obj = 0;

   if (inEvent.type==etMouseMove || inEvent.type==etMouseDown)
		mLastMousePos = UserPoint(inEvent.x, inEvent.y);

   if (mMouseDownObject)
   {
      switch(inEvent.type)
      {
         case etMouseMove:
            if (inEvent.flags & efLeftDown)
            {
               mMouseDownObject->Drag(inEvent);
               break;
            }
            // fallthrough
         case etMouseClick:
         case etMouseDown:
         case etMouseUp:
            mMouseDownObject->EndDrag(inEvent);
            mMouseDownObject->DecRef();
            mMouseDownObject = 0;
            break;
      }
   }

   if (inEvent.type==etKeyDown || inEvent.type==etKeyUp)
   {
      inEvent.id = mFocusObject ? mFocusObject->id : id;
      if (mHandler)
         mHandler(inEvent,mHandlerData);
      if (inEvent.result==0 && mFocusObject)
         mFocusObject->OnKey(inEvent);
   }

   if (inEvent.type==etMouseMove || inEvent.type==etMouseDown || inEvent.type==etMouseUp ||
         inEvent.type==etMouseClick )
   {
      hit_obj = HitTest(inEvent.x,inEvent.y);
      inEvent.id = hit_obj ? hit_obj->id : id;
      Cursor cur = hit_obj ? hit_obj->GetCursor() : curPointer;
      SetCursor( (gMouseShowCursor || cur==curTextSelect) ? cur : curNone );
   }

   if (hit_obj)
      hit_obj->IncRef();

   if (mHandler)
      mHandler(inEvent,mHandlerData);

   if (hit_obj)
   {
      if ((inEvent.type==etMouseDown) && inEvent.result!=erCancel )
      {
         if (hit_obj->WantsFocus())
            SetFocusObject(hit_obj,fsMouse);
         #ifdef IPHONE
         else
         {
            EnablePopupKeyboard(false);
            SetFocusObject(0,fsMouse);
         }
         #endif
      }
   
      if (inEvent.type==etMouseDown)
      {
         if (hit_obj->CaptureDown(inEvent))
         {
            hit_obj->IncRef();
            mMouseDownObject = hit_obj;
         }
      }
   }
   #ifdef IPHONE
   else if (inEvent.type==etMouseClick ||  inEvent.type==etMouseDown )
   {
      EnablePopupKeyboard(false);
      SetFocusObject(0);
   }
   #endif
 
   
   if (hit_obj)
      hit_obj->DecRef();
}

void Stage::setOpaqueBackground(uint32 inBG)
{
   opaqueBackground = inBG | 0xff000000;
   DirtyCache();
}


void Stage::RemovingFromStage(DisplayObject *inObject)
{
   DisplayObject *f = mFocusObject;
   while(f)
   {
      if (f==inObject)
      {
         mFocusObject->DecRef();
         mFocusObject = 0;
         return;
      }
      f = f->getParent();
   }

   DisplayObject *m = mMouseDownObject;
   while(m)
   {
      if (m==inObject)
      {
         mMouseDownObject->DecRef();
         mMouseDownObject = 0;
         return;
      }
      m = m->getParent();
   }

}


bool Stage::FinishEditOnEnter()
{
   if (mFocusObject && mFocusObject!=this)
      return mFocusObject->FinishEditOnEnter();
   return false;
}


void Stage::RenderStage()
{
   ColorTransform::TidyCache();
   AutoStageRender render(this,opaqueBackground);

   RenderState state(0,mQuality);

   //gState.mTransform.mMatrix = Matrix().Rotate(rot).Translate(tx+100,200);
   state.mClipRect = Rect( render.Width(), render.Height() );

   state.mPhase = rpBitmap;
   state.mRoundSizeToPOW2 = render.Target().IsHardware();
   Render(render.Target(),state);

   state.mPhase = rpRender;
   Render(render.Target(),state);
}

double Stage::getStageWidth()
{
   Surface *s = GetPrimarySurface();
   if (!s) return 0;
   return s->Width();
}

double Stage::getStageHeight()
{
   Surface *s = GetPrimarySurface();
   if (!s) return 0;
   return s->Height();
}



DisplayObject *Stage::HitTest(int inX,int inY)
{
   Surface *surface = GetPrimarySurface();

   // TODO: special version that does not actually do rendering...
   RenderTarget target = surface->BeginRender( Rect(surface->Width(),surface->Height()) );

   RenderState state(0,mQuality);
   state.mClipRect = Rect( inX, inY, 1, 1 );
   state.mRoundSizeToPOW2 = target.IsHardware();
   state.mPhase = rpHitTest;

   Render(target,state);

   surface->EndRender();

   // printf("Stage hit %p\n", state.mHitResult );

   return state.mHitResult;
}

} // end namespace nme

