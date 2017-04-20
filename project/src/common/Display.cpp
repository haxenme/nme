#include <Display.h>
#include <Surface.h>
#include <math.h>


#ifndef M_PI
#define M_PI 3.1415926535897932385
#endif

#ifdef ANDROID
#include <android/log.h>
#endif

namespace nme
{

bool gNmeRenderGcFree = false;

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
   #ifdef NME_S3D
   z = 0;
   #endif
   scaleX = scaleY = 1.0;
   rotation = 0;
   visible = true;
   mBitmapCache = 0;
   cacheAsBitmap = false;
   pedanticBitmapCaching = false;
   blendMode = bmNormal;
   pixelSnapping = psNone;
   opaqueBackground = 0;
   mouseEnabled = true;
   hitEnabled = true;
   needsSoftKeyboard = false;
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
   {
      mGfx->removeOwner(this);
      mGfx->DecRef();
   }
   delete mBitmapCache;
   mBitmapCache = 0;
   if (mMask)
      setMask(0);
   ClearFilters();
}

Graphics &DisplayObject::GetGraphics()
{
   if (!mGfx)
      mGfx = new Graphics(this,true);
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
   mBitmapGfx = mGfx ? mGfx->Version() : 0;
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
   mParent = inParent;
   DirtyCache();

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
   Matrix m = GetFullMatrix(false);
   return m.ApplyInverse(inPoint);
}

UserPoint DisplayObject::LocalToGlobal(const UserPoint &inPoint)
{
   Matrix m = GetFullMatrix(false);
   return m.Apply(inPoint.x,inPoint.y);
}



void DisplayObject::setCacheAsBitmap(bool inVal)
{
   cacheAsBitmap = inVal;
}


void DisplayObject::setPixelSnapping(int inVal)
{
   if (pixelSnapping!=inVal)
   {
      pixelSnapping = inVal;
      DirtyCache();
   }
}


void DisplayObject::setVisible(bool inVal)
{
   if (visible!=inVal)
   {
      visible = inVal;
      DirtyCache(!visible);
   }
}




void DisplayObject::CheckCacheDirty(bool inForHardware)
{
   if (mBitmapCache && IsCacheDirty())
   {
      delete mBitmapCache;
      mBitmapCache = 0;
   }

   if (!IsBitmapRender(inForHardware) && !IsMask() && mBitmapCache)
   {
      delete mBitmapCache;
      mBitmapCache = 0;
   }
}

bool DisplayObject::IsBitmapRender(bool inHardware)
{
   return cacheAsBitmap || blendMode!=bmNormal || NonNormalBlendChild() || filters.size() ||
                                      (inHardware && mMask);
}

void DisplayObject::SetBitmapCache(BitmapCache *inCache)
{
   delete mBitmapCache;
   mBitmapCache = inCache;
}




void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpHitTest && !hitEnabled )
      return;

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
      }
      else if (mGfx)
      {
         hit = mGfx->Render(inTarget,inState);
      }

      if (hit && inState.mPhase==rpHitTest)
         inState.mHitResult = this;
   }
   else if (inState.mPhase==rpBitmap && inState.mWasDirtyPtr && !*inState.mWasDirtyPtr)
   {
      *inState.mWasDirtyPtr = DisplayObject::IsCacheDirty();
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

   ImagePoint offset;
   if (inState.mMask)
   {
      BitmapCache *mask = inState.mMask;
      ImagePoint buffer;
      mask->PushTargetOffset(inState.mTargetOffset,buffer);
      mBitmapCache->Render(inTarget,inState.mClipRect,mask,blendMode);
      mask->PopTargetOffset(buffer);
   }
   else
   {
      mBitmapCache->Render(inTarget,inState.mClipRect,0,blendMode);
   }
}

void DisplayObject::DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState )
{
   if (mMask)
      mMask->RenderBitmap(inTarget,inState);
}




void DisplayObject::DirtyCache(bool inParentOnly)
{
   if (!(mDirtyFlags & dirtCache))
   {
      if (!inParentOnly)
         mDirtyFlags |= dirtCache;
      if (mParent)
         mParent->DirtyCache(false);
   }
}

