#include <ExternalInterface.h>
#include <Utils.h>
#include <jni.h>
#include <ByteArray.h>

#include <android/log.h>

using namespace nme;

extern JNIEnv *gEnv;

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

struct JNIObject : public nme::Object
{
   JNIObject(jobject inObject)
   {
      mObject = inObject;
      if (mObject)
         gEnv->NewGlobalRef(mObject);
   }
   ~JNIObject()
   {
      if (mObject)
         gEnv->DeleteGlobalRef(mObject);
   }
   operator jobject() { return mObject; }
   jobject mObject;
};

bool AbstractToJObject(value inValue, JNIObject *&outObject)
{
   if (AbstractToObject(inValue,outObject))
      return true;
   static int id__jobject = -1;
   if (id__jobject<0)
      id__jobject =  val_id("__jobject");
   value jobj = val_field(inValue,id__jobject);
   return AbstractToObject(jobj,outObject);
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

      mClass = gEnv->FindClass(val_string(inClass));
      const char *signature = val_string(inSignature);
      if (mClass)
      {
         if (inStatic)
            mMethod = gEnv->GetStaticMethodID(mClass,
               val_string(inMethod), signature);
         else
            mMethod = gEnv->GetMethodID(mClass,
               val_string(inMethod), signature);
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

   bool HaxeToJNI(value inValue, JNIType inType, jvalue &out)
   {
      switch(inType)
      {
         case jniObjectString:
            {
               out.l = gEnv->NewStringUTF(val_string(inValue));
               return true;
            }
         case jniObjectArray: return false; // TODO
         case jniObject:
            {
               JNIObject *obj = 0;
               if (!AbstractToJObject(inValue,obj))
                  return false;
               out.l = *obj;
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


   bool HaxeToJNIArgs(value inArray, jvalue *outValues)
   {
      if (val_array_size(inArray)!=mArgCount)
      {
         ELOG("Invalid array count: %d!=%d",val_array_size(inArray)!=mArgCount);
         return false;
      }
      for(int i=0;i<mArgCount;i++)
      {
         if (!HaxeToJNI(val_array_i(inArray,i),mArgs[i],outValues[i]))
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

   value JStringToHaxe(jobject inObject)
   {
      jboolean is_copy;
      const char *str = gEnv->GetStringUTFChars( (jstring)inObject, &is_copy);
      value result = alloc_string(str);
      gEnv->ReleaseStringUTFChars((jstring)inObject, str);
      return result;
   }


   value CallStatic( value inArgs)
   {
      jvalue jargs[MAX];
      if (!HaxeToJNIArgs(inArgs,jargs))
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
            gEnv->CallStaticVoidMethodA(mClass, mMethod, jargs);
            break;
         case jniObject:
            result = JObjectToHaxe(gEnv->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectString:
            result = JStringToHaxe(gEnv->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniObjectArray:
            result = JArrayToHaxe(gEnv->CallStaticObjectMethodA(mClass, mMethod, jargs));
            break;
         case jniBoolean:
            result = alloc_bool(gEnv->CallStaticBooleanMethodA(mClass, mMethod, jargs));
            break;
         case jniByte:
            result = alloc_int(gEnv->CallStaticByteMethodA(mClass, mMethod, jargs));
            break;
         case jniChar:
            result = alloc_int(gEnv->CallStaticCharMethodA(mClass, mMethod, jargs));
            break;
         case jniShort:
            result = alloc_int(gEnv->CallStaticShortMethodA(mClass, mMethod, jargs));
            break;
         case jniLong:
            result = alloc_int(gEnv->CallStaticLongMethodA(mClass, mMethod, jargs));
            break;
         case jniFloat:
            result = alloc_float(gEnv->CallStaticFloatMethodA(mClass, mMethod, jargs));
            break;
         case jniDouble:
            result = alloc_float(gEnv->CallStaticDoubleMethodA(mClass, mMethod, jargs));
            break;
      }

      CleanStringArgs();
      CheckException();
      return result;
   }

   void CheckException()
   {
      jthrowable exc = gEnv->ExceptionOccurred();
      if (exc)
      {
         gEnv->ExceptionDescribe();
         gEnv->ExceptionClear();
         val_throw(alloc_string("JNI Exception"));
      }
   }

   value CallMember(jobject inObject, value inArgs)
   {
      jvalue jargs[MAX];
      if (!HaxeToJNIArgs(inArgs,jargs))
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
            gEnv->CallVoidMethodA(inObject, mMethod, jargs);
            break;
         case jniObject:
            result = JObjectToHaxe(gEnv->CallObjectMethodA(inObject,mMethod, jargs));
            break;
         case jniObjectString:
            result = JStringToHaxe(gEnv->CallObjectMethodA(inObject, mMethod, jargs));
            break;
         case jniObjectArray:
            result = JArrayToHaxe(gEnv->CallObjectMethodA(inObject, mMethod, jargs));
            break;
         case jniBoolean:
            result = alloc_bool(gEnv->CallBooleanMethodA(inObject, mMethod, jargs));
            break;
         case jniByte:
            result = alloc_int(gEnv->CallByteMethodA(inObject, mMethod, jargs));
            break;
         case jniChar:
            result = alloc_int(gEnv->CallCharMethodA(inObject, mMethod, jargs));
            break;
         case jniShort:
            result = alloc_int(gEnv->CallShortMethodA(inObject, mMethod, jargs));
            break;
         case jniLong:
            result = alloc_int(gEnv->CallLongMethodA(inObject, mMethod, jargs));
            break;
         case jniFloat:
            result = alloc_float(gEnv->CallFloatMethodA(inObject, mMethod, jargs));
            break;
         case jniDouble:
            result = alloc_float(gEnv->CallDoubleMethodA(inObject, mMethod, jargs));
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


value nme_jni_call_member(value inObject, value inMethod, value inArgs)
{
   JNIMethod *method;
   JNIObject *object;
   if (!AbstractToObject(inMethod,method))
      return alloc_null();
   if (!AbstractToJObject(inObject,object))
      return alloc_null();
   return method->CallMember(object->mObject,inArgs);
}
DEFINE_PRIM(nme_jni_call_member,3);


