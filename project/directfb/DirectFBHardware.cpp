#include <Graphics.h>
#include <Surface.h>
#include <directfb.h>


namespace nme
{


// --- HardwareContext -----------------------------


class DirectFBHardwareContext : public HardwareContext
{
public:
   IDirectFB *mDirectFB;
   IDirectFBSurface *mPrimarySurface;
   int mWidth;
   int mHeight;
   
   DirectFBHardwareContext(IDirectFB *inDirectFB, IDirectFBSurface *inSurface)
   {
      mDirectFB = inDirectFB;
      mPrimarySurface = inSurface;
      mWidth = mHeight = 0;
   }
   
   void SetWindowSize(int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
   }
   
   void SetQuality(StageQuality inQuality) {}
   
   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mPrimarySurface->Clear(mPrimarySurface, 0xFF, 0xFF, 0xFF, 0xFF);
   }
   
   void EndRender()
   {
      mPrimarySurface->Flip(mPrimarySurface, NULL, (DFBSurfaceFlipFlags)0);
   }
   
   void SetViewport(const Rect &inRect) {}
   void Clear(uint32 inColour,const Rect *inRect=0) {}
   void Flip() {}
   void DestroyNativeTexture(void *) {}
   
   int Width() const { return mWidth; }
   int Height() const { return mHeight; } 
   
   class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags);
   void Render(const RenderState &inState, const HardwareCalls &inCalls) {}
   void BeginBitmapRender(Surface *inSurface,uint32 inTint, bool inRepeat, bool inSmooth) {}
   void RenderBitmap(const Rect &inSrc, int inX, int inY) {}
   void EndBitmapRender() {}
};


class DirectFBTexture : public Texture
{
public:
   unsigned int flags;
   int          width;
   int          height;
   
   DirectFBTexture(DirectFBHardwareContext *inContext, Surface *inSurface, unsigned int inFlags)
   {
      
   }
   
   ~DirectFBTexture()
   {
      
   }
   
   void Bind(class Surface *inSurface, int inSlot) {}
   void BindFlags(bool inRepeat, bool inSmooth) {}
   
   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/width, inPixels.y/height);
   }
   
   UserPoint TexToPaddedTex(const UserPoint &inPixels)
   {
      return inPixels;
   }
};


class Texture *DirectFBHardwareContext::CreateTexture(class Surface *inSurface, unsigned int inFlags)
{
   return new DirectFBTexture(this, inSurface, inFlags);
}


HardwareContext *HardwareContext::current = 0;

HardwareContext *HardwareContext::CreateDirectFB(void *inDirectFB, void *inSurface)
{
   return new DirectFBHardwareContext((IDirectFB*)inDirectFB, (IDirectFBSurface*)inSurface);
}


HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders)
{
   return NULL;
}


// --- Hardware Jobs ---------------------------------------------------------------------


class HardwareRenderer : public Renderer
{
public:
   HardwareRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath, HardwareContext &inHardware)
   {
      mJob = &inJob;
      mPath = &inPath;
      mContext = &inHardware;
      
      DirectFBHardwareContext *context = (DirectFBHardwareContext*)&inHardware;
      mPrimarySurface = context->mPrimarySurface;
   }
   
   void Destroy() {};

   bool Render(const RenderTarget &inTarget, const RenderState &inState)
   {
      if (mJob->mIsTileJob)
      {
         printf("Render tile\n");
      }
      else if (mJob->mFill)
      {
         GraphicsSolidFill *solid = mJob->mFill->AsSolidFill();
         if (solid)
         {
            mPrimarySurface->SetColor(mPrimarySurface, solid->mRGB.c0, solid->mRGB.c1, solid->mRGB.c2, solid->mRGB.a);
         }
         else
         {
            GraphicsGradientFill *grad = mJob->mFill->AsGradientFill();
            if (grad)
            {
               
            }
            else
            {
               GraphicsBitmapFill *bmp = mJob->mFill->AsBitmapFill();
               //mTextureMapper = bmp->matrix.Inverse();
               //mSurface = bmp->bitmapData->IncRef();
               //mTexture = mSurface->GetOrCreateTexture(inHardware);
               //mElement.mBitmapRepeat = bmp->repeat;
               //mElement.mBitmapSmooth = bmp->smooth;
               mPrimarySurface->SetColor(mPrimarySurface, 0xFF, 0, 0, 0xFF);
             }
          }
      }
      
      if (mJob->mTriangles)
      {
         printf("Render triangle\n");
      }
      else if (mJob->mIsPointJob)
      {
         printf("Render point\n");
      }
      else if (mJob->mStroke)
      {
         printf("Render stroke\n");
      }
      else
      {
         const uint8* inCommands = (const uint8*)&mPath->commands[mJob->mCommand0];
         UserPoint *point = (UserPoint *)&mPath->data[mJob->mData0];
         
         float x0, y0, x1, y1;
         
         for(int i=0; i< mJob->mCommandCount; i++)
         {
            switch(inCommands[i])
            {
               case pcBeginAt:
                  //printf("begin at\n");
                  // fallthrough
               case pcMoveTo:
                  //printf("move to\n");
                  //printf("move to: %d %d \n", point->x, point->y);
                  x0 = point->x;
                  y0 = point->y;
                  point++;
                  break;

               case pcLineTo:
                  if (point->x > x1) x1 = point->x;
                  if (point->x < x0) x0 = point->x;
                  if (point->y > y1) y1 = point->y;
                  if (point->y < y0) y0 = point->y;
                  point++;
                  break;

               case pcCurveTo:
                  //printf("curve to\n");
                  point++;
                  break;
            }
         }
         
         mPrimarySurface->FillRectangle(mPrimarySurface, inState.mTransform.mMatrix->mtx + x0, inState.mTransform.mMatrix->mty + y0, x1 - x0, y1 - y0);
      }
      return true;
   };

   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent, bool inIncludeStroke) { return false; };
   bool Hits(const RenderState &inState) { return false; }
   
