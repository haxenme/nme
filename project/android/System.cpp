#include <jni.h>
#include <android/log.h>
#include <stdio.h>

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

}