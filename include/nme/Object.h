#ifndef NME_OBJECT_H
#define NME_OBJECT_H

#include "NmeApi.h"
#include "QuickVec.h"

#ifdef HXCPP_JS_PRIME
#include <emscripten.h>
#include <emscripten/val.h>
#endif

namespace nme
{

class ImageBuffer;

extern int gImageData;

enum NmeObjectType
{
   notUnknown,
   notBytes,
   notSurface,
   notGraphics,
   notHardwareContext,
   notHardwareResource,
   notTilesheet,
   notSound,
   notSoundChannel,
   notCamera,
   notIGraphicsData,
   notUrl,
   notFrame,
   notTextFormat,
   notFont,
   notStage,
   notVideo,
   notManagedStage,
   notDisplayObject,  // Shape, Bitmap
   notDisplayObjectContainer, // Sprite
   notDirectRenderer,
   notSimpleButton,
   notTextField,
   notCOUNT,
};

extern const char *gObjectTypeNames[];


class Object
{
protected:
   virtual ~Object() { }

public:
   Object(bool inInitialRef=0) : mRefCount(inInitialRef?1:0)
   #ifdef HXCPP_JS_PRIME
   , val(0), held(false)
   #endif
   {
      #ifdef HXCPP_JS_PRIME
      sLiveObjectCount++;
      #endif
   }
   Object *IncRef() { mRefCount++; return this; }
   #ifdef HXCPP_JS_PRIME
   void releaseObject();
   void DecRef() { mRefCount--; if (mRefCount<=0) releaseObject(); }
   #else
   void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }
   #endif
   virtual int GetRefCount() { return mRefCount; }

   virtual int getApiVersion() { return NME_API_VERSION; }

   #ifdef HXCPP_JS_PRIME
   virtual NmeObjectType getObjectType() = 0;
   #else
   virtual NmeObjectType getObjectType() { return notUnknown; }
   #endif

   virtual void encodeStream(class ObjectStreamOut &inStream) { }
   virtual void decodeStream(class ObjectStreamIn &inStream)  { }

   #ifdef HXCPP_JS_PRIME
   emscripten::val &toAbstract();
   static Object *toObject( emscripten::val &inValue );

   emscripten::val *val;
   bool held;
   virtual void unrealize();

   static int sFrameId;
   static int sLiveObjectCount;
   #endif


   virtual ImageBuffer *asImageBuffer() { return 0; }

   int mRefCount;
};

template<typename OBJ>
class ObjectPtr
{
   OBJ *ptr;

public:
   ObjectPtr(OBJ *inPtr=nullptr) : ptr(inPtr) { if (inPtr) inPtr->IncRef(); }

   // Copy constructor
   ObjectPtr(const ObjectPtr& other) : ptr(other.ptr) { if (ptr) ptr->IncRef(); }

   ~ObjectPtr() { if (ptr) ptr->DecRef(); }

    // Copy assignment
    ObjectPtr& operator=(const ObjectPtr& other)
    {
        if (this != &other) {
           if (other.ptr) other.ptr->IncRef();
           if (ptr) ptr->DecRef();
           ptr = other.ptr;
        }
        return *this;
    }

    OBJ& operator*() const { return *ptr; }
    OBJ* operator->() const { return ptr; }
    OBJ* get() const { return ptr; }

    // Reset pointer
    void reset(OBJ* p = nullptr) {
       if (p) p->IncRef();
       if (ptr) ptr->DecRef();
       ptr = p;
    }

    // Check if pointer is valid
    operator bool() const { return ptr != nullptr; }

};

class ApiObject : public Object
{
public:
   ApiObject(bool inInitialRef=0) : Object(inInitialRef) { }

   virtual NmeApi *getApi() { return &gNmeApi; }
};


} // end namespace nme


#endif
