#include <emscripten.h>
#include <emscripten/bind.h>
#include <vector>
#include <string>
#include <unordered_map>

typedef std::unordered_map<std::string,int> IdMap;
typedef emscripten::val value;
typedef emscripten::val values_array;
typedef std::string HxString;
typedef std::wstring HxWString;


typedef int vkind;

extern IdMap sIdMap;
extern IdMap sKindMap;
extern std::vector<value> sIdKeys;
extern std::vector<const char *> sIdKeyNames;

// emscripten will perform these checks
#define val_check_kind(v,t)
#define val_check_function(f,n)
#define val_check(v,t)
#define val_null alloc_null()




inline int val_id(const char *inName)
{
   IdMap::iterator id = sIdMap.find(inName);
   if (id==sIdMap.end())
   {
      int result = sIdMap.size();
      sIdMap[inName] = result;
      sIdKeys.push_back(value(inName));
      sIdKeyNames.push_back(inName);
      return result;
   }
   return id->second;
}


inline void kind_share(vkind *outKind,const std::string &inName)
{
   auto it = sKindMap.find(inName);
   if (it==sKindMap.end())
   {
      int k = sKindMap.size()+1;
      sKindMap[inName] = k;
      *outKind = k;
   }
   else
      *outKind = it->second;
}

class AutoGCBlocking
{
public:
   AutoGCBlocking() {}
   void Close() { }
};

class AutoGCRoot
{
public:
   AutoGCRoot(value inValue) : mValue(inValue) { }

   const value &get()const { return mValue; }
   void set(value inValue) { mValue = inValue; }
   
private:
   value mValue;
};

inline bool val_is_null(value inVal) { return inVal.isNull() || inVal.isUndefined(); }


inline double val_field_numeric(value inObject, int fieldId)
{
   return inObject[sIdKeys[fieldId]].as<double>();
}

inline int val_int(value inValue) { return inValue.as<int>(); }
inline bool val_bool(value inValue) { return inValue.as<bool>(); }
inline double val_number(value inValue) { return inValue.as<double>(); }
inline double val_float(value inValue) { return inValue.as<double>(); }

inline value alloc_null() { return emscripten::val::null(); }
inline value alloc_int(int inValue) { return value(inValue); }
inline value alloc_best_int(int inValue) { return value(inValue); }
inline value alloc_int32(int inValue) { return value(inValue); }
inline value alloc_bool(bool inValue) { return value(inValue); }
inline value alloc_float(double inValue) { return value(inValue); }
inline value alloc_empty_object() { return value::object(); }

inline value alloc_string(const char *inStr) { return value(std::string(inStr)); }
inline value alloc_wstring(const wchar_t *inStr) { return value(std::wstring(inStr)); }

inline value alloc_abstract(vkind inKind,void *inObject)
{
   value abstract(value::object());
   abstract.set("ptr", (int)inObject);
   abstract.set("kind", (int)inKind);
   return abstract;
}

inline void gc_enter_blocking() { }
inline void gc_exit_blocking() { }
inline void gc_safe_point() { }

inline bool val_is_array(value inValue)
{
   return value::global("Array").call<bool>("isArray",inValue);
}

// Array access - fast if possible - may return null
// Resizing the array may invalidate the pointer
inline bool *val_array_bool(value) { return 0; }
inline int *val_array_int(value) { return 0; }
inline double *val_array_double(value) { return 0; }
inline float *val_array_float(value) { return 0; }

inline values_array val_array_value(value inValue) { return value::global("Array").call<bool>("isArray",inValue) ? inValue : value::null(); }
inline bool value_array_ok(values_array a) { return !val_is_null(a); }

inline void array_set_int(values_array a, int inIndex, int val) { a.set(inIndex,val); }
inline void array_set_bool(values_array a, int inIndex, bool val) { a.set(inIndex,val); }
inline void array_set_float(values_array a, int inIndex, float val) { a.set(inIndex,val); }
inline void array_set_double(values_array a, int inIndex, double val) { a.set(inIndex,val); }
inline void array_set_value(values_array a, int inIndex, value val) {  a.set(inIndex,val); }

