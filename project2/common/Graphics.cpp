#include <Graphics.h>
#include <Surface.h>

Graphics::Graphics(bool inInitRef) : Object(inInitRef)
{
   mLastConvertedItem = 0;
   mRotation0 = 0;
   mRenderDirty = false;
}


Graphics::~Graphics()
{
	clear();
}

void Graphics::MakeDirty()
{
   mExtent0.Invalidate();
   mRenderDirty = true;
}

void Graphics::clear()
{
   for(int i=0;i<mCache.size();i++)
   {
      RendererCache &cache = mCache[i];
      if (cache.mSoftware)
         cache.mSoftware->Destroy();
      if (cache.mHardware)
         cache.mHardware->Destroy();
   }
	mCache.resize(0);

   for(int i=0;i<mItems.size();i++)
      mItems[i]->DecRef();
	mItems.resize(0);

   mExtent0 = Extent2DF();
   mRenderDirty = true;
   mRotation0 = 0;

   mRenderData.DeleteAll();

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

	moveTo(x+w,y);
	curveTo(x+w,  y+ch_, x+w_, y+h_);
	curveTo(x+cw_,y+h,   x,    y+h);
	curveTo(x-cw_,y+h,   x-w_, y+h_);
	curveTo(x-w,  y+ch_, x-w,  y);
	curveTo(x-w,  y-ch_, x-w_, y-h_);
	curveTo(x-cw_,y-h,   x,    y-h);
	curveTo(x+cw_,y-h,   x+w_, y-h_);
	curveTo(x+w,  y-ch_, x+w,  y);

   MakeDirty();
}

void Graphics::drawRoundRect(float x,float  y,float  width,float  height,float  rx,float  ry)
{
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

	moveTo(x+w,y+lh);
	curveTo(x+w,  y+ch_, x+w_, y+h_);
	curveTo(x+cw_,y+h,   x+lw,    y+h);
	lineTo(x-lw,    y+h);
	curveTo(x-cw_,y+h,   x-w_, y+h_);
	curveTo(x-w,  y+ch_, x-w,  y+lh);
	lineTo( x-w, y-lh);
	curveTo(x-w,  y-ch_, x-w_, y-h_);
	curveTo(x-cw_,y-h,   x-lw,    y-h);
	lineTo(x+lw,    y-h);
	curveTo(x+cw_,y-h,   x+w_, y-h_);
	curveTo(x+w,  y-ch_, x+w,  y-lh);
	lineTo(x+w,  y+lh);
   MakeDirty();
}


void Graphics::drawGraphicsData(IGraphicsData **graphicsData,int inN)
{
   mItems.reserve(mItems.size()+inN);
   for(int i=0;i<inN;i++)
      mItems.push_back( graphicsData[i]->IncRef() );
   MakeDirty();
}

void Graphics::Add(IGraphicsData *inData)
{
   mItems.push_back(inData->IncRef());
   MakeDirty();
}

void Graphics::Add(IRenderData *inData)
{
   inData->IncRef();
   mRenderData.push_back(inData);
   MakeDirty();
}


GraphicsPath *Graphics::GetLastPath()
{
   MakeDirty();

   if (mLastConvertedItem<mItems.size())
   {
      IGraphicsData *last = mItems.last();
      GraphicsPath *path = last->AsPath();
      if (path)
         return path;
   }
   GraphicsPath *path = new GraphicsPath();
   Add(path);
   return path;
}



void Graphics::beginFill(unsigned int color, float alpha)
{
   Add(new GraphicsSolidFill(color,alpha));
}

void Graphics::beginBitmapFill(Surface *bitmapData, const Matrix &inMatrix,
	bool inRepeat, bool inSmooth)
{
   Add(new GraphicsBitmapFill(bitmapData,inMatrix,inRepeat,inSmooth) );
}


void Graphics::lineStyle(double thickness, unsigned int color, double alpha,
                  bool pixelHinting, StrokeScaleMode scaleMode,
                  StrokeCaps caps,
                  StrokeJoints joints, double miterLimit)
{
   IGraphicsFill *solid = new GraphicsSolidFill(color,alpha);
   Add(new GraphicsStroke(solid,thickness,pixelHinting,scaleMode,caps,joints,miterLimit));
}




void Graphics::lineTo(float x, float y)
{
   GetLastPath()->lineTo(x,y);
}

void Graphics::moveTo(float x, float y)
{
   GetLastPath()->moveTo(x,y);
}

void Graphics::curveTo(float cx, float cy, float x, float y)
{
   GetLastPath()->curveTo(cx,cy,x,y);
}

void Graphics::arcTo(float cx, float cy, float x, float y)
{
   GetLastPath()->arcTo(cx,cy,x,y);
}





// This routine converts a list of "GraphicsPaths" (mItems) into a list
//  of LineData and SolidData.
// The items intermix fill-styles and line-stypes with move/draw/triangle
//  geometry data - this routine separates them out.

