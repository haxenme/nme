#include "AndroidCommon.h"
#include <android/log.h>
#include <string>
#include <map>
#include <stdint.h> 

#undef LOGE
#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

JavaVM *_vm;
std::map<std::string, jclass> jClassCache;
static jobject gClassLoader;
static jmethodID gFindClassMethod;

JNIEnv *GetEnv()
{
    JNIEnv *env;
    int getEnvStat = _vm->GetEnv((void**)&env, JNI_VERSION_1_4);
    if (getEnvStat == JNI_EDETACHED)
    {
        LOGE("GetEnv: not attached");
        if (_vm->AttachCurrentThread(&env, 0) != 0)
        {
            LOGE("Failed to attach");
        }
    }
    return env;
}

JavaVM *getJavaVM()
{
	return _vm;
}

jclass FindClass(const char *className)
{
    std::string cppClassName(className);
    jclass ret;
    if(jClassCache[cppClassName]!=NULL)
    {
        ret = jClassCache[cppClassName];
    }
    else
    {
        JNIEnv *env = GetEnv();
        jstring jClassName = env->NewStringUTF(className);
        jclass tmp = (jclass)env->CallObjectMethod(gClassLoader, gFindClassMethod, jClassName);
        env->DeleteLocalRef(jClassName);
        if (env->ExceptionCheck())
        {
            env->ExceptionClear();
            tmp = env->FindClass(className);
        }
        ret = (jclass)env->NewGlobalRef(tmp);
        jClassCache[cppClassName] = ret;
    }
    return ret;
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved)
{
    _vm = vm;
    jClassCache = std::map<std::string, jclass>();
   
    JNIEnv *env = GetEnv();

    jclass activityClass = env->FindClass("org/haxe/nme/GameActivity");
    jclass classClass = env->FindClass("java/lang/Class");
    jclass classLoaderClass = env->FindClass("java/lang/ClassLoader");
    jmethodID getClassLoaderMethod = env->GetMethodID(classClass, "getClassLoader", "()Ljava/lang/ClassLoader;");
    gClassLoader = (jclass)env->NewGlobalRef(env->CallObjectMethod(activityClass, getClassLoaderMethod));
    gFindClassMethod =env->GetMethodID(classLoaderClass, "findClass", "(Ljava/lang/String;)Ljava/lang/Class;");
    
    return  JNI_VERSION_1_4;                    // the required JNI version
    
}
