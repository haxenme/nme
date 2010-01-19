#define IMPLEMENT_API

#include <ExternalInterface.h>
#include <Display.h>

namespace nme
{

vkind gObjectKind = alloc_kind();

static void release_object(value inValue)
{
   if (val_is_kind(inValue,gObjectKind))
   {
      Object *obj = (Object *)val_to_kind(inValue,gObjectKind);
      if (obj)
         obj->DecRef();
   }
}

value ObjectToAbstract(Object *inObject)
{
   inObject->IncRef();
   value result = alloc_abstract(gObjectKind,inObject);
   val_gc(result,release_object);
   return result;
}

}

using namespace nme;

value nme_get_frame_stage(value inValue)
{
   Frame *frame;
   if (!AbstractToObject(inValue,frame))
      return alloc_null();

   return ObjectToAbstract(frame->GetStage());
}

DEFINE_PRIM(nme_get_frame_stage,1);

value nme_create_main_frame(value inWidth,value inHeight,value inFlags,value inTitle,value inIcon)
{
   Frame *frame = CreateMainFrame((int)val_number(inWidth), (int)val_number(inHeight),
                     val_int(inFlags), val_string(inTitle), val_string(inIcon) );
   if (frame)
     return ObjectToAbstract(frame);
   return alloc_null();
}

DEFINE_PRIM(nme_create_main_frame,5);

value nme_main_loop()
{
   MainLoop();
   return alloc_null();
}

DEFINE_PRIM(nme_main_loop,0);


value nme_close()
{
   TerminateMainLoop();
   return alloc_null();
}

DEFINE_PRIM(nme_close,0);

static int _id_type = val_id("type");
static int _id_x = val_id("x");
static int _id_y = val_id("y");
static int _id_value = val_id("value");
static int _id_id = val_id("id");
static int _id_flags = val_id("flags");

void external_handler( nme::Event &ioEvent, void *inUserData )
{
   AutoGCRoot *handler = (AutoGCRoot *)inUserData;
   if (ioEvent.type == etDestroyHandler)
   {
      delete handler;
      return;
   }

   value o = alloc_empty_object( );
   alloc_field(o,_id_type,alloc_int(ioEvent.type));
   alloc_field(o,_id_x,alloc_int(ioEvent.x));
   alloc_field(o,_id_y,alloc_int(ioEvent.y));
   alloc_field(o,_id_value,alloc_int(ioEvent.value));
   alloc_field(o,_id_id,alloc_int(ioEvent.id));
   alloc_field(o,_id_flags,alloc_int(ioEvent.flags));
   val_call1(handler->get(), o);
}


value nme_set_stage_handler(value inStage,value inHandler)
{
   Stage *stage;
   if (!AbstractToObject(inStage,stage))
      return alloc_null();

   AutoGCRoot *data = new AutoGCRoot(inHandler);

   stage->SetEventHandler(external_handler,data);

   return alloc_null();
}

DEFINE_PRIM(nme_set_stage_handler,2);

