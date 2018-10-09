#ifndef NME_DISPLAY_H
#define NME_DISPLAY_H

#include <nme/Object.h>
#include <nme/Event.h>
#include <nme/ObjectStream.h>
#include <Utils.h>
#include <Geom.h>
#include <Graphics.h>
#include <CachedExtent.h>
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

extern bool gNmeRenderGcFree;
extern bool gSDLIsInit;
extern int  gSDLMixerFreq;

enum FocusSource { fsProgram, fsMouse, fsKey };

typedef void (*EventHandler)(Event &ioEvent, void *inUserData);

class Stage;
class DisplayObjectContainer;

enum
{
   dirtDecomp      = 0x0001,
   dirtLocalMatrix = 0x0002,
   dirtCache       = 0x0004,
   dirtExtent      = 0x0008,
   dirtAll         = 0x000f,
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
   saCentre,
   saGame,
   saGamePixels,
   saGameStretch,
};

enum PixelSnapping
{
   psNone = 0,
   psAuto = 1,
   psAlways = 2,
};

enum Cursor { curNone, curPointer, curHand,
              curTextSelect0, curTextSelect90, curTextSelect180, curTextSelect270 };

extern const char *sTextCursorData[];
extern const char *sHandCursorData[];

extern bool gMouseShowCursor;

class DisplayObject : public Object
{
public:
   int            id;
   WString        name;
   BlendMode      blendMode;
   bool           cacheAsBitmap;
   bool           pedanticBitmapCaching;
   unsigned char  pixelSnapping;
   ColorTransform colorTransform;
   FilterList     filters;

   uint32 opaqueBackground;
   DRect  scale9Grid;
   DRect  scrollRect;
   bool   visible;
   bool   mouseEnabled;
   bool   hitEnabled;
   bool   needsSoftKeyboard;
   int    softKeyboard;
   bool   movesForSoftKeyboard;
   uint32 mDirtyFlags;

protected:
   DisplayObjectContainer *mParent;
   Graphics               *mGfx;
   BitmapCache            *mBitmapCache;
   int                     mBitmapGfx;

   // Masking...
   DisplayObject          *mMask;
   int                    mIsMaskCount;

   // Matrix stuff
   Matrix mLocalMatrix;
   // Decomp
   double x;
   double y;
   double scaleX;
   double scaleY;
   double rotation;




public:
   DisplayObject(bool inInitRef = false);

   NmeObjectType getObjectType() { return notDisplayObject; }

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
   bool getHitEnabled() { return hitEnabled; }
   void setHitEnabled(bool inVal) { hitEnabled = inVal; }
   bool getNeedsSoftKeyboard() { return needsSoftKeyboard; }
   void setNeedsSoftKeyboard(bool inVal) { needsSoftKeyboard = inVal; }
   int getSoftKeyboard() { return softKeyboard; }
   void setSoftKeyboard(int inType) { softKeyboard = inType; }
   bool getMovesForSoftKeyboard() { return movesForSoftKeyboard; }
   void setMovesForSoftKeyboard(bool inVal) { movesForSoftKeyboard = inVal; }
   bool getCacheAsBitmap() { return cacheAsBitmap; }
   void setCacheAsBitmap(bool inVal);
   bool getPedanticBitmapCaching() { return pedanticBitmapCaching; }
   void setPedanticBitmapCaching(bool inVal) { pedanticBitmapCaching=inVal; }
   int getPixelSnapping() { return pixelSnapping; }
   void setPixelSnapping(int inVal);
   bool getVisible() { return visible; }
   void setVisible(bool inVal);
   const wchar_t *getName() { return name.c_str(); }
   void setName(const WString &inName) { name = inName; }
   void setMatrix(const Matrix &inMatrix);
   void setColorTransform(const ColorTransform &inTransform);

   double getAlpha() { return colorTransform.alphaMultiplier; }
   void   setAlpha(double inAlpha);
   BlendMode getBlendMode() { return blendMode; }
   void setBlendMode(int inMode);

   int getID() const { return id; }


   //const Transform &getTransform();

   DisplayObject *getParent();
   void hackSetParent(DisplayObjectContainer *inParent) { mParent=inParent; } 

   DisplayObject *getRoot();
   virtual Stage  *getStage();

   struct LoaderInfo &GetLoaderInfo();

   virtual void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap,bool inIncludeStroke);

   virtual void Render( const RenderTarget &inTarget, const RenderState &inState );

   void RenderBitmap( const RenderTarget &inTarget, const RenderState &inState );
   bool CreateMask( const Rect &inClipRect,int inAA);
   bool HitBitmap( const RenderTarget &inTarget, const RenderState &inState );
   void DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState );

   virtual void DirtyCache(bool inParentOnly = false);
   virtual void DirtyExtent();
   virtual void ClearExtentDirty();
   virtual bool NonNormalBlendChild() { return false; }

   virtual Cursor GetCursor() { return curPointer; }
   virtual bool WantsFocus() { return false; }
   virtual void Focus();
   virtual void Unfocus();

   virtual bool CaptureDown(Event &inEvent) { return false; }
   virtual void Drag(Event &inEvent) {  }
   virtual void EndDrag(Event &inEvent) { }
   virtual void OnKey(Event &inEvent) { }
   virtual bool FinishEditOnEnter() { return false; }

   void SetParent(DisplayObjectContainer *inParent);

   UserPoint GlobalToLocal(const UserPoint &inPoint);
   UserPoint LocalToGlobal(const UserPoint &inPoint);

   Graphics &GetGraphics();
   virtual Matrix   GetFullMatrix(bool inWithStageScaling);
   Matrix   &GetLocalMatrix();
   virtual void modifyLocalMatrix(Matrix &ioMatrix) { }
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
   virtual bool IsInteractive() const { return false; }

   void CombineColourTransform(const RenderState *inState,
                               const ColorTransform *inObjTrans,
                               ColorTransform *inBuf);

   virtual void ChildrenDirty() { }

   void encodeStream(ObjectStreamOut &inStream);
   void decodeStream(ObjectStreamIn &inStream);
   static DisplayObject *fromStream(ObjectStreamIn &inStream);


protected:
   void UpdateDecomp();
   void UpdateLocalMatrix();
   void ClearFilters();
   ~DisplayObject();
};



class DisplayObjectContainer : public DisplayObject
{
public:
   bool mouseChildren;
   CachedExtent mExtentCache[3];
protected:
   QuickVec<DisplayObject *> mChildren;


public:
   DisplayObjectContainer(bool inInitRef = false) : DisplayObject(inInitRef), mouseChildren(true) { }
   NmeObjectType getObjectType() { return notDisplayObjectContainer; }

   void decodeStream(ObjectStreamIn &inStream);
   void encodeStream(ObjectStreamOut &inStream);

   void addChild(DisplayObject *inChild);
   void setChildIndex(DisplayObject *inChild);
   void swapChildrenAt(int inChild1, int inChild2);
   void removeChild(DisplayObject *inChild);
   void removeChildAt(int inIndex);
   void setChildIndex(DisplayObject *inChild,int inNewIndex);
   DisplayObject *getChildAt(int index);

   void RemoveChildFromList(DisplayObject *inChild);

   void Render( const RenderTarget &inTarget, const RenderState &inState );
   bool IsCacheDirty();
   void ClearCacheDirty();
   bool NonNormalBlendChild();
   void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap,bool inIncludeStroke);
   void DirtyCache(bool inParentOnly = false);
   virtual void DirtyExtent();
   virtual void ClearExtentDirty();

   bool IsInteractive() const { return true; }

   void hackAddChild(DisplayObject *inObj) { mChildren.push_back(inObj); } 
   void hackRemoveChildren() { mChildren.resize(0); }

   bool getMouseChildren() { return mouseChildren; }
   void setMouseChildren(bool inVal) { mouseChildren = inVal; }


protected:
   ~DisplayObjectContainer();
};





class DirectRenderer : public DisplayObject
{
   typedef void (*RenderFunc)(void *,const Rect &inClipRect,const Transform &inTransform);

public:
   DirectRenderer( RenderFunc inOnRender ) : onRender(inOnRender), renderHandle(0) { }

