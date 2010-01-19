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
   etUnknown,
   etKey,
   etMouseMove,
   etMouseButton,
   etResize,
   etRender,
   etQuit,

   // Internal for now...
   etDestroyHandler,
   etRedraw,
   etTimer,
};


struct Event
{
   Event(EventType inType=etUnknown) :
        type(inType), x(0), y(0), value(0), id(0), flags(0)
   {
   }

   EventType type;
   int       x,y;
   int       value;
   int       id;
   int       flags;
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
   void   setScrollRect(const DRect &inRect);
   void   setMask(DisplayObject *inMask);
   DisplayObject   *getMask() { return mMask; }

   void   setAlpha(double inAlpha);


   const Transform &getTransform();

   DisplayObject *getParent();

   double getMouseX();
   double getMouseY();
   DisplayObject *getRoot();
   Stage  *getStage();

   struct LoaderInfo &GetLoaderInfo();

   BlendMode blendMode;
   bool cacheAsBitmap;
   ColorTransform  colorTransform;
   QuickVec<class Filter *> filters;

   std::wstring  name;
   uint32 opaqueBackground;
   DRect   scale9Grid;
   DRect   scrollRect;
   bool   visible;

   virtual void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap);



   virtual void Render( const RenderTarget &inTarget, const RenderState &inState );

   void RenderBitmap( const RenderTarget &inTarget, const RenderState &inState );
   void DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState );

   virtual void DirtyUp(uint32 inFlags);
   virtual void DirtyDown(uint32 inFlags);
   virtual bool NonNormalBlendChild() { return false; }

   void SetParent(DisplayObjectContainer *inParent);

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
   void removeChild(DisplayObject *inChild);
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
