#ifndef IPHONE
#define IMPLEMENT_API
#endif


#include <Utils.h>
#include <ExternalInterface.h>
#include <Display.h>
#include <TextField.h>
#include <Surface.h>
#include <Tilesheet.h>
#include <Font.h>
#include <Sound.h>
#include <Input.h>
#include <algorithm>
#include <ByteArray.h>

#ifdef ANDROID
#include <android/log.h>
#endif

#ifdef min
#undef min
#undef max
#endif


namespace nme
{

static int _id_type;
static int _id_x;
static int _id_y;
static int _id_z;
static int _id_width;
static int _id_height;
static int _id_length;
static int _id_value;
static int _id_id;
static int _id_flags;
static int _id_result;
static int _id_code;
static int _id_a;
static int _id_b;
static int _id_c;
static int _id_d;
static int _id_tx;
static int _id_ty;
static int _id_angle;
static int _id_distance;
static int _id_strength;
static int _id_alpha;
static int _id_hideObject;
static int _id_knockout;
static int _id_inner;
static int _id_blurX;
static int _id_blurY;
static int _id_quality;
static int _id_align;
static int _id_blockIndent;
static int _id_bold;
static int _id_bullet;
static int _id_color;
static int _id_font;
static int _id_indent;
static int _id_italic;
static int _id_kerning;
static int _id_leading;
static int _id_leftMargin;
static int _id_letterSpacing;
static int _id_rightMargin;
static int _id_size;
static int _id_tabStops;
static int _id_target;
static int _id_underline;
static int _id_url;
static int _id_error;
static int _id_bytesTotal;
static int _id_bytesLoaded;
static int _id_volume;
static int _id_pan;

static int _id_alphaMultiplier;
static int _id_redMultiplier;
static int _id_greenMultiplier;
static int _id_blueMultiplier;

static int _id_alphaOffset;
static int _id_redOffset;
static int _id_greenOffset;
static int _id_blueOffset;
static int _id_rgb;

vkind gObjectKind;

static int sgIDsInit = false;

extern "C" void InitIDs()
{
   sgIDsInit = true;
   _id_type = val_id("type");
   _id_x = val_id("x");
   _id_y = val_id("y");
   _id_z = val_id("z");
   _id_width = val_id("width");
   _id_height = val_id("height");
   _id_length = val_id("length");
   _id_value = val_id("value");
   _id_id = val_id("id");
   _id_flags = val_id("flags");
   _id_result = val_id("result");
   _id_code = val_id("code");
   _id_a = val_id("a");
   _id_b = val_id("b");
   _id_c = val_id("c");
   _id_d = val_id("d");
   _id_tx = val_id("tx");
   _id_ty = val_id("ty");
   _id_angle = val_id("angle");
   _id_distance = val_id("distance");
   _id_strength = val_id("strength");
   _id_alpha = val_id("alpha");
   _id_hideObject = val_id("hideObject");
   _id_knockout = val_id("knockout");
   _id_inner = val_id("inner");
   _id_blurX = val_id("blurX");
   _id_blurY = val_id("blurY");
   _id_quality = val_id("quality");
   _id_align = val_id("align");
   _id_blockIndent = val_id("blockIndent");
   _id_bold = val_id("bold");
   _id_bullet = val_id("bullet");
   _id_color = val_id("color");
   _id_font = val_id("font");
   _id_indent = val_id("indent");
   _id_italic = val_id("italic");
   _id_kerning = val_id("kerning");
   _id_leading = val_id("leading");
   _id_leftMargin = val_id("leftMargin");
   _id_letterSpacing = val_id("letterSpacing");
   _id_rightMargin = val_id("rightMargin");
   _id_size = val_id("size");
   _id_tabStops = val_id("tabStops");
   _id_target = val_id("target");
   _id_underline = val_id("underline");
   _id_url = val_id("url");
   _id_error = val_id("error");
   _id_bytesTotal = val_id("bytesTotal");
   _id_bytesLoaded = val_id("bytesLoaded");
   _id_volume = val_id("volume");
   _id_pan = val_id("pan");

   _id_alphaMultiplier = val_id("alphaMultiplier");
   _id_redMultiplier = val_id("redMultiplier");
   _id_greenMultiplier = val_id("greenMultiplier");
   _id_blueMultiplier = val_id("blueMultiplier");

   _id_alphaOffset = val_id("alphaOffset");
   _id_redOffset = val_id("redOffset");
   _id_greenOffset = val_id("greenOffset");
   _id_blueOffset = val_id("blueOffset");
   _id_rgb = val_id("rgb");

   gObjectKind = alloc_kind();
}

DEFINE_ENTRY_POINT(InitIDs)


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

WString val2stdwstr(value inVal)
{
   const wchar_t *val = val_wstring(inVal);
   int len=0;
   while(val[len]) len++;
   char buf[100];
   for(int i=0;i<100 && i<=len;i++)
      buf[i] = val[i];
   buf[99] = '\0';
   return WString(val,len);
}


void FromValue(Matrix &outMatrix, value inValue)
{
   if (!val_is_null(inValue))
   {
      outMatrix.m00 =  val_field_numeric(inValue,_id_a);
      outMatrix.m01 =  val_field_numeric(inValue,_id_c);
      outMatrix.m10 =  val_field_numeric(inValue,_id_b);
      outMatrix.m11 =  val_field_numeric(inValue,_id_d);
      outMatrix.mtx =  val_field_numeric(inValue,_id_tx);
      outMatrix.mty =  val_field_numeric(inValue,_id_ty);
   }
}

void FromValue(ColorTransform &outTrans, value inValue)
{
   if (!val_is_null(inValue))
   {
      outTrans.alphaOffset = val_field_numeric(inValue,_id_alphaOffset);
      outTrans.redOffset = val_field_numeric(inValue,_id_redOffset);
      outTrans.greenOffset = val_field_numeric(inValue,_id_greenOffset);
      outTrans.blueOffset = val_field_numeric(inValue,_id_blueOffset);

      outTrans.alphaMultiplier = val_field_numeric(inValue,_id_alphaMultiplier);
      outTrans.redMultiplier = val_field_numeric(inValue,_id_redMultiplier);
      outTrans.greenMultiplier = val_field_numeric(inValue,_id_greenMultiplier);
      outTrans.blueMultiplier = val_field_numeric(inValue,_id_blueMultiplier);
   }
}




void FromValue(SoundTransform &outTrans, value inValue)
{
   if (!val_is_null(inValue))
   {
       outTrans.volume = val_number( val_field(inValue,_id_volume) );
       outTrans.pan = val_number( val_field(inValue,_id_pan) );
   }
}

void FromValue(DRect &outRect, value inValue)
{
	if (val_is_null(inValue))
		return;
   outRect.x = val_field_numeric(inValue,_id_x);
   outRect.y = val_field_numeric(inValue,_id_y);
   outRect.w = val_field_numeric(inValue,_id_width);
   outRect.h = val_field_numeric(inValue,_id_height);
}

void FromValue(Rect &outRect, value inValue)
{
	if (val_is_null(inValue))
		return;
   outRect.x = val_field_numeric(inValue,_id_x);
   outRect.y = val_field_numeric(inValue,_id_y);
   outRect.w = val_field_numeric(inValue,_id_width);
   outRect.h = val_field_numeric(inValue,_id_height);
}

void FromValue(ImagePoint &outPoint,value inValue)
{
   outPoint.x = val_field_numeric(inValue,_id_x);
   outPoint.y = val_field_numeric(inValue,_id_y);
}



void ToValue(value &outVal,const Matrix &inMatrix)
{
    alloc_field(outVal,_id_a, alloc_float(inMatrix.m00) );
    alloc_field(outVal,_id_c, alloc_float(inMatrix.m01) );
    alloc_field(outVal,_id_b, alloc_float(inMatrix.m10) );
    alloc_field(outVal,_id_d, alloc_float(inMatrix.m11) );
    alloc_field(outVal,_id_tx, alloc_float(inMatrix.mtx) );
    alloc_field(outVal,_id_ty, alloc_float(inMatrix.mty) );
}

void ToValue(value &outVal,const ColorTransform &inTrans)
{
    alloc_field(outVal,_id_alphaMultiplier, alloc_float(inTrans.alphaMultiplier) );
    alloc_field(outVal,_id_redMultiplier, alloc_float(inTrans.redMultiplier) );
    alloc_field(outVal,_id_greenMultiplier, alloc_float(inTrans.greenMultiplier) );
    alloc_field(outVal,_id_blueMultiplier, alloc_float(inTrans.blueMultiplier) );

    alloc_field(outVal,_id_alphaOffset, alloc_float(inTrans.alphaOffset) );
    alloc_field(outVal,_id_redOffset, alloc_float(inTrans.redOffset) );
    alloc_field(outVal,_id_greenOffset, alloc_float(inTrans.greenOffset) );
    alloc_field(outVal,_id_blueOffset, alloc_float(inTrans.blueOffset) );
}




template<typename T>
void FillArrayInt(QuickVec<T> &outArray,value inVal)
{
   if (val_is_null(inVal))
      return;
   int n = val_array_size(inVal);
   outArray.resize(n);
   int *c = val_array_int(inVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         outArray[i] = c[i];
   }
   else
   {
      value *vals = val_array_value(inVal);
      if (vals)
      {
         for(int i=0;i<n;i++)
            outArray[i] = val_int(vals[i]);
      }
      else
      {
         for(int i=0;i<n;i++)
            outArray[i] = val_int(val_array_i(inVal,i));
      }
   }

}

template<typename T>
void FillArrayInt(value outVal, const QuickVec<T> &inArray)
{
   int n = inArray.size();
   val_array_set_size(outVal,n);
   int *c = val_array_int(outVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         c[i] = inArray[i];
   }
   else
   {
      value *vals = val_array_value(outVal);
      if (vals)
         for(int i=0;i<n;i++)
            vals[i] = alloc_int(inArray[i]);
      else
         for(int i=0;i<n;i++)
            val_array_set_i(outVal,i,alloc_int(inArray[i]));
   }
}

template<typename T>
void FillArrayDouble(value outVal, const QuickVec<T> &inArray)
{
   int n = inArray.size();
   val_array_set_size(outVal,n);
   double *c = val_array_double(outVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         c[i] = inArray[i];
   }
   else
   {
      value *vals = val_array_value(outVal);
      if (vals)
         for(int i=0;i<n;i++)
            vals[i] = alloc_float(inArray[i]);
      else
         for(int i=0;i<n;i++)
            val_array_set_i(outVal,i,alloc_float(inArray[i]));
   }
}




template<typename T>
void FillArrayDouble(QuickVec<T> &outArray,value inVal)
{
   if (val_is_null(inVal))
      return;
   int n = val_array_size(inVal);
   outArray.resize(n);
   double *c = val_array_double(inVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         outArray[i] = c[i];
   }
   else
   {
      value *vals = val_array_value(inVal);
      if (vals)
         for(int i=0;i<n;i++)
            outArray[i] = val_number(vals[i]);
      else
         for(int i=0;i<n;i++)
            outArray[i] = val_number(val_array_i(inVal,i));
   }

}




}

