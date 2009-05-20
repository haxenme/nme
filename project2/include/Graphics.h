// Some design ramblings to see how some things may fit together.

enum GraphicsAPIType { datBase, datInternal,  datQuartz, datCairo, datOpenGL, datOpenGLES };
enum SurfaceAPIType  { datInternal, datSDL, datCairo };

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
   virtual GraphicsBitmapFill   *CreateBitmapFill(bitmapData, matrix, smooth, repeat)=0;

   virtual GraphicsPath         *CreatePath()=0;
   virtual GraphicsTrianglePath *CreateTrianglePath()=0;

   virtual GraphicsStroke       *CreateStroke()=0;

   virtual BitmapData           *CreateBimapData()=0;
};

GraphicsAPI *gGraphics;


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
   virtual DrawingAPIType   GetAPI() { return gdtBase; }

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


private:
   IGraphicsData(const IGraphicsData &inRHS);
   void operator=(const IGraphicsData &inRHS);

   virtual ~IGraphicsData();
   int     mRefCount;
};


class IGraphicsFill : public IGraphicsData
{
   virtual GraphicsFill   *AsFill() { return this; }
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
   GraphicsGradientFill   *AsBitmapFill() { return this; }

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
   NO_OP  = 0,
   MOVE_TO  = 1,
   LINE_TO = 2,
   CURVE_TO =  3,
   WIDE_MOVE_TO  4,
   WIDE_LINE_TO = 5,
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
}

struct BlitData
{
   BitmapData mData;
   Rect       mRect;
};

class Font;

class IRenderTarget
{
   virtual bool ViewPort(int inOX,int inOY, int inW,int inH);
   virtual void BeginRender();
   virtual void Render(DisplayList &inDisplayList, const Transform &inTransform)=0;
   virtual void Render(TextList &inTextList, const Transform &inTransform)=0;
   virtual void Blit(BlitData inBitmap, int inOX, int inOY, double inScale, int Rotation)=0;
   virtual void EndRender();
};


class Frame : public IRenderTarget
{
   virtual void Flip();
   virtual void SetEventHadler();
   virtual void SetTitle();
   virtual void SetIcon();
   virtual void GetMouse();
};

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, icon, title );

#ifdef _WIN32
Frame *CreateNativeFrame(HWND inParent);
#endif

Stage *CreateNativeState(Frame *inFrame, value inEventHandler);




// ---- Surface API --------------

struct *NativeSurface;

class Surface
{
public:
   Surface();
   Surface(int inWidth,int inHeight,PixelFormat inFormat);

   bool Load(char *inFilename);

   bool Load(unsigned char *inBytes,int inLen);

   ~Surface();
   void Blit(Surface *inSrc, Rect inRect1,int inDX, int inDY);
   int  BytesPerRow();
   char *Base();
   int  Width();
   int  Height();

   NativeSurface *mNativeSurface;
};


class BitmapData : public IRenderTarget
{
   virtual int getWidth();
   virtual int getHeight();
   virtual PixelFormat GetPixelFormat();

   virtual int GetBytesPerRow();
   virtual char *GetBase();
   virtual void SetPixel();

   virtual NativeSurface *GetSurface() { return 0; }

   NativeSurface *mSurface;
};



