#include <directfb.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>


namespace nme
{


class DirectFBFrame;
DirectFBFrame *sgDirectFBFrame;
static IDirectFB *dfb = NULL;


class DirectFBStage : public Stage
{
public:
   DirectFBStage(IDirectFBSurface *inWindow, int inWidth, int inHeight) : mPrimarySurface(0)
   {
      mWindow = inWindow;
   }
   
   
   ~DirectFBStage()
   {
      mPrimarySurface->DecRef();
   }
   
   
   void SetCursor(Cursor inCursor)
   {
      switch (inCursor)
      {
         case curNone:
            break;
         case curPointer:
            break;
         case curHand:
            break;
      }
   }
   
   
   void GetMouse()
   {
      
   }
   
   
   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }
   
   
   bool isOpenGL() const { return false; }
   
   
   void Flip()
   {
      
   }
   
   
   void Resize(const int inWidth, const int inHeight)
   {
      
   }
   
   
   IDirectFBSurface *mWindow;
   
   
private:
   Surface *mPrimarySurface;
   
   
};



class DirectFBFrame : public Frame
{
public:
   DirectFBFrame(IDirectFBSurface *inWindow, int inWidth, int inHeight)
   {
      mStage = new DirectFBStage(inWindow, inWidth,inHeight);
      mStage->IncRef();
   }
   
   
   ~DirectFBFrame()
   {
      mStage->DecRef();
   }
   
   
   void Resize(const int inWidth, const int inHeight)
   {
      mStage->Resize(inWidth, inHeight);
   }
   
   
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
   
   
   inline void HandleEvent(Event &event)
   {
      mStage->HandleEvent(event);
   }
   
   
   IDirectFBSurface *GetWindow()
   {
      return mStage->mWindow;
   }
   
   
private:
   DirectFBStage *mStage;
   
   
};


void StartAnimation()
{
   while (true)
   {
      IDirectFBSurface *surface = sgDirectFBFrame->GetWindow();
      int screen_width, screen_height;
      surface->GetSize(surface, &screen_width, &screen_height);
      surface->SetColor(surface, 0x0, 0x0, 0x0, 0xFF);
      surface->FillRectangle(surface, 0, 0, screen_width, screen_height);
      surface->SetColor(surface, 0xFF, 0x80, 0xFF, 0xFF);
      //DFBCHECK (primary->DrawRectangle(primary, 0, 0, screen_width, screen_height));
      surface->DrawLine(surface, 0, screen_height / 2, screen_width - 1, screen_height / 2);               
      surface->Flip(surface, NULL, (DFBSurfaceFlipFlags)0);
   }
}


void PauseAnimation()
{
   
}


void ResumeAnimation()
{
   
}


void StopAnimation()
{
   
}


DirectFBFrame *createWindowFrame(const char *inTitle, int inWidth, int inHeight, unsigned int inFlags)
{
   DFBSurfaceDescription dsc;
   
   putenv ((char*)"DFBARGS=system=x11");
   
   DirectFBInit(0, NULL);
   DirectFBCreate(&dfb);
   dfb->SetCooperativeLevel(dfb, DFSCL_FULLSCREEN);
   
   dsc.flags = DSDESC_CAPS;
   dsc.caps = (DFBSurfaceCapabilities)(DSCAPS_PRIMARY | DSCAPS_FLIPPING);
   
   IDirectFBSurface *surface = NULL;
   
   dfb->CreateSurface(dfb, &dsc, &surface);
   
   return new DirectFBFrame(surface, inWidth, inHeight);
}


void CreateMainFrame(FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon)
{
   sgDirectFBFrame = createWindowFrame(inTitle, inWidth, inHeight, inFlags);
   inOnFrame(sgDirectFBFrame);
   
   StartAnimation();
}


void SetIcon(const char *path)
{
   
}


QuickVec<int>* CapabilitiesGetScreenResolutions()
{
   int count;
   QuickVec<int> *out = new QuickVec<int>();
   return out;
}


double CapabilitiesGetScreenResolutionX()
{
	return 0;
}


double CapabilitiesGetScreenResolutionY()
{
	return 0;
}


}