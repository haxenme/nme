#ifndef GRAPHICS_H

// Some design ramblings to see how some things may fit together.

#include <QuickVec.h>
#include <Matrix.h>
#include <Scale9.h>

typedef unsigned int uint32;


enum GraphicsAPIType { gatBase, gatInternal,  gatQuartz, gatCairo, gatOpenGL, gatOpenGLES };

enum SurfaceAPIType  { satInternal, satSDL, satCairo };

enum PixelFormat
{
   pfUnkown,
   pfBGR,
   pfRGB555,
   pfARGB,
   pfXRGB,
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

class BitmapData;

// Don't know if these belong in the c++ level?
class IGraphicsFill;
class IGraphicsPath;
class IGraphicsStroke;


class GraphicsAPI
{
public:
   virtual GraphicsEndFill      *CreateEndFill()=0;
   virtual GraphicsSolidFill    *CreateSolidFill()=0;
   virtual GraphicsGradientFill *CreateGradientFill()=0;
   virtual GraphicsBitmapFill   *CreateBitmapFill(/*bitmapData, matrix, smooth, repeat*/)=0;

   virtual GraphicsPath         *CreatePath()=0;
   virtual GraphicsTrianglePath *CreateTrianglePath()=0;

   virtual GraphicsStroke       *CreateStroke()=0;

   virtual BitmapData           *CreateBimapData()=0;
};

extern GraphicsAPI *gGraphics;


enum GraphicsDataType
{
   gdtUnknown, gdtEndFill, gdtSolidFill, gdtGradientFill, gdtBitmapFill,
   gdtPath, gdtTrianglePath, gdtStroke
};


class IGraphicsData
{
public:
   IGraphicsData();

   void DecRef();

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
   virtual ~IGraphicsData();
private:
   IGraphicsData(const IGraphicsData &inRHS);
   void operator=(const IGraphicsData &inRHS);

   int     mRefCount;
};


class IGraphicsFill : public IGraphicsData
{
   virtual IGraphicsFill *AsFill() { return this; }

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
   GraphicsDataType GetType() { return gdtSolidFill; }
   GraphicsSolidFill   *AsSolidFill() { return this; }

   double alpha;
   int    rgb;
};


struct GradStop
{
   double  mAlpha;
   int     mRGB;
};

enum InterpolationMethod {  imLinearRGB, imRGB };
enum SpreadMethod {  smPad, smReflect, smRepeat };

class GraphicsGradientFill : public IGraphicsFill
{
public:
   GraphicsDataType GetType() { return gdtGradientFill; }
   GraphicsGradientFill   *AsGradientFill() { return this; }

   QuickVec<GradStop>  mStops;

   double              focalPointRatio;
   Matrix              matrix;
   InterpolationMethod interpolationMethod;
   SpreadMethod        spreadMethod;
   bool                isLinear;
};


class GraphicsBitmapFill : public IGraphicsFill
{
public:
   ~GraphicsBitmapFill();

   GraphicsDataType GetType() { return gdtBitmapFill; }
   GraphicsBitmapFill   *AsBitmapFill() { return this; }

   BitmapData          *bitmapData;
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
   ~GraphicsStroke();

   GraphicsStroke *AsStroke() { return this; }

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
};

enum WindingRule { wrOddEven, wrNonZero };


class GraphicsPath : public IGraphicsPath
{
public:
   QuickVec<unsigned char> command;
   QuickVec<double>        data;
   WindingRule             winding;
};


enum TriangleCulling { tcNegative = -1, tcNone = 0, tcPositive = 1};

class GraphicsTrianglePath : public IGraphicsPath
{
public:
   TriangleCulling   culling;
   QuickVec<int>     indices;
   QuickVec<double>  uvtData;
   QuickVec<double>  uvtVertices;
   int               mUVTDim;
};


// ----------------------------------------------------------------------


// Blender = blend mode + (colour transform + alpha)

enum BlendMode { bmNormal, nmAdd };

struct Rect
{
   Rect(int inW=0,int inH=0) : x(0), y(0), w(inW), h(inH) { } 
   Rect(int inX,int inY,int inW,int inH) : x(inX), y(inY), w(inW), h(inH) { } 
   int x,y;
   int w,h;
};

class ColorTransform
{
   double redScale, redOffset;
   double greenScale, greenOffset;
   double blueScale, blueOffset;
   double alphaScale, alphaOffset;
};

struct Mask
{
   // ??
};

struct Transform
{
   Matrix3D       mMatrix3D;
   Matrix         mMatrix;
   Scale9         mScale9;

