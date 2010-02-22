#include <Graphics.h>
#include <Surface.h>

namespace nme
{

// TODO: invlidate/cache extents (do for whole lot at once)

Graphics::Graphics(bool inInitRef) : Object(inInitRef)
{
   mRotation0 = 0;
   mCursor = UserPoint(0,0);
   mHardwareData = 0;
   mPathData = new GraphicsPath;
   mBuiltHardware = 0;
}


Graphics::~Graphics()
{
   clear();
   mPathData->DecRef();
}


void Graphics::clear()
{
   mFillJob.clear();
   mLineJob.clear();
   mTriJob.clear();

   // clear jobs
   for(int i=0;i<mJobs.size();i++)
      mJobs[i].clear();
   mJobs.resize(0);

   if (mHardwareData)
   {
      delete mHardwareData;
      mHardwareData = 0;
   }
   mPathData->clear();

   mExtent0 = Extent2DF();
   mRotation0 = 0;
   mBuiltHardware = 0;
   mMeasuredJobs = 0;
   mCursor = UserPoint(0,0);
}

#define SIN45 0.70710678118654752440084436210485
#define TAN22 0.4142135623730950488016887242097

void Graphics::drawEllipse(float x,float  y,float  width,float  height)
{
   float w = width;
   float w_ = w*SIN45;
   float cw_ = w*TAN22;
   float h = height;
   float h_ = h*SIN45;
   float ch_ = h*TAN22;

   Flush();

   mPathData->moveTo(x+w,y);
   mPathData->curveTo(x+w,  y+ch_, x+w_, y+h_);
   mPathData->curveTo(x+cw_,y+h,   x,    y+h);
   mPathData->curveTo(x-cw_,y+h,   x-w_, y+h_);
   mPathData->curveTo(x-w,  y+ch_, x-w,  y);
   mPathData->curveTo(x-w,  y-ch_, x-w_, y-h_);
   mPathData->curveTo(x-cw_,y-h,   x,    y-h);
   mPathData->curveTo(x+cw_,y-h,   x+w_, y-h_);
   mPathData->curveTo(x+w,  y-ch_, x+w,  y);

   Flush();
}

void Graphics::drawRoundRect(float x,float  y,float  width,float  height,float  rx,float  ry)
{
   rx *= 0.5;
   ry *= 0.5;
   float w = width*0.5;
   x+=w;
   if (rx>w) rx = w;
   int   lw = w - rx;
   float w_ = lw + rx*SIN45;
   float cw_ = lw + rx*TAN22;
   float h = height*0.5;
   y+=h;
   if (ry>h) ry = h;
   int   lh = h - ry;
   float h_ = lh + ry*SIN45;
   float ch_ = lh + ry*TAN22;

   Flush();

   mPathData->moveTo(x+w,y+lh);
   mPathData->curveTo(x+w,  y+ch_, x+w_, y+h_);
   mPathData->curveTo(x+cw_,y+h,   x+lw,    y+h);
   mPathData->lineTo(x-lw,    y+h);
   mPathData->curveTo(x-cw_,y+h,   x-w_, y+h_);
   mPathData->curveTo(x-w,  y+ch_, x-w,  y+lh);
   mPathData->lineTo( x-w, y-lh);
   mPathData->curveTo(x-w,  y-ch_, x-w_, y-h_);
   mPathData->curveTo(x-cw_,y-h,   x-lw,    y-h);
   mPathData->lineTo(x+lw,    y-h);
   mPathData->curveTo(x+cw_,y-h,   x+w_, y-h_);
   mPathData->curveTo(x+w,  y-ch_, x+w,  y-lh);
   mPathData->lineTo(x+w,  y+lh);

   Flush();
}

void Graphics::drawPath(const QuickVec<uint8> &inCommands, const QuickVec<float> &inData,
           WindingRule inWinding )
{
   int n = inCommands.size();
   if (n==0 || inData.size()<2)
      return;

   const UserPoint *point = (UserPoint *)&inData[0];
   const UserPoint *last =  point + inData.size()/2;

   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   for(int i=0;i<n && point<last;i++)
   {
      switch(inCommands[i])
      {
         case pcWideMoveTo:
            point++;
            if (point==last) break;
         case pcMoveTo:
            mPathData->moveTo(point->x,point->y);
            mCursor = *point++;
            break;

         case pcWideLineTo:
            point++;
            if (point==last) break;
         case pcLineTo:
            mPathData->lineTo(point->x,point->y);
            mCursor = *point++;
            break;

         case pcCurveTo:
            if (point+1==last) break;
            mPathData->curveTo(point->x,point->y,point[1].x,point[1].y);
            mCursor = point[1];
            point += 2;
      }
   }
}



void Graphics::drawGraphicsDatum(IGraphicsData *inData)
{
   switch(inData->GetType())
   {
      case gdtPath:
         {
         GraphicsPath *path = inData->AsPath();
         drawPath(path->commands, path->data, path->winding);
         break;
         }
      case gdtEndFill:
         endFill();
         break;
      case gdtSolidFill:
      case gdtGradientFill:
         Flush(false,true);
         if (mFillJob.mFill)
            mFillJob.mFill->DecRef();
         mFillJob.mFill = inData->AsIFill();
         mFillJob.mFill->IncRef();
         if (mFillJob.mCommand0 == mPathData->commands.size())
            mPathData->initPosition(mCursor);
         break;
      case gdtStroke:
         {
         Flush(true,false);
         if (mLineJob.mStroke)
         {
            mLineJob.mStroke->DecRef();
            mLineJob.mStroke = 0;
         }
         GraphicsStroke *stroke = inData->AsStroke();
         if (stroke->thickness>=0 && stroke->fill)
         {
            mLineJob.mStroke = stroke;
            mLineJob.mStroke->IncRef();
            if (mLineJob.mCommand0 == mPathData->commands.size())
               mPathData->initPosition(mCursor);
         }
         }
         break;

   }
}

void Graphics::drawGraphicsData(IGraphicsData **graphicsData,int inN)
{
   for(int i=0;i<inN;i++)
      drawGraphicsDatum(graphicsData[i]);
}

void Graphics::beginFill(unsigned int color, float alpha)
{
   Flush(false,true);
   if (mFillJob.mFill)
      mFillJob.mFill->DecRef();
   mFillJob.mFill = new GraphicsSolidFill(color,alpha);
   mFillJob.mFill->IncRef();
   if (mFillJob.mCommand0 == mPathData->commands.size())
      mPathData->initPosition(mCursor);
}

void Graphics::endFill()
{
   Flush(false,true);
   if (mFillJob.mFill)
   {
      mFillJob.mFill->DecRef();
      mFillJob.mFill = 0;
   }
}

void Graphics::beginBitmapFill(Surface *bitmapData, const Matrix &inMatrix,
   bool inRepeat, bool inSmooth)
{
   Flush(false,true);
   if (mFillJob.mFill)
      mFillJob.mFill->DecRef();
   mFillJob.mFill = new GraphicsBitmapFill(bitmapData,inMatrix,inRepeat,inSmooth);
   mFillJob.mFill->IncRef();
   if (mFillJob.mCommand0 == mPathData->commands.size())
      mPathData->initPosition(mCursor);
}


void Graphics::lineStyle(double thickness, unsigned int color, double alpha,
                  bool pixelHinting, StrokeScaleMode scaleMode,
                  StrokeCaps caps,
                  StrokeJoints joints, double miterLimit)
{
   Flush(true,false);
   if (mLineJob.mStroke)
   {
      mLineJob.mStroke->DecRef();
      mLineJob.mStroke = 0;
   }
   if (thickness>=0)
   {
      IGraphicsFill *solid = new GraphicsSolidFill(color,alpha);
      mLineJob.mStroke = new GraphicsStroke(solid,thickness,pixelHinting,
          scaleMode,caps,joints,miterLimit);
      mLineJob.mStroke->IncRef();
      if (mLineJob.mCommand0 == mPathData->commands.size())
         mPathData->initPosition(mCursor);
   }
}



void Graphics::lineTo(float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   mPathData->lineTo(x,y);
   mCursor = UserPoint(x,y);
}

void Graphics::moveTo(float x, float y)
{
   mPathData->moveTo(x,y);
   mCursor = UserPoint(x,y);
}

void Graphics::curveTo(float cx, float cy, float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   mPathData->curveTo(cx,cy,x,y);
   mCursor = UserPoint(x,y);
}

void Graphics::arcTo(float cx, float cy, float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   mPathData->arcTo(cx,cy,x,y);
   mCursor = UserPoint(x,y);
}





// This routine converts a list of "GraphicsPaths" (mItems) into a list
//  of LineData and SolidData.
// The items intermix fill-styles and line-stypes with move/draw/triangle
//  geometry data - this routine separates them out.

void Graphics::Flush(bool inLine, bool inFill)
{
   int n = mPathData->commands.size();
   int d = mPathData->data.size();

   // Do fill first, so lines go over top - will have to add some extra code
   //  to insert fill under appropriate lines at some stage.
   if (inFill)
   {
      if (mFillJob.mFill && mFillJob.mCommand0 <n)
      {
         mFillJob.mFill->IncRef();
         mFillJob.mCommandCount = n-mFillJob.mCommand0;
         mFillJob.mDataCount = d-mFillJob.mData0;

         // Move it up the list so it is "below" lines that start at the same point
         int pos = mJobs.size()-1;
         while(pos>0)
         {
            if (mJobs[pos].mCommand0 < mFillJob.mCommand0)
               break;
            pos--;
         }
         pos++;
         if (pos==mJobs.size())
            mJobs.push_back(mFillJob);
         else
            mJobs.InsertAt(0,mFillJob);
      }
      mFillJob.mCommand0 = n;
      mFillJob.mData0 = d;
   }


   if (inLine)
   {
      if (mLineJob.mStroke && mLineJob.mCommand0 <n)
      {
         mLineJob.mStroke->IncRef();
         mLineJob.mCommandCount = n-mLineJob.mCommand0;
         mLineJob.mDataCount = d-mLineJob.mData0;
         mJobs.push_back(mLineJob);
      }
      mLineJob.mCommand0 = n;
      mLineJob.mData0 = d;
   }
}


Extent2DF Graphics::GetExtent(const Transform &inTransform)
{
   Extent2DF result;
   Flush();

   /*
   for(int i=0;i<mCache.size();i++)
   {
      // See if we can get the extent from somewhere!
      RendererCache &cache = mCache[i];
      if (cache.mSoftware && cache.mSoftware->GetExtent(inTransform,result))
         continue;
       TODO:
      if (cache.mHardware && cache.mHardware->GetExtent(inTransform,result))
         continue;

      // No - ok, create a software renderer...
      cache.mSoftware = mRenderData[i]->CreateSoftwareRenderer();
      cache.mSoftware->GetExtent(inTransform,result);
   }
*/

   return result;
}

const Extent2DF &Graphics::GetExtent0(double inRotation)
{
   if ( mMeasuredJobs<mJobs.size() || inRotation!=mRotation0)
   {
      Transform trans;
      Matrix  m;
      trans.mMatrix = &m;
      if (inRotation)
         m.Rotate(inRotation);
      mExtent0 = GetExtent(trans);
      mRotation0 = inRotation;
      mMeasuredJobs = mJobs.size();
   }
   return mExtent0;
}


bool Graphics::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   Flush();
   if (inTarget.IsHardware())
   {
     if (!mHardwareData)
         mHardwareData = new HardwareData();
     while(mBuiltHardware<mJobs.size())
         BuildHardwareJob(mJobs[mBuiltHardware++],*mPathData,*mHardwareData,*inTarget.mHardware);

     if (mHardwareData->mCalls.size())
	  {
		   if (inState.mPhase==rpHitTest)
			   return inTarget.mHardware->Hits(inState,mHardwareData->mCalls);
		   else
            inTarget.mHardware->Render(inState,mHardwareData->mCalls);
	  }
   }
   else
   {
      for(int i=0;i<mJobs.size();i++)
      {
         GraphicsJob &job = mJobs[i];
         if (!job.mSoftwareRenderer)
            job.mSoftwareRenderer = Renderer::CreateSoftware(job,*mPathData);

		   if (inState.mPhase==rpHitTest)
			{
            if (job.mSoftwareRenderer->Hits(inState))
					return true;
			}
			else
            job.mSoftwareRenderer->Render(inTarget,inState);
      }
   }

