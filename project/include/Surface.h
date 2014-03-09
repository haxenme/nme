#ifndef NME_SURFACE_H
#define NME_SURFACE_H

#include <Graphics.h>
#include <Utils.h>
#include <ByteArray.h>
#include <Filters.h>

#include "Hardware.h"

// ---- Surface API --------------

namespace nme
{


void HintColourOrder(bool inRedFirst);

extern int gTextureContextVersion;

enum
{
   SURF_FLAGS_NOT_REPEAT_IF_NON_PO2    = 0x0001,
   SURF_FLAGS_USE_PREMULTIPLIED_ALPHA  = 0x0002,
   SURF_FLAGS_HAS_PREMULTIPLIED_ALPHA  = 0x0004,
};

class Texture
{
public:
   virtual ~Texture() {};

   virtual void Bind(class ImageBuffer *inImage,int inSlot)=0;
   virtual void BindFlags(bool inRepeat,bool inSmooth)=0;
   virtual UserPoint PixelToTex(const UserPoint &inPixels)=0;
   virtual UserPoint TexToPaddedTex(const UserPoint &inPixels)=0;
   virtual void Dirty(const Rect &inRect) = 0;
   virtual bool IsCurrentVersion() = 0;
};


class ImageBuffer : public Object
{
protected: // Use 'DecRef'
   virtual       ~ImageBuffer() { };
public:
   virtual int Width() const =0;
   virtual int Height() const =0;
   virtual unsigned int GetFlags() const = 0;
   virtual void SetFlags(unsigned int inFlags) = 0;
   virtual PixelFormat Format()  const = 0;
   virtual const uint8 *GetBase() const = 0;
   virtual int GetStride() const = 0;
   virtual int BytesPP() const =0;
   virtual void Clear(uint32 inColour,const Rect *inRect=0) = 0;
   virtual int Version() const  = 0;
   virtual Texture *GetTexture()  = 0;
   virtual Texture *GetOrCreateTexture(HardwareContext &inHardware) = 0;

   inline const uint8 *Row(int inY) const { return GetBase() + GetStride()*inY; }
};

class Surface : public ImageBuffer
{
public:
   // Non-PO2 will generate dodgy repeating anyhow...
   Surface() : mTexture(0), mVersion(0), mFlags(SURF_FLAGS_NOT_REPEAT_IF_NON_PO2), mAllowTrans(true) { };

   // Implementation depends on platform.
   static Surface *Load(const OSChar *inFilename);
   static Surface *LoadFromBytes(const uint8 *inBytes,int inLen);
   bool Encode( nme::ByteArray *outBytes,bool inPNG,double inQuality);

   Surface *IncRef() { mRefCount++; return this; }

   virtual unsigned int GetFlags() const { return mFlags; }
   virtual void SetFlags(unsigned int inFlags) { mFlags = inFlags; }
   virtual int         GPUFormat() const { return Format(); }
   virtual bool GetAllowTrans() const { return mAllowTrans; }
   virtual void SetAllowTrans(bool inAllowTrans) { mAllowTrans = inAllowTrans; }

   virtual void Zero() { Clear(0); }
   virtual void createHardwareSurface() { }
   virtual void destroyHardwareSurface() { }
   virtual void dispose() { }
   virtual void dumpBits() { /*printf("Dumping bits from Surface\n");*/  }
   virtual void setGPUFormat( PixelFormat pf ) {}
   virtual void unmultiplyAlpha() { }

   int BytesPP() const { return Format()==pfAlpha ? 1 : 4; }

   virtual RenderTarget BeginRender(const Rect &inRect,bool inForHitTest=false)=0;
   virtual void EndRender()=0;

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff ) const = 0;
   virtual void StretchTo(const RenderTarget &outTarget,
                          const Rect &inSrcRect, const DRect &inDestRect) const = 0;
   virtual void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
									 int inPosX, int inPosY,
									 int inSrcChannel, int inDestChannel ) const = 0;

   Texture *GetTexture() { return mTexture; }
   Texture *GetOrCreateTexture(HardwareContext &inHardware);
   void Bind(HardwareContext &inHardware,int inSlot=0);

   virtual Surface *clone() { return 0; }
   virtual void getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder=false,bool inLittleEndian=false) { }
   virtual void setPixels(const Rect &inRect,const uint32 *intPixels,bool inIgnoreOrder=false,bool inLittleEndian=false) { }
   virtual void getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect)
   {
      outRect = Rect(0,0,Width(),Height());
   }
   virtual uint32 getPixel(int inX,int inY) { return 0; }
   virtual void setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo=false) { }
   virtual void scroll(int inDX,int inDY) { }
   virtual void colorTransform(const Rect &inRect, ColorTransform &inTransform) { }
   virtual void applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter) { }

   virtual void noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale) { }

   int Version() const  { return mVersion; }


