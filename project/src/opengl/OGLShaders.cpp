#include "./OGL.h"

#ifdef HX_MAXOS
  #include <OpenGL/glext.h>
#endif

#if defined(NME_S3D) && defined(ANDROID)
#include <S3D.h>
#include <S3DEye.h>
#endif

namespace nme
{

const float one_on_255 = 1.0/255.0;

class OGLProg : public GPUProg
{
public:
   OGLProg(const std::string &inVertProg, const std::string &inFragProg)
   {
      mVertProg = inVertProg;
      mFragProg = inFragProg;
      mVertId = 0;
      mFragId = 0;

      mImageSlot = -1;
      mColourTransform = 0;

      vertexSlot = -1;
      textureSlot = -1;
      normalSlot = -1;
      colourSlot = -1;

      //printf("%s", inVertProg.c_str());
      //printf("%s", inFragProg.c_str());

      recreate();
   }

   virtual ~OGLProg() {}


   GLuint createShader(GLuint inType, const char *inShader)
   {
      const char *source = inShader;
      GLuint shader = glCreateShader(inType);

      glShaderSource(shader,1,&source,0);
      glCompileShader(shader);

      GLint compiled = 0;
      glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
      if (compiled)
         return shader;

      GLint blen = 0;	
      GLsizei slen = 0;

      glGetShaderiv(shader, GL_INFO_LOG_LENGTH , &blen);       
      if (blen > 0)
      {
         char* compiler_log = (char*)malloc(blen);
         glGetShaderInfoLog(shader, blen, &slen, compiler_log);
         ELOG("Error compiling shader : %s\n", compiler_log);
         ELOG("%s\n", source);
         free (compiler_log);
      }
      else
      {
         ELOG("Unknown error compiling shader : \n");
		 ELOG("%s\n", source);
      }
      glDeleteShader(shader);
      return 0;
   }


   void recreate()
   {
      mContextVersion = gTextureContextVersion;
      mProgramId = 0;

      mVertId = createShader(GL_VERTEX_SHADER,mVertProg.c_str());
      if (!mVertId)
         return;
      mFragId = createShader(GL_FRAGMENT_SHADER,mFragProg.c_str());
      if (!mFragId)
         return;

      mProgramId = glCreateProgram();

      glAttachShader(mProgramId, mVertId);
      glAttachShader(mProgramId, mFragId);

      glLinkProgram(mProgramId); 


      // Validate program
      glValidateProgram(mProgramId);


      GLint linked;
      glGetProgramiv(mProgramId, GL_LINK_STATUS, &linked);
      if (linked)
      {
         // All good !
         //printf("Linked!\n");
      }
      else
      {
         ELOG("Bad Link.");
		 
		 // Check the status of the compile/link
		int logLen = 0;
		glGetProgramiv(mProgramId, GL_INFO_LOG_LENGTH, &logLen);
      if(logLen > 0)
      {
          // Show any errors as appropriate
          char *log = new char[logLen];
          glGetProgramInfoLog(mProgramId, logLen, &logLen, log);
          ELOG("----");
          ELOG("VERT: %s", mVertProg.c_str());
          ELOG("FRAG: %s", mFragProg.c_str());
          ELOG("ERROR:\n%s\n", log);
          delete [] log;
      }
	  
         glDeleteShader(mVertId);
         glDeleteShader(mFragId);
         glDeleteProgram(mProgramId);
         mVertId = mFragId = mProgramId = 0;
      }


      vertexSlot = glGetAttribLocation(mProgramId, "aVertex");
      textureSlot = glGetAttribLocation(mProgramId, "aTexCoord");
      colourSlot = glGetAttribLocation(mProgramId, "aColourArray");
      normalSlot = glGetAttribLocation(mProgramId, "aNormal");

      mTransformSlot = glGetUniformLocation(mProgramId, "uTransform");
      mImageSlot = glGetUniformLocation(mProgramId, "uImage0");
      mColourOffsetSlot = glGetUniformLocation(mProgramId, "uColourOffset");
      mColourScaleSlot = glGetUniformLocation(mProgramId, "uColourScale");
      mFXSlot = glGetUniformLocation(mProgramId, "mFX");
      mASlot = glGetUniformLocation(mProgramId, "mA");
      mOn2ASlot = glGetUniformLocation(mProgramId, "mOn2A");

      
      glUseProgram(mProgramId);
      if (mImageSlot>=0)
         glUniform1i(mImageSlot,0);
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

   void disableSlots()
   {
      if (vertexSlot>=0)
         glDisableVertexAttribArray(vertexSlot);

      if (normalSlot>=0)
         glDisableVertexAttribArray(normalSlot);

      if (colourSlot>=0)
         glDisableVertexAttribArray(colourSlot);
      
      if (textureSlot>=0)
         glDisableVertexAttribArray(textureSlot);
   }

   void setColourTransform(const ColorTransform *inTransform, uint32 inColor)
   {
      float rf, gf, bf, af;
      if (inColor==0xffffffff)
      {
         rf = gf = bf = af = 1.0;
      }
      else
      {
         rf = ( (inColor>>16) & 0xff ) * one_on_255;
         gf = ( (inColor>>8 ) & 0xff ) * one_on_255;
         bf = ( (inColor    ) & 0xff ) * one_on_255;
         af = ( (inColor>>24) & 0xff ) * one_on_255;
      }

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
                      inTransform->redMultiplier * rf,
                      inTransform->greenMultiplier * gf,
                      inTransform->blueMultiplier * bf,
                      inTransform->alphaMultiplier * af);
      }
      else
      {
         if (mColourOffsetSlot>=0)
            glUniform4f(mColourOffsetSlot,0,0,0,0);

         if (mColourScaleSlot>=0)
         {
            glUniform4f(mColourScaleSlot,rf,gf,bf,af);
         }
      }
   }

   int  getTextureSlot()
   {
      return mImageSlot;
   }


   void setTransform(const Trans4x4 &inTrans)
   {
      glUniformMatrix4fv(mTransformSlot, 1, 0, inTrans[0]);
   }

   virtual void setGradientFocus(float inFocus)
   {
      if (mASlot>=0)
      {
	      double fx = inFocus;
			if (fx < -0.99) fx = -0.99;
			else if (fx > 0.99) fx = 0.99;
			
			// mFY = 0;	mFY can be set to zero, since rotating the matrix
			//  can also compensate for this.
			
			double a = (fx * fx - 1.0);
			double on2a = 1.0 / (2.0 * a);
			a *= 4.0;
         glUniform1f(mASlot,a);
         glUniform1f(mFXSlot,fx);
         glUniform1f(mOn2ASlot,on2a);
      }
   }

   std::string mVertProg;
   std::string mFragProg;
   GLuint     mProgramId;
   GLuint     mVertId;
   GLuint     mFragId;
   int        mContextVersion;
   const ColorTransform *mColourTransform;


   // int vertexSlot;
   // int textureSlot;
   // int normalSlot;
   // int colourSlot;

   GLint     mImageSlot;
   GLint     mColourArraySlot;
   GLint     mColourScaleSlot;
   GLint     mColourOffsetSlot;
   GLint     mTransformSlot;
   GLint     mASlot;
   GLint     mFXSlot;
   GLint     mOn2ASlot;
};