   return false;
}


// --- RenderState -------------------------------------------------------------------

void GraphicsJob::clear()
{
   if (mStroke) mStroke->DecRef();
   if (mFill) mFill->DecRef();
   if (mSoftwareRenderer) mSoftwareRenderer->Destroy();
   memset(this,0,sizeof(GraphicsJob));
}

// --- RenderState -------------------------------------------------------------------

ColorTransform sgIdentityColourTransform;

RenderState::RenderState(Surface *inSurface,int inAA)
{
   mTransform.mAAFactor = inAA;
   mMask = 0;
   mPhase = rpRender;
   mAlpha_LUT = 0;
   mC0_LUT = 0;
   mC1_LUT = 0;
   mC2_LUT = 0;
   mColourTransform = &sgIdentityColourTransform;
   mRoundSizeToPOW2 = false;
   mHitResult = 0;
   if (inSurface)
   {
      mClipRect = Rect(inSurface->Width(),inSurface->Height());
   }
   else
      mClipRect = Rect(0,0);
}



void RenderState::CombineColourTransform(const RenderState &inState,
                                         const ColorTransform *inObjTrans,
                                         ColorTransform *inBuf)
{
   mAlpha_LUT = mColourTransform->IsIdentityAlpha() ? 0 : mColourTransform->GetAlphaLUT();
   if (inObjTrans->IsIdentity())
   {
      mColourTransform = inState.mColourTransform;
      mAlpha_LUT = inState.mAlpha_LUT;
      mC0_LUT = inState.mC0_LUT;
      mC1_LUT = inState.mC1_LUT;
      mC2_LUT = inState.mC2_LUT;
      return;
   }

   mColourTransform = inBuf;
   inBuf->Combine(*(inState.mColourTransform),*inObjTrans);

   if (mColourTransform->IsIdentityColour())
   {
      mC0_LUT = 0;
      mC1_LUT = 0;
      mC2_LUT = 0;
   }
   else
   {
      mC0_LUT = mColourTransform->GetC0LUT();
      mC1_LUT = mColourTransform->GetC1LUT();
      mC2_LUT = mColourTransform->GetC2LUT();
   }

   if (mColourTransform->IsIdentityAlpha())
      mAlpha_LUT = 0;
   else
      mAlpha_LUT = mColourTransform->GetAlphaLUT();
}



