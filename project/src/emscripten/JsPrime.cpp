#include <nme/NmeCffi.h>
#include <nme/QuickVec.h>
#include <Utils.h>
#include <Display.h>
#include <Surface.h>
#include <Tilesheet.h>
#include <Font.h>

IdMap sIdMap;
IdMap sKindMap;
std::vector<value> sIdKeys;
std::vector<const char *> sIdKeyNames;

namespace nme
{
QuickVec<Object *> gTempRefs; 
static int realized = 0;
static int unrealized = 0;
static int released = 0;
int BufferData::totalSize = 0;

static void pushTemp(Object *obj)
{
   if (!obj->held)
   {
      obj->held = true;
      obj->IncRef();
      gTempRefs.push_back(obj);
   }
}

struct ValueObjectStreamOut : public ObjectStreamOut
{
   typedef emscripten::val value;

   value handleArray;
   int   count;

   ValueObjectStreamOut() : handleArray(value::object()), count(0)
   {

   }

   void encodeObject(Object *inObj)
   {
      addInt(count);
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
      int check = getInt();
      if (check!=count)
      {
         printf("Bad handle count mismatch %d/%d\n", check, count);
         *(int *)0=0;
      }
      value v = handleArray[count++];
      if (v.isNull() || v.isUndefined())
      {
         printf("Bad handle %d?\n", count-1);
         *(int *)0=0;
         return 0;
      }
      return Object::toObject(v);
   }
};


BufferData::BufferData() : data(0), allocLen(0)
{
   pushTemp(this);
}

void BufferData::verify(const char *inWhere)
{
   if (data)
   {
      if (data[-1]!=68)
      {
         printf("Buffer underrun %s %d\n",  inWhere, data[-1]);
         *(int *)0=0;
      }
      if (data[allocLen]!=69)
      {
         printf("Buffer override %s %d\n", inWhere, data[allocLen]);
         *(int *)0=0;
      }
   }
}

void BufferData::setDataSize(int inSize, bool keepData)
{
   if (!keepData)
   {
      if (data)
      {
         verify("setDataSize noKeep");
         data[-1]=77;
         free(data - 4);
         totalSize -= allocLen;
      }
      allocLen = inSize;
      data = (unsigned char *)malloc(allocLen + 5) + 4;
      totalSize += allocLen;
      data[-1] = 68;
      data[allocLen] = 69;
   }
   else
   {
      unsigned char *next = (unsigned char *)malloc(inSize + 5) + 4;
      totalSize += inSize;
      next[-1] = 68;
      next[inSize] = 69;

      if (data)
         memcpy(next, data, std::min(inSize,allocLen));
      if (inSize>allocLen)
         memset(next + allocLen, 0, inSize-allocLen);
      if (data)
      {
         verify("setDataSize keep");
         data[-1]=77;
         free(data - 4);
         totalSize -= allocLen;
      }
      data = next;
      allocLen = inSize;
   }
}

void BufferData::swapData(std::vector<unsigned char > &ioData)
{
   setDataSize(ioData.size(),false);
   memcpy(data, &ioData[0], ioData.size() );
   std::vector<unsigned char > empty;
   empty.swap(ioData);
}



BufferData *BufferData::fromStream(class ObjectStreamIn &inStream)
{
   int len = inStream.getInt();
   BufferData *buf = new BufferData();
   buf->setDataSize(len,false);
   if (len)
      memcpy(buf->data, inStream.getBytes(len), len);
   return buf;
}

void BufferData::encodeStream(class ObjectStreamOut &inStream)
{
   inStream.addInt(allocLen);
   if (allocLen)
      inStream.append(data, allocLen);
}


int Object::sLiveObjectCount = 0;

void Object::releaseObject()
{
   sLiveObjectCount--;
   released++;
   if (val)
   {
      value &v = *val;
      if (!v["unrealize"].isUndefined())
      {
         v.call<void>("unrealize");
      }
      else
      {
         unrealize();
         val->set("ptr", emscripten::val::null() );
         val->set("type", (int)getObjectType() );
      }
      delete val;
   }
   delete this;
}

value &Object::toAbstract()
{
   if (!val)
   {
      val = new emscripten::val( emscripten::val::object() );
      val->set("ptr", (int)this);
      val->set("kind", (int)gObjectKind);
   }
   return *val;
}

Object *Object::toObject( value &inValue )
{
   if (inValue.isNull() || inValue.isUndefined())
      return 0;

   if (inValue["ptr"].isNull()  || inValue["ptr"].isUndefined())
   {
      // Custom 'realize' method (ByteArray)
      if (!inValue["realize"].isUndefined())
      {
         realized++;
         inValue.call<void>("realize");
         Object *newObject = (Object *)inValue["ptr"].as<int>();
         pushTemp(newObject);

         newObject->val = new emscripten::val(inValue);
         inValue.set("ptr",(int)newObject);
         // printf("new temp ref %p (%d)\n", newObject, newObject->mRefCount);

         return newObject;
      }
      else if (!inValue["type"].isUndefined())
      {
         realized++;

         NmeObjectType realizeType = (NmeObjectType)inValue["type"].as<int>();

         int len = value::global("Module").call<int>("realize", inValue );
         unsigned char *ptr = (unsigned char *)inValue["ptr"].as<int>();
         ValueObjectStreamIn input(ptr,len,inValue["handles"],inValue);
         Object *newObject = 0;

         switch(realizeType)
         {
            // notSound,
            // notSoundChannel,

            case notBytes:
               newObject = BufferData::fromStream(input);
               break;

            case notSurface:
               newObject = SimpleSurface::fromStream(input);
               break;

            case notTilesheet:
               newObject = Tilesheet::fromStream(input);
               break;

            case notTextFormat:
               newObject = TextFormat::fromStream(input);
               break;

            case notDisplayObject:
            case notDisplayObjectContainer:
            case notDirectRenderer:
            case notSimpleButton:
            case notTextField:
               newObject = DisplayObject::fromStream(input);
               break;

            case notGraphics:
               newObject = Graphics::fromStream(input);
               break;

            default:
               printf("TODO - realize resource %d\n", realizeType);
               free(ptr);
               return 0;
         }

         if (newObject)
            pushTemp(newObject);

         return newObject;
      }
      else
      {
         return 0;
      }
   }

   Object *ptr = (Object *)inValue["ptr"].as<int>();

   return ptr;
}

void ValueObjectStreamIn::linkAbstract(Object *newObject)
{
   if (newObject->val)
   {
      printf("Object already has value?\n");
      *(int *)0=0;
   }
   newObject->val = new emscripten::val(abstract);
   abstract.set("ptr",(int)newObject);
   abstract.set("type",(int)newObject->getObjectType());
}


void ValueObjectStreamOut::toValue(value &v)
{
   int offset = (int)&data[0];
   int len = data.size();

   value::global("Module").call<void>("unrealize", v, offset, len, value::null() );
   if (count)
      v.set("handles", handleArray);
}



const char *gObjectTypeNames[] = {
   "Unknown",
   "Bytes",
   "Surface",
   "Graphics",
   "HardwareContext",
   "HardwareResource",
   "Tilesheet",
   "Sound",
   "SoundChannel",
   "Camera",
   "IGraphicsData",
   "Url",
   "Frame",
   "TextFormat",
   "Font",
   "Stage",
   "Video",
   "ManagedStage",
   "DisplayObject",
   "DisplayObjectContainer",
   "DirectRenderer",
   "SimpleButton",
   "TextField",
};



void Object::unrealize()
{
   if (val)
   {
      unrealized++;
      ValueObjectStreamOut stream;
      encodeStream(stream);
      if (stream.empty())
         printf("TODO unrealize object %s\n", gObjectTypeNames[getObjectType()]);
      else
         stream.toValue(*val);
   }
}


BufferData::~BufferData()
{
   if (data)
   {
      verify("~BufferData");
      data[-1]=77;
      free(data - 4);
      totalSize -= allocLen;
   }
}

int nme_buffer_create(int inLength)
{
   BufferData *data = new BufferData();
   data->setDataSize(inLength, true);
   //data->verify("nme_buffer_create");
   return (int)data;
}
DEFINE_PRIME1(nme_buffer_create)


int nme_buffer_offset(int inPtr)
{
   BufferData *data = (BufferData *)inPtr;
   //data->verify("nme_buffer_offset");
   return (int)data->getData();
}
DEFINE_PRIME1(nme_buffer_offset)


int nme_buffer_length(int inPtr)
{
   BufferData *data = (BufferData *)inPtr;
   //data->verify("nme_buffer_length");
   return data->getDataSize();
}
DEFINE_PRIME1(nme_buffer_length)



void nme_buffer_resize(int inPtr, int inNewSize)
{
   BufferData *data = (BufferData *)inPtr;
   data->setDataSize(inNewSize, true);
   //data->verify("nme_buffer_resize");
}
DEFINE_PRIME2v(nme_buffer_resize)



void nme_native_resource_dispose(value inValue)
{
   if (inValue.isNull() || inValue.isUndefined())
      return;

   if (inValue["ptr"].isNull()  || inValue["ptr"].isUndefined())
      return;

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
   {
      ptr->DecRef();
   }
   inValue.set("ptr",value::null());
}
DEFINE_PRIME1v(nme_native_resource_dispose)

static int lockedResources = 0;

void nme_native_resource_lock(value inValue)
{
   if (inValue.isNull() || inValue.isUndefined())
      return;

   if (inValue["ptr"].isNull()  || inValue["ptr"].isUndefined())
      return;

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
   {
      lockedResources++;
      ptr->IncRef();
   }
}
DEFINE_PRIME1v(nme_native_resource_lock)

void nme_native_resource_unlock(value inValue)
{
   if (inValue.isNull() || inValue.isUndefined())
      return;

   if (inValue["ptr"].isNull()  || inValue["ptr"].isUndefined())
      return;

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
   {
      lockedResources--;
      ptr->DecRef();
   }
}
DEFINE_PRIME1v(nme_native_resource_unlock)


void nme_native_resource_release_temps()
{
   if (!gTempRefs.size())
      return;

   int held = gTempRefs.size();
   for(int i=0;i<gTempRefs.size();i++)
   {
      Object *obj = gTempRefs[i];
      obj->held = false;
      obj->DecRef();
   }
   gTempRefs.resize(0);

   //printf("created=%d, freed=%d #tot=%d temps=%d imageData=%d bufferData=%d\n", realized, released, Object::sLiveObjectCount, held, gImageData, BufferData::totalSize);
   unrealized = 0;
   realized = 0;
   released = 0;
}

DEFINE_PRIME0v(nme_native_resource_release_temps)

}

