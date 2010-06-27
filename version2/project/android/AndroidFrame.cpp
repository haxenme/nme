#include <hx/CFFI.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <jni.h>

#include <android/log.h>



namespace nme
{

static class AndroidStage *sStage = 0;
static class AndroidFrame *sFrame = 0;
static FrameCreationCallback sOnFrame = 0;
static bool sTerminal = false;

class AndroidStage : public Stage
{
public:
   AndroidStage(int inWidth,int inHeight,int inFlags) : Stage(true)
   {
      mHardwareContext = HardwareContext::CreateOpenGL(0,0);
      mHardwareContext->IncRef();
      mHardwareContext->SetWindowSize(inWidth,inHeight);
      mHardwareSurface = new HardwareSurface(mHardwareContext);
      mHardwareSurface->IncRef();
   }
   ~AndroidStage()
   {
      mHardwareSurface->DecRef();
      mHardwareContext->DecRef();
   }

   void Flip() { }
   void GetMouse()
   {
   }
   Surface *GetPrimarySurface() { return mHardwareSurface; }
   bool isOpenGL() const { return true; }
   virtual void SetCursor(Cursor inCursor) { }

   void OnRender()
   {
      Event evt(etRedraw);
      HandleEvent(evt);
   }
   void Resize(int inWidth,int inHeight)
   {
      mHardwareContext->SetWindowSize(inWidth,inHeight);
      Event evt(etResize, inWidth, inHeight);
      HandleEvent(evt);
   }


   HardwareContext *mHardwareContext;
   HardwareSurface *mHardwareSurface;
};



class AndroidFrame : public Frame
{
public:
   AndroidFrame(FrameCreationCallback inOnFrame, int inWidth,int inHeight,
       unsigned int inFlags, const char *inTitle, const char *inIcon )
   {
      sOnFrame = inOnFrame;
      mFlags = inFlags;
      sFrame = this;
      __android_log_print(ANDROID_LOG_INFO, "AndroidFrame", "Construct %p, sOnFrame=%p", sFrame,sOnFrame);
   }
   ~AndroidFrame()
   {
     if (sStage)
        sStage->DecRef();
     sStage = 0;
   }

   virtual void SetTitle() { }
   virtual void SetIcon() { }
   virtual Stage *GetStage() 
   {
      return sStage;
   }

   void onResize(int inWidth, int inHeight)
   {
      if (!sStage)
      {
         sStage = new AndroidStage(inWidth,inHeight,mFlags);
         __android_log_print(ANDROID_LOG_INFO, "AndroidFrame::onResize",
            "Create stage %p, sOnFrame=%p", sStage,sOnFrame);
         if (sOnFrame)
            sOnFrame(this);
      }
      else
      {
         ResetHardwareContext();
         sStage->Resize(inWidth,inHeight);
      }
   }

   unsigned int mFlags;
};


void CreateMainFrame( FrameCreationCallback inOnFrame, int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, const char *inIcon )
{
	__android_log_print(ANDROID_LOG_INFO, "CreateMainFrame!", "creating...");
   sOnFrame = inOnFrame;
   sFrame = new AndroidFrame(inOnFrame, inWidth, inHeight, inFlags,
                 inTitle, inIcon);
	__android_log_print(ANDROID_LOG_INFO, "CreateMainFrame", "%dx%d  %p", inWidth,inHeight,sOnFrame);
}

void TerminateMainLoop()
{
   sTerminal = true;
}

} // end namespace nme


extern "C"
{

#ifdef __GNUC__
  #define JAVA_EXPORT __attribute__ ((visibility("default"))) JNIEXPORT
#else
  #define JAVA_EXPORT JNIEXPORT
#endif

JAVA_EXPORT void JNICALL Java_org_haxe_NME_onResize(JNIEnv * env, jobject obj,  jint width, jint height)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   __android_log_print(ANDROID_LOG_INFO, "Resize", "%p  %d,%d", nme::sFrame, width, height);
   if (nme::sFrame)
      nme::sFrame->onResize(width,height);
}



JAVA_EXPORT void JNICALL Java_org_haxe_NME_onRender(JNIEnv * env, jobject obj)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnRender();
}


} // end extern C





