#include <hx/CFFI.h>
#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <Utils.h>
#include <StageVideo.h>
#include <jni.h>
#include <ByteArray.h>
#include <Sound.h>

#include <android/log.h>
#include "AndroidCommon.h"

#include <sys/types.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

JavaVM *gJVM = 0;
extern jclass GameActivity;

#define LOG(...) ((void)__android_log_print(ANDROID_LOG_VERBOSE, "NME", __VA_ARGS__))


jobject CreateJavaHaxeObjectRef(JNIEnv *env,  value inValue, bool inNme);

namespace nme
{

static class AndroidStage *sStage = 0;
static class AndroidFrame *sFrame = 0;
static FrameCreationCallback sOnFrame = 0;
static bool sCloseActivity = false;
static std::string launchAppLink = "";

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

class AndroidVideo : public StageVideo
{
   Stage                   *stage;
   std::string             lastUrl;
   bool                    vpIsSet;
   DRect                   viewport;
   double                  duration;
   int                     videoWidth;
   int                     videoHeight;

   jclass                  nmeVideoView;
   jmethodID               setStageVideoHandlerId;
   jmethodID               setPathId;
   jmethodID               playId;
   jmethodID               startId;
   jmethodID               pauseId;
   jmethodID               stopId;
   jmethodID               destroyId;
   jmethodID               getDurationId;
   jmethodID               getPositionId;
   jmethodID               getBufferedId;
   jmethodID               seekId;
   jmethodID               setVolumeId;
   jmethodID               setViewportId;

public:
   AndroidVideo(JNIEnv *env, Stage *inStage)
   {
      IncRef();
      this->stage = inStage;
      vpIsSet = false;
      videoWidth = 0;
      videoHeight = 0;
      duration = 0;
      nmeVideoView = FindClass("org/haxe/nme/NMEVideoView");
      playId = env->GetStaticMethodID(nmeVideoView, "nmePlay", "(Ljava/lang/String;DD)V");
      startId = env->GetStaticMethodID(nmeVideoView, "nmeStart", "()V");
      stopId = env->GetStaticMethodID(nmeVideoView, "nmeStop", "()V");
      destroyId = env->GetStaticMethodID(nmeVideoView, "nmeDestroy", "()V");
      pauseId = env->GetStaticMethodID(nmeVideoView, "nmePause", "()V");
      seekId = env->GetStaticMethodID(nmeVideoView, "nmeSeek", "(D)V");
      getDurationId = env->GetStaticMethodID(nmeVideoView, "nmeGetDuration", "()D");
      getPositionId = env->GetStaticMethodID(nmeVideoView, "nmeGetPosition", "()D");
      getBufferedId = env->GetStaticMethodID(nmeVideoView, "nmeGetBuffered", "()D");
      setVolumeId = env->GetStaticMethodID(nmeVideoView, "nmeSetVolume", "(D)V");
      setViewportId = env->GetStaticMethodID(nmeVideoView, "nmeSetViewport", "(DDDD)V");
   }


   void play(const char *inUrl, double inStart, double inLength)
   {
      LOG("video: play %s %f %f\n", inUrl, inStart, inLength);

      if (inUrl==lastUrl)
      {
         LOG("Replay\n");
         return;
      }

      lastUrl = inUrl;
      JNIEnv *env = GetEnv();

      jstring str = env->NewStringUTF( inUrl );
      env->CallStaticVoidMethod(nmeVideoView, playId, str ,inStart, inLength);
      env->DeleteLocalRef(str);
   }

   void seek(double inTime)
   {
      LOG("video: seek %f\n", inTime);
      JNIEnv *env = GetEnv();
      env->CallStaticVoidMethod(nmeVideoView, seekId, inTime);
   }

   void setPan(double x, double y)
   {
      LOG("video: setPan %f %f\n",x,y);
   }

   double getBufferedPercent()
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticDoubleMethod(nmeVideoView, getBufferedId);
   }

   void setZoom(double x, double y)
   {
      LOG("video: setZoom %f %f\n",x,y);
   }

   void setSoundTransform(double inVolume, double inPosition)
   {
      LOG("video: setSoundTransform %f %f\n", inVolume, inPosition);
      JNIEnv *env = GetEnv();
      return env->CallStaticVoidMethod(nmeVideoView, setVolumeId, inVolume);
   }

