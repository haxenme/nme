#ifndef GRAPHICS_H
#define GRAPHICS_H

// Some design ramblings to see how some things may fit together.

#include <Object.h>
#include <QuickVec.h>
#include <Matrix.h>
#include <Scale9.h>
#include "Pixel.h"

typedef unsigned int uint32;
typedef unsigned char uint8;


enum GraphicsAPIType { gatBase, gatInternal,  gatQuartz, gatCairo, gatOpenGL, gatOpenGLES };

enum SurfaceAPIType  { satInternal, satSDL, satCairo };

enum PixelFormat
{
   pfXRGB     = 0x00,
   pfARGB     = 0x01,
   pfXRGBSwap = 0x02,
   pfARGBSwap = 0x03,

   pfHasAlpha = 0x01,
   pfSwapRB   = 0x02,
};



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


class IGraphicsData
{
public:
   IGraphicsData() : mRefCount(0) { };

   IGraphicsData *IncRef() { mRefCount++; return this; }

   void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }

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

   int     mRefCount;
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
	GraphicsSolidFill(int inRGB=0, float inAlpha=1) : rgb(inRGB), alpha(inAlpha) { }
   GraphicsDataType GetType() { return gdtSolidFill; }
   GraphicsSolidFill   *AsSolidFill() { return this; }

   float alpha;
   int   rgb;
};


struct GradStop
{
	GradStop(int inRGB=0, float inAlpha=0, float inRatio=0) :
		mARGB(inRGB, inAlpha<0 ? 0 : inAlpha>=1 ? 255 : 255.0*inAlpha ),
		mPos(inRatio<=0 ? 0 : inRatio>=1.0 ? 255 : inRatio*255.0 ) { }

   ARGB   mARGB;
   int    mPos;
};
typedef QuickVec<GradStop>  Stops;

enum InterpolationMethod {  imLinearRGB, imRGB };
enum SpreadMethod {  smPad, smReflect, smRepeat };

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
};

enum StrokeCaps { scNone, scRound, scSquare };
enum StrokeJoints { sjMiter, sjRound, sjBevel };
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
};

enum WindingRule { wrOddEven, wrNonZero };


class GraphicsPath : public IGraphicsPath
{
public:
   GraphicsPath *AsPath() { return this; }

	GraphicsPath() : winding(wrOddEven) { }
   QuickVec<uint8> command;
   QuickVec<float>         data;
   WindingRule             winding;

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

struct IRenderData : public IGraphicsData
{
public:
   virtual ~IRenderData() { }
	virtual struct SolidData *AsSolid() { return 0; }
	virtual struct LineData *AsLine() { return 0; }
	virtual struct TriangleData *AsTriangles() { return 0; }
	virtual class Renderer *CreateSoftwareRenderer() = 0;
};

struct SolidData : IRenderData
{
	SolidData(IGraphicsFill *inFill) : mFill(inFill) { }
	SolidData *AsSolid() { return this; }
	class Renderer *CreateSoftwareRenderer();
	void Add(GraphicsPath *inPath);
	void Close();

   IGraphicsFill           *mFill;
   QuickVec<uint8> command;
   QuickVec<float>        data;
};

struct LineData : IRenderData
{
	LineData(GraphicsStroke *inStroke=0) : mStroke(inStroke) { }
	LineData *AsLine() { return this; }
	class Renderer *CreateSoftwareRenderer();
	void Add(GraphicsPath *inPath);

   GraphicsStroke         *mStroke;
   QuickVec<uint8> command;
   QuickVec<float>        data;
};

struct TriangleData : IRenderData
{
	TriangleData *AsTriangles() { return this; }
	class Renderer *CreateSoftwareRenderer();
   IGraphicsFill           *mFill;
   IGraphicsStroke         *mStroke;
   TriangleData            *mTriangles;
};



// ----------------------------------------------------------------------


// Blender = blend mode + (colour transform + alpha)

enum BlendMode { bmNormal, bmCopy, bmAdd };

class ColorTransform
{
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

   Matrix3D       mMatrix3D;
   Matrix         mMatrix;
   Scale9         mScale9;

	int            mAAFactor;

	double         mStageScaleX;
	double         mStageScaleY;
	double         mStageOX;
	double         mStageOY;
};


struct RenderState
{
	RenderState(Surface *inSurface=0,int inAA=1);

	// Spatial Transform
	Transform      mTransform;

	// Viewport
   Rect           mClipRect;
	// Scaled for speed....
   Rect           mAAClipRect;

	// Colour transform
   double         mAlpha;
   ColorTransform mColourTrans;
   BlendMode      mBlendMode;

	// Masking...
	Surface        *mHardwareMask;
	SoftwareMask   *mSoftwareMask;
};


typedef QuickVec<IRenderData *> RenderData;


/*
struct Tile
{
   Surface *mData;
   Rect     mRect;
	double   mX0;
	double   mY0;
};
*/

struct RenderTarget;

class Renderer
{
public:
   virtual void Destroy()=0;

	virtual bool Render( const RenderTarget &inTarget, const RenderState &inState ) = 0;

