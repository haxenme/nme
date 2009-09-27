#ifndef SURFACE_H
#define SURFACE_H

#include <Graphics.h>

// ---- Surface API --------------



// Need a context ?
struct NativeTexture;
NativeTexture *CreateNativeTexture(Surface *inSoftwareSurface);
void DestroyNativeTexture(NativeTexture *inTexture);


void HintColourOrder(bool inRedFirst);

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

	virtual void Clear(uint32 inColour) = 0;
	virtual void Zero() { Clear(0); }

   int BytesPP() const { return Format()==pfAlpha ? 1 : 4; }
   const uint8 *Row(int inY) const { return GetBase() + GetStride()*inY; }

   virtual RenderTarget BeginRender(const Rect &inRect)=0;
   virtual void EndRender()=0;

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       uint32 inTint=0xffffff,bool inUseSrcAlphaOnly=false)=0;

   virtual NativeTexture *GetTexture() { return mTexture; }
   virtual void SetTexture(NativeTexture *inTexture);


protected:
   NativeTexture *mTexture;
	int           mRefCount;
	virtual       ~Surface();
};

// Helper class....
class AutoSurfaceRender
{
	Surface *mSurface;
	RenderTarget mTarget;
public:
	AutoSurfaceRender(Surface *inSurface, const Rect *inRect=0)
	{
		mSurface = inSurface;
		mTarget = inRect ? inSurface->BeginRender( *inRect ) :
		                 inSurface->BeginRender( Rect(mSurface->Width(),mSurface->Height()) );
	}
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
	void Clear(uint32 inColour);
	void Zero();


   RenderTarget BeginRender(const Rect &inRect);
   void EndRender();

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inDX, int inDY,
                       uint32 inTint=0xffffff,bool inUseSrcAlphaOnly = false);

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



#endif
