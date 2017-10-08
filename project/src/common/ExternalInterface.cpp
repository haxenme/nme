#ifndef STATIC_LINK
#define IMPLEMENT_API
#elif defined(HXCPP_JS_PRIME)
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
// Include neko glue....
#define NEKO_COMPATIBLE
#endif

#if defined(EMSCRIPTEN) || defined(HX_WINRT)
#define NME_NO_CURL
#define NME_NO_CAMERA
#endif
#if defined(HXCPP_JS_PRIME) || defined(HX_WINRT)
#define NME_NO_LZMA
#endif

#ifdef ANDROID
#include <android/log.h>
#endif

#include <nme/NmeCffi.h>
#include <Utils.h>
#include <Display.h>
#include <TextField.h>
#include <Surface.h>
#include <Tilesheet.h>
#include <Font.h>
#include <Sound.h>
#include <Video.h>
#include <Input.h>
#include <algorithm>
#include <URL.h>
#include <ByteArray.h>
#include <Lzma.h>
#include <NMEThread.h>
#include <StageVideo.h>
#include <NmeBinVersion.h>
#ifndef NME_TOOLKIT_BUILD
#include <NmeStateVersion.h>
#endif
#include <nme/NmeApi.h>


#ifdef min
#undef min
#undef max
#endif    