   void setViewport(double x, double y, double width, double height)
   {
      //LOG("video: setviewport %f %f %f %f\n",x,y, width,height);
      vpIsSet = true;
      JNIEnv *env = GetEnv();
      return env->CallStaticVoidMethod(nmeVideoView, setViewportId, x,y,width,height);
   }

   double getTime()
   {
      //NSTimeInterval t = player.currentPlaybackTime;
      //LOG("video: getTime %f\n", t);
      JNIEnv *env = GetEnv();
      return env->CallStaticDoubleMethod(nmeVideoView, getPositionId);
   }

   void pause()
   {
      LOG("video: pause\n");
      JNIEnv *env = GetEnv();
      env->CallStaticVoidMethod(nmeVideoView, pauseId);
   }

   void resume()
   {
      LOG("video: resume\n");
      JNIEnv *env = GetEnv();
      env->CallStaticVoidMethod(nmeVideoView, startId);
   }

   void togglePause()
   {
      LOG("video: togglePause\n");
      /*
      if (player.currentPlaybackRate>0)
         [player pause];
      else
         [player play];
      */
   }

   void destroy()
   {
      LOG("video: destroy\n");
      lastUrl = "";
      JNIEnv *env = GetEnv();
      env->CallStaticVoidMethod(nmeVideoView, destroyId);
      stage->cleanStageVideo();
   }

   void onFinished()
   { 
      //sendState( PLAY_STATUS_COMPLETE );
   }
};

