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


// --- DisplayObjectContainer -----------------------------------------------------

value nme_create_display_object_container()
{
	return ObjectToAbstract( new DisplayObjectContainer() );
}

DEFINE_PRIM(nme_create_display_object_container,0);

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



