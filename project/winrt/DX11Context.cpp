#include <Display.h>
#include <Graphics.h>
#include <Surface.h>

namespace nme
{

class DX11Context : public HardwareContext
{
public:
   DX11Context(void *inWindow)
   {
      mWidth = mHeight = 0;
   }

   void SetWindowSize(int inWidth,int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
   }

   void SetQuality(StageQuality inQuality)
   {
   }

   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
   }

   void EndRender()
   {
   }


   void SetViewport(const Rect &inRect)
   {
   }

   void Clear(uint32 inColour,const Rect *inRect=0)
   {
   }

   void Flip()
   {
   }

   int Width() const { return mWidth; }

   int Height() const { return mHeight; } 

   class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags)
   {
      return 0;
   }

   void Render(const RenderState &inState, const HardwareCalls &inCalls )
   {
   }

   void BeginBitmapRender(Surface *inSurface,uint32 inTint,bool inRepeat,bool inSmooth)
   {
   }

   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
   }

   void EndBitmapRender()
   {
   }

   int mWidth;
   int mHeight;
};

HardwareContext *HardwareContext::current = 0;

HardwareContext *HardwareContext::CreateDX11(void *inWindow)
{
   return new DX11Context(inWindow);
}

} // end namespace nme
