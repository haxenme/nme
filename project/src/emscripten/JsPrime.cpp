#include <nme/NmeCffi.h>
#include <nme/QuickVec.h>

namespace nme
{
IdMap sIdMap;
IdMap sKindMap;
std::vector<value> sIdKeys;

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
   Object *ptr = (Object *)inValue["ptr"].as<int>();
   if (ptr)
      return ptr;

   std::string type = inValue["type"].as<std::string>();
   printf("TODO: create from type %s\n", type.c_str() );

   return 0;
}


}