GPUProg *GPUProg::create(unsigned int inID)
{
   std::string vertexVars =
      "uniform mat4   uTransform;\n"
      "attribute vec4 aVertex;\n";
   std::string vertexProg =
      "   gl_Position = aVertex * uTransform;\n";
   std::string pixelVars = "";
   std::string pixelProlog = "";

   #ifdef NME_GLES
   pixelVars = std::string("precision mediump float;\n");
   #endif



   std::string fragColour = "";
   if (inID & PROG_TINT)
   {
      pixelVars += "uniform vec4 uColourScale;\n";
      fragColour = "uColourScale";
   }

   if (inID & PROG_COLOUR_OFFSET)
   {
       pixelVars += "uniform vec4 uColourOffset;\n";
   }


   if (inID & PROG_COLOUR_PER_VERTEX)
   {
      vertexVars +=
        "attribute vec4 aColourArray;\n"
        "varying vec4 vColourArray;\n";
      vertexProg =
        "   vColourArray = aColourArray;\n" + vertexProg;
      pixelVars +=
        "varying vec4 vColourArray;\n";

      if (fragColour!="")
         fragColour += "*";
      fragColour += "vColourArray";
   }


   if (inID & PROG_TEXTURE)
   {
      vertexVars +=
        "attribute vec2 aTexCoord;\n"
        "varying vec2 vTexCoord;\n";

      vertexProg =
        "   vTexCoord = aTexCoord;\n" + vertexProg;

      pixelVars +=
        "uniform sampler2D uImage0;\n"
        "varying vec2 vTexCoord;\n";

      if (!(inID & PROG_RADIAL))
      {
         if (fragColour!="")
            fragColour += "*";

         if (inID & PROG_ALPHA_TEXTURE)
            fragColour += "vec4(1,1,1,texture2D(uImage0,vTexCoord).a)";
         else
            fragColour += "texture2D(uImage0,vTexCoord)";
      }
   }

   if (inID & PROG_RADIAL)
   {
      if (inID & PROG_RADIAL_FOCUS)
      {
         pixelVars +=
            "uniform float mA;\n"
            "uniform float mFX;\n"
            "uniform float mOn2A;\n";

         pixelProlog = 
            "   float GX = vTexCoord.x - mFX;\n"
            "   float C = GX*GX + vTexCoord.y*vTexCoord.y;\n"
            "   float B = 2.0*GX * mFX;\n"
            "   float det =B*B - mA*C;\n"
            "   float rad;\n"
            "   if (det<0.0)\n"
            "      rad = -B * mOn2A;\n"
            "   else\n"
            "      rad = (-B - sqrt(det)) * mOn2A;\n";
      }
      else
      {
         pixelProlog = 
             "   float rad = sqrt(vTexCoord.x*vTexCoord.x + vTexCoord.y*vTexCoord.y);\n";
      }

      if (fragColour!="")
         fragColour += "*";
      fragColour += "texture2D(uImage0,vec2(rad,0))";
   }


   if (inID & PROG_NORMAL_DATA)
   {
      vertexVars +=
        "attribute vec2 aNormal;\n"
        "varying vec2 vNormal;\n";

      vertexProg =
        "   vNormal = aNormal;\n" + vertexProg;

      pixelVars +=
        "varying vec2 vNormal;\n";
   }

   std::string vertexShader = 
      vertexVars + 
      "void main()\n"
      "{\n" +
         vertexProg +
      "}\n";

   if (fragColour=="")
      fragColour = "vec4(1,1,1,1)";

   if ( inID & PROG_COLOUR_OFFSET )
      fragColour = fragColour + "+ uColourOffset";

   if ( inID & PROG_NORMAL_DATA )
   {
      fragColour = "(" + fragColour + ") * vec4(1,1,1, min(vNormal.x-abs(vNormal.y),1.0) )";
   }
 

   std::string pixelShader =
      pixelVars +
      "void main()\n"
      "{\n" +
         pixelProlog +
         "   gl_FragColor = " + fragColour + ";\n" +
      "}\n";

   return new OGLProg(vertexShader, pixelShader);
}


#ifdef NME_S3D

class OpenGLS3D
{
public:
   
   OpenGLS3D()
   {
      mFocalLength = 0.5;
      mEyeSeparation = 0.01;

      mCurrentEye = EYE_MIDDLE;
   }
   
   ~OpenGLS3D()
   {
      glDeleteRenderbuffers(1, &mRenderbuffer);
      glDeleteFramebuffers(1, &mFramebuffer);
      glDeleteTextures(1, &mLeftEyeTexture);
      glDeleteTextures(1, &mRightEyeTexture);
      glDeleteTextures(1, &mEyeMaskTexture);
      glDeleteBuffers(1, &mS3DVertexBuffer);
      glDeleteBuffers(1, &mS3DTextureBuffer);
      delete mS3DProgram;
   }