// --- RenderTarget -------------------------------------------------------------------

RenderTarget::RenderTarget(const Rect &inRect,PixelFormat inFormat,uint8 *inPtr, int inStride)
{
   mRect = inRect;
   mPixelFormat = inFormat;
   mSoftPtr = inPtr;
   mSoftStride = inStride;
   mHardware = 0;
}

RenderTarget::RenderTarget(const Rect &inRect,HardwareContext *inContext)
{
   mRect = inRect;
   mPixelFormat = pfHardware;
   mSoftPtr = 0;
   mSoftStride = 0;
   mHardware = inContext;
}

RenderTarget::RenderTarget() : mRect(0,0)
{
   mPixelFormat = pfAlpha;
   mSoftPtr = 0;
   mSoftStride = 0;
   mHardware = 0;
}


RenderTarget RenderTarget::ClipRect(const Rect &inRect) const
{
   RenderTarget result = *this;
   result.mRect = result.mRect.Intersect(inRect);
   return result;
}

void RenderTarget::Clear(uint32 inColour, const Rect &inRect) const
{
   if (IsHardware())
   {
      mHardware->Clear(inColour,&inRect);
      return;
   }

   if (mPixelFormat==pfAlpha)
   {
      int val = inColour>>24;
      for(int y=inRect.y;y<inRect.y1();y++)
      {
         uint8 *alpha = (uint8 *)Row(y) + inRect.x;
         memset(alpha,val,inRect.w);
      }
   }
   else
   {
      ARGB rgb(inColour);
      if ( mPixelFormat&pfSwapRB)
         rgb.SwapRB();
      if (!(mPixelFormat & pfHasAlpha))
         rgb.a = 255;

      for(int y=inRect.y;y<inRect.y1();y++)
      {
         int *ptr = (int *)Row(y) + inRect.x;
         for(int x=0;x<inRect.w;x++)
            *ptr++ = rgb.ival;
      }
 
   }
}




