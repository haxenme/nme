#ifndef NME_CFFI_H
#define NME_CFFI_H

#ifdef STATIC_LINK
  #define HXCPP_NO_PRIME_EXPORT
#endif

#ifdef HXCPP_JS_PRIME
#include "NmeJsPrime.h"
#include <Utils.h>

#else

#include <hx/CFFIPrime.h>
#include <string>
#include <Utils.h>


typedef value * values_array;

inline bool value_array_ok(values_array a) { return a; }
inline int array_get_int(values_array a, int inIndex) { return val_int(a[inIndex]); }
inline bool array_get_bool(values_array a, int inIndex) { return val_bool(a[inIndex]); }
inline float array_get_float(values_array a, int inIndex) { return val_float(a[inIndex]); }
inline double array_get_double(values_array a, int inIndex) { return val_float(a[inIndex]); }
inline value array_get_value(values_array a, int inIndex) { return a[inIndex]; }

inline void array_set_int(values_array a, int inIndex, int val) { a[inIndex] = alloc_int(val); }
inline void array_set_bool(values_array a, int inIndex, bool val) { a[inIndex] = alloc_bool(val); }
inline void array_set_float(values_array a, int inIndex, float val) { a[inIndex] = alloc_float(val); }
inline void array_set_double(values_array a, int inIndex, double val) { a[inIndex] = alloc_float(val); }
inline void array_set_value(values_array a, int inIndex, value val) {  a[inIndex] = val; }

struct HxWString
{
   inline HxWString(const HxWString &inRHS)
   {
      length = inRHS.length;
      __s = inRHS.__s;
   }
   inline HxWString(const wchar_t *inS,int inLen=-1, bool inAllocGcString=true)
   {
      if (inAllocGcString)
      {
         if (inLen<0)
         {
            inLen = 0;
            while(inS[inLen]) inLen++;
         }
         __s = (wchar_t *)alloc_string_len((const char *)inS,(inLen+1)*sizeof(wchar_t)-1);
         length = inLen;
      }
      else
      {
         __s = inS;
         length = inLen;
      }
   }
   inline HxWString() : length(0), __s(0) { }

   inline int size() const { return length; }
   inline const wchar_t *c_str() const { return __s; }


   int length;
   const wchar_t *__s;
};

inline std::wstring valToStdWString(value inVal)
{
   return val_wstring(inVal);
}


#endif


#include <nme/Object.h>



inline HxString valToHxString(value inValue,bool inAllowNull=true)
{
   if (val_is_null(inValue))
   {
      if (inAllowNull)
         return HxString();
      return HxString("");
   }
#ifdef HXCPP_JS_PRIME
   return inValue.as<std::string>();
#else
   return HxString( val_string(inValue), val_strlen(inValue), false );
#endif
}

inline std::string valToStdString(value inValue,bool inAllowNull=true)
{
#ifdef HXCPP_JS_PRIME
   return inValue.as<std::string>();
#else
   const char *str = val_string(inValue);
   if (!str)
      return inAllowNull ? std::string() : std::string("");

   return std::string( str, str+val_strlen(inValue));
#endif
}


#ifdef HXCPP_JS_PRIME
inline const std::string &hxToStdString(const HxString &inValue) { return inValue; }
#else
inline std::string hxToStdString(const HxString &inValue)
{
   return std::string( inValue.__s, inValue.__s+inValue.length );
}
#endif

inline HxWString valToHxWString(value inValue,bool inAllowNull=true)
{
   if (val_is_null(inValue))
   {
      if (inAllowNull)
         return HxWString();
      return HxWString(L"");
   }
#ifdef HXCPP_JS_PRIME
   return inValue.as<std::wstring>();
#else
   //return HxWString( val_wstring(inValue), val_wstrlen(inValue), false );
   return HxWString( val_wstring(inValue), -1, false );
#endif
}

namespace nme
{

// In nme namespace
struct CffiBytes
{
   #ifndef HXCPP_JS_PRIME

   unsigned char *data;
   int length;
   CffiBytes( unsigned char *inData=0, int inLength=0) : data(inData), length(inLength) {}

   int getLength() { return length; };
   unsigned char *getData() { return data; };
   const unsigned char *readData() { return data; };

   #else
   protected:
      unsigned char *data;
      int length;
      value bound;

   public:

   CffiBytes() : bound( value::null() ), data(0), length(0) {}
   CffiBytes(value inValue) : bound(inValue)
   {
      if (bound.isNull())
      {
         data = 0;
         length = 0;
      }
      else
      {
         bound.call<void>("bind");
         data = (unsigned char *)bound["byteOffset"].as<int>();
         length = bound["byteLength"].as<int>();
      }
   }
   CffiBytes(CffiBytes&& v) : bound(v.bound), data(v.data), length(v.length)
   {
      v.bound = value::null();
   }

   CffiBytes(const CffiBytes& v) : bound(v.bound)
   {
      if (!bound.isNull())
         bound.call<void>("bind");
      data = v.data;
      length = v.length;
   }
   CffiBytes& operator=(CffiBytes&& v)
   {
      if (!bound.isNull())
         bound.call<void>("unbind");
      bound = v.bound;
      v.bound = value::null();
      return *this;
   }

