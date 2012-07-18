#include "./OGL.h"
#ifdef ALLOW_OGL2

#ifdef HX_MAXOS
  #include <OpenGL/glext.h>
#endif

namespace nme
{

const float one_on_255 = 1.0/255.0;

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
      mColourTransform = 0;
      recreate();
   }

   virtual ~OGLProg() {}


   GLuint createShader(GLuint inType, const char *inShader)
   {
      GLuint shader = glCreateShader(inType);
      glShaderSource(shader,1,&inShader,0);
      glCompileShader(shader);

      GLint compiled = 0;
      glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
      if (compiled)
         return shader;

      GLint blen = 0;	
      GLsizei slen = 0;

      glGetShaderiv(shader, GL_INFO_LOG_LENGTH , &blen);       
      if (blen > 1)
      {
         char* compiler_log = (char*)malloc(blen);
         glGetShaderInfoLog(shader, blen, &slen, compiler_log);
         printf("Error compiling shader : %s\n", compiler_log);
         printf("%s\n", inShader);
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
          printf("----\n");
          printf("VERT: %s\n", mVertProg);
          printf("FRAG: %s\n", mFragProg);
          printf("ERROR:\n%s\n\n", mVertProg);
          delete [] log;
      }


      GLint linked;
      glGetProgramiv(mProgramId, GL_LINK_STATUS, &linked);
      if (linked)
      {
         // All good !
         //printf("Linked!\n");
      }
      else
      {
         printf("Bad Link.\n");
         glDeleteShader(mVertId);
         glDeleteShader(mFragId);
         glDeleteProgram(mProgramId);
         mVertId = mFragId = mProgramId = 0;
      }


      mPositionSlot = glGetAttribLocation(mProgramId, "glPosition");
      mTransformSlot = glGetUniformLocation(mProgramId, "uTransform");
      mTintSlot = glGetUniformLocation(mProgramId, "uTint");
      mColourArraySlot = glGetAttribLocation(mProgramId, "aColourArray");
      mTextureSlot = glGetUniformLocation(mProgramId, "uImage0");
      mColourOffsetSlot = glGetUniformLocation(mProgramId, "uColourOffset");
      mColourScaleSlot = glGetUniformLocation(mProgramId, "uColourScale");
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
      #ifdef NME_GLES
      glVertexAttribPointer(mPositionSlot, inIsPerspective ? 4 : 2 , GL_FLOAT, GL_FALSE, 0, inData);
      #else
      glVertexPointer(inIsPerspective ? 4 : 2,GL_FLOAT,0,inData);
      #endif
   }

   void setTexCoordData(const float *inData)
   {
      if (inData)
      {
         #ifdef NME_GLES
         //glEnableVertexAttribArray
         #else
         glEnable(GL_TEXTURE_2D);
         glEnableClientState(GL_TEXTURE_COORD_ARRAY);
         glTexCoordPointer(2, GL_FLOAT, 0, inData);
         glUniform1i(mTextureSlot,0);
         #endif
      }
      else
      {
         #ifdef NME_GLES
         #else
         glDisable(GL_TEXTURE_2D);
         glDisableClientState(GL_TEXTURE_COORD_ARRAY);
         #endif
      }
   }

   void setColourData(const int *inData)
   {
      if (inData && mColourArraySlot>=0)
      {
         glVertexAttribPointer(mColourArraySlot, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, inData);
         glEnableVertexAttribArray(mColourArraySlot);
      }
      else if (mColourArraySlot>=0)
      {
         glDisableVertexAttribArray(mColourArraySlot);
      }
   }

   void finishDrawing()
   {
      if (mColourArraySlot>=0)
      {
         glDisableVertexAttribArray(mColourArraySlot);
      }
   }

   void setColourTransform(const ColorTransform *inTransform)
   {
      mColourTransform = inTransform;
      if (inTransform && !inTransform->IsIdentity())
      {
          if (mColourOffsetSlot>=0)
             glUniform4f(mColourOffsetSlot,
                      inTransform->redOffset*one_on_255,
                      inTransform->greenOffset*one_on_255,
                      inTransform->blueOffset*one_on_255,
                      inTransform->alphaOffset*one_on_255);
          if (mColourScaleSlot>=0)
             glUniform4f(mColourScaleSlot,
                      inTransform->redMultiplier,
                      inTransform->greenMultiplier,
                      inTransform->blueMultiplier,
                      inTransform->alphaMultiplier);
          /*
             printf("offset %d = %f %f %f %f\n",mColourOffsetSlot,
                      inTransform->redOffset,
                      inTransform->greenOffset,
                      inTransform->blueOffset,
                      inTransform->alphaOffset);
             printf("scale %d = %f %f %f %f\n",mColourScaleSlot,
                      inTransform->redMultiplier,
                      inTransform->greenMultiplier,
                      inTransform->blueMultiplier,
                      inTransform->alphaMultiplier);
          */
      }
      else
      {
         if (mColourOffsetSlot>=0)
            glUniform4f(mColourOffsetSlot,0,0,0,0);
         if (mColourScaleSlot>=0)
            glUniform4f(mColourScaleSlot,1,1,1,1);
      }
   }

   int  getTextureSlot()
   {
      return mTextureSlot;
   }


   void setTransform(const Trans4x4 &inTrans)
   {
      glUniformMatrix4fv(mTransformSlot, 1, 0, inTrans[0]);
   }

   void setTint(unsigned int inColour)
   {
      if (mTintSlot>=0)
         glUniform4f(mTintSlot, ((inColour >> 16) & 0xff) * one_on_255,
                                ((inColour >> 8) & 0xff) * one_on_255,
                                ((inColour) & 0xff) * one_on_255,
                                ((inColour >> 24) & 0xff) * one_on_255 );
   }

   //virtual void setGradientFocus(float inFocus) = 0;

   const char *mVertProg;
   const char *mFragProg;
   GLuint     mProgramId;
   GLuint     mVertId;
   GLuint     mFragId;
   int        mContextVersion;
   const ColorTransform *mColourTransform;

   GLint     mTextureSlot;
   GLint     mTexCoordSlot;

   GLint     mPositionSlot;
   GLint     mColourArraySlot;
   GLint     mColourScaleSlot;
   GLint     mColourOffsetSlot;
   GLint     mTransformSlot;
   GLint     mTintSlot;
};