protected:
   mutable int   mVersion;
   Texture       *mTexture;
   virtual       ~Surface();
   unsigned int  mFlags;
   bool          mAllowTrans;
};

// Helper class....
class AutoSurfaceRender
{
   Surface *mSurface;
   RenderTarget mTarget;
public:
   AutoSurfaceRender(Surface *inSurface) : mSurface(inSurface),
       mTarget(inSurface->BeginRender( Rect(inSurface->Width(),inSurface->Height()),false ) ) { }
   AutoSurfaceRender(Surface *inSurface,const Rect &inRect) : mSurface(inSurface),
       mTarget(inSurface->BeginRender(inRect,false)) { }
   ~AutoSurfaceRender() { mSurface->EndRender(); }
   const RenderTarget &Target() { return mTarget; }

};

class SimpleSurface : public Surface
{
public:
   SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign=4,int inGPUPixelFormat=-1);

   int Width() const  { return mWidth; }
   int Height() const  { return mHeight; }
   PixelFormat Format() const  { return mPixelFormat; }
   int         GPUFormat() const  { return mGPUPixelFormat; }
   void Clear(uint32 inColour,const Rect *inRect);
   void Zero();


   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest);
   void EndRender();

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff ) const;

   virtual void StretchTo(const RenderTarget &outTarget,
                          const Rect &inSrcRect, const DRect &inDestRect) const;

	virtual void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
									 int inPosX, int inPosY,
									 int inSrcChannel, int inDestChannel ) const;

   virtual void colorTransform(const Rect &inRect, ColorTransform &inTransform);
   virtual void setGPUFormat( PixelFormat pf ) { mGPUPixelFormat = pf; }
   void unmultiplyAlpha();
   
   const uint8 *GetBase() const { return mBase; }
   int GetStride() const { return mStride; }
   Surface *clone();
   void getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder=false, bool inLittleEndian=false);
   void setPixels(const Rect &inRect,const uint32 *intPixels,bool inIgnoreOrder=false, bool inLittleEndian=false);
   void getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect);
   uint32 getPixel(int inX,int inY);
   void setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo=false);
   void scroll(int inDX,int inDY);
   void applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter);
   void noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale);
   void createHardwareSurface();
   void destroyHardwareSurface();
   void dispose();
   
   void dumpBits();


protected:
   int           mWidth;
   int           mHeight;
   PixelFormat   mPixelFormat;
   int           mGPUPixelFormat;
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
   HardwareSurface(HardwareRenderer *inContext);

   int Width() const { return mHardware->Width(); }
   int Height() const { return mHardware->Height(); }
   PixelFormat Format()  const { return pfHardware; }
   const uint8 *GetBase() const { return 0; }
   int GetStride() const { return 0; }
   void Clear(uint32 inColour,const Rect *inRect=0) { mHardware->Clear(inColour,inRect); }
   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mHardware->BeginRender(inRect,inForHitTest);
      return RenderTarget(inRect,mHardware);
   }
   void EndRender()
   {
      mHardware->EndRender();
   }

   void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint ) const { }
   void StretchTo(const RenderTarget &outTarget,
                          const Rect &inSrcRect, const DRect &inDestRect) const { }
	void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
									 int inPosX, int inPosY,
									 int inSrcChannel, int inDestChannel ) const  { }

   Surface *clone();
   void getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder=false);
   void setPixels(const Rect &inRect,const uint32 *intPixels,bool inIgnoreOrder=false);

   protected:
      ~HardwareSurface();
   private:
      HardwareRenderer *mHardware;
};


} // end namespace nme


#endif
