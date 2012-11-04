#include <Display.h>
#include <Graphics.h>
#include <Surface.h>
#include "Direct3DBase.h"
#include "BasicTimer.h"

using namespace Windows::ApplicationModel;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::ApplicationModel::Activation;
using namespace Windows::UI::Core;
using namespace Windows::System;
using namespace Windows::Foundation;
using namespace Windows::Graphics::Display;
using namespace concurrency;

namespace nme
{

static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;
static bool sgInitCalled = false;
static class WinRTFrame *sgWinRTFrame = 0;

enum { NO_TOUCH = -1 };

class WinRTStage : public Stage, public Direct3DBase
{
public:
   WinRTStage(uint32 inFlags, int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      mFlags = inFlags;

      mIsFullscreen = true;

      mDXContext = HardwareContext::CreateDX11(0);

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

   void Render()
   {
      RenderStage();
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




// --- The app class --------------------------------------------------------

static FrameCreationCallback sgOnFrame = 0;

ref class Direct3DApp sealed : public Windows::ApplicationModel::Core::IFrameworkView
{
   int width;
   int height;
   unsigned int flags;

public:
   Direct3DApp(int inWidth, int inHeight, unsigned int inFlags)
   {
      m_windowClosed = false;
      m_windowVisible = true;
      width = inWidth;
      height = inHeight;
      flags = inFlags;
   }

   // IFrameworkView Methods.
   virtual void Initialize(Windows::ApplicationModel::Core::CoreApplicationView^ applicationView)
   {
      applicationView->Activated +=
           ref new TypedEventHandler<CoreApplicationView^, IActivatedEventArgs^>(this, &Direct3DApp::OnActivated);
      CoreApplication::Suspending +=
           ref new ::EventHandler<SuspendingEventArgs^>(this, &Direct3DApp::OnSuspending);
      CoreApplication::Resuming +=
           ref new ::EventHandler<Platform::Object^>(this, &Direct3DApp::OnResuming);
   }

   virtual void SetWindow(Windows::UI::Core::CoreWindow^ window)
   {
      window->SizeChanged += 
           ref new TypedEventHandler<CoreWindow^, WindowSizeChangedEventArgs^>(this, &Direct3DApp::OnWindowSizeChanged);

      window->VisibilityChanged +=
         ref new TypedEventHandler<CoreWindow^, VisibilityChangedEventArgs^>(this, &Direct3DApp::OnVisibilityChanged);

      window->Closed += 
           ref new TypedEventHandler<CoreWindow^, CoreWindowEventArgs^>(this, &Direct3DApp::OnWindowClosed);

      window->PointerCursor = ref new CoreCursor(CoreCursorType::Arrow, 0);

      window->PointerPressed +=
         ref new TypedEventHandler<CoreWindow^, PointerEventArgs^>(this, &Direct3DApp::OnPointerPressed);

      window->PointerMoved +=
         ref new TypedEventHandler<CoreWindow^, PointerEventArgs^>(this, &Direct3DApp::OnPointerMoved);

      bootNME();

      mStage->Initialize(CoreWindow::GetForCurrentThread());
   }


   virtual void Load(Platform::String^ entryPoint)
   {
   }

   virtual void Run()
   {
      BasicTimer^ timer = ref new BasicTimer();

      while (!m_windowClosed)
      {
         if (m_windowVisible)
         {
            timer->Update();
            CoreWindow::GetForCurrentThread()->Dispatcher->ProcessEvents(CoreProcessEventsOption::ProcessAllIfPresent);
            //mStage->Update(timer->Total, timer->Delta);
            mStage->Render();
            mStage->Present(); // This call is synchronized to the display frame rate.
         }
         else
         {
            CoreWindow::GetForCurrentThread()->Dispatcher->ProcessEvents(CoreProcessEventsOption::ProcessOneAndAllPending);
         }
      }
   }

   virtual void Uninitialize()
   {
   }


protected:

   void bootNME()
   {
      mFrame = new WinRTFrame(flags,width,height);
      mStage = mFrame->mStage;
      if (sgOnFrame)
      {
         sgOnFrame(mFrame);
         sgOnFrame = 0;
      }
   }


   // Event Handlers.
   void OnWindowSizeChanged(CoreWindow^ sender, WindowSizeChangedEventArgs^ args)
   {
   }

   void OnLogicalDpiChanged(Platform::Object^ sender)
   {
   }
   void OnActivated(Windows::ApplicationModel::Core::CoreApplicationView^ applicationView,
                    Windows::ApplicationModel::Activation::IActivatedEventArgs^ args)
   {
   }
   void OnSuspending(Platform::Object^ sender, Windows::ApplicationModel::SuspendingEventArgs^ args)
   {
   }
   void OnResuming(Platform::Object^ sender, Platform::Object^ args)
   {
   }
   void OnWindowClosed(CoreWindow^ sender, CoreWindowEventArgs^ args)
   {
   }
   void OnVisibilityChanged(CoreWindow^ sender,VisibilityChangedEventArgs^ args)
   {
   }
   void OnPointerPressed(CoreWindow^ sender, PointerEventArgs^ args)
   {
   }
   void OnPointerMoved(CoreWindow^ sender, PointerEventArgs^ args)
   {
   }

private:
   WinRTFrame  *mFrame;
   WinRTStage  *mStage;
   bool m_windowClosed;
   bool m_windowVisible;
};



// --- When using the simple window class -----------------------------------------------

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



// --- AppSource -------------------------------------------------------

ref class Direct3DAppSource sealed : Windows::ApplicationModel::Core::IFrameworkViewSource
{
   int width;
   int height;
   unsigned int flags;

public:
   Direct3DAppSource(int inWidth, int inHeight, unsigned int inFlags)
   {
      width = inWidth;
      height = inHeight;
      flags = inFlags;
   }

   virtual IFrameworkView^ Direct3DAppSource::CreateView()
   {
      auto result = ref new Direct3DApp(width,height,flags);
      return result;
   }
};


// --- External -------------------------------------------------------

void CreateMainFrame(FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, Surface *inIcon )
{
   sgOnFrame = inOnFrame;

   auto source = ref new Direct3DAppSource(inWidth,inHeight,inFlags);

   CoreApplication::Run(source);
}



} // end namespace nme