class AndroidStage : public Stage
{
    
public:
   AndroidStage(int inWidth,int inHeight,int inFlags) : Stage(true)
   {
      mHardwareRenderer = HardwareRenderer::CreateOpenGL(0, 0, inFlags & (wfAllowShaders|wfRequireShaders));
      mHardwareRenderer->IncRef();
      mHardwareRenderer->SetWindowSize(inWidth,inHeight);
      mHardwareSurface = new HardwareSurface(mHardwareRenderer);
      mHardwareSurface->IncRef();
      mMultiTouch = true;
      mSingleTouchID = NO_TOUCH;
      video = 0;
      mDX = 0;
      mDY = 0;

      // Click detection
      mDownX = 0;
      mDownY = 0;

      mBackground = 0xff000000;

      normalOrientation = 0;
       
   }
   ~AndroidStage()
   {
      mHardwareSurface->DecRef();
      mHardwareRenderer->DecRef();
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

   StageVideo *createStageVideo(void *inOwner)
   {
      if (!video)
      {
         JNIEnv *env = GetEnv();

         jobject handler = CreateJavaHaxeObjectRef(env, (value)inOwner, true);

         jclass cls = FindClass("org/haxe/nme/GameActivity");
         jmethodID createVideoWindow = env->GetStaticMethodID(cls,"createStageVideo",
                      "(Lorg/haxe/nme/HaxeObject;)V");
         LOG("createStageVideo : %p", createVideoWindow);
         env->CallStaticVoidMethod(cls, createVideoWindow, handler );
         video = new AndroidVideo(env, this);
         video->setOwner( (value) inOwner );
      }

      return video;
   }
   
   void cleanStageVideo() {
       delete video;
       video = 0;
   }

   uint32 getBackgroundMask()
   {
      return video ? 0x00ffffff :  (mBackground|0xffffff);
   }


   void setOpaqueBackground(uint32 inBG)
   {
      Stage::setOpaqueBackground(inBG);
      if (mBackground != inBG)
      {
         mBackground = inBG;
         JNIEnv *env = GetEnv();
         jclass cls = FindClass("org/haxe/nme/GameActivity");
         jmethodID setBackground = env->GetStaticMethodID(cls,"setBackground","(I)V" );
         env->CallStaticVoidMethod(cls, setBackground, mBackground );
      }
   }


   void onActivityEvent(int inVal)
   {
      LOG("Activity action %d", inVal);
      if (inVal==1 || inVal==2)
      {
         Event evt( inVal==1 ? etActivate : etDeactivate );
         HandleEvent(evt);
      }
   }
   
   void handleAppLink(const char * c)
   {
      Event evt(etAppLink);
      evt.utf8Text = c;
      evt.utf8Length = evt.utf8Text ? strlen(evt.utf8Text) : 0;
      HandleEvent(evt);
   }

   void OnRender()
   {
      Event evt(etRedraw);
      HandleEvent(evt);
   }
   void Resize(int inWidth,int inHeight)
   {
      mHardwareRenderer->SetWindowSize(inWidth,inHeight);
      Event evt(etResize, inWidth, inHeight);
      HandleEvent(evt);
   }
   void OnContextLost()
   {
      //__android_log_print(ANDROID_LOG_INFO, "NME", "OnContextLost, ResetHardwareContext...");
      ResetHardwareContext();
      Event evt(etRenderContextLost);
      HandleEvent(evt);
   }

   void OnContextRestored()
   {
      //__android_log_print(ANDROID_LOG_INFO, "NME", "OnContextRestored");
      Event evt(etRenderContextRestored);
      HandleEvent(evt);
   }

   void OnKey(int inKeyCode, int inCharCode, bool inDown, bool isChar)
   {
      //__android_log_print(ANDROID_LOG_INFO, "NME", "OnKey %d %d", inCode, inDown);
      Event key( inDown ? etKeyDown : etKeyUp );
      key.code = inCharCode;
      key.value = inKeyCode;
      HandleEvent(key);
      
      if(isChar) {//if(inDown) {
         Event key( etChar );
         key.code = inCharCode;
         //key.value = inKeyCode;
         HandleEvent(key);
      }
   }


   void OnJoy(int inDeviceId, int inCode, bool inDown)
   {
      //__android_log_print(ANDROID_LOG_INFO, "NME", "OnJoy %d %d %d", inDeviceId, inCode, inDown);
      Event joystick( inDown ? etJoyButtonDown : etJoyButtonUp );
      joystick.id = inDeviceId;
      joystick.code = inCode;
      HandleEvent(joystick);
   }
   
   void OnJoyMotion(int inDeviceId, int inAxis, float inValue)
   {
      Event joystick(etJoyAxisMove);
      joystick.id = inDeviceId;
      joystick.code = inAxis;
      joystick.value = inValue;
      HandleEvent(joystick);
   }
   
   void OnTrackball(double inX, double inY)
   {
      // __android_log_print(ANDROID_LOG_INFO, "NME", "Trackball %f %f", inX, inY);
   }
   
   void OnMouseWheel(double inX, double inY, int inEventDir) {
       Event mouse(etMouseUp, inX, inY, inEventDir);
       mouse.deltaY = inEventDir==3 ? 1 : -1;
       HandleEvent(mouse);
   }

   void OnTouch(int inType,double inX, double inY, int inID, float sizeX, float sizeY)
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
               
               mouse.scaleX = sizeX;
               mouse.scaleY = sizeY;

               //if (inType==etTouchBegin)
                  //ELOG("DOWN %d %f,%f (%s) %f,%f", inID, inX, inY, (mouse.flags & efPrimaryTouch) ? "P":"S", sizeX, sizeY );

               //if (inType==etTouchEnd)
                  //ELOG("UP %d %f,%f (%s) %f,%f", inID, inX, inY, (mouse.flags & efPrimaryTouch) ? "P":"S", sizeX, sizeY );

               HandleEvent(mouse);
         }
   }

   void OnDeviceOrientationUpdate(int orientation)
   {
      currentDeviceOrientation = orientation;
      //__android_log_print(ANDROID_LOG_INFO, "NME", "Device Orientation %d", currentDeviceOrientation);
   }

   void OnNormalOrientationFound(int orientation)
   {
      normalOrientation = orientation;
      //__android_log_print(ANDROID_LOG_INFO, "NME", "Normal Orientation %d", normalOrientation);
   }

   void OnOrientationUpdate(double inX, double inY, double inZ)
   {
      mOrientationX = inX;
      mOrientationY = inY;
      mOrientationZ = inZ;
      //__android_log_print(ANDROID_LOG_INFO, "NME", "Orientation %f %f %f", inX, inY, inZ);
   }
   
   void OnAccelerate(double inX, double inY, double inZ)
   {
      if (normalOrientation == 0 || normalOrientation == 1) { // UNKNOWN || PORTRAIT
         mAccX = -inX / 9.80665;
         mAccY = -inY / 9.80665;
         mAccZ = -inZ / 9.80665;
      } else { // 4 || LANDSCAPE_LEFT
         mAccX = inY / 9.80665;
         mAccY = -inX / 9.80665;
         mAccZ = -inZ / 9.80665;
      }
      //__android_log_print(ANDROID_LOG_INFO, "NME", "Accelerometer %f %f %f", inX, inY, inZ);
   }

   void PopupKeyboard(PopupKeyboardMode inMode,WString *inValue)
   {
      JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
      jstring str = 0;
      if (inValue)
      {
         std::string cstr = WideToUTF8(*inValue);
         str = env->NewStringUTF( cstr.c_str() );
      }

      int sk;
      DisplayObject *fobj = GetFocusObject();
      if(fobj)
          sk = fobj->softKeyboard;
      else
          sk = softKeyboard;
      jmethodID mid = env->GetStaticMethodID(cls, "popupKeyboard", "(ILjava/lang/String;I)V");
      if (mid == 0)
        return;

      env->CallStaticVoidMethod(cls, mid, (int)inMode, str, sk);
   }

   void SetPopupTextSelection(int inSel0, int inSel1)
   {
      JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
      jmethodID mid = env->GetStaticMethodID(cls, "setPopupSelection", "(II)V");
      if (mid == 0)
        return;

      env->CallStaticVoidMethod(cls, mid, inSel0, inSel1);
   }

   bool getMultitouchSupported() { return true; }
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   bool getMultitouchActive() {  return mMultiTouch; }

   AndroidVideo *video;

   bool mMultiTouch;
   int  mSingleTouchID;
   uint32  mBackground;
  
   double mDX;
   double mDY;
   
   int currentDeviceOrientation;
   int normalOrientation;
   double mOrientationX;
   double mOrientationY;
   double mOrientationZ;
      
   double mAccX;
   double mAccY;
   double mAccZ;
      
   double mDownX;
   double mDownY;

   HardwareRenderer *mHardwareRenderer;
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

   virtual Stage *GetStage() 
   {
      return sStage;
   }

   void onContextLost()
   {
      if (sStage)
      {
         sStage->OnContextLost();
      }
   }

   void onContextRestored()
   {
      if (sStage)
      {
         sStage->OnContextRestored();
      }
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
            
         if (nme::launchAppLink != "")
         {
            std::string temp = nme::launchAppLink;
            nme::launchAppLink = "";
            sStage->handleAppLink(temp.c_str());
         }
      }
      else
      {
         sStage->Resize(inWidth,inHeight);
      }
   }

   unsigned int mFlags;
};


