#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
// Include neko glue....
#define NEKO_COMPATIBLE
#endif


// Only tested on mac so far ...
#if defined(HX_MACOS) || defined(HX_WINDOWS)


#ifdef ANDROID
#include <android/log.h>
#endif

#include <ExternalInterface.h>
#include <ByteArray.h>
#include "OGL.h"

using namespace nme;

// --- General -------------------------------------------

value nme_gl_enable(value inCap)
{
   glEnable(val_int(inCap));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_enable,1);


value nme_gl_disable(value inCap)
{
   glDisable(val_int(inCap));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_disable,1);



// --- Program -------------------------------------------

value nme_gl_create_program()
{
   int result = glCreateProgram();
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_create_program,0);


value nme_gl_link_program(value inId)
{
   int id = val_int(inId);
   glLinkProgram(id);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_link_program,1);


value nme_gl_get_program_info_log(value inId)
{
   char buf[1024];
   int id = val_int(inId);
   glGetProgramInfoLog(id,1024,0,buf);
   return alloc_string(buf);
}
DEFINE_PRIM(nme_gl_get_program_info_log,1);


value nme_gl_delete_program(value inId)
{
   int id = val_int(inId);
   glDeleteProgram(id);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_delete_program,1);



value nme_gl_get_attrib_location(value inId,value inName)
{
   int id = val_int(inId);
   return alloc_int(glGetAttribLocation(id,val_string(inName)));
}
DEFINE_PRIM(nme_gl_get_attrib_location,2);


value nme_gl_get_uniform_location(value inId,value inName)
{
   int id = val_int(inId);
   return alloc_int(glGetUniformLocation(id,val_string(inName)));
}
DEFINE_PRIM(nme_gl_get_uniform_location,2);