inline int array_get_int(values_array a, int inIndex) { return a[inIndex].as<int>(); }
inline bool array_get_bool(values_array a, int inIndex) { return a[inIndex].as<bool>(); }
inline float array_get_float(values_array a, int inIndex) { return a[inIndex].as<float>(); }
inline double array_get_double(values_array a, int inIndex) { return a[inIndex].as<double>(); }
inline value array_get_value(values_array a, int inIndex) { return a[inIndex]; }

// TODO - can't shrink
inline void val_array_set_size(value array, int n) { if (n>0) array.set(n-1,alloc_null()); }

// Array access - generic
inline value val_array_i(value array,int index) { return array[index]; }

inline value alloc_array(int inSize)
{
   value result = value::array();
   if (inSize>0)
      result.set(inSize-1, value::null() );
   return result;
}

inline int val_array_size(value inArray)
{
   return (int)inArray["length"].as<unsigned>();
}

//DEFFUNC_2(void,val_array_set_size,value,int)
inline void val_array_set_i(value array,int index,value data) { array[index] = data; }

inline void val_array_push(value array, value data) { array[ 1+array["length"].as<int>() ] = data; }


inline value alloc_string_len(const char *inStr,int inLen) { return value(std::string(inStr,inStr+inLen)); }
inline value alloc_wstring_len(const wchar_t *inStr,int inLen) { return value(std::wstring(inStr,inStr+inLen)); }

inline std::wstring valToStdWString(value inVal)
{
   return inVal.as<std::wstring>();
}


inline void val_throw(value message)
{
   std::string v = message.as<std::string>();
    EM_ASM_({ throw $0; }, v.c_str());
}
inline void hx_fail(const char *message,const char *,int)
{
    EM_ASM_({ throw $0; }, message);
}
inline void hx_error() { hx_fail("error","unknown",0); }



// Call Function 
inline value val_call0(value func)
{
    return func();
}
inline value val_call1(value func,value arg0)
{
   return func(arg0);
}
inline value val_call2(value func,value arg0,value arg1)
{
   return func(arg0, arg1);
}
inline value val_call3(value func,value arg0,value arg1,value arg2)
{
   return func(arg0, arg1, arg2);
}
inline value val_callN(value func,value *args,int count)
{
   switch(count)
   {
      case 0: return func();
      case 1: return func(args[0]);
      case 2: return func(args[0],args[1]);
      case 3: return func(args[0],args[1],args[2]);
      case 4: return func(args[0],args[1],args[2],args[3]);
      case 5: return func(args[0],args[1],args[2],args[3],args[4]);
      case 6: return func(args[0],args[1],args[2],args[3],args[4],args[5]);
      case 7: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
      case 8: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
      case 9: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]);
      case 10: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9]);
   }
   hx_fail("Too many args",__FILE__,__LINE__);
   return alloc_null();
}

// Call the function - catch and print any exceptions
//DEFFUNC_1(value,val_call0_traceexcept,value)

// Call object field
inline value val_ocall0(value obj,int fieldId)
{
   return obj.call<value>(sIdKeyNames[fieldId]);
}
inline value val_ocall1(value obj,int fieldId,value arg0)
{
   return obj.call<value>(sIdKeyNames[fieldId],arg0);
}
inline value val_ocall2(value obj,int fieldId,value arg0,value arg1)
{
   return obj.call<value>(sIdKeyNames[fieldId],arg0,arg1);
}

/*
inline value val_ocallN(value obj,int fieldId,value *args,int count)
{
   value func = obj[sIdKeys[fieldId]];

   switch(count)
   {
      case 0: return func();
      case 1: return func(args[0]);
      case 2: return func(args[0],args[1]);
      case 3: return func(args[0],args[1],args[2]);
      case 4: return func(args[0],args[1],args[2],args[3]);
      case 5: return func(args[0],args[1],args[2],args[3],args[4]);
      case 6: return func(args[0],args[1],args[2],args[3],args[4],args[5]);
      case 7: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
      case 8: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
      case 9: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]);
      case 10: return func(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9]);
   }
   hx_fail("Too many args",__FILE__,__LINE__);
   return alloc_null();
}
*/

//int val_type(value inObject) { value = inObject.typeof(); }

inline vkind val_kind(value inObject)
{
   return (vkind)inObject["kind"].as<int>();
}


