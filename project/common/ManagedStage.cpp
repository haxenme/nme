#include <Graphics.h>
#include <Display.h>
#include <Surface.h>
#include <windows.h>
#include <KeyCodes.h>
#include <map>

#include <gl/GL.h>

namespace nme
{


// --- Stage ------------------------------------------------------------------------


//typedef std::vector<Stage *> StageList;
static Stage *sgStage = 0;

ManagedStage::ManagedStage(int inWidth,int inHeight)
{
   mHardwareContext = 0;
   mHardwareSurface = 0;
   mCursor = curPointer;
   mIsHardware = true;
   HintColourOrder(mIsHardware);
	mActiveWidth = inWidth;
	mActiveHeight = inHeight;
	SetNominalSize(inWidth,inHeight);

   sgStage = this;

	mHardwareContext = HardwareContext::CreateOpenGL(0,0);
   mHardwareContext->IncRef();
   mHardwareSurface = new HardwareSurface(mHardwareContext);
   mHardwareSurface->IncRef();
}

ManagedStage::~ManagedStage()
{
   if (mHardwareContext)
      mHardwareContext->DecRef();
   if (mHardwareSurface)
      mHardwareSurface->DecRef();
}


void ManagedStage::SetCursor(Cursor inCursor)
{
  mCursor = inCursor;
}


void ManagedStage::SetActiveSize(int inW,int inH)
{
	mActiveWidth = inW;
	mActiveHeight = inH;
   mHardwareContext->SetWindowSize(inW,inH);

	Event event(etResize,inW,inH);
   Stage::HandleEvent(event);
}

Surface *ManagedStage::GetPrimarySurface()
{
  return mHardwareSurface;
}


} // end namespace nme

