#include <Display.h>
#include <Surface.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.1415926535897932385
#endif

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
}

DisplayObject::~DisplayObject()
{
   if (mGfx)
      mGfx->DecRef();
   // assert mParent==0
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

void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (mGfx)
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
      printf("Rotation = %f\n",rotation);
      /*
      scaleX = cos(rotation) * mLocalMatrix.m00 +
               -sin(rotation) * mLocalMatrix.m10;
      scaleY = sin(rotation) * mLocalMatrix.m01 + 
               cos(rotation) * mLocalMatrix.m11;
               */
      printf("scale = %f,%f\n", scaleX, scaleY );
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
      DirtyUp(dirtCache);
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

   const Extent2DF &ext0 = mGfx->GetExtent0(rotation);
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
   Extent2DF ext = mGfx->GetExtent(trans);
   if (!ext.Valid())
      return 0;

   return ext.Width();
}


void DisplayObject::setHeight(double inValue)
{
   if (!mGfx)
      return;

   const Extent2DF &ext0 = mGfx->GetExtent0(rotation);
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
   Extent2DF ext = mGfx->GetExtent(trans);
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
      DirtyUp(dirtCache);
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
      DirtyUp(dirtCache);
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
   DirtyUp(dirtCache);
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
      DirtyUp(dirtCache);
   }
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

void DisplayObjectContainer::removeChild(DisplayObject *inChild)
{
   IncRef();
   inChild->SetParent(0);
   DecRef();
}

void DisplayObjectContainer::addChild(DisplayObject *inChild,bool inTakeRef)
{
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
	DisplayObject::Render(inTarget,inState);

   Matrix full;
   RenderState state(inState);
   state.mTransform.mMatrix = &full;

   for(int i=0;i<mChildren.size();i++)
   {
      DisplayObject *obj = mChildren[i];

      full = inState.mTransform.mMatrix->Mult( obj->GetLocalMatrix() );
      if (obj->scrollRect.HasPixels())
      {
         UserPoint bottom_right = full.Apply(obj->scrollRect.w,obj->scrollRect.h);
         Rect screen_rect(full.mtx,full.mty,bottom_right.x,bottom_right.y,true);

         screen_rect.MakePositive();

			full.TranslateData(-obj->scrollRect.x, -obj->scrollRect.y );

         RenderState clip_state(state);
         clip_state.mClipRect = clip_state.mClipRect.Intersect(screen_rect);
      
         obj->Render(inTarget,clip_state);
      }
      else
		{
         obj->Render(inTarget,state);
		}
   }
}


DisplayObject *DisplayObjectContainer::getChildAt(int index)
{
   if (index<0 || index>=mChildren.size())
      return 0;
   return mChildren[index];
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
   mBackgroundColour = 0xffffff;
   mQuality = 4;
}

Stage::~Stage()
{
}


void Stage::RenderStage()
{
   AutoStageRender render(this,mBackgroundColour);

   RenderState state(0,mQuality);

   //gState.mTransform.mMatrix = Matrix().Rotate(rot).Translate(tx+100,200);
   state.mClipRect = Rect( render.Width(), render.Height() );

   Render(render.Target(),state);
}