#define DO_PROP_READ(Obj,obj_prefix,prop,Prop,to_val) \
value nme_##obj_prefix##_get_##prop(value inObj) \
{ \
   Obj *obj; \
   if (AbstractToObject(inObj,obj)) \
      return to_val( obj->get##Prop() ); \
   return alloc_float(0); \
} \
\
DEFINE_PRIM(nme_##obj_prefix##_get_##prop,1)

#define DO_PROP(Obj,obj_prefix,prop,Prop,to_val,from_val) \
DO_PROP_READ(Obj,obj_prefix,prop,Prop,to_val) \
value nme_##obj_prefix##_set_##prop(value inObj,value inVal) \
{ \
   Obj *obj; \
   if (AbstractToObject(inObj,obj)) \
      obj->set##Prop(from_val(inVal)); \
   return alloc_null(); \
} \
\
DEFINE_PRIM(nme_##obj_prefix##_set_##prop,2)


#define DO_DISPLAY_PROP(prop,Prop,to_val,from_val) \
   DO_PROP(DisplayObject,display_object,prop,Prop,to_val,from_val) 

#define DO_STAGE_PROP(prop,Prop,to_val,from_val) \
   DO_PROP(Stage,stage,prop,Prop,to_val,from_val) 


using namespace nme;


value nme_time_stamp()
{
	return alloc_float( GetTimeStamp() );
}
DEFINE_PRIM(nme_time_stamp,0);

// --- ByteArray -----------------------------------------------------

value nme_byte_array_create(value inLen)
{
	ByteArray *array = new ByteArray();
	array->mBytes.resize(val_int(inLen));
	return ObjectToAbstract(array);
}
DEFINE_PRIM(nme_byte_array_create,1);

value nme_byte_array_read_file(value inFilename)
{
	FILE *file = OpenRead(val_os_string(inFilename));
   if (!file)
      return alloc_null();

   fseek(file,0,SEEK_END);
   int len = ftell(file);
   fseek(file,0,SEEK_SET);

   ByteArray *result = new ByteArray;
	result->mBytes.resize(len);
   fread(&result->mBytes[0],len,1,file);
   fclose(file);

	return ObjectToAbstract(result);
}
DEFINE_PRIM(nme_byte_array_read_file,1);


value nme_byte_array_get_length(value inArray)
{
	ByteArray *array;
	if (AbstractToObject(inArray,array))
	{
		return alloc_int(array->mBytes.size());
	}
	return alloc_null();
}
DEFINE_PRIM(nme_byte_array_get_length,1);

value nme_byte_array_get(value inArray, value inPos)
{
	ByteArray *array;
	if (AbstractToObject(inArray,array))
	{
		int idx = val_int(inPos);
		if (idx>=0 && idx<array->mBytes.size())
			return alloc_int(array->mBytes[idx]);
	}
	return alloc_null();
}
DEFINE_PRIM(nme_byte_array_get,2);

value nme_byte_array_set(value inArray,value inPos, value inVal)
{
	ByteArray *array;
	if (AbstractToObject(inArray,array))
	{
		int idx = val_int(inPos);
		if (idx>=0 && idx<array->mBytes.size())
			array->mBytes[idx] = val_int(inVal);
	}
	return alloc_null();
}
DEFINE_PRIM(nme_byte_array_set,3);

struct ByteData
{
	uint8 *data;
	int   length;
};

bool FromValue(ByteData &outData,value inData)
{
	ByteArray *array;
	if (AbstractToObject(inData,array))
	{
		outData.length = array->mBytes.size();
		outData.data = &array->mBytes[0];
		return true;
	}

	if (!val_is_buffer(inData))
		return false;

	buffer buf = val_to_buffer(inData);
	outData.length = buffer_size(buf);
	outData.data = (uint8 *)buffer_data(buf);
	return true;
}


// --- Stage ----------------------------------------------------------------------

value nme_get_frame_stage(value inValue)
{
   Frame *frame;
   if (!AbstractToObject(inValue,frame))
      return alloc_null();

   return ObjectToAbstract(frame->GetStage());
}
DEFINE_PRIM(nme_get_frame_stage,1);

AutoGCRoot *sOnCreateCallback = 0;

void OnMainFrameCreated(Frame *inFrame)
{
   value frame = inFrame ? ObjectToAbstract(inFrame) : alloc_null();
   val_call1( sOnCreateCallback->get(),frame );
   delete sOnCreateCallback;
}

value nme_create_main_frame(value *arg, int nargs)
{
   if (!sgIDsInit)
      InitIDs();
   enum { aCallback, aWidth, aHeight, aFlags, aTitle, aIcon, aSIZE };

   sOnCreateCallback = new AutoGCRoot(arg[aCallback]);

   CreateMainFrame(OnMainFrameCreated,
       (int)val_number(arg[aWidth]), (int)val_number(arg[aHeight]),
       val_int(arg[aFlags]), val_string(arg[aTitle]), val_string(arg[aIcon]) );

   return alloc_null();
}

DEFINE_PRIM_MULT(nme_create_main_frame);

value nme_close()
{
   TerminateMainLoop();
   return alloc_null();
}
DEFINE_PRIM(nme_close,0);

value nme_stage_set_next_wake(value inStage, value inNextWake)
{
   Stage *stage;

   if (AbstractToObject(inStage,stage))
   {
      stage->SetNextWakeDelay(val_number(inNextWake));
   }

   return alloc_null();
}

DEFINE_PRIM(nme_stage_set_next_wake,2);

void external_handler( nme::Event &ioEvent, void *inUserData )
{
   AutoGCRoot *handler = (AutoGCRoot *)inUserData;
   if (ioEvent.type == etDestroyHandler)
   {
      delete handler;
      return;
   }

   value crap = alloc_int(123);


   value o = alloc_empty_object( );
   alloc_field(o,_id_type,alloc_int(ioEvent.type));
   alloc_field(o,_id_x,alloc_int(ioEvent.x));
   alloc_field(o,_id_y,alloc_int(ioEvent.y));
   alloc_field(o,_id_value,alloc_int(ioEvent.value));
   alloc_field(o,_id_id,alloc_int(ioEvent.id));
   alloc_field(o,_id_flags,alloc_int(ioEvent.flags));
   alloc_field(o,_id_code,alloc_int(ioEvent.code));
   alloc_field(o,_id_result,alloc_int(ioEvent.result));
   val_call1(handler->get(), o);
   ioEvent.result = (EventResult)val_int( val_field(o,_id_result) );
}


value nme_set_stage_handler(value inStage,value inHandler,value inNomWidth, value inNomHeight)
{
   Stage *stage;
   if (!AbstractToObject(inStage,stage))
      return alloc_null();

   AutoGCRoot *data = new AutoGCRoot(inHandler);

   stage->SetNominalSize(val_int(inNomWidth), val_int(inNomHeight) );
   stage->SetEventHandler(external_handler,data);

   return alloc_null();
}

DEFINE_PRIM(nme_set_stage_handler,4);


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


value nme_stage_get_focus_id(value inValue)
{
   int result = -1;
   Stage *stage;
   if (AbstractToObject(inValue,stage))
   {
      DisplayObject *obj = stage->GetFocusObject();
      if (obj)
         result = obj->getID();
   }

   return alloc_int(result);
}
DEFINE_PRIM(nme_stage_get_focus_id,1);

value nme_stage_set_focus(value inStage,value inObject,value inDirection)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      DisplayObject *obj = 0;
      AbstractToObject(inObject,obj);
      stage->SetFocusObject(obj);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_focus,3);

DO_STAGE_PROP(focus_rect,FocusRect,alloc_bool,val_bool)
DO_STAGE_PROP(scale_mode,ScaleMode,alloc_int,val_int)
DO_STAGE_PROP(align,Align,alloc_int,val_int)
DO_STAGE_PROP(quality,Quality,alloc_int,val_int)
DO_STAGE_PROP(display_state,DisplayState,alloc_int,val_int)
DO_PROP_READ(Stage,stage,stage_width,StageWidth,alloc_float);
DO_PROP_READ(Stage,stage,stage_height,StageHeight,alloc_float);


value nme_stage_is_opengl(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      return alloc_bool(stage->isOpenGL());
   }
   return alloc_bool(false);
}
DEFINE_PRIM(nme_stage_is_opengl,1);
 

// --- Input --------------------------------------------------------------

value nme_input_get_acceleration()
{
   double x,y,z;
   if (!GetAcceleration(x,y,z))
       return alloc_null();

   value obj = alloc_empty_object();
   alloc_field(obj,_id_x, alloc_float(x));
   alloc_field(obj,_id_y, alloc_float(y));
   alloc_field(obj,_id_z, alloc_float(z));
   return obj;
}

DEFINE_PRIM(nme_input_get_acceleration,0);


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

value nme_display_object_draw_to_surface(value *arg,int count)
{
   enum { aObject, aSurface, aMatrix, aColourTransform, aBlendMode, aClipRect, aSIZE};

   DisplayObject *obj;
   Surface *surf;
   if (AbstractToObject(arg[aObject],obj) && AbstractToObject(arg[aSurface],surf))
   {
      Rect r(surf->Width(),surf->Height());
      if (!val_is_null(arg[aClipRect]))
         FromValue(r,arg[aClipRect]);
      AutoSurfaceRender render(surf,r);

      Matrix matrix;
      if (!val_is_null(arg[aMatrix]))
         FromValue(matrix,arg[aMatrix]);
      RenderState state(surf,4);
      state.mTransform.mMatrix = &matrix;

      ColorTransform col_trans;
      if (!val_is_null(arg[aColourTransform]))
      {
         ColorTransform t;
         FromValue(t,arg[aColourTransform]);
         state.CombineColourTransform(state,&t,&col_trans);
      }

      // TODO: Blend mode
      state.mRoundSizeToPOW2 = false;
      state.mPhase = rpRender;

      obj->Render(render.Target(), state);
   }

   return alloc_null();
}

DEFINE_PRIM_MULT(nme_display_object_draw_to_surface)


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
      UserPoint point( val_field_numeric(ioPoint, _id_x),
                     val_field_numeric(ioPoint, _id_y) );
      UserPoint trans = obj->GlobalToLocal(point);
      alloc_field(ioPoint, _id_x, alloc_float(trans.x) );
      alloc_field(ioPoint, _id_y, alloc_float(trans.y) );
   }

   return alloc_null();
}