   void Render( const RenderTarget &inTarget, const RenderState &inState );

   void *renderHandle;
   RenderFunc onRender;
};

class SimpleButton : public DisplayObjectContainer
{
public:
   enum { stateUp=0, stateDown, stateOver, stateHitTest, stateSIZE };

   DisplayObject *mState[stateSIZE];
   bool enabled;
   bool useHandCursor;
   int  mMouseState;


   SimpleButton(bool inInitRef = false);
   ~SimpleButton();

   void RemoveChildFromList(DisplayObject *inChild);

   void setMouseState(int inState);
   void Render( const RenderTarget &inTarget, const RenderState &inState );
   void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen,bool inIncludeStroke);
   bool IsCacheDirty();
   void ClearCacheDirty();
   bool NonNormalBlendChild();
   void DirtyCache(bool inParentOnly = false);

   bool getEnabled() const { return enabled; }
   void setEnabled(bool inEnabled) { enabled = inEnabled; }
   bool getUseHandCursor() const { return useHandCursor; }
   void setUseHandCursor(bool inUseHandCursor) { useHandCursor = inUseHandCursor; }

   void setState(int inState, DisplayObject *inObject);

   void decodeStream(ObjectStreamIn &inStream);
   void encodeStream(ObjectStreamOut &inStream);

};



double GetTimeStamp();

enum PopupKeyboardMode
{
   pkmOff    = 0x0000,
   pkmDumb   = 0x0001,
   pkmSmart  = 0x0002,
   pkmNative = 0x0003,
};

class Stage : public DisplayObjectContainer
{
public:
   Stage(bool inInitRef=false);
   static Stage *GetCurrent() { return gCurrentStage; }

   virtual void Flip() = 0;
   virtual void GetMouse() = 0;
   virtual Surface *GetPrimarySurface() = 0;
   virtual void PollNow() { }

   virtual void BeginRenderStage(bool inDoClear);
   virtual void RenderStage();
   virtual void EndRenderStage();
   virtual void ResizeWindow(int inWidth, int inHeight) {};

   virtual bool isOpenGL() const = 0;
   virtual int getWindowFrameBufferId() { return 0; };

   void SetEventHandler(EventHandler inHander,void *inUserData);
   void SetNominalSize(int inWidth,int inHeight);
   virtual void   setOpaqueBackground(uint32 inBG);
   DisplayObject *HitTest(UserPoint inPoint,DisplayObject *inRoot=0,bool inRecurse=true);
   virtual void SetFullscreen(bool inFullscreen) { }
   virtual void SetResolution(int inWidth, int inHeight) { }
   virtual void SetScreenMode(ScreenMode mode) { }
   virtual void ShowCursor(bool inShow) { };
   virtual void SetCursor(Cursor inCursor)=0;
   virtual void PopupKeyboard(PopupKeyboardMode inMode, WString *inValue=0) { };
   virtual void SetPopupTextSelection(int inSel0, int inSel1) { }
   double GetNextWake() { return mNextWake; }
   virtual void SetNextWakeDelay(double inNextWake);

   virtual bool getMultitouchSupported() { return false; }
   virtual void setMultitouchActive(bool inActive) {  }
   virtual bool getMultitouchActive() {  return false; }

   virtual uint32 getBackgroundMask() { return 0xffffffff; }

   virtual const char *getJoystickName(int id) { return NULL; }
   virtual void onTextFieldText(const std::string &inText, int inPos0, int inPos1);
   virtual void onTextFieldSelect(int inPos0, int inPos1);


   Matrix GetFullMatrix(bool inStageScaling);
   bool FinishEditOnEnter();
   bool BuildCache();

   void setFocusRect(bool inVal) { focusRect = inVal; }
   bool getFocusRect() const { return focusRect; }
   UserPoint getMousePos() const { return mLastMousePos; }
   virtual double getStageWidth();
   virtual double getStageHeight();
   virtual double getDPIScale() { return 1.0; }
   int getScaleMode() const { return scaleMode; }
   void setScaleMode(int inMode);
   int getAlign() const { return align; }
   void setAlign(int inAlign);
   int getQuality() const { return quality; }
   void setQuality(int inQuality);
   int getDisplayState() const { return displayState; }
   void setDisplayState(int inDisplayState);
   int GetAA();


