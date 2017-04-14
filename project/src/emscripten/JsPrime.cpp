#include <nme/NmeCffi.h>
#include <nme/QuickVec.h>

IdMap sIdMap;
IdMap sKindMap;
std::vector<value> sIdKeys;

namespace nme
{
QuickVec<Object *> gTempRefs; 

Object::~Object()
{
   if (val)
   {
      val->set("type", getObjectType() );
      unrealize(*val);
      delete val;
   }
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
      if (inValue["realize"].isUndefined())
         return 0;

      inValue.call<void>("realize");
      newRef = true;
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

   printf("TODO: create from type\n");
   std::string type = inValue["type"].as<std::string>();

   return 0;
}

int nme_create_buffer(int inLength)
{
   // TODO = leak
   BufferData *data = new BufferData();
   data->data.resize(inLength*4);
   return (int)data;
}
DEFINE_PRIME1(nme_create_buffer)


int nme_buffer_offset(int inPtr)
{
   BufferData *data = (BufferData *)inPtr;
   return (int)(&data->data[0]);
}
DEFINE_PRIME1(nme_buffer_offset)


void nme_resize_buffer(int inPtr, int inNewSize)
{
   BufferData *data = (BufferData *)inPtr;
   data->data.resize(inNewSize*4);
}
DEFINE_PRIME2v(nme_resize_buffer)



}