value nme_gl_get_program_parameter(value inId,value inName)
{
   int id = val_int(inId);
   int result = 0;
   glGetProgramiv(id, val_int(inName), &result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_program_parameter,2);


value nme_gl_use_program(value inId)
{
   int id = val_int(inId);
   glUseProgram(id);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_use_program,1);


value nme_gl_uniform_matrix(value inLocation, value inTranspose, value inBytes,value inCount)
{
   int loc = val_int(inLocation);
   int count = val_int(inCount);
   ByteArray bytes(inBytes);
   int size = bytes.Size();

   if (size>=count*4*4)
   {
      const float *data = (float *)bytes.Bytes();

      bool trans = val_bool(inTranspose);
      if (count==2)
         glUniformMatrix2fv(loc,1,trans,data);
      else if (count==3)
         glUniformMatrix3fv(loc,1,trans,data);
      else if (count==4)
         glUniformMatrix4fv(loc,1,trans,data);
   }
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform_matrix,4);

value nme_gl_uniform1i(value inLocation, value inV0)
{
   glUniform1i(val_int(inLocation),val_int(inV0));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_uniform1i,2);

// --- Shader -------------------------------------------


value nme_gl_create_shader(value inType)
{
    return alloc_int(glCreateShader(val_int(inType)));
}
DEFINE_PRIM(nme_gl_create_shader,1);


value nme_gl_delete_shader(value inId)
{
   int id = val_int(inId);
   glDeleteShader(id);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_delete_shader,1);


value nme_gl_shader_source(value inId,value inSource)
{
   int id = val_int(inId);
   const char *source = val_string(inSource);
   glShaderSource(id,1,&source,0);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_shader_source,2);


value nme_gl_attach_shader(value inProg,value inShader)
{
   glAttachShader(val_int(inProg),val_int(inShader));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_attach_shader,2);



value nme_gl_compile_shader(value inId)
{
   int id = val_int(inId);
   glCompileShader(id);

   return alloc_null();
}
DEFINE_PRIM(nme_gl_compile_shader,1);


value nme_gl_get_shader_parameter(value inId,value inName)
{
   int id = val_int(inId);
   int result = 0;
   glGetShaderiv(id,val_int(inName), & result);
   return alloc_int(result);
}
DEFINE_PRIM(nme_gl_get_shader_parameter,2);


value nme_gl_get_shader_info_log(value inId)
{
   int id = val_int(inId);
   char buf[1024] = "";
   glGetShaderInfoLog(id,1024,0,buf);

   return alloc_string(buf);
}
DEFINE_PRIM(nme_gl_get_shader_info_log,1);

// --- Buffer -------------------------------------------


value nme_gl_create_buffer()
{
 	GLuint buffers;
   glGenBuffers(1,&buffers);
   return alloc_int(buffers);
}
DEFINE_PRIM(nme_gl_create_buffer,0);


value nme_gl_delete_buffer(value inId)
{
   GLuint id = val_int(inId);
   glDeleteBuffers(1,&id);
   return alloc_null();
}
DEFINE_PRIM(nme_gl_delete_buffer,1);


value nme_gl_bind_buffer(value inTarget, value inId )
{
   glBindBuffer(val_int(inTarget),val_int(inId));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_buffer,2);


value nme_gl_buffer_data(value inTarget, value inByteBuffer, value inStart, value inLen, value inUsage)
{
   int len = val_int(inLen);
   int start = val_int(inStart);

   ByteArray bytes(inByteBuffer);
   const unsigned char *data = bytes.Bytes();
   int size = bytes.Size();

   if (len+start>size)
      val_throw(alloc_string("Invalid byte length"));

   glBufferData(val_int(inTarget), len, data + start, val_int(inUsage) );

   return alloc_null();
}
DEFINE_PRIM(nme_gl_buffer_data,5);


value nme_gl_vertex_attrib_pointer(value *arg, int nargs)
{
   enum { aIndex, aSize, aType, aNormalized, aStride, aOffset, aSIZE };

   glVertexAttribPointer( val_int(arg[aIndex]),
                          val_int(arg[aSize]),
                          val_int(arg[aType]),
                          val_bool(arg[aNormalized]),
                          val_int(arg[aStride]),
                          (void *)val_int(arg[aOffset]) );

   return alloc_null();
}

DEFINE_PRIM_MULT(nme_gl_vertex_attrib_pointer);

value nme_gl_enable_vertex_attrib_array(value inIndex)
{
   glEnableVertexAttribArray(val_int(inIndex));
   return alloc_null();
}

DEFINE_PRIM(nme_gl_enable_vertex_attrib_array,1);

// --- Drawing -------------------------------


value nme_gl_draw_arrays(value inMode, value inFirst, value inCount)
{
   glDrawArrays( val_int(inMode), val_int(inFirst), val_int(inCount) );
   return alloc_null();
}
DEFINE_PRIM(nme_gl_draw_arrays,3);




// --- Windowing -------------------------------

value nme_gl_viewport(value inX, value inY, value inW,value inH)
{
   glViewport(val_int(inX),val_int(inY),val_int(inW),val_int(inH));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_viewport,4);


value nme_gl_scissor(value inX, value inY, value inW,value inH)
{
   glScissor(val_int(inX),val_int(inY),val_int(inW),val_int(inH));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_scissor,4);

value nme_gl_clear(value inMask)
{
   glClear(val_int(inMask));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_clear,1);


value nme_gl_clear_color(value r,value g, value b, value a)
{
   glClearColor(val_number(r),val_number(g),val_number(b),val_number(a));
   return alloc_null();
}
DEFINE_PRIM(nme_gl_clear_color,4);

// --- Texture -------------------------------------------
value nme_gl_bind_bitmap_data_texture(value inBitmapData)
{
   Surface  *surface;
   if (AbstractToObject(inBitmapData,surface) )
   {
      HardwareContext *ctx = gDirectRenderContext;
      if (!ctx)
         ctx = nme::HardwareContext::current;
      if (ctx)
      {
         Texture *texture = surface->GetOrCreateTexture(*gDirectRenderContext);
         if (texture)
            texture->Bind(surface,-1);
      }
   }

   return alloc_null();
}
DEFINE_PRIM(nme_gl_bind_bitmap_data_texture,1);


#endif // ifdef HX_MACOS


