#include <nme/NmeCffi.h>
#include <nme/QuickVec.h>
#include <Utils.h>
#include <Display.h>

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
   bool newRef = false;
   if (inValue.isNull() || inValue.isUndefined())
      return 0;
   if (inValue["ptr"].isNull()  || inValue["ptr"].isUndefined())
   {
      // Custom 'realize' method (ByteArray)
      if (!inValue["realize"].isUndefined())
      {
         inValue.call<void>("realize");
      }
      else if (!inValue["type"].isUndefined())
      {
         NmeObjectType realizeType = (NmeObjectType)inValue["type"].as<int>();
         switch(realizeType)
         {
            default:
               printf("TODO - realize resource %d\n", realizeType);
               return 0;
         }
         newRef = true;
      }
      else
         return 0;
   }

   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
   {
      if (newRef)
      {
         ptr->IncRef();
         gTempRefs.push_back(ptr);
      }
      return ptr;
   }

   return 0;
}

void ByteStream::toValue(value v)
{
   int len = data.size();
   int offset = (int)&data[0];

   /*
    * TODO
   EM_ASM_({
      var buffer = new ArrayBuffer($2);
      var buf8 = new UInt8Array(buffer);
      buf8.set( Module.HEAP8, $1, $2);
      $1["data"] = buf8;
    }, v, offset, len);
  */
}

void Object::unrealize()
{
   printf("TODO unrealize object %d\n", getObjectType());
   DisplayObject *d = dynamic_cast<DisplayObject *>(this);
   if (d)
      printf("name %S\n", d->name.c_str());
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
   inValue["ptr"] = value::null();
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
   /*
    * TODO:
   for(int i=0;i<gTempRefs.size();i++)
      gTempRefs[i]->DecRef();
   gTempRefs.resize(0);
   */
}

DEFINE_PRIME0v(nme_native_resource_release_temps)

}

