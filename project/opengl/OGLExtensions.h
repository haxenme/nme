
#ifdef HX_WINDOWS
#define CALLING_CONVENTION APIENTRY
#else
#define CALLING_CONVENTION APIENTRY
#endif


#ifdef DECLARE_EXTENSION

#define OGL_EXT(func,ret,args) \
   extern ret (CALLING_CONVENTION *func)args;

#elif defined(DEFINE_EXTENSION)

#define OGL_EXT(func,ret,args) \
   ret (CALLING_CONVENTION *func)args=0;

#elif defined(GET_EXTENSION)

#ifdef HX_WINDOWS
#define OGL_EXT(func,ret,args) \
{\
   *(void **)&func = (void *)wglGetProcAddress(#func);\
   if (!func) \
      *(void **)&func = (void *)wglGetProcAddress(#func "ARB");\
}
#endif


#endif

OGL_EXT(glBindBuffer,void,(GLenum,GLuint))
OGL_EXT(glDeleteBuffers,void,(GLsizei,const GLuint *))
OGL_EXT(glGenBuffers,void,(GLsizei,GLuint*))
OGL_EXT(glBufferData,void,(GLenum,GLuint,const void *, GLenum))
OGL_EXT(glCreateShader,GLuint,(GLenum))
OGL_EXT(glGetUniformLocation,GLint,(GLuint,const char *))
OGL_EXT(glUniform4f,void,(GLint,float,float,float,float))
OGL_EXT(glUniformMatrix2fv,void,(GLint,GLsizei,GLboolean,const float *))
OGL_EXT(glUniformMatrix3fv,void,(GLint,GLsizei,GLboolean,const float *))
OGL_EXT(glUniformMatrix4fv,void,(GLint,GLsizei,GLboolean,const float *))
OGL_EXT(glDeleteShader,void,(GLint))
OGL_EXT(glDeleteProgram,void,(GLint))
OGL_EXT(glGetAttribLocation,GLint,(GLuint,const char *))
OGL_EXT(glShaderSource,void,(GLuint,GLsizei,const char **, const GLint *))
OGL_EXT(glDisableVertexAttribArray,void,(GLuint))
OGL_EXT(glEnableVertexAttribArray,void,(GLuint))
OGL_EXT(glAttachShader,void,(GLuint,GLuint))
OGL_EXT(glCreateProgram,GLuint,())
OGL_EXT(glCompileShader,void,(GLuint))
OGL_EXT(glLinkProgram,void,(GLuint))
OGL_EXT(glGetShaderiv,void,(GLuint,GLenum,GLint *))
OGL_EXT(glValidateProgram,void,(GLuint))
OGL_EXT(glGetShaderInfoLog,void,(GLuint,GLsizei,GLsizei *,char *))
OGL_EXT(glGetProgramiv,void,(GLuint,GLenum,GLint *))
OGL_EXT(glGetProgramInfoLog,void,(GLuint,GLsizei,GLsizei *,char *))
OGL_EXT(glUseProgram,void,(GLuint))
OGL_EXT(glUniform1i,void,(GLuint,GLint))
OGL_EXT(glVertexAttribPointer,void,(GLuint,GLint,GLenum,GLboolean,GLsizei,const void *))
OGL_EXT(glActiveTexture,void,(GLenum))

#undef OGL_EXT
#undef CALLING_CONVENTION

