#include <Display.h>
#include <Surface.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.1415926535897932385
#endif

namespace nme
{

unsigned int gDisplayRefCounting = drDisplayChildRefs;

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
   mMask = 0;
   mIsMaskCount = 0;
}

DisplayObject::~DisplayObject()
{
   if (mGfx)
      mGfx->DecRef();
   delete mBitmapCache;
   if (mMask)
      setMask(0);
   DecFilters();
}

Graphics &DisplayObject::GetGraphics()
{
   if (!mGfx)
   {
      mGfx = new Graphics(true);
   }
   return *mGfx;
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
      mParent->RemoveChildFromList(this);
      mParent->DirtyDown(dirtCache);
   }
   DirtyUp(dirtCache);

   mParent = inParent;

   DecRef();
}

void DisplayObject::CheckCacheDirty()
{
   if ( mDirtyFlags & dirtCache)
   {
      if (mBitmapCache)
      {
         delete mBitmapCache;
         mBitmapCache = 0;
      }
      mDirtyFlags ^= dirtCache;
   }

   if (!IsBitmapRender() && !IsMask() && mBitmapCache)
   {
      delete mBitmapCache;
      mBitmapCache = 0;
   }
}

bool DisplayObject::IsBitmapRender()
{
   return cacheAsBitmap || blendMode!=bmNormal || NonNormalBlendChild() || mFilters.size();
}

void DisplayObject::SetBitmapCache(BitmapCache *inCache)
{
   delete mBitmapCache;
   mBitmapCache = inCache;
}




void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (mGfx && !inState.mBitmapPhase)
   {
      if (scale9Grid.HasPixels())
      {
         RenderState state(inState);

         const Extent2DF &ext0 = mGfx->GetExtent0(0);
         Scale9 s9;
         s9.Activate(scale9Grid,ext0,scaleX,scaleY);
         state.mTransform.mScale9 = &s9;

         Matrix unscaled = state.mTransform.mMatrix->Mult( Matrix(1.0/scaleX,1.0/scaleY) );
         state.mTransform.mMatrix = &unscaled;

         mGfx->Render(inTarget,state);
      }
      else
         mGfx->Render(inTarget,inState);
   }
}


DisplayObject *DisplayObject::HitTest(const UserPoint &inPoint)
{
	if (mGfx)
	{
		const Extent2DF &ext0 = mGfx->GetExtent0(0);
		if (!ext0.Contains(inPoint))
			return 0;

		if (scale9Grid.HasPixels())
		{
			const Extent2DF &ext0 = mGfx->GetExtent0(0);
			Scale9 s9;
			s9.Activate(scale9Grid,ext0,scaleX,scaleY);
			UserPoint p( s9.InvTransX(inPoint.x), s9.InvTransY(inPoint.y) );
			if (mGfx->HitTest(p))
				return this;
		}
		else if (mGfx->HitTest(inPoint))
			return this;
	}

	return 0;
}

void DisplayObject::RenderBitmap( const RenderTarget &inTarget, const RenderState &inState )
{
   if (!mBitmapCache)
      return;

   RenderTarget t = inTarget.ClipRect( inState.mClipRect );
   mBitmapCache->Render(inTarget,inState.mMask,blendMode);
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


void DisplayObject::DirtyDown(uint32 inFlags)
{
   mDirtyFlags |= inFlags;
   if (mParent)
      mParent->DirtyDown(inFlags);
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
      outExt.Add(mGfx->GetExtent(inTrans));
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
      if (mParent) mParent->DirtyDown(dirtCache);
   }
}

void DisplayObject::setScaleX(double inValue)
{
   UpdateDecomp();
   if (scaleX!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      scaleX = inValue;
      //if (mParent) mParent->DirtyDown(dirtCache);
      //DirtyUp(dirtCache);
   }
}

double DisplayObject::getScaleX()
{
   UpdateDecomp();
   return scaleX;
}