DEFINE_PRIM(nme_display_object_global_to_local,2);

value nme_display_object_hit_test_point(
				value inObj,value inX, value inY, value inShape, value inRecurse)
{
   DisplayObject *obj;
	UserPoint pos(val_number(inX),val_number(inY));

   if (AbstractToObject(inObj,obj))
   {
		if (val_bool(inShape))
		{
			Stage *stage = obj->getStage();
			if (stage)
			{
				bool recurse = val_bool(inRecurse);
				return alloc_bool( stage->HitTest( pos, obj, recurse ) );
			}
		}
		else
		{
			Matrix m = obj->GetFullMatrix(false);
			Transform trans;
			trans.mMatrix = &m;

			Extent2DF ext;
			obj->GetExtent(trans, ext, true );
			return alloc_bool( ext.Contains(pos) );
		}
	}

   return alloc_null();
}
DEFINE_PRIM(nme_display_object_hit_test_point,5);

value nme_display_object_set_filters(value inObj,value inFilters)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      FilterList filters;
      if (!val_is_null(inFilters))
         for(int f=0;f<val_array_size(inFilters);f++)
         {
            value filter = val_array_value(inFilters)[f];
            WString type = val2stdwstr( val_field(filter,_id_type) );
            int q = val_int(val_field(filter,_id_quality));
            if (q<1) continue;
            if (type==L"BlurFilter")
            {
               filters.push_back( new BlurFilter( q,
                   (int)val_field_numeric(filter,_id_blurX),
                   (int)val_field_numeric(filter,_id_blurY) ) );
            }
            else if (type==L"DropShadowFilter")
            {
               filters.push_back( new DropShadowFilter( q,
                   (int)val_field_numeric(filter,_id_blurX),
                   (int)val_field_numeric(filter,_id_blurY),
                   val_field_numeric(filter,_id_angle),
                   val_field_numeric(filter,_id_distance),
                   val_int( val_field(filter,_id_color) ),
                   val_field_numeric(filter,_id_strength),
                   val_field_numeric(filter,_id_alpha),
                   (bool)val_field_numeric(filter,_id_hideObject),
                   (bool)val_field_numeric(filter,_id_knockout),
                   (bool)val_field_numeric(filter,_id_inner)
                   ) );
            }
         }
         obj->setFilters(filters);
   }

   return alloc_null();
}

