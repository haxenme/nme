#include <nme/NmeCffi.h>
#include <nme/QuickVec.h>

namespace nme
{

QuickVec<Object *> gTempRefs; 

value &Object::toAbstract()
{
   if (!val)
   {
      val = new emscripten::val( emscripten::val::object() );
      val->set("ptr", this);
      IncRef();
      gTempRefs.push_back(this);
   }

   return *val;
}

Object *Object::toObject( value &inValue )
{
   int ptr = inValue["ptr"].as<int>();
   return (Object *)ptr;
}


}
