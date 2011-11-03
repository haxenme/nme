#include <jni.h>
#include <android/log.h>
#include <stdio.h>
#include <string>

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

extern JNIEnv *GetEnv();


namespace nme {


	
	double CapabilitiesGetPixelAspectRatio () {
		
		JNIEnv *env = GetEnv();
		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetPixelAspectRatio", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenDPI () {
		
		JNIEnv *env = GetEnv();
		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenDPI", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenResolutionX () {
		
		JNIEnv *env = GetEnv();
		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenResolutionX", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenResolutionY () {
		
		JNIEnv *env = GetEnv();
		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenResolutionY", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	

bool LaunchBrowser(const char *inUtf8URL)
{
   JNIEnv *env = GetEnv();
    jclass cls = env->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = env->GetStaticMethodID(cls, "launchBrowser", "(Ljava/lang/String;)V");
    if (mid == 0)
        return false;

    jstring str = env->NewStringUTF( inUtf8URL );

    env->CallStaticVoidMethod(cls, mid, str );
	return true;

}

std::string GetUserPreference(const char *inId)
{
   JNIEnv *env = GetEnv();
	jclass cls = env->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = env->GetStaticMethodID(cls, "getUserPreference", "(Ljava/lang/String;)Ljava/lang/String;");
    if (mid == 0)
	{
		return std::string("");
	}
	
	jstring jInId = env->NewStringUTF(inId);
	printf("about to call method");
	jstring jPref = (jstring) env->CallStaticObjectMethod(cls, mid, jInId);
	env->DeleteLocalRef(jInId);
	printf("about to create preference");
	const char *nativePref = env->GetStringUTFChars(jPref, 0);
	std::string result(nativePref);
	printf("about to release");
	env->ReleaseStringUTFChars(jPref, nativePref);
	printf("about to return.");
	return result;	
}
	//
bool SetUserPreference(const char *inId, const char *inPreference)
{
   JNIEnv *env = GetEnv();
    jclass cls = env->FindClass("org/haxe/nme/GameActivity");
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
    jclass cls = env->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = env->GetStaticMethodID(cls, "clearUserPreference", "(Ljava/lang/String;)V");
    if (mid == 0)
		return false;
	
    jstring jInId = env->NewStringUTF( inId );
    env->CallStaticVoidMethod(cls, mid, jInId );
	return true;
}


}
