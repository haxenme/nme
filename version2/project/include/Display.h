#ifndef NME_DISPLAY_H
#define NME_DISPLAY_H

#include <Object.h>
#include <Geom.h>
#include <Graphics.h>
#include <string>

namespace nme
{

enum
{
   drDisplayChildRefs  = 0x01,
   drDisplayParentRefs = 0x02,
};

extern unsigned int gDisplayRefCounting;

enum EventType
{
   etUnknown,   // 0
   etKeyDown,   // 1
   etChar,      // 2
   etKeyUp,     // 3
   etMouseMove, // 4
   etMouseDown, // 5
   etMouseClick,// 6
   etMouseUp,   // 7
   etResize,    // 8
   etPoll,      // 9
   etQuit,      // 10
   etFocus,     // 11

   // Internal for now...
   etDestroyHandler,
   etRedraw,
};

enum EventFlags
{
   efLeftDown  =  0x0001,
   efShiftDown =  0x0002,
   efCtrlDown  =  0x0004,
   efAltDown   =  0x0008,
   efCommandDown = 0x0010,
};

enum FocusSource { fsProgram, fsMouse, fsKey };

enum EventResult
{
   erOk,
   erCancel,
};

struct Event
{
   Event(EventType inType=etUnknown,int inX=0,int inY=0,int inValue=0,int inID=0,int inFlags=0):
        type(inType), x(inX), y(inY), value(inValue), id(inID), flags(inFlags), result(erOk)
   {
   }

   EventType type;
   int       x,y;
   int       value;
   int       code;
   int       id;
   int       flags;
   EventResult result;
};

typedef void (*EventHandler)(Event &ioEvent, void *inUserData);

class Stage;
class DisplayObjectContainer;

enum
{
   dirtDecomp      = 0x0001,
   dirtLocalMatrix = 0x0002,
   dirtCache       = 0x0004,
};

class Filter : public Object
{
   Filter(int inQuality = 1) : mQuality(inQuality) { }
   virtual ~Filter() {}

   virtual class SimpleSurface *Process(const Surface *inSurface,bool inToPOW2) const = 0;
   virtual void GetOffset(int &ioDX, int &ioDY) const = 0;
   virtual int GetQuality() const { return mQuality; }

protected:
   int mQuality;
};

typedef QuickVec<Filter *> Filters;

Rect GetFilteredRect(const Filters &inFilters,const Rect &inObjRect);
Rect GetRectToCreateFiltered(const Filters &inFilters,const Rect &inTargetRect);

void FilterBitmap(const Filters &inFilters,SimpleSurface *&bitmap, const Rect &inSrcRect, const Rect &outDestRect, bool inMakePOW2);

        
enum Cursor { curNone, curPointer, curHand, curTextSelect };

extern const char *sTextCursorData[];

extern bool gMouseShowCursor;

class DisplayObject : public Object
{
public:
   DisplayObject(bool inInitRef = false);

   double getX();
   void   setX(double inValue);
   double getY();
   void   setY(double inValue);
   virtual double getHeight();
   virtual void   setHeight(double inValue);
   virtual double getWidth();
   virtual void   setWidth(double inValue);
   double getRotation();
   void   setRotation(double inValue);
   double getScaleX();
   void   setScaleX(double inValue);
   double getScaleY();
   void   setScaleY(double inValue);
   void   setScale9Grid(const DRect &inRect);
   void   setScrollRect(const DRect &inRect);
   void   setMask(DisplayObject *inMask);
   DisplayObject   *getMask() { return mMask; }
   virtual void   setOpaqueBackground(uint32 inBG);
   uint32 getOpaqueBackground() { return opaqueBackground; }
	bool getMouseEnabled() { return mouseEnabled; }
	void setMouseEnabled(bool inVal) { mouseEnabled = inVal; }

   void   setAlpha(double inAlpha);

	int getID() const { return id; }


   const Transform &getTransform();

   DisplayObject *getParent();

   double getMouseX();
   double getMouseY();
   DisplayObject *getRoot();
   virtual Stage  *getStage();

   struct LoaderInfo &GetLoaderInfo();

