#ifndef INCLUDED_OGL_H
#define INCLUDED_OGL_H

#if defined(NME_ANGLE)
   // Static link, not dll import
   #define EGLAPI
   #define GL_APICALL
   #define NME_GLES
   #define GL_GLEXT_PROTOTYPES

   #define NME_GL_LEVEL 300

   #include <GLES3/gl3.h>
   #include <GLES2/gl2ext.h>

#elif defined(EMSCRIPTEN)

   #define NME_GLES
   //#define NME_GL_LEVEL 300
   #define NME_GL_LEVEL 200

   #include <GLES3/gl3.h>
   #include <GLES3/gl2ext.h>

#elif defined(ANDROID) || defined(RASPBERRYPI)

   #define NME_GLES
   // TODO - check extensions
   #define NME_GL_LEVEL 200

   #include <GLES2/gl2.h>
   #include <GLES2/gl2ext.h>

#elif defined(GCW0)

   #define NME_GLES
   // TODO - check extensions
   #define NME_GL_LEVEL 200
   #include <GLES2/gl2.h>
   #include <GLES2/gl2ext.h>

#elif defined(IPHONE)

   // TODO - check extensions
   //#define NME_GL_LEVEL 300
   #define NME_GL_LEVEL 200

   #include <OpenGLES/ES3/gl.h>
   #include <OpenGLES/ES3/glext.h>

   //typedef CAEAGLLayer *WinDC;
   //typedef EAGLContext *GLCtx;
   #define NME_GLES

#elif defined(HX_LINUX)

  #define NME_GL_LEVEL 300
  #define NEED_EXTENSIONS
  #define DYNAMIC_OGL

  #define GL_GLEXT_PROTOTYPES
  #include <SDL_opengl.h>
  #define FORCE_NON_PO2

#elif defined(HX_MACOS)

  #define GL_GLEXT_PROTOTYPES
  #include <SDL_opengl.h>
  #define FORCE_NON_PO2

  // TODO - do we care about mac?  They do not care about us.
  #define NME_GL_LEVEL 200

  #define glBindFramebuffer glBindFramebufferEXT
  #define glBindRenderbuffer glBindRenderbufferEXT
  #define glGenFramebuffers glGenFramebuffersEXT
  #define glDeleteFramebuffers glDeleteFramebuffersEXT
  #define glGenRenderbuffers glGenRenderbuffersEXT
  #define glDeleteRenderbuffers glDeleteRenderbuffersEXT
  #define glFramebufferRenderbuffer glFramebufferRenderbufferEXT
  #define glFramebufferTexture2D glFramebufferTexture2DEXT
  #define glRenderbufferStorage glRenderbufferStorageEXT
  #define glCheckFramebufferStatus glCheckFramebufferStatusEXT
  #define glCheckFramebufferStatus glCheckFramebufferStatusEXT
  #define glGenerateMipmap glGenerateMipmapEXT
  #define glGetFramebufferAttachmentParameteriv glGetFramebufferAttachmentParameterivEXT
  #define glGetRenderbufferParameteriv glGetRenderbufferParameterivEXT
  #define glIsFramebuffer glIsFramebufferEXT
  #define glIsRenderbuffer glIsRenderbufferEXT

#elif defined(HX_WINDOWS)

#define NME_GL_LEVEL 300

// Windows ....
#include <windows.h>
#include <gl/GL.h>
//#define FORCE_NON_PO2
#ifdef __MINGW32__
#include <stddef.h>
#endif
typedef ptrdiff_t GLsizeiptrARB;

#define NEED_EXTENSIONS
#define GL_GLEXT_PROTOTYPES
#include <SDL_opengl.h>
#ifdef NME_TOOLKIT_BUILD
#include <SDL_opengl_glext.h>
#endif

#endif

#if defined(HX_WINDOWS) && !defined(NME_ANGLE)
typedef HDC WinDC;
typedef HGLRC GLCtx;
#else
typedef void *WinDC;
typedef void *GLCtx;
#endif


#ifndef GL_BUFFER_SIZE