private:
   const GraphicsJob *mJob;
   const GraphicsPath *mPath;
   HardwareContext *mContext;
   IDirectFBSurface *mPrimarySurface;
};


Renderer *Renderer::CreateHardware(const GraphicsJob &inJob, const GraphicsPath &inPath, HardwareContext &inHardware)
{
   return new HardwareRenderer(inJob, inPath, inHardware);
}


// --- HardwareArrays ---------------------------------------------------------------------


HardwareArrays::HardwareArrays(Surface *inSurface,unsigned int inFlags)
{
   mFlags = inFlags;
   mSurface = inSurface;
   if (inSurface)
      inSurface->IncRef();
}

HardwareArrays::~HardwareArrays()
{
   if (mSurface)
      mSurface->DecRef();
}

bool HardwareArrays::ColourMatch(bool inWantColour)
{
   if (mVertices.empty())
      return true;
   return mColours.empty() != inWantColour;
}



// --- HardwareData ---------------------------------------------------------------------
HardwareData::~HardwareData()
{
   mCalls.DeleteAll();
}

HardwareArrays &HardwareData::GetArrays(Surface *inSurface,bool inWithColour,unsigned int inFlags)
{
   if (mCalls.empty() || mCalls.last()->mSurface != inSurface ||
           !mCalls.last()->ColourMatch(inWithColour) ||
           mCalls.last()->mFlags != inFlags )
   {
       HardwareArrays *arrays = new HardwareArrays(inSurface,inFlags);
       mCalls.push_back(arrays);
   }

   return *mCalls.last();
}



// --- Texture -----------------------------
void Texture::Dirty(const Rect &inRect)
{
   if (!mDirtyRect.HasPixels())
      mDirtyRect = inRect;
   else
      mDirtyRect = mDirtyRect.Union(inRect);
}

// --- HardwareContext -----------------------------


// Cache line thickness transforms...
static Matrix sLastMatrix;
double sLineScaleV = -1;
double sLineScaleH = -1;
double sLineScaleNormal = -1;