   void Init()
   {
      // TODO: renderbuffer is only needed when using depth buffer
      glGenRenderbuffers(1, &mRenderbuffer);

      glGenFramebuffers(1, &mFramebuffer);
      glGenBuffers(1, &mS3DVertexBuffer);
      glGenBuffers(1, &mS3DTextureBuffer);

      mCurrentEye = EYE_MIDDLE;
      mLeftEyeTexture = mRightEyeTexture = mEyeMaskTexture = 0;

      mS3DProgram = new OGLProg(
         /* vertex */
         "attribute vec3 aVertex;\n"
         "attribute vec2 aTexCoord;\n"
         "varying vec2 vTexCoord;\n"
         "uniform mat4 uTransform;"
         "\n"
         "void main (void) {\n"
         "  vTexCoord = aTexCoord;\n"
         "  gl_Position = vec4 (aVertex, 1.0) * uTransform;\n"
         "}\n"
         ,

         /* fragment */
         #if defined (NME_GLES)
         // TODO: highp precision is required for screens above a certain
         // dimension, however, GLES doesn't guarantee highp support in fragment
         // shaders
         "precision highp float;\n"
         "precision highp sampler2D;\n"
         #endif
         "varying vec2 vTexCoord;\n"
         "uniform sampler2D uLeft;\n"
         "uniform sampler2D uRight;\n"
         "uniform sampler2D uMask;\n"
         "\n"
         "void main (void)\n"
         "{\n"
         "  float parity = mod (gl_FragCoord.x, 2.0);\n"
         "  vec4 left = texture2D (uLeft, vTexCoord).rgba;\n"
         "  vec4 right = texture2D (uRight, vTexCoord).rgba;\n"
         "   float mask = texture2D (uMask, floor (gl_FragCoord.xy) / vec2 (2.0, 1.0)).x;\n"
         "   gl_FragColor = mix (left, right, mask);\n"
         "}\n"
      );

      mLeftImageUniform = glGetUniformLocation(mS3DProgram->mProgramId, "uLeft");
      mRightImageUniform = glGetUniformLocation(mS3DProgram->mProgramId, "uRight");
      mMaskImageUniform = glGetUniformLocation(mS3DProgram->mProgramId, "uMask");
      mPixelSizeUniform = glGetUniformLocation(mS3DProgram->mProgramId, "pixelSize");
   }
   
   void EndS3DRender(int inWidth, int inHeight, const Trans4x4 &inTrans)
   {
      mCurrentEye = EYE_MIDDLE;

      const GLfloat verts[] = 
      {
         inWidth, inHeight, 0,
         0,       inHeight, 0,
         inWidth,        0, 0,
         0,              0, 0
      };
         
      static const GLfloat textureCoords[] = 
      {
         1, 1,
         0, 1, 
         1, 0, 
         0, 0
      };

      glBindRenderbuffer(GL_RENDERBUFFER, 0);
      glBindFramebuffer(GL_FRAMEBUFFER, 0);

      // use the multiplexing shader
      mS3DProgram->bind();
      
      glClearColor(0, 0, 0, 1.0);
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

      glEnableVertexAttribArray(mS3DProgram->vertexSlot);
      glEnableVertexAttribArray(mS3DProgram->textureSlot);
      
      glBindBuffer(GL_ARRAY_BUFFER, mS3DVertexBuffer);
      glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 12, verts, GL_STATIC_DRAW);
      glVertexAttribPointer(mS3DProgram->vertexSlot, 3, GL_FLOAT, false, 0, 0);

