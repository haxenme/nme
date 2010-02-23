#ifndef NME_GRAPHICS_H
#define NME_GRAPHICS_H

#include <Object.h>
#include <QuickVec.h>
#include <Matrix.h>
#include <Scale9.h>
#include <Pixel.h>

typedef unsigned int uint32;
typedef unsigned char uint8;

namespace nme
{

enum GraphicsAPIType { gatBase, gatInternal,  gatQuartz, gatCairo, gatOpenGL, gatOpenGLES };

// enum SurfaceAPIType  { satInternal, satSDL, satCairo };


// --- Graphics Data -------------------------------------------------------

// These classes match the flash API very closely...
class GraphicsEndFill;
class GraphicsSolidFill;
class GraphicsGradientFill;
class GraphicsBitmapFill;

class GraphicsPath;
class GraphicsTrianglePath;

class GraphicsStroke;

class Surface;

// Don't know if these belong in the c++ level?
class IGraphicsFill;
class IGraphicsPath;
class IGraphicsStroke;


enum GraphicsDataType
{
   gdtUnknown, gdtEndFill, gdtSolidFill, gdtGradientFill, gdtBitmapFill,
   gdtPath, gdtTrianglePath, gdtStroke
};


class IGraphicsData : public Object
{
public:
   IGraphicsData() { };

   IGraphicsData *IncRef() { mRefCount++; return this; }

   virtual GraphicsDataType GetType() { return gdtUnknown; }
   virtual GraphicsAPIType  GetAPI() { return gatBase; }

   virtual IGraphicsFill   *AsIFill() { return 0; }
   virtual IGraphicsPath   *AsIPath() { return 0; }
   virtual IGraphicsStroke   *AsIStroke() { return 0; }

   virtual GraphicsEndFill      *AsEndFill() { return 0; }
   virtual GraphicsSolidFill    *AsSolidFill() { return 0; }
   virtual GraphicsGradientFill *AsGradientFill() { return 0; }
   virtual GraphicsBitmapFill   *AsBitmapFill() { return 0; }

   virtual GraphicsStroke         *AsStroke() { return 0; }

   virtual GraphicsPath           *AsPath() { return 0; }
   virtual GraphicsTrianglePath   *AsTrianglePath() { return 0; }


protected:
   virtual ~IGraphicsData() { }
private:
   IGraphicsData(const IGraphicsData &inRHS);
   void operator=(const IGraphicsData &inRHS);
};


class IGraphicsFill : public IGraphicsData
{
   virtual IGraphicsFill *AsIFill() { return this; }

protected:
   virtual ~IGraphicsFill() { };
};


class GraphicsEndFill : public IGraphicsFill
{
public:
   GraphicsDataType GetType() { return gdtEndFill; }
   GraphicsEndFill   *AsEndFill() { return this; }
};

class GraphicsSolidFill : public IGraphicsFill
{
public:
   GraphicsSolidFill(int inRGB=0, float inAlpha=1) : mRGB(inRGB,inAlpha) { }
   GraphicsDataType GetType() { return gdtSolidFill; }
   GraphicsSolidFill   *AsSolidFill() { return this; }

   ARGB  mRGB;
};


struct GradStop
{
   GradStop(int inRGB=0, float inAlpha=0, float inRatio=0) :
      mARGB(inRGB, inAlpha ),
      mPos(inRatio<=0 ? 0 : inRatio>=1.0 ? 255 : inRatio*255.0 ) { }

   ARGB   mARGB;
   int    mPos;
};
typedef QuickVec<GradStop>  Stops;

enum InterpolationMethod {  imRGB, imLinearRGB };
enum SpreadMethod { smPad, smRepeat, smReflect };

class GraphicsGradientFill : public IGraphicsFill
{
public:
   GraphicsGradientFill(bool inIsLinear=true, const Matrix &inMatrix=Matrix(),
      SpreadMethod inSpread=smPad,
      InterpolationMethod inInterp=imLinearRGB, double inFocal = 0.0 ) :
         isLinear(inIsLinear), matrix(inMatrix), spreadMethod(inSpread),
         interpolationMethod(inInterp), focalPointRatio(inFocal) { } 

   void AddStop(int inRGB, float inAlpha=1, float inRatio=0)
   {
      mStops.push_back( GradStop(inRGB, inAlpha, inRatio) );
   }
   void FillArray(ARGB *outColours, bool inSwap);


   GraphicsDataType GetType() { return gdtGradientFill; }
   GraphicsGradientFill   *AsGradientFill() { return this; }

   Stops               mStops;

