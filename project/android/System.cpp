#include <jni.h>
#include <android/log.h>
#include <stdio.h>
#include <string>

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

extern JNIEnv *gEnv;

namespace nme {

bool LaunchBrowser(const char *inUtf8URL)
{
    jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = gEnv->GetStaticMethodID(cls, "launchBrowser", "(Ljava/lang/String;)V");
    if (mid == 0)
        return false;

    jstring str = gEnv->NewStringUTF( inUtf8URL );

    gEnv->CallStaticObjectMethod(cls, mid, str );
	return true;

}

std::string GetUserPreference(const char *inId)
{
	jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = gEnv->GetStaticMethodID(cls, "getUserPreference", "(Ljava/lang/String;)Ljava/lang/String;");
    if (mid == 0)
	{
		return std::string("");
	}
	
	jstring jInId = gEnv->NewStringUTF(inId);
	printf("about to call method");
	jstring jPref = (jstring) gEnv->CallStaticObjectMethod(cls, mid, jInId);
	printf("about to create preference");
	const char *nativePref = gEnv->GetStringUTFChars(jPref, 0);
	std::string result(nativePref);
	printf("about to release");
	gEnv->ReleaseStringUTFChars(jPref, nativePref);
	printf("about to return.");
	return result;	
}
	//
bool SetUserPreference(const char *inId, const char *inPreference)
{
    jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = gEnv->GetStaticMethodID(cls, "setUserPreference", "(Ljava/lang/String;Ljava/lang/String;)V");
    if (mid == 0)
		return false;
	
    jstring jInId = gEnv->NewStringUTF( inId );
	jstring jPref = gEnv->NewStringUTF ( inPreference );
    gEnv->CallStaticObjectMethod(cls, mid, jInId, jPref );
	return true;
}

bool ClearUserPreference(const char *inId)
{
    jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
    jmethodID mid = gEnv->GetStaticMethodID(cls, "clearUserPreference", "(Ljava/lang/String;)V");
    if (mid == 0)
		return false;
	
    jstring jInId = gEnv->NewStringUTF( inId );
    gEnv->CallStaticObjectMethod(cls, mid, jInId );
	return true;
}


}