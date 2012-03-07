#include "./OGL.h"
#ifdef ALLOW_OGL2

#ifdef HX_MAXOS
  #include <OpenGL/glext.h>
#endif

namespace nme
{


class OGLProg : public GPUProg
{
public:
   OGLProg(const char *inVertProg, const char *inFragProg)
   {
      mVertProg = inVertProg;
      mFragProg = inFragProg;
      mVertId = 0;
      mFragId = 0;
      mTextureSlot = -1;
      recreate();
   }

   virtual ~OGLProg() {}


   GLuint createShader(GLuint inType, const char *inShader)
   {
      GLuint shader = glCreateShader(inType);
      glShaderSource(inType,1,&inShader,0);
      glCompileShader(shader);

      GLint compiled;
      glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
      if (compiled)
      {
         printf("Compiled shader\n");
         return shader;
      }      

      GLint blen = 0;	
      GLsizei slen = 0;

      glGetShaderiv(shader, GL_INFO_LOG_LENGTH , &blen);       
      if (blen > 1)
      {
         GLchar* compiler_log = (GLchar*)malloc(blen);
         glGetShaderInfoLog(shader, blen, &slen, compiler_log);
         printf("Error compiling shader %s\n",  compiler_log);
         free (compiler_log);
      }
      glDeleteShader(shader);
      return 0;
   }


   void recreate()
   {
      mContextVersion = gTextureContextVersion;
      mProgramId = 0;

      mVertId = createShader(GL_VERTEX_SHADER,mVertProg);
      if (!mVertId)
         return;
      mFragId = createShader(GL_FRAGMENT_SHADER,mFragProg);
      if (!mFragId)
         return;

      mProgramId = glCreateProgram();

      glAttachShader(mProgramId, mVertId);
      glAttachShader(mProgramId, mFragId);

      glLinkProgram(mProgramId); 


      // Validate program
      glValidateProgram(mProgramId);

      // Check the status of the compile/link
		int logLen = 0;
		glGetProgramiv(mProgramId, GL_INFO_LOG_LENGTH, &logLen);
      if(logLen > 0)
      {
          // Show any errors as appropriate
          char *log = new char[logLen];
          glGetProgramInfoLog(mProgramId, logLen, &logLen, log);
          printf("Prog Info Log: %s\n", log);
          delete [] log;
      }


      GLint linked;
      glGetProgramiv(mProgramId, GL_LINK_STATUS, &linked);
      if (linked)
      {
         // All good !
         printf("Linked!\n");
      }
      else
      {
         printf("Bad Linked!\n");
         glDeleteShader(mVertId);
         glDeleteShader(mFragId);
         glDeleteProgram(mProgramId);
         mVertId = mFragId = mProgramId = 0;
      }
   }

   virtual bool bind()
   {
      if (gTextureContextVersion!=mContextVersion)
         recreate();

      if (mProgramId==0)
         return false;

      glUseProgram(mProgramId);
      return true;
   }

   void setPositionData(const float *inData, bool inIsPerspective)
   {
   }

   void setTexCoordData(const float *inData)
   {
   }


   void setColourTransform(const ColorTransform *inTransform)
   {
   }

   int  getTextureSlot()
   {
      return mTextureSlot;
   }


   void setTransform(const Trans2x4 &inTrans)
   {
   }

   void setTint(unsigned int inColour)
   {
   }

   //virtual void setGradientFocus(float inFocus) = 0;

   const char *mVertProg;
   const char *mFragProg;
   GLuint     mProgramId;
   GLuint     mVertId;
   GLuint     mFragId;
   int        mContextVersion;
   int        mTextureSlot;

};

const char *gSolidVert = 
" void main(void)\n"
"{\n"
"   vec4 a = gl_Vertex;\n"
"   gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;"
"}";
const char *gColourVert = gSolidVert;
const char *gTextureVert = gSolidVert;


const char *gSolidFrag = 
"void main(void)\n"
"{\n"
"   gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);\n"
"}\n";
const char *gColourFrag = gSolidFrag;
const char *gTextureFrag = gSolidFrag;
const char *gTextureTransFrag = gSolidFrag;


GPUProg *GPUProg::create(GPUProgID inID)
{
   switch(inID)
   {
      case gpuSolid:
         return new OGLProg( gSolidVert, gSolidFrag );
      case gpuColour:
         return new OGLProg( gColourVert, gColourFrag );
      case gpuTexture:
         return new OGLProg( gTextureVert, gTextureFrag );
      case gpuTextureTransform:
         return new OGLProg( gTextureVert, gTextureTransFrag );
   }
   return 0;
}

} // end namespace nme

#else

namespace nme
{
GPUProg *GPUProg::create(GPUProgID inID) { return 0; }
}

#endif