DEFINE_PRIM(nme_display_object_set_filters,2);

value nme_display_object_set_scale9_grid(value inObj,value inRect)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      if (val_is_null(inRect))
         obj->setScale9Grid(DRect(0,0,0,0));
      else
      {
         DRect rect;
         FromValue(rect,inRect);
         obj->setScale9Grid(rect);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(nme_display_object_set_scale9_grid,2);

value nme_display_object_set_scroll_rect(value inObj,value inRect)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      if (val_is_null(inRect))
         obj->setScrollRect(DRect(0,0,0,0));
      else
      {
         DRect rect;
         FromValue(rect,inRect);
         obj->setScrollRect(rect);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(nme_display_object_set_scroll_rect,2);

value nme_display_object_set_mask(value inObj,value inMask)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      DisplayObject *mask = 0;
      AbstractToObject(inMask,mask);
      obj->setMask(mask);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_display_object_set_mask,2);


value nme_display_object_set_matrix(value inObj,value inMatrix)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
       Matrix m;
       FromValue(m,inMatrix);

       obj->setMatrix(m);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_display_object_set_matrix,2);

value nme_display_object_get_matrix(value inObj,value outMatrix, value inFull)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Matrix m = val_bool(inFull) ? obj->GetLocalMatrix() : obj->GetFullMatrix(false);
      ToValue(outMatrix,m);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_display_object_get_matrix,3);

value nme_display_object_set_color_transform(value inObj,value inTrans)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
       ColorTransform trans;
       FromValue(trans,inTrans);

       obj->setColorTransform(trans);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_display_object_set_color_transform,2);

value nme_display_object_get_color_transform(value inObj,value outTrans, value inFull)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      ColorTransform t = val_bool(inFull) ? obj->GetLocalColorTransform() :
                                            obj->GetFullColorTransform();
      ToValue(outTrans,t);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_display_object_get_color_transform,3);

value nme_display_object_get_pixel_bounds(value inObj,value outBounds)
{
   return alloc_null();
}
DEFINE_PRIM(nme_display_object_get_pixel_bounds,2);



DO_DISPLAY_PROP(x,X,alloc_float,val_number)
DO_DISPLAY_PROP(y,Y,alloc_float,val_number)
DO_DISPLAY_PROP(scale_x,ScaleX,alloc_float,val_number)
DO_DISPLAY_PROP(scale_y,ScaleY,alloc_float,val_number)
DO_DISPLAY_PROP(rotation,Rotation,alloc_float,val_number)
DO_DISPLAY_PROP(width,Width,alloc_float,val_number)
DO_DISPLAY_PROP(height,Height,alloc_float,val_number)
DO_DISPLAY_PROP(alpha,Alpha,alloc_float,val_number)
DO_DISPLAY_PROP(bg,OpaqueBackground,alloc_int,val_int)
DO_DISPLAY_PROP(mouse_enabled,MouseEnabled,alloc_bool,val_bool)
DO_DISPLAY_PROP(cache_as_bitmap,CacheAsBitmap,alloc_bool,val_bool)
DO_DISPLAY_PROP(visible,Visible,alloc_bool,val_bool)
DO_DISPLAY_PROP(name,Name,alloc_wstring,val2stdwstr)
DO_PROP_READ(DisplayObject,display_object,mouse_x,MouseX,alloc_float)
DO_PROP_READ(DisplayObject,display_object,mouse_y,MouseY,alloc_float)


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


