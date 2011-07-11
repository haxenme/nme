#include <hx/CFFI.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <Utils.h>
#include <jni.h>
#include <ByteArray.h>

#include <android/log.h>

JNIEnv *gEnv = 0;



namespace nme
{

static class AndroidStage *sStage = 0;
static class AndroidFrame *sFrame = 0;
static FrameCreationCallback sOnFrame = 0;
static bool sCloseActivity = false;

static int sgNMEResult = 0;

int GetResult()
{
   if (sCloseActivity)
   {
      sCloseActivity = false;
      return -1;
   }
   int r = sgNMEResult;
   sgNMEResult = 0;
   return r;
}

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
      mMultiTouch = true;
      mSingleTouchID = 0;
      mDX = 0;
      mDY = 0;

      // Click detection
      mDownX = 0;
      mDownY = 0;
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

	void OnPoll()
   {
      Event evt(etPoll);
      HandleEvent(evt);
   }

   void onActivityEvent(int inVal)
   {
      __android_log_print(ANDROID_LOG_INFO, "NME", "Activity action %d", inVal);
      if (inVal==1 || inVal==2)
      {
         Event evt( inVal==1 ? etActivate : etDeactivate );
         HandleEvent(evt);
      }
   }
 

   void OnRender()
   {
      Event evt(etRedraw);
      HandleEvent(evt);
   }
   void Resize(int inWidth,int inHeight)
   {
      ResetHardwareContext();
      mHardwareContext->SetWindowSize(inWidth,inHeight);
      Event evt(etResize, inWidth, inHeight);
      HandleEvent(evt);
   }

   void OnKey(int inCode, bool inDown)
   {
      __android_log_print(ANDROID_LOG_ERROR, "NME", "OnKey %d %d", inCode, inDown);
      Event key( inDown ? etKeyDown : etKeyUp );
      key.code = inCode;
      key.value = inCode;
      HandleEvent(key);
   }

   void OnTrackball(double inX, double inY)
   {
      // __android_log_print(ANDROID_LOG_INFO, "NME", "Trackball %f %f", inX, inY);
   }

   void OnTouch(int inType,double inX, double inY, int inID)
   {
         if (mSingleTouchID==0 || inID==mSingleTouchID || mMultiTouch)
         {
            EventType type = (EventType)inType;
            if (!mMultiTouch)
            {
               switch(inType)
               {
                  case  etTouchBegin: type = etMouseDown; break;
                  case  etTouchEnd:   type = etMouseUp; break;
                  case  etTouchMove : type = etMouseMove; break;
                  case  etTouchTap:   type = etMouseClick; break;
               }
            }

               Event mouse(type, inX, inY);
               if (mSingleTouchID==0 || inID==mSingleTouchID || !mMultiTouch)
                  mouse.flags |= efPrimaryTouch;

               if (inType==etTouchBegin)
               {
                  if (mSingleTouchID==0)
                     mSingleTouchID = inID;
                  mouse.flags |= efLeftDown;
                  mDownX = inX;
                  mDownY = inY;
               }
               else if (inType==etTouchEnd)
               {
                  if (mSingleTouchID==inID)
                     mSingleTouchID = 0;
               }
               else if (inType==etTouchMove)
               {
                  mouse.flags |= efLeftDown;
               }
               mouse.value = inID;

               //ELOG("TOUCH %d %f,%f  %d(%d)", inID, inX, inY, type, mouse.flags & efPrimaryTouch );

               HandleEvent(mouse);
         }
   }

   bool getMultitouchSupported() { return true; }
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   bool getMultitouchActive() {  return mMultiTouch; }


   bool mMultiTouch;
   int  mSingleTouchID;
  
   double mDX;
   double mDY;

   double mDownX;
   double mDownY;

   HardwareContext *mHardwareContext;
   HardwareSurface *mHardwareSurface;
};



