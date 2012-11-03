#include <Display.h>
#include <Graphics.h>
#include <Surface.h>

namespace nme
{

static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;
static bool sgInitCalled = false;
static class WinRTFrame *sgWinRTFrame = 0;

enum { NO_TOUCH = -1 };

class WinRTStage : public Stage
{
public:
   WinRTStage(uint32 inFlags, int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      mFlags = inFlags;

      mIsFullscreen = true;

      mPrimarySurface = new HardwareSurface(mDXContext);

      mMultiTouch = true;
      mSingleTouchID = NO_TOUCH;
      mDX = 0;
      mDY = 0;

      // Click detection
      mDownX = 0;
      mDownY = 0;
   }

   ~WinRTStage()
   {
      mPrimarySurface->DecRef();
   }

   void Resize(int inWidth,int inHeight)
   {
      // Little hack to help windows
      //mSDLSurface->w = inWidth;
      //mSDLSurface->h = inHeight;
      //mDXContext->SetWindowSize(inWidth,inHeight);
      gTextureContextVersion++;

      //nme_resize_id ++;
      mDXContext->DecRef();
      mDXContext = HardwareContext::CreateDX11(0);
      mDXContext->SetWindowSize(inWidth, inHeight);
      mDXContext->IncRef();
      mPrimarySurface->DecRef();
      mPrimarySurface = new HardwareSurface(mDXContext);
   }

   void SetFullscreen(bool inFullscreen)
   {
      // Hmmm
      //Event resize(etResize,w,h);
      //ProcessEvent(resize);
   }

   bool isOpenGL() const { return false; }

   void ProcessEvent(Event &inEvent)
   {
      HandleEvent(inEvent);
   }


   void Flip()
   {
   }
   void GetMouse()
   {
   }

   void SetCursor(Cursor inCursor)
   {
   }

   void ShowCursor(bool inShow)
   {
      if (inShow!=mShowCursor)
      {
         mShowCursor = inShow;
         this->SetCursor(mCurrentCursor);
      }
   }
   
   
   void EnablePopupKeyboard(bool enabled)
   {
   }
   
   
   bool getMultitouchSupported()
   { 
       return true;
   }
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   bool getMultitouchActive()
   {
      return mMultiTouch;
   }
   
   bool mMultiTouch;
   int  mSingleTouchID;
  
   double mDX;
   double mDY;

   double mDownX;
   double mDownY;

   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }

   HardwareContext *mDXContext;
   Surface     *mPrimarySurface;
   double       mFrameRate;
   Cursor       mCurrentCursor;
   bool         mShowCursor;
   bool         mIsFullscreen;
   unsigned int mFlags;
   int          mWidth;
   int          mHeight;
};


class WinRTFrame : public Frame
{
public:
   WinRTFrame(uint32 inFlags, int inW,int inH)
   {
      mFlags = inFlags;
      mStage = new WinRTStage(mFlags,inW,inH);
      mStage->IncRef();
      // SetTimer(mHandle,timerFrame, 10,0);
   }
   ~WinRTFrame()
   {
      mStage->DecRef();
   }

   void ProcessEvent(Event &inEvent)
   {
      mStage->ProcessEvent(inEvent);
   }
   void Resize(int inWidth,int inHeight)
   {
      mStage->Resize(inWidth,inHeight);
   }

  // --- Frame Interface ----------------------------------------------------

   void SetTitle()
   {
   }
   void SetIcon()
   {
   }
   Stage *GetStage()
   {
      return mStage;
   }

   WinRTStage *mStage;
   uint32 mFlags;
   double mAccX;
   double mAccY;
   double mAccZ;
};


// --- When using the simple window class -----------------------------------------------

void CreateMainFrame(FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, Surface *inIcon )
{
   sgWinRTFrame = new WinRTFrame( inFlags, inWidth, inHeight );

   inOnFrame(sgWinRTFrame);

   //StartAnimation();
}

bool sgDead = false;

void SetIcon( const char *path ) { }

QuickVec<int> *CapabilitiesGetScreenResolutions()
{
   // TODO
   QuickVec<int> *out = new QuickVec<int>();
   out->push_back(1024);
   out->push_back(768);
   return out;
}

double CapabilitiesGetScreenResolutionX() { return sgDesktopWidth; }

double CapabilitiesGetScreenResolutionY() { return sgDesktopHeight; }
void PauseAnimation() {}
void ResumeAnimation() {}

void StopAnimation()
{
   sgDead = true;
}

void StartAnimation()
{
}


} // end namespace nme
