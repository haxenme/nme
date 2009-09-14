#ifndef DISPLAY_H
#define DISPLAY_H

#include <Object.h>
#include <Geom.h>
#include <Graphics.h>


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
	Rect   scale9Grid;
	Rect   scrollRect;
	bool   visible;

   void SetParent(DisplayObjectContainer *inParent);

protected:
	~DisplayObject();
   Transform mTransform;
   DisplayObjectContainer *mParent;
};



class DisplayObjectContainer : public DisplayObject
{
public:
	DisplayObjectContainer(bool inInitRef = false) : DisplayObject(inInitRef) { }

   void addChild(DisplayObject *inChild);
   void removeChild(DisplayObject *inChild);


   void RemoveChildFromList(DisplayObject *inChild);

protected:
   ~DisplayObjectContainer();
   QuickVec<DisplayObject *> mChildren;
};

class Stage : public DisplayObjectContainer
{
public:
   virtual void Flip() = 0;
   virtual void GetMouse() = 0;
   virtual void SetEventHandler(EventHandler inHander,void *inUserData) = 0;
	virtual Surface *GetPrimarySurface() = 0;
};


// Helper class....
class AutoStageRender
{
	Surface *mSurface;
	Stage   *mToFlip;
	RenderTarget mTarget;
public:
	AutoStageRender(Stage *inStage,int inRGB)
	{
		mSurface = inStage->GetPrimarySurface();
		mToFlip = inStage;
		mTarget = mSurface->BeginRender( Rect(mSurface->Width(),mSurface->Height()) );
		mSurface->Clear(inRGB);
	}
	int Width() const { return mSurface->Width(); }
	int Height() const { return mSurface->Height(); }
	~AutoStageRender()
	{
		mSurface->EndRender();
		mToFlip->Flip();
	}
	const RenderTarget &Target() { return mTarget; }

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

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, wchar_t *inTitle );
void MainLoop();
void TerminateMainLoop();

#endif