namespace nme
{
void InitCamera();

// Not static
int _id_id=0;

static int _id_type;
static int _id_x;
static int _id_y;
static int _id_z;
static int _id_scaleX;
static int _id_scaleY;
static int _id_deltaX;
static int _id_deltaY;
static int _id_width;
static int _id_height;
static int _id_length;
static int _id_value;
static int _id_bigEndian;
static int _id_flags;
static int _id_result;
static int _id_code;
static int _id_text;
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
static int _id_userAgent;
static int _id_error;
static int _id_state;
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

static int _id_authType;
static int _id_credentials;
static int _id_cookieString;
static int _id_verbose;
static int _id_followRedirects;

static int _id_method;
static int _id_requestHeaders;
static int _id_name;
static int _id_contentType;
static int _id___bytes;

static int _id_rect;
static int _id_matrix;

static int _id_ascent;
static int _id_descent;

static FRect _tile_rect;

vkind gObjectKind;

NmeApi gNmeApi;


static int sgIDsInit = false;
static int sgRenderingCount = 0;
#if 1
#define CHECK_ACCESS(where)
#else
#define CHECK_ACCESS(where) \
   if(sgRenderingCount) \
     { ELOG("Error calling gfx api '%s' while rendering.",where); }
#endif

extern "C" void InitIDs()
{
   if (sgIDsInit)
      return;
   sgIDsInit = true;
   _id_type = val_id("type");
   _id_x = val_id("x");
   _id_y = val_id("y");
   _id_z = val_id("z");
   _id_scaleX = val_id("scaleX");
   _id_scaleY = val_id("scaleY");
   _id_deltaX = val_id("deltaX");
   _id_deltaY = val_id("deltaY");
   _id_width = val_id("width");
   _id_height = val_id("height");
   _id_length = val_id("length");
   _id_value = val_id("value");
   _id_bigEndian = val_id("bigEndian");
   _id_id = val_id("id");
   _id_flags = val_id("flags");
   _id_result = val_id("result");
   _id_code = val_id("code");
   _id_text = val_id("text");
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
   _id_userAgent = val_id("userAgent");
   _id_error = val_id("error");
   _id_bytesTotal = val_id("bytesTotal");
   _id_state = val_id("state");
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

   _id_authType = val_id("authType");
   _id_credentials = val_id("credentials");
   _id_cookieString = val_id("cookieString");
   _id_verbose = val_id("verbose");
   _id_followRedirects = val_id("followRedirects");
   
   _id_method = val_id("method");
   _id_requestHeaders = val_id("requestHeaders");
   _id_name = val_id("name");
   _id_contentType = val_id("contentType");
   _id___bytes = val_id("__bytes");
   _id_rect = val_id("rect");
   _id_matrix = val_id("matrix");

   _id_ascent = val_id("ascent");
   _id_descent = val_id("descent");

   kind_share(&gObjectKind,"nme::Object");
   
   _tile_rect = FRect(0, 0, 1, 1);

   #ifndef NME_NO_CAMERA
   InitCamera();
   #endif
}

DEFINE_ENTRY_POINT(InitIDs)



template<typename T>
void FillArrayInt(QuickVec<T> &outArray,value inVal)
{
   if (val_is_null(inVal))
      return;
   int n = val_array_size(inVal);
   if (n <= 0)
      return;
   outArray.resize(n);
   int *c = val_array_int(inVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         outArray[i] = c[i];
   }
   else
   {
      values_array vals = val_array_value(inVal);
      if (value_array_ok(vals))
      {
         for(int i=0;i<n;i++)
            outArray[i] = array_get_int(vals,i);
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
   if (n <= 0)
      return;
   val_array_set_size(outVal,n);
   int *c = val_array_int(outVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         c[i] = inArray[i];
   }
   else
   {
      values_array vals = val_array_value(outVal);
      if (value_array_ok(vals))
         for(int i=0;i<n;i++)
            array_set_int(vals,i,inArray[i]);
      else
         for(int i=0;i<n;i++)
            val_array_set_i(outVal,i,alloc_int(inArray[i]));
   }
}

template<typename T>
void FillArrayDouble(value outVal, const QuickVec<T> &inArray)
{
   int n = inArray.size();
   if (n <= 0)
      return;
   val_array_set_size(outVal,n);
   double *c = val_array_double(outVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         c[i] = inArray[i];
   }
   else
   {
      float *f = val_array_float(outVal);
      if (f)
      {
         for(int i=0;i<n;i++)
            f[i] = inArray[i];
      }
      else
      {
         values_array vals = val_array_value(outVal);
         if (value_array_ok(vals))
            for(int i=0;i<n;i++)
               array_set_float(vals,i,inArray[i]);
         else
            for(int i=0;i<n;i++)
               val_array_set_i(outVal,i,alloc_float(inArray[i]));
      }
   }
}




template<typename T,int N>
void FillArrayDoubleN(QuickVec<T,N> &outArray,value inVal)
{
   if (val_is_null(inVal))
      return;
   int n = val_array_size(inVal);
   if (n <= 0)
      return;
   outArray.resize(n);
   double *c = val_array_double(inVal);
   if (c)
   {
      for(int i=0;i<n;i++)
         outArray[i] = c[i];
   }
   else
   {
      float *f = val_array_float(inVal);
      if (f)
      {
         for(int i=0;i<n;i++)
            outArray[i] = f[i];
      }
      else
      {
         values_array vals = val_array_value(inVal);
         if (value_array_ok(vals))
            for(int i=0;i<n;i++)
               outArray[i] = array_get_double(vals,i);
         else
            for(int i=0;i<n;i++)
               outArray[i] = val_number(val_array_i(inVal,i));
      }
   }
}


template<typename T>
void FillArrayDouble(QuickVec<T> &outArray,value inVal)
{
   FillArrayDoubleN<T,16>(outArray,inVal);
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

int ValInt(value inObject, int inID, int inDefault)
{
   value field = val_field(inObject,inID);
   if (val_is_null(field))
      return inDefault;
   return (int)val_number(field);
}


void FromValue(Event &outEvent, value inValue)
{
   outEvent.type = (EventType)ValInt(inValue,_id_type,etUnknown);
   outEvent.x = ValInt(inValue,_id_x,0);
   outEvent.y = ValInt(inValue,_id_y,0);
   outEvent.value = ValInt(inValue,_id_value,0);
   outEvent.id = ValInt(inValue,_id_id,-1);
   outEvent.flags = ValInt(inValue,_id_flags,0);
   outEvent.code = ValInt(inValue,_id_code,0);
   outEvent.result = (EventResult)ValInt(inValue,_id_result,0);
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



int RGB2Int32(value inRGB)
{
   #ifndef HXCPP_JS_PRIME
   if (val_is_int(inRGB))
      return val_int(inRGB);
   if (val_is_object(inRGB))
   {
      return (int)(val_field_numeric(inRGB,_id_rgb)) |
             ( ((int)val_field_numeric(inRGB,_id_a)) << 24 );
   }
   #else
   return val_int(inRGB);
   #endif
   return 0;
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

Filter *FilterFromValue(value filter)
{
   WString type = valToStdWString( val_field(filter,_id_type) );
   if (type==L"BlurFilter")
   {
      int q = val_int(val_field(filter,_id_quality));
      if (q<1) return 0;
      return( new BlurFilter( q,
          (int)val_field_numeric(filter,_id_blurX),
          (int)val_field_numeric(filter,_id_blurY) ) );
   }
   else if (type==L"ColorMatrixFilter")
   {
      QuickVec<float> inMatrix;
      FillArrayDouble(inMatrix, val_field(filter,_id_matrix));
      return( new ColorMatrixFilter(inMatrix) );
   }
   else if (type==L"DropShadowFilter")
   {
      int q = val_int(val_field(filter,_id_quality));
      if (q<1) return 0;
      return( new DropShadowFilter( q,
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
   return 0;
}

void ToValue(value &outVal,const Rect &inRect)
{
    alloc_field(outVal,_id_x, alloc_float(inRect.x) );
    alloc_field(outVal,_id_y, alloc_float(inRect.y) );
    alloc_field(outVal,_id_width, alloc_float(inRect.w) );
    alloc_field(outVal,_id_height, alloc_float(inRect.h) );
}

void FromValue(ImagePoint &outPoint,value inValue)
{
   outPoint.x = val_field_numeric(inValue,_id_x);
   outPoint.y = val_field_numeric(inValue,_id_y);
}

void FromValue(UserPoint &outPoint,value inValue)
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



#ifndef EMSCRIPTEN
void FromValue(value obj, URLRequest &request)
{
   request.url = val_string( val_field(obj, _id_url) );
   value userAgent = val_field(obj, _id_userAgent);
   request.userAgent = val_is_string(userAgent) ? val_string( userAgent ) : "";
   request.authType = val_field_numeric(obj, _id_authType );
   request.credentials = val_string( val_field(obj, _id_credentials) );
   request.cookies = val_string( val_field(obj, _id_cookieString) );
   request.method = val_string( val_field(obj, _id_method) );
   request.contentType = val_string( val_field(obj, _id_contentType) );
   request.debug = val_field_numeric( obj, _id_verbose );
   request.postData = ByteArray( val_field(obj,_id___bytes) );
   request.followRedirects = val_field_numeric( obj, _id_followRedirects ); 

   // headers
  if (!val_is_null(val_field(obj, _id_requestHeaders)) && val_array_size(val_field(obj, _id_requestHeaders)) )
  {
    int size = val_array_size(val_field(obj, _id_requestHeaders));
    QuickVec<URLRequestHeader> headers;
     value *header_array = val_array_value(val_field(obj, _id_requestHeaders));
     for(int i = 0; i < val_array_size(val_field(obj, _id_requestHeaders)); i++)
     {
        value headerVal = header_array ? header_array[i] : val_array_i(val_field(obj, _id_requestHeaders), i);
        URLRequestHeader header;
        header.name = val_string(val_field(headerVal, _id_name));
        header.value = val_string(val_field(headerVal, _id_value));
        headers.push_back(header);
    }
  request.headers = headers;
  }
}
#endif

#ifndef HXCPP_JS_PRIME
void print_field(value inValue, int id, void *cookie)
{
   if (val_is_string(inValue))
      printf("Field : %d = %s\n",id,val_string(inValue));
   else
      printf("Field : %d = %f\n",id,val_number(inValue));
}
#endif

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

#define DO_PROP_READ_PRIME(Obj,obj_prefix,prop,Prop,to_type) \
to_type nme_##obj_prefix##_get_##prop(value inObj) \
{ \
   Obj *obj; \
   if (AbstractToObject(inObj,obj)) \
   AbstractToObject(inObj,obj); \
      return obj->get##Prop(); \
   return (to_type)0; \
} \
\
DEFINE_PRIME1(nme_##obj_prefix##_get_##prop)

#define DO_PROP_PRIME(Obj,obj_prefix,prop,Prop,to_type,from_type) \
DO_PROP_READ_PRIME(Obj,obj_prefix,prop,Prop,to_type) \
void nme_##obj_prefix##_set_##prop(value inObj,from_type inVal) \
{ \
   Obj *obj; \
   if (AbstractToObject(inObj,obj)) \
      obj->set##Prop(inVal); \
} \
\
DEFINE_PRIME2v(nme_##obj_prefix##_set_##prop)

#define DO_DISPLAY_PROP_PRIME(prop,Prop,to_val,from_val) \
   DO_PROP_PRIME(DisplayObject,display_object,prop,Prop,to_val,from_val) 
   
#define DO_DISPLAY_PROP(prop,Prop,to_val,from_val) \
   DO_PROP(DisplayObject,display_object,prop,Prop,to_val,from_val) 

#define DO_STAGE_PROP(prop,Prop,to_val,from_val) \
   DO_PROP(Stage,stage,prop,Prop,to_val,from_val) 


using namespace nme;


double nme_time_stamp()
{
   return GetTimeStamp();
}
DEFINE_PRIME0(nme_time_stamp)


value nme_error_output(value message)
{
   fprintf(stderr, "%s", valToHxString(message).c_str() );
   return alloc_null();
}
DEFINE_PRIM(nme_error_output,1);

value nme_get_ndll_version()
{
   return alloc_int( NME_BINARY_VERSION );
}
DEFINE_PRIM(nme_get_ndll_version,0);

value nme_get_nme_state_version()
{
   #ifdef NME_TOOLKIT_BUILD
   return alloc_string( "toolkit" );
   #else
   return alloc_string( NME_STATE_VERSION );
   #endif
}
DEFINE_PRIM(nme_get_nme_state_version,0);

value nme_get_bits()
{
   return alloc_int( sizeof(void *) * 8 );
}
DEFINE_PRIM(nme_get_bits,0);


value nme_log(value inMessage)
{
   HxString message = valToHxString(inMessage);
   #ifdef IPHONE
      nmeLog(message.c_str());
   #else
      printf("%s\n",message.c_str());
   #endif

   return alloc_null();
}
DEFINE_PRIM(nme_log,1);





// --- ByteArray -----------------------------------------------------

AutoGCRoot *gByteArrayCreate = 0;
AutoGCRoot *gByteArrayLen = 0;
AutoGCRoot *gByteArrayResize = 0;
AutoGCRoot *gByteArrayBytes = 0;

AutoGCRoot *gResourceFactory = 0;

value nme_byte_array_init(value inFactory, value inLen, value inResize, value inBytes)
{
   gByteArrayCreate = new AutoGCRoot(inFactory);
   gByteArrayLen = new AutoGCRoot(inLen);
   gByteArrayResize = new AutoGCRoot(inResize);
   gByteArrayBytes = new AutoGCRoot(inBytes);
   return alloc_null();
}
DEFINE_PRIM(nme_byte_array_init,4);


value nme_set_resource_factory(value inFactory)
{
   gResourceFactory = new AutoGCRoot(inFactory);
   return alloc_null();
}
DEFINE_PRIM(nme_set_resource_factory,1);



ByteArray::ByteArray(int inSize) :
   mValue(val_call1(gByteArrayCreate->get(), alloc_int(inSize) ))
{
}

ByteArray::ByteArray() : mValue(val_null) { }

ByteArray::ByteArray(const QuickVec<uint8> &inData)
   : mValue(val_call1(gByteArrayCreate->get(), alloc_int(inData.size()) ))
{
   uint8 *bytes = Bytes();
   if (bytes)
     memcpy(bytes, &inData[0], inData.size() );
}

ByteArray::ByteArray(const ByteArray &inRHS) : mValue(inRHS.mValue) { }

ByteArray::ByteArray(value inValue) : mValue(inValue) { }

void ByteArray::Resize(int inSize)
{
   val_call2(gByteArrayResize->get(), mValue, alloc_int(inSize) );
}

int ByteArray::Size() const
{
   return val_int( val_call1(gByteArrayLen->get(), mValue ));
}


const unsigned char *ByteArray::Bytes() const
{
   #ifndef HXCPP_JS_PRIME
   value bytes = val_call1(gByteArrayBytes->get(),mValue);
   if (val_is_string(bytes))
      return (unsigned char *)val_string(bytes);
   #else
   value bytes = mValue;
   #endif

   buffer buf = val_to_buffer(bytes);
   if (buf==0)
   {
      val_throw(alloc_string("Bad ByteArray"));
   }
   return (unsigned char *)buffer_data(buf);
}


unsigned char *ByteArray::Bytes()
{
   #ifndef HXCPP_JS_PRIME
   value bytes = val_call1(gByteArrayBytes->get(),mValue);
   if (val_is_string(bytes))
      return (unsigned char *)val_string(bytes);
   #else
   value bytes = mValue;
   #endif
   buffer buf = val_to_buffer(bytes);
   if (buf==0)
   {
      val_throw(alloc_string("Bad ByteArray"));
   }
   return (unsigned char *)buffer_data(buf);
}


bool ByteArray::LittleEndian()
{
   value f = val_field(mValue,_id_bigEndian);
   #ifdef HXCPP_JS_PRIME
   if (!f.isUndefined())
   #else
   if (val_is_bool(f))
   #endif
   {
      return !val_bool(f);
   }
   int one = 0x0000001;
   return *(unsigned char *)&one == 1;
}


ByteArray::ByteArray(const char *inResourceName) : mValue(val_null)
{
   //printf("ByteArray from rsource factory %p %s\n", gResourceFactory, inResourceName);
   if (gResourceFactory)
   {
      mValue = val_call1(gResourceFactory->get(),alloc_string(inResourceName));
   }
}


// --------------------


// [ddc]
value nme_byte_array_overwrite_file(value inFilename, value inBytes)
{
   // file is created if it doesn't exist,
   // if it exists, it is truncated to zero
   FILE *file = OpenOverwrite(val_os_string(inFilename));
   if (!file)
   {
      #ifdef ANDROID
      // [todo]
      #endif
      return alloc_null();
   }

   ByteArray array(inBytes);

   // The function fwrite() writes nitems objects, each size bytes long, to the
   // stream pointed to by stream, obtaining them from the location given by
   // ptr.
   // fwrite(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream);
   fwrite( array.Bytes() , 1, array.Size() , file);

   fclose(file);
   return alloc_null();
}
DEFINE_PRIM(nme_byte_array_overwrite_file,2);

value nme_byte_array_read_file(value inFilename)
{
   ByteArray result = ByteArray::FromFile(val_os_string(inFilename));
   return result.mValue;
}
DEFINE_PRIM(nme_byte_array_read_file,1);


value nme_byte_array_get_native_pointer(value inByteArray)
{
   ByteArray bytes (inByteArray);
   if (!val_is_null (bytes.mValue))
   {
      return alloc_int((intptr_t)bytes.Bytes ());
   }
   return alloc_null();
}
DEFINE_PRIM(nme_byte_array_get_native_pointer,1);


struct ByteData
{
   uint8 *data;
   int   length;
};

bool FromValue(ByteData &outData,value inData)
{
   ByteArray array(inData);
   outData.data = array.Bytes();
   outData.length = array.Size();
   return true;
}

// --- WeakRef -----------------------------------------------------

#ifndef HXCPP_JS_PRIME

struct WeakRefInfo
{
   int64 mHolder;
   int64 mPtr;
};

static QuickVec<WeakRefInfo> sWeakRefs;
static QuickVec<int> sFreeRefIDs;

#define PTR_MANGLE 0x11010101

static void release_weak_ref(value inValue)
{
   int64 key = ((int64)(inValue)) ^ PTR_MANGLE;
   for(int i=0;i<sWeakRefs.size();i++)
   {
      if (sWeakRefs[i].mPtr==key)
         // Wait until controlling object access it again
         sWeakRefs[i].mPtr = 0;
   }
}

static void release_weak_ref_holder(value inValue)
{
   int64 key = ((int64)(inValue)) ^ PTR_MANGLE;
   for(int i=0;i<sWeakRefs.size();i++)
   {
      if (sWeakRefs[i].mHolder==key)
      {
         sWeakRefs[i].mHolder = 0;
         sWeakRefs[i].mPtr = 0;
         sFreeRefIDs.push_back(i);
         break;
      }
   }
}

value nme_weak_ref_create(value inHolder,value inRef)
{
   int id = 0;
   if (!sFreeRefIDs.empty())
      id = sFreeRefIDs.qpop();
   else
   {
      id = sWeakRefs.size();
      sWeakRefs.resize(id+1);
   }

   WeakRefInfo &info = sWeakRefs[id];
   info.mHolder = ((int64)(inHolder)) ^ PTR_MANGLE;
   info.mPtr = ((int64)(inRef)) ^ PTR_MANGLE;
   val_gc(inHolder,release_weak_ref_holder);
   val_gc(inRef,release_weak_ref);

   return alloc_int(id);
}
DEFINE_PRIM(nme_weak_ref_create,2);

value nme_weak_ref_get(value inValue)
{
   int id = val_int(inValue);
   if (sWeakRefs[id].mPtr==0)
   {
      sWeakRefs[id].mHolder = 0;
      sFreeRefIDs.push_back(id);
      return alloc_null();
   }
   return (value)( sWeakRefs[id].mPtr ^ PTR_MANGLE );
}
DEFINE_PRIM(nme_weak_ref_get,1);

#endif

value nme_get_unique_device_identifier()
{
#if defined(IPHONE)
  return alloc_string(GetUniqueDeviceIdentifier().c_str());
#else
  return alloc_null();
#endif
}
DEFINE_PRIM(nme_get_unique_device_identifier,0);

value nme_get_local_ip_address()
{
#if defined(IPHONE)
  return alloc_string(GetLocalIPAddress().c_str());
#else
  return alloc_null();
#endif
}
DEFINE_PRIM(nme_get_local_ip_address,0);




value nme_set_icon( value path ) {
   //printf( "setting icon\n" );
   #if defined( HX_WINDOWS ) || defined( HX_MACOS )
       SetIcon( val_string( path ) );
   #endif   
   return alloc_null();
}

DEFINE_PRIM(nme_set_icon,1);

// --- nme.system.Capabilities -----------------------------------------------------

value nme_sys_get_exe_name()
{
   return alloc_string( GetExeName().c_str() );
}

DEFINE_PRIM( nme_sys_get_exe_name, 0 );



value nme_capabilities_get_screen_resolutions ()
{
   //Only really makes sense on PC platforms
   #if defined( HX_WINDOWS ) || defined( HX_MACOS ) || defined( HX_LINUX )
      QuickVec<int>* res = CapabilitiesGetScreenResolutions();
      
      value result = alloc_array( res->size());
      for(int i=0;i<res->size();i++)
      {
          int outres = (*res)[ i ];
          val_array_set_i(result,i,alloc_int( outres ) );
      }
   
      return result;
   #endif
   return alloc_null();
}

DEFINE_PRIM( nme_capabilities_get_screen_resolutions, 0 );


value nme_capabilities_get_screen_modes () {


   //Only really makes sense on PC platforms
   #if defined( HX_WINDOWS ) || defined( HX_MACOS ) || defined( HX_LINUX )


      QuickVec<ScreenMode>* modes = CapabilitiesGetScreenModes();

      value result = alloc_array( modes->size() * 4 );

      for(int i=0;i<modes->size();i++) {
         ScreenMode mode = (*modes)[ i ];
         val_array_set_i(result,i * 4 + 0,alloc_int( mode.width ) );
         val_array_set_i(result,i * 4 + 1,alloc_int( mode.height ) );
         val_array_set_i(result,i * 4 + 2,alloc_int( mode.refreshRate ) );
         val_array_set_i(result,i * 4 + 3,alloc_int( (int)mode.format ) );
      }
    
      return result;
    
    #endif
  
    return alloc_null();
  
  
}

DEFINE_PRIM( nme_capabilities_get_screen_modes, 0 );


value nme_capabilities_get_pixel_aspect_ratio () {
   
   return alloc_float (CapabilitiesGetPixelAspectRatio ());
   
}
DEFINE_PRIM (nme_capabilities_get_pixel_aspect_ratio, 0);


value nme_capabilities_get_screen_dpi () {
   
   return alloc_float (CapabilitiesGetScreenDPI ());
   
}
DEFINE_PRIM (nme_capabilities_get_screen_dpi, 0);

value nme_capabilities_get_screen_resolution_x () {
   
   return alloc_float (CapabilitiesGetScreenResolutionX ());
   
}
DEFINE_PRIM (nme_capabilities_get_screen_resolution_x, 0);

value nme_capabilities_get_screen_resolution_y () {
   
   return alloc_float (CapabilitiesGetScreenResolutionY ());
   
}
DEFINE_PRIM (nme_capabilities_get_screen_resolution_y, 0);

value nme_capabilities_get_language() {
   
   return alloc_string(CapabilitiesGetLanguage().c_str());
   
}
DEFINE_PRIM (nme_capabilities_get_language, 0);

// ---  nme.desktop.Clipboard -----------------------------------------------------
#ifndef HXCPP_JS_PRIME
value nme_desktop_clipboard_set_clipboard_text(value inText) {
   return alloc_bool(SetClipboardText(val_string(inText)));
}
DEFINE_PRIM (nme_desktop_clipboard_set_clipboard_text, 1);

value nme_desktop_clipboard_has_clipboard_text() {
   return alloc_bool(HasClipboardText());
}
DEFINE_PRIM (nme_desktop_clipboard_has_clipboard_text, 0);

value nme_desktop_clipboard_get_clipboard_text() {
   return alloc_string(GetClipboardText());
}
DEFINE_PRIM (nme_desktop_clipboard_get_clipboard_text, 0);
#endif


// ---  nme.filesystem -------------------------------------------------------------
value nme_get_resource_path()
{
#if defined(IPHONE)
  return alloc_string(GetResourcePath().c_str());
#else
  return alloc_null();
#endif
}
DEFINE_PRIM(nme_get_resource_path,0);

value nme_filesystem_get_special_dir(value inWhich)
{
   static std::string dirs[DIR_SIZE];
   int idx = val_int(inWhich);

   if (dirs[idx]=="")
      GetSpecialDir((SpecialDir)idx,dirs[idx]);

   return alloc_string(dirs[idx].c_str());
}
DEFINE_PRIM(nme_filesystem_get_special_dir,1);

value nme_filesystem_get_volumes(value outVolumes, value inFactory)
{
   std::vector<VolumeInfo> volumes;
   nme::GetVolumeInfo(volumes);
   for(int v=0;v<volumes.size();v++)
   {
      VolumeInfo &info = volumes[v];
      value args = alloc_array(6);
      val_array_set_i(args,0,alloc_string(info.path.c_str()));
      val_array_set_i(args,1,alloc_string(info.name.c_str()));
      val_array_set_i(args,2,alloc_bool(info.writable));
      val_array_set_i(args,3,alloc_bool(info.removable));
      val_array_set_i(args,4,alloc_string(info.fileSystemType.c_str()));
      val_array_set_i(args,5,alloc_string(info.drive.c_str()));
      val_array_push(outVolumes, val_call1(inFactory,args) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_filesystem_get_volumes,2);



// --- getURL ----------------------------------------------------------------------
value nme_get_url(value url)
{
   bool result=LaunchBrowser(valToHxString(url).c_str());
   return alloc_bool(result);
}
DEFINE_PRIM(nme_get_url,1);


// --- Haptic Vibrate ---------------------------------------------------------------

value nme_haptic_vibrate(value inPeriod, value inDuration)
{
   #if defined(WEBOS) || defined(ANDROID)
   HapticVibrate (val_int(inPeriod), val_int(inDuration));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_haptic_vibrate,2);


// --- SharedObject ----------------------------------------------------------------------
value nme_set_user_preference(value inId,value inValue)
{
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN) //|| defined(HX_WINRT)
      bool result=SetUserPreference(valToHxString(inId).c_str(),valToHxString(inValue).c_str());
      return alloc_bool(result);
   #endif
   return alloc_bool(false);
}
DEFINE_PRIM(nme_set_user_preference,2);

value nme_get_user_preference(value inId)
{
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN) //|| defined(HX_WINRT)
      std::string result=GetUserPreference(valToHxString(inId).c_str());
      return alloc_string(result.c_str());
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_get_user_preference,1);

value nme_clear_user_preference(value inId)
{
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN) //|| defined(HX_WINRT)
      bool result=ClearUserPreference(valToHxString(inId).c_str());
      return alloc_bool(result);
   #endif
   return alloc_bool(false);
}
DEFINE_PRIM(nme_clear_user_preference,1);

// --- Stage ----------------------------------------------------------------------

value nme_stage_set_fixed_orientation(value inValue)
{
#if defined(IPHONE) || defined(TIZEN)
   gFixedOrientation = val_int(inValue);
#endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_fixed_orientation,1);


value nme_init_sdl_audio( )
{
   #if defined(NME_MIXER) && !defined(EMSCRIPTEN)
   if (gSDLAudioState==sdaNotInit)
      InitSDLAudio();
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_init_sdl_audio,0);

value nme_get_frame_stage(value inValue)
{
   Stage *stage;
   if (AbstractToObject(inValue,stage))
      return inValue;

   Frame *frame;
   if (!AbstractToObject(inValue,frame))
      return alloc_null();
   

   return ObjectToAbstract(frame->GetStage());
}
DEFINE_PRIM(nme_get_frame_stage,1);


AutoGCRoot *sOnCreateCallback = 0;

void OnMainFrameCreated(Frame *inFrame)
{
   SetMainThread();
   value frame = inFrame ? ObjectToAbstract(inFrame) : alloc_null();
   val_call1( sOnCreateCallback->get(),frame );
   delete sOnCreateCallback;
}


value nme_set_package(value inCompany,value inFile,value inPackage,value inVersion)
{
   gCompany = valToStdString(inCompany);
   gFile = valToStdString(inFile);
   gPackage = valToStdString(inPackage);
   gVersion = valToStdString(inVersion);
   return val_null;
}
DEFINE_PRIM(nme_set_package,4);


void nme_create_main_frame(value inCallback, int width, int height, int flags,
                                  HxString title, value inIcon )
{
   InitIDs();

   sOnCreateCallback = new AutoGCRoot(inCallback);

   Surface *icon=0;
   AbstractToObject(inIcon,icon);

   CreateMainFrame(OnMainFrameCreated, width, height, flags, title.c_str(), icon );
}
DEFINE_PRIME6v(nme_create_main_frame)

value nme_set_asset_base(value inBase)
{
   gAssetBase = valToStdString(inBase);
   return val_null;
}
DEFINE_PRIM(nme_set_asset_base,1);

value nme_terminate()
{
   exit(0);
   return alloc_null();
}
DEFINE_PRIM(nme_terminate,0);

value nme_close()
{
   StopAnimation();
   return alloc_null();
}
DEFINE_PRIM(nme_close,0);

value nme_start_animation()
{
   StartAnimation();
   return alloc_null();
}
DEFINE_PRIM(nme_start_animation,0);

value nme_pause_animation()
{
   PauseAnimation();
   return alloc_null();
}
DEFINE_PRIM(nme_pause_animation,0);

value nme_resume_animation()
{
   ResumeAnimation();
   return alloc_null();
}
DEFINE_PRIM(nme_resume_animation,0);

value nme_stop_animation()
{
   StopAnimation();
   return alloc_null();
}
DEFINE_PRIM(nme_stop_animation,0);

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

   value o = alloc_empty_object( );
   alloc_field(o,_id_type,alloc_int(ioEvent.type));
   alloc_field(o,_id_x,alloc_int(ioEvent.x));
   alloc_field(o,_id_y,alloc_int(ioEvent.y));
   alloc_field(o,_id_value,alloc_int(ioEvent.value));
   alloc_field(o,_id_id,alloc_int(ioEvent.id));
   alloc_field(o,_id_flags,alloc_int(ioEvent.flags));
   alloc_field(o,_id_code,alloc_int(ioEvent.code));
   alloc_field(o,_id_result,alloc_int(ioEvent.result));
   alloc_field(o,_id_scaleX,alloc_float(ioEvent.scaleX));
   alloc_field(o,_id_scaleY,alloc_float(ioEvent.scaleY));
   alloc_field(o,_id_deltaX,alloc_float(ioEvent.deltaX));
   alloc_field(o,_id_deltaY,alloc_float(ioEvent.deltaY));
   if (ioEvent.utf8Text && ioEvent.utf8Length)
      alloc_field(o,_id_text, alloc_string_len(ioEvent.utf8Text,ioEvent.utf8Length) );
   else
      alloc_field(o,_id_text,alloc_null());

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

Stage *sgNativeHandlerStage = 0;

void external_handler_native( nme::Event &ioEvent, void *inUserData )
{
   AutoGCRoot *handler = (AutoGCRoot *)inUserData;
   if (ioEvent.type == etDestroyHandler)
   {
      delete handler;
      return;
   }

   static AutoGCRoot *dynamicEvent = 0;
   static nme::Event eventData;
   static vkind eventKind;
   if (dynamicEvent==0)
   {
      kind_share(&eventKind,"nme::Event");
      value eventHolder = alloc_abstract(eventKind,&eventData);
      dynamicEvent = new AutoGCRoot(eventHolder);
   }

   eventData = ioEvent;
   eventData.pollTime = GetTimeStamp();

   val_call1(handler->get(), dynamicEvent->get());

   ioEvent.result = eventData.result;

   sgNativeHandlerStage->SetNextWakeDelay(eventData.pollTime);
}


value nme_set_stage_handler_native(value inStage,value inHandler,value inNomWidth, value inNomHeight)
{
   Stage *stage;
   if (!AbstractToObject(inStage,stage))
      return alloc_null();

   sgNativeHandlerStage = stage;

   AutoGCRoot *data = new AutoGCRoot(inHandler);

   stage->SetNominalSize(val_int(inNomWidth), val_int(inNomHeight) );
   stage->SetEventHandler(external_handler_native,data);

   return alloc_null();
}

DEFINE_PRIM(nme_set_stage_handler_native,4);


value nme_stage_begin_render(value inStage,value inClear)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
      stage->BeginRenderStage(val_bool(inClear));
   return alloc_null();
}
DEFINE_PRIM(nme_stage_begin_render,2);



value nme_render_stage(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      sgRenderingCount++;
      stage->RenderStage();
      sgRenderingCount--;
   }
   return alloc_null();
}

DEFINE_PRIM(nme_render_stage,1);



value nme_stage_end_render(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
      stage->EndRenderStage();
   return alloc_null();
}
DEFINE_PRIM(nme_stage_end_render,1);

value nme_stage_check_cache(value inStage)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
      return alloc_bool(stage->BuildCache());
   return alloc_null();
}
DEFINE_PRIM(nme_stage_check_cache,1);






value nme_set_render_gc_free(value inGcFree)
{
   gNmeRenderGcFree = val_bool(inGcFree);
   return alloc_null();
}

DEFINE_PRIM(nme_set_render_gc_free,1);


value nme_stage_resize_window(value inStage, value inWidth, value inHeight)
{
   #if (defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX))
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->ResizeWindow(val_int(inWidth), val_int(inHeight));
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_resize_window,3);


value nme_stage_set_resolution(value inStage, value inWidth, value inHeight)
{
   #if (defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX))
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->SetResolution(val_int(inWidth), val_int(inHeight));
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_resolution,3);


value nme_stage_set_screenmode(value inStage, value inWidth, value inHeight, value inRefresh, value inFormat)
{
   #if (defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX))
   Stage *stage;
   if (AbstractToObject(inStage,stage)){
      ScreenMode mode;
      mode.width = val_int(inWidth);
      mode.height = val_int(inHeight);
      mode.refreshRate = val_int(inRefresh);
      mode.format = (ScreenFormat)val_int(inFormat);
      stage->SetScreenMode(mode);
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_screenmode,5);


value nme_stage_set_fullscreen(value inStage, value inFull)
{
   #if (defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX))
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->setDisplayState(val_bool(inFull) ? sdsFullscreenInteractive : sdsNormal);
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_fullscreen,2);


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

value nme_stage_get_joystick_name(value inStage, value inId)
{
   #if (defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX))
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      const char *joystickName = stage->getJoystickName(val_int(inId));
      if (joystickName != NULL) return alloc_string(joystickName);
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_get_joystick_name,2);

DO_STAGE_PROP(focus_rect,FocusRect,alloc_bool,val_bool)
DO_STAGE_PROP(scale_mode,ScaleMode,alloc_int,val_int)
#ifdef NME_S3D
DO_STAGE_PROP(autos3d,AutoS3D,alloc_bool,val_bool)
#endif
DO_STAGE_PROP(align,Align,alloc_int,val_int)
DO_STAGE_PROP(quality,Quality,alloc_int,val_int)
DO_STAGE_PROP(display_state,DisplayState,alloc_int,val_int)
DO_STAGE_PROP(multitouch_active,MultitouchActive,alloc_bool,val_bool)
DO_PROP_READ(Stage,stage,stage_width,StageWidth,alloc_float);
DO_PROP_READ(Stage,stage,stage_height,StageHeight,alloc_float);
DO_PROP_READ(Stage,stage,dpi_scale,DPIScale,alloc_float);
DO_PROP_READ(Stage,stage,multitouch_supported,MultitouchSupported,alloc_bool);


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
 
namespace nme { void AndroidRequestRender(); }
value nme_stage_request_render()
{
   #ifdef ANDROID
   AndroidRequestRender();
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_stage_request_render,0);
 

value nme_stage_show_cursor(value inStage,value inShow)
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      stage->ShowCursor(val_bool(inShow));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_stage_show_cursor,2);

value nme_stage_constrain_cursor_to_window_frame(value inStage, value inLock)
{
    Stage *stage;
    if (AbstractToObject(inStage,stage)) {       
        bool lock = val_bool(inLock);
        stage->ConstrainCursorToWindowFrame( lock );
    }
    return alloc_null();
}
DEFINE_PRIM(nme_stage_constrain_cursor_to_window_frame,2);

value nme_stage_set_cursor_position_in_window( value inStage, value inX, value inY )
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      int x = val_int(inX);
      int y = val_int(inY);      
      stage->SetCursorPositionInWindow(x,y);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_cursor_position_in_window,3);


value nme_stage_get_window_x( value inStage )
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      return alloc_int(stage->GetWindowX());
   }
   return alloc_int(0);
}
DEFINE_PRIM(nme_stage_get_window_x,1);


value nme_stage_get_window_y( value inStage )
{
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      return alloc_int(stage->GetWindowY());
   }
   return alloc_int(0);
}
DEFINE_PRIM(nme_stage_get_window_y,1);




value nme_stage_set_window_position( value inStage, value inX, value inY ) {

    Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      int x = val_int(inX);
      int y = val_int(inY);      
      stage->SetStageWindowPosition(x,y);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_stage_set_window_position,3);


value nme_stage_get_orientation() {

   #if defined(IPHONE) || defined(ANDROID) || defined(BLACKBERRY)
      return alloc_int( GetDeviceOrientation() );
   
   #else
   
      return alloc_int( 0 );
      
   #endif
   
}

DEFINE_PRIM(nme_stage_get_orientation, 0);

value nme_stage_get_normal_orientation() {

   #if defined(ANDROID)
      return alloc_int( GetNormalOrientation() );
   #elif defined(IPHONE)
      return alloc_int( 1 ); // ios device sensors are always portrait orientated  
   #else
      return alloc_int( 0 );  
   #endif
}

DEFINE_PRIM(nme_stage_get_normal_orientation, 0);

// --- StageVideo ----------------------------------------------------------------------

StageVideo::StageVideo() : mOwner(val_null) { }
void StageVideo::setOwner(value inOwner) { mOwner.set(inOwner); }

value nme_sv_create(value inStage, value inOwner)
{
   #ifndef HXCPP_JS_PRIME
   Stage *stage;
   if (AbstractToObject(inStage,stage))
   {
      StageVideo *video = stage->createStageVideo(inOwner);
      if (video)
      {
         return ObjectToAbstract(video);
      }
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_sv_create, 2);

value nme_sv_destroy(value inVideo)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->destroy();
   return alloc_null();
}
DEFINE_PRIM(nme_sv_destroy, 1);

value nme_sv_action(value inVideo,value inAction)
{
   enum { actPause, actResume, actToggle };

   int action = val_int(inAction);
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
   {
      if (action==actPause)
         video->pause();
      else if (action==actResume)
         video->resume();
      else if (action==actToggle)
         video->togglePause();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sv_action, 2);


value nme_sv_play(value inVideo,value inUrl, value inStart, value inLength)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->play(valToHxString(inUrl).c_str(), val_number(inStart), val_number(inLength));
   return alloc_null();
}
DEFINE_PRIM(nme_sv_play, 4);

value nme_sv_seek(value inVideo,value inWhere)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->seek(val_number(inWhere));
   return alloc_null();
}
DEFINE_PRIM(nme_sv_seek, 2);


value nme_sv_get_time(value inVideo)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      return alloc_float( video->getTime() );
   return alloc_null();
}
DEFINE_PRIM(nme_sv_get_time, 1);


value nme_sv_viewport(value inVideo,value a0, value a1, value a2, value a3)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->setViewport(val_number(a0), val_number(a1), val_number(a2), val_number(a3) );
   return alloc_null();
}
DEFINE_PRIM(nme_sv_viewport, 5);


value nme_sv_pan(value inVideo,value a0, value a1)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->setPan(val_number(a0), val_number(a1));
   return alloc_null();
}
DEFINE_PRIM(nme_sv_pan, 3);


