#ifndef DISPLAY_H
#define DISPLAY_H

#include <Object.h>
#include <Geom.h>
#include <Graphics.h>
#include <string>


enum
{
   drDisplayChildRefs  = 0x01,
   drDisplayParentRefs = 0x02,
};

extern unsigned int gDisplayRefCounting;

enum EventType
{
   etUnknown,
   etClose,
   etResize,
   etMouseMove,
   etMouseClick,
   etTimer,
   etRedraw,
   etNextFrame,
};


struct Event
{
	Event(EventType inType=etUnknown) :
		  mType(inType), mWinX(0), mWinY(0), mValue(0), mModState(0)
	{
	}

   EventType mType;
   float     mWinX,mWinY;
   int       mValue;
   int       mModState;
};

typedef void (*EventHandler)(Event &ioEvent, void *inUserData);

class Stage;
class DisplayObjectContainer;

enum
{
   dirtDecomp      = 0x0001,
   dirtLocalMatrix = 0x0002,
   dirtFullMatrix  = 0x0004,
   dirtCache       = 0x0004,
};

class DisplayObject : public Object
{
public:
	DisplayObject(bool inInitRef = false);

	double getX();
	void   setX(double inValue);
	double getY();
	void   setY(double inValue);
	double getHeight();
	void   setHeight(double inValue);
	double getWidth();
	void   setWidth(double inValue);
	double getRotation();
	void   setRotation(double inValue);
	double getScaleX();
	void   setScaleX(double inValue);
	double getScaleY();
	void   setScaleY(double inValue);
	void   setScale9Grid(const DRect &inRect);


	const Transform &getTransform();

	DisplayObject *getParent();

	double getMouseX();
	double getMouseY();
	DisplayObject *getRoot();
	Stage  *getStage();

	struct LoaderInfo &GetLoaderInfo();

   double alpha;
	BlendMode blendMode;
	bool cacheAsBitmap;
	QuickVec<class Filter *> filters;

 	DisplayObject *mask;
	std::wstring  name;
	uint32 opaqueBackground;
	DRect   scale9Grid;
	Rect   scrollRect;
	bool   visible;


	virtual void Render( const RenderTarget &inTarget, const RenderState &inState );

	virtual void DirtyUp(uint32 inFlags);
	virtual void DirtyDown(uint32 inFlags);

   void SetParent(DisplayObjectContainer *inParent);

	Graphics &GetGraphics();
   Matrix   &GetFullMatrix();
   Matrix   &GetLocalMatrix();

protected:
   void UpdateDecomp();
   void UpdateLocalMatrix();
	~DisplayObject();
   DisplayObjectContainer *mParent;
	Graphics               *mGfx;

   // Matrix stuff
   uint32 mDirtyFlags;
   Matrix mLocalMatrix;
   Matrix mFullMatrix;
   // Decomp
   double x;
   double y;
   double scaleX;
   double scaleY;
   double rotation;

};



class DisplayObjectContainer : public DisplayObject
{
public:
	DisplayObjectContainer(bool inInitRef = false) : DisplayObject(inInitRef) { }

   void addChild(DisplayObject *inChild,bool inTakeRef=false);
   void removeChild(DisplayObject *inChild);
      DisplayObject *getChildAt(int index);


   void RemoveChildFromList(DisplayObject *inChild);
	void Render( const RenderTarget &inTarget, const RenderState &inState );
	void DirtyUp(uint32 inFlags);

protected:
   ~DisplayObjectContainer();
   QuickVec<DisplayObject *> mChildren;
};

class Stage : public DisplayObjectContainer
{
public:
	Stage(bool inInitRef=false);

   virtual void Flip() = 0;
   virtual void GetMouse() = 0;
   virtual void SetEventHandler(EventHandler inHander,void *inUserData) = 0;
	virtual Surface *GetPrimarySurface() = 0;

	virtual void RenderStage();

	uint32 mBackgroundColour;
	int    mQuality;

protected:
	~Stage();
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
   wfVSync      = 0x00000010,
};

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, wchar_t *inTitle );
void MainLoop();
void TerminateMainLoop();

#endif
