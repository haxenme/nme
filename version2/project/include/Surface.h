#ifndef NME_SURFACE_H
#define NME_SURFACE_H

#include <Graphics.h>

// ---- Surface API --------------

namespace nme
{


void HintColourOrder(bool inRedFirst);

class Texture
{
public:
   virtual ~Texture() {};
   virtual void Bind(class Surface *inSurface,int inSlot)=0;
   virtual UserPoint PixelToTex(const UserPoint &inPixels)=0;

   void Dirty(const Rect &inRect);

   Rect mDirtyRect;
};

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

   virtual void Clear(uint32 inColour,const Rect *inRect=0) = 0;
   virtual void Zero() { Clear(0); }

   int BytesPP() const { return Format()==pfAlpha ? 1 : 4; }
   const uint8 *Row(int inY) const { return GetBase() + GetStride()*inY; }

   virtual RenderTarget BeginRender(const Rect &inRect)=0;
   virtual void EndRender()=0;

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff ) = 0;

   Texture *GetTexture() { return mTexture; }
   void Bind(HardwareContext &inHardware,int inSlot=0);


protected:
   Texture       *mTexture;
   int           mRefCount;
   virtual       ~Surface();
};

// Helper class....
class AutoSurfaceRender
{
   Surface *mSurface;
   RenderTarget mTarget;
public:
   AutoSurfaceRender(Surface *inSurface) : mSurface(inSurface),
       mTarget(inSurface->BeginRender( Rect(inSurface->Width(),inSurface->Height()) ) ) { }
   AutoSurfaceRender(Surface *inSurface,const Rect &inRect) : mSurface(inSurface),
       mTarget(inSurface->BeginRender(inRect)) { }
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
   void Clear(uint32 inColour,const Rect *inRect);
   void Zero();


   RenderTarget BeginRender(const Rect &inRect);
   void EndRender();

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff );

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

class HardwareSurface : public Surface
{
public:
   HardwareSurface(HardwareContext *inContext);

   int Width() const { return mHardware->Width(); }
   int Height() const { return mHardware->Height(); }
   PixelFormat Format()  const { return pfHardware; }
   const uint8 *GetBase() const { return 0; }
   int GetStride() const { return 0; }
   void Clear(uint32 inColour,const Rect *inRect=0) { mHardware->Clear(inColour,inRect); }
   RenderTarget BeginRender(const Rect &inRect)
   {
      mHardware->BeginRender(inRect);
      return RenderTarget(inRect,mHardware);
   }
   void EndRender() { }

   void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint ) { }

   protected:
      ~HardwareSurface();
   private:
      HardwareContext *mHardware;
};


} // end namespace nme


#endif