value nme_sv_zoom(value inVideo,value a0, value a1)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->setZoom(val_number(a0), val_number(a1));
   return alloc_null();
}
DEFINE_PRIM(nme_sv_zoom, 3);



value nme_sv_set_sound_transform(value inVideo,value a0, value a1)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      video->setSoundTransform(val_number(a0), val_number(a1));
   return alloc_null();
}
DEFINE_PRIM(nme_sv_set_sound_transform, 3);


value nme_sv_get_buffered_percent(value inVideo)
{
   StageVideo *video;
   if (AbstractToObject(inVideo,video))
      return alloc_float(video->getBufferedPercent());
   return alloc_float(0);
}
DEFINE_PRIM(nme_sv_get_buffered_percent, 1);





// --- ManagedStage ----------------------------------------------------------------------


value nme_managed_stage_create(value inW,value inH,value inFlags)
{
#ifdef HX_WINRT
   return alloc_null();
#else
   SetMainThread();
   ManagedStage *stage = new ManagedStage(val_int(inW),val_int(inH),val_int(inFlags));
   return ObjectToAbstract(stage);
#endif
}
DEFINE_PRIM(nme_managed_stage_create,3);


value nme_managed_stage_pump_event(value inStage,value inEvent)
{
#ifndef HX_WINRT
   ManagedStage *stage;
   if (AbstractToObject(inStage,stage))
   {
      Event event;
      FromValue(event,inEvent);
      stage->PumpEvent(event);
   }
#endif
   return alloc_null();
}
DEFINE_PRIM(nme_managed_stage_pump_event,2);






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

