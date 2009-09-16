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
   DirtyUp(dirtFullMatrix|dirtCache);

   mParent = inParent;

   DecRef();
}

void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
	if (mGfx)
   {
      RenderState state(inState);
      state.mTransform.mMatrix = &GetFullMatrix();
		mGfx->Render(inTarget,state);
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

Matrix &DisplayObject::GetFullMatrix()
{
   if (mDirtyFlags & dirtFullMatrix)
   {
      mDirtyFlags ^= dirtFullMatrix;
      if (mParent)
         mFullMatrix = mParent->GetFullMatrix().Mult(GetLocalMatrix());
      else
         mFullMatrix = GetLocalMatrix();
   }
   return mFullMatrix;
}

Matrix &DisplayObject::GetLocalMatrix()
{
   if (mDirtyFlags & dirtLocalMatrix)
   {
      mDirtyFlags ^= dirtLocalMatrix;
      double r = rotation*M_PI/180.0;
      double c = cos(r);
      double s = sin(r);
      mLocalMatrix.m00 = c*scaleX;
      mLocalMatrix.m01 = s*scaleX;
      mLocalMatrix.m10 = -s*scaleY;
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
                     mLocalMatrix.m01*mLocalMatrix.m01 );
      scaleY = sqrt( mLocalMatrix.m10*mLocalMatrix.m10 +
                     mLocalMatrix.m11*mLocalMatrix.m11 );
      rotation = scaleX>0 ? atan2( mLocalMatrix.m01, mLocalMatrix.m00 ) :
                 scaleY>0 ? atan2( mLocalMatrix.m11, mLocalMatrix.m10 ) : 0.0;
      rotation *= 180.0/M_PI;
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
      DirtyUp(dirtFullMatrix|dirtCache);
   }
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
      DirtyUp(dirtFullMatrix|dirtCache);
   }
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
      DirtyUp(dirtFullMatrix|dirtCache);
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

void DisplayObjectContainer::addChild(DisplayObject *inChild)
{
   IncRef();
   inChild->SetParent(this);

   mChildren.push_back(inChild);
   if (gDisplayRefCounting & drDisplayParentRefs)
      IncRef();

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
   RenderState state(inState);
   state.mTransform.mMatrix = &GetFullMatrix();
   if (mGfx)
   {
		mGfx->Render(inTarget,state);
   }

	for(int i=0;i<mChildren.size();i++)
		mChildren[i]->Render(inTarget,state);
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

   RenderState state;

	//gState.mTransform.mMatrix = Matrix().Rotate(rot).Translate(tx+100,200);
	state.mClipRect = Rect( render.Width(), render.Height() );
	state.mTransform.mAAFactor = mQuality;
	state.mAAClipRect = state.mClipRect * mQuality;


	Render(render.Target(),state);
}