   void RemovingFromStage(DisplayObject *inObject);
   Stage  *getStage() { return this; }

   virtual class StageVideo *createStageVideo(void *) { return 0; }
   virtual void cleanStageVideo() {}

   virtual void setTitle(const std::string &) { }
   virtual std::string getTitle() { return ""; }


   DisplayObject *GetFocusObject() { return mFocusObject; }
   void SetFocusObject(DisplayObject *inObj,FocusSource inSource=fsProgram,int inKey=0);
   void HandleEvent(Event &inEvent);

protected:
   ~Stage();
   void CalcStageScaling(double inW,double inH);
   EventHandler mHandler;
   void         *mHandlerData;
   bool         focusRect;
   UserPoint    mLastMousePos;
   StageScaleMode scaleMode;
   StageAlign     align;
   StageQuality   quality;
   StageDisplayState   displayState;
   RenderTarget   currentTarget;

   Matrix         mStageScale;

   int            mNominalWidth;
   int            mNominalHeight;

   double         mNextWake;

   DisplayObject *mFocusObject;
   DisplayObject *mMouseDownObject;
   SimpleButton  *mSimpleButton;

   static Stage  *gCurrentStage;

public:
      //Window pointer locking
   virtual void ConstrainCursorToWindowFrame(bool inLock) { };
   virtual void SetCursorPositionInWindow(int inX, int inY) { };
   virtual void SetStageWindowPosition(int inX, int inY) { };
   virtual int GetWindowX() { return 0; };
   virtual int GetWindowY() { return 0; };

};

class HardwareSurface;
class HardwareContext;
class HardwareRenderer;

class ManagedStage : public Stage
{
public:
   ManagedStage(int inW,int inH,int inFlags);
   ~ManagedStage();

   void SetCursor(Cursor inCursor);
   bool isOpenGL() const { return mHardwareRenderer; }
   Surface *GetPrimarySurface();

   int Width() { return mActiveWidth; }
   int Height() { return mActiveHeight; }

   double getStageWidth() { return mActiveWidth; }
   double getStageHeight() { return mActiveHeight; }


   void SetActiveSize(int inW,int inH);
   void PumpEvent(Event &inEvent);
   void Flip() { }
   void GetMouse() { }

protected:
   double          mFrameRate;
   int             mActiveWidth;
   int             mActiveHeight;
   HardwareSurface *mHardwareSurface;
   HardwareRenderer *mHardwareRenderer;
   bool            mIsHardware;
   Cursor          mCursor;
};





class Frame : public Object
{
public:
   virtual Stage *GetStage() = 0;

   NmeObjectType getObjectType() { return notFrame; }
};

enum WindowFlags
{
   wfFullScreen     = 0x00000001,
   wfBorderless     = 0x00000002,
   wfResizable      = 0x00000004,
   wfHardware       = 0x00000008,
   wfVSync          = 0x00000010,
   wfHW_AA          = 0x00000020,
   wfHW_AA_HIRES    = 0x00000060,
   wfAllowShaders   = 0x00000080,
   wfRequireShaders = 0x00000100,
   wfDepthBuffer    = 0x00000200,
   wfStencilBuffer  = 0x00000400,
   wfSingleInstance = 0x00000800,
   wfScaleBase      = 0x00001000,
   wfScaleMask      = 0x0000f000,
};

enum WindowScaleMode
{
   wsmNative,
   wsmGame,
   wsmCentre,
   wsmUiScaled,
   wsmGamePixels,
   wsmGameStretch,
};


void StartAnimation();
void PauseAnimation();
void ResumeAnimation();
void StopAnimation();

Stage *IPhoneGetStage();

typedef void (*FrameCreationCallback)(Frame *);

void CreateMainFrame( FrameCreationCallback inOnFrame, int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, Surface *inIcon );


} // end namespace nme

#endif