DEFINE_PRIME0(nme_create_display_object);

value nme_display_object_get_graphics(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return ObjectToAbstract( &obj->GetGraphics() );

   return alloc_null();
}

DEFINE_PRIME1(nme_display_object_get_graphics);

void nme_display_object_draw_to_surface(value aObject, value aSurface, value aMatrix,
                                        value aColourTransform, int aBlendMode, value aClipRect )
{
   DisplayObject *obj;
   Surface *surf;
   if (AbstractToObject(aObject,obj) && AbstractToObject(aSurface,surf))
   {
      Rect r(surf->Width(),surf->Height());
      if (!val_is_null(aClipRect))
         FromValue(r,aClipRect);
      AutoSurfaceRender render(surf,r);

      Matrix matrix;
      if (!val_is_null(aMatrix))
         FromValue(matrix,aMatrix);
      int aa = 4;
      Stage *stage = Stage::GetCurrent();
      if (stage)
      {
         switch(stage->getQuality())
         {
             case sqLow:    aa=1; break;
             case sqMedium: aa=2; break;
             case sqHigh:   aa=4; break;
             case sqBest:   aa=4; break;
         }
      }
      RenderState state(surf,aa);
      state.mTransform.mMatrix = &matrix;

      ColorTransform col_trans;
      if (!val_is_null(aColourTransform))
      {
         ColorTransform t;
         FromValue(t,aColourTransform);
         state.CombineColourTransform(state,&t,&col_trans);
      }

      // TODO: Blend mode
      state.mRoundSizeToPOW2 = false;
      state.mPhase = rpBitmap;

      // get current transformation
      Matrix objMatrix = obj->GetLocalMatrix();
      
      // untransform for draw (set matrix to identity)
      float m00 = objMatrix.m00;
      float m01 = objMatrix.m01;
      float m10 = objMatrix.m10;
      float m11 = objMatrix.m11;
      float mtx = objMatrix.mtx;
      float mty = objMatrix.mty;
      objMatrix.m00 = 1;
      objMatrix.m01 = 0;
      objMatrix.m10 = 0;
      objMatrix.m11 = 1;
      objMatrix.mtx = 0;
      objMatrix.mty = 0;
      obj->setMatrix(objMatrix);

      // save current alpha but set to baseline for draw
      float objAlpha = obj->getAlpha();
      obj->setAlpha(1);

      DisplayObjectContainer *dummy = new DisplayObjectContainer(true);
      dummy->hackAddChild(obj);
      dummy->Render(render.Target(), state);

      state.mPhase = rpRender;
      dummy->Render(render.Target(), state);
      dummy->hackRemoveChildren();
      dummy->DecRef();

      // restore original transformation now that surface has rendered
      objMatrix.m00 = m00;
      objMatrix.m01 = m01;
      objMatrix.m10 = m10;
      objMatrix.m11 = m11;
      objMatrix.mtx = mtx;
      objMatrix.mty = mty;
      obj->setMatrix(objMatrix);

      // restore alpha
      obj->setAlpha(objAlpha);
   }
}
DEFINE_PRIME6v(nme_display_object_draw_to_surface)


int nme_display_object_get_id(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return obj->id;

   return -1;
}

DEFINE_PRIME1(nme_display_object_get_id);

void nme_display_object_global_to_local(value inObj,value ioPoint)
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
}
DEFINE_PRIME2v(nme_display_object_global_to_local);


value nme_display_object_encode(value inObj, int inFlags)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      ObjectStreamOut *outStream = ObjectStreamOut::createEncoder(inFlags);
      outStream->addObject(obj);
      ByteArray array(outStream->data);
      delete outStream;
      return array.mValue;
   }
   return alloc_null();
}
DEFINE_PRIME2(nme_display_object_encode)



value nme_display_object_decode(value inArray, int inFlags)
{
   ByteArray array(inArray);

   ObjectStreamIn *inStream = ObjectStreamIn::createDecoder(array.Bytes(),array.Size(),inFlags);
   if (!(inFlags & 0x0001))
      inStream->newIds = true;

   DisplayObject *dobj=0;
   inStream->getObject(dobj,false);
   if (!dobj)
      return alloc_null();
   return ObjectToAbstract(dobj);

}
DEFINE_PRIME2(nme_display_object_decode)




value nme_type(value inObj)
{
   #ifndef HXCPP_JS_PRIME
   val_iter_fields(inObj, nme::print_field, 0);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_type,1);


void nme_display_object_local_to_global(value inObj,value ioPoint)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      UserPoint point( val_field_numeric(ioPoint, _id_x),
                     val_field_numeric(ioPoint, _id_y) );
      UserPoint trans = obj->LocalToGlobal(point);
      alloc_field(ioPoint, _id_x, alloc_float(trans.x) );
      alloc_field(ioPoint, _id_y, alloc_float(trans.y) );
   }
}
DEFINE_PRIME2v(nme_display_object_local_to_global);


bool nme_display_object_hit_test_point(
            value inObj, double inX, double inY, bool inShape, bool inRecurse)
{
   DisplayObject *obj;
   UserPoint pos(inX,inY);

   if (AbstractToObject(inObj,obj))
   {
      if (inShape)
      {
         Stage *stage = obj->getStage();
         if (stage)
         {
            return stage->HitTest( pos, obj, inRecurse );
         }
      }
      else
      {
         Matrix m = obj->GetFullMatrix(false);
         Transform trans;
         trans.mMatrix = &m;

         Extent2DF ext;
         obj->GetExtent(trans, ext, true, true );
         return ext.Contains(pos);
      }
   }
   return false;
}
DEFINE_PRIME5(nme_display_object_hit_test_point);


void nme_display_object_set_filters(value inObj,value inFilters)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      FilterList filters;
      if (!val_is_null(inFilters) && val_array_size(inFilters) )
      {
         int n = val_array_size(inFilters);
         for(int f=0;f<n;f++)
         {
            value filter = val_array_i(inFilters,f);
            Filter *fil = FilterFromValue(filter);
            if (fil)
               filters.push_back(fil);
        }
      }
      obj->setFilters(filters);
   }
}
DEFINE_PRIME2v(nme_display_object_set_filters);

void nme_display_object_set_scale9_grid(value inObj,value inRect)
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
}
DEFINE_PRIME2v(nme_display_object_set_scale9_grid);

void nme_display_object_set_scroll_rect(value inObj,value inRect)
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
}
DEFINE_PRIME2v(nme_display_object_set_scroll_rect);

void nme_display_object_set_mask(value inObj,value inMask)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      DisplayObject *mask = 0;
      AbstractToObject(inMask,mask);
      obj->setMask(mask);
   }
}
DEFINE_PRIME2v(nme_display_object_set_mask);


void nme_display_object_set_matrix(value inObj,value inMatrix)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
       Matrix m;
       FromValue(m,inMatrix);

       obj->setMatrix(m);
   }
}
DEFINE_PRIME2v(nme_display_object_set_matrix);

void nme_display_object_get_matrix(value inObj,value outMatrix, bool inFull)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Matrix m = inFull ? obj->GetFullMatrix(false) : obj->GetLocalMatrix();
      ToValue(outMatrix,m);
   }
}
DEFINE_PRIME3v(nme_display_object_get_matrix);

void nme_display_object_set_color_transform(value inObj,value inTrans)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
       ColorTransform trans;
       FromValue(trans,inTrans);

       obj->setColorTransform(trans);
   }
}
DEFINE_PRIME2v(nme_display_object_set_color_transform);

void nme_display_object_get_color_transform(value inObj,value outTrans, bool inFull)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      ColorTransform t = inFull ? obj->GetFullColorTransform() :
                                  obj->GetLocalColorTransform();
      ToValue(outTrans,t);
   }
}
DEFINE_PRIME3v(nme_display_object_get_color_transform);

void nme_display_object_get_pixel_bounds(value inObj,value outBounds)
{

}
DEFINE_PRIME2v(nme_display_object_get_pixel_bounds);

void nme_display_object_get_bounds(value inObj, value inTarget, value outBounds, bool inIncludeStroke)
{
   DisplayObject *obj;
   DisplayObject *target;
   if (AbstractToObject(inObj,obj) && AbstractToObject(inTarget,target))
   {
      Matrix reference = target->GetFullMatrix(false);
      Matrix ref_i = reference.Inverse();

      Matrix m = obj->GetFullMatrix(false);
      m = ref_i.Mult(m);

      Transform trans;
      trans.mMatrix = &m;

      Extent2DF ext;
      obj->GetExtent(trans, ext, false, inIncludeStroke);
      
      Rect rect;
      if (ext.GetRect(rect))
         ToValue(outBounds,rect);
   }
}
DEFINE_PRIME4v(nme_display_object_get_bounds);


bool nme_display_object_request_soft_keyboard(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Stage *stage = obj->getStage();
      if (stage)
      {
         // TODO: return whether it pops up
         stage->PopupKeyboard(pkmDumb);
         return true;
      }
   }
   return false;
}
DEFINE_PRIME1v(nme_display_object_request_soft_keyboard);


bool nme_display_object_dismiss_soft_keyboard(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
   {
      Stage *stage = obj->getStage();
      if (stage)
      {
         // TODO: return whether it pops up
         stage->PopupKeyboard(pkmOff);
         return true;
      }
   }
   return false;
}
DEFINE_PRIME1(nme_display_object_dismiss_soft_keyboard);


DO_DISPLAY_PROP_PRIME(x,X,double,double)
DO_DISPLAY_PROP_PRIME(y,Y,double,double)
#ifdef NME_S3D
DO_DISPLAY_PROP_PRIME(z,Z,double,double)
#endif
DO_DISPLAY_PROP_PRIME(scale_x,ScaleX,double,double)
DO_DISPLAY_PROP_PRIME(scale_y,ScaleY,double,double)
DO_DISPLAY_PROP_PRIME(rotation,Rotation,double,double)
DO_DISPLAY_PROP_PRIME(width,Width,double,double)
DO_DISPLAY_PROP_PRIME(height,Height,double,double)
DO_DISPLAY_PROP_PRIME(alpha,Alpha,double,double)
DO_DISPLAY_PROP_PRIME(bg,OpaqueBackground,int,int)
DO_DISPLAY_PROP_PRIME(mouse_enabled,MouseEnabled,bool,bool)
DO_DISPLAY_PROP_PRIME(cache_as_bitmap,CacheAsBitmap,bool,bool)
DO_DISPLAY_PROP_PRIME(pedantic_bitmap_caching,PedanticBitmapCaching,bool,bool)
DO_DISPLAY_PROP_PRIME(pixel_snapping,PixelSnapping,int,int)
DO_DISPLAY_PROP_PRIME(visible,Visible,bool,bool)
#if 1
DO_DISPLAY_PROP(name,Name,alloc_wstring,valToStdWString)
#else
HxString nme_display_object_get_name(value inObj)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      return HxString(obj->getName());
   return HxString("");
}
DEFINE_PRIME1(nme_display_object_get_name)
void nme_display_object_set_name(value inObj,HxString inVal)
{
   DisplayObject *obj;
   if (AbstractToObject(inObj,obj))
      obj->setName(inVal);
}
DEFINE_PRIME2v(nme_display_object_set_name)
#endif
DO_DISPLAY_PROP_PRIME(blend_mode,BlendMode,int,int)
DO_DISPLAY_PROP_PRIME(needs_soft_keyboard,NeedsSoftKeyboard,bool,bool)
DO_DISPLAY_PROP_PRIME(soft_keyboard,SoftKeyboard,int,int)
DO_DISPLAY_PROP_PRIME(moves_for_soft_keyboard,MovesForSoftKeyboard,bool,bool)
DO_DISPLAY_PROP_PRIME(hit_enabled,HitEnabled,bool,bool)
DO_PROP_READ_PRIME(DisplayObject,display_object,mouse_x,MouseX,double)
DO_PROP_READ_PRIME(DisplayObject,display_object,mouse_y,MouseY,double)

// --- DirectRenderer -----------------------------------------------------

void onDirectRender(void *inHandle,const Rect &inRect, const Transform &inTransform)
{
   if (inHandle)
   {
      AutoGCRoot *root = (AutoGCRoot *)inHandle;
      value rect = alloc_empty_object();
      ToValue(rect,inRect);
      val_call1(root->get(),rect);
   }
}

value nme_direct_renderer_create()
{
   return ObjectToAbstract( new DirectRenderer(onDirectRender) );
}
DEFINE_PRIM(nme_direct_renderer_create,0);

