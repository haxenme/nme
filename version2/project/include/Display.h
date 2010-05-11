#ifndef NME_DISPLAY_H
#define NME_DISPLAY_H

#include <Object.h>
#include <Geom.h>
#include <Graphics.h>
#include <string>
#include <Filters.h>

namespace nme
{

enum
{
   drDisplayChildRefs  = 0x01,
   drDisplayParentRefs = 0x02,
};

extern unsigned int gDisplayRefCounting;

extern bool gSDLIsInit;

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
   etShouldRotate, // 12

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
   efMiddleDown  = 0x0020,
   efRightDown  = 0x0040,

   efLocationRight  = 0x4000,
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

enum StageScaleMode
{
    ssmShowAll,
    ssmNoScale,
    ssmNoBorder,
    ssmExactFit,
};

enum StageAlign
{
   saTopRight,
   saTopLeft,
   saTop,
   saRight,
   saLeft,
   saBottomRight,
   saBottomLeft,
   saBottom,
};



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
   double getMouseX();
   double getMouseY();
   void   setScale9Grid(const DRect &inRect);
   void   setScrollRect(const DRect &inRect);
   void   setMask(DisplayObject *inMask);
   DisplayObject   *getMask() { return mMask; }
   virtual void   setOpaqueBackground(uint32 inBG);
   uint32 getOpaqueBackground() { return opaqueBackground; }
   bool getMouseEnabled() { return mouseEnabled; }
   void setMouseEnabled(bool inVal) { mouseEnabled = inVal; }
   bool getCacheAsBitmap() { return cacheAsBitmap; }
   void setCacheAsBitmap(bool inVal);
   bool getVisible() { return visible; }
   void setVisible(bool inVal);
   const wchar_t *getName() { return name.c_str(); }
   void setName(const std::wstring &inName) { name = inName; }
   void setMatrix(const Matrix &inMatrix);
   void setColorTransform(const ColorTransform &inTransform);

   double getAlpha() { return colorTransform.alphaMultiplier; }
   void   setAlpha(double inAlpha);

   int getID() const { return id; }


   //const Transform &getTransform();

   DisplayObject *getParent();

   DisplayObject *getRoot();
   virtual Stage  *getStage();

   struct LoaderInfo &GetLoaderInfo();

   BlendMode blendMode;
   bool cacheAsBitmap;
   ColorTransform  colorTransform;
   FilterList filters;

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
   bool CreateMask( const Rect &inClipRect,int inAA);
   bool HitBitmap( const RenderTarget &inTarget, const RenderState &inState );
   void DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState );

   virtual void DirtyUp(uint32 inFlags);
   virtual void DirtyCache(bool inParentOnly = false);
   virtual bool NonNormalBlendChild() { return false; }

   virtual Cursor GetCursor() { return curPointer; }
   virtual bool WantsFocus() { return false; }
   virtual void Focus() { }
   virtual void Unfocus() { }

   virtual bool CaptureDown(Event &inEvent) { return false; }
   virtual void Drag(Event &inEvent) {  }
   virtual void EndDrag(Event &inEvent) { }
   virtual void OnKey(Event &inEvent) { }
   virtual bool FinishEditOnEnter() { return false; }


   void SetParent(DisplayObjectContainer *inParent);

   UserPoint GlobalToLocal(const UserPoint &inPoint);

   Graphics &GetGraphics();
   virtual Matrix   GetFullMatrix(bool inWithStageScaling);
   Matrix   &GetLocalMatrix();
   ColorTransform   &GetLocalColorTransform() { return colorTransform; }
   ColorTransform   GetFullColorTransform();
   const FilterList &getFilters() { return filters; }
   // Takes ownership of filters...
   void     setFilters(FilterList &inFilters);

   virtual bool IsCacheDirty();
   virtual void ClearCacheDirty();

   void CheckCacheDirty(bool inForHardware);
   bool IsBitmapRender(bool inForHardware);
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
   void ClearFilters();
   ~DisplayObject();
   DisplayObjectContainer *mParent;
   Graphics               *mGfx;
   BitmapCache            *mBitmapCache;
   int                    mBitmapGfx;


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
   void swapChildrenAt(int inChild1, int inChild2);
   void removeChild(DisplayObject *inChild);
   void removeChildAt(int inIndex);
   void setChildIndex(DisplayObject *inChild,int inNewIndex);
   DisplayObject *getChildAt(int index);

   void RemoveChildFromList(DisplayObject *inChild);

   void Render( const RenderTarget &inTarget, const RenderState &inState );
   void DirtyUp(uint32 inFlags);
   bool IsCacheDirty();
   void ClearCacheDirty();
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

   virtual bool isOpenGL() const = 0;

   void SetEventHandler(EventHandler inHander,void *inUserData);
   void SetNominalSize(int inWidth,int inHeight);
   virtual void   setOpaqueBackground(uint32 inBG);
   DisplayObject *HitTest(UserPoint inPoint);
   virtual void SetCursor(Cursor inCursor)=0;
   virtual void EnablePopupKeyboard(bool inEnable) { }
   Matrix GetFullMatrix(bool inStageScaling);
   bool FinishEditOnEnter();

   void setFocusRect(bool inVal) { focusRect = inVal; }
   bool getFocusRect() const { return focusRect; }
   UserPoint getMousePos() const { return mLastMousePos; }
   double getStageWidth();
   double getStageHeight();
   int getScaleMode() const { return scaleMode; }
   void setScaleMode(int inMode);
   int getAlign() const { return align; }
   void setAlign(int inAlign);

   int    mQuality;

   void RemovingFromStage(DisplayObject *inObject);
   Stage  *getStage() { return this; }


   DisplayObject *GetFocusObject() { return mFocusObject; }
   void SetFocusObject(DisplayObject *inObj,FocusSource inSource=fsProgram,int inKey=0);

protected:
   ~Stage();
   void HandleEvent(Event &inEvent);
   void CalcStageScaling(double inW,double inH);
   EventHandler mHandler;
   void         *mHandlerData;
   bool         focusRect;
   UserPoint    mLastMousePos;
   StageScaleMode scaleMode;
   StageAlign     align;

   Matrix         mStageScale;

   int            mNominalWidth;
   int            mNominalHeight;

   DisplayObject *mFocusObject;
   DisplayObject *mMouseDownObject;
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

void TerminateMainLoop();

Stage *IPhoneGetStage();

typedef void (*FrameCreationCallback)(Frame *);

void CreateMainFrame( FrameCreationCallback inOnFrame, int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, const char *inIcon );


} // end namespace nme

#endif
