#include <Graphics.h>
#include <Surface.h>
#include <Display.h>

namespace nme
{

void Graphics::OnChanged()
{
   mVersion++;
   if (mOwner && !(mOwner->mDirtyFlags & dirtExtent))
      mOwner->DirtyExtent();
}



// TODO: invlidate/cache extents (do for whole lot at once)

Graphics::Graphics(DisplayObject *inOwner,bool inInitRef) : Object(inInitRef)
{
   mRotation0 = 0;
   mCursor = UserPoint(0,0);
   mHardwareData = 0;
   mPathData = new GraphicsPath;
   mBuiltHardware = 0;
   mTileJob.mIsTileJob = true;
   mMeasuredJobs = 0;
   mClearCount = 0;
   mVersion = 0;
   mOwner = inOwner;
}


Graphics::~Graphics()
{
   mOwner = 0;
   clear();
   if (mPathData)
      mPathData->DecRef();
}

void Graphics::setOwner(DisplayObject *inOwner)
{
   mOwner = inOwner;
}

void Graphics::clear(bool inForceFreeHardware)
{
   mFillJob.clear();
   mLineJob.clear();
   mTileJob.clear();

   // clear jobs
   for(int i=0;i<mJobs.size();i++)
      mJobs[i].clear();
   mJobs.resize(0);

   if (mHardwareData)
   {
      if (inForceFreeHardware || mClearCount<4)
      {
         delete mHardwareData;
         mHardwareData = 0;
      }
      else
         mHardwareData->clear();
      if (!inForceFreeHardware)
         mClearCount++;
   }

   mPathData->clear();

   mExtent0 = Extent2DF();
   mRotation0 = 0;
   mBuiltHardware = 0;
   mMeasuredJobs = 0;
   mCursor = UserPoint(0,0);
   OnChanged();
}

int Graphics::Version() const
{
   int result = mVersion;
	for(int i=0;i<mJobs.size();i++)
		result += mJobs[i].Version();
	return result;
}

#define SIN45 0.70710678118654752440084436210485
#define TAN22 0.4142135623730950488016887242097

void Graphics::drawEllipse(float x, float y, float width, float height)
{
   x += width/2;
   y += height/2;
   float w = width*0.5;
   float w_ = w*SIN45;
   float cw_ = w*TAN22;
   float h = height*0.5;
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
   OnChanged();
}

/*

   < ------------ w ----->
      < -------- w_ ----->
       < ------ cw_ ----->
             < --- lw ---> 
        c   --------------+
         222 |            x
        2    |
       p
    c 1 ..   ry
     1    . 
     1     ..|
    | - rx --
    |
    |

*/

void Graphics::drawRoundRect(float x,float  y,float  width,float  height,float  rx,float  ry)
{
   rx *= 0.5;
   ry *= 0.5;
   float w = width*0.5;
   //x+=w;
   if (rx>w) rx = w;
   //float lw = w - rx;
   //float w_ = lw + rx*SIN45;
   //float cw_ = lw + rx*TAN22;
   float h = height*0.5;
   //y+=h;
   if (ry>h) ry = h;
   //float lh = h - ry;
   //float h_ = lh + ry*SIN45;
   //float ch_ = lh + ry*TAN22;

   Flush();

   float d = 1 - 0.55228;

   float x0 = x;
   float cx0 = x + d*rx;
   float x1 = x + rx;
   float x2 = x + width - rx;
   float cx1 = x + width - d*rx;
   float x3 = x + width;

   float y0 = y;
   float cy0 = y + d*ry;
   float y1 = y + ry;
   float y2 = y + height - ry;
   float cy1 = y + height - d*ry;
   float y3 = y + height;

   mPathData->moveTo(x0,y1);
   mPathData->cubicTo(x0,cy0, cx0,y0, x1, y0);
   if (x1!=x2)
      mPathData->lineTo(x2,y0);
   mPathData->cubicTo(cx1,y0, x3,cy0, x3,y1);
   if (y1!=y2)
      mPathData->lineTo(x3,y2);
   mPathData->cubicTo(x3,cy1, cx1,y3, x2,y3);
   if (x1!=x2)
      mPathData->lineTo(x1,y3);
   mPathData->cubicTo(cx0,y3, x0,cy1, x0,y2);
   if (y1!=y2)
      mPathData->lineTo(x0,y1);

   /*
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
   */

   Flush();
   OnChanged();
}

void Graphics::close()
{
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
   OnChanged();
}



void Graphics::drawGraphicsDatum(IGraphicsData *inData)
{
   switch(inData->GetType())
   {
      case gdtUnknown: break;
      case gdtTrianglePath: break;
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
      case gdtBitmapFill:
         {
         IGraphicsFill *fill = inData->AsIFill();
         if (fill->isSolidStyle())
         {
            Flush(false,true);
            endTiles();
            if (mFillJob.mFill)
               mFillJob.mFill->DecRef();
            mFillJob.mFill = fill;
            mFillJob.mFill->IncRef();
            if (mFillJob.mCommand0 == mPathData->commands.size())
               mPathData->initPosition(mCursor);
         }
         else if (mLineJob.mStroke)
         {
            Flush(true,false);
            mLineJob.mStroke = mLineJob.mStroke->CloneWithFill(fill);
         }
         }
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
   OnChanged();
}

void Graphics::drawGraphicsData(IGraphicsData **graphicsData,int inN)
{
   for(int i=0;i<inN;i++)
      drawGraphicsDatum(graphicsData[i]);
   OnChanged();
}

void Graphics::beginFill(unsigned int color, float alpha)
{
   Flush(false,true,true);
   endTiles();
   if (mFillJob.mFill)
      mFillJob.mFill->DecRef();
   mFillJob.mFill = new GraphicsSolidFill(color,alpha);
   mFillJob.mFill->IncRef();
   if (mFillJob.mCommand0 == mPathData->commands.size())
      mPathData->initPosition(mCursor);
}

void Graphics::endFill()
{
   Flush(true,true);
   if (mFillJob.mFill)
   {
      mFillJob.mFill->DecRef();
      mFillJob.mFill = 0;
   }
}

void Graphics::beginBitmapFill(Surface *bitmapData, const Matrix &inMatrix,
   bool inRepeat, bool inSmooth)
{
   Flush(false,true,true);
   endTiles();
   if (mFillJob.mFill)
      mFillJob.mFill->DecRef();
   mFillJob.mFill = new GraphicsBitmapFill(bitmapData,inMatrix,inRepeat,inSmooth);
   mFillJob.mFill->IncRef();
   if (mFillJob.mCommand0 == mPathData->commands.size())
      mPathData->initPosition(mCursor);
}

void Graphics::endTiles()
{
   if (mTileJob.mFill)
   {
      mTileJob.mFill->DecRef();
      mTileJob.mFill = 0;
      OnChanged();
   }
}

void Graphics::beginTiles(Surface *bitmapData,bool inSmooth,int inBlendMode, int inMode, int inCount)
{
   endFill();
   lineStyle(-1);
   Flush();
   if (mTileJob.mFill)
      mTileJob.mFill->DecRef();
   mTileJob.mFill = new GraphicsBitmapFill(bitmapData,Matrix(),false,inSmooth);
   mTileJob.mFill->IncRef();
   mTileJob.mBlendMode = inBlendMode;
   mTileJob.mTileCount = inCount;
   mTileJob.mTileMode = inMode;
   OnChanged();
}

void Graphics::lineStyle(double thickness, unsigned int color, double alpha,
                  bool pixelHinting, StrokeScaleMode scaleMode,
                  StrokeCaps caps,
                  StrokeJoints joints, double miterLimit)
{
   Flush(true,false,true);
   endTiles();
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
   OnChanged();
}

void Graphics::moveTo(float x, float y)
{
   mPathData->moveTo(x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

#ifdef EMSCRIPTEN
#define EPSILON 0.0001
#else
#define EPSILON 0.00001
#endif

void Graphics::curveTo(float cx, float cy, float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   if ( (fabs(mCursor.x-cx)<EPSILON && fabs(mCursor.y-cy)<EPSILON) ||
        (fabs(x-cx)<EPSILON && fabs(y-cy)<EPSILON)  )
   {
      mPathData->lineTo(x,y);
      return;
   }
   else
      mPathData->curveTo(cx,cy,x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

inline float Interp(float a, float b, float frac)
{
   return a + (b-a)*frac;
}

void Graphics::cubicTo(float cx0, float cy0, float cx1, float cy1, float x, float y)
{
   if ( (fabs(cx0-cx1)<EPSILON && fabs(cy0-cy1)<EPSILON )  ||
        (fabs(x-cx1)<EPSILON && fabs(y-cy1)<EPSILON ) )
   {
      curveTo(cx0, cy0, x, y);
      return;
   }

   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   if ( fabs(mCursor.x-cx0)<EPSILON && fabs(mCursor.y-cy0)<EPSILON )
   {
      curveTo(cx1, cy1, x, y);
      return;
   }

   mPathData->cubicTo(cx0,cy0,cx1,cy1,x,y);

   mCursor = UserPoint(x,y);
   OnChanged();
}

void Graphics::arcTo(float cx, float cy, float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   mPathData->arcTo(cx,cy,x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

void Graphics::tile(float x, float y, const Rect &inTileRect,float *inTrans,float *inRGBA)
{
   mTileJob.mTileCount++;
   mPathData->tile(x,y,inTileRect,inTrans,inRGBA);
}


void Graphics::drawPoints(QuickVec<float> inXYs, QuickVec<int> inRGBAs, unsigned int inDefaultRGBA,
								  double inSize)
{
   endFill();
   lineStyle(-1);
   Flush();

   GraphicsJob job;
   job.mCommand0 = mPathData->commands.size();
   job.mCommandCount = 1;
   job.mData0 = mPathData->data.size();
   job.mIsPointJob = true;
   mPathData->drawPoints(inXYs,inRGBAs);
   job.mDataCount = mPathData->data.size() - job.mData0;
   if (mPathData->commands[job.mCommand0]==pcPointsXY)
   {
      job.mFill = new GraphicsSolidFill(inDefaultRGBA&0xffffff,(inDefaultRGBA>>24)/255.0);
      job.mFill->IncRef();
   }
	if (inSize>0)
	{
		job.mStroke = new GraphicsStroke(0,inSize);
		job.mStroke->IncRef();
	}

   mJobs.push_back(job);
}

void Graphics::drawTriangles(const QuickVec<float> &inXYs,
            const QuickVec<int> &inIndices,
            const QuickVec<float> &inUVT, int inCull,
            const QuickVec<int> &inColours,
            int blendMode)
{
	Flush( );
	
	if (!mFillJob.mFill)
	{
		beginFill (0, 0);
	}
	
	IGraphicsFill *fill = mFillJob.mFill;

   GraphicsTrianglePath *path = new GraphicsTrianglePath(inXYs,
           inIndices, inUVT, inCull, inColours, blendMode );
   GraphicsJob job;
   path->IncRef();

	if (!fill || !fill->AsBitmapFill())
		path->mUVT.resize(0);

   job.mFill = fill ? fill->IncRef() : 0;
   job.mStroke = mLineJob.mStroke ? mLineJob.mStroke->IncRef() : 0;
   job.mTriangles = path;

   mJobs.push_back(job);
}



// This routine converts a list of "GraphicsPaths" (mItems) into a list
//  of LineData and SolidData.
// The items intermix fill-styles and line-stypes with move/draw/triangle
//  geometry data - this routine separates them out.

void Graphics::Flush(bool inLine, bool inFill, bool inTile)
{
   int n = mPathData->commands.size();
   int d = mPathData->data.size();
   bool wasFilled = false;

   if (inTile)
   {
      if (mTileJob.mFill && mTileJob.mTileCount>0)
      {
         mTileJob.mFill->IncRef();
         mTileJob.mDataCount = d-mTileJob.mData0;
         mTileJob.mIsTileJob = true;
         mJobs.push_back(mTileJob);
      }
   }


   // Do fill first, so lines go over top.
   if (inFill)
   {
      if (mFillJob.mFill && mFillJob.mCommand0 <n)
      {
         mFillJob.mFill->IncRef();
         mFillJob.mCommandCount = n-mFillJob.mCommand0;
         mFillJob.mDataCount = d-mFillJob.mData0;
         wasFilled = true;

         // Move the fill job up the list so it is "below" lines that start at the same
         // (or later) data point
         int pos = mJobs.size()-1;
         while(pos>=0)
         {
            if (mJobs[pos].mData0 < mFillJob.mData0)
               break;
            pos--;
         }
         pos++;
         if (pos==mJobs.size())
         {
            mJobs.push_back(mFillJob);
         }
         else
         {
            mJobs.InsertAt(0,mFillJob);
         }
         mFillJob.mCommand0 = n;
         mFillJob.mData0 = d;
      }
   }


   if (inLine)
   {
      if (mLineJob.mStroke && mLineJob.mCommand0 <n-1)
      {
         mLineJob.mStroke->IncRef();

         // Add closing segment...
         if (wasFilled)
         {
            mPathData->closeLine(mLineJob.mCommand0,mLineJob.mData0);
            n = mPathData->commands.size();
            d = mPathData->data.size();
         }
         mLineJob.mCommandCount = n-mLineJob.mCommand0;
         mLineJob.mDataCount = d-mLineJob.mData0;
         mJobs.push_back(mLineJob);
      }
      mLineJob.mCommand0 = n;
      mLineJob.mData0 = d;
   }


   if (inTile)
   {
      mTileJob.mTileCount = 0;
      mTileJob.mData0 = d;
   }

   if (inFill)
   {
      mFillJob.mCommand0 = n;
      mFillJob.mData0 = d;
   }

}


Extent2DF Graphics::GetSoftwareExtent(const Transform &inTransform, bool inIncludeStroke)
{
   Extent2DF result;
   Flush();

   for(int i=0;i<mJobs.size();i++)
   {
      GraphicsJob &job = mJobs[i];
      if (!job.mSoftwareRenderer)
         job.mSoftwareRenderer = Renderer::CreateSoftware(job,*mPathData);

      job.mSoftwareRenderer->GetExtent(inTransform,result,inIncludeStroke);
   }

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
      mExtent0 = GetSoftwareExtent(trans,true);
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
      else if (!mHardwareData->isScaleOk(inState))
      {
         mHardwareData->clear();
         mBuiltHardware = 0;
      }
      
      while(mBuiltHardware<mJobs.size())
      {
         BuildHardwareJob(mJobs[mBuiltHardware++],*mPathData,*mHardwareData,*inTarget.mHardware,inState);
      }
      
      if (mHardwareData && !mHardwareData->mElements.empty())
      {
         if (inState.mPhase==rpHitTest)
            return inTarget.mHardware->Hits(inState,*mHardwareData);
         else
            inTarget.mHardware->Render(inState,*mHardwareData);
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




void encodeGraphicsData(ObjectStreamOut &stream, IGraphicsData *data)
{
   switch(stream.addInt(data->GetType()))
   {
      case gdtUnknown:
         break;

      case gdtEndFill:
         // nothing to do
         break;
      case gdtSolidFill:
         {
         GraphicsSolidFill *fill = data->AsSolidFill();
         stream.addBool( fill->isSolidStyle() );
         stream.add( fill->mRGB );
         }
         break;

      case gdtGradientFill:
         {
         GraphicsGradientFill *grad = data->AsGradientFill();
         stream.addBool( grad->isSolidStyle() );
         stream.addVec( grad->mStops );
         stream.add( grad->focalPointRatio );
         stream.add( grad->matrix );
         stream.add( grad->interpolationMethod );
         stream.add( grad->spreadMethod  );
         stream.add( grad->isLinear  );
         break;
         }

      case gdtBitmapFill:
         {
         GraphicsBitmapFill *bmp = data->AsBitmapFill();
         stream.addBool( bmp->isSolidStyle() );
         stream.addObject( bmp->bitmapData );
         stream.add( bmp->matrix );
         stream.add( bmp->repeat );
         stream.add( bmp->smooth );
         break;
         }

      case gdtPath:
         {
         GraphicsPath *path = data->AsPath();
         stream.addVec(path->commands);
         stream.addVec(path->data);
         stream.add(path->winding);
         break;
         }

      case gdtTrianglePath:
         {
         GraphicsTrianglePath *tris = data->AsTrianglePath();
         stream.add(tris->mType);
         stream.add(tris->mBlendMode);
         stream.add(tris->mTriangleCount);
         stream.addVec(tris->mVertices);
         stream.addVec(tris->mUVT);
         stream.addVec(tris->mColours);
         break;
         }
      case gdtStroke:
         {
         GraphicsStroke *stroke = data->AsStroke();
         if (stream.addBool(stroke->fill))
            encodeGraphicsData(stream,stroke->fill);

         stream.add(stroke->caps);
         stream.add(stroke->joints);
         stream.add(stroke->miterLimit);
         stream.add(stroke->pixelHinting);
         stream.add(stroke->scaleMode);
         stream.add(stroke->thickness);
         break;
         }
   }
}


IGraphicsData *decodeGraphicsData(ObjectStreamIn &stream);

template<typename T>
void decodeGraphicsData(ObjectStreamIn &stream, T *&outPointer)
{
   outPointer = 0;
   IGraphicsData *g = decodeGraphicsData(stream);
   if (g)
   {
      g->IncRef();
      T *result = dynamic_cast<T*>(g);
      if (result)
      {
         outPointer = result;
      }
      else
      {
         printf("decodeGraphicsData not right type, have : %d, want %d\n", g->GetType(),
                 (new T)->GetType() );
         g->DecRef();
      }
   }
   else
      printf("Could not decodeGraphicsData\n");
}


IGraphicsData *decodeGraphicsData(ObjectStreamIn &stream)
{
   int type = stream.getInt();
   switch(type)
   {
      case gdtUnknown:
         return 0;

      case gdtEndFill:
         return new GraphicsEndFill();

      case gdtSolidFill:
         {
         GraphicsSolidFill *fill = new GraphicsSolidFill();
         fill->setIsSolidStyle(stream.getBool());
         stream.get( fill->mRGB );
         return fill;
         }

      case gdtGradientFill:
         {
         GraphicsGradientFill *grad = new GraphicsGradientFill();
         grad->setIsSolidStyle(stream.getBool());
         stream.getVec( grad->mStops );
         stream.get( grad->focalPointRatio );
         stream.get( grad->matrix );
         stream.get( grad->interpolationMethod );
         stream.get( grad->spreadMethod  );
         stream.get( grad->isLinear  );
         return grad;
         }

      case gdtBitmapFill:
         {
         GraphicsBitmapFill *bmp = new GraphicsBitmapFill();
         bmp->setIsSolidStyle(stream.getBool());
         stream.getObject( bmp->bitmapData );
         stream.get( bmp->matrix );
         stream.get( bmp->repeat );
         stream.get( bmp->smooth );
         return bmp;
         }

      case gdtPath:
         {
         GraphicsPath *path = new GraphicsPath();
         stream.getVec(path->commands);
         stream.getVec(path->data);
         stream.get(path->winding);
         return path;
         }

      case gdtTrianglePath:
         {
         GraphicsTrianglePath *tris = new GraphicsTrianglePath();
         stream.get(tris->mType);
         stream.get(tris->mBlendMode);
         stream.get(tris->mTriangleCount);
         stream.getVec(tris->mVertices);
         stream.getVec(tris->mUVT);
         stream.getVec(tris->mColours);
         return tris;
         }


      case gdtStroke:
         {
         GraphicsStroke *stroke = new GraphicsStroke();
         if (stream.getBool())
            decodeGraphicsData(stream,stroke->fill);

         stream.get(stroke->caps);
         stream.get(stroke->joints);
         stream.get(stroke->miterLimit);
         stream.get(stroke->pixelHinting);
         stream.get(stroke->scaleMode);
         stream.get(stroke->thickness);
         return stroke;
         }
   }
   return 0;
}


Graphics *Graphics::fromStream(ObjectStreamIn &inStream)
{
   Graphics *result = new Graphics(0);
   inStream.linkAbstract(result);
   result->decodeStream(inStream);
   return result;
}


void Graphics::encodeStream(ObjectStreamOut &stream)
{
      //*mOwner;
      Flush();

      int count = mJobs.size();
      stream.addInt(count);
      for(int j=0;j<count;j++)
      {
         GraphicsJob &job = mJobs[j];

         stream.add(job.mCommand0);
         stream.add(job.mCommandCount);
         stream.add(job.mData0);
         stream.add(job.mDataCount);
         stream.add(job.mIsTileJob);
         stream.add(job.mIsPointJob);
         stream.add(job.mTileMode);
         stream.add(job.mBlendMode);

         if (stream.addBool(job.mFill))
            encodeGraphicsData(stream,job.mFill);

         if (stream.addBool(job.mStroke))
            encodeGraphicsData(stream, job.mStroke);

         GraphicsTrianglePath *tris = job.mTriangles;
         if (stream.addBool(tris))
            encodeGraphicsData(stream,tris);
      }

      if (stream.addBool(mPathData))
         encodeGraphicsData(stream,mPathData);
}

void Graphics::decodeStream(ObjectStreamIn &stream)
{
   int count = stream.getInt();
   mJobs.resize(count);
   mJobs.Zero();
   for(int j=0;j<count;j++)
   {
      GraphicsJob &job = mJobs[j];

      stream.get(job.mCommand0);
      stream.get(job.mCommandCount);
      stream.get(job.mData0);
      stream.get(job.mDataCount);
      stream.get(job.mIsTileJob);
      stream.get(job.mIsPointJob);
      stream.get(job.mTileMode);
      stream.get(job.mBlendMode);

      if (stream.getBool())
         decodeGraphicsData(stream,job.mFill);

      if (stream.getBool())
         decodeGraphicsData(stream, job.mStroke);

      if (stream.getBool())
         decodeGraphicsData(stream,job.mTriangles);
   }

   if (stream.getBool())
   {
      if (mPathData)
      {
         mPathData->DecRef();
         mPathData = 0;
      }

      decodeGraphicsData(stream,mPathData);
   }
   else
   {
      printf("No path data?\n");
   }
}





// --- RenderState -------------------------------------------------------------------

void GraphicsJob::clear()
{
   if (mStroke) mStroke->DecRef();
   if (mFill) mFill->DecRef();
   if (mTriangles) mTriangles->DecRef();
   if (mSoftwareRenderer) mSoftwareRenderer->Destroy();
   bool was_tile = mIsTileJob;
   memset(this,0,sizeof(GraphicsJob));
   mIsTileJob = was_tile;
}

// --- RenderState -------------------------------------------------------------------

ColorTransform sgIdentityColourTransform;

RenderState::RenderState(Surface *inSurface,int inAA)
{
   mTransform.mAAFactor = inAA;
   mMask = 0;
   mPhase = rpRender;
   mAlpha_LUT = 0;
   mR_LUT = 0;
   mG_LUT = 0;
   mB_LUT = 0;
   mColourTransform = &sgIdentityColourTransform;
   mRoundSizeToPOW2 = false;
   mHitResult = 0;
   mRecurse = true;
   mTargetOffset = ImagePoint(0,0);
   mWasDirtyPtr = 0;
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
      mR_LUT = inState.mR_LUT;
      mG_LUT = inState.mG_LUT;
      mB_LUT = inState.mB_LUT;
      return;
   }

   mColourTransform = inBuf;
   inBuf->Combine(*(inState.mColourTransform),*inObjTrans);

   if (mColourTransform->IsIdentityColour())
   {
      mR_LUT = 0;
      mG_LUT = 0;
      mB_LUT = 0;
   }
   else
   {
      mR_LUT = mColourTransform->GetRLUT();
      mG_LUT = mColourTransform->GetGLUT();
      mB_LUT = mColourTransform->GetBLUT();
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

RenderTarget::RenderTarget(const Rect &inRect,HardwareRenderer *inHardware)
{
   mRect = inRect;
   mPixelFormat = pfRenderBuffer;
   mSoftPtr = 0;
   mSoftStride = 0;
   mHardware = inHardware;
}

RenderTarget::RenderTarget() : mRect(0,0)
{
   mPixelFormat = pfAlpha;
   mSoftPtr = 0;
   mSoftStride = 0;
   mHardware = 0;
}

bool RenderTarget::supportsComponentAlpha() const
{
   return !mHardware || mHardware->supportsComponentAlpha();
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
      mHardware->Clear(inColour,&inRect);
   else
      SetPixelRect(inColour, inRect, mPixelFormat, mSoftPtr, mSoftStride);
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

int GraphicsBitmapFill::Version() const
{
	return bitmapData->Version();
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

GraphicsStroke *GraphicsStroke::CloneWithFill(IGraphicsFill *inFill)
{
   if (mRefCount < 2)
   {
      inFill->IncRef();
      if (fill)
         fill->DecRef();
      fill = inFill;
      return this;
   }

   GraphicsStroke *clone = new GraphicsStroke(inFill,thickness,pixelHinting,scaleMode,caps,joints,miterLimit);
   DecRef();
   clone->IncRef();
   return clone;
}



// --- Gradient ---------------------------------------------------------------------


static void GetLinearLookups(int **outToLinear, int **outFromLinear)
{
   static int *to = 0;
   static int *from = 0;

   if (!to)
   {
      double a = 0.055;
      to = new int[256];
      from = new int[4096];

      for(int i=0;i<4096;i++)
      {
         double t = i / 4095.0;
         from[i] = 255.0 * (t<=0.0031308 ? t*12.92 : (a+1)*pow(t,1/2.4)-a) + 0.5;
      }

      for(int i=0;i<256;i++)
      {
         double t = i / 255.0;
         to[i] = 4095.0 * ( t<=0.04045 ? t/12.92 : pow( (t+a)/(1+a), 2.4 ) ) + 0.5;
      }
   }

   *outToLinear = to;
   *outFromLinear = from;
}


void GraphicsGradientFill::FillArray(ARGB *outColours)
{
   int *ToLinear = 0;
   int *FromLinear = 0;

   if (interpolationMethod==imLinearRGB)
      GetLinearLookups(&ToLinear,&FromLinear);
    
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

            int da = mStops[k+1].mARGB.a - c0.a;
            if (ToLinear)
            {
               int dr = ToLinear[mStops[k+1].mARGB.r] - ToLinear[c0.r];
               int dg = ToLinear[mStops[k+1].mARGB.g] - ToLinear[c0.g];
               int db = ToLinear[mStops[k+1].mARGB.b] - ToLinear[c0.b];
               for(i=p0;i<p1;i++)
               {
                  outColours[i].r= FromLinear[ ToLinear[c0.r] + dr*(i-p0)/diff];
                  outColours[i].g= FromLinear[ ToLinear[c0.g] + dg*(i-p0)/diff];
                  outColours[i].b= FromLinear[ ToLinear[c0.b] + db*(i-p0)/diff];
                  outColours[i].a = FromLinear[ ToLinear[c0.a] + da*(i-p0)/diff];
               }
            }
            else
            {
               int dr = mStops[k+1].mARGB.r - c0.r;
               int dg = mStops[k+1].mARGB.g - c0.g;
               int db = mStops[k+1].mARGB.b - c0.b;
               for(i=p0;i<p1;i++)
               {
                  outColours[i].r = c0.r + dr*(i-p0)/diff;
                  outColours[i].g = c0.g + dg*(i-p0)/diff;
                  outColours[i].b = c0.b + db*(i-p0)/diff;
                  outColours[i].a = c0.a + da*(i-p0)/diff;
               }
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
