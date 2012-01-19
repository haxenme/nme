#include <ExternalInterface.h>
#include <Utils.h>
#include <jni.h>
#include <pthread.h>
#include <ByteArray.h>
#include <map>

#include <android/log.h>

using namespace nme;

extern JNIEnv *GetEnv();

enum JNIType
{
   jniUnknown,
   jniVoid,
   jniObjectString,
   jniObjectArray,
   jniObject,
   jniBoolean,
   jniByte,
   jniChar,
   jniShort,
   jniInt,
   jniLong,
   jniFloat,
   jniDouble,
   jniObjectHaxe,
};

static bool sInit = false;
jclass GameActivity;
jmethodID postUICallback;
jclass HaxeObject;
jmethodID HaxeObject_create;
jfieldID __haxeHandle;

AutoGCRoot *gCallback = 0;

void JNIInit(JNIEnv *env)
{
   if (sInit)
      return;

   GameActivity = env->FindClass("org/haxe/nme/GameActivity");
   postUICallback = env->GetStaticMethodID(GameActivity, "postUICallback", "(J)V");

   HaxeObject   = env->FindClass("org/haxe/nme/HaxeObject");
   HaxeObject_create = env->GetStaticMethodID(HaxeObject, "create", "(J)Lorg/haxe/nme/HaxeObject;");
   __haxeHandle = env->GetFieldID(HaxeObject, "__haxeHandle", "J");

   sInit = true;
}

value nme_jni_init_callback(value inCallback)
{
   if (!gCallback)
      gCallback = new AutoGCRoot(inCallback);
   return alloc_null();
}
DEFINE_PRIM(nme_jni_init_callback,1);


void CheckException()
{
   JNIEnv *env = GetEnv();
   jthrowable exc = env->ExceptionOccurred();
   if (exc)
   {
      env->ExceptionDescribe();
      env->ExceptionClear();
      val_throw(alloc_string("JNI Exception"));
   }
}

struct JavaHaxeReference
{
   JavaHaxeReference(value inValue) : root(inValue)
   {
      refCount = 1;
   }

   int        refCount;
   AutoGCRoot root;
};

typedef std::map<value,JavaHaxeReference *> JavaHaxeReferenceMap;
JavaHaxeReferenceMap gJavaObjects;
bool gJavaObjectsMutexInit = false;
pthread_mutex_t gJavaObjectsMutex;

jobject CreateJavaHaxeObjectRef(JNIEnv *env,  value inValue)
{
   JNIInit(env);
   if (!gJavaObjectsMutexInit)
   {
      gJavaObjectsMutexInit = false;
      pthread_mutex_init(&gJavaObjectsMutex,0);
   }

   pthread_mutex_lock(&gJavaObjectsMutex);
   JavaHaxeReferenceMap::iterator it = gJavaObjects.find(inValue);
   if (it!=gJavaObjects.end())
      it->second->refCount++;
   else
      gJavaObjects[inValue] = new JavaHaxeReference(inValue);
   pthread_mutex_unlock(&gJavaObjectsMutex);

   jobject result = env->CallStaticObjectMethod(HaxeObject, HaxeObject_create, (jlong)inValue);
   jthrowable exc = env->ExceptionOccurred();
   CheckException();
   return result;
}

void RemoveJavaHaxeObjectRef(value inValue)
{
   pthread_mutex_lock(&gJavaObjectsMutex);
   JavaHaxeReferenceMap::iterator it = gJavaObjects.find(inValue);
   if (it!=gJavaObjects.end())
   {
      it->second->refCount--;
      if (!it->second->refCount)
      {
         delete it->second;
         gJavaObjects.erase(it);
      }
   }
   else
   {
      ELOG("Bad jni reference count");
   }
   pthread_mutex_unlock(&gJavaObjectsMutex);
}


struct JNIObject : public nme::Object
{
   JNIObject(jobject inObject)
   {
      mObject = inObject;
      if (mObject)
         GetEnv()->NewGlobalRef(mObject);
   }
   ~JNIObject()
   {
      if (mObject)
         GetEnv()->DeleteGlobalRef(mObject);
   }
   operator jobject() { return mObject; }
   jobject GetJObject() { return mObject; }
   jobject mObject;
};



bool AbstractToJObject(value inValue, jobject &outObject)
{
   JNIObject *jniobj = 0;
   if (AbstractToObject(inValue,jniobj))
   {
      outObject = jniobj->GetJObject();
      return true;
   }

   static int id__jobject = -1;
   if (id__jobject<0)
      id__jobject =  val_id("__jobject");

   value jobj = val_field(inValue,id__jobject);
   if (val_is_null(jobj))
      return false;

   return AbstractToJObject(jobj,outObject);
}


value JArrayToHaxe(JNIEnv *inEnv,jobject inObject)
{
   int len = inEnv->GetArrayLength((jarray)inObject);
   value result = alloc_array(len);
   //JObjectToHaxe(inObject);
   return result;
}

value JStringToHaxe(JNIEnv *inEnv,jobject inObject)
{
   jboolean is_copy;
   const char *str = inEnv->GetStringUTFChars( (jstring)inObject, &is_copy);
   value result = alloc_string(str);
   inEnv->ReleaseStringUTFChars((jstring)inObject, str);
   return result;
}

value JObjectToHaxe(jobject inObject)
{
   if (inObject==0)
      return alloc_null();
   JNIObject *obj = new JNIObject(inObject);
   value result =  ObjectToAbstract(obj);
   return result;
}

value JObjectToHaxeObject(JNIEnv *env,jobject inObject)
{
   JNIInit(env);

   if (inObject)
   {
      jlong val = env->GetLongField(inObject,__haxeHandle);
      return (value)val;
   }

   return alloc_null();
}




struct JNIMethod : public nme::Object
{
   enum { MAX = 20 };

   JNIMethod(value inClass, value inMethod, value inSignature,bool inStatic)
   {
      mClass = 0;
      mMethod = 0;
      mReturn = jniVoid;
      mArgCount = 0;

      const char *method = val_string(inMethod);
      mIsConstructor = !strncmp(method,"<init>",6);

      JNIEnv *env = GetEnv();

      mClass = env->FindClass(val_string(inClass));
      const char *signature = val_string(inSignature);
      if (mClass)
      {
         if (inStatic && !mIsConstructor)
            mMethod = env->GetStaticMethodID(mClass, method, signature);
         else
            mMethod = env->GetMethodID(mClass, method, signature);
      }
      if (Ok())
      {
         bool ok = ParseSignature(signature);
         if (!ok)
         {
            ELOG("Bad signature %s.", signature);
            mMethod = 0;
         }
      }
   }

   bool HaxeToJNI(JNIEnv *inEnv,value inValue, JNIType inType, jvalue &out)
   {
      switch(inType)
      {
         case jniObjectString:
            {
               out.l = inEnv->NewStringUTF(val_string(inValue));
               return true;
            }
         case jniObjectArray:
            ELOG("HaxeToJNI : jniObjectArray not implemented");
            return false; // TODO
         case jniObjectHaxe:
            out.l = CreateJavaHaxeObjectRef(inEnv,inValue);
            return true;
         case jniObject:
            {
               jobject obj = 0;
               if (!AbstractToJObject(inValue,obj))
               {
                  ELOG("HaxeToJNI : jniObject not an object %p", inValue);
                  return false;
               }
               out.l = obj;
               return true;
            }
         case jniBoolean: out.z = val_bool(inValue); return true;
         case jniByte: out.b = val_int(inValue); return true;
         case jniChar: out.c = val_int(inValue); return true;
         case jniShort: out.s = val_int(inValue); return true;
         case jniInt: out.i = val_int(inValue); return true;
         case jniLong: out.i = val_int(inValue); return true;
         case jniFloat: out.f = val_number(inValue); return true;
         case jniDouble: out.d = val_number(inValue); return true;
      }
      return false;
   }


   bool HaxeToJNIArgs(JNIEnv *inEnv, value inArray, jvalue *outValues)
   {
      if (val_array_size(inArray)!=mArgCount)
      {
         ELOG("Invalid array count: %d!=%d",val_array_size(inArray)!=mArgCount);
         return false;
      }
      for(int i=0;i<mArgCount;i++)
      {
         value arg_i = val_array_i(inArray,i);
         if (!HaxeToJNI(inEnv,arg_i,mArgType[i],outValues[i]))
         {
            ELOG("HaxeToJNI could not convert param %d (%p) to %d",i, arg_i, mArgType[i]);
            return false;
         }
      }
      return true;
   }

   void CleanStringArgs()
   {
   }

   const char *ParseType(const char *inStr, JNIType &outType)
   {
      switch(*inStr++)
      {
         case 'B': outType=jniBoolean; return inStr;
         case 'C': outType=jniChar; return inStr;
         case 'D': outType=jniDouble; return inStr;
         case 'F': outType=jniFloat; return inStr;
         case 'I': outType=jniInt; return inStr;
         case 'J': outType=jniLong; return inStr;
         case 'S': outType=jniShort; return inStr;
         case 'V': outType=jniVoid; return inStr;
         case 'Z': outType=jniBoolean; return inStr;
         case '[':
            {
            JNIType array_of;
            inStr = ParseType(inStr,array_of);
            outType = array_of==jniUnknown ? jniUnknown : jniObjectArray;
            return inStr;
            }
         case 'L':
            {
               const char *src = inStr;
               while(*inStr!='\0' && *inStr!=';' && *inStr!=')')
                  inStr++;
               if (*inStr!=';')
                  break;
               if (!strncmp(src,"java/lang/String;",17) ||
                   !strncmp(src,"java/lang/CharSequence;",23)  )
                  outType = jniObjectString;
               else if (!strncmp(src,"org/haxe/nme/HaxeObject;",24))
                  outType = jniObjectHaxe;
               else
                  outType = jniObject;
               return inStr+1;
            }
      }
      outType = jniUnknown;
      return inStr;
   }

   bool ParseSignature(const char *inSig)
   {
      if (*inSig++!='(')
          return false;

      mArgCount = 0;
      while(*inSig!=')')
      {
         if (mArgCount==MAX)
            return false;
         JNIType type;
         inSig = ParseType(inSig,type);
         if (type==jniUnknown)
            return false;
         mArgType[mArgCount++] = type;
      }
      inSig++;
      ParseType(inSig,mReturn);
      return mReturn!=jniUnknown;
   }

   bool Ok() const { return mMethod>0; }



   value CallStatic( value inArgs)
   {
      JNIEnv *env = GetEnv();
      jvalue jargs[MAX];
      if (!HaxeToJNIArgs(env,inArgs,jargs))
      {
         CleanStringArgs();
         ELOG("CallStatic - bad argument list");
         return alloc_null();
      }
      value result = 0;

      if (mIsConstructor)
      {
         jobject obj =  env->NewObjectA(mClass, mMethod, jargs);
         result =  JObjectToHaxe(obj);
      }
      else switch(mReturn)
      {
         case jniVoid:
            result = alloc_null();
            env->CallStaticVoidMethodA(mClass, mMethod, jargs);
            break;
         case jniObject:
            result = JObjectToHaxe(env->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectHaxe:
            result = JObjectToHaxeObject(env,env->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectString:
            result = JStringToHaxe(env,env->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectArray:
            result = JArrayToHaxe(env,env->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniBoolean:
            result = alloc_bool(env->CallStaticBooleanMethodA(mClass, mMethod, jargs));
            break;
         case jniByte:
            result = alloc_int(env->CallStaticByteMethodA(mClass, mMethod, jargs));
            break;
         case jniChar:
            result = alloc_int(env->CallStaticCharMethodA(mClass, mMethod, jargs));
            break;
         case jniShort:
            result = alloc_int(env->CallStaticShortMethodA(mClass, mMethod, jargs));
            break;
         case jniInt:
            result = alloc_int(env->CallStaticIntMethodA(mClass, mMethod, jargs));
            break;
         case jniLong:
            result = alloc_int(env->CallStaticLongMethodA(mClass, mMethod, jargs));
            break;
         case jniFloat:
            result = alloc_float(env->CallStaticFloatMethodA(mClass, mMethod, jargs));
            break;
         case jniDouble:
            result = alloc_float(env->CallStaticDoubleMethodA(mClass, mMethod, jargs));
            break;
      }

      CleanStringArgs();
      CheckException();
      return result;
   }



   value CallMember(jobject inObject, value inArgs)
   {
      JNIEnv *env = GetEnv();

      jvalue jargs[MAX];
      if (!HaxeToJNIArgs(env,inArgs,jargs))
      {
         CleanStringArgs();
         ELOG("CallMember - bad argument list");
         return alloc_null();
      }
      value result = 0;

      switch(mReturn)
      {
         case jniVoid:
            result = alloc_null();
            env->CallVoidMethodA(inObject, mMethod, jargs);
            break;
         case jniObject:
            result = JObjectToHaxe(env->CallObjectMethodA(inObject,mMethod, jargs));
            break;
         case jniObjectHaxe:
            result = JObjectToHaxeObject(env,env->CallObjectMethodA(inObject,mMethod, jargs));
            break;
         case jniObjectString:
            result = JStringToHaxe(env,env->CallObjectMethodA(inObject, mMethod, jargs));
            break;
         case jniObjectArray:
            result = JArrayToHaxe(env,env->CallObjectMethodA(inObject, mMethod, jargs));
            break;
         case jniBoolean:
            result = alloc_bool(env->CallBooleanMethodA(inObject, mMethod, jargs));
            break;
         case jniByte:
            result = alloc_int(env->CallByteMethodA(inObject, mMethod, jargs));
            break;
         case jniChar:
            result = alloc_int(env->CallCharMethodA(inObject, mMethod, jargs));
            break;
         case jniShort:
            result = alloc_int(env->CallShortMethodA(inObject, mMethod, jargs));
            break;
         case jniInt:
            result = alloc_int(env->CallIntMethodA(mClass, mMethod, jargs));
            break;
         case jniLong:
            result = alloc_int(env->CallLongMethodA(inObject, mMethod, jargs));
            break;
         case jniFloat:
            result = alloc_float(env->CallFloatMethodA(inObject, mMethod, jargs));
            break;
         case jniDouble:
            result = alloc_float(env->CallDoubleMethodA(inObject, mMethod, jargs));
            break;
      }

      CleanStringArgs();
      return result;
   }

   jclass    mClass;
   jmethodID mMethod;
   JNIType   mReturn;
   JNIType   mArgType[MAX];
   int       mArgCount;
   bool      mIsConstructor;
};


value nme_jni_create_method(value inClass, value inMethod, value inSig,value inStatic)
{
   JNIMethod *method = new JNIMethod(inClass,inMethod,inSig,val_bool(inStatic) );
   if (method->Ok())
      return ObjectToAbstract(method);
   ELOG("nme_jni_create_method - failed");
   delete method;
   return alloc_null();
}
DEFINE_PRIM(nme_jni_create_method,4);


value nme_jni_call_static(value inMethod, value inArgs)
{
   JNIMethod *method;
   if (!AbstractToObject(inMethod,method))
      return alloc_null();
   value result =  method->CallStatic(inArgs);
   return result;
}
DEFINE_PRIM(nme_jni_call_static,2);


value nme_jni_call_member(value inMethod, value inObject, value inArgs)
{
   JNIMethod *method;
   jobject object;
   if (!AbstractToObject(inMethod,method))
   {
      ELOG("nme_jni_call_member - not a method");
      return alloc_null();
   }
   if (!AbstractToJObject(inObject,object))
   {
      ELOG("nme_jni_call_member - invalid this");
      return alloc_null();
   }
   return method->CallMember(object,inArgs);
}
DEFINE_PRIM(nme_jni_call_member,3);




value nme_post_ui_callback(value inCallback)
{
   JNIEnv *env = GetEnv();
   JNIInit(env);

   AutoGCRoot *root = new AutoGCRoot(inCallback);
   ELOG("NME set onCallback %p",root);
   env->CallStaticVoidMethod(GameActivity, postUICallback, (jlong) root);
   jthrowable exc = env->ExceptionOccurred();
   if (exc)
   {
      env->ExceptionDescribe();
      env->ExceptionClear();
      delete root;
      val_throw(alloc_string("JNI Exception"));
   }

   return alloc_null();
}
DEFINE_PRIM(nme_post_ui_callback,1);


extern "C"
{

#ifdef __GNUC__
  #define JAVA_EXPORT __attribute__ ((visibility("default"))) JNIEXPORT
#else
  #define JAVA_EXPORT JNIEXPORT
#endif


JAVA_EXPORT void JNICALL Java_org_haxe_nme_NME_onCallback(JNIEnv * env, jobject obj, jlong handle)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);

   ELOG("NME onCallback %p",(void *)handle);
   AutoGCRoot *root = (AutoGCRoot *)handle;
   val_call0( root->get() );
   delete root;
   gc_set_top_of_stack(0,true);
}


JAVA_EXPORT jobject JNICALL Java_org_haxe_nme_NME_releaseReference(JNIEnv * env, jobject obj, jlong handle)
{
   value val = (value)handle;
   RemoveJavaHaxeObjectRef(val);
   return 0;
}

value CallHaxe(JNIEnv * env, jobject obj, jlong handle, jstring function, jobject inArgs)
{
   if (gCallback)
   {
      value objValue = (value)handle;
      value funcName = JStringToHaxe(env,function);
      value args = JArrayToHaxe(env,inArgs);
      return val_call3(gCallback->get(),objValue,funcName,args);
   }
   else
   {
      ELOG("NME CallHaxe - init not called.");
      return alloc_null();
   }
}



JAVA_EXPORT jobject JNICALL Java_org_haxe_nme_NME_callObjectFunction(JNIEnv * env, jobject obj, jlong handle, jstring function, jobject args)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);

   value result = CallHaxe(env,obj,handle,function,args);

   // TODO:
   //jobject val = JAnonToHaxe(result);
   jobject val = 0;

   gc_set_top_of_stack(0,true);
   return val;
}


JAVA_EXPORT jdouble JNICALL Java_org_haxe_nme_NME_callNumericFunction(JNIEnv * env, jobject obj, jlong handle, jstring function, jobject args)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);

   value result = CallHaxe(env,obj,handle,function,args);

   double val = val_number(result);

   gc_set_top_of_stack(0,true);
   return val;
}



}