   double              focalPointRatio;
   Matrix              matrix;
   InterpolationMethod interpolationMethod;
   SpreadMethod        spreadMethod;
   bool                isLinear;
};


class GraphicsBitmapFill : public IGraphicsFill
{
public:
   GraphicsBitmapFill(Surface *inBitmapData, const Matrix &inMatrix, bool inRepeat, bool inSmooth);
   ~GraphicsBitmapFill();

   GraphicsDataType GetType() { return gdtBitmapFill; }
   GraphicsBitmapFill   *AsBitmapFill() { return this; }

   Surface             *bitmapData;
   Matrix              matrix;
   bool                repeat;
   bool                smooth;
};

class IGraphicsStroke : public IGraphicsData
{
public:
   IGraphicsStroke *AsIStroke() { return this; }
   virtual GraphicsDataType GetType() { return gdtStroke; }
};

enum StrokeCaps { scRound, scNone, scSquare };
enum StrokeJoints { sjRound, sjMiter, sjBevel };
enum StrokeScaleMode { ssmNormal, ssmNone, ssmVertical, ssmHorizontal };

class GraphicsStroke : public IGraphicsStroke
{
public:
   GraphicsStroke(IGraphicsFill *fill=0, double thickness=0,
                  bool pixelHinting = false, StrokeScaleMode saleMode = ssmNormal,
                  StrokeCaps caps = scRound,
                  StrokeJoints joints = sjBevel, double miterLimit= 3.0);

   ~GraphicsStroke();

   GraphicsStroke *AsStroke() { return this; }

   bool IsClear() { return false; }

   StrokeCaps      caps;
   IGraphicsFill   *fill;
   StrokeJoints    joints;
   double          miterLimit;
   bool            pixelHinting;
   StrokeScaleMode scaleMode;
   double          thickness;
};


class IGraphicsPath : public IGraphicsData
{
public:
   IGraphicsPath *AsIPath() { return this; }
   virtual GraphicsDataType GetType() { return gdtPath; }
};

enum PathCommand
{
   pcNoOp  = 0,
   pcMoveTo  = 1,
   pcLineTo = 2,
   pcCurveTo =  3,
   pcWideMoveTo = 4,
   pcWideLineTo = 5,
   pcArcTo =  6,

   // Special code so we can mix lines and fills...
   pcBeginAt  = 7,
};

enum WindingRule { wrOddEven, wrNonZero };


class GraphicsPath : public IGraphicsPath
{
public:
   GraphicsPath *AsPath() { return this; }
	bool empty() const { return commands.empty(); }

   GraphicsPath() : winding(wrOddEven) { }
   QuickVec<uint8> commands;
   QuickVec<float> data;
   WindingRule     winding;

	void clear();
   void initPosition(const UserPoint &inPos);

   void curveTo(float controlX, float controlY, float anchorX, float anchorY);
   void arcTo(float controlX, float controlY, float anchorX, float anchorY);
   void lineTo(float x, float y);
   void moveTo(float x, float y);
   void wideLineTo(float x, float y);
   void wideMoveTo(float x, float y);
};


enum TriangleCulling { tcNegative = -1, tcNone = 0, tcPositive = 1};

struct Vertex
{
   float  x;
   float  y;
   float  z;
   bool   edge;
};

struct VertexUV : public Vertex
{
   UserPoint uv;
};

struct VertexUVT : public VertexUV
{
   float t;
};

enum VertexType { vtVertex, vtVertexUV, vtVertexUVT };

class GraphicsTrianglePath : public IGraphicsPath
{
public:
   GraphicsTrianglePath();
   ~GraphicsTrianglePath();

   TriangleCulling   culling;
   VertexType mType;
   Vertex     *mVertex;
   int        mTriangleCount;
};

// ----------------------------------------------------------------------


enum BlendMode
{
   bmNormal,
   bmLayer,
   bmMultiply,
   bmScreen,
   bmLighten,
   bmDarken,
   bmDifference,
   bmAdd,
   bmSubtract,
   bmInvert,
   bmAlpha,
   bmErase,
   bmOverlay,
   bmHardLight,

   // Used for rendering text
   bmTinted,
};

class ColorTransform
{
public:
   ColorTransform() :
      redScale(1), redOffset(0),
      greenScale(1), greenOffset(0),
      blueScale(1), blueOffset(0),
      alphaScale(1), alphaOffset(0) { }

   uint32 Transform(uint32 inValue) const;

   void Combine(const ColorTransform &inParent, const ColorTransform &inChild);

   inline bool IsIdentityColour() const
   {
      return redScale==1 && greenScale==1 && blueScale==1 &&
             redOffset==0 && greenOffset==0 && blueOffset==0;
   }
   inline bool IsIdentityAlpha() const
   {
      return alphaScale==1 && alphaOffset == 0;
   }
   inline bool IsIdentity() const { return IsIdentityAlpha() && IsIdentityColour(); }

   static void TidyCache();


