#include "AndroidCommon.h"
#include <android/log.h>

#undef LOGE
#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

JavaVM *_vm;

JNIEnv *GetEnv()
{
    JNIEnv *env;
    _vm->GetEnv((void**)&env, JNI_VERSION_1_4);
    return env;
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved)
{
    _vm = vm;
    return  JNI_VERSION_1_4; /* the required JNI version */
}