void DisplayObject::setWidth(double inValue)
{
   if (!mGfx)
      return;

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
   if (!mGfx)
      return 0;

   Transform trans;
   trans.mMatrix = &GetLocalMatrix();
   Extent2DF ext;
   GetExtent(trans,ext,false);
   if (!ext.Valid())
      return 0;

   return ext.Width();
}


void DisplayObject::setHeight(double inValue)
{
   if (!mGfx)
      return;

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
   if (!mGfx)
      return 0;

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
      if (mParent) mParent->DirtyDown(dirtCache);
   }
}

void DisplayObject::setScaleY(double inValue)
{
   UpdateDecomp();
   if (scaleY!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      scaleY = inValue;
      if (mParent) mParent->DirtyDown(dirtCache);
      //DirtyUp(dirtCache);
   }
}

void DisplayObject::setScale9Grid(const DRect &inRect)
{
   scale9Grid = inRect;
   if (mParent) mParent->DirtyDown(dirtCache);
}

void DisplayObject::setScrollRect(const DRect &inRect)
{
   scrollRect = inRect;
   UpdateDecomp();
   mDirtyFlags |= dirtLocalMatrix;
   if (mParent) mParent->DirtyDown(dirtCache);
   //DirtyUp(dirtCache);
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
      if (mParent) mParent->DirtyDown(dirtCache);
      //DirtyUp(dirtCache);
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
}

void DisplayObject::setAlpha(double inAlpha)
{
   // todo : dirty cache
   colorTransform.alphaScale = inAlpha;
   colorTransform.alphaOffset = 0;
}

void DisplayObject::SetFilters(const Filters &inFilters)
{
   DecFilters();
   mFilters.resize(inFilters.size());
   for(int i=0;i<mFilters.size();i++)
      (mFilters[i] = inFilters[i])->IncRef();
   DirtyDown(dirtCache);
}


void DisplayObject::DecFilters()
{
   for(int i=0;i<mFilters.size();i++)
      mFilters[i]->DecRef();
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
         DirtyDown(dirtCache);
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

   // Otherwise do it at end...
   if (!inState.mBitmapPhase)
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
   // Build top first when making bitmaps and masks....
   if (inState.mBitmapPhase)
   {
      first = last - 1;
      last = -1;
      dir = -1;
   }
   for(int i=first; i!=last; i+=dir)
   {
      DisplayObject *obj = mChildren[i];
      if (!obj->visible || (!inState.mBitmapPhase && obj->IsMask()) )
         continue;

      RenderState *obj_state = &state;
      full = inState.mTransform.mMatrix->Mult( obj->GetLocalMatrix() );

      if (obj->scrollRect.HasPixels())
      {
         UserPoint bottom_right = full.Apply(obj->scrollRect.w,obj->scrollRect.h);
         Rect screen_rect(full.mtx,full.mty,bottom_right.x,bottom_right.y,true);

         screen_rect.MakePositive();

         full.TranslateData(-obj->scrollRect.x, -obj->scrollRect.y );

         clip_state.mClipRect = clip_state.mClipRect.Intersect(screen_rect);
      
         obj_state = &clip_state;
      }


      if (inState.mBitmapPhase)
      {
         obj->CheckCacheDirty();

         if (obj->IsBitmapRender() || obj->IsMask())
         {
            Extent2DF screen_extent;
            obj->GetExtent(obj_state->mTransform,screen_extent,true);

            // Get bounding pixel rect
            Rect rect = obj_state->mTransform.GetTargetRect(screen_extent);

            const Filters &filters = obj->GetFilters();
            Rect filtered = GetFilteredRect( filters, rect );

            // Intersect with clip rect ...
            visible_bitmap = filtered.Intersect(obj_state->mClipRect);

            if (obj->GetBitmapCache())
            {
               // Done - our bitmap is good!
               if (obj->GetBitmapCache()->StillGood(obj_state->mTransform, filtered, visible_bitmap))
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
                      //visible_bitmap.w, visible_bitmap.h );

               Rect render_to = GetRectToCreateFiltered(filters,visible_bitmap);
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
               SimpleSurface *bitmap = new SimpleSurface(w, h, obj->IsBitmapRender() ?
                         (bg ? pfXRGB : pfARGB) : pfAlpha );

               if (bg && obj->IsBitmapRender())
                  bitmap->Clear(obj->opaqueBackground | 0xff000000,0);
               else
                  bitmap->Zero();
               // debug ...
               //bitmap->Clear(0xff333333);
               AutoSurfaceRender render(bitmap,Rect(render_to.w,render_to.h));
               Matrix orig = full;
               full.Translate(-render_to.x, -render_to.y );

               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);

               obj_state->mBitmapPhase = true;
               obj->Render(render.Target(), *obj_state);

               obj_state->mBitmapPhase = false;
               bool old_pow2 = obj_state->mRoundSizeToPOW2;
               obj_state->mRoundSizeToPOW2 = false;

               obj->Render(render.Target(), *obj_state);

               FilterBitmap(filters,bitmap,render_to,visible_bitmap,old_pow2);

               full = orig;
               obj->SetBitmapCache(
                      new BitmapCache(bitmap, obj_state->mTransform, visible_bitmap, false));
               obj_state->mRoundSizeToPOW2 = old_pow2;
            }
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

         if (obj->IsBitmapRender() || obj->IsMask())
         {
            obj->RenderBitmap(inTarget,*obj_state);
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
                  inTarget.Clear(obj->opaqueBackground,rect);
               }
            }
            obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);
            obj->Render(inTarget,*obj_state);
         }

         obj_state->mMask = old_mask;
      }
   }

   if (inState.mBitmapPhase)
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