value nme_doc_swap_children(value inParent, value inChild0, value inChild1)
{
   DisplayObjectContainer *parent;
   if (AbstractToObject(inParent,parent))
   {
      parent->swapChildrenAt(val_int(inChild0), val_int(inChild1) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_doc_swap_children,3);


value nme_doc_remove_child(value inParent, value inPos)
{
   DisplayObjectContainer *parent;
   if (AbstractToObject(inParent,parent))
   {
      parent->removeChildAt(val_int(inPos));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_doc_remove_child,2);

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

value nme_gfx_clear(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
      gfx->clear();
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_clear,1);

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


value nme_gfx_begin_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth)
{
   Graphics *gfx;
   Surface  *surface;
   if (AbstractToObject(inGfx,gfx) && AbstractToObject(inBMP,surface) )
   {
      Matrix matrix;
      FromValue(matrix,inMatrix);
      gfx->beginBitmapFill( surface, matrix, val_bool(inRepeat), val_bool(inSmooth) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_begin_bitmap_fill,5);


value nme_gfx_begin_gradient_fill(value *arg, int args)
{
   enum { aGfx, aType, aColors, aAlphas, aRatios, aMatrix, aSpreadMethod, aInterpMethod,
          aFocal, aSIZE };

   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      Matrix matrix;
      FromValue(matrix,arg[aMatrix]);
      GraphicsGradientFill *grad = new GraphicsGradientFill(val_int(arg[aType]), 
         matrix,
         (SpreadMethod)val_int( arg[aSpreadMethod]),
         (InterpolationMethod)val_int( arg[aInterpMethod]),
         val_number( arg[aFocal] ) );
      int n = std::min( val_array_size(arg[aColors]),
           std::min(val_array_size(arg[aAlphas]), val_array_size(arg[aRatios]) ) );
      for(int i=0;i<n;i++)
         grad->AddStop( val_int( val_array_i( arg[aColors], i ) ),
                        val_number( val_array_i( arg[aAlphas], i ) ),
                        val_number( val_array_i( arg[aRatios], i ) )/255.0 );

      grad->IncRef();
      gfx->drawGraphicsDatum(grad);
      grad->DecRef();
   }
   return alloc_null();
}

DEFINE_PRIM_MULT(nme_gfx_begin_gradient_fill)

value nme_gfx_end_fill(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
      gfx->endFill();
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_end_fill,1);


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

value nme_gfx_draw_rect(value inGfx,value inX, value inY, value inWidth, value inHeight)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      gfx->drawRect( val_number(inX), val_number(inY), val_number(inWidth), val_number(inHeight) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_rect,5);


value nme_gfx_draw_round_rect(value *arg, int args)
{
   enum { aGfx, aX, aY, aW, aH, aRx, aRy, aSIZE };
   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      gfx->drawRoundRect( val_number(arg[aX]), val_number(arg[aX]), val_number(arg[aW]), val_number(arg[aH]), val_number(arg[aRx]), val_number(arg[aRy]) );
   }
   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gfx_draw_round_rect);

value nme_gfx_draw_triangles(value inGfx, value inVertices, value inIndices,
         value inUVData, value inCull )
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      QuickVec<float> vertices;
      QuickVec<int> indices;
      QuickVec<float> uvt;
      FillArrayDouble(vertices,inVertices);
      FillArrayInt(indices,inIndices);
      FillArrayDouble(uvt,inUVData);

      gfx->drawTriangles(vertices, indices, uvt, val_int(inCull) );
   }
   
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_triangles,5);


value nme_gfx_draw_data(value inGfx,value inData)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      int n = val_array_size(inData);
      for(int i=0;i<n;i++)
      {
         IGraphicsData *data;
         if (AbstractToObject(val_array_i(inData,i),data))
            gfx->drawGraphicsDatum(data);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_data,2);


value nme_gfx_draw_datum(value inGfx,value inDatum)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      IGraphicsData *datum;
      if (AbstractToObject(inDatum,datum))
            gfx->drawGraphicsDatum(datum);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_datum,2);

value nme_gfx_draw_tiles(value inGfx,value inSheet, value inXYIDs)
{
   Graphics *gfx;
   Tilesheet *sheet;
   if (AbstractToObject(inGfx,gfx) && AbstractToObject(inSheet,sheet))
   {
      bool smooth = false;
      gfx->beginTiles(&sheet->GetSurface(), smooth );

      int n = val_array_size(inXYIDs)/3;
      double *vals = val_array_double(inXYIDs);
      int max = sheet->Tiles();

      if (vals)
      {
         for(int i=0;i<n;i++)
         {
            int id = (int)(vals[2]+0.5);
            if (id>=0 && id<max)
            {
               const Rect &r = sheet->GetTile(id).mRect;
               gfx->tile(vals[0],vals[1],r);
            }
            vals+=3;
         }
      }
      else
      {
         value *vals = val_array_value(inXYIDs);
         if (vals)
         {
            for(int i=0;i<n;i++)
            {
               int id = (int)(val_number(vals[2])+0.5);
               //printf("tile %d/%d %f %f\n", id,max,val_number(vals[0]),val_number(vals[1]));
               if (id>=0 && id<max)
               {
                  const Rect &r = sheet->GetTile(id).mRect;
                  gfx->tile(val_number(vals[0]),val_number(vals[1]),r);
               }
               vals+=3;
            }
         }
      }

   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_tiles,3);


static bool sNekoLutInit = false;
static int sNekoLut[256];

value nme_gfx_draw_points(value inGfx,value inXYs, value inRGBA, value inDefaultRGBA,
      value inIs31Bits )
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      QuickVec<float> xys;
      FillArrayDouble(xys,inXYs);

      QuickVec<int> RGBAs;
      FillArrayInt(RGBAs,inRGBA);

      int def_rgba = val_int(inDefaultRGBA);

      if (val_bool(inIs31Bits))
      {
         if (!sNekoLutInit)
         {
            sNekoLutInit = true;
            for(int i=0;i<64;i++)
               sNekoLut[i] = ((int)(i*255.0/63.0 + 0.5)) << 24;
         }
         for(int i=0;i<RGBAs.size();i++)
         {
            int &rgba = RGBAs[i];
            rgba = (rgba & 0xffffff) | sNekoLut[(rgba>>24) & 63];
         }
         def_rgba = (def_rgba & 0xffffff) | sNekoLut[(def_rgba>>24) & 63];
      }

      gfx->drawPoints(xys,RGBAs,def_rgba);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_points,5);




// --- IGraphicsData -----------------------------------------------------



value nme_graphics_path_create(value inCommands,value inData,value inWinding)
{
   GraphicsPath *result = new GraphicsPath();

   if (!val_bool(inWinding))
      result->winding = wrNonZero;

   FillArrayInt(result->commands,inCommands);
   FillArrayDouble(result->data,inData);

   return ObjectToAbstract(result);
}
DEFINE_PRIM(nme_graphics_path_create,3)


