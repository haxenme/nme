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

BufferData *BufferData::fromStream(class ObjectStreamIn &inStream)
{
   int len = inStream.getInt();
   BufferData *buf = new BufferData();
   buf->data.resize(len);
   if (len)
      memcpy(&buf->data[0], inStream.getBytes(len), len);
   return buf;
}

void BufferData::encodeStream(class ObjectStreamOut &inStream)
{
   inStream.addInt(data.size());
   if (data.size())
      inStream.append(&data[0], data.size());
}


int Object::sLiveObjectCount = 0;
int Object::sFrameId = 0;

void Object::releaseObject()
{
   sLiveObjectCount--;
   released++;
   if (val)
   {
      value &v = *val;
      if (!v["unrealize"].isUndefined())
         v.call<void>("unrealize");
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
      IncRef();
      gTempRefs.push_back(this);
   }
   lastFrameId = sFrameId;
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
         inValue.call<void>("realize");
         Object *newObject = (Object *)inValue["ptr"].as<int>();

         newObject->val = new emscripten::val(inValue);
         inValue.set("ptr",(int)newObject);
         newObject->IncRef();
         newObject->lastFrameId = Object::sFrameId;
         gTempRefs.push_back(newObject);

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
            newObject->lastFrameId = Object::sFrameId;

         return newObject;
      }
      else
      {
         return 0;
      }
   }

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
      ptr->lastFrameId = sFrameId;

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
   newObject->IncRef();
   gTempRefs.push_back(newObject);
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


int nme_buffer_create(int inLength)
{
   BufferData *data = new BufferData();
   data->data.resize(inLength*4);
   return (int)data;
}
DEFINE_PRIME1(nme_buffer_create)


int nme_buffer_offset(int inPtr)
{
   BufferData *data = (BufferData *)inPtr;
   return (int)(&data->data[0]);
}
DEFINE_PRIME1(nme_buffer_offset)


int nme_buffer_length(int inPtr)
{
   BufferData *data = (BufferData *)inPtr;
   return data->data.size();
}
DEFINE_PRIME1(nme_buffer_length)



void nme_buffer_resize(int inPtr, int inNewSize)
{
   BufferData *data = (BufferData *)inPtr;
   data->data.resize(inNewSize*4);
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
   for(int i=0;i<gTempRefs.size();i++)
   {
      Object *obj = gTempRefs[i];
      if (obj->lastFrameId<Object::sFrameId)
      {
         obj->DecRef();
         gTempRefs.qremoveAt(i);
      }
      else
         i++;
   }
   //printf("rel=%d, free=%d tot=%d\n", realized, released, Object::sLiveObjectCount);
   unrealized = 0;
   realized = 0;
   released = 0;
   Object::sFrameId++;
}

DEFINE_PRIME0v(nme_native_resource_release_temps)

}

