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
    if (getEnvStat == JNI_EDETACHED) {
        LOGE("GetEnv: not attached");
        if (_vm->AttachCurrentThread(&env, 0) != 0) {
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
	 //LOGE("Llamada a Findclass con: %s", className);
    std::string cppClassName(className);
    jclass ret;
    if(jClassCache[cppClassName]!=NULL)
    {
        ret = jClassCache[cppClassName];
        //LOGE("Devuelvo de la cache");
    }
    else
    {
        JNIEnv *env = GetEnv();
        
		  LOGE("pre llamar el metodo 0x%x 0x%x", gClassLoader, gFindClassMethod);
        
        jstring jClassName = env->NewStringUTF(className);
        jclass tmp = (jclass)env->CallObjectMethod(gClassLoader, gFindClassMethod, jClassName);
        env->DeleteLocalRef(jClassName);
        
        if (env->ExceptionCheck()) {
        		LOGE("Excepcion!");
        		env->ExceptionClear();
        		tmp = env->FindClass(className);
            /*
            jthrowable throwable = env->ExceptionOccurred();
            jclazz clazz = env->GetObjectClass(throwable);
            jmethodID getMessageMethod = env->GetMethodID(clazz, "getMessage", "()Ljava/lang/String;");
            jstring message = env->CallObjectMethod(throwable, getMessageMethod);
            const char *cMessage = env->GetStringUTFChars(message, NULL);
            if (cMessage) {
            	printf("ERROR: %s\n", cMessage);
               env->ReleaseStringUTFChars(message, cMessage);
            }
            env->DeleteLocalRef(clazz);
            */
        }
        
        LOGE("tmp vale: %i", tmp);
        
        ret = (jclass)env->NewGlobalRef(tmp);
        jClassCache[cppClassName] = ret;
    }
    return ret;
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved)
{
    _vm = vm;
    jClassCache = std::map<std::string, jclass>();
   
    // Intengo de guardar un class loader mas copado:
    JNIEnv *env = GetEnv();
    
    //int status = vm->GetEnv((void**)&env, JNI_VERSION_1_4);
    //replace with one of your classes in the line below
    jclass activityClass = env->FindClass("org/haxe/nme/GameActivity");
    jclass classClass = env->FindClass("java/lang/Class");
    jclass classLoaderClass = env->FindClass("java/lang/ClassLoader");
    jmethodID getClassLoaderMethod = env->GetMethodID(classClass, "getClassLoader", "()Ljava/lang/ClassLoader;");
    gClassLoader = (jclass)env->NewGlobalRef(env->CallObjectMethod(activityClass, getClassLoaderMethod));
    gFindClassMethod =env->GetMethodID(classLoaderClass, "findClass", "(Ljava/lang/String;)Ljava/lang/Class;");
    
    return  JNI_VERSION_1_4;                    // the required JNI version
    
}