   BlendMode blendMode;
   bool cacheAsBitmap;
   ColorTransform  colorTransform;
   QuickVec<class Filter *> filters;

   std::wstring  name;
   uint32 opaqueBackground;
   DRect   scale9Grid;
   DRect   scrollRect;
   int     id;
   bool   visible;
	bool   mouseEnabled;

   virtual void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap);

   virtual void Render( const RenderTarget &inTarget, const RenderState &inState );

   void RenderBitmap( const RenderTarget &inTarget, const RenderState &inState );
   void DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState );

   virtual void DirtyUp(uint32 inFlags);
   virtual void DirtyDown(uint32 inFlags);
   virtual bool NonNormalBlendChild() { return false; }

	virtual Cursor GetCursor() { return curPointer; }
   virtual bool WantsFocus() { return false; }
   virtual void Focus() { }
   virtual void Unfocus() { }

   void SetParent(DisplayObjectContainer *inParent);

   UserPoint GlobalToLocal(const UserPoint &inPoint);

   Graphics &GetGraphics();
   Matrix   GetFullMatrix();
   Matrix   &GetLocalMatrix();
   const Filters &GetFilters() { return mFilters; }
   void     SetFilters(const Filters &inFilters);

   void CheckCacheDirty();
   bool IsBitmapRender();
   void SetBitmapCache(BitmapCache *inCache);
   BitmapCache *GetBitmapCache() { return mBitmapCache; }

   void ChangeIsMaskCount(int inDelta);

   bool IsMask() const { return mIsMaskCount; }

   void CombineColourTransform(const RenderState *inState,
                               const ColorTransform *inObjTrans,
                               ColorTransform *inBuf);

protected:
   void UpdateDecomp();
   void UpdateLocalMatrix();
   void DecFilters();
   ~DisplayObject();
   DisplayObjectContainer *mParent;
   Graphics               *mGfx;
   BitmapCache            *mBitmapCache;
   Filters                mFilters;


   // Masking...
   DisplayObject          *mMask;
   int                    mIsMaskCount;

   // Matrix stuff
   uint32 mDirtyFlags;
   Matrix mLocalMatrix;
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
   void setChildIndex(DisplayObject *inChild,bool inTakeRef=false);
   void removeChild(DisplayObject *inChild);
   void setChildIndex(DisplayObject *inChild,int inNewIndex);
   DisplayObject *getChildAt(int index);

   void RemoveChildFromList(DisplayObject *inChild);

   void Render( const RenderTarget &inTarget, const RenderState &inState );
   void DirtyUp(uint32 inFlags);
   bool NonNormalBlendChild();
   virtual void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap);


protected:
   ~DisplayObjectContainer();
   QuickVec<DisplayObject *> mChildren;
};

class Stage : public DisplayObjectContainer
{
public:
	enum PollMethod { pollNever, pollTimer, pollAlways };


   Stage(bool inInitRef=false);

   virtual void Flip() = 0;
   virtual void GetMouse() = 0;
   virtual Surface *GetPrimarySurface() = 0;
   virtual void SetPollMethod(PollMethod inMethod) = 0;
   virtual void PollNow() { }

   virtual void RenderStage();

   void SetEventHandler(EventHandler inHander,void *inUserData);
   virtual void   setOpaqueBackground(uint32 inBG);
   DisplayObject *HitTest(int inX,int inY);
   virtual void SetCursor(Cursor inCursor)=0;

   int    mQuality;

	void RemovingFromStage(DisplayObject *inObject);
	Stage  *getStage() { return this; }


	DisplayObject *GetFocusObject() { return mFocusObject; }
	void SetFocusObject(DisplayObject *inObj,FocusSource inSource=fsProgram,int inKey=0);

protected:
   ~Stage();
   void HandleEvent(Event &inEvent);
   EventHandler mHandler;
   void         *mHandlerData;
	DisplayObject *mFocusObject;
};





class Frame : public Object
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
   wfHardware   = 0x00000008,
   wfVSync      = 0x00000010,
};

void MainLoop();
void TerminateMainLoop();

Stage *IPhoneGetStage();
Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, const char *inTitle, const char *inIcon );


} // end namespace nme

#endif
