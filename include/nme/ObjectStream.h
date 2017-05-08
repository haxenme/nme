#ifndef NME_OBJECT_STREAM_H
#define NME_OBJECT_STREAM_H

#include "Object.h"
#include "QuickVec.h"

#ifdef HXCPP_JS_PRIME
#include <emscripten.h>
#include <emscripten/bind.h>
#endif

namespace nme
{


struct ObjectStreamOut
{
   QuickVec<unsigned char> data;
   bool parentToo;

   ObjectStreamOut(bool inParentToo=true) : parentToo(inParentToo)
   {
   }

   inline int addInt(int inVal)
   {
      data.append((unsigned char *)&inVal,4);
      return inVal;
   }

   inline void append(const void *inData, int inBytes)
   {
      data.append((unsigned char *)inData, inBytes);
   }
   template<typename T>
   void add(const T& inData)
   {
      data.append((unsigned char *)&inData, sizeof(T));
   }
   template<typename T,int N>
   void addVec(const QuickVec<T,N> &inData)
   {
      addInt(inData.size());
      append(inData.ByteData(), inData.ByteCount());
   }

   bool addBool(bool inValue)
   {
      add(inValue);
      return inValue;
   }

   virtual void addObject(Object *inObj) = 0;

   /*
   {
      if (addBool(inObj))
         addHandle( inObj->toAbstract() );
   }

   inline void addHandle(const value &inHandle)
   {
      handleArray.set(count++, inHandle);
   }
   */

   //void toValue(value &outValue);
};


struct ObjectStreamIn
{
   const unsigned char *ptr;
   int len;

   ObjectStreamIn(const unsigned char *inPtr, int inLength)
       : ptr(inPtr), len(inLength)
   {
   }
   virtual ~ObjectStreamIn() { }

   virtual void linkAbstract(Object *inObject) { }

   inline int getInt()
   {
      int result;
      memcpy(&result,ptr,4);
      ptr+=4;
      len-=4;
      return result;
   }
   inline const unsigned char *getBytes(int inLen)
   {
      const unsigned char *result = ptr;
      ptr+=inLen;
      len-=inLen;
      return result;
   }

   template<typename T>
   void get(T& outData)
   {
      memcpy(&outData, ptr, sizeof(T));
      ptr+=sizeof(T);
      len-=sizeof(T);
   }
   template<typename T>
   void getVec(QuickVec<T> &outData)
   {
      int n = getInt();
      outData.resize(n);
      int size = n*sizeof(T);
      memcpy(outData.ByteData(), getBytes(size),size);
   }

   bool getBool()
   {
      bool result=false;
      get(result);
      return result;
   }

   virtual Object *decodeObject() = 0;


   template<typename T>
   void getObject(T *&outObject,bool inAddRef=true)
   {
      if (getBool())
      {
         Object *obj = decodeObject();
         outObject = dynamic_cast<T*>(obj);
         if (obj && !outObject)
         {
            printf("got object, but wrong type %p\n", obj);
         }
         else if (inAddRef)
            obj->IncRef();
      }
      else
      {
         outObject = 0;
      }
   }


};



#ifdef HXCPP_JS_PRIME
struct ValueObjectStreamOut : public ObjectStreamOut
{
   typedef emscripten::val value;

   value handleArray;
   int   count;

   ValueObjectStreamOut() : handleArray(value::object()), count(0)
   {
   }

   void addObject(Object *inObj)
   {
      if (addBool(inObj))
         handleArray.set(count++, inObj->toAbstract() );
   }

   void toValue(value &outValue);
};


struct ValueObjectStreamIn : public ObjectStreamIn
{
   typedef emscripten::val value;

   int count;
   value handleArray;
   value abstract;

   ValueObjectStreamIn(const unsigned char *inPtr, int inLength, value inHandles, value inAbstract)
       : ObjectStreamIn(inPtr,inLength), handleArray(inHandles), abstract(inAbstract)
   {
      count = 0;
   }

   void linkAbstract(Object *inObject);

   Object *decodeObject()
   {
      if (getBool())
      {
         value v = handleArray[count++];
         if (v.isNull() || v.isUndefined())
         {
            printf("Bad handle?\n");
            return 0;
         }
         return Object::toObject(v);
      }
      else
         return 0;
   }
};

#endif



}
#endif