// --- GraphicsBitmapFill -------------------------------------------------------------------

GraphicsBitmapFill::GraphicsBitmapFill(Surface *inBitmapData,
      const Matrix &inMatrix, bool inRepeat, bool inSmooth) : bitmapData(inBitmapData),
         matrix(inMatrix),  repeat(inRepeat), smooth(inSmooth)
{
   if (bitmapData)
      bitmapData->IncRef();
}

GraphicsBitmapFill::~GraphicsBitmapFill()
{
   if (bitmapData)
      bitmapData->DecRef();
}

// --- GraphicsStroke -------------------------------------------------------------------

GraphicsStroke::GraphicsStroke(IGraphicsFill *inFill, double inThickness,
                  bool inPixelHinting, StrokeScaleMode inScaleMode,
                  StrokeCaps inCaps,
                  StrokeJoints inJoints, double inMiterLimit)
      : fill(inFill), thickness(inThickness), pixelHinting(inPixelHinting),
        scaleMode(inScaleMode), caps(inCaps), joints(inJoints), miterLimit(inMiterLimit)
   {
      if (fill)
         fill->IncRef();
   }


GraphicsStroke::~GraphicsStroke()
{
   if (fill)
      fill->DecRef();
}




// --- Gradient ---------------------------------------------------------------------