value nme_direct_renderer_set(value inRenderer, value inCallback)
{
   DirectRenderer *renderer = 0;

   if (AbstractToObject(inRenderer,renderer))
   {
      if (val_is_null(inCallback))
      {
         if (renderer->renderHandle)
         {
            AutoGCRoot *root = (AutoGCRoot *)renderer->renderHandle;
            delete root;
            renderer->renderHandle = 0;
         }
      }
      else
      {
         if (renderer->renderHandle)
         {
            AutoGCRoot *root = (AutoGCRoot *)renderer->renderHandle;
            root->set(inCallback);
         }
         else
         {
            renderer->renderHandle = new AutoGCRoot(inCallback);
         }
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_direct_renderer_set,2);

// --- SimpleButton -----------------------------------------------------

value nme_simple_button_create()
{
   return ObjectToAbstract( new SimpleButton() );
}
DEFINE_PRIM(nme_simple_button_create,0);

value nme_simple_button_set_state(value inButton, value inState, value inObject)
{
   SimpleButton *button = 0;

   if (AbstractToObject(inButton,button))
   {
      DisplayObject *object = 0;
      AbstractToObject(inObject,object);
      button->setState(val_int(inState), object);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_simple_button_set_state,3);




DO_PROP(SimpleButton,simple_button,enabled,Enabled,alloc_bool,val_bool) 
DO_PROP(SimpleButton,simple_button,hand_cursor,UseHandCursor,alloc_bool,val_bool) 

// --- DisplayObjectContainer -----------------------------------------------------

value nme_create_display_object_container()
{
   return ObjectToAbstract( new DisplayObjectContainer() );
}

DEFINE_PRIM(nme_create_display_object_container,0);

void nme_doc_add_child(value inParent, value inChild)
{
   DisplayObjectContainer *parent;
   DisplayObject *child;
   if (AbstractToObject(inParent,parent) && AbstractToObject(inChild,child))
   {
      CHECK_ACCESS("nme_doc_add_child");
      parent->addChild(child);
   }
}
DEFINE_PRIME2v(nme_doc_add_child);


value nme_doc_swap_children(value inParent, value inChild0, value inChild1)
{
   DisplayObjectContainer *parent;
   if (AbstractToObject(inParent,parent))
   {
      CHECK_ACCESS("nme_doc_swap_children");
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
      CHECK_ACCESS("nme_doc_remove_child");
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
      CHECK_ACCESS("nme_doc_set_child_index");
      parent->setChildIndex(child,val_int(inPos));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_doc_set_child_index,3);


DO_PROP(DisplayObjectContainer,doc,mouse_children,MouseChildren,alloc_bool,val_bool);


// --- ExternalInterface -----------------------------------------------------

AutoGCRoot *sExternalInterfaceHandler = 0;

value nme_external_interface_add_callback (value inFunctionName, value inClosure)
{
   #ifdef WEBOS
      if (sExternalInterfaceHandler == 0) {
         AutoGCRoot *sExternalInterfaceHandler = new AutoGCRoot (inClosure);
      }
      ExternalInterface_AddCallback (val_string (inFunctionName), sExternalInterfaceHandler);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_external_interface_add_callback,2);

value nme_external_interface_available ()
{
   #ifdef WEBOS
      return alloc_bool(true);
   #else
      return alloc_bool(false);
   #endif
}
DEFINE_PRIM(nme_external_interface_available,0);

value nme_external_interface_call (value inFunctionName, value args)
{
   #ifdef WEBOS
      int n = val_array_size(args);
      const char *params[n];
      for (int i = 0; i < n; i++) {
         params[i] = val_string (val_array_i(args, i));
      }
      ExternalInterface_Call (val_string (inFunctionName), params, n);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_external_interface_call,2);

value nme_external_interface_register_callbacks ()
{
   #ifdef WEBOS
      ExternalInterface_RegisterCallbacks ();
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_external_interface_register_callbacks,0);


// --- Graphics -----------------------------------------------------

value nme_gfx_clear(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_clear");
      gfx->clear();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_clear,1);

value nme_gfx_close(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_close");
      gfx->close();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_close,1);



value nme_gfx_begin_fill(value inGfx,value inColour, value inAlpha)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_begin_fill");
      gfx->beginFill( val_int(inColour), val_number(inAlpha) );
   }
   return alloc_null();
}

DEFINE_PRIM(nme_gfx_begin_fill,3);


void nme_gfx_begin_set_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth, bool inForSolid)
{
   Graphics *gfx;
   Surface  *surface;
   if (AbstractToObject(inGfx,gfx) && AbstractToObject(inBMP,surface) )
   {
      Matrix matrix;
      FromValue(matrix,inMatrix);
      CHECK_ACCESS("nme_gfx_begin_set_bitmap_fill");

      GraphicsBitmapFill *fill = new GraphicsBitmapFill(surface,matrix,val_bool(inRepeat), val_bool(inSmooth));
      fill->setIsSolidStyle(inForSolid);
      fill->IncRef();
      gfx->drawGraphicsDatum(fill);
      fill->DecRef();
   }
}

value nme_gfx_begin_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth)
{
   CHECK_ACCESS("nme_gfx_begin_bitmap_fill");
   nme_gfx_begin_set_bitmap_fill(inGfx,inBMP,inMatrix,inRepeat,inSmooth,true);
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_begin_bitmap_fill,5);

value nme_gfx_line_bitmap_fill(value inGfx,value inBMP, value inMatrix,
     value inRepeat, value inSmooth)
{
   nme_gfx_begin_set_bitmap_fill(inGfx,inBMP,inMatrix,inRepeat,inSmooth,false);
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_line_bitmap_fill,5);



void nme_gfx_begin_set_gradient_fill(
      value aGfx,  int aType, value aColors, value aAlphas, value aRatios, value aMatrix,
        int aSpreadMethod, int aInterpMethod, double aFocal, bool inForSolid)
{
   Graphics *gfx;
   if (AbstractToObject(aGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_begin_set_gradient_fill");
      Matrix matrix;
      FromValue(matrix,aMatrix);
      GraphicsGradientFill *grad = new GraphicsGradientFill(aType, 
         matrix,
         (SpreadMethod)aSpreadMethod,
         (InterpolationMethod)aInterpMethod,
         aFocal);
      int n = std::min( val_array_size(aColors),
           std::min(val_array_size(aAlphas), val_array_size(aRatios) ) );
      for(int i=0;i<n;i++)
         grad->AddStop( val_int( val_array_i( aColors, i ) ),
                        val_number( val_array_i( aAlphas, i ) ),
                        val_number( val_array_i( aRatios, i ) )/255.0 );

      grad->setIsSolidStyle(inForSolid);
      grad->IncRef();
      gfx->drawGraphicsDatum(grad);
      grad->DecRef();
   }
}
DEFINE_PRIME10v(nme_gfx_begin_set_gradient_fill)


value nme_gfx_end_fill(value inGfx)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
      gfx->endFill();
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_end_fill,1);


void nme_gfx_line_style(value argGfx, value argThickness, int argColour, double argAlpha,
                        bool argPixelHinting, int argScaleMode,
                        int argCapsStyle, int argJointStyle, double argMiterLimit )
{
   Graphics *gfx;
   if (AbstractToObject(argGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_line_style");
      double thickness = -1;
      if (!val_is_null(argThickness))
      {
         thickness = val_number(argThickness);
         if (thickness<0)
            thickness = 0;
      }
      gfx->lineStyle(thickness, argColour, argAlpha,
                 argPixelHinting,
                 (StrokeScaleMode)argScaleMode,
                 (StrokeCaps)argCapsStyle,
                 (StrokeJoints)argJointStyle,
                 argMiterLimit);
   }
}
DEFINE_PRIME9v(nme_gfx_line_style)





value nme_gfx_move_to(value inGfx,value inX, value inY)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_move_to");
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
      CHECK_ACCESS("nme_gfx_line_to");
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
      CHECK_ACCESS("nme_gfx_curve_to");
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
      CHECK_ACCESS("nme_gfx_arc_to");
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
      CHECK_ACCESS("nme_gfx_draw_ellipse");
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
      CHECK_ACCESS("nme_gfx_draw_rect");
      gfx->drawRect( val_number(inX), val_number(inY), val_number(inWidth), val_number(inHeight) );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_rect,5);

value nme_gfx_draw_path(value inGfx, value inCommands, value inData, value inWinding)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_draw_path");
      QuickVec<uint8> commands;
      QuickVec<float> data;
      
      FillArrayInt(commands, inCommands);
      FillArrayDouble(data, inData);
      
      if (!val_bool(inWinding))
         gfx->drawPath(commands, data, wrNonZero);
      else
         gfx->drawPath(commands, data, wrOddEven);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gfx_draw_path, 4);