bool HardwareContext::Hits(const RenderState &inState, const HardwareCalls &inCalls )
{
   if (inState.mClipRect.w!=1 || inState.mClipRect.h!=1)
      return false;

   UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);
   UserPoint pos = inState.mTransform.mMatrix->ApplyInverse(screen);

   if (sLastMatrix!=*inState.mTransform.mMatrix)
   {
      sLastMatrix=*inState.mTransform.mMatrix;
      sLineScaleV = -1;
      sLineScaleH = -1;
      sLineScaleNormal = -1;
   }


    for(int c=0;c<inCalls.size();c++)
   {
      HardwareArrays &arrays = *inCalls[c];
      Vertices &vert = arrays.mVertices;

      // TODO: include extent in HardwareArrays

      DrawElements &elements = arrays.mElements;
      for(int e=0;e<elements.size();e++)
      {
         DrawElement draw = elements[e];

         if (draw.mPrimType == ptLineStrip)
         {
            if ( draw.mCount < 2 || draw.mWidth==0)
               continue;

            double width = 1;
            Matrix &m = sLastMatrix;
            switch(draw.mScaleMode)
            {
               case ssmNone: width = draw.mWidth; break;
               case ssmNormal:
               case ssmOpenGL:
                  if (sLineScaleNormal<0)
                     sLineScaleNormal =
                        sqrt( 0.5*( m.m00*m.m00 + m.m01*m.m01 +
                                    m.m10*m.m10 + m.m11*m.m11 ) );
                  width = draw.mWidth*sLineScaleNormal;
                  break;
               case ssmVertical:
                  if (sLineScaleV<0)
                     sLineScaleV =
                        sqrt( m.m00*m.m00 + m.m01*m.m01 );
                  width = draw.mWidth*sLineScaleV;
                  break;

               case ssmHorizontal:
                  if (sLineScaleH<0)
                     sLineScaleH =
                        sqrt( m.m10*m.m10 + m.m11*m.m11 );
                  width = draw.mWidth*sLineScaleH;
                  break;
            }

            double x0 = pos.x - width;
            double x1 = pos.x + width;
            double y0 = pos.y - width;
            double y1 = pos.y + width;
            double w2 = width*width;

            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;

            int prev = 0;
            if (p0.x<x0) prev |= 0x01;
            if (p0.x>x1) prev |= 0x02;
            if (p0.y<y0) prev |= 0x04;
            if (p0.y>y1) prev |= 0x08;
            if (prev==0 && pos.Dist2(p0)<=w2)
               return true;
            for(int i=1;i<draw.mCount;i++)
            {
               UserPoint p = v[i];
               int flags = 0;
               if (p.x<x0) flags |= 0x01;
               if (p.x>x1) flags |= 0x02;
               if (p.y<y0) flags |= 0x04;
               if (p.y>y1) flags |= 0x08;
               if (flags==0 && pos.Dist2(p)<=w2)
                  return true;
               if ( !(flags & prev) )
               {
                  // Line *may* pass though the point...
                  UserPoint vec = p-p0;
                  double len = sqrt(vec.x*vec.x + vec.y*vec.y);
                  if (len>0)
                  {
                     double a = vec.Dot(pos-p0)/len;
                     if (a>0 && a<1)
                     {
                        if ( (p0 + vec*a).Dist2(pos) < w2 )
                           return true;
                     }
                  }
               }
               prev = flags;
               p0 = p;
            }
         }
         else if (draw.mPrimType == ptTriangleFan)
         {
            if (draw.mCount<3)
               continue;
            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;
            int count_left = 0;
            for(int i=1;i<=draw.mCount;i++)
            {
               UserPoint p = v[i%draw.mCount];
               if ( (p.y<pos.y) != (p0.y<pos.y) )
               {
                  // Crosses, but to the left?
                  double ratio = (pos.y-p0.y)/(p.y-p0.y);
                  double x = p0.x + (p.x-p0.x) * ratio;
                  if (x<pos.x)
                     count_left++;
               }
               p0 = p;
            }
            if (count_left & 1)
               return true;
         }
         else if (draw.mPrimType == ptTriangles)
         {
            if (draw.mCount<3)
               continue;
            UserPoint *v = &vert[ draw.mFirst ];
			
			   int numTriangles = draw.mCount / 3;
			
            for(int i=0;i<numTriangles;i++)
            {
               UserPoint base = *v++;
               bool bgx = pos.x>base.x;
               if ( bgx!=(pos.x>v[0].x) || bgx!=(pos.x>v[1].x) )
               {
                  bool bgy = pos.y>base.y;
                  if ( bgy!=(pos.y>v[0].y) || bgy!=(pos.y>v[1].y) )
                  {
                     UserPoint v0 = v[0] - base;
                     UserPoint v1 = v[1] - base;
                     UserPoint v2 = pos - base;
                     double dot00 = v0.Dot(v0);
                     double dot01 = v0.Dot(v1);
                     double dot02 = v0.Dot(v2);
                     double dot11 = v1.Dot(v1);
                     double dot12 = v1.Dot(v2);

                     // Compute barycentric coordinates
                     double denom = (dot00 * dot11 - dot01 * dot01);
                     if (denom!=0)
                     {
                        denom = 1 / denom;
                        double u = (dot11 * dot02 - dot01 * dot12) * denom;
                        if (u>=0)
                        {
                           double v = (dot00 * dot12 - dot01 * dot02) * denom;

                           // Check if point is in triangle
                           if ( (v >= 0) && (u + v < 1) )
                              return true;
                        }
                     }
                  }
               }
               v+=2;
            }
         }
      }
   }

   return false;
}



} // end namespace nme