void CreateMainFrame( FrameCreationCallback inOnFrame, int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle,  Surface *inIcon )
{
   __android_log_print(ANDROID_LOG_INFO, "CreateMainFrame!", "creating...");
   sOnFrame = inOnFrame;
   sFrame = new AndroidFrame(inOnFrame, inWidth, inHeight, inFlags,
                 inTitle, inIcon);
	//__android_log_print(ANDROID_LOG_INFO, "CreateMainFrame", "%dx%d  %p", inWidth,inHeight,sOnFrame);
}

void StartAnimation()
{
   sCloseActivity = false;
}

void PauseAnimation()
{
   sCloseActivity = true;
}

void ResumeAnimation()
{
   sCloseActivity = false;
}

void StopAnimation()
{
   sCloseActivity = true;
}

AAssetManager* androidAssetManager = 0;
jclass androidAssetManagerRef = 0;


AAsset *AndroidGetAsset(const char *inResource)
{
   if (!androidAssetManager)
   {
      JNIEnv *env = GetEnv();
      jmethodID mid = env->GetStaticMethodID(GameActivity, "getAssetManager", "()Landroid/content/res/AssetManager;");
      if (mid == 0)
         return 0;
      
      jobject assetManager = (jobject)env->CallStaticObjectMethod(GameActivity, mid);
      if (assetManager==0)
      {
         //LOG("Could not find assetManager for asset %s", inResource);
         return 0;
      }
      
      androidAssetManager = AAssetManager_fromJava(env, assetManager);
      if (androidAssetManager==0)
      {
         LOG("Could not create assetManager for asset %s", inResource);
         return 0;
      }
      
      androidAssetManagerRef = (jclass)env->NewGlobalRef(assetManager);
      env->DeleteLocalRef(assetManager);
   }

   AAsset *result = AAssetManager_open(androidAssetManager, inResource, AASSET_MODE_UNKNOWN);

   return result;
}