void nme_gfx_draw_round_rect(value aGfx,double aX,double aY,double aW,double aH,double aRx,double aRy )
{
   Graphics *gfx;
   if (AbstractToObject(aGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_draw_round_rect");
      gfx->drawRoundRect( aX, aY, aW, aH, aRx, aRy );
   }
}
DEFINE_PRIME7v(nme_gfx_draw_round_rect);

void nme_gfx_draw_triangles(value aGfx,value aVertices,value aIndices,value aUVData, int aCull, value aColours, int aBlend )
{
   Graphics *gfx;
   if (AbstractToObject(aGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_draw_triangles");
      QuickVec<float> vertices;
      QuickVec<int> indices;
      QuickVec<float> uvt;
      QuickVec<int> colours;

      FillArrayDouble(vertices,aVertices);
      FillArrayInt(indices,aIndices);
      FillArrayDouble(uvt,aUVData);
      FillArrayInt(colours,aColours);

      gfx->drawTriangles(vertices, indices, uvt, aCull, colours, aBlend);
   }
}
DEFINE_PRIME7v(nme_gfx_draw_triangles);


value nme_gfx_draw_data(value inGfx,value inData)
{
   Graphics *gfx;
   if (AbstractToObject(inGfx,gfx))
   {
      CHECK_ACCESS("nme_gfx_draw_data");
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


enum
{
  TILE_SCALE    = 0x0001,
  TILE_ROTATION = 0x0002,
  TILE_RGB      = 0x0004,
  TILE_ALPHA    = 0x0008,
  TILE_TRANS_2x2= 0x0010,
  TILE_RECT     = 0x0020,
  TILE_ORIGIN   = 0x0040,
  TILE_NO_ID    = 0x0080,
  TILE_SMOOTH   = 0x1000,

  TILE_BLEND_ADD   = 0x10000,
  TILE_BLEND_MULTIPLY   = 0x20000,
  TILE_BLEND_SCREEN   = 0x40000,
  TILE_BLEND_MASK  = 0xf0000,


  TILE_RECT_TILE          = 0,
  TILE_RECT_GIVEN         = 1,
  TILE_RECT_ORIGIN_GIVEN  = 2,
  TILE_RECT_FULL          = 3,
  TILE_RECT_FULL_NO_ID    = 4,
  TILE_RECT_ID_0          = 5,
};




inline float TToFloat( float *f, int inIdx ) { return f[inIdx]; }
inline double TToFloat( double *f, int inIdx ) { return f[inIdx]; }
#ifndef HXCPP_JS_PRIME
inline double TToFloat( value *v, int inIdx ) { return val_number(v[inIdx]); }
#else
inline double TToFloat( const value &v, int inIdx ) {
   value val = v[inIdx];
   return val.isUndefined() ? 0.0 : val.as<double>();
}
#endif

template<typename FLOATS,int RECTMODE, int TRANS, int COL>
void TAddTilesCol( GraphicsPath *inPath, Tilesheet *inSheet, int inN, FLOATS inValues)
{
   int max = inSheet->Tiles();
   float rgba_buf[] = { 1, 1, 1, 1 };
   float trans_2x2_buf[] = { 1, 0, 0, 1 };

   float *rgba = COL ? rgba_buf : 0;
   float *trans_2x2 = TRANS ? trans_2x2_buf : 0;
   float ox = 0.0f;
   float oy = 0.0f;
   int badIdSkip = 0;
   if (RECTMODE==TILE_RECT_TILE)
   {
      if (TRANS & TILE_TRANS_2x2)
         badIdSkip += 4;
      if (TRANS & TILE_ROTATION)
         badIdSkip++;
      if (TRANS & TILE_SCALE)
         badIdSkip++;
      if (COL & TILE_RGB)
         badIdSkip+=3;
      if (COL & TILE_ALPHA)
         badIdSkip++;
   }


   FRect rectBuf(_tile_rect);
   const FRect *r = &rectBuf;

   inPath->reserveTiles(inN, RECTMODE==TILE_RECT_FULL || RECTMODE==TILE_RECT_FULL_NO_ID, TRANS!=0, COL!=0);

   int v = 0;
   for(int i=0;i<inN;i++)
   {
      float x = TToFloat(inValues,v++);
      float y = TToFloat(inValues,v++);

      if (RECTMODE==TILE_RECT_GIVEN || RECTMODE==TILE_RECT_ORIGIN_GIVEN)
      {
         rectBuf.x = TToFloat(inValues,v++);
         rectBuf.y = TToFloat(inValues,v++);
         rectBuf.w = TToFloat(inValues,v++);
         rectBuf.h = TToFloat(inValues,v++);

         if (RECTMODE==TILE_RECT_ORIGIN_GIVEN)
         {
            ox = TToFloat(inValues,v++);
            oy = TToFloat(inValues,v++);
         }
      }
      else if (RECTMODE==TILE_RECT_FULL_NO_ID)
      {
          // Ok!
      }
      else if (RECTMODE==TILE_RECT_FULL)
      {
         // Skip id
         v++;
      }
      else
      {
         int id;

         if (RECTMODE==TILE_RECT_ID_0)
            id = 0;
         else
         {
            id = TToFloat(inValues,v++);
            if (id<0 || id>=max)
            {
               v+=badIdSkip;
               continue;
            }
         }

         const Tile &tile =  inSheet->GetTile(id);
         ox = tile.mOx;
         oy = tile.mOy;
         r = &tile.mFRect;
      }

      if (TRANS & TILE_TRANS_2x2)
      {
         trans_2x2[0] = TToFloat(inValues,v++);
         trans_2x2[1] = TToFloat(inValues,v++);
         trans_2x2[2] = TToFloat(inValues,v++);
         trans_2x2[3] = TToFloat(inValues,v++);
      }
      else if (TRANS)
      {
         if (TRANS & TILE_SCALE)
         {
            double scale = TToFloat(inValues,v++);

            if (TRANS & TILE_ROTATION)
            {
               double theta = TToFloat(inValues,v++);
               trans_2x2[0] = scale*cos(theta);
               trans_2x2[1] = scale*sin(theta);
            }
            else
            {
               trans_2x2[0] = scale;
            }
         }
         else if (TRANS & TILE_ROTATION)
         {
            double theta = TToFloat(inValues,v++);
            trans_2x2[0] = cos(theta);
            trans_2x2[1] = sin(theta);
         }

         trans_2x2[2] = -trans_2x2[1];
         trans_2x2[3] = trans_2x2[0];
      }

      if (RECTMODE!=TILE_RECT_FULL && RECTMODE!=TILE_RECT_FULL_NO_ID)
      {
         if (TRANS)
         {
            x-= ox*trans_2x2[0] + oy*trans_2x2[2];
            y-= ox*trans_2x2[1] + oy*trans_2x2[3];
         }
         else
         {
            x-=ox;
            y-=oy;
         }
      }

      if (COL & TILE_RGB)
      {
         rgba[0] = TToFloat(inValues,v++);
         rgba[1] = TToFloat(inValues,v++);
         rgba[2] = TToFloat(inValues,v++);
      }

      if (COL & TILE_ALPHA)
         rgba[3] = TToFloat(inValues,v++);

      if (RECTMODE==TILE_RECT_FULL || RECTMODE==TILE_RECT_FULL_NO_ID)
      {
         if (TRANS)
         {
            if (COL)
               inPath->qimage(x,y,trans_2x2,rgba);
            else
               inPath->qimage(x,y,trans_2x2,0);
         }
         else if (COL)
            inPath->qimage(x,y,0,rgba);
         else
            inPath->qimage(x,y,0,0);
      }
      else
      {
         if (TRANS)
         {
            if (COL)
               inPath->qtile(x,y,r,trans_2x2,rgba);
            else
               inPath->qtile(x,y,r,trans_2x2,0);
         }
         else if (COL)
            inPath->qtile(x,y,r,0,rgba);
         else
            inPath->qtile(x,y,r,0,0);
      }
   }
   /*
   if (!inPath->commands.verify() || !inPath->data.verify())
      printf("Something has gone horribly wrong\n");
   */
}


template<typename FLOATS,int RECTMODE, int TRANS>
void TAddTilesTrans( GraphicsPath *inPath, Tilesheet *inSheet, int inN, FLOATS &inValues, unsigned int inFlags)
{
   if (inFlags & TILE_RGB)
   {
      if (inFlags & TILE_ALPHA)
         TAddTilesCol<FLOATS, RECTMODE, TRANS, TILE_RGB|TILE_ALPHA>( inPath, inSheet, inN, inValues);
      else
         TAddTilesCol<FLOATS, RECTMODE, TRANS, TILE_RGB>( inPath, inSheet, inN, inValues);
   }
   else if (inFlags & TILE_ALPHA)
      TAddTilesCol<FLOATS, RECTMODE, TRANS, TILE_ALPHA>( inPath, inSheet, inN, inValues);
   else
      TAddTilesCol<FLOATS, RECTMODE, TRANS, 0>( inPath, inSheet, inN, inValues);
}

template<typename FLOATS,int RECTMODE>
void TAddTilesRect( GraphicsPath *inPath, Tilesheet *inSheet, int inN, FLOATS &inValues, unsigned int inFlags)
{
   if ( inFlags & TILE_TRANS_2x2 )
      TAddTilesTrans<FLOATS,RECTMODE, TILE_TRANS_2x2>( inPath, inSheet, inN, inValues, inFlags);
   else if (inFlags & TILE_SCALE)
   {
       if (inFlags & TILE_ROTATION)
          TAddTilesTrans<FLOATS,RECTMODE, TILE_SCALE | TILE_ROTATION>( inPath, inSheet, inN, inValues, inFlags);
       else
          TAddTilesTrans<FLOATS,RECTMODE, TILE_SCALE>( inPath, inSheet, inN, inValues, inFlags);
   }
   else if (inFlags & TILE_ROTATION)
      TAddTilesTrans<FLOATS,RECTMODE, TILE_ROTATION>( inPath, inSheet, inN, inValues, inFlags);
   else
      TAddTilesTrans<FLOATS,RECTMODE, 0>( inPath, inSheet, inN, inValues, inFlags);
}

template<typename FLOATS>
void TAddTiles( GraphicsPath *inPath, Tilesheet *inSheet, int inN, FLOATS &inValues, unsigned int inFlags, bool inFullImage)
{
   if (inFullImage)
   {
      if (inFlags & TILE_NO_ID)
         TAddTilesRect<FLOATS, TILE_RECT_FULL_NO_ID>( inPath, inSheet, inN, inValues, inFlags );
      else
         TAddTilesRect<FLOATS, TILE_RECT_FULL>( inPath, inSheet, inN, inValues, inFlags );
   }
   else if (inFlags & TILE_NO_ID)
   {
      TAddTilesRect<FLOATS, TILE_RECT_ID_0>( inPath, inSheet, inN, inValues, inFlags );
   }
   else if (inFlags & TILE_RECT)
   {
      if (inFlags & TILE_ORIGIN)
         TAddTilesRect<FLOATS, TILE_RECT_ORIGIN_GIVEN>( inPath, inSheet, inN, inValues, inFlags );
      else
         TAddTilesRect<FLOATS, TILE_RECT_GIVEN>( inPath, inSheet, inN, inValues, inFlags );
   }
   else
      TAddTilesRect<FLOATS, TILE_RECT_TILE >( inPath, inSheet, inN, inValues, inFlags );
}



value nme_gfx_draw_tiles(value inGfx,value inSheet, value inXYIDs,value inFlags,value inDataSize)
{
   Graphics *gfx;
   Tilesheet *sheet;
   if (AbstractToObject(inGfx,gfx) && AbstractToObject(inSheet,sheet))
   {
      CHECK_ACCESS("nme_gfx_draw_tiles");
      int  flags = val_int(inFlags);
      BlendMode blend = bmNormal;
      switch(flags & TILE_BLEND_MASK)
      {
         case TILE_BLEND_ADD:
            blend = bmAdd;
            break;
         case TILE_BLEND_MULTIPLY:
            blend = bmMultiply;
            break;
         case TILE_BLEND_SCREEN:
            blend = bmScreen;
            break;
      }

      bool smooth = flags & TILE_SMOOTH;

      bool useRect = flags & TILE_RECT;
      bool useOrigin = flags & TILE_ORIGIN;
      bool noId = flags & TILE_NO_ID;
      bool fullImage = !useOrigin && !useRect && sheet->IsSingleTileImage();


      int components = noId ? 2 : 3;
      if (useRect)
         components = useOrigin ? 8 : 6;

      if (flags & TILE_TRANS_2x2)
         components+=4;
      else
      {
         if (flags & TILE_SCALE)
            components++;
         if (flags & TILE_ROTATION)
            components++;
      }
      if (flags & TILE_RGB)
         components+=3;
      if (flags & TILE_ALPHA)
         components++;

      int n = val_is_null(inDataSize) ? -1 : val_int(inDataSize);
      buffer buf = 0;
      if (n < 0)
      {
         buf = val_to_buffer(inXYIDs);
         if (buf)
         {
            n = buffer_size(buf)/sizeof(float);
         }
         else
            n = val_array_size(inXYIDs);
      }
      n /= components;

      if (n)
      {
         int tileFlags = pcTile;
         if (fullImage)
            tileFlags |= pcTile_Full_Image_Bit;
         if (flags & (TILE_SCALE | TILE_ROTATION | TILE_TRANS_2x2 ) )
            tileFlags |= pcTile_Trans_Bit;
         if (flags & (TILE_RGB | TILE_ALPHA) )
            tileFlags |= pcTile_Col_Bit;

         gfx->beginTiles(&sheet->GetSurface(), smooth, blend, tileFlags, n);

         double *vals = val_array_double(inXYIDs);
         if (vals)
            TAddTiles( gfx->getPath(), sheet, n, vals, flags, fullImage );
         else
         {
            float *fvals = val_array_float(inXYIDs);
            if (!fvals)
            {
               if (!buf)
                  buf = val_to_buffer(inXYIDs);
               if (buf)
                  fvals = (float *)buffer_data(buf);
            }
            #ifndef EMSCRIPTEN
            if (!fvals && val_is_string(inXYIDs))
               fvals = (float *)val_string(inXYIDs);
            #endif
            if (fvals)
               TAddTiles( gfx->getPath(), sheet, n, fvals, flags, fullImage );
            else
            {
               values_array val_ptr = val_array_value(inXYIDs);
               if (value_array_ok(val_ptr))
                  TAddTiles( gfx->getPath(), sheet, n, val_ptr, flags, fullImage );
            }
         }
      }
   }

   return alloc_null();
}

DEFINE_PRIM(nme_gfx_draw_tiles,5);

static bool sNekoLutInit = false;
static int sNekoLut[256];

value nme_gfx_draw_points(value *arg, int nargs)
{
   enum { aGfx, aXYs, aRGBAs, aDefaultRGBA, aIs31Bits, aPointSize, aSIZE };

   Graphics *gfx;
   if (AbstractToObject(arg[aGfx],gfx))
   {
      QuickVec<float> xys;
      FillArrayDouble(xys,arg[aXYs]);

      QuickVec<int> RGBAs;
      FillArrayInt(RGBAs,arg[aRGBAs]);

      int def_rgba = val_int(arg[aDefaultRGBA]);

      if (val_bool(arg[aIs31Bits]))
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

      gfx->drawPoints(xys,RGBAs,def_rgba, val_number(arg[aPointSize]));
   }
   return alloc_null();
}
DEFINE_PRIM_MULT(nme_gfx_draw_points);




// --- IGraphicsData -----------------------------------------------------



value nme_graphics_path_create(value inCommands,value inData,value inWinding)
{
   GraphicsPath *result = new GraphicsPath();
   printf("nme_graphics_path_create!\n");

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
DEFINE_PRIM(nme_graphics_end_fill_create,0)


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
{
   return alloc_wstring_len(inStr.c_str(),inStr.length());
}


void FromValue(Optional<int> &outVal,value inVal) { outVal = (int)val_number(inVal); }
void FromValue(Optional<uint32> &outVal,value inVal) { outVal = (uint32)val_number(inVal); }
void FromValue(Optional<bool> &outVal,value inVal) { outVal = val_bool(inVal); }
void FromValue(Optional<WString> &outVal,value inVal)
{
   outVal = valToStdWString(inVal);
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
   WString name = valToStdWString(inVal);
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


#define GTF(attrib,ifSet) \
{ \
   if (!ifSet || inFormat.attrib.IsSet()) alloc_field(outValue, _id_##attrib, ToValue( inFormat.attrib.Get() ) ); \
}


void GetTextFormat(const TextFormat &inFormat, value &outValue, bool inIfSet = false)
{
   GTF(align,inIfSet);
   GTF(blockIndent,inIfSet);
   GTF(bold,inIfSet);
   GTF(bullet,inIfSet);
   GTF(color,inIfSet);
   GTF(font,inIfSet);
   GTF(indent,inIfSet);
   GTF(italic,inIfSet);
   GTF(kerning,inIfSet);
   GTF(leading,inIfSet);
   GTF(leftMargin,inIfSet);
   GTF(letterSpacing,inIfSet);
   GTF(rightMargin,inIfSet);
   GTF(size,inIfSet);
   GTF(tabStops,inIfSet);
   GTF(target,inIfSet);
   GTF(underline,inIfSet);
   GTF(url,inIfSet);
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

value nme_text_field_get_text_format(value inText,value outFormat,value inStart,value inEnd)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      TextFormat *fmt = text->getTextFormat(val_int(inStart),val_int(inEnd));
      GetTextFormat(*fmt,outFormat,true);
   }
   return alloc_null();
}

DEFINE_PRIM(nme_text_field_get_text_format,4)


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


void GetTextLineMetrics(const TextLineMetrics &inMetrics, value &outValue)
{
   alloc_field(outValue,_id_x, alloc_float(inMetrics.x));
   alloc_field(outValue,_id_width, alloc_float(inMetrics.width));
   alloc_field(outValue,_id_height, alloc_float(inMetrics.height));
   alloc_field(outValue,_id_ascent, alloc_float(inMetrics.ascent));
   alloc_field(outValue,_id_descent, alloc_float(inMetrics.descent));
   alloc_field(outValue,_id_leading, alloc_float(inMetrics.leading));
}

value nme_text_field_get_line_metrics(value inText,value inIndex,value outMetrics)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      const TextLineMetrics *mts = text->getLineMetrics(val_int(inIndex));
      GetTextLineMetrics(*mts, outMetrics);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_text_field_get_line_metrics,3);


value nme_text_field_get_char_boundaries(value inText,value inIndex,value outBounds)
{
   TextField *text;
   if (AbstractToObject(inText,text))
   {
      Rect rect = text->getCharBoundaries(val_int(inIndex));
      ToValue(outBounds,rect);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_text_field_get_char_boundaries,3);


value nme_text_field_set_selection(value inText, value inStart, value inEnd)
{
   TextField *text;
   if (AbstractToObject(inText,text))
      text->setSelection(val_int(inStart), val_int(inEnd));

   return alloc_null();
}
DEFINE_PRIM(nme_text_field_set_selection,3);


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

#define TEXT_PROP_GET_IDX(prop,Prop,to_val) \
value nme_text_field_get_##prop(value inHandle,value inIndex) \
{ \
   TextField *t; \
   if (AbstractToObject(inHandle,t)) \
      return to_val(t->get##Prop(val_int(inIndex))); \
   return alloc_null(); \
} \
DEFINE_PRIM(nme_text_field_get_##prop,2);

TEXT_PROP(text,Text,alloc_wstring,valToStdWString);
TEXT_PROP(html_text,HTMLText,alloc_wstring,valToStdWString);
TEXT_PROP(text_color,TextColor,alloc_int,val_int);
TEXT_PROP(selectable,Selectable,alloc_bool,val_bool);
TEXT_PROP(display_as_password,DisplayAsPassword,alloc_bool,val_bool);
TEXT_PROP(type,IsInput,alloc_bool,val_bool);
TEXT_PROP(multiline,Multiline,alloc_bool,val_bool);
TEXT_PROP(word_wrap,WordWrap,alloc_bool,val_bool);
TEXT_PROP(background,Background,alloc_bool,val_bool);
TEXT_PROP(background_color,BackgroundColor,alloc_int,val_int);
TEXT_PROP(border,Border,alloc_bool,val_bool);
TEXT_PROP(border_color,BorderColor,alloc_int,val_int);
TEXT_PROP(embed_fonts,EmbedFonts,alloc_bool,val_bool);
TEXT_PROP(auto_size,AutoSize,alloc_int,val_int);
TEXT_PROP_GET(text_width,TextWidth,alloc_float);
TEXT_PROP_GET(text_height,TextHeight,alloc_float);
TEXT_PROP_GET(max_scroll_h,MaxScrollH,alloc_int);
TEXT_PROP_GET(max_scroll_v,MaxScrollV,alloc_int);
TEXT_PROP_GET(bottom_scroll_v,BottomScrollV,alloc_int);
TEXT_PROP_GET(selection_begin_index,SelectionBeginIndex,alloc_int);
TEXT_PROP_GET(selection_end_index,SelectionEndIndex,alloc_int);
TEXT_PROP(scroll_h,ScrollH,alloc_int,val_int);
TEXT_PROP(scroll_v,ScrollV,alloc_int,val_int);
TEXT_PROP_GET(num_lines,NumLines,alloc_int);
TEXT_PROP(max_chars,MaxChars,alloc_int,val_int);
TEXT_PROP_GET_IDX(line_text,LineText,alloc_wstring);
TEXT_PROP_GET_IDX(line_offset,LineOffset,alloc_int);


value nme_bitmap_data_create(value width, value height, value pixelFormat, value fill)
{
   int w = val_int(width);
   int h = val_int(height);

   PixelFormat format = (PixelFormat)val_int(pixelFormat);

   Surface *result = new SimpleSurface( w, h, format, 1 );
   if (!val_is_null(fill))
      result->Clear( val_int(fill) );
   return ObjectToAbstract(result);
}
DEFINE_PRIM(nme_bitmap_data_create,4);

value nme_bitmap_data_width(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int(surface->Width());
   return alloc_int(0);
}
DEFINE_PRIM(nme_bitmap_data_width,1);

value nme_bitmap_data_height(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int(surface->Height());
   return alloc_int(0);
}
DEFINE_PRIM(nme_bitmap_data_height,1);

value nme_bitmap_data_get_prem_alpha(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_bool(surface->Format() == pfBGRPremA);
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_prem_alpha,1);

value nme_bitmap_data_set_prem_alpha(value inHandle,value inVal)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      bool use = val_bool(inVal) && (surface->Format()<pfAlpha);
      if (use)
         surface->ChangeInternalFormat(pfBGRPremA);
      else
         surface->ChangeInternalFormat(pfBGRA);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_prem_alpha,2);



value nme_bitmap_data_clear(value inHandle,value inRGB)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->Clear( val_int(inRGB) );
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_clear,2);

value nme_bitmap_data_get_transparent(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_bool( HasAlphaChannel(surface->Format()) );
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_transparent,1);

value nme_bitmap_data_set_flags(value inHandle,value inFlags)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->SetFlags(val_int(inFlags));
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_flags,2);


value nme_bitmap_data_get_flags(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      return alloc_int( surface->GetFlags() );
   return alloc_int(0);
}
DEFINE_PRIM(nme_bitmap_data_get_flags,1);


value nme_bitmap_data_fill(value inHandle, value inRect, value inRGB, value inA)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      if (val_is_null(inRect))
         surface->Clear( val_int(inRGB) | (val_int(inA)<<24) );
      else
      {
       Rect rect;
       FromValue(rect,inRect);
         surface->Clear( val_int(inRGB) | (val_int(inA)<<24), &rect );
      }
   }
   return alloc_null();

}
DEFINE_PRIM(nme_bitmap_data_fill,4);

value nme_bitmap_data_load(value inFilename, value format)
{
   Surface *surface = Surface::Load(val_os_string(inFilename));
   if (surface)
   {
      PixelFormat targetFormat = (PixelFormat)val_int(format);
      if (targetFormat>=0)
         surface->ChangeInternalFormat(targetFormat);

      value result = ObjectToAbstract(surface);
      surface->DecRef();
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_load,2);

value nme_bitmap_data_set_format(value inHandle, value format, value inConvert)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      PixelFormat targetFormat = (PixelFormat)val_int(format);
      if (targetFormat!=pfNone)
      {
         if (val_bool(inConvert))
            surface->ChangeInternalFormat(targetFormat);
         else
            surface->ReinterpretPixelFormat(targetFormat);
      }
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_format,3);

value nme_bitmap_data_get_format(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
   {
      return alloc_int(surface->Format());
   }
   return alloc_int(0);
}
DEFINE_PRIM(nme_bitmap_data_get_format,1);


value nme_bitmap_data_from_bytes(value inRGBBytes, value inAlphaBytes)
{
   ByteData bytes;
   if (!FromValue(bytes,inRGBBytes))
      return alloc_null();

   Surface *surface = Surface::LoadFromBytes(bytes.data,bytes.length);
   
   
   if (surface)
   {
      if (!val_is_null(inAlphaBytes))
      {
         ByteData alphabytes;
         if (!FromValue(alphabytes,inAlphaBytes))
            return alloc_null();
            
         if(alphabytes.length > 0)
         {
            if (surface->Format()!=pfBGRA)
               surface->ChangeInternalFormat(pfBGRA);
            uint8 *base = surface->Edit(0);
            int index = 0;
            for (int y=0; y < surface->Height(); y++)
            {
               ARGB *rgba = (ARGB *)(base + y*surface->GetStride());
               for (int x=0; x < surface->Width(); x++)
                  rgba[x].a = alphabytes.data[index++];
            } 
            surface->Commit();
         }
      }
     
      value result = ObjectToAbstract(surface);
      surface->DecRef();
      return result;
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_from_bytes,2);


value nme_bitmap_data_encode(value inSurface, value inFormat,value inQuality)
{
   Surface *surf;
   if (!AbstractToObject(inSurface,surf))
      return alloc_null();

   ByteArray array;

   bool ok = surf->Encode(&array, !strcmp(valToHxString(inFormat).c_str(),"png"), val_number(inQuality) );

   if (!ok)
      return alloc_null();
  
   return array.mValue;
}
DEFINE_PRIM(nme_bitmap_data_encode,3);




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


value nme_bitmap_data_color_transform(value inSurface,value inRect, value inColorTransform)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      ColorTransform trans;
      FromValue(trans,inColorTransform);
      Rect rect;
      FromValue(rect,inRect);

      surf->colorTransform(rect,trans);

   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_color_transform,3);


value nme_bitmap_data_apply_filter(value inDest, value inSrc,value inRect, value inOffset, value inFilter)
{
   Surface *src;
   Surface *dest;
   if (AbstractToObject(inSrc,src) && AbstractToObject(inDest,dest))
   {
      Filter *filter = FilterFromValue(inFilter);
      if (filter)
      {
         Rect rect;
         FromValue(rect,inRect);
         ImagePoint offset;
         FromValue(offset,inOffset);
         dest->applyFilter(src, rect, offset, filter);
      }
      //delete filter;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_apply_filter,5);



value nme_bitmap_data_copy(value inSource, value inSourceRect, value inTarget, value inOffset, value inMergeAlpha)
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
      
      BlendMode blend = val_bool(inMergeAlpha) ? bmNormal : bmCopy;
      source->BlitTo(render.Target(),rect,offset.x, offset.y, blend, 0);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_copy,5);

void nme_bitmap_data_copy_channel(value aSrc, value aSrcRect, value aDest, value aDestPoint, int aSrcChannel, int aDestChannel)
{
   Surface *source;
   Surface *dest;
   if (AbstractToObject(aSrc,source) && AbstractToObject(aDest,dest))
   {
      Rect rect;
      FromValue(rect,aSrcRect);
      ImagePoint offset;
      FromValue(offset,aDestPoint);


      int srcChannel =  aSrcChannel;
      int destChannel =  aDestChannel;

      if (destChannel==CHAN_ALPHA && !HasAlphaChannel(dest->Format()))
         dest->ChangeInternalFormat(pfBGRA);

      AutoSurfaceRender render(dest);
      source->BlitChannel(render.Target(),rect,offset.x, offset.y, srcChannel, destChannel );
   }
}
DEFINE_PRIME6v(nme_bitmap_data_copy_channel);


value nme_bitmap_data_get_pixels(value inSurface, value inRect)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         int size = rect.w * rect.h*4;
         ByteArray array(size);

         surf->getPixels(rect,(unsigned int *)array.Bytes());

         return array.mValue;
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_pixels,2);

value nme_bitmap_data_get_array(value inSurface, value inRect, value outArray)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         int *ints = val_array_int(outArray);
         if (ints)
            surf->getPixels(rect,(unsigned int *)ints,false,true);
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_array,3);




value nme_bitmap_data_get_color_bounds_rect(value inSurface, value inMask, value inCol, value inFind, value outRect)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect result;

      int mask = RGB2Int32(inMask);
      int col = RGB2Int32(inCol);
      surf->getColorBoundsRect(mask,col,val_bool(inFind),result);

      ToValue(outRect,result);
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_get_color_bounds_rect,5);


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
      alloc_field(result,_id_a, alloc_int( (rgb >> 24) & 0xff) );
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
      if (!val_is_null(a) && !val_is_null(rgb))
         surf->setPixel(val_int(inX),val_int(inY),(val_int(a)<<24) | val_int(rgb), true);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_pixel_rgba,4);