      glBindBuffer(GL_ARRAY_BUFFER, mS3DTextureBuffer);
      glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 8, textureCoords, GL_STATIC_DRAW);
      glVertexAttribPointer(mS3DProgram->textureSlot, 2, GL_FLOAT, false, 0, 0);

      // bind left eye texture
      glActiveTexture(GL_TEXTURE0);
      glBindTexture(GL_TEXTURE_2D, mLeftEyeTexture);
      glUniform1i(mLeftImageUniform, 0);

      // bind right eye texture
      glActiveTexture(GL_TEXTURE1);
      glBindTexture(GL_TEXTURE_2D, mRightEyeTexture);
      glUniform1i(mRightImageUniform, 1);
      
      // bind eye mask
      glActiveTexture(GL_TEXTURE2);
      glBindTexture(GL_TEXTURE_2D, mEyeMaskTexture);
      glUniform1i(mMaskImageUniform, 2);

      // supply our matrices and screen info
      glUniformMatrix4fv(mS3DProgram->mTransformSlot, 1, false, (const GLfloat*) inTrans);
      
      // here's where the magic happens
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

      // glDisable (GL_TEXTURE_2D);

      // clean up
      glBindBuffer(GL_ARRAY_BUFFER, 0);
      glDisableVertexAttribArray(mS3DProgram->vertexSlot);
      glDisableVertexAttribArray(mS3DProgram->textureSlot);
      glUseProgram(0);

      glBindRenderbuffer(GL_RENDERBUFFER, 0);
      glBindFramebuffer(GL_FRAMEBUFFER, 0);

      glActiveTexture(GL_TEXTURE0);
      glBindTexture(GL_TEXTURE_2D, 0);
      
      glActiveTexture(GL_TEXTURE1);
      glBindTexture(GL_TEXTURE_2D, 0);
      
      glActiveTexture(GL_TEXTURE2);
      glBindTexture(GL_TEXTURE_2D, 0);
   }
   
   void SetS3DEye(int eye)
   {
      if (eye == EYE_MIDDLE)
      {
         return;
      }

      mCurrentEye = eye;

      GLint texture = mRightEyeTexture;
      if (eye == EYE_LEFT)
      {
         texture = mLeftEyeTexture;
      }

      glActiveTexture(GL_TEXTURE0);

      // TODO: no need to bind 0 texture here, right?
      glBindTexture(GL_TEXTURE_2D, 0);

      glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
      glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
      glBindTexture(GL_TEXTURE_2D, texture);

      glFramebufferTexture2D(
         GL_FRAMEBUFFER,
         GL_COLOR_ATTACHMENT0,
         GL_TEXTURE_2D, texture, 0);
      
      glClearColor(0, 0, 0, 1.0);
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
   }
   
   void Resize(int inWidth, int inHeight)
   {
      if (mLeftEyeTexture != 0)
      {
         glDeleteTextures(1, &mLeftEyeTexture);
         glDeleteTextures(1, &mRightEyeTexture);
         glDeleteTextures(1, &mEyeMaskTexture);
      }

      int texWidth = inWidth; // UpToPower2 (inWidth);
      int texHeight = inHeight; // UpToPower2 (inHeight);

      glGenTextures(1, &mLeftEyeTexture);
      glBindTexture(GL_TEXTURE_2D, mLeftEyeTexture);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
      glBindTexture(GL_TEXTURE_2D, 0);

      glGenTextures(1, &mRightEyeTexture);
      glBindTexture(GL_TEXTURE_2D, mRightEyeTexture);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
      glBindTexture(GL_TEXTURE_2D, 0);

      GLubyte maskData[] = {
         0, 0xFF,
         0, 0xFF
      };

      glGenTextures(1, &mEyeMaskTexture);
      glBindTexture(GL_TEXTURE_2D, mEyeMaskTexture);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 2, 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, maskData);
      glBindTexture(GL_TEXTURE_2D, 0);

      // create depth buffer
      glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
      glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, inWidth, inHeight);
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mRenderbuffer);

      glBindRenderbuffer(GL_RENDERBUFFER, 0);
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
   }
   
   void FocusEye(Trans4x4 &outTrans)
   {
      if (mCurrentEye != EYE_MIDDLE)
      {
         float offset = GetEyeOffset();
         float theta = asin(offset/mFocalLength);

         float m = sin(theta);
         float n = cos(theta);

         float a = outTrans[0][0];
         float b = outTrans[0][1];
         float c = outTrans[1][0];
         float d = outTrans[1][1];
         float tx = outTrans[0][3];
         float ty = outTrans[1][3];
         float tz = outTrans[2][3];
         
         outTrans[0][0] = (a*n);
         outTrans[0][1] = (b*n);
         outTrans[0][2] = m;
         outTrans[0][3] = (n*tx + m*-tz);
         
         outTrans[1][0] = c;
         outTrans[1][1] = d;
         outTrans[1][2] = 0;
         outTrans[1][3] = ty;

         outTrans[2][0] = -a*m;
         outTrans[2][1] = -b*m;
         outTrans[2][2] = -n;
         outTrans[2][3] = -(n*-tz-m*tx);
      }
   }
   
   double GetEyeOffset()
   {
      if (mCurrentEye == EYE_MIDDLE)
      {
         return 0;
      }
      else if (mCurrentEye == EYE_LEFT)
      {
         return -1 * mEyeSeparation;
      }
      return mEyeSeparation;
   }

   double mFocalLength;
   double mEyeSeparation;

private:
   int mWidth;
   int mHeight;

   int mCurrentEye;
   OGLProg *mS3DProgram;
   GLuint mFramebuffer;
   GLuint mRenderbuffer;
   GLuint mLeftEyeTexture;
   GLuint mRightEyeTexture;
   GLuint mEyeMaskTexture;
   GLint mLeftImageUniform;
   GLint mRightImageUniform;
   GLint mMaskImageUniform;
   GLint mPixelSizeUniform;
   GLint mScreenUniform;
   GLuint mS3DVertexBuffer;
   GLuint mS3DTextureBuffer;
};

#endif


} // end namespace nme


