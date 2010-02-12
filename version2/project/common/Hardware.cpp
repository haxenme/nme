#include <Graphics.h>
#include <Surface.h>

namespace nme
{

class HardwareBuilder
{
public:
   HardwareBuilder(HardwareData &ioData,SolidData *inSolidData)
   {
      mElement.mType = ptTriangleFan;
      mElement.mFirst = 0;
      mElement.mCount = 0;
      mElement.mScaleMode = ssmNormal;
      mElement.mWidth = -1;
      mElement.mColour = 0;

      SetFill(inSolidData->mFill);

		mArrays = &ioData.GetArrays(mSurface);

      AddObject(inSolidData->command,inSolidData->data,true);
   }

   HardwareBuilder(HardwareData &ioData,LineData *inLineData)
   {
		mElement.mType = ptLineStrip;
      mElement.mFirst = 0;
      mElement.mCount = 0;
      mElement.mScaleMode = inLineData->mStroke->scaleMode;
      mElement.mWidth = inLineData->mStroke->thickness;
      mElement.mColour = 0;
      bool textured = SetFill(inLineData->mStroke->fill);
		mArrays = &ioData.GetArrays(mSurface);

      AddObject(inLineData->command,inLineData->data,false);
   }

  
   bool SetFill(IGraphicsFill *inFill)
   {
       mSurface = 0;

       GraphicsSolidFill *solid = inFill->AsSolidFill();
       if (solid)
       {
           mElement.mColour = solid->mRGB.ival;
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

             mTextureMapper = grad->matrix.Inverse();

				 return true;
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
			// The point will be in the (-819.2 ... 819.2) range...
			p.x = (p.x +819.2) / 1638.4;
			if (mGradReflect)
				p.x *= 0.5;
			p.y = 0;
			tex[i] = p;
		 }
	}




   void AddObject(const QuickVec<uint8> &inCommands, const QuickVec<float> &inData, bool inClose)
   {
		Vertices &vertices = mArrays->mVertices;
		DrawElements &elements = mArrays->mElements;
		mElement.mFirst = vertices.size();

      int n = inCommands.size();
      UserPoint *point = (UserPoint *)&inData[0];
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;

      for(int i=0;i<n;i++)
      {
         switch(inCommands[i])
         {
            case pcWideMoveTo:
               point++;
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
               points = 1;
               last_point = *point++;
               last_move = last_point;
               mElement.mFirst = vertices.size();
               vertices.push_back(last_move);
               break;

            case pcWideLineTo:
               point++;
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
         }
      }

      if (points>0)
      {
         //mVertices.push_back(last_move);
         mElement.mCount = vertices.size() - mElement.mFirst;
			if (mSurface)
				CalcTexCoords();
         elements.push_back(mElement);
      }
   }

	/*
   bool Render( const RenderTarget &inTarget, const RenderState &inState )
   {
      if (mLineWidth>=0)
      {
         double thick = mLineWidth;
         const Matrix &m = *inState.mTransform.mMatrix;
         switch(mStrokeScaleMode)
         {
            case ssmNone:
               // Done!
               break;
            case ssmNormal:
               thick *= sqrt( 0.5*(m.m00*m.m00 + m.m01*m.m01 + m.m10*m.m10 + m.m11*m.m11) );
               break;
            case ssmVertical:
               thick *= sqrt( m.m00*m.m00 + m.m01*m.m01 );
               break;
            case ssmHorizontal:
               thick *= sqrt( m.m10*m.m10 + m.m11*m.m11 );
               break;
         }
         inTarget.mHardware->SetLineWidth(thick,true);
      }

      inTarget.mHardware->Render(inState,mElements,mVertices,mTexCoords,mSurface,mColour);
      return true;
   }
	*/

	HardwareArrays *mArrays;
   Surface      *mSurface;
   DrawElement mElement;
	bool        mGradReflect;
	Matrix      mTextureMapper;
};

void LineData::BuildHardware(HardwareData &ioData)
{
	HardwareBuilder builder(ioData,this);
}

void SolidData::BuildHardware(HardwareData &ioData)
{
	HardwareBuilder builder(ioData,this);
}

// --- HardwareData ---------------------------------------------------------------------

void HardwareArrays::clear()
{
	if (mSurface)
		mSurface->DecRef();
	mVertices.clear();
	mTexCoords.clear();
	mElements.clear();
}

HardwareData::~HardwareData()
{
	for(int c=0;c<mCalls.size();c++)
		mCalls[c].clear();
}

HardwareArrays &HardwareData::GetArrays(Surface *inSurface)
{
	if (mCalls.empty() || mCalls.last().mSurface != inSurface)
	{
#error - make HardwareCalls a pointer, and change clear to delete.
	}

	return mCalls.last();
}



// --- Texture -----------------------------
void Texture::Dirty(const Rect &inRect)
{
   if (!mDirtyRect.HasPixels())
      mDirtyRect = inRect;
   else
      mDirtyRect = mDirtyRect.Union(inRect);
}

} // end namespace nme