DisplayObject *DisplayObjectContainer::HitTest(const UserPoint &inPoint)
{
	// TODO: Check mask...
   for(int i=0;i<mChildren.size();i++)
   {
      DisplayObject *obj = mChildren[i];

      UserPoint local = obj->GetLocalMatrix().ApplyInverse(inPoint);

		if ( obj->scrollRect.HasPixels() )
		{
			// TODO - is this right?
         if (obj->scrollRect.Contains(local))
			   return this;
		}
		else
		{
         DisplayObject *result = obj->HitTest(local);
		   if (result)
			   return result;
		}
   }

	return DisplayObject::HitTest(inPoint);
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


bool BitmapCache::StillGood(const Transform &inTransform,const Rect &inExtent, const Rect &inVisiblePixels)
{
   if  (!mMatrix.IsIntTranslation(*inTransform.mMatrix,mTX,mTY) && mScale9!=*inTransform.mScale9)
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
      mSurface->Clear(inRGB);
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
   mBackgroundColour = 0xffffff;
   mQuality = 4;
}

Stage::~Stage()
{
}

void Stage::SetEventHandler(EventHandler inHander,void *inUserData)
{
   mHandler = inHander;
   mHandlerData = inUserData;
}

void Stage::HandleEvent(Event &inEvent)
{
   if (inEvent.type==etMouseMove)
   {
      DisplayObject *obj = HitTest(inEvent.x,inEvent.y);
   }

   if (mHandler)
      mHandler(inEvent,mHandlerData);
}


void Stage::RenderStage()
{
   ColorTransform::TidyCache();
   AutoStageRender render(this,mBackgroundColour);

   RenderState state(0,mQuality);

   //gState.mTransform.mMatrix = Matrix().Rotate(rot).Translate(tx+100,200);
   state.mClipRect = Rect( render.Width(), render.Height() );

   state.mBitmapPhase = true;
   state.mRoundSizeToPOW2 = render.Target().IsHardware();
   Render(render.Target(),state);

   state.mBitmapPhase = false;
   Render(render.Target(),state);
}


DisplayObject *Stage::HitTest(int inX,int inY)
{
	DisplayObject *result =  DisplayObjectContainer::HitTest(UserPoint(inX,inY));
   if (result)
	   printf("Hit %p\n",result);
	return result;
}

} // end namespace nme