void GraphicsGradientFill::FillArray(ARGB *outColours, bool inSwap)
{
   bool reflect = spreadMethod==smReflect;
   int n = mStops.size();
   if (n==0)
      memset(outColours,0,sizeof(ARGB)*(reflect?512:256));
   else
   {
      int i;
      int last = mStops[0].mPos;
      if (last>255) last = 255;

      for(i=0;i<=last;i++)
         outColours[i] = mStops[0].mARGB;
      for(int k=0;k<n-1;k++)
      {
         ARGB c0 = mStops[k].mARGB;
         int p0 = mStops[k].mPos;
         int p1 = mStops[k+1].mPos;
         int diff = p1 - p0;
         if (diff>0)
         {
            if (p0<0) p0 = 0;
            if (p1>256) p1 = 256;
            int dc0 = mStops[k+1].mARGB.c0 - c0.c0;
            int dc1 = mStops[k+1].mARGB.c1 - c0.c1;
            int dc2 = mStops[k+1].mARGB.c2 - c0.c2;
            int da = mStops[k+1].mARGB.a - c0.a;
            for(i=p0;i<p1;i++)
            {
               outColours[i].c1 = c0.c1 + dc1*(i-p0)/diff;
               if (inSwap)
               {
                  outColours[i].c2 = c0.c0 + dc0*(i-p0)/diff;
                  outColours[i].c0 = c0.c2 + dc2*(i-p0)/diff;
               }
               else
               {
                  outColours[i].c0 = c0.c0 + dc0*(i-p0)/diff;
                  outColours[i].c2 = c0.c2 + dc2*(i-p0)/diff;
               }
               outColours[i].a = c0.a + da*(i-p0)/diff;
            }
         }
      }
      for(;i<256;i++)
         outColours[i] = mStops[n-1].mARGB;

      if (reflect)
      {
         for(;i<512;i++)
            outColours[i] = outColours[511-i];
      }
   }
}

// --- Helper ----------------------------------------

int UpToPower2(int inX)
{
   int result = 1;
   while(result<inX) result<<=1;
   return result;
}

}
