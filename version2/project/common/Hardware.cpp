#include <Graphics.h>
#include <Surface.h>

namespace nme
{

class HardwareBuilder
{
public:
   HardwareBuilder(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
   {
      mTexture = 0;
      mTileMode = false;
      mElement.mColour = 0xffffffff;
      if (inJob.mIsTileJob)
      {
         mElement.mBitmapRepeat = true;
         mElement.mBitmapSmooth = false;

         mElement.mPrimType = ptTriangles;
         mElement.mScaleMode = ssmNormal;
         mElement.mWidth = -1;

         GraphicsBitmapFill *bmp = inJob.mFill->AsBitmapFill();
         mSurface = bmp->bitmapData->IncRef();
         mTexture = mSurface->GetOrCreateTexture(inHardware);
         mElement.mBitmapRepeat = false;
         mElement.mBitmapSmooth = bmp->smooth;
         mTileMode = true;
      }
      else if (inJob.mFill)
      {
         mElement.mPrimType = inJob.mTriangles ? ptTriangles : ptTriangleFan;
         mElement.mScaleMode = ssmNormal;
         mElement.mWidth = -1;
         SetFill(inJob.mFill,inHardware);
      }
      else
      {
         mElement.mPrimType = ptLineStrip;
         GraphicsStroke *stroke = inJob.mStroke;
         mElement.mScaleMode = stroke->scaleMode;
         mElement.mWidth = stroke->thickness;
         SetFill(stroke->fill,inHardware);
      }
      mElement.mFirst = 0;
      mElement.mCount = 0;



		if (inJob.mTriangles)
      {
         mArrays = &ioData.GetArrays(mSurface,false,inJob.mTriangles->mType == vtVertexUVT);
			AddTriangles(inJob.mTriangles);
      }
		else
      {
         mArrays = &ioData.GetArrays(mSurface,false);
         AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount,
                &inPath.data[inJob.mData0], inJob.mFill);
      }
   }

  
   bool SetFill(IGraphicsFill *inFill,HardwareContext &inHardware)
   {
      mSurface = 0;
      mElement.mBitmapRepeat = true;
      mElement.mBitmapSmooth = false;

      GraphicsSolidFill *solid = inFill->AsSolidFill();
      if (solid)
      {
          mElement.mColour = solid->mRGB.ToInt();
      }
      else
      {
         GraphicsGradientFill *grad = inFill->AsGradientFill();
         if (grad)
         {
            mGradReflect = grad->spreadMethod == smReflect;
            int w = mGradReflect ? 512 : 256;
            mSurface = new SimpleSurface(w,1,pfARGB);
            mSurface->IncRef();
            grad->FillArray( (ARGB *)mSurface->GetBase(), false);

            mElement.mBitmapRepeat = grad->spreadMethod!=smPad;
            mElement.mBitmapSmooth = true;

            mTextureMapper = grad->matrix.Inverse();

            return true;
         }
         else
         {
            GraphicsBitmapFill *bmp = inFill->AsBitmapFill();
            mTextureMapper = bmp->matrix.Inverse();
            mSurface = bmp->bitmapData->IncRef();
            mTexture = mSurface->GetOrCreateTexture(inHardware);
            mElement.mBitmapRepeat = bmp->repeat;
            mElement.mBitmapSmooth = bmp->smooth;
          }
       }
       return false;
   }

   ~HardwareBuilder()
   {
      if (mSurface)
         mSurface->DecRef();
   }


   void CalcTexCoords()
   {
      Vertices &vertices = mArrays->mVertices;
      Vertices &tex = mArrays->mTexCoords;
      int v0 = vertices.size();
      int t0 = tex.size();
      tex.resize(v0);
      for(int i=t0;i<v0;i++)
      {
         UserPoint p = mTextureMapper.Apply(vertices[i].x,vertices[i].y);
         if (mTexture)
         {
            p = mTexture->PixelToTex(p);
         }
         else
         {
            // The point will be in the (-819.2 ... 819.2) range...
            p.x = (p.x +819.2) / 1638.4;
            if (mGradReflect)
               p.x *= 0.5;
            p.y = 0;
         }
			tex[i] = p;
       }
   }


	void AddTriangles(GraphicsTrianglePath *inPath)
	{
		Vertices &vertices = mArrays->mVertices;
      Vertices &tex = mArrays->mTexCoords;
      DrawElements &elements = mArrays->mElements;
		bool persp = inPath->mType == vtVertexUVT;
      mElement.mFirst = vertices.size() / (persp?2:1);
      mElement.mPrimType = ptTriangles;

		const float *t = &inPath->mUVT[0];
		for(int v=0;v<inPath->mVertices.size();v++)
		{
			if (!persp)
			  vertices.push_back(inPath->mVertices[v]);

			if (inPath->mType != vtVertex)
         {
            tex.push_back( mTexture->TexToPaddedTex( UserPoint(t[0],t[1]) ) );
				t+=2;
            if (persp)
				{
					float w= 1.0/ *t++;
			      vertices.push_back(inPath->mVertices[v]*w);
			      vertices.push_back( UserPoint(0,w) );
				}
         }
		}

		mElement.mCount = (vertices.size() - mElement.mFirst)/(persp ? 2:1);
      elements.push_back(mElement);
	}