Matrix DisplayObject::GetFullMatrix(bool inStageScaling)
{
   if (mParent)
     return mParent->GetFullMatrix(inStageScaling).Mult(GetLocalMatrix().
                Translated(-scrollRect.x,-scrollRect.y));
   return GetLocalMatrix().Translated(-scrollRect.x,-scrollRect.y);
}

void DisplayObject::setMatrix(const Matrix &inMatrix)
{
   mLocalMatrix = inMatrix;
   DirtyCache();
   mDirtyFlags |= dirtDecomp;
   mDirtyFlags &= ~dirtLocalMatrix;
}


ColorTransform DisplayObject::GetFullColorTransform()
{
  if (mParent)
  {
     ColorTransform result;
     result.Combine(mParent->GetFullColorTransform(),colorTransform);
     return result;
  }
  return colorTransform;
}


void DisplayObject::setColorTransform(const ColorTransform &inTrans)
{
   colorTransform = inTrans;
   DirtyCache();
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
      #ifdef NME_S3D
      mLocalMatrix.mtz = z;
      #endif
      modifyLocalMatrix(mLocalMatrix);
   }
   return mLocalMatrix;
}

void DisplayObject::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen,bool inIncludeStroke)
{
   if (mGfx)
      outExt.Add(mGfx->GetSoftwareExtent(inTrans,inIncludeStroke));
}




void DisplayObject::UpdateDecomp()
{
   if (mDirtyFlags & dirtDecomp)
   {
      mDirtyFlags ^= dirtDecomp;
      x = mLocalMatrix.mtx;
      y = mLocalMatrix.mty;
      #ifdef NME_S3D
      z = mLocalMatrix.mtz;
      #endif
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
      s = Stage::GetCurrent();
   UserPoint p = s->getMousePos();
   UserPoint result = GetFullMatrix(true).ApplyInverse(p);
   return result.x;
   
}

double DisplayObject::getMouseY()
{
   Stage *s = getStage();
   if (!s)
      s = Stage::GetCurrent();
   UserPoint p = s->getMousePos();
   UserPoint result = GetFullMatrix(true).ApplyInverse(p);
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
   GetExtent(trans0,ext0,false,true);

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
   GetExtent(trans,ext,false,true);

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
   GetExtent(trans0,ext0,false,true);

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
   GetExtent(trans,ext,false,true);
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

#ifdef NME_S3D

double DisplayObject::getZ()
{
   UpdateDecomp();
   return z;
}

void DisplayObject::setZ(double inValue)
{
   UpdateDecomp();
   if (z!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      z = inValue;
      DirtyCache(true);
   }
}

#endif

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
   colorTransform.alphaMultiplier = inAlpha;
   colorTransform.alphaOffset = 0;
   DirtyCache();
}

void DisplayObject::setBlendMode(int inMode)
{
   if (inMode!=blendMode)
   {
      blendMode = (BlendMode)inMode;
      DirtyCache();
   }
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



void DisplayObject::Focus()
{
#if defined(IPHONE) || defined (ANDROID) || defined(WEBOS) || defined(BLACKBERRY) || defined(TIZEN)
  if (needsSoftKeyboard)
  {
     Stage *stage = getStage();
     if (stage)
        stage->PopupKeyboard(pkmDumb);
  }
#endif
}

void DisplayObject::Unfocus()
{
#if defined(IPHONE) || defined (ANDROID) || defined(WEBOS) || defined(BLACKBERRY) || defined(TIZEN)
  if (needsSoftKeyboard)
  {
     Stage *stage = getStage();
     if (stage)
        stage->PopupKeyboard(pkmOff);
  }
#endif
}

// --- DirectRenderer ------------------------------------------------

HardwareRenderer *gDirectRenderContext = 0;

void DirectRenderer::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpRender && inTarget.IsHardware())
   {
      gDirectRenderContext = inTarget.mHardware;
      gDirectRenderContext->BeginDirectRender();
      Rect clip = inState.mClipRect;
      clip.y = inTarget.mHardware->Height() - clip.y - clip.h;
      if (gNmeRenderGcFree)
      {
         gc_exit_blocking();
         onRender(renderHandle,clip,inState.mTransform);
         gc_enter_blocking();
      }
      else
         onRender(renderHandle,clip,inState.mTransform);
      gDirectRenderContext->EndDirectRender();
      gDirectRenderContext = 0;
   }
}


