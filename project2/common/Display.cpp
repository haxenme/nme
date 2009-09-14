#include <Display.h>

unsigned int gDisplayRefCounting = drDisplayChildRefs;

// --- DisplayObject ------------------------------------------------

DisplayObject::DisplayObject(bool inInitRef) : Object(inInitRef)
{
   mParent = 0;
	mGfx = 0;
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
      mParent->RemoveChildFromList(this);

   mParent = inParent;

   DecRef();
}

void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
	if (mGfx)
		mGfx->Render(inTarget,inState);
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

void DisplayObjectContainer::Render( const RenderTarget &inTarget, const RenderState &inState )
{
	DisplayObject::Render(inTarget,inState);
	for(int i=0;i<mChildren.size();i++)
		mChildren[i]->Render(inTarget,inState);
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