ByteArray AndroidGetAssetBytes(const char *inResource)
{
   AAsset *asset = AndroidGetAsset(inResource);
   
   if (asset)
   {
      long size = AAsset_getLength(asset);
      ByteArray result(size);
      AAsset_read(asset, result.Bytes(), size);
      AAsset_close(asset);
      return result;
   }
   
   
   JNIEnv *env = GetEnv();
   
   jmethodID mid = env->GetStaticMethodID(GameActivity, "getResource", "(Ljava/lang/String;)[B");
   if (mid == 0)
      return 0;
   
   jstring str = env->NewStringUTF( inResource );
   jbyteArray bytes = (jbyteArray)env->CallStaticObjectMethod(GameActivity, mid, str);
   env->DeleteLocalRef(str);
   if (bytes==0)
      return 0;
   
   jint len = env->GetArrayLength(bytes);
   ByteArray result(len);
   env->GetByteArrayRegion(bytes, (jint)0, (jint)len, (jbyte*)result.Bytes());
   return result;
}

FileInfo AndroidGetAssetFD(const char *inResource)
{
   FileInfo info;
   info.fd = 0;
   info.offset = 0;
   info.length = 0;
   
   AAsset *asset = AndroidGetAsset(inResource);
   
   if (asset)
   {
      info.fd = AAsset_openFileDescriptor(asset, &info.offset, &info.length);
      if (info.fd <=0 )
         LOG("Bad asset : %s", inResource);
      AAsset_close(asset);
   }
   
   return info;
}

void AndroidRequestRender()
{
    JNIEnv *env = GetEnv();
    jclass cls = FindClass("org/haxe/nme/MainView");
    jmethodID mid = env->GetStaticMethodID(cls, "renderNow", "()V");
    if (mid == 0)
        return;
    env->CallStaticVoidMethod(cls, mid);
}

int GetDeviceOrientation() {
	if (sStage) {
		return sStage->currentDeviceOrientation;
	}
	return 0;
}

int GetNormalOrientation() {
	if (sStage) {
		return sStage->normalOrientation;
	}
	return 0;
}

bool GetOrientation(double& outX, double& outY, double& outZ) {
	if (sStage) {
		outX = sStage->mOrientationX;
		outY = sStage->mOrientationY;
		outZ = sStage->mOrientationZ;
		return true;
	}
	return false;
}

bool GetAcceleration(double& outX, double& outY, double& outZ) {
	if (sStage) {
		outX = sStage->mAccX;
		outY = sStage->mAccY;
		outZ = sStage->mAccZ;
		return true;
	}
	return false;
}

} // end namespace nme