void Graphics::CreateRenderData()
{
   int n = mItems.size();
   if (mLastConvertedItem<n)
   {
      IGraphicsFill *fill = 0;
      GraphicsStroke *stroke = 0;
      // Find "current" fill/stroke
      for(int i=0;i<mLastConvertedItem;i++)
      {
         IGraphicsData *data = mItems[i];
         IGraphicsFill *f= data->AsIFill();
         if (f)
            fill = f;
         IGraphicsStroke *s= data->AsIStroke();
         if (s)
            stroke = data->AsStroke();
      }


      SolidData *solid = 0;
      LineData *line = 0;
      for(int i=mLastConvertedItem;i<n;i++)
      {
         IGraphicsData *data = mItems[i];
         IGraphicsFill *f= data->AsIFill();
         // TODO: order of lines and solids...
         if (f)
         {
            if (solid)
            {
               solid->Close();
               Add(solid);
               solid = 0;
            }
            fill = data->AsEndFill() ? 0 : f;
            if (line)
            {
               Add(line);
               line = 0;
            }
            continue;
         }

         IGraphicsStroke *s= data->AsIStroke();
         if (s)
         {
            if (line)
            {
               Add(line);
               line = 0;
            }
            stroke = data->AsStroke();
            continue;
         }

         GraphicsPath *path= data->AsPath();
         if (path)
         {
            if (!line && stroke)
               line = new LineData(stroke);
            if (line)
               line->Add(path);
            if (!solid && fill)
               solid = new SolidData(fill);
            if (solid)
               solid->Add(path);
         }
      }
      if (solid)
         Add(solid);
      if (line)
         Add(line);

      mLastConvertedItem = n;
		for(int i=mCache.size();i<mRenderData.size();i++)
         mCache.push_back( RendererCache() );
   }

}


Extent2DF Graphics::GetExtent(const Transform &inTransform)
{
   // TODO: cache this?
   Extent2DF result;
   CreateRenderData();
   for(int i=0;i<mCache.size();i++)
   {
      // See if we can get the extent from somewhere!
      RendererCache &cache = mCache[i];
      if (cache.mSoftware && cache.mSoftware->GetExtent(inTransform,result))
         continue;
      if (cache.mHardware && cache.mHardware->GetExtent(inTransform,result))
         continue;

      // No - ok, create a software renderer...
      cache.mSoftware = mRenderData[i]->CreateSoftwareRenderer();
      cache.mSoftware->GetExtent(inTransform,result);
   }

   return result;
}

const Extent2DF &Graphics::GetExtent0(double inRotation)
{
   if (!mExtent0.Valid() || inRotation!=mRotation0)
   {
      Transform trans;
      Matrix  m;
      trans.mMatrix = &m;
      if (inRotation)
         m.Rotate(inRotation);
      mExtent0 = GetExtent(trans);
      mRotation0 = inRotation;
   }
   return mExtent0;
}


bool Graphics::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   CreateRenderData();
   for(int i=0;i<mCache.size();i++)
   {
      RendererCache &cache = mCache[i];
      if (inTarget.is_hardware)
      {
      }
      else
      {
			if (!cache.mSoftware)
            cache.mSoftware = mRenderData[i]->CreateSoftwareRenderer();

         cache.mSoftware->Render(inTarget,inState);
      }
   }

   return true;
}

// --- RenderState -------------------------------------------------------------------

RenderState::RenderState(Surface *inSurface,int inAA)
{
	mAlpha = 1.0;
	mTransform.mAAFactor = inAA;
	mBlendMode = bmNormal;
	mHardwareMask = 0;
	mSoftwareMask = 0;
	if (inSurface)
	{
		mClipRect = Rect(inSurface->Width(),inSurface->Height());
	}
	else
		mClipRect = Rect(0,0);
	mAAClipRect =Rect( mClipRect.w*inAA, mClipRect.h*inAA );
}

// --- RenderTarget -------------------------------------------------------------------

RenderTarget RenderTarget::ClipRect(const Rect &inRect) const
{
   RenderTarget result = *this;
   result.mRect = result.mRect.Intersect(inRect);
   return result;
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


// --- LineData -------------------------------------------------------------------

void LineData::Add(GraphicsPath *inPath)
{
   command.append(inPath->command);
   data.append(inPath->data);
}

Renderer *LineData::CreateSoftwareRenderer()
{
   return Renderer::CreateSoftware(this);
}



// --- SolidData -------------------------------------------------------------------
void SolidData::Add(GraphicsPath *inPath)
{
   command.append(inPath->command);
   data.append(inPath->data);
}

Renderer *SolidData::CreateSoftwareRenderer()
{
   return Renderer::CreateSoftware(this);
}



void SolidData::Close()
{
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
