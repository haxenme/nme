#ifndef INCLUDED_OGL_H
#define INCLUDED_OGL_H

#if defined(WEBOS) || defined(BLACKBERRY) || defined(ANDROID) || defined(GPH)

#include <GLES/gl.h>
#include <GLES/glext.h>
#define NME_GLES

#elif defined(IPHONE)

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

//typedef CAEAGLLayer *WinDC;
//typedef EAGLContext *GLCtx;
#define NME_GLES

#elif !defined(HX_WINDOWS)
// Mac/Linux....
#include <SDL_opengl.h>
#define FORCE_NON_PO2

#else

// Windows ....
#include <windows.h>
#include <gl/GL.h>
#define FORCE_NON_PO2
typedef ptrdiff_t GLsizeiptrARB;
#endif


#ifdef HX_WINDOWS
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

#endif


#ifndef GL_CLAMP_TO_EDGE
#define GL_CLAMP_TO_EDGE 0x812F
#endif

#ifdef GPH
#define NME_DITHER
#endif

#include <Graphics.h>
#include <Surface.h>

namespace nme
{

Texture *OGLCreateTexture(Surface *inSurface,unsigned int inFlags);

class GPUProg
{
public:
   static GPUProg *Create(const char *inVertexShader, const char *inPixelShader);
   virtual ~GPUProg() {}

   virtual bool bind() = 0;
   virtual int  getPositionSlot() = 0;
   virtual int  getTexCoord1DSlot() = 0;
   virtual int  getTexCoord2DSlot() = 0;
   virtual int  getTexCoordMaskSlot() = 0;

   virtual void setTextureMode(bool inRepeat, bool inSmooth) = 0;
   virtual void setMatrix(const float *inMatrix) = 0;
   virtual void setTint(unsigned int inColour) = 0;
   virtual void setGradientFocus(float inFocus) = 0;
   virtual void setColourTransform(float *inOffset, float *inScale) = 0;
};


} // end namespace nme


#endif // INCLUDED_OGL_H