// --- SimpleButton ------------------------------------------------
SimpleButton::SimpleButton(bool inInitRef) : DisplayObjectContainer(inInitRef),
        enabled(true), useHandCursor(true), mMouseState(stateUp)
{
   for(int i=0;i<stateSIZE; i++)
      mState[i] = 0;
}

SimpleButton::~SimpleButton()
{
   for(int i=0;i<stateSIZE; i++)
      if (mState[i])
         mState[i]->DecRef();
}

void SimpleButton::RemoveChildFromList(DisplayObject *inChild)
{
   // This is called by 'setParent'
}


void SimpleButton::setState(int inState, DisplayObject *inObject)
{
   if (inState>=0 && inState<stateSIZE)
   {
       if (inObject)
          inObject->IncRef();
       if (mState[inState])
       {
          bool inMultipleTimes = false;
          for(int i=0;i<stateSIZE;i++)
             if (i!=inState && mState[i]==inObject)
                inMultipleTimes = true;
          if (!inMultipleTimes)
             mState[inState]->SetParent(0);
          mState[inState]->DecRef();
       }
       mState[inState] = inObject;
       if (inObject)
          inObject->SetParent(this);
   }
}


void SimpleButton::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpHitTest)
   {
      if (!hitEnabled)
         return;
      if (mState[stateHitTest])
      {
          DisplayObject *oldHit = inState.mHitResult;
          mState[stateHitTest]->Render(inTarget,inState);
          if (inState.mHitResult && inState.mHitResult!=oldHit)
             inState.mHitResult = this;
      }
   }
   else
   {
      DisplayObject *obj = mState[mMouseState];
      if (obj)
         obj->Render(inTarget,inState);
   }
}

void SimpleButton::setMouseState(int inState)
{
   if (mState[inState]!=mState[mMouseState])
       DirtyCache();

   mMouseState = inState;
}

void SimpleButton::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen, bool inIncludeStroke)
{
   DisplayObject::GetExtent(inTrans,outExt,inForScreen,inIncludeStroke);

   Matrix full;
   Transform trans(inTrans);
   trans.mMatrix = &full;

   for(int i=0;i<stateSIZE;i++)
   {
      if (i == stateHitTest) continue;
      DisplayObject *obj = mState[i];
      if (!obj)
         continue;

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
         obj->GetExtent(trans,outExt,inForScreen,inIncludeStroke);
   }
}


bool SimpleButton::IsCacheDirty()
{
   DisplayObject *obj = mState[mMouseState];
   if (obj && obj->IsCacheDirty())
         return true;
   return DisplayObject::IsCacheDirty();
}


void SimpleButton::ClearCacheDirty()
{
   DisplayObject::ClearCacheDirty();
   DisplayObject *obj = mState[mMouseState];
   if (obj)
      obj->ClearCacheDirty();
   DisplayObject::ClearCacheDirty();
}

bool SimpleButton::NonNormalBlendChild()
{
   DisplayObject *obj = mState[mMouseState];
   if (obj)
      return obj->NonNormalBlendChild();
   return false;
}

void SimpleButton::DirtyCache(bool inParentOnly)
{
   DisplayObject::DirtyCache(inParentOnly);
}




// --- DisplayObjectContainer ------------------------------------------------

DisplayObjectContainer::~DisplayObjectContainer()
{
   while(mChildren.size())
      mChildren[0]->SetParent(0);
}