class AndroidFrame : public Frame
{
public:
   AndroidFrame(FrameCreationCallback inOnFrame, int inWidth,int inHeight,
       unsigned int inFlags, const char *inTitle, Surface *inIcon )
   {
      sOnFrame = inOnFrame;
      mFlags = inFlags;
      sFrame = this;
      //__android_log_print(ANDROID_LOG_INFO, "AndroidFrame", "Construct %p, sOnFrame=%p", sFrame,sOnFrame);
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
         //__android_log_print(ANDROID_LOG_INFO, "AndroidFrame::onResize",
            //"Create stage %p, sOnFrame=%p", sStage,sOnFrame);
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
   unsigned int inFlags, const char *inTitle, Surface *inIcon )
{
   __android_log_print(ANDROID_LOG_INFO, "CreateMainFrame!", "creating...");
   sOnFrame = inOnFrame;
   sFrame = new AndroidFrame(inOnFrame, inWidth, inHeight, inFlags,
                 inTitle, inIcon);
	//__android_log_print(ANDROID_LOG_INFO, "CreateMainFrame", "%dx%d  %p", inWidth,inHeight,sOnFrame);
}

void TerminateMainLoop()
{
   sCloseActivity = true;
}

ByteArray AndroidGetAssetBytes(const char *inResource)
{
    jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = gEnv->GetStaticMethodID(cls, "getResource", "(Ljava/lang/String;)[B");
    if (mid == 0)
        return 0;

    jstring str = gEnv->NewStringUTF( inResource );
    jbyteArray bytes = (jbyteArray)gEnv->CallStaticObjectMethod(cls, mid, str);
    if (bytes==0)
	 {
       return 0;
	 }

    jint len = gEnv->GetArrayLength(bytes);
	 ByteArray result(len);
    gEnv->GetByteArrayRegion(bytes, (jint)0, (jint)len, (jbyte*)result.Bytes());
    return result;
}

void AndoidRequestRender()
{
	jclass cls = gEnv->FindClass("org/haxe/nme/MainView");
   jmethodID mid = gEnv->GetStaticMethodID(cls, "renderNow", "()V");
   if (mid == 0)
       return;
    gEnv->CallStaticObjectMethod(cls, mid );
}



} // end namespace nme



extern "C"
{

#ifdef __GNUC__
  #define JAVA_EXPORT __attribute__ ((visibility("default"))) JNIEXPORT
#else
  #define JAVA_EXPORT JNIEXPORT
#endif

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onResize(JNIEnv * env, jobject obj,  jint width, jint height)
{
   gEnv = env;

   int top = 0;
   gc_set_top_of_stack(&top,true);
   __android_log_print(ANDROID_LOG_INFO, "Resize", "%p  %d,%d", nme::sFrame, width, height);
   if (nme::sFrame)
      nme::sFrame->onResize(width,height);
   return nme::GetResult();
}



JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onRender(JNIEnv * env, jobject obj)
{
   gEnv = env;

   int top = 0;
   gc_set_top_of_stack(&top,true);
   //double t0 = nme::GetTimeStamp();
   //__android_log_print(ANDROID_LOG_INFO, "NME", "NME onRender: %p", nme::sStage );
   if (nme::sStage)
      nme::sStage->OnRender();
   //__android_log_print(ANDROID_LOG_INFO, "NME", "Haxe Time: %f", nme::GetTimeStamp()-t0);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTouch(JNIEnv * env, jobject obj, jint type, jfloat x, jfloat y, jint id)
{
   gEnv = env;

   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnTouch(type,x,y,id);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTrackball(JNIEnv * env, jobject obj, jfloat dx, jfloat dy)
{
   gEnv = env;

   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnTrackball(dx,dy);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onKeyChange(JNIEnv * env, jobject obj, int code, bool down)
{
   gEnv = env;
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnKey(code,down);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onPoll(JNIEnv * env, jobject obj)
{
   gEnv = env;
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnPoll();
   return nme::GetResult();
}

JAVA_EXPORT double JNICALL Java_org_haxe_nme_NME_getNextWake(JNIEnv * env, jobject obj)
{
   gEnv = env;
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
	{
      double delta = nme::sStage->GetNextWake()-nme::GetTimeStamp();
      return delta;
	}
   return 3600*100000;
}


JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onActivity(JNIEnv * env, jobject obj, int inVal)
{
   gEnv = env;
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->onActivityEvent(inVal);
   return nme::GetResult();
}






} // end extern C





