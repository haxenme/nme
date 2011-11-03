#include <hx/CFFI.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <Utils.h>
#include <jni.h>
#include <ByteArray.h>

#include <android/log.h>

JavaVM *gJVM=0;
JNIEnv *GetEnv()
{
   JNIEnv *env = 0;
   gJVM->AttachCurrentThread(&env, NULL);
   return env;
}


namespace nme
{

static class AndroidStage *sStage = 0;
static class AndroidFrame *sFrame = 0;
static FrameCreationCallback sOnFrame = 0;
static bool sCloseActivity = false;

static int sgNMEResult = 0;

enum { NO_TOUCH = -1 };

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
      mSingleTouchID = NO_TOUCH;
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
         if (mSingleTouchID==NO_TOUCH || inID==mSingleTouchID || mMultiTouch)
         {
            EventType type = (EventType)inType;
            if (!mMultiTouch)
            {
               switch(inType)
               {
                  case  etTouchBegin: type = etMouseDown; break;
                  case  etTouchEnd:   type = etMouseUp; break;
                  case  etTouchMove : type = etMouseMove; break;
                  case  etTouchTap:   return; break;
               }
            }

               Event mouse(type, inX, inY);
               if (mSingleTouchID==NO_TOUCH || inID==mSingleTouchID || !mMultiTouch)
                  mouse.flags |= efPrimaryTouch;

               if (inType==etTouchBegin)
               {
                  if (mSingleTouchID==NO_TOUCH)
                     mSingleTouchID = inID;
                  mouse.flags |= efLeftDown;
                  mDownX = inX;
                  mDownY = inY;
               }
               else if (inType==etTouchEnd)
               {
                  if (mSingleTouchID==inID)
                     mSingleTouchID = NO_TOUCH;
               }
               else if (inType==etTouchMove)
               {
                  mouse.flags |= efLeftDown;
               }
               mouse.value = inID;

               //if (inType==etTouchBegin)
                  //ELOG("DOWN %d %f,%f (%s)", inID, inX, inY, (mouse.flags & efPrimaryTouch) ? "P":"S" );

               //if (inType==etTouchEnd)
                  //ELOG("UP %d %f,%f (%s)", inID, inX, inY, (mouse.flags & efPrimaryTouch) ? "P":"S" );

               HandleEvent(mouse);
         }
   }

   void EnablePopupKeyboard(bool inEnable)
   {
      JNIEnv *env = GetEnv();
      jclass cls = env->FindClass("org/haxe/nme/GameActivity");
      jmethodID mid = env->GetStaticMethodID(cls, "showKeyboard", "(Z)V");
      if (mid == 0)
        return;

      env->CallStaticVoidMethod(cls, mid, (jboolean) inEnable);
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
   unsigned int inFlags, const char *inTitle, const char *inPackage, Surface *inIcon )
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
    JNIEnv *env = GetEnv();

    jclass cls = env->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = env->GetStaticMethodID(cls, "getResource", "(Ljava/lang/String;)[B");
    if (mid == 0)
        return 0;

    jstring str = env->NewStringUTF( inResource );
    jbyteArray bytes = (jbyteArray)env->CallStaticObjectMethod(cls, mid, str);
	env->DeleteLocalRef(str);
    if (bytes==0)
	 {
       return 0;
	 }

    jint len = env->GetArrayLength(bytes);
	 ByteArray result(len);
    env->GetByteArrayRegion(bytes, (jint)0, (jint)len, (jbyte*)result.Bytes());
    return result;
}

void AndoidRequestRender()
{
   JNIEnv *env = GetEnv();
	jclass cls =env->FindClass("org/haxe/nme/MainView");
   jmethodID mid = env->GetStaticMethodID(cls, "renderNow", "()V");
   if (mid == 0)
       return;
    env->CallStaticVoidMethod(cls, mid);
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
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   __android_log_print(ANDROID_LOG_INFO, "Resize", "%p  %d,%d", nme::sFrame, width, height);
   if (nme::sFrame)
      nme::sFrame->onResize(width,height);
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}



JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onRender(JNIEnv * env, jobject obj)
{
   env->GetJavaVM(&gJVM);

   int top = 0;
   gc_set_top_of_stack(&top,true);
   //double t0 = nme::GetTimeStamp();
   //__android_log_print(ANDROID_LOG_INFO, "NME", "NME onRender: %p", nme::sStage );
   if (nme::sStage)
      nme::sStage->OnRender();
   //__android_log_print(ANDROID_LOG_INFO, "NME", "Haxe Time: %f", nme::GetTimeStamp()-t0);
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTouch(JNIEnv * env, jobject obj, jint type, jfloat x, jfloat y, jint id)
{

   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnTouch(type,x,y,id);
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTrackball(JNIEnv * env, jobject obj, jfloat dx, jfloat dy)
{

   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnTrackball(dx,dy);
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onKeyChange(JNIEnv * env, jobject obj, int code, bool down)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnKey(code,down);
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onPoll(JNIEnv * env, jobject obj)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->OnPoll();
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}

JAVA_EXPORT double JNICALL Java_org_haxe_nme_NME_getNextWake(JNIEnv * env, jobject obj)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
	{
      double delta = nme::sStage->GetNextWake()-nme::GetTimeStamp();
      gc_set_top_of_stack(0,true);
      return delta;
	}
   gc_set_top_of_stack(0,true);
   return 3600*100000;
}


JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onActivity(JNIEnv * env, jobject obj, int inVal)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (nme::sStage)
      nme::sStage->onActivityEvent(inVal);
   gc_set_top_of_stack(0,true);
   return nme::GetResult();
}






} // end extern C