// Objects access
inline void alloc_field(value inObject,int inIndex,value inField)
{
   inObject.set(sIdKeys[inIndex],inField);
}

inline value val_field(value inObject,int inIndex)
{
   return inObject[sIdKeys[inIndex]];
}

inline value val_field_name(int inField)
{
   return sIdKeys[inField];
}

#define DEFINE_ENTRY_POINT(func) \
struct js_entry_boot { \
   js_entry_boot() { func(); } \
}; \
static js_entry_boot _js_entry_boot;

#define DEFINE_PRIM(func,nargs) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
// TODO - no pointer
#define DEFINE_PRIM_MULT(func) 


#define DEFINE_PRIME0(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME1(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME2(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME3(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME4(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME5(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME6(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME7(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME8(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME9(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME10(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME11(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME12(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }


#define DEFINE_PRIME0v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME1v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME2v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME3v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME4v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME5v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME6v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME7v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME8v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME9v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME10v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME11v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }
#define DEFINE_PRIME12v(func) EMSCRIPTEN_BINDINGS(func) { emscripten::function(#func, &func); }



/*
void val_iter_fields(value inObject,__hx_field_iter inIter,void *inHandle)
{
}

void val_iter_field_vals(value inObject,__hx_field_iter inIter,void *inHandle)
{
}
*/



/*
// Determine value type
DEFFUNC_2(void *,val_to_kind,value,vkind)
// don't check the 'kind' ...
DEFFUNC_1(void *,val_data,value)
DEFFUNC_1(int,val_fun_nargs,value)



// String access
DEFFUNC_1(int,val_strlen,value)
DEFFUNC_1(const wchar_t *,val_wstring,value)
DEFFUNC_1(const char *,val_string,value)
DEFFUNC_1(wchar_t *,val_dup_wstring,value)
DEFFUNC_1(char *,val_dup_string,value)
DEFFUNC_2(char *,alloc_string_data,const char *,int)
DEFFUNC_2(value,alloc_string_len,const char *,int)
DEFFUNC_2(value,alloc_wstring_len,const wchar_t *,int)


// String Buffer
// A 'buffer' is a tool for joining strings together.
// The C++ implementation is haxe.io.BytesData
// The neko implementation is something else again, and can't be passes as a value, only copied to a string

// Create a buffer from string of an empty buffer of a given length
DEFFUNC_1(buffer,alloc_buffer,const char *)
DEFFUNC_1(buffer,alloc_buffer_len,int)

// Append a string representation of a value to the buffer
DEFFUNC_2(void,val_buffer,buffer,value)

// Append a c-string to a buffer
DEFFUNC_2(void,buffer_append,buffer,const char *)

// Append given number of bytes of a c-string to the buffer
DEFFUNC_3(void,buffer_append_sub,buffer,const char *,int)

// Append given character to string
DEFFUNC_2(void,buffer_append_char,buffer,int)

// Convert buffer back into string value
DEFFUNC_1(value,buffer_to_string,buffer)



// These routines are for direct access to the c++ BytesData structure
// Use getByteData and resizeByteData for more generic access to haxe.io.Bytes

// This will never return true on a neko host.
DEFFUNC_1(bool,val_is_buffer,value)

// These functions are only valid if val_is_buffer returns true
// Currently, cffiByteBuffer is the same struct as buffer, but the usage is quite different
DEFFUNC_1(cffiByteBuffer,val_to_buffer,value)

// Number of byes in the array
DEFFUNC_1(int,buffer_size,cffiByteBuffer)

// Pointer to the byte data - will become invalid if the array is resized
DEFFUNC_1(char *,buffer_data,cffiByteBuffer)

// Convert c++ ByteBuffer back to 'value' - no copy involved
DEFFUNC_1(value,buffer_val,cffiByteBuffer)

// Resize the array - will invalidate the data
DEFFUNC_2(void,buffer_set_size,cffiByteBuffer,int)

// This is used by resizeByteData for manipulating bytes directly on neko
DEFFUNC_1(value,alloc_raw_string,int)


// Abstract types
DEFFUNC_0(vkind,alloc_kind)


// Used for finding functions in static libraries
DEFFUNC_2(int, hx_register_prim, const char *, void*)
*/



