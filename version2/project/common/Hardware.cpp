#include <Graphics.h>
#include <Surface.h>

namespace nme
{

class HardwareBuilder
{
public:
   HardwareBuilder(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData)
   {
		if (inJob.mFill)
		{
         mElement.mType = ptTriangleFan;
         mElement.mScaleMode = ssmNormal;
         mElement.mWidth = -1;
         SetFill(inJob.mFill);
		}
		else
		{
         mElement.mType = ptLineStrip;
			GraphicsStroke *stroke = inJob.mStroke;
         mElement.mScaleMode = stroke->scaleMode;
         mElement.mWidth = stroke->thickness;
         SetFill(stroke->fill);
		}
      mElement.mFirst = 0;
      mElement.mCount = 0;
      mElement.mColour = 0;


      mArrays = &ioData.GetArrays(mSurface);

      AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount,
					 &inPath.data[inJob.mData0], inJob.mFill);
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




   void AddObject(const uint8* inCommands, int inCount,
						const float *inData,  bool inClose)
   {
      Vertices &vertices = mArrays->mVertices;
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
						continue;
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

void BuildHardwareJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData)
{
   HardwareBuilder builder(inJob,inPath,ioData);
}


// --- HardwareArrays ---------------------------------------------------------------------

HardwareArrays::HardwareArrays(Surface *inSurface)
{
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

HardwareArrays &HardwareData::GetArrays(Surface *inSurface)
{
   if (mCalls.empty() || mCalls.last()->mSurface != inSurface)
   {
       HardwareArrays *arrays = new HardwareArrays(inSurface);
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

} // end namespace nme

