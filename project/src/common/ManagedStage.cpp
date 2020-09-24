#include <Graphics.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <map>


namespace nme
{


// --- Stage ------------------------------------------------------------------------


//typedef std::vector<Stage *> StageList;
static Stage *sgStage = 0;

ManagedStage::ManagedStage(int inWidth,int inHeight,int inFlags)
{
   mHardwareRenderer = 0;
   mHardwareSurface = 0;
   mCursor = curPointer;
   mIsHardware = true;
   mActiveWidth = inWidth;
   mActiveHeight = inHeight;
   SetNominalSize(inWidth,inHeight);

   sgStage = this;

   #if NME_OGL
   mHardwareRenderer = HardwareRenderer::CreateOpenGL(0, 0, inFlags & wfAllowShaders);
   #elif defined(NME_METAL)
   // TODO?
   mHardwareRenderer = HardwareRenderer::CreateMetal(0);
   #else
   #error "No valid HardwareRenderer"
   #endif
   mHardwareRenderer->IncRef();
   mHardwareSurface = new HardwareSurface(mHardwareRenderer);
   mHardwareSurface->IncRef();
}

ManagedStage::~ManagedStage()
{
   if (mHardwareRenderer)
      mHardwareRenderer->DecRef();
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
   mHardwareRenderer->SetWindowSize(inW,inH);

   Event event(etResize,inW,inH);
   Stage::HandleEvent(event);
}

void ManagedStage::PumpEvent(Event &inEvent)
{
   if (inEvent.type==etResize)
   {
      SetActiveSize(inEvent.x, inEvent.y);
   }
   else
      Stage::HandleEvent(inEvent);
}

Surface *ManagedStage::GetPrimarySurface()
{
  return mHardwareSurface;
}


} // end namespace nme