   const uint8 *GetAlphaLUT() const;
   const uint8 *GetC0LUT() const;
   const uint8 *GetC1LUT() const;
   const uint8 *GetC2LUT() const;

   double redScale, redOffset;
   double greenScale, greenOffset;
   double blueScale, blueOffset;
   double alphaScale, alphaOffset;
};

struct SoftwareMask;

struct Transform
{
   Transform();
   bool operator==(const Transform &inRHS) const;
   bool operator!=(const Transform &inRHS) const
      { return !(operator==(inRHS)); }

   UserPoint      Apply(float inX, float inY) const;
   Fixed10        ToImageAA(const UserPoint &inPoint) const;

   Rect           GetTargetRect(const Extent2DF &inExtent) const;

   const Matrix3D *mMatrix3D;
   const Matrix   *mMatrix;
   const Scale9   *mScale9;

   int            mAAFactor;

   double         mStageScaleX;
   double         mStageScaleY;
   double         mStageOX;
   double         mStageOY;
};



class BitmapCache
{
public:
   BitmapCache(Surface *inSurface,const Transform &inTrans, const Rect &inRect,bool inMaskOnly);
   ~BitmapCache();

   bool StillGood(const Transform &inTransform,const Rect &inExtent, const Rect &inVisiblePixels);

   void Render(const struct RenderTarget &inTarget,const BitmapCache *inMask,BlendMode inBlend);

   PixelFormat Format() const;

   Rect GetRect() const { return mRect.Translated(mTX,mTY); }

   const uint8 *Row(int inRow) const;
   int GetTX() const { return mTX; }
   int GetTY() const { return mTX; }

private:
   int        mTX,mTY;
   Rect       mRect;
   Matrix     mMatrix;
   Scale9     mScale9;
   Surface    *mBitmap;
};


enum RenderPhase { rpBitmap, rpRender, rpHitTest };


struct RenderState
{
   RenderState(Surface *inSurface=0,int inAA=1);

   void CombineColourTransform(const RenderState &inState,
                           const ColorTransform *inObjTrans,
                           ColorTransform *inBuf);

   // Spatial Transform
   Transform      mTransform;

   // Colour transform
   bool HasAlphaLUT() const { return mAlpha_LUT; }
   bool HasColourLUT() const { return mC0_LUT; }

   const ColorTransform *mColourTransform;
   const uint8 *mC0_LUT;
   const uint8 *mC1_LUT;
   const uint8 *mC2_LUT;
   const uint8 *mAlpha_LUT;

   // Viewport
   Rect           GetAARect() const { return mClipRect*mTransform.mAAFactor; }
   Rect           mClipRect;

   RenderPhase    mPhase;
   bool           mRoundSizeToPOW2;
   // Masking...
   class BitmapCache    *mMask;
   // HitTest result...
   mutable class DisplayObject  *mHitResult;
};



enum PrimType { ptTriangleFan, ptTriangleStrip, ptTriangles, ptLineStrip };

struct DrawElement
{
   uint8    mPrimType;
	bool     mBitmapRepeat;
	bool     mBitmapSmooth;
   int      mFirst;
   int      mCount;
   uint32   mColour;
   float    mWidth;
   StrokeScaleMode mScaleMode;
};

typedef QuickVec<DrawElement> DrawElements;
typedef QuickVec<UserPoint>   Vertices;

struct HardwareArrays
{
   HardwareArrays(Surface *inSurface);
   ~HardwareArrays();

   Vertices mVertices;
   Vertices mTexCoords;
   DrawElements mElements;
   Surface *mSurface;
};

typedef QuickVec<HardwareArrays *> HardwareCalls;

class HardwareData
{
public:
   ~HardwareData();

   HardwareArrays &GetArrays(Surface *inSurface);

   HardwareCalls mCalls;
};


class HardwareContext : public Object
{
public:
   static HardwareContext *CreateOpenGL(void *inWindow, void *inGLCtx);

	// Could be common to multiple implementations...
   virtual bool Hits(const RenderState &inState, const HardwareCalls &inCalls );

   virtual void SetWindowSize(int inWidth,int inHeight)=0;
   virtual void BeginRender(const Rect &inRect)=0;
   virtual void SetViewport(const Rect &inRect)=0;
   virtual void Clear(uint32 inColour,const Rect *inRect=0) = 0;
   virtual void Flip() = 0;

   virtual int Width() const = 0;
   virtual int Height() const = 0;