value nme_graphics_path_curve_to(value inPath,value inX1, value inY1, value inX2, value inY2)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->curveTo(val_number(inX1), val_number(inY1), val_number(inX2), val_number(inY2) );
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_curve_to,5)



value nme_graphics_path_line_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->lineTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_line_to,3)

value nme_graphics_path_move_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->moveTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_move_to,3)


   
value nme_graphics_path_wline_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->wideLineTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_wline_to,3)

value nme_graphics_path_wmove_to(value inPath,value inX1, value inY1)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      path->wideMoveTo(val_number(inX1), val_number(inY1));
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_wmove_to,3)


value nme_graphics_path_get_commands(value inPath,value outCommands)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayInt(outCommands,path->commands);
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_get_commands,2)

value nme_graphics_path_set_commands(value inPath,value inCommands)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayInt(path->commands,inCommands);
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_set_commands,2)

value nme_graphics_path_get_data(value inPath,value outData)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayDouble(outData,path->data);
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_get_data,2)

value nme_graphics_path_set_data(value inPath,value inData)
{
   GraphicsPath *path;
   if (AbstractToObject(inPath,path))
      FillArrayDouble(path->data,inData);
   return alloc_null();
}
DEFINE_PRIM(nme_graphics_path_set_data,2)



// --- IGraphicsData - Fills ---------------------------------------------

value nme_graphics_solid_fill_create(value inColour, value inAlpha)
{
   GraphicsSolidFill *solid = new GraphicsSolidFill( val_int(inColour), val_number(inAlpha) );
   return ObjectToAbstract(solid);
}
DEFINE_PRIM(nme_graphics_solid_fill_create,2)


value nme_graphics_end_fill_create()
{
   GraphicsEndFill *end = new GraphicsEndFill;
   return ObjectToAbstract(end);
}
DEFINE_PRIM(nme_graphics_end_fill_create,2)


// --- IGraphicsData - Stroke ---------------------------------------------

value nme_graphics_stroke_create(value* arg, int nargs)
{
   enum { argThickness, argPixelHinting, argScaleMode, argCapsStyle,
          argJointStyle, argMiterLimit, argFill, argSIZE };

   double thickness = -1;
   if (!val_is_null(arg[argThickness]))
   {
      thickness = val_number(arg[argThickness]);
      if (thickness<0)
         thickness = 0;
   }

   IGraphicsFill *fill=0;
   AbstractToObject(arg[argFill],fill);

   GraphicsStroke *stroke = new GraphicsStroke(fill, thickness,
                 val_bool(arg[argPixelHinting]),
                 (StrokeScaleMode)val_int(arg[argScaleMode]),
                 (StrokeCaps)val_int(arg[argCapsStyle]),
                 (StrokeJoints)val_int(arg[argJointStyle]),
                 val_number(arg[argMiterLimit]) );

   return ObjectToAbstract(stroke);
}

DEFINE_PRIM_MULT(nme_graphics_stroke_create)



// --- TextField --------------------------------------------------------------

value nme_text_field_create()
{
   TextField *text = new TextField();
   return ObjectToAbstract(text);
}
DEFINE_PRIM(nme_text_field_create,0)

inline value alloc_wstring(const WString &inStr)
   { return alloc_wstring_len(inStr.c_str(),inStr.length()); }


void FromValue(Optional<int> &outVal,value inVal) { outVal = val_int(inVal); }
void FromValue(Optional<uint32> &outVal,value inVal) { outVal = val_int(inVal); }
void FromValue(Optional<bool> &outVal,value inVal) { outVal = val_bool(inVal); }
void FromValue(Optional<WString> &outVal,value inVal)
{
   outVal = val2stdwstr(inVal);
}
void FromValue(Optional<QuickVec<int> > &outVal,value inVal)
{
   QuickVec<int> &val = outVal.Set();
   int n = val_array_size(inVal);
   val.resize(n);
   for(int i=0;i<n;i++)
      val[i] = val_int( val_array_i(inVal,i) );
}
void FromValue(Optional<TextFormatAlign> &outVal,value inVal)
{
   WString name = val2stdwstr(inVal);
   if (name==L"center")
      outVal = tfaCenter;
   else if (name==L"justify")
      outVal = tfaJustify;
   else if (name==L"right")
      outVal = tfaRight;
   else
      outVal = tfaLeft;
}

#define STF(attrib) \
{ \
   value tmp = val_field(inValue,_id_##attrib); \
   if (!val_is_null(tmp)) FromValue(outFormat.attrib, tmp); \
}

void SetTextFormat(TextFormat &outFormat, value inValue)
{
   STF(align);
   STF(blockIndent);
   STF(bold);
   STF(bullet);
   STF(color);
   STF(font);
   STF(indent);
   STF(italic);
   STF(kerning);
   STF(leading);
   STF(leftMargin);
   STF(letterSpacing);
   STF(rightMargin);
   STF(size);
   STF(tabStops);
   STF(target);
   STF(underline);
   STF(url);
}



value ToValue(const int &inVal) { return alloc_int(inVal); }
value ToValue(const uint32 &inVal) { return alloc_int(inVal); }
value ToValue(const bool &inVal) { return alloc_bool(inVal); }
value ToValue(const WString &inVal) { return alloc_wstring(inVal); }
value ToValue(const QuickVec<int> &outVal)
{
   // TODO:
   return alloc_null();
}
value ToValue(const TextFormatAlign &inTFA)
{
   switch(inTFA)
   {
      case tfaLeft : return alloc_wstring(L"left");
      case tfaRight : return alloc_wstring(L"right");
      case tfaCenter : return alloc_wstring(L"center");
      case tfaJustify : return alloc_wstring(L"justify");
   }

   return alloc_wstring(L"left");
}


#define GTF(attrib) \
{ \
   alloc_field(outValue, _id_##attrib, ToValue( inFormat.attrib.Get() ) ); \
}


void GetTextFormat(const TextFormat &inFormat, value &outValue)
{
   GTF(align);
   GTF(blockIndent);
   GTF(bold);
   GTF(bullet);
   GTF(color);
   GTF(font);
   GTF(indent);
   GTF(italic);
   GTF(kerning);
   GTF(leading);
   GTF(leftMargin);
   GTF(letterSpacing);
   GTF(rightMargin);
   GTF(size);
   GTF(tabStops);
   GTF(target);
   GTF(underline);
   GTF(url);
}


value nme_text_field_set_def_text_format(value inText,value inFormat)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      TextFormat *fmt = TextFormat::Create(true);
      SetTextFormat(*fmt,inFormat);
      text->setDefaultTextFormat(fmt);
      fmt->DecRef();
   }
   return alloc_null();
}