extern "C"
{

static bool nmeContextIsLost = false;

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onResize(JNIEnv * env, jobject obj,  jint width, jint height)
{
   AutoHaxe haxe("onResize");
   if (nme::sFrame)
      nme::sFrame->onResize(width,height);
   return nme::GetResult();
}


JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onContextLost(JNIEnv * env, jobject obj)
{
   // Delay the result to just prior to render - docs seem to say you should
   //  do it here, but I seem to be missing something
   nmeContextIsLost = true;

   AutoHaxe haxe("onContextLost");
   //__android_log_print(ANDROID_LOG_INFO, "NME", "NME onContextLost !: %p", nme::sFrame );
   if (nme::sFrame)
      nme::sFrame->onContextLost();
   return 0;
}



JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onRender(JNIEnv * env, jobject obj)
{
   AutoHaxe haxe("onRender");
   if (nmeContextIsLost)
   {
      LOG("Send on lost");
      nmeContextIsLost = false;
      if (nme::sFrame)
         nme::sFrame->onContextRestored();
   }

   //double t0 = nme::GetTimeStamp();
   //__android_log_print(ANDROID_LOG_INFO, "NME", "NME onRender: %p", nme::sStage );
   if (nme::sStage)
      nme::sStage->OnRender();
   //__android_log_print(ANDROID_LOG_INFO, "NME", "Haxe Time: %f", nme::GetTimeStamp()-t0);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onNormalOrientationFound(JNIEnv * env, jobject obj, jint orientation)
{
   AutoHaxe haxe("onOrientation");
   if (nme::sStage)
      nme::sStage->OnNormalOrientationFound(orientation);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onDeviceOrientationUpdate(JNIEnv * env, jobject obj, jint orientation)
{
   AutoHaxe haxe("onDeviceOrientation");
   if (nme::sStage)
      nme::sStage->OnDeviceOrientationUpdate(orientation);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onOrientationUpdate(JNIEnv * env, jobject obj, jfloat x, jfloat y, jfloat z)
{
   AutoHaxe haxe("onUpdateOrientation");
   if (nme::sStage)
      nme::sStage->OnOrientationUpdate(x,y,z);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onAccelerate(JNIEnv * env, jobject obj, jfloat x, jfloat y, jfloat z)
{
   AutoHaxe haxe("onAcceration");
   if (nme::sStage)
      nme::sStage->OnAccelerate(x,y,z);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onMouseWheel(JNIEnv * env, jobject obj, jfloat x, jfloat y, jint eventDir)
{
   AutoHaxe haxe("onMouseWheel");
   if (nme::sStage)
      nme::sStage->OnMouseWheel(x,y,eventDir);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTouch(JNIEnv * env, jobject obj, jint type, jfloat x, jfloat y, jint id, jfloat sizeX, jfloat sizeY)
{
   AutoHaxe haxe("onTouch");
   if (nme::sStage)
      nme::sStage->OnTouch(type,x,y,id,sizeX,sizeY);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTrackball(JNIEnv * env, jobject obj, jfloat dx, jfloat dy)
{
   AutoHaxe haxe("onTrackball");
   if (nme::sStage)
      nme::sStage->OnTrackball(dx,dy);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onKeyChange(JNIEnv * env, jobject obj, int keyCode, int charCode, bool down, bool isChar)
{
   AutoHaxe haxe("onKey");
   if (nme::sStage)
      nme::sStage->OnKey(keyCode,charCode,down,isChar);
   return nme::GetResult();
}


JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onText(JNIEnv * env, jobject obj, jstring inText, int inReplacePos, int inReplaceLen)
{
   AutoHaxe haxe("onText");
   if (nme::sStage)
   {
      std::string text = JStringToStdString(env, inText, false);
      nme::sStage->onTextFieldText(text,inReplacePos,inReplaceLen);
   }
   return nme::GetResult();
}


JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onTextSelect(JNIEnv * env, jobject obj, int inReplacePos, int inReplaceLen)
{
   AutoHaxe haxe("onTextSelect");
   if (nme::sStage)
      nme::sStage->onTextFieldSelect(inReplacePos,inReplaceLen);

   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onJoyChange(JNIEnv * env, jobject obj, int deviceId, int code, bool down)
{
   AutoHaxe haxe("onJoy");
   if (nme::sStage)
      nme::sStage->OnJoy(deviceId,code,down);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onJoyMotion(JNIEnv * env, jobject obj, int deviceId, int axis, float value)
{
   AutoHaxe haxe("onJoyMotion");
   if (nme::sStage)
      nme::sStage->OnJoyMotion(deviceId,axis,value);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onPoll(JNIEnv * env, jobject obj)
{
   AutoHaxe haxe("onPoll");
   if (nme::sStage)
      nme::sStage->OnPoll();
   return nme::GetResult();
}

JAVA_EXPORT double JNICALL Java_org_haxe_nme_NME_getNextWake(JNIEnv * env, jobject obj)
{
   AutoHaxe haxe("onGetNextWake");
   if (nme::sStage)
   {
      if (nme::sStage->BuildCache())
      {
         nme::AndroidRequestRender();
         return 0;
      }
      return nme::sStage->GetNextWake()-nme::GetTimeStamp();
   }
   return 3600*100000;
}


JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onActivity(JNIEnv * env, jobject obj, int inVal)
{
   AutoHaxe haxe("onActivity");
   JNIInit(env);
   if (nme::sStage)
      nme::sStage->onActivityEvent(inVal);
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_setLaunchAppLink(JNIEnv * env, jobject obj, jstring url)
{
   AutoHaxe haxe("setLaunchAppLink");
   
   std::string string = JStringToStdString(env, url, true);
   nme::launchAppLink = string;
   
   return nme::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_nme_NME_onAppLink(JNIEnv * env, jobject obj, jstring url)
{
   AutoHaxe haxe("onAppLink");
   
   if (nme::sStage) {
      std::string string = JStringToStdString(env, url, true);
      nme::sStage->handleAppLink(string.c_str());
   }
   
   return nme::GetResult();
}


} // end extern C