void DisplayObjectContainer::RemoveChildFromList(DisplayObject *inChild)
{
   for(int i=0;i<mChildren.size();i++)
      if (inChild==mChildren[i])
      {
         if (gDisplayRefCounting & drDisplayParentRefs)
            DecRef();
         mChildren.EraseAt(i);
         DirtyCache();
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

void DisplayObjectContainer::swapChildrenAt(int inChild1, int inChild2)
{
   if (inChild1>=0 && inChild2>=0 &&
        inChild1<mChildren.size() &&  inChild2<mChildren.size() )
   {
      std::swap(mChildren[inChild1],mChildren[inChild2]);
      DirtyCache();
   }
}
 


void DisplayObjectContainer::removeChild(DisplayObject *inChild)
{
   IncRef();
   inChild->SetParent(0);
   DecRef();
   DirtyCache();
}

void DisplayObjectContainer::removeChildAt(int inIndex)
{
   if (inIndex>=0 && inIndex<mChildren.size())
      removeChild( mChildren[inIndex] );
}


void DisplayObjectContainer::addChild(DisplayObject *inChild)
{
   //printf("DisplayObjectContainer::addChild\n");
   IncRef();
   inChild->SetParent(this);

   mChildren.push_back(inChild);
   if (gDisplayRefCounting & drDisplayParentRefs)
      IncRef();

   DirtyCache();
   DecRef();
}

void DisplayObjectContainer::DirtyCache(bool inParentOnly)
{
   if (!(mDirtyFlags & dirtCache))
      DisplayObject::DirtyCache(inParentOnly);
   if (!(mDirtyFlags & dirtExtent))
      DirtyExtent();
}

void DisplayObjectContainer::DirtyExtent()
{
   if (!(mDirtyFlags & dirtExtent))
   {
      mDirtyFlags |= dirtExtent;
      mExtentCache[0].mIsSet = 
       mExtentCache[1].mIsSet = 
        mExtentCache[2].mIsSet = false;
      if (mParent)
         mParent->DirtyExtent();
   }
}

void DisplayObject::DirtyExtent()
{
   mDirtyFlags |= dirtExtent;
   if (mParent)
      mParent->DirtyExtent();
}

void DisplayObject::ClearExtentDirty()
{
   mDirtyFlags &= ~dirtExtent;
}

void DisplayObjectContainer::ClearExtentDirty()
{
   if (mDirtyFlags & dirtExtent)
   {
      mDirtyFlags &= ~dirtExtent;
      for(int c=0;c<mChildren.size();c++)
         mChildren[c]->ClearExtentDirty();
   }
}



bool DisplayObject::CreateMask(const Rect &inClipRect,int inAA)
{
   Transform trans;
   trans.mAAFactor = inAA;
   Matrix m = GetFullMatrix(true);
   trans.mMatrix = &m;
   Scale9 s9;
   if ( scale9Grid.HasPixels() )
   {
      const Extent2DF &ext0 = mGfx->GetExtent0(0);
      s9.Activate(scale9Grid,ext0,scaleX,scaleY);
      trans.mScale9 = &s9;

      m = m.Mult( Matrix(1.0/scaleX,1.0/scaleY) );
   }

   Extent2DF ext;
   GetExtent(trans,ext,false,true);

   Rect rect;
   if (!ext.GetRect(rect,0.999,0.999))
   {
      SetBitmapCache(0);
      return false;
   }

   rect = rect.Intersect(inClipRect);
   if (!rect.HasPixels())
   {
      SetBitmapCache(0);
      return false;
   }


   if (GetBitmapCache())
   {
      // Clear mask if invalid
      if (!GetBitmapCache()->StillGood(trans, rect,0))
      {
         SetBitmapCache(0);
      }
      else
         return true;
   }

   int w = rect.w;
   int h = rect.h;
   //w = UpToPower2(w); h = UpToPower2(h);

   Surface *bitmap = new SimpleSurface(w, h, pfAlpha);
   RenderState state(bitmap,inAA);

   bitmap->IncRef();
   if (opaqueBackground)
      bitmap->Clear(0xffffffff);
   else
   {
      bitmap->Zero();

      AutoSurfaceRender render(bitmap,Rect(rect.w,rect.h));

      state.mTransform = trans;
   
      state.mPhase = rpCreateMask;
      Matrix obj_matrix = m;

      m.Translate(-rect.x, -rect.y );
      Render(render.Target(), state);

      m = obj_matrix;

      ClearCacheDirty();
   }
   
   SetBitmapCache( new BitmapCache(bitmap, trans, rect, false, 0));
   bitmap->DecRef();
   return true;
}



/*
static int level = 0;
struct Leveller
{
   Leveller() { level++; print(); printf(">>>\n"); }
   ~Leveller() { level--; print(); printf(">>>\n"); }
   void print()
   {
      for(int i=0;i<level;i++)
         printf(" ");
   }
};
*/

void DisplayObjectContainer::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   //Leveller level;

   Rect visible_bitmap;

   bool parent_first = inState.mPhase==rpRender || inState.mPhase==rpCreateMask;

   // Render parent first (or at the end) ?
   if (parent_first)
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
   // Build top first when making bitmaps, or doing hit test...
   if (!parent_first)
   {
      first = last - 1;
      last = -1;
      dir = -1;
   }

   BitmapCache *orig_mask = inState.mMask;
   if (!inState.mRecurse)
      last = first;


   bool mouseDisabledObjectHit = false;

   for(int i=first; i!=last; i+=dir)
   {
      DisplayObject *obj = mChildren[i];
      //printf("Render phase = %d, parent = %d, child = %d\n", inState.mPhase, id, obj->id);
      if (!obj->visible || (inState.mPhase!=rpCreateMask && obj->IsMask()) ||
            (inState.mPhase==rpHitTest && !obj->hitEnabled)  )
         continue;

      // Already found a diabled one - no need to look at others
      if (mouseDisabledObjectHit && !obj->mouseEnabled)
         continue;

      RenderState *obj_state = &state;
      full = inState.mTransform.mMatrix->Mult( obj->GetLocalMatrix() );

      if (obj->scrollRect.HasPixels())
      {
         Extent2DF extent;
 
         DRect rect = obj->scrollRect;
         for(int c=0;c<4;c++)
            extent.Add( full.Apply( (((c&1)>0) ? rect.w :0), (((c&2)>0) ? rect.h :0) ) );


         Rect screen_rect(extent.minX,extent.minY, extent.maxX, extent.maxY, true );

         full.TranslateData(-obj->scrollRect.x, -obj->scrollRect.y );

         ImagePoint scroll(obj->scrollRect.x, obj->scrollRect.y);

         clip_state.mClipRect = inState.mClipRect.Intersect(screen_rect);

         if (!clip_state.mClipRect.HasPixels())
         {
            continue;
         }

         obj_state = &clip_state;
      }

      if (obj->pixelSnapping)
      {
         if (obj->pixelSnapping!=psAuto || (
             full.m00>0.99 && full.m00<1.01 && full.m01==0 &&
             full.m11>0.99 && full.m11<1.01 && full.m10==0 ) )
         {
            full.mtx = (int)full.mtx;
            full.mty = (int)full.mty;
         }
      }

      obj_state->mMask = orig_mask;

      DisplayObject *mask = obj->getMask();
      if (mask)
      {
         if (!mask->CreateMask(inTarget.mRect.Translated(obj_state->mTargetOffset),
                               obj_state->mTransform.mAAFactor))
            continue;

         // todo: combine masks ?
         //obj->DebugRenderMask(inTarget,obj->getMask());
         obj_state->mMask = mask->GetBitmapCache();
      }

      if (inState.mPhase==rpBitmap)
      {
         //printf("Bitmap phase %d\n", obj->id);
         if (obj->IsBitmapRender(inTarget.IsHardware()) )
         {
            obj->CheckCacheDirty(inTarget.IsHardware());

            Extent2DF screen_extent;
            obj->GetExtent(obj_state->mTransform,screen_extent,true,true);
            BitmapCache *mask = obj_state->mMask;

            // Get bounding pixel rect
            Rect rect = obj_state->mTransform.GetTargetRect(screen_extent);

            if (mask)
            {
               rect = rect.Intersect(mask->GetRect().Translated(-inState.mTargetOffset));
            }

            const FilterList &filters = obj->getFilters();


            // Move rect to include filtered pixels...
            Rect filtered = GetFilteredObjectRect(filters,rect);


            // Expand clip rect to account for pixels that must be rendered so the
            //  filtered image remains valid in the original clip region.
            Rect expanded = ExpandVisibleFilterDomain( filters, obj_state->mClipRect );


            // Must render to this ...
            Rect render_to  = rect.Intersect(expanded);
            // In order to get this ...
            visible_bitmap  = filtered.Intersect(obj_state->mClipRect );

            if (obj->GetBitmapCache())
            {
               // Done - our bitmap is good!
               if (obj->GetBitmapCache()->StillGood(obj_state->mTransform,
                      visible_bitmap, mask))
                  continue;
               else
               {
                  if (state.mWasDirtyPtr)
                     *state.mWasDirtyPtr = true;
                  obj->SetBitmapCache(0);
               }
            }

            // Ok, build bitmap cache...
            if (visible_bitmap.HasPixels())
            {
               if (state.mWasDirtyPtr)
                  *state.mWasDirtyPtr = true;

               /*
               printf("object rect %d,%d %dx%d\n", rect.x, rect.y, rect.w, rect.h);
               printf("filtered rect %d,%d %dx%d\n", filtered.x, filtered.y, filtered.w, filtered.h);
               printf("expanded rect %d,%d %dx%d\n", expanded.x, expanded.y, expanded.w, expanded.h);
               printf("render to %d,%d %dx%d\n", render_to.x, render_to.y, render_to.w, render_to.h);
               printf("Build bitmap cache (%d,%d %dx%d)\n", visible_bitmap.x, visible_bitmap.y,
                  visible_bitmap.w, visible_bitmap.h );
               */

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
               Surface *bitmap = new SimpleSurface(w, h, obj->IsBitmapRender(inTarget.IsHardware()) ?
                         (bg ? pfRGB : pfBGRPremA) : pfAlpha );
               bitmap->IncRef();

               if (bg && obj->IsBitmapRender(inTarget.IsHardware()))
                  bitmap->Clear(obj->opaqueBackground | 0xff000000,0);
               else
                  bitmap->Zero();
               // debug ...
               //bitmap->Clear(0xff333333);

               //printf("Render %dx%d\n", w,h);
               bool old_pow2 = obj_state->mRoundSizeToPOW2;
               Matrix orig = full;
               {
               AutoSurfaceRender render(bitmap,Rect(render_to.w,render_to.h));
               full.Translate(-render_to.x, -render_to.y );
               ImagePoint offset = obj_state->mTargetOffset;
               Rect clip = obj_state->mClipRect;
               RenderPhase phase = obj_state->mPhase;

               obj_state->mClipRect = Rect(render_to.w,render_to.h);

               obj_state->mTargetOffset += ImagePoint(render_to.x,render_to.y);

               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);

               obj_state->mPhase = rpBitmap;
               obj->Render(render.Target(), *obj_state);

               obj_state->mPhase = rpRender;
               obj_state->mRoundSizeToPOW2 = false;

               int old_aa = obj_state->mTransform.mAAFactor;
               obj_state->mTransform.mAAFactor = 4;

               obj->Render(render.Target(), *obj_state);
               obj_state->mTransform.mAAFactor = old_aa;

               obj->ClearCacheDirty();
               obj_state->mTargetOffset = offset;
               obj_state->mClipRect = clip;
               obj_state->mPhase = phase;
               }

               bitmap = FilterBitmap(filters,bitmap,render_to,visible_bitmap,old_pow2,true);

               full = orig;
               obj->SetBitmapCache(
                      new BitmapCache(bitmap, obj_state->mTransform, visible_bitmap, false, mask));
               obj_state->mRoundSizeToPOW2 = old_pow2;
               bitmap->DecRef();
            }
            else
            {
               obj->ClearCacheDirty();
            }
         }
         else
         {
            if (!obj->IsMask())
               obj->SetBitmapCache(0);
            obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);
            obj->Render(inTarget,*obj_state);
         }
      }
      // Not rpBitmap ...
      else
      {
         if ( (obj->IsBitmapRender(inTarget.IsHardware()) && inState.mPhase!=rpHitTest) )
         {
            if (inState.mPhase==rpRender)
               obj->RenderBitmap(inTarget,*obj_state);
         }
         // Can just test the rect?
         else if (obj->opaqueBackground && inState.mPhase==rpHitTest && !obj->scrollRect.HasPixels())
         {
            Rect rect = clip_state.mClipRect;
            if ( !obj->scrollRect.HasPixels() )
            {
               // TODO: this should actually be a rectangle rotated like the object?
               Extent2DF screen_extent;
               obj->GetExtent(obj_state->mTransform,screen_extent,true,true);
               // Get bounding pixel rect
               rect = obj_state->mTransform.GetTargetRect(screen_extent);

               // Intersect with clip rect ...
               rect = rect.Intersect(obj_state->mClipRect);
            }

            if (rect.HasPixels())
               obj_state->mHitResult = obj;
         }
         else
         {
            if (inState.mPhase==rpRender)
               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);

            obj->Render(inTarget,*obj_state);
         }

         if (obj_state->mHitResult && inState.mPhase==rpHitTest)
         {
            if (!obj_state->mHitResult->mouseEnabled)
            {
               // Objects underneath a mouseEnabled=false object will register the hit
               //  first (hmm) - but if there is none, then the hit will be attributed to the
               //  parent object (this)
               mouseDisabledObjectHit = true;
               obj_state->mHitResult = 0;
            }
            else
            {
               inState.mHitResult = obj_state->mHitResult;
               // Child has been hit - should we steal the hit?
               if (!inState.mHitResult->IsInteractive() || !mouseChildren)
                  inState.mHitResult = this;
               return;
            }
         }
      }
   }

   if (mouseDisabledObjectHit)
   {
      inState.mHitResult = this;
      return;
   }

   // Render parent at beginning or end...
   if (!parent_first)
      DisplayObject::Render(inTarget,inState);

}