value nme_bitmap_data_set_bytes(value inSurface, value inRect, value inBytes,value inOffset)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         ByteArray array(inBytes);
         surf->setPixels(rect,(unsigned int *)(array.Bytes() + val_int(inOffset)), false, array.LittleEndian() );
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_bytes,4);

value nme_bitmap_data_set_array(value inSurface, value inRect, value inArray)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      Rect rect(0,0,surf->Width(),surf->Height());
      FromValue(rect,inRect);
      if (rect.w>0 && rect.h>0)
      {
         int *ints = val_array_int(inArray);
         if (ints)
            surf->setPixels(rect,(unsigned int *)ints,false,true);
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_set_array,3);



value nme_bitmap_data_generate_filter_rect(value inRect, value inFilter, value outRect)
{
   Rect rect;
   FromValue(rect,inRect);

   Filter *filter = FilterFromValue(inFilter);
   if (filter)
   {
      int quality = filter->GetQuality();
      for(int q=0;q<quality;q++)
         filter->ExpandVisibleFilterDomain(rect, q);
      delete filter;
   }

   ToValue(outRect,rect);
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_generate_filter_rect,3);



value nme_bitmap_data_noise(value *args, int nArgs)
{
   enum { aSurface, aRandomSeed, aLow, aHigh, aChannelOptions, aGrayScale };

   Surface *surf;
   if (AbstractToObject(args[aSurface],surf))
   {
      surf->noise(val_int(args[aRandomSeed]), val_int(args[aLow]), val_int(args[aHigh]),
            val_int(args[aChannelOptions]), val_int(args[aGrayScale]));
   }

   return alloc_null();
}
DEFINE_PRIM_MULT(nme_bitmap_data_noise);



value nme_bitmap_data_flood_fill(value inSurface, value inX, value inY, value inColor)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      int x = val_int(inX);
      int y = val_int(inY);
      int color = val_int(inColor);
      
      int width = surf->Width();
      int height = surf->Height();
      
      std::vector<UserPoint> queue;
      queue.push_back(UserPoint(x,y));
      
      int old = surf->getPixel(x,y);
      
      bool *search = new bool[width*height];
      std::fill_n(search, width*height, false);
      
      while (queue.size() > 0)
      {
         UserPoint currPoint = queue.back();
       queue.pop_back();
         
         x = currPoint.x;
         y = currPoint.y;
       
         if (x<0 || x>=width) continue;
         if (y<0 || y>=height) continue;
         
         search[y*width + x] = true;
         
         if (surf->getPixel(x,y) == old)
         {
            surf->setPixel(x,y,color,true);
            if (x<width && !search[y*width + (x+1)])
            {
               queue.push_back(UserPoint(x+1,y));
            }
            if (y<height && !search[(y+1)*width + x])
            {
               queue.push_back(UserPoint(x,y+1));
            }
            if (x>0 && !search[y*width + (x-1)])
            {
               queue.push_back(UserPoint(x-1,y));
            }
            if (y>0 && !search[(y-1)*width + x])
            {
               queue.push_back(UserPoint(x,y-1));
            }
         }
      }
      delete [] search;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_flood_fill,4);


void nme_render_surface_to_surface(value aTarget,value aSurface,value aMatrix,value aColourTransform,int aBlendMode,value aClipRect,bool aSmooth)
{
   Surface *surf;
   Surface *src;
   if (AbstractToObject(aTarget,surf) && AbstractToObject(aSurface,src))
   {
      Rect r(surf->Width(),surf->Height());
      if (!val_is_null(aClipRect))
         FromValue(r,aClipRect);
      AutoSurfaceRender render(surf,r);

      Matrix matrix;
      if (!val_is_null(aMatrix))
         FromValue(matrix,aMatrix);
      RenderState state(surf,4);
      state.mTransform.mMatrix = &matrix;

      ColorTransform col_trans;
      if (!val_is_null(aColourTransform))
      {
         ColorTransform t;
         FromValue(t,aColourTransform);
         state.CombineColourTransform(state,&t,&col_trans);
      }

      // TODO: Blend mode
      state.mRoundSizeToPOW2 = false;
      state.mPhase = rpRender;

      Graphics *gfx = new Graphics(0,true);
      gfx->beginBitmapFill(src,Matrix(),false,aSmooth);
      gfx->moveTo(0,0);
      gfx->lineTo(src->Width(),0);
      gfx->lineTo(src->Width(),src->Height());
      gfx->lineTo(0,src->Height());
      gfx->lineTo(0,0);

      gfx->Render(render.Target(),state);

      gfx->DecRef();
   }
}
DEFINE_PRIME7v(nme_render_surface_to_surface);


value nme_bitmap_data_dispose(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface, surf))
   {
       surf->dispose();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_dispose,1);


value nme_bitmap_data_destroy_hardware_surface(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->destroyHardwareSurface();
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_destroy_hardware_surface,1);