DEFINE_PRIM(nme_text_field_set_def_text_format,2)

value nme_text_field_set_text_format(value inText,value inFormat,value inStart,value inEnd)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      TextFormat *fmt = TextFormat::Create(true);
      SetTextFormat(*fmt,inFormat);
      text->setTextFormat(fmt,val_int(inStart),val_int(inEnd));
      fmt->DecRef();
   }
   return alloc_null();
}

DEFINE_PRIM(nme_text_field_set_text_format,4)


value nme_text_field_get_def_text_format(value inText,value outFormat)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      const TextFormat *fmt = text->getDefaultTextFormat();
      GetTextFormat(*fmt,outFormat);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_text_field_get_def_text_format,2);



#define TEXT_PROP_GET(prop,Prop,to_val) \
value nme_text_field_get_##prop(value inHandle) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      return to_val(t->get##Prop()); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_text_field_get_##prop,1);


#define TEXT_PROP(prop,Prop,to_val,from_val) \
   TEXT_PROP_GET(prop,Prop,to_val) \
value nme_text_field_set_##prop(value inHandle,value inValue) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      t->set##Prop(from_val(inValue)); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_text_field_set_##prop,2);

TEXT_PROP(text,Text,alloc_wstring,val2stdwstr);
TEXT_PROP(html_text,HTMLText,alloc_wstring,val2stdwstr);
TEXT_PROP(text_color,TextColor,alloc_int,val_int);
TEXT_PROP(selectable,Selectable,alloc_bool,val_bool);
TEXT_PROP(type,IsInput,alloc_bool,val_bool);
TEXT_PROP(multiline,Multiline,alloc_bool,val_bool);
TEXT_PROP(word_wrap,WordWrap,alloc_bool,val_bool);
TEXT_PROP(background,Background,alloc_bool,val_bool);
TEXT_PROP(background_color,BackgroundColor,alloc_int,val_int);
TEXT_PROP(border,Border,alloc_bool,val_bool);
TEXT_PROP(border_color,BorderColor,alloc_int,val_int);
TEXT_PROP(auto_size,AutoSize,alloc_int,val_int);
TEXT_PROP_GET(text_width,TextWidth,alloc_float);
TEXT_PROP_GET(text_height,TextHeight,alloc_float);
TEXT_PROP_GET(max_scroll_h,MaxScrollH,alloc_int);
TEXT_PROP_GET(max_scroll_v,MaxScrollV,alloc_int);
TEXT_PROP_GET(bottom_scroll_v,BottomScrollV,alloc_int);
TEXT_PROP(scroll_h,ScrollH,alloc_int,val_int);
TEXT_PROP(scroll_v,ScrollV,alloc_int,val_int);



value nme_bitmap_data_create(value inWidth, value inHeight, value inFlags, value inRGB, value inA)
{
   uint32 flags = val_int(inFlags);
   PixelFormat format = (flags & 0x01) ? pfARGB : pfXRGB;
   Surface *result = new SimpleSurface( val_int(inWidth),val_int(inHeight), format );
   if (val_is_int(inRGB))
   {
      int rgb = val_int(inRGB);
      int alpha = val_is_int(inA) ? val_int(inA) : 255;
      result->Clear( rgb + (alpha<<24) );
   }
   return ObjectToAbstract(result);
}
DEFINE_PRIM(nme_bitmap_data_create,5);

value nme_bitmap_data_width(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int(surface->Width());
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_width,1);

value nme_bitmap_data_height(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int(surface->Height());
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_height,1);

value nme_bitmap_data_clear(value inHandle,value inRGB)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->Clear( val_int(inRGB) | 0xff000000 );
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_clear,2);

value nme_bitmap_data_get_transparent(value inHandle,value inRGB)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_bool( surface->Format() & pfHasAlpha );
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_transparent,1);

value nme_bitmap_data_fill(value inHandle, value inRect, value inRGB, value inA)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      if (val_is_null(inRect))
         surface->Clear( val_int(inRGB) | (val_int(inA)<<24) );
      else
      {
         Rect r(val_int(val_field(inRect,_id_x)),val_int(val_field(inRect,_id_y)),
                val_int(val_field(inRect,_id_width)),val_int(val_field(inRect,_id_height)) );
         surface->Clear( val_int(inRGB) | (val_int(inA)<<24), &r );
      }
   }
   return alloc_null();

}
DEFINE_PRIM(nme_bitmap_data_fill,4);

value nme_bitmap_data_load(value inFilename)
{
   Surface *surface = Surface::Load(val_os_string(inFilename));
   if (surface)
   {
      value result = ObjectToAbstract(surface);
      surface->DecRef();
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_load,1);

value nme_bitmap_data_from_bytes(value inRGBBytes, value inAlphaBytes)
{
	ByteData bytes;
	if (!FromValue(bytes,inRGBBytes))
		return alloc_null();

	Surface *surface = Surface::LoadFromBytes(bytes.data,bytes.length);
	if (surface)
	{
		value result = ObjectToAbstract(surface);
		surface->DecRef();
		return result;
	}

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_from_bytes,2);


value nme_bitmap_data_clone(value inSurface)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
		Surface *result = surf->clone();
      value val = ObjectToAbstract(result);
		result->DecRef();
		return val;
	}
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_clone,1);


value nme_bitmap_data_copy(value inSource, value inSourceRect, value inTarget, value inOffset)
{
   Surface *source;
   Surface *dest;
   if (AbstractToObject(inSource,source) && AbstractToObject(inTarget,dest))
   {
      Rect rect;
      FromValue(rect,inSourceRect);
      ImagePoint offset;
      FromValue(offset,inOffset);

      AutoSurfaceRender render(dest);
      source->BlitTo(render.Target(),rect,offset.x, offset.y, bmNormal, 0);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_copy,4);

value nme_bitmap_data_get_pixels(value inSurface, value inRect, value outBytes)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
		Rect rect(0,0,surf->Width(),surf->Height());
		FromValue(rect,inRect);
		if (rect.w>0 && rect.h>0)
		{
		   int size = rect.w * rect.h*4;
			ByteArray *array;
			buffer buf;
   		if (AbstractToObject(outBytes,array))
			{
				array->mBytes.resize(size);
				surf->getPixels(rect,(unsigned int *)&array->mBytes[0]);
			}
			else if (buf=val_to_buffer(outBytes))
			{
				buffer_set_size(buf, size);
				surf->getPixels(rect,(unsigned int *)buffer_data(buf));
			}
		}
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_pixels,3);

value nme_bitmap_data_get_pixel(value inSurface, value inX, value inY)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
		return alloc_int(surf->getPixel(val_int(inX),val_int(inY)) & 0xffffff);

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_pixel,3);

value nme_bitmap_data_get_pixel32(value inSurface, value inX, value inY)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
		return alloc_int(surf->getPixel(val_int(inX),val_int(inY)));

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_pixel32,3);