   virtual class Texture *CreateTexture(class Surface *inSurface)=0;
   virtual void Render(const RenderState &inState, const HardwareCalls &inCalls )=0;
   virtual void BeginBitmapRender(Surface *inSurface,uint32 inTint=0,bool inRepeat=true,bool inSmooth=true)=0;
   virtual void RenderBitmap(const Rect &inSrc, int inX, int inY)=0;
   virtual void EndBitmapRender()=0;
};

void BuildHardwareJob(const class GraphicsJob &inJob,const GraphicsPath &inPath,
							 HardwareData &ioData, HardwareContext &inHardware);

int UpToPower2(int inX);


struct RenderTarget
{
   RenderTarget(const Rect &inRect,PixelFormat inFormat,uint8 *inPtr, int inStride);
   RenderTarget(const Rect &inRect,HardwareContext *inContext);
   RenderTarget();

   bool IsHardware() const { return mHardware; }

   void Clear(uint32 inColour,const Rect &inRect ) const;

   RenderTarget ClipRect(const Rect &inRect) const;

		Rect        mRect;
   PixelFormat mPixelFormat;

   // Software target
   uint8 *mSoftPtr;
   int   mSoftStride;
   uint8 *Row(int inRow) const { return mSoftPtr+mSoftStride*inRow; }

   // Hardware target - RenderTarget does not hold reference on HardwareContext
   HardwareContext *mHardware;
};


class Renderer
{
public:
   virtual void Destroy()=0;

   virtual bool Render( const RenderTarget &inTarget, const RenderState &inState ) = 0;

   virtual bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent) = 0;

   virtual bool Hits(const RenderState &inState) { return false; }

   static Renderer *CreateSoftware(const class GraphicsJob &inJob,const GraphicsPath &inPath);

protected:
   virtual ~Renderer() { }
};


struct GraphicsJob
{
   GraphicsJob() { memset(this,0,sizeof(GraphicsJob)); }

   void clear();

   GraphicsStroke  *mStroke;
   IGraphicsFill   *mFill;
   //TriangleData    *mTriagles;
   class Renderer  *mSoftwareRenderer;
   int             mCommand0;
   int             mData0;
   int             mCommandCount;
   int             mDataCount;
};



typedef QuickVec<GraphicsJob> GraphicsJobs;


class Graphics : public Object
{
public:
   Graphics(bool inInitRef = false);
   ~Graphics();

   void clear();

   Extent2DF GetExtent(const Transform &inTransform);

   bool Render( const RenderTarget &inTarget, const RenderState &inState );

   void drawGraphicsDatum(IGraphicsData *inData);
   void drawGraphicsData(IGraphicsData **graphicsData,int inN);
   void beginFill(unsigned int color, float alpha = 1.0);
   void endFill();
   void beginBitmapFill(Surface *bitmapData, const Matrix &inMatrix = Matrix(),
                        bool inRepeat = true, bool inSmooth = false);
   void lineStyle(double thickness, unsigned int color = 0, double alpha = 1.0,
                  bool pixelHinting = false, StrokeScaleMode scaleMode = ssmNormal,
                  StrokeCaps caps = scRound,
                  StrokeJoints joints = sjBevel, double miterLimit= 3.0);

   void lineTo(float x, float y);
   void moveTo(float x, float y);
   void curveTo(float cx,float cy,float x, float y);
   void arcTo(float cx,float cy,float x, float y);
   void drawPath(const QuickVec<uint8> &inCommands, const QuickVec<float> &inData,
           WindingRule inWinding );

   void drawEllipse(float x,float  y,float  width,float  height);
   void drawCircle(float x,float y, float radius) { drawEllipse(x,y,radius,radius); }
   void drawRect(float x,float  y,float  width,float  height)
   {
		Flush();
      moveTo(x,y);
      lineTo(x+width,y);
      lineTo(x+width,y+height);
      lineTo(x,y+height);
      lineTo(x,y);
		Flush();
   }
   void drawRoundRect(float x,float  y,float  width,float  height,float  ellipseWidth,float  ellipseHeight);

   const Extent2DF &GetExtent0(double inRotation);
   bool  HitTest(const UserPoint &inPoint);

   bool empty() const { return !mPathData || mPathData->empty(); }

protected:
	void                      BuildHardware();
   void                      Flush(bool inLine=true,bool inFill=true);

private:
   GraphicsJobs              mJobs;
	int                       mConvertedJobs;
	int                       mMeasuredJobs;
	int                       mBuiltHardware;

   GraphicsPath              *mPathData;
   HardwareData              *mHardwareData;

   double                    mRotation0;
   Extent2DF                 mExtent0;

   GraphicsJob               mFillJob;
   GraphicsJob               mLineJob;
   GraphicsJob               mTriJob;

   UserPoint                 mCursor;

   void BuiltExtent0(double inRotation);


private:
   // Rule of 3 - we must manually clean up the jobs (performance optimisation)
   Graphics(const Graphics &inRHS);
   void operator=(const Graphics &inRHS);
};





} // end namespace nme

#endif