   CffiBytes& operator=(const CffiBytes& v)
   {
      if (!v.bound.isNull())
         bound.call<void>("bind");
      if (!bound.isNull())
         bound.call<void>("unbind");
      bound = v.bound;
      return *this;
   }

   ~CffiBytes()
   {
      if (!bound.isNull())
      {
         bound.call<void>("unbind");
      }
   }

   int getLength() { return length; };
   unsigned char *getData() {
      if (data)
         bound.call<void>("setEdited");
      return data;
   };
   const unsigned char *readData() { return data; };

   #endif
};

inline CffiBytes getByteData(value inValue)
{
   #ifndef HXCPP_JS_PRIME
   if (val_is_object(inValue))
   {
      static field bField = 0;
      static field lengthField = 0;
      if (bField==0)
      {
         bField = val_id("b");
         lengthField = val_id("length");
      }
      value b = val_field(inValue, bField);
      value len = val_field(inValue, lengthField);
      if (val_is_string(b) && val_is_int(len))
         return CffiBytes( (unsigned char *)val_string(b), val_int(len) );
      if (val_is_buffer(b) && val_is_int(len))
         return CffiBytes( (unsigned char *)buffer_data(val_to_buffer(b)), val_int(len) );
   }
   #else
   if (!inValue.isNull())
   {
      value b = inValue["b"];
      if (!b.isUndefined())
         return CffiBytes(b);
   }
   #endif
   return CffiBytes();
}

inline bool resizeByteData(value inValue, int inNewLen)
{
   #ifndef HXCPP_JS_PRIME
   if (!val_is_object(inValue))
      return false;

   static field bField = 0;
   static field lengthField = 0;
   if (bField==0)
   {
      bField = val_id("b");
      lengthField = val_id("length");
   }
   value len = val_field(inValue, lengthField);
   if (!val_is_int(len))
      return false;
   int oldLen = val_int(len);
   value b = val_field(inValue, bField);
   if (val_is_string(b))
   {
      if (inNewLen>oldLen)
      {
         value newString = alloc_raw_string(inNewLen);
         memcpy( (char *)val_string(newString), val_string(b), inNewLen);
         alloc_field(inValue, bField, newString );
      }
      alloc_field(inValue, lengthField, alloc_int(inNewLen) );
   }
   return true;
   #else
   if (!inValue.isNull())
   {
      value b = inValue["b"];
      if (!b.isUndefined())
      {
         b.call<void>("resizeByteData",inNewLen);
         return true;
      }
   }
   return false;
   #endif
}






extern vkind gObjectKind;

#ifdef HXCPP_JS_PRIME
inline value ObjectToAbstract(Object *inObject) { return inObject->toAbstract(); }

template<typename OBJ>
inline bool AbstractToObject(value inValue, OBJ *&outObj)
{
   outObj = 0;
   Object *obj = Object::toObject(inValue);
   if (obj)
      outObj = dynamic_cast<OBJ *>(obj);
   return outObj;
}

struct BufferData : Object
{
   BufferData();

   NmeObjectType getObjectType() { return notBytes; }

   unsigned char *getData() { return data; }
   int getDataSize() { return allocLen; }

   void setDataSize(int inSize, bool keepData);
   void swapData(std::vector<unsigned char > &ioData);
   void verify(const char *inWhere);

   static BufferData *fromStream(class ObjectStreamIn &inStream);
   void encodeStream(class ObjectStreamOut &inStream);

   static int totalSize;

   private:
      unsigned char *data;
      int allocLen;

      BufferData(const BufferData &);
      void operator = (const BufferData &);
   protected:
      ~BufferData();
};
typedef BufferData *buffer;

inline buffer val_to_buffer(value bytes)
{
   buffer result = 0;
   AbstractToObject(bytes,result);
   return result;
}
inline unsigned char *buffer_data(buffer inBuffer)
{
   return inBuffer ? inBuffer->getData() : 0;
}
inline int buffer_size(buffer inBuffer) { return inBuffer ? inBuffer->getDataSize() : 0; }


#else

namespace
{
   inline void release_object(value inValue)
   {
      if (val_is_kind(inValue,gObjectKind))
      {
         Object *obj = (Object *)val_to_kind(inValue,gObjectKind);
         if (obj)
            obj->DecRef();
      }
   }
}

inline value ObjectToAbstract(Object *inObject)
{
   inObject->IncRef();
   value result = alloc_abstract(gObjectKind,inObject);
   val_gc(result,release_object);
   return result;
}


template<typename OBJ>
bool AbstractToObject(value inValue, OBJ *&outObj)
{
   outObj = 0;
   if ( ! val_is_kind(inValue,gObjectKind) )
      return false;
   Object *obj = (Object *)val_to_kind(inValue,gObjectKind);
   outObj = dynamic_cast<OBJ *>(obj);
   return outObj;
}
#endif


}


#endif
