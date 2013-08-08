#include <directfb.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>

namespace nme
{

class DirectFBFrame;

DirectFBFrame *sgDirectFBFrame;
static IDirectFBSurface *primary = NULL;
static IDirectFB *dfb = NULL;
static int screen_width  = 0;
static int screen_height = 0;

#define DFBCHECK(x...)                                         \
  {                                                            \
    DFBResult err = x;                                         \
                                                               \
    if (err != DFB_OK)                                         \
      {                                                        \
        fprintf( stderr, "%s <%d>:\n\t", __FILE__, __LINE__ ); \
        DirectFBErrorFatal( #x, err );                         \
      }                                                        \
  }
//#define MAX_JOYSTICKS 16

class DirectFBStage : public Stage
{
public:
   DirectFBStage(/*DirectFBwindow *inWindow, */int inWidth, int inHeight)
      : /*mOpenGLContext(0),*/ mPrimarySurface(0)
   {
      //mWindow = inWindow;

      // size window for the first time
      Resize(inWidth, inHeight);
   }

   ~DirectFBStage()
   {
      //mOpenGLContext->DecRef();
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
      //DFBCHECK (primary->Flip (primary, NULL, (DFBSurfaceFlipFlags)0));
      //DirectFBSwapBuffers(mWindow);
   }

   void Resize(const int inWidth, const int inHeight)
   {
      // Calling this recreates the gl context and we loose all our textures and
      // display lists. So Work around it.
      /*if (mOpenGLContext)
      {
         gTextureContextVersion++;
         mOpenGLContext->DecRef();
      }
      mOpenGLContext = HardwareContext::CreateOpenGL(0, 0, true);
      mOpenGLContext->SetWindowSize(inWidth, inHeight);
      mOpenGLContext->IncRef();

      if (mPrimarySurface)
      {
         mPrimarySurface->DecRef();
      }
      mPrimarySurface = new HardwareSurface(mOpenGLContext);
      mPrimarySurface->IncRef();*/
   }

   //DirectFBwindow *mWindow;

private:
   //HardwareContext *mOpenGLContext;
   Surface *mPrimarySurface;
};

class DirectFBFrame : public Frame
{
public:
   DirectFBFrame(/*DirectFBwindow *inSurface, */int inW, int inH)
   {
      mStage = new DirectFBStage(/*inSurface,*/inW,inH);
      mStage->IncRef();
      // SetTimer(mHandle,timerFrame, 10,0);
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

   /*DirectFBwindow *GetWindow()
   {
      return mStage->mWindow;
   }*/

private:
   DirectFBStage *mStage;
};

void StartAnimation() {
   //while loop
	while (true) {
  DFBCHECK (primary->GetSize (primary, &screen_width, &screen_height));
  DFBCHECK (primary->SetColor (primary, 0x0, 0x0, 0x0, 0xFF));
  DFBCHECK (primary->FillRectangle (primary, 0, 0, screen_width, screen_height));
  DFBCHECK (primary->SetColor (primary, 0xFF, 0x80, 0xFF, 0xFF));
  
  //DFBCHECK (primary->DrawRectangle(primary, 0, 0, screen_width, screen_height));
  DFBCHECK (primary->DrawLine (primary,
			                      0, screen_height / 2,
			       screen_width - 1, screen_height / 2));
			                      
  DFBCHECK (primary->Flip (primary, NULL, (DFBSurfaceFlipFlags)0));
}
}
void PauseAnimation() {}
void ResumeAnimation() {}
void StopAnimation() {
	//primary->Release( primary );
  //dfb->Release( dfb );
   /*DirectFBwindow *window = sgDirectFBFrame->GetWindow();
   DirectFBDestroyWindow(window);
   DirectFBTerminate();*/
}


DirectFBFrame *createWindowFrame(const char *inTitle, int inWidth, int inHeight, unsigned int inFlags)
{
	DFBSurfaceDescription dsc;
  //DFBCHECK (DirectFBInit (&argc, &argv));
  DFBCHECK (DirectFBInit (0, NULL));
  DFBCHECK (DirectFBCreate (&dfb));
  DFBCHECK (dfb->SetCooperativeLevel (dfb, DFSCL_FULLSCREEN));
  dsc.flags = DSDESC_CAPS;
  dsc.caps  = (DFBSurfaceCapabilities) (DSCAPS_PRIMARY | DSCAPS_FLIPPING);
  DFBCHECK (dfb->CreateSurface( dfb, &dsc, &primary ));
   /*bool fullscreen = (inFlags & wfFullScreen) != 0;

   if (inFlags & wfResizable)
      DirectFBWindowHint(DirectFB_RESIZABLE, GL_TRUE);
   else
      DirectFBWindowHint(DirectFB_RESIZABLE, GL_FALSE);

   if (inFlags & wfBorderless)
      DirectFBWindowHint(DirectFB_DECORATED, GL_FALSE);

   DirectFBWindowHint(DirectFB_DEPTH_BITS, (inFlags & wfDepthBuffer ? 24 : 0));
   DirectFBWindowHint(DirectFB_STENCIL_BITS, (inFlags & wfStencilBuffer ? 8 : 0));

   if (inFlags & wfVSync)
      DirectFBSwapInterval(1);

   DirectFBwindow *window = DirectFBCreateWindow(inWidth, inHeight, inTitle, fullscreen ? DirectFBGetPrimaryMonitor() : NULL, NULL);
   if (!window)
   {
      fprintf(stderr, "Failed to create DirectFB window\n");
      DirectFBTerminate();
      return 0;
   }
   DirectFBMakeContextCurrent(window);

   DirectFBSetKeyCallback(window, key_callback);
   DirectFBSetMouseButtonCallback(window, mouse_button_callback);
   DirectFBSetCursorPosCallback(window, cursor_pos_callback);
   DirectFBSetWindowSizeCallback(window, window_size_callback);
   DirectFBSetWindowFocusCallback(window, window_focus_callback);
   // DirectFBSetWindowCloseCallback(window, window_close_callback);
	*/
   return new DirectFBFrame(/*window,*/ inWidth, inHeight);
}

void CreateMainFrame(FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, Surface *inIcon )
{
   //bool opengl = (inFlags & wfHardware) != 0;
   // sgShaderFlags = (inFlags & (wfAllowShaders|wfRequireShaders) );

   /*if (!DirectFBInit())
   {
      fprintf(stderr, "Could not initialize DirectFB\n");
      inOnFrame(0);
      return;
   }

   sgDirectFBFrame = createWindowFrame(inTitle, inWidth, inHeight, inFlags);
   inOnFrame(sgDirectFBFrame);

   StartAnimation();*/
   
   sgDirectFBFrame = createWindowFrame(inTitle, inWidth, inHeight, inFlags);
   inOnFrame(sgDirectFBFrame);

   StartAnimation();
}

void SetIcon(const char *path) {}

QuickVec<int>*  CapabilitiesGetScreenResolutions()
{
   // DirectFBInit();
   int count;
   QuickVec<int> *out = new QuickVec<int>();
   /*const DirectFBvidmode *modes = DirectFBGetVideoModes(DirectFBGetPrimaryMonitor(), &count);
   for (int i = 0; i < count; i++)
   {
      out->push_back( modes[i].width );
      out->push_back( modes[i].height );
   }*/
   return out;
}

double CapabilitiesGetScreenResolutionX()
{
   // DirectFBInit();
   //const DirectFBvidmode *mode = DirectFBGetVideoMode(DirectFBGetPrimaryMonitor());
   //return mode->width;
	return 0;
}

double CapabilitiesGetScreenResolutionY()
{
   // DirectFBInit();
   //const DirectFBvidmode *mode = DirectFBGetVideoMode(DirectFBGetPrimaryMonitor());
   //return mode->width;
	return 0;
}

}