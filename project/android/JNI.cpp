#include <ExternalInterface.h>
#include <Utils.h>
#include <jni.h>
#include <ByteArray.h>

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
};


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



class HaxeJavaLink : public Object
{
public:
   HaxeJavaLink(const std::string &inClassName, value inHaxeOwner)
   {
      mHaxeOwner = inHaxeOwner;
      mHaxeRoot = new AutoGCRoot((value)0);
      mJavaObject = 0;
   }
   ~HaxeJavaLink()
   {
      delete mHaxeRoot;
   }
   void onJavaLinkLost()
   {
      mJavaObject = 0;
      mHaxeRoot->set((value)0);
   }
   jobject GetJObject()
   {
      if (!mJavaObject)
      {
         // While jobject is alive, we keep the haxe object alive
         mJavaObject = CreateInstance();
         mHaxeRoot->set(mHaxeOwner);
      }
      return mJavaObject;
   }

   jobject CreateInstance()
   {
      JNIEnv *env = GetEnv();
      jclass cls = env->FindClass("org/haxe/nme/GameActivity");
      if (!cls)
         return 0;

      jmethodID def = env->GetStaticMethodID(cls, "createInterfaceInstance", "(Ljava/lang/String;J)V");
      if (def != 0)
      {
         jstring name = env->NewStringUTF(mClassName.c_str());
   
         jobject result = env->CallStaticObjectMethod(cls, def, name, this);
         jthrowable exc = env->ExceptionOccurred();
         CheckException();
         return result;
      }
      return 0;
   }
 

   std::string mClassName;
   value       mHaxeOwner;
   jobject     mJavaObject;
   AutoGCRoot  *mHaxeRoot;
};




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
   jobject mObject;
};



bool AbstractToJObject(value inValue, jobject &outObject)
{
   if (AbstractToObject(inValue,outObject))
      return true;
   HaxeJavaLink *link = 0;
   if (AbstractToObject(inValue,link))
   {
      outObject = link->GetJObject();
      return true;
   }
 
   static int id__jobject = -1;
   if (id__jobject<0)
      id__jobject =  val_id("__jobject");
   value jobj = val_field(inValue,id__jobject);
   if (AbstractToObject(jobj,outObject))
      return true;
   if (AbstractToObject(inValue,link))
   {
      outObject = link->GetJObject();
      return true;
   }
 
   return false;
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

      JNIEnv *env = GetEnv();

      mClass = env->FindClass(val_string(inClass));
      const char *signature = val_string(inSignature);
      if (mClass)
      {
         if (inStatic)
            mMethod = env->GetStaticMethodID(mClass, val_string(inMethod), signature);
         else
            mMethod = env->GetMethodID(mClass, val_string(inMethod), signature);
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
         case jniObjectArray: return false; // TODO
         case jniObject:
            {
               jobject obj = 0;
               if (!AbstractToJObject(inValue,obj))
                  return false;
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
         if (!HaxeToJNI(inEnv,val_array_i(inArray,i),mArgs[i],outValues[i]))
         {
            ELOG("HaxeToJNI could not convert param %d",i);
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
         mArgs[mArgCount++] = type;
      }
      inSig++;
      ParseType(inSig,mReturn);
      return mReturn!=jniUnknown;
   }

   bool Ok() const { return mMethod>0; }

   value JObjectToHaxe(jobject inObject)
   {
      if (inObject==0)
         return alloc_null();
      JNIObject *obj = new JNIObject(inObject);
      return ObjectToAbstract(obj);
   }

   value JArrayToHaxe(jobject inObject)
   {
      // TODO: arrays
      return JObjectToHaxe(inObject);
   }

   value JStringToHaxe(JNIEnv *inEnv,jobject inObject)
   {
      jboolean is_copy;
      const char *str = inEnv->GetStringUTFChars( (jstring)inObject, &is_copy);
      value result = alloc_string(str);
      inEnv->ReleaseStringUTFChars((jstring)inObject, str);
      return result;
   }


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

      switch(mReturn)
      {
         case jniVoid:
            result = alloc_null();
            env->CallStaticVoidMethodA(mClass, mMethod, jargs);
            break;
         case jniObject:
            result = JObjectToHaxe(env->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectString:
            result = JStringToHaxe(env,env->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectArray:
            result = JArrayToHaxe(env->CallStaticObjectMethodA(mClass, mMethod, jargs));
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
         case jniObjectString:
            result = JStringToHaxe(env,env->CallObjectMethodA(inObject, mMethod, jargs));
            break;
         case jniObjectArray:
            result = JArrayToHaxe(env->CallObjectMethodA(inObject, mMethod, jargs));
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
   JNIType   mArgs[MAX];
   int       mArgCount;
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
   return method->CallStatic(inArgs);
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
   jclass cls = env->FindClass("org/haxe/nme/GameActivity");
   if (cls)
   {
      jmethodID mid = env->GetStaticMethodID(cls, "postUICallback", "(J)V");
      if (mid != 0)
      {
         AutoGCRoot *root = new AutoGCRoot(inCallback);
         ELOG("NME set onCallback %p",root);
         env->CallStaticVoidMethod(cls, mid, (jlong) root);
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
   }
   ELOG("nme_post_ui_callback - failed");
   return alloc_null();
}
DEFINE_PRIM(nme_post_ui_callback,1);

value nme_jni_create_interface(value inHaxeValue, value inClassName, value inClassDef)
{
   JNIEnv *env = GetEnv();
   jclass cls = env->FindClass("org/haxe/nme/GameActivity");
   if (!cls)
   {
      ELOG("nme_jni_create_interface - bad class");
      return alloc_null();
   }

   // Create class def
   buffer buf = val_to_buffer(inClassDef);
   if (buf!=0)
   {
      int len = buffer_size(buf);
      char *data = buffer_data(buf);

      ELOG("nme_jni_create_interface %d (%p)", len, data );

      jbyteArray bArray = env->NewByteArray( len );
      jbyte *jBytes = env->GetByteArrayElements( bArray, 0);
      if (jBytes)
      {
         memcpy(jBytes, data, len);
         env->ReleaseByteArrayElements(bArray, jBytes, 0);

         jmethodID def = env->GetStaticMethodID(cls, "defineClass", "([BLjava/lang/String;)V");
         if (def != 0)
         {
            jstring name = env->NewStringUTF(val_string(inClassName));
            env->CallStaticVoidMethod(cls, def, bArray, name);
            CheckException();
         }
         else
            ELOG("nme_jni_create_interface - no method", len, data );
      }
   }


   HaxeJavaLink *link = new HaxeJavaLink( val_string(inClassName), inHaxeValue );
   return ObjectToAbstract(link);
}
DEFINE_PRIM(nme_jni_create_interface,3);



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


JAVA_EXPORT jobject JNICALL Java_org_haxe_nme_NME_releaseInterface(JNIEnv * env, jobject obj, jlong handle)
{
   HaxeJavaLink *link = (HaxeJavaLink *)handle;
   link->onJavaLinkLost();
   return 0;
}



JAVA_EXPORT jobject JNICALL Java_org_haxe_nme_NME_callObjectFunction(JNIEnv * env, jobject obj, jlong handle, jstring function, jobject args)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);

   gc_set_top_of_stack(0,true);
   return 0;
}


JAVA_EXPORT jdouble JNICALL Java_org_haxe_nme_NME_callNumericFunction(JNIEnv * env, jobject obj, jlong handle, jstring function, jobject args)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);

   gc_set_top_of_stack(0,true);
   return 0.0;
}



}


