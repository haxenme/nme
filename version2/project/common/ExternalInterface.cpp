#ifndef IPHONE
#define IMPLEMENT_API
#endif


#include <ExternalInterface.h>
#include <Display.h>
#include <TextField.h>

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


// --- Stage ----------------------------------------------------------------------

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

value nme_set_stage_poll_method(value inStage, value inMethod)
{
   Stage *stage;

   if (AbstractToObject(inStage,stage))
   {
      stage->SetPollMethod((Stage::PollMethod)val_int(inMethod));
   }

   return alloc_null();
}

DEFINE_PRIM(nme_set_stage_poll_method,2);

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


value nme_render_stage(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->RenderStage();
   }

   return alloc_null();
}

DEFINE_PRIM(nme_render_stage,1);

// --- DisplayObject --------------------------------------------------------------

value nme_create_display_object()
{
   return ObjectToAbstract( new DisplayObject() );
}

DEFINE_PRIM(nme_create_display_object,0);

value nme_display_object_get_graphics(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return ObjectToAbstract( &obj->GetGraphics() );

   return alloc_null();
}

DEFINE_PRIM(nme_display_object_get_graphics,1);

value nme_display_object_get_id(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return alloc_int( obj->id );

   return alloc_null();
}

DEFINE_PRIM(nme_display_object_get_id,1);

value nme_display_object_global_to_local(value inObj,value ioPoint)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      UserPoint point( val_field_numeric(ioPoint, val_id("x")),
                     val_field_numeric(ioPoint, val_id("y")) );
      UserPoint trans = obj->GlobalToLocal(point);
      alloc_field(ioPoint, val_id("x"), alloc_float(trans.x) );
      alloc_field(ioPoint, val_id("y"), alloc_float(trans.y) );
   }

   return alloc_null();
}

DEFINE_PRIM(nme_display_object_global_to_local,2);





#define DO_PROP(prop,Prop) \
value nme_display_object_get_##prop(value inObj) \
{ \
   DisplayObject *obj; \
   if (AbstractToObject(inObj,obj)) \
      return alloc_float( obj->get##Prop() ); \
   return alloc_float(0); \
} \
\
DEFINE_PRIM(nme_display_object_get_##prop,1) \
value nme_display_object_set_##prop(value inObj,value inVal) \
{ \
   DisplayObject *obj; \
   if (AbstractToObject(inObj,obj)) \
      obj->set##Prop(val_number(inVal)); \
   return alloc_null(); \
} \
\
DEFINE_PRIM(nme_display_object_set_##prop,2)

DO_PROP(x,X)
DO_PROP(y,Y)


// --- DisplayObjectContainer -----------------------------------------------------

value nme_create_display_object_container()
{
   return ObjectToAbstract( new DisplayObjectContainer() );
}

DEFINE_PRIM(nme_create_display_object_container,0);

value nme_doc_add_child(value inParent, value inChild)
{
   DisplayObjectContainer *parent;
   DisplayObject *child;
   if (AbstractToObject(inParent,parent) && AbstractToObject(inChild,child))
   {
      parent->addChild(child);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_doc_add_child,2);

/*
value nme_doc_remove_child(value inParent, value inPos)
{
   DisplayObjectContainer *parent;
   if (AbstractToObject(inParent,parent))
   {
      parent->removeChild(val_int(inPos));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_doc_insert_child,3);
*/

value nme_doc_set_child_index(value inParent, value inChild, value inPos)
{
   DisplayObjectContainer *parent;
   DisplayObject *child;
   if (AbstractToObject(inParent,parent) && AbstractToObject(inChild,child))
   {
      parent->setChildIndex(child,val_int(inPos));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_doc_set_child_index,3);



// --- Graphics -----------------------------------------------------

value nme_gfx_begin_fill(value inGfx,value inColour, value inAlpha)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->beginFill( val_int(inColour), val_number(inAlpha) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_begin_fill,3);


value nme_gfx_line_style(value* arg, int nargs)
{
   enum { argGfx, argThickness, argColour, argAlpha, argPixelHinting, argScaleMode, argCapsStyle,
          argJointStyle, argMiterLimit, argSIZE };

   Graphics *gfx;
   if (AbstractToObject(arg[argGfx],gfx))
   {
      double thickness = -1;
      if (!val_is_null(arg[argThickness]))
      {
         thickness = val_number(arg[argThickness]);
         if (thickness<0)
            thickness = 0;
      }
      gfx->lineStyle(thickness, val_int(arg[argColour]), val_number(arg[argAlpha]),
                 val_bool(arg[argPixelHinting]),
                 (StrokeScaleMode)val_int(arg[argScaleMode]),
                 (StrokeCaps)val_int(arg[argCapsStyle]),
                 (StrokeJoints)val_int(arg[argJointStyle]),
                 val_number(arg[argMiterLimit]) );
   }
   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gfx_line_style)





value nme_gfx_move_to(value inGfx,value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->moveTo( val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_move_to,3);

value nme_gfx_line_to(value inGfx,value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->lineTo( val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_line_to,3);

value nme_gfx_curve_to(value inGfx,value inCX, value inCY, value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->curveTo( val_number(inCX), val_number(inCY), val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_curve_to,5);

value nme_gfx_arc_to(value inGfx,value inCX, value inCY, value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->arcTo( val_number(inCX), val_number(inCY), val_number(inX), val_number(inY) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_arc_to,5);

value nme_gfx_draw_ellipse(value inGfx,value inX, value inY, value inWidth, value inHeight)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->drawEllipse( val_number(inX), val_number(inY), val_number(inWidth), val_number(inHeight) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_ellipse,5);

// --- TextField --------------------------------------------------------------

value nme_text_field_create()
{
   TextField *text = new TextField();
   return ObjectToAbstract(text);
}
DEFINE_PRIM(nme_text_field_create,0)

inline value alloc_wstring(const std::wstring &inStr)
   { return alloc_wstring_len(inStr.c_str(),inStr.length()); }

#define TEXT_PROP(from_val,to_val,prop,Prop) \
value nme_text_field_get_##prop(value inHandle) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      return to_val(t->get##Prop()); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_text_field_get_##prop,1); \
value nme_text_field_set_##prop(value inHandle,value inValue) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      t->set##Prop(from_val(inValue)); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_text_field_set_##prop,2);

TEXT_PROP(val_wstring,alloc_wstring,text,Text);



// Reference this to bring in all the symbols for the static library
extern "C" int nme_register_prims() { return 0; }

