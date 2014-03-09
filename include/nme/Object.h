#ifndef NME_OBJECT_H
#define NME_OBJECT_H

#include "NmeApi.h"

namespace nme
{



class ImageBuffer;


class Object
{
protected:
   virtual ~Object() { }

public:
   Object(bool inInitialRef=0) : mRefCount(inInitialRef?1:0) { }
   Object *IncRef() { mRefCount++; return this; }
   void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }
   int GetRefCount() { return mRefCount; }

   virtual int getApiVersion() { return NME_API_VERSION; }
   virtual NmeApi *getApi() { return &gNmeApi; }

   virtual ImageBuffer *asImageBuffer() { return 0; }


   int mRefCount;
};

} // end namespace nme


#endif