value nme_bitmap_data_get_pixel_rgba(value inSurface, value inX,value inY)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
	{
		int rgb = surf->getPixel(val_int(inX),val_int(inY));
		value result = alloc_empty_object();
		alloc_field(result,_id_rgb, alloc_int( rgb & 0xffffff) );
		alloc_field(result,_id_a, alloc_int( rgb >> 24) );
		return result;
	}

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_pixel_rgba,3);

value nme_bitmap_data_scroll(value inSurface, value inDX, value inDY)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
		surf->scroll(val_int(inDX),val_int(inDY));

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_scroll,3);

value nme_bitmap_data_set_pixel(value inSurface, value inX, value inY, value inRGB)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
		surf->setPixel(val_int(inX),val_int(inY),val_int(inRGB));

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_pixel,4);

value nme_bitmap_data_set_pixel32(value inSurface, value inX, value inY, value inRGB)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
		surf->setPixel(val_int(inX),val_int(inY),val_int(inRGB),true);

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_pixel32,4);


value nme_bitmap_data_set_pixel_rgba(value inSurface, value inX, value inY, value inRGBA)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
	{
		value a = val_field(inRGBA,_id_a);
		value rgb = val_field(inRGBA,_id_rgb);
		if (val_is_int(a) && val_is_int(rgb))
		   surf->setPixel(val_int(inX),val_int(inY),(val_int(a)<<24) | val_int(rgb), true );
	}
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_pixel_rgba,4);

value nme_bitmap_data_set_bytes(value inSurface, value inRect, value inBytes)
{
	Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
		Rect rect(0,0,surf->Width(),surf->Height());
		FromValue(rect,inRect);
		if (rect.w>0 && rect.h>0)
		{
			ByteArray *array;
			buffer buf;
   		if (AbstractToObject(inBytes,array))
			{
				//array->mBytes.resize(size);
				surf->setPixels(rect,(unsigned int *)&array->mBytes[0]);
			}
			else if (buf=val_to_buffer(inBytes))
			{
				//buffer_set_size(buf, size);
				surf->setPixels(rect,(unsigned int *)buffer_data(buf));
			}
		}
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_bytes,3);

value nme_render_surface_to_surface(value* arg, int nargs)
{
   enum { aTarget, aSurface, aMatrix, aColourTransform, aBlendMode, aClipRect, aSmooth, aSIZE};

   Surface *surf;
   Surface *src;
   if (AbstractToObject(arg[aTarget],surf) && AbstractToObject(arg[aSurface],src))
   {
      Rect r(surf->Width(),surf->Height());
      if (!val_is_null(arg[aClipRect]))
         FromValue(r,arg[aClipRect]);
      AutoSurfaceRender render(surf,r);

      Matrix matrix;
      if (!val_is_null(arg[aMatrix]))
         FromValue(matrix,arg[aMatrix]);
      RenderState state(surf,4);
      state.mTransform.mMatrix = &matrix;

      ColorTransform col_trans;
      if (!val_is_null(arg[aColourTransform]))
      {
         ColorTransform t;
         FromValue(t,arg[aColourTransform]);
         state.CombineColourTransform(state,&t,&col_trans);
      }

      // TODO: Blend mode
      state.mRoundSizeToPOW2 = false;
      state.mPhase = rpRender;

      Graphics *gfx = new Graphics(true);
      gfx->beginBitmapFill(src,Matrix(),false,val_bool(arg[aSmooth]));
      gfx->moveTo(0,0);
      gfx->lineTo(src->Width(),0);
      gfx->lineTo(src->Width(),src->Height());
      gfx->lineTo(0,src->Height());
      gfx->lineTo(0,0);

      gfx->Render(render.Target(),state);

      gfx->DecRef();


   }

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_render_surface_to_surface);


// --- Sound --------------------------------------------------

value nme_sound_from_file(value inFilename,value inForceMusic)
{
   Sound *sound = val_is_null(inFilename) ? 0 :
                  Sound::Create( val_string(inFilename), val_bool(inForceMusic) );

   if (sound)
   {
      value result =  ObjectToAbstract(sound);
      sound->DecRef();
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_from_file,2);

#define GET_ID3(name) \
  sound->getID3Value(name,val); \
  alloc_field(outVar, val_id(name), alloc_string(val.c_str() ) );

value nme_sound_get_id3(value inSound, value outVar)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      std::string val;
      GET_ID3("album")
      GET_ID3("artist")
      GET_ID3("comment")
      GET_ID3("genre")
      GET_ID3("songName")
      GET_ID3("track")
      GET_ID3("year")
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_get_id3,2);

value nme_sound_get_length(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      return alloc_float( sound->getLength() );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_get_length,1);
 
value nme_sound_close(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      sound->close();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_close,1);
 
value nme_sound_get_status(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      value result = alloc_empty_object();
      alloc_field(result, _id_bytesLoaded, alloc_int(sound->getBytesLoaded()));
      alloc_field(result, _id_bytesTotal, alloc_int(sound->getBytesTotal()));
      if (!sound->ok())
         alloc_field(result, _id_error, alloc_string(sound->getError().c_str()));
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_get_status,1);
 
value nme_sound_channel_is_complete(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_bool(channel->isComplete());
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_is_complete,1);

value nme_sound_channel_get_left(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getLeft());
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_get_left,1);

value nme_sound_channel_get_right(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getRight());
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_get_right,1);

value nme_sound_channel_get_position(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getPosition());
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_get_position,1);

value nme_sound_channel_stop(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      channel->stop();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_stop,1);

value nme_sound_channel_set_transform(value inChannel, value inTransform)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      SoundTransform trans;
      FromValue(trans,inTransform);
      channel->setTransform(trans);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_set_transform,2);

value nme_sound_channel_create(value inSound, value inStart, value inLoops, value inTransform)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      SoundTransform trans;
      FromValue(trans,inTransform);
      SoundChannel *channel = sound->openChannel(val_number(inStart),val_int(inLoops),trans);
      if (channel)
      {
         value result = ObjectToAbstract(channel);
         return result;
      }
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_create,4);

// --- Tilesheet -----------------------------------------------

value nme_tilesheet_create(value inSurface)
{
   Surface *surface;
   if (AbstractToObject(inSurface,surface))
   {
      surface->IncRef();
      Tilesheet *sheet = new Tilesheet(surface);
      surface->DecRef();
      return ObjectToAbstract(sheet);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_tilesheet_create,1);

value nme_tilesheet_add_rect(value inSheet,value inRect)
{
   Tilesheet *sheet;
   if (AbstractToObject(inSheet,sheet))
   {
      Rect rect;
      FromValue(rect,inRect);
      sheet->addTileRect(rect);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_tilesheet_add_rect,2);



// Reference this to bring in all the symbols for the static library
extern "C" int nme_register_prims() { return 0; }



