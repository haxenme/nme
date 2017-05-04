#include <nme/NmeCffi.h>
#include <nme/QuickVec.h>
#include <Utils.h>
#include <Display.h>
#include <Surface.h>

IdMap sIdMap;
IdMap sKindMap;
std::vector<value> sIdKeys;
std::vector<const char *> sIdKeyNames;

namespace nme
{
QuickVec<Object *> gTempRefs; 

void Object::releaseObject()
{
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
         gTempRefs.push_back(newObject);

         return newObject;
      }
      else if (!inValue["type"].isUndefined())
      {
         NmeObjectType realizeType = (NmeObjectType)inValue["type"].as<int>();

         int len = value::global("Module").call<int>("realize", inValue );
         unsigned char *ptr = (unsigned char *)inValue["ptr"].as<int>();
         InputStream input(ptr,len,inValue["handles"],inValue);
         Object *newObject = 0;

         switch(realizeType)
         {
            case notSurface:
               newObject = SimpleSurface::realize(input);
               break;

            case notDisplayObject:
            case notDisplayObjectContainer:
            case notDirectRenderer:
            case notSimpleButton:
            case notTextField:
               newObject = DisplayObject::realize(input);
               break;

            case notGraphics:
               newObject = Graphics::realize(input);
               break;

            default:
               printf("TODO - realize resource %d\n", realizeType);
               free(ptr);
               return 0;
         }

         return newObject;
      }
      else
         return 0;
   }

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   return ptr;
}

void InputStream::linkAbstract(Object *newObject)
{
   newObject->val = new emscripten::val(abstract);
   abstract.set("ptr",(int)newObject);
   newObject->IncRef();
   gTempRefs.push_back(newObject);
}


void ByteStream::toValue(value &v)
{
   int offset = (int)&data[0];
   int len = data.size();

   value::global("Module").call<void>("unrealize", v, offset, len, value::null() );
}

void OutputStream::toValue(value &v)
{
   ByteStream::toValue(v);
   if (count)
      v.set("handles", handleArray);
   //printf("Saved(%p) %d bytes, %d handles\n", this, data.size(), count);
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
   printf("TODO unrealize object %s\n", gObjectTypeNames[getObjectType()]);
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

void nme_native_resource_lock(value inValue)
{
   if (inValue.isNull() || inValue.isUndefined())
      return;

   if (inValue["ptr"].isNull()  || inValue["ptr"].isUndefined())
      return;

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
   {
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
      ptr->DecRef();
}
DEFINE_PRIME1v(nme_native_resource_unlock)


void nme_native_resource_release_temps()
{
   for(int i=0;i<gTempRefs.size();i++)
   {
      Object *obj = gTempRefs[i];
      int type = obj->getObjectType();
      switch(type)
      {
         case notBytes:
         case notSurface:
         case notDisplayObject:
         case notGraphics:
            // Ok, implemented
            obj->DecRef();
            break;
         default:
            // potentially leak for now
            //obj->DecRef();
            ;
      }
   }
   gTempRefs.resize(0);
}

DEFINE_PRIME0v(nme_native_resource_release_temps)

}