   virtual bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent) = 0;

	// HitTest

   static Renderer *CreateHardware(LineData *inLineData);
   static Renderer *CreateHardware(SolidData *inSolidData);
   static Renderer *CreateHardware(TriangleData *inTriangleData);

	static Renderer *CreateSoftware(LineData *inLineData);
   static Renderer *CreateSoftware(SolidData *inSolidData);
   static Renderer *CreateSoftware(TriangleData *inTriangleData);

protected:
   virtual ~Renderer() { }
};


struct RendererCache
{
	RendererCache() : mSoftware(0), mHardware(0) { }

	Renderer *mSoftware;
	Renderer *mHardware;
};



class Graphics : public Object
{
public:
   Graphics(bool inInitRef = false);
   ~Graphics();

	void clear();

	Extent2DF GetExtent(const Transform &inTransform);

	bool Render( const RenderTarget &inTarget, const RenderState &inState );


	void addData(IGraphicsData *inData) { inData->IncRef(); Add(inData); }

   void drawGraphicsData(IGraphicsData **graphicsData,int inN);
   void beginFill(unsigned int color, float alpha = 1.0);
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

   void drawEllipse(float x,float  y,float  width,float  height);
   void drawCircle(float x,float y, float radius) { drawEllipse(x,y,radius,radius); }
   void drawRect(float x,float  y,float  width,float  height)
	{
		moveTo(x,y);
		lineTo(x+width,y);
		lineTo(x+width,y+height);
		lineTo(x,y+height);
		lineTo(x,y);
	}
   void drawRoundRect(float x,float  y,float  width,float  height,float  ellipseWidth,float  ellipseHeight);


	bool empty() const { return mItems.empty(); }


private:
	QuickVec<RendererCache>     mCache;
   QuickVec<IGraphicsData *> mItems;
   int                       mLastConvertedItem;
	RenderData                mRenderData;

	void CreateRenderData();
	void Add(IRenderData *inData);
	void Add(IGraphicsData *inData);
	GraphicsPath *GetLastPath();


private:
   // Rule of 3 - we must manually delete the mItems...
   Graphics(const Graphics &inRHS);
   void operator=(const Graphics &inRHS);
};




// ---- Surface API --------------


struct HardwareContext;

struct RenderTarget
{
   Rect mRect;
	PixelFormat format;
	bool is_hardware;

	RenderTarget ClipRect(const Rect &inRect) const;

   uint8 *Row(int inRow) const { return data+stride*inRow; }

	union
	{
	  struct
	  {
        uint8 *data;
        int  stride;
	  };
	  HardwareContext *context;
	};
};

// Need a context ?
struct NativeTexture;
NativeTexture *CreateNativeTexture(Surface *inSoftwareSurface);
void DestroyNativeTexture(NativeTexture *inTexture);


void HintColourOrder(bool inRedFirst);

class Surface
{
public:
   Surface() : mTexture(0), mRefCount(0) { };

   Surface *IncRef() { mRefCount++; return this; }
   void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }

   virtual int Width() const =0;
   virtual int Height() const =0;
   virtual PixelFormat Format()  const = 0;
	virtual const uint8 *GetBase() const = 0;
	virtual int GetStride() const = 0;

	virtual void Clear(uint32 inColour) = 0;

   virtual RenderTarget BeginRender(const Rect &inRect)=0;
   virtual void EndRender()=0;

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       uint32 inTint=0xffffff,bool inUseSrcAlphaOnly=false)=0;

   virtual NativeTexture *GetTexture() { return mTexture; }
   virtual void SetTexture(NativeTexture *inTexture);


protected:
   NativeTexture *mTexture;
	int           mRefCount;
	virtual       ~Surface();
};

// Helper class....
class AutoSurfaceRender
{
	Surface *mSurface;
	RenderTarget mTarget;
public:
	AutoSurfaceRender(Surface *inSurface, const Rect *inRect=0)
	{
		mSurface = inSurface;
		mTarget = inRect ? inSurface->BeginRender( *inRect ) :
		                 inSurface->BeginRender( Rect(mSurface->Width(),mSurface->Height()) );
	}
	~AutoSurfaceRender() { mSurface->EndRender(); }
	const RenderTarget &Target() { return mTarget; }

};

class SimpleSurface : public Surface
{
public:
   SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign=4);

   int Width() const  { return mWidth; }
   int Height() const  { return mHeight; }
   PixelFormat Format() const  { return mPixelFormat; }
	void Clear(uint32 inColour);

   RenderTarget BeginRender(const Rect &inRect);
   void EndRender();

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inDX, int inDY,
                       uint32 inTint=0xffffff,bool inUseSrcAlphaOnly = false);

	const uint8 *GetBase() const { return mBase; }
	int GetStride() const { return mStride; }


protected:
   int           mWidth;
   int           mHeight;
   PixelFormat   mPixelFormat;
   int           mStride;
   uint8         *mBase;
   ~SimpleSurface();

private:
   SimpleSurface(const SimpleSurface &inRHS);
   void operator=(const SimpleSurface &inRHS);
};




#endif