value nme_bitmap_data_create_hardware_surface(value inHandle)
{
   Surface *surface;
   if (AbstractToObject(inHandle,surface))
      surface->createHardwareSurface();
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_create_hardware_surface,1);


value nme_bitmap_data_dump_bits(value inSurface)
{
   Surface *surf;
   if (AbstractToObject(inSurface,surf))
   {
      surf->MakeTextureOnly();
   }
   return alloc_null();
}
DEFINE_PRIM(nme_bitmap_data_dump_bits,1);



// --- Video --------------------------------------------------

value nme_video_create(value inWidth, value inHeight)
{
   /*
   Video *video = Video::Create( val_int(inWidth), val_int(inHeight) );
   if (video)
   {
      value result = ObjectToAbstract(video);
      return result;
   }
   */
   return alloc_null();
}
DEFINE_PRIM(nme_video_create,2);

value nme_video_load(value inHandle, value inFilename)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->Load(valToStdString(inFilename).c_str());
   return alloc_null();
}
DEFINE_PRIM(nme_video_load,2);

value nme_video_play(value inHandle)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->Play();
   return alloc_null();
}
DEFINE_PRIM(nme_video_play,1);

value nme_video_clear(value inHandle)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->Clear();
   return alloc_null();
}
DEFINE_PRIM(nme_video_clear,1);

value nme_video_set_smoothing(value inHandle, value inSmoothing)
{
   Video *video;
   if (AbstractToObject(inHandle,video))
      video->smoothing = val_bool(inSmoothing);
   return alloc_null();
}
DEFINE_PRIM(nme_video_set_smoothing,2);



// --- Sound --------------------------------------------------

value nme_sound_from_file(value inFilename,value inForceMusic, value inEngine)
{
   std::string engine = valToStdString(inEngine,false);
   Sound *sound = val_is_null(inFilename) ? 0 :
                  Sound::FromFile( valToStdString(inFilename).c_str(), val_bool(inForceMusic), engine );

   if (sound)
   {
      value result =  ObjectToAbstract(sound);
      sound->DecRef();
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_from_file,3);

value nme_sound_from_data(value inData, value inLen, value inForceMusic, value inEngine)
{
   int length = val_int(inLen);
   Sound *sound;
  // printf("trying bytes with length %d", length);
   if (!val_is_null(inData) && length > 0) {
      ByteArray buf = ByteArray(inData);
      std::string engine = val_is_null(inEngine) ? std::string() : valToStdString(inEngine,false);
      //printf("I'm here! trying bytes with length %d", length);
      sound = Sound::FromEncodedBytes(buf.Bytes(), length, val_bool(inForceMusic), engine );
   } else {

      val_throw(alloc_string("Empty ByteArray"));
   }

   if (sound)
   {
      value result =  ObjectToAbstract(sound);
      sound->DecRef();
      return result;
   } else {
      val_throw(alloc_string("Not Sound"));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_from_data, 4);

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
   if (AbstractToObject(inSound, sound))
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
 

 
value nme_sound_get_engine(value inSound)
{
   Sound *sound;
   if (AbstractToObject(inSound,sound))
   {
      return alloc_string( sound->getEngine() );
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_get_engine,1);
 


// --- SoundChannel --------------------------------------------------------

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

value nme_sound_channel_set_position(value inChannel, value inFloat)
{
   #ifdef HX_MACOS
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {    
      float position = val_number(inFloat);
      channel->setPosition(position);
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_set_position,2);

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

// --- dynamic sound ---


value nme_sound_channel_needs_data(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_bool(channel->needsData());
   }
   return alloc_bool(false);
}
DEFINE_PRIM(nme_sound_channel_needs_data,1);


value nme_sound_channel_add_data(value inChannel, value inBytes)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      channel->addData(ByteArray(inBytes));
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_add_data,2);


value nme_sound_channel_get_data_position(value inChannel)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      return alloc_float(channel->getDataPosition());
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_get_data_position,1);



value nme_sound_channel_create_dynamic(value inBytes, value inTransform)
{
   ByteArray bytes(inBytes);
   SoundTransform trans;
   FromValue(trans,inTransform);
   SoundChannel *channel = SoundChannel::CreateSyncChannel(bytes,trans);
   if (channel)
   {
      value result = ObjectToAbstract(channel);
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_create_dynamic,2);



// --- Async Sound -----------------------------------------------

void SoundChannel::PerformAsyncCallback(void *inCallback)
{
   AutoGCRoot *agc = (AutoGCRoot *)inCallback;
   val_call0(agc->get());
}


void SoundChannel::DestroyAsyncCallback(void *inCallback)
{
   AutoGCRoot *agc = (AutoGCRoot *)inCallback;
   delete agc;
}



value nme_sound_channel_create_async(value inRate, value inIsStereo, value inFormat, value inCallback, value inEngine)
{
   int rateId = val_int(inRate);
   int rate = rateId==0 ? 11025 : rateId==1 ? 22050 : 44100;
   int fmtId = val_int(inFormat);
   SoundDataFormat fmt = fmtId==0 ? sdfByte : fmtId==1 ? sdfShort : sdfFloat;
   std::string engine = valToStdString(inEngine,false);
   SoundChannel *channel = SoundChannel::CreateAsyncChannel(
                   fmt, val_bool(inIsStereo),rate, new AutoGCRoot(inCallback), engine );

   if (channel)
   {
      value result = ObjectToAbstract(channel);
      return result;
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_create_async,5);



value nme_sound_channel_post_buffer(value inChannel, value inBytes)
{
   SoundChannel *channel;
   if (AbstractToObject(inChannel,channel))
   {
      ByteArray bytes(inBytes);
      channel->addData(bytes);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_sound_channel_post_buffer,2);




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

value nme_tilesheet_add_rect(value inSheet,value inRect, value inHotSpot)
{
   Tilesheet *sheet;
   if (AbstractToObject(inSheet,sheet))
   {
      Rect rect;
      FromValue(rect,inRect);
      UserPoint p(0,0);
      if (!val_is_null(inHotSpot))
         FromValue(p,inHotSpot);
      int tile = sheet->addTileRect(rect,p.x,p.y);
     return alloc_int(tile);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_tilesheet_add_rect,3);

value nme_tilesheet_get_rect(value inSheet, value inIndex, value outRect)
{
   Tilesheet *sheet;
   if (AbstractToObject(inSheet,sheet))
   {
      int index = val_int(inIndex);
      Tile tile = sheet->GetTile(index);
      ToValue(outRect, tile.mRect);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_tilesheet_get_rect,3);


// --- URL ----------------------------------------------------------
value nme_curl_initialize(value inCACertFilePath)
{
   #ifndef NME_NO_CURL
   URLLoader::initialize(val_string(inCACertFilePath));
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_curl_initialize,1);

value nme_curl_create(value inURLRequest)
{
   #ifndef NME_NO_CURL
   URLRequest request;
   FromValue(inURLRequest,request);
   URLLoader *loader = URLLoader::create(request);
   return ObjectToAbstract(loader);
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_curl_create,1);

value nme_curl_process_loaders()
{
   #ifndef NME_NO_CURL
   return alloc_bool(URLLoader::processAll());
   #endif
   return alloc_bool(true);
}
DEFINE_PRIM(nme_curl_process_loaders,0);

value nme_curl_update_loader(value inLoader,value outHaxeObj)
{
   #ifndef NME_NO_CURL
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      alloc_field(outHaxeObj,_id_state, alloc_int(loader->getState()) );
      alloc_field(outHaxeObj,_id_bytesTotal, alloc_int(loader->bytesTotal()) );
      alloc_field(outHaxeObj,_id_bytesLoaded, alloc_int(loader->bytesLoaded()) );
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_curl_update_loader,2);

value nme_curl_get_error_message(value inLoader)
{
   #ifndef NME_NO_CURL
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      return alloc_string(loader->getErrorMessage());
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_curl_get_error_message,1);

value nme_curl_get_code(value inLoader)
{
   #ifndef NME_NO_CURL
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      return alloc_int(loader->getHttpCode());
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_curl_get_code,1);


value nme_curl_get_data(value inLoader)
{
   #ifndef NME_NO_CURL
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      ByteArray b = loader->releaseData();
      if (b.mValue)
         return b.mValue;
   }
   #endif
   return alloc_null();
}
DEFINE_PRIM(nme_curl_get_data,1);

value nme_curl_get_cookies(value inLoader)
{
   #ifndef NME_NO_CURL
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      std::vector<std::string> cookies;
      loader->getCookies(cookies);
      value result = alloc_array(cookies.size());
      for(int i=0;i<cookies.size();i++)
         val_array_set_i(result,i,alloc_string_len(cookies[i].c_str(),cookies[i].length()));
      return result;
   }
   #endif
   return alloc_array(0);
}
DEFINE_PRIM(nme_curl_get_cookies,1);

value nme_curl_get_headers(value inLoader)
{
   #ifndef NME_NO_CURL
   URLLoader *loader;
   if (AbstractToObject(inLoader,loader))
   {
      std::vector<std::string> responseHeaders;
      loader->getResponseHeaders(responseHeaders);
      int size = responseHeaders.size();
      value result = alloc_array(size);
      for(int i=0;i<size;i++)
         val_array_set_i(result,i,alloc_string_len(responseHeaders[i].c_str(),responseHeaders[i].length()));
      return result;
   }
   #endif
   return alloc_array(0);
}
DEFINE_PRIM(nme_curl_get_headers,1);



#ifdef HXCPP_JS_PRIME

#include <zlib.h>

int nme_zip_encode(value ioBuffer)
{
   buffer buf = val_to_buffer(ioBuffer);

   std::vector<unsigned char> &src = buf->data;
   int slen = src.size();

   z_stream z;
   memset(&z,0,sizeof(z_stream));
   int err = 0;
   int flush = Z_NO_FLUSH;
   int level = 5;
   if ( deflateInit(&z,level) != Z_OK )
      val_throw(alloc_string("bad deflateInit"));

   int dlen = deflateBound(&z,slen);
   std::vector<unsigned char> dest(dlen);

   z.next_in = (Bytef*)&src[0];
   z.avail_in = slen;
   z.next_out = (Bytef*)&dest[0];
   z.avail_out = dlen;

   int code = 0;
   if( (code = ::deflate(&z,flush)) < 0 )
   {
       deflateEnd(&z);
       val_throw( alloc_string("bad deflate") );
   }
   int size = z.next_out - (Bytef*)&dest[0];
   dest.resize(size);
   buf->data.swap(dest);
   deflateEnd(&z);
   return size;
}
DEFINE_PRIME1(nme_zip_encode);

int nme_zip_decode(value ioBuffer)
{
   buffer buf = val_to_buffer(ioBuffer);
   if (!buf)
      return 0;

   std::vector<unsigned char> &src = buf->data;
   int slen = src.size();
   if (slen==0)
      return 0;

   std::vector<unsigned char> dest(slen*2);

   z_stream z;
   memset(&z,0,sizeof(z_stream));
   int err = 0;
   int flush = Z_NO_FLUSH;
   if ( inflateInit2(&z,MAX_WBITS) != Z_OK )
      val_throw(alloc_string("bad inflateInit"));

   z.next_in = (Bytef*)&src[0];
   z.avail_in = slen;

   int dstpos = 0;
   while(true)
   {
      z.next_out = (Bytef*)&dest[dstpos];
      z.avail_out = dest.size() - dstpos;
      int code = 0;
      if( (code = ::inflate(&z,flush)) < 0 )
      {
          inflateEnd(&z);
          val_throw( alloc_string("bad inflate") );
      }
      if (code==Z_STREAM_END)
      {
         int size = z.next_out - (Bytef*)&dest[0];
         dest.resize(size);
         buf->data.swap(dest);
         inflateEnd(&z);
         return size;
      }
      // Alloc some more...
      dstpos = dest.size();
      dest.resize(dest.size() + std::max(20, slen/2));
   }
   return 0;
}
DEFINE_PRIME1(nme_zip_decode);
#endif




value nme_lzma_encode(value input_value)
{
#if !defined(NME_NO_LZMA)
   buffer input_buffer = val_to_buffer(input_value);
   buffer output_buffer = alloc_buffer_len(0);
   Lzma::Encode(input_buffer, output_buffer);
   return buffer_val(output_buffer);
#else
   return alloc_null();
#endif
}
DEFINE_PRIM(nme_lzma_encode,1);

value nme_lzma_decode(value input_value)
{
#if !defined(NME_NO_LZMA)
   buffer input_buffer = val_to_buffer(input_value);
   buffer output_buffer = alloc_buffer_len(0);
   Lzma::Decode(input_buffer, output_buffer);
   return buffer_val(output_buffer);
#else
   return alloc_null();
#endif
}
DEFINE_PRIM(nme_lzma_decode,1);


value nme_file_dialog_folder(value in_title, value in_text )
{ 
    std::string _title( valToStdString( in_title ) );
    std::string _text( valToStdString( in_text ) );

    std::string path = FileDialogFolder( _title, _text );

    return alloc_string( path.c_str() );
}
DEFINE_PRIM(nme_file_dialog_folder,2);

value nme_file_dialog_open(value in_title, value in_text, value in_types )
{ 
    std::string _title( valToStdString( in_title ) );
    std::string _text( valToStdString( in_text ) );

    //value *_types = val_array_value( in_types );

    std::string path = FileDialogOpen( _title, _text, std::vector<std::string>() );

    return alloc_string( path.c_str() );
}
DEFINE_PRIM(nme_file_dialog_open,3);

value nme_file_dialog_save(value in_title, value in_text, value in_types )
{ 
    std::string _title( valToStdString( in_title ) );
    std::string _text( valToStdString( in_text ) );

    //value *_types = val_array_value( in_types );

    std::string path = FileDialogSave( _title, _text, std::vector<std::string>() );

    return alloc_string( path.c_str() );
}
DEFINE_PRIM(nme_file_dialog_save,3);

// Reference this to bring in all the symbols for the static library
#ifdef STATIC_LINK
extern "C" int nme_oglexport_register_prims();
#endif

extern "C" int nme_register_prims()
{
   InitIDs();
   #ifdef STATIC_LINK
   nme_oglexport_register_prims();
   #endif
   return 0;
}