   void AddObject(const uint8* inCommands, int inCount,
                  const float *inData,  bool inClose)
   {
      Vertices &vertices = mArrays->mVertices;
      Vertices &tex = mArrays->mTexCoords;
      DrawElements &elements = mArrays->mElements;
      mElement.mFirst = vertices.size();

      UserPoint *point = (UserPoint *)inData;
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;

      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
         {
            case pcBeginAt:
               if (points>0)
               {
                  point++;
                  continue;
               }
            case pcMoveTo:
               if (points>1)
               {
                  if (inClose)
                     vertices.push_back(last_move);
                  mElement.mCount = vertices.size() - mElement.mFirst;
                 if (mSurface)
                    CalcTexCoords();
                  elements.push_back(mElement);
               }
               else if (points==1 && last_move==*point)
               {
                  point++;
                  continue;
               }

               points = 1;
               last_point = *point++;
               last_move = last_point;
               mElement.mFirst = vertices.size();
               vertices.push_back(last_move);
               break;

            case pcLineTo:
               if (points>0)
               {
                  vertices.push_back(*point);
                  last_point = *point++;
                  points++;
               }
               break;

            case pcCurveTo:
               {
               double len = ((last_point-point[0]).Norm() + (point[1]-point[0]).Norm()) * 0.25;
               if (len==0)
                  break;
               int steps = (int)len;
               if (steps<3) steps = 3;
               if (steps>100) steps = 100;
               double step = 1.0/(steps+1);
               double t = 0;

               for(int s=0;s<steps;s++)
               {
                  t+=step;
                  double t_ = 1.0-t;
                  UserPoint p = last_point * (t_*t_) + point[0] * (2.0*t*t_) + point[1] * (t*t);
                  vertices.push_back(p);
               }

               last_point = point[1];
               vertices.push_back(last_point);
               point += 2;
               points++;
               }
               break;

            case pcTile:
               if (mTileMode)
               {
                  UserPoint pos(point[0]);
                  UserPoint tex_pos(point[1]);
                  UserPoint size(point[2]);

                  vertices.push_back(pos);
                  vertices.push_back( UserPoint(pos.x+size.x,pos.y) );
                  vertices.push_back( UserPoint(pos.x+size.x,pos.y+size.y) );
                  vertices.push_back(pos);
                  vertices.push_back( UserPoint(pos.x+size.x,pos.y+size.y) );
                  vertices.push_back( UserPoint(pos.x,pos.y+size.y) );

                  pos = tex_pos;
                  tex.push_back( mTexture->PixelToTex(pos) );
                  tex.push_back( mTexture->PixelToTex(pos) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y)) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y+size.y)) );
                  tex.push_back( mTexture->PixelToTex(pos) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y+size.y)) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x,pos.y+size.y)) );
               }
               point += 3;
         }
      }

      if (points>0 || (mTileMode && vertices.size()))
      {
         //mVertices.push_back(last_move);
         mElement.mCount = vertices.size() - mElement.mFirst;
         //printf("%d\n", mElement.mCount);
         if (mSurface && !mTileMode)
            CalcTexCoords();
         elements.push_back(mElement);
      }
   }


   HardwareArrays *mArrays;
   Surface      *mSurface;
   DrawElement mElement;
   Texture     *mTexture;
   bool        mGradReflect;
   bool        mTileMode;
   Matrix      mTextureMapper;
};

void CreatePointJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
{
   DrawElement elem;


   elem.mColour = 0xffffffff;
	GraphicsSolidFill *fill = inJob.mFill ? inJob.mFill->AsSolidFill() : 0;
	if (fill)
		elem.mColour = fill->mRGB.ToInt();

   elem.mPrimType = ptPoints;
   elem.mScaleMode = ssmNormal;
   elem.mWidth = -1;

   elem.mCount = inJob.mDataCount / (fill ? 2 : 3);

   HardwareArrays *arrays = &ioData.GetArrays(0,fill==0);
   Vertices &vertices = arrays->mVertices;
   elem.mFirst = vertices.size();
	vertices.resize( elem.mFirst + elem.mCount );
	memcpy( &vertices[elem.mFirst], &inPath.data[ inJob.mData0 ], elem.mCount*sizeof(UserPoint) );

	if (!fill)
	{
	   Colours &colours = arrays->mColours;
	   colours.resize( elem.mFirst + elem.mCount );
	   memcpy( &colours[elem.mFirst], &inPath.data[ inJob.mData0 + elem.mCount*2],
			         elem.mCount*sizeof(int) );
	}

   arrays->mElements.push_back(elem);
}

void BuildHardwareJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                      HardwareContext &inHardware)
{
	if (inJob.mIsPointJob)
		CreatePointJob(inJob,inPath,ioData,inHardware);
	else
	{
      HardwareBuilder builder(inJob,inPath,ioData,inHardware);
	}
}


// --- HardwareArrays ---------------------------------------------------------------------

HardwareArrays::HardwareArrays(Surface *inSurface,bool inPersp)
{
	mPerspectiveCorrect = inPersp;
   mSurface = inSurface;
   if (inSurface)
      inSurface->IncRef();
}

HardwareArrays::~HardwareArrays()
{
   if (mSurface)
      mSurface->DecRef();
}

// --- HardwareData ---------------------------------------------------------------------
HardwareData::~HardwareData()
{
   mCalls.DeleteAll();
}

HardwareArrays &HardwareData::GetArrays(Surface *inSurface,bool inWithColour,bool inPersp)
{
   if (mCalls.empty() || mCalls.last()->mSurface != inSurface ||
		     mCalls.last()->mColours.empty() != inWithColour ||
		     mCalls.last()->mPerspectiveCorrect != inPersp )
   {
       HardwareArrays *arrays = new HardwareArrays(inSurface,inPersp);
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
      }
   }

   return false;
}



} // end namespace nme