void DisplayObjectContainer::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen,bool inIncludeStroke)
{
   int smallest = mExtentCache[0].mID;
   int slot = 0;
   ClearExtentDirty();
   for(int i=0;i<3;i++)
   {
      CachedExtent &cache = mExtentCache[i];
      if (cache.mIsSet && *inTrans.mMatrix==cache.mMatrix &&
            *inTrans.mScale9==cache.mScale9 && cache.mIncludeStroke==inIncludeStroke &&
               cache.mForScreen==inForScreen)
         {
            // Maybe set but not valid - ie, 0 size
            if (cache.mExtent.Valid())
               outExt.Add(cache.mExtent);
            return;
         }
      if (cache.mID<gCachedExtentID)
         cache.mID = gCachedExtentID;

      if (cache.mID<smallest)
      {
         smallest = cache.mID;
         slot = i;
      }
   }

   // Need to recalculate the extent...
   CachedExtent &cache = mExtentCache[slot];
   cache.mExtent = Extent2DF();
   cache.mIsSet = true;
   cache.mMatrix = *inTrans.mMatrix;
   cache.mScale9 = *inTrans.mScale9;
   // todo:Matrix3d?
   cache.mForScreen = inForScreen;
   cache.mIncludeStroke = inIncludeStroke;

   DisplayObject::GetExtent(inTrans,cache.mExtent,inForScreen,inIncludeStroke);

   // TODO - allow translations without clearing cache
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
            cache.mExtent.Add( full.Apply(x,y) );
         }
      }
      else
         // Seems scroll rects are ignored when calculating extent...
         obj->GetExtent(trans,cache.mExtent,inForScreen,inIncludeStroke);
   }

   if (cache.mExtent.Valid())
     outExt.Add(cache.mExtent);
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
      if (mChildren[i]->visible && mChildren[i]->blendMode!=bmNormal)
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




} // end namespace nme

