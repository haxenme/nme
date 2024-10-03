#ifndef NME_HARDWARE_H
#define NME_HARDWARE_H

#include "Graphics.h"

#if defined(GCW0)
#define NME_FLOAT32_VERT_VALUES
#endif

namespace nme
{

#if NME_OGL
  #ifdef NME_METAL
     extern bool nmeOpenglRenderer;
  #else
     const bool nmeOpenglRenderer = true;
  #endif
#else
   const bool nmeOpenglRenderer = false;
#endif



void ResetHardwareContext();

typedef QuickVec<UserPoint>   Vertices;

enum PrimType { ptTriangleFan, ptTriangleStrip, ptTriangles, ptLineStrip, ptPoints, ptLines, ptQuads, ptQuadsFull };

enum
{
   DRAW_HAS_COLOUR      = 0x0001,
   DRAW_HAS_NORMAL      = 0x0002,
   DRAW_HAS_PERSPECTIVE = 0x0004,
   DRAW_RADIAL          = 0x0008,

   DRAW_HAS_TEX         = 0x0010,
   DRAW_BMP_REPEAT      = 0x0020,
   DRAW_BMP_SMOOTH      = 0x0040,
   
   DRAW_TILE_MOUSE      = 0x0080,
   DRAW_EDGE_DIST       = 0x0100,
};



struct DrawElement
{
   unsigned short mFlags;
   short        mRadialPos;
   uint8        mPrimType;
   uint8        mBlendMode;
   uint8        mScaleMode;

   uint8        mStride;
   int          mCount;

   int          mVertexOffset;
   int          mTexOffset;
   int          mColourOffset;
   int          mNormalOffset;

   uint32       mColour;
   Surface      *mSurface;

   // For  ptLineStrip/ptLines
   float    mWidth;

};

typedef QuickVec<DrawElement> DrawElements;

class HardwareData
{
public:
   HardwareData();
   ~HardwareData();

   void            releaseVbo();
   float           scaleOf(const RenderState &inState) const;
   bool            isScaleOk(const RenderState &inState) const;
   void            clear();

   DrawElements    mElements;
   QuickVec<uint8> mArray;
   float           mMinScale;
   float           mMaxScale;

   mutable class HardwareRenderer *mVboOwner;
   mutable int             mRendersWithoutVbo;
   mutable int             mContextId;
   union
   {
      mutable unsigned int mVertexBo;
      mutable void         *mVertexBufferPtr;
   };
};


void NmeClipOutline(Vertices &ioOutline,QuickVec<int> &ioSubPolys, WindingRule inWinding);
bool ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys,WindingRule inWinding);

class HardwareContext : public Object
{
protected:
   ~HardwareContext() {}
public:
   virtual bool IsOpenGL() const = 0;
   virtual class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags)=0;
   NmeObjectType getObjectType() { return notHardwareContext; }

};



typedef float Trans4x4[4][4];

class HardwareRenderer : public HardwareContext
{
protected:
   int mWidth,mHeight;
   Matrix mModelView;
   Trans4x4 mTrans;

   double mScaleX;
   double mScaleY;
   double mOffsetX;
   double mOffsetY;
   double mLineWidth;

   double mLineScaleV;
   double mLineScaleH;
   double mLineScaleNormal;
   StageQuality mQuality;

   Rect mViewport;

public:
   HardwareRenderer();

   static HardwareRenderer *current;

   static HardwareRenderer *CreateMetal(void *inMetalLayer);
   static HardwareRenderer *CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders);
   static HardwareRenderer *CreateDX11(void *inDevice, void *inContext);

   virtual void OnContextLost() = 0;

   // Could be common to multiple implementations...
   virtual bool Hits(const RenderState &inState, const HardwareData &inData );
   void setOrtho(float x0,float x1, float y0, float y1);
   void CombineModelView(const Matrix &inModelView);

   virtual void SetWindowSize(int inWidth,int inHeight);
   virtual void SetQuality(StageQuality inQuality);
   virtual int Width() const;
   virtual int Height() const;

   virtual void BeginRender(const Rect &inRect,bool inForHitTest)=0;
   virtual void EndRender()=0;
   virtual void SetViewport(const Rect &inRect)=0;
   virtual void Clear(uint32 inColour,const Rect *inRect=0) = 0;
   virtual void Flip() = 0;

   virtual bool supportsComponentAlpha() const = 0;


   virtual void Render(const RenderState &inState, const HardwareData &inData );
   virtual void RenderData(const HardwareData &inData, const ColorTransform *ctrans,const Trans4x4 &inTrans)=0;

   virtual void BeginDirectRender(const Rect &inRect)=0;
   virtual void EndDirectRender()=0;


   virtual void DestroyNativeTexture(void *inNativeTexture) { }
   virtual void DestroyTexture(unsigned int inTex) { }
   virtual void DestroyVbo(unsigned int inVbo, void *inVboPtr) { }
   virtual void DestroyProgram(unsigned int inProg) { }
   virtual void DestroyShader(unsigned int inShader) { }
   virtual void DestroyFramebuffer(unsigned int inBuffer) { }
   virtual void DestroyRenderbuffer(unsigned int inBuffer) { }
   virtual void DestroyQuery(unsigned int inQuert) { }
   virtual void DestroyVertexArray(unsigned int inVertexArray) { }
   virtual void DestroyTransformFeedback(unsigned int inTransformFeedback) { }

};

extern HardwareRenderer *gDirectRenderContext;
extern int gDirectMaxAttribArray;

void BuildHardwareJob(const class GraphicsJob &inJob,const GraphicsPath &inPath,
                      HardwareData &ioData, HardwareRenderer &inHardware,const RenderState &inState);



} // end namespace nme

#endif
