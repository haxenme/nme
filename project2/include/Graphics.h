// Some design ramblings to see how some things may fit together.

enum DrawingAPIType { datInternal, datSDL, datQuartz, datCairo, datOpenGL, datOpenGLES };


class IRenderer
{
};

class IRenderTarget
{
   DisplayList *CreateDisplayList();

   void Render(DisplayList, mask,matrix,colour_transform,clipRect);
};


class Stage : public IRenderTarget
{
};

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, icon, title );

#ifdef _WIN32
Frame *CreateNativeFrame(HWND inParent);
#endif

Stage *CreateNativeState(Frame *inFrame, value inEventHandler);




// ---- Surface ------------------
//


class BitmapData : public IRenderTarget
{
   virtual int getWidth();
   virtual int getHeight();
   virtual PixelFormat GetPixelFormat();

   virtual int GetBytesPerRow();
   virtual char *GetBase();

   virtual void *GetNativeAPI(DrawingAPI inAPI) { return 0; }
   // dirty rect?
};


// --- Drawing -------------------
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

class IGraphicsStroke : public IGraphicsData
{
};

class IGraphicsFill : public IGraphicsData
{
};

class GraphicsBitmapFill : public IGraphicsFill
{
   BitmapData bitmapData;
   Matrix     matrix;
   bool       repeat;
   bool       smooth;
};


class GraphicsPath : public IGraphicsData
{
   FastArray<int>    commands;
   FastArray<double> data;
   WindingRule       winding;
};


class DisplayList
{
   virtual ~DisplayList() { }

   FastArray<IGraphicsData> mCommands;

   void addMoveTo(double,double);

   F2DExtent GetExtent(Matrix &inMatrix);
}

class Mask
{
}