#define GL_BUFFER_SIZE                0x8764
#define GL_BUFFER_USAGE               0x8765
#define GL_ARRAY_BUFFER               0x8892
#define GL_ELEMENT_ARRAY_BUFFER       0x8893
#define GL_ARRAY_BUFFER_BINDING       0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING 0x8895
#define GL_VERTEX_ARRAY_BUFFER_BINDING 0x8896
#define GL_NORMAL_ARRAY_BUFFER_BINDING 0x8897
#define GL_COLOR_ARRAY_BUFFER_BINDING 0x8898
#define GL_INDEX_ARRAY_BUFFER_BINDING 0x8899
#define GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING 0x889A
#define GL_EDGE_FLAG_ARRAY_BUFFER_BINDING 0x889B
#define GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING 0x889C
#define GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING 0x889D
#define GL_WEIGHT_ARRAY_BUFFER_BINDING 0x889E
#define GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING 0x889F
#define GL_READ_ONLY                  0x88B8
#define GL_WRITE_ONLY                 0x88B9
#define GL_READ_WRITE                 0x88BA
#define GL_BUFFER_ACCESS              0x88BB
#define GL_BUFFER_MAPPED              0x88BC
#define GL_BUFFER_MAP_POINTER         0x88BD
#define GL_STREAM_DRAW                0x88E0
#define GL_STREAM_READ                0x88E1
#define GL_STREAM_COPY                0x88E2
#define GL_STATIC_DRAW                0x88E4
#define GL_STATIC_READ                0x88E5
#define GL_STATIC_COPY                0x88E6
#define GL_DYNAMIC_DRAW               0x88E8
#define GL_DYNAMIC_READ               0x88E9
#define GL_DYNAMIC_COPY               0x88EA
#define GL_COMPILE_STATUS             0x8B81
#define GL_LINK_STATUS                0x8B82
#define GL_VALIDATE_STATUS            0x8B83
#define GL_INFO_LOG_LENGTH            0x8B84
#define GL_ATTACHED_SHADERS           0x8B85
#define GL_ACTIVE_UNIFORMS            0x8B86
#define GL_ACTIVE_UNIFORM_MAX_LENGTH  0x8B87
#define GL_SHADER_SOURCE_LENGTH       0x8B88
#define GL_VERTEX_SHADER              0x8B31
#define GL_FRAGMENT_SHADER            0x8B30
#define GL_TEXTURE0                   0x84C0
#endif


#ifndef GL_CLAMP_TO_EDGE
#define GL_CLAMP_TO_EDGE 0x812F
#endif

#ifndef GL_POINT_SMOOTH
#define GL_POINT_SMOOTH 0x0B10
#endif

#ifndef GL_LINE_SMOOTH
#define GL_LINE_SMOOTH  0x0B20
#endif

#include <Graphics.h>
#include <Surface.h>



#ifdef NEED_EXTENSIONS
   #define DECLARE_EXTENSION
   #include "OGLExtensions.h"
   #undef DECLARE_EXTENSION
   #define CHECK_EXT(x) x
#else
   #define CHECK_EXT(x) true
#endif

namespace nme
{

Texture *OGLCreateTexture(Surface *inSurface,unsigned int inFlags);

enum
{
   PROG_TEXTURE =           0x0001,
   PROG_ALPHA_TEXTURE =     0x0002,
   PROG_COLOUR_PER_VERTEX = 0x0004,
   PROG_NORMAL_DATA =       0x0008,
   PROG_RADIAL =            0x0010,
   PROG_RADIAL_FOCUS =      0x0020,
   PROG_TINT =              0x0040,
   PROG_COLOUR_OFFSET =     0x0080,

   PROG_COUNT =             0x0100,
};


class GPUProg
{
public:
   typedef float Trans4x4[4][4];

   static GPUProg *create(unsigned int inID);

   virtual ~GPUProg() {}

   virtual bool bind() = 0;

   virtual void disableSlots() = 0;
   virtual void setTransform(const Trans4x4 &inTrans) = 0;
   virtual void setColourTransform(const ColorTransform *inTransform, unsigned int inColour,
                                    bool inPremultiplyAlpha) = 0;
   virtual void setGradientFocus(float inFocus) = 0;

   int vertexSlot;
   int textureSlot;
   int normalSlot;
   int colourSlot;

};

void InitOGL2Extensions();

#define NME_GL_STATS_DRAW_ARRAYS 0x0
#define NME_GL_STATS_DRAW_ELEMENTS 0x2
#define NME_GL_STATS_GLVIEW 0x4
struct glStatsStruct
{
    glStatsStruct(){
        clear();
    }
    inline void clear(){
        #ifndef NME_NO_GL_STATS
        memset(statsArray, 0x0, sizeof(statsArray));
        #endif
    }
    inline void record(int verts, int flag){
        #ifndef NME_NO_GL_STATS
        statsArray[flag] += verts;
        statsArray[++flag]++;
        #endif
    }
    inline void get(int * arr, int n){
        #ifndef NME_NO_GL_STATS
        n = (n>=8?8:n);
        memcpy(arr, statsArray, sizeof(int)*n);
        #endif
    }
    inline void get(glStatsStruct *inStats){
        #ifndef NME_NO_GL_STATS
        memcpy(inStats->statsArray, statsArray, sizeof(statsArray));
        #endif
    }
    int statsArray[8];
};

} // end namespace nme

#endif // INCLUDED_OGL_H