const char *gSolidVert = 
"uniform mat4 uTransform;\n"
"void main(void)\n"
"{\n"
"   gl_Position = gl_Vertex * uTransform;\n"
"}";

const char *gColourVert =
"uniform mat4 uTransform;\n"
"attribute vec4 aColourArray;\n"
"varying vec4 vColourArray;\n"
"void main(void)\n"
"{\n"
"   vColourArray = aColourArray;\n"
"   gl_Position = gl_Vertex * uTransform;\n"
"}";


const char *gTextureVert =
"uniform mat4 uTransform;\n"
"varying vec2 vTexCoord;\n"
"void main(void)\n"
"{\n"
"   vTexCoord = gl_MultiTexCoord0.xy;\n"
"   gl_Position = gl_Vertex * uTransform;\n"
"}";


const char *gTextureColourVert =
"uniform mat4 uTransform;\n"
"varying vec2 vTexCoord;\n"
"attribute vec4 aColourArray;\n"
"varying vec4 vColourArray;\n"
"void main(void)\n"
"{\n"
"   vColourArray = aColourArray;\n"
"   vTexCoord = gl_MultiTexCoord0.xy;\n"
"   gl_Position = gl_Vertex * uTransform;\n"
"}";



const char *gSolidFrag = 
"uniform vec4 uTint;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor = uTint;\n"
"}\n";

const char *gColourFrag =
"varying vec4 vColourArray;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor = vColourArray;\n"
"}\n";


const char *gColourTransFrag =
"varying vec4 vColourArray;\n"
"uniform vec4 uColourScale;\n"
"uniform vec4 uColourOffset;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor = vColourArray*uColourScale+uColourOffset;\n"
"}\n";



const char *gBitmapAlphaFrag =
"varying vec2 vTexCoord;\n"
"uniform sampler2D uImage0;\n"
"uniform vec4 uTint;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor.rgb = uTint.rgb;\n"
"   gl_FragColor.a  = texture2D(uImage0,vTexCoord).a;\n"
"}\n";


const char *gBitmapFrag =
"varying vec2 vTexCoord;\n"
"uniform sampler2D uImage0;\n"
"uniform vec4 uTint;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor  = texture2D(uImage0,vTexCoord)*uTint;\n"
"}\n";


const char *gTextureFrag =
"varying vec2 vTexCoord;\n"
"uniform sampler2D uImage0;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor = texture2D(uImage0,vTexCoord);\n"
"}\n";


const char *gRadialTextureFrag =
"varying vec2 vTexCoord;\n"
"uniform sampler2D uImage0;\n"
"void main(void)\n"
"{\n"
"   float rad = sqrt(vTexCoord.x*vTexCoord.x + vTexCoord.y*vTexCoord.y);\n"
"   gl_FragColor = texture2D(uImage0,vec2(rad,0));\n"
"}\n";


const char *gTextureColourFrag =
"uniform sampler2D uImage0;\n"
"varying vec2 vTexCoord;\n"
"varying vec4 vColourArray;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor = texture2D(uImage0,vTexCoord) * vColourArray;\n"
"}\n";



const char *gTextureTransFrag =
"varying vec2 vTexCoord;\n"
"uniform sampler2D uImage0;\n"
"uniform vec4 uColourScale;\n"
"uniform vec4 uColourOffset;\n"
"void main(void)\n"
"{\n"
"   gl_FragColor = texture2D(uImage0,vTexCoord) * uColourScale + uColourOffset;\n"
"}\n";




GPUProg *GPUProg::create(GPUProgID inID)
{
   switch(inID)
   {
      case gpuSolid:
         return new OGLProg( gSolidVert, gSolidFrag );
      case gpuColourTransform:
         return new OGLProg( gColourVert, gColourTransFrag );
      case gpuColour:
         return new OGLProg( gColourVert, gColourFrag );
      case gpuRadialGradient:
         return new OGLProg( gTextureVert, gRadialTextureFrag );
      case gpuTexture:
         return new OGLProg( gTextureVert, gTextureFrag );
      case gpuTextureColourArray:
         return new OGLProg( gTextureColourVert, gTextureColourFrag );
      case gpuTextureTransform:
         return new OGLProg( gTextureVert, gTextureTransFrag );
      case gpuBitmap:
         return new OGLProg( gTextureVert, gBitmapFrag );
      case gpuBitmapAlpha:
         return new OGLProg( gTextureVert, gBitmapAlphaFrag );
      default:
        break;
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