   double         mAlpha;
   BlendMode      mBlendMode;
   ColorTransform mTransform;

   Rect           mClipRect;
   Mask           mMask;
};


class DisplayList
{
public:
   ~DisplayList();

   QuickVec<IGraphicsPath *> mItems;

private:
   // Rule of 3 - we must manually delete the mItems...
   DisplayList(const DisplayList &inRHS);
   void operator=(const DisplayList &inRHS);
};

struct BlitData
{
   BitmapData *mData;
   Rect       mRect;
};

typedef char *String;

class NativeFont;

class TextData
{
   String     mText;
   NativeFont *mFont;
   uint32     mColour;
   double     mSize;
   double     mX;
   double     mY;
};


typedef QuickVec<TextData> TextList;

class IRenderTarget
{
public:
   virtual int  Width()=0;
   virtual int  Height()=0;

   virtual void ViewPort(int inOX,int inOY, int inW,int inH)=0;
   virtual void BeginRender()=0;
   virtual void Render(DisplayList &inDisplayList, const Transform &inTransform)=0;
   virtual void Render(TextList &inTextList, const Transform &inTransform)=0;
   virtual void Blit(BlitData &inBitmap, int inOX, int inOY, double inScale, int Rotation)=0;
   virtual void EndRender() = 0;
};

enum EventType
{
   etUnknown,
   etClose,
   etResize,
   etMouseMove,
   etMouseClick,
   etTimer,
};


struct Event
{
   EventType mType;
   int       inWinX,inWinY;
   int       mValue;
   int       mModState;
};

typedef void (*EventHandler)(Event &ioEvent, void *inUserData);

class DisplayObject
{
public:

};


class DisplayObjectContainer : public DisplayObject
{
public:

};

class Stage : public DisplayObjectContainer, public IRenderTarget
{
public:
   virtual void Flip() = 0;
   virtual void GetMouse() = 0;
   virtual void SetEventHandler(EventHandler inHander,void *inUserData) = 0;
};


class Frame
{
public:
   virtual void SetTitle() = 0;
   virtual void SetIcon() = 0;
   virtual Stage *GetStage() = 0;
};

enum WindowFlags
{
   wfFullScreen = 0x00000001,
   wfBorderless = 0x00000002,
   wfResizable  = 0x00000004,
   wfOpenGL     = 0x00000008,
};

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, String inTitle );
void MainLoop();
void TerminateMainLoop();

#ifdef _WIN32
//Frame *CreateNativeFrame(HWND inParent);
#endif


// ---- Surface API --------------

struct NativeSurface;

struct SurfaceData
{
   char *mData;
   int  mWidth;
   int  mHeight;
   int  mStride;
};

enum
{
   surfLockRead = 0x0001,
   surfLockWrite = 0x0002,
};

class Surface
{
public:
   virtual ~Surface() { }

   virtual int Width()=0;
   virtual int Height()=0;
   virtual PixelFormat Format() = 0;

   virtual void Blit(Surface *inSrc, const Rect &inSrcRect,int inDX, int inDY)=0;
   virtual SurfaceData Lock(const Rect &inRect,uint32 inFlags)=0;
   virtual void Unlock()=0;
};

class SimpleSurface : public Surface
{
public:
   SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign=4);
   ~SimpleSurface();

   int Width() { return mWidth; }
   int Height() { return mHeight; }
   PixelFormat Format() { return mPixelFormat; }

   void Blit(Surface *inSrc, const Rect &inSrcRect,int inDX, int inDY);
   SurfaceData Lock(const Rect &inRect,uint32 inFlags);
   void Unlock();

private:
   int           mWidth;
   int           mHeight;
   PixelFormat   mPixelFormat;
   int           mStride;
   unsigned char *mBase;

private:
   SimpleSurface(const SimpleSurface &inRHS);
   void operator=(const SimpleSurface &inRHS);
};


class BitmapData : public IRenderTarget
{
public:
   virtual int Width();
   virtual int Height();
   virtual PixelFormat GetPixelFormat();

   virtual int GetBytesPerRow();
   virtual char *GetBase();
   virtual void SetPixel();

   NativeSurface *mSurface;
};


#endif
