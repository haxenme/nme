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
         GLchar* compiler_log = (GLchar*)malloc(blen);
         glGetShaderInfoLog(shader, blen, &slen, compiler_log);
         printf("Error compiling shader : %s\n", compiler_log);
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
         //printf("Linked!\n");
      }
      else
      {
         printf("Bad Linked!\n");
         glDeleteShader(mVertId);
         glDeleteShader(mFragId);
         glDeleteProgram(mProgramId);
         mVertId = mFragId = mProgramId = 0;
      }

      mPositionSlot = glGetAttribLocation(mProgramId, "glPosition");
      mTransformSlot = glGetUniformLocation(mProgramId, "uTransform");
      //printf("mTransformSlot %d\n", mTransformSlot);
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
      glVertexAttribPointer(mPositionSlot, inIsPerspective ? 2 : 0 , GL_FLOAT, GL_FALSE, 0, inData);
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
   }

   void setColourTransform(const ColorTransform *inTransform)
   {
      if (inTransform)
      {
          glUniform4f(mColourOffsetSlot, 1.0f, 1.0f, 1.0f, 1.0f);
          glUniform4f(mColourOffsetScale, 1.0f, 0.0f, 0.0f,1);
         //glColor4f( inTransform->redMultiplier,
         //           inTransform->greenMultiplier,
         //           inTransform->blueMultiplier,
         //           inTransform->alphaMultiplier);
      }
   }

   int  getTextureSlot()
   {
      return mTextureSlot;
   }


   void setTransform(const Trans4x4 &inTrans)
   {
      /*
      for(int j=0;j<4;j++)
      {
         for(int i=0;i<4;i++)
            printf("%.3f ", inTrans[j][i] );
         printf("\n");
      }
      printf("\n");
      */
      glUniformMatrix4fv(mTransformSlot, 1, 0, inTrans[0]);
    
      //Trans4x4 test;
      //for(int i=0;i<4;i++)
         //for(int j=0;j<4;j++)
            //test[i][j] = (i==j) ? (i<3 ? 0.01 : 1 ) : 0;
      //glUniformMatrix4fv(mTransformSlot, 1, true, test[0]);
   }

   void setTint(unsigned int inColour)
   {
      glUniform4f(mTintSlot, 1.0f, 0.0f, 0.0f,1);
   }

   //virtual void setGradientFocus(float inFocus) = 0;

   const char *mVertProg;
   const char *mFragProg;
   GLuint     mProgramId;
   GLuint     mVertId;
   GLuint     mFragId;
   int        mContextVersion;

   int        mTextureSlot;

   GLuint     mPositionSlot;
   GLuint     mColourOffsetScale;
   GLuint     mColourOffsetSlot;
   GLuint     mTransformSlot;
   GLuint     mTintSlot;
};

const char *gSolidVert = 
"uniform mat4 uTransform;\n"
"void main(void)\n"
"{\n"
"   gl_Position = gl_Vertex * uTransform;\n"
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

