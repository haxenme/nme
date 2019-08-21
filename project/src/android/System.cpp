#include <jni.h>
#include <android/log.h>
#include <stdio.h>
#include <string>
#include <vector>
#include "AndroidCommon.h"

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

namespace nme {


	
	double CapabilitiesGetPixelAspectRatio () {
		
		JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetPixelAspectRatio", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenDPI () {
		
		JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenDPI", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenResolutionX () {
		
		JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenResolutionX", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenResolutionY () {
		
		JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenResolutionY", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	std::string CapabilitiesGetLanguage() {
		JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetLanguage", "()Ljava/lang/String;");
		if(mid == 0)
			return std::string("");
		jstring jLang = (jstring) env->CallStaticObjectMethod(cls, mid);
      return JStringToStdString(env,jLang,true);
	}
	
	void HapticVibrate (int period, int duration)
	{
		JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "vibrate", "(II)V");
		if (mid)
			env->CallStaticVoidMethod(cls, mid, period, duration);	
	}
	

	bool LaunchBrowser(const char *inUtf8URL)
	{
	   JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "launchBrowser", "(Ljava/lang/String;)V");
		if (mid == 0)
			return false;

		jstring str = env->NewStringUTF( inUtf8URL );
		env->CallStaticVoidMethod(cls, mid, str );
      env->DeleteLocalRef(str);
		return true;

	}
	
	
	std::string GetUserPreference(const char *inId)
	{
	   JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "getUserPreference", "(Ljava/lang/String;)Ljava/lang/String;");
		if (mid == 0)
		{
			return std::string("");
		}
		
		jstring jInId = env->NewStringUTF(inId);
		jstring jPref = (jstring) env->CallStaticObjectMethod(cls, mid, jInId);
		env->DeleteLocalRef(jInId);
      return JStringToStdString(env,jPref,true);
	}
	
	bool SetUserPreference(const char *inId, const char *inPreference)
	{
	   JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "setUserPreference", "(Ljava/lang/String;Ljava/lang/String;)V");
		if (mid == 0)
			return false;
	
		jstring jInId = env->NewStringUTF( inId );
		jstring jPref = env->NewStringUTF ( inPreference );
		env->CallStaticVoidMethod(cls, mid, jInId, jPref );
		env->DeleteLocalRef(jInId);
		env->DeleteLocalRef(jPref);
		return true;
	}
	
	
	bool ClearUserPreference(const char *inId)
	{
	   JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "clearUserPreference", "(Ljava/lang/String;)V");
		if (mid == 0)
			return false;
		
		jstring jInId = env->NewStringUTF( inId );
		env->CallStaticVoidMethod(cls, mid, jInId );
		env->DeleteLocalRef(jInId);
		return true;
	}


	bool SetClipboardText(const char* text) {
        JNIEnv *env = GetEnv();
        jclass cls = FindClass("org/haxe/nme/GameActivity");
        jmethodID mid = env->GetStaticMethodID(cls, "setClipboardText", "(Ljava/lang/String;)Z");
        if (mid == 0)
            return false;

        jstring jtext = env->NewStringUTF( text );
        bool result = env->CallStaticBooleanMethod (cls, mid, jtext);
        env->DeleteLocalRef(jtext);
        return result;
    }

    bool HasClipboardText(){
        JNIEnv *env = GetEnv();
        jclass cls = FindClass("org/haxe/nme/GameActivity");
        jmethodID mid = env->GetStaticMethodID(cls, "hasClipboardText", "()Z");
        if (mid == 0)
            return false;

        return env->CallStaticBooleanMethod (cls, mid);
    }

    const char* GetClipboardText(){
        JNIEnv *env = GetEnv();
        jclass cls = FindClass("org/haxe/nme/GameActivity");
        jmethodID mid = env->GetStaticMethodID(cls, "getClipboardText", "()Ljava/lang/String;");
        if (mid == 0)
            return std::string("").c_str();

        jstring jPref = (jstring) env->CallStaticObjectMethod(cls, mid);
        return JStringToStdString(env,jPref,true).c_str();
    }

}
