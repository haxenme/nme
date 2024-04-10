#ifndef OGL_SHADERS_H
#define OGL_SHADERS_H


#include "./OGL.h"


namespace nme
{


class OGLProg : public GPUProg
{
public:
  
   OGLProg(const std::string &inVertProg, const std::string &inFragProg, int inProgFlags);
   virtual ~OGLProg();

   GLuint createShader(GLuint inType, const char *inShader);
   void recreate();
   virtual bool bind();
   void disableSlots();
   void setColourTransform(const ColorTransform *inTransform, uint32 inColor, bool inPremAlpha);
   int  getTextureSlot();
   void setTransform(const Trans4x4 &inTrans);
   virtual void setGradientFocus(float inFocus);
   void setNormScale(float inScale);

   std::string mVertProg;
   std::string mFragProg;
   GLuint     mProgramId;
   GLuint     mVertId;
   GLuint     mFragId;
   int        mContextVersion;
   const ColorTransform *mColourTransform;


   GLint     mImageSlot;
   GLint     mColourArraySlot;
   GLint     mColourScaleSlot;
   GLint     mColourOffsetSlot;
   GLint     mTransformSlot;
   GLint     mASlot;
   GLint     mFXSlot;
   GLint     mOn2ASlot;
   int       programFlags;
};



} // end namespace nme


#endif
