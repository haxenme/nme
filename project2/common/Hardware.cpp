#include <Graphics.h>
#include <Surface.h>

class HardwareRenderer : public Renderer
{
public:
   HardwareRenderer(SolidData *inSolidData)
   {
      AddObject(inSolidData->command,inSolidData->data,ptTriangleFan,true);
      SetFill(inSolidData->mFill);
      mLineWidth = -1;
      mStrokeScaleMode = ssmNormal;
   }

   HardwareRenderer(LineData *inLineData)
   {
      AddObject(inLineData->command,inLineData->data,ptLineStrip,false);
      SetFill(inLineData->mStroke->fill);
      mLineWidth = inLineData->mStroke->thickness;
      mStrokeScaleMode = inLineData->mStroke->scaleMode;
   }


   void SetFill(IGraphicsFill *inFill)
   {
       mColour = 0;
       mSurface = 0;

       GraphicsSolidFill *solid = inFill->AsSolidFill();
       if (solid)
       {
           mColour = solid->mRGB.ival;
       }
       else
       {
          GraphicsGradientFill *grad = inFill->AsGradientFill();
          if (grad)
          {
             bool reflect = grad->spreadMethod == smReflect;
             int w = reflect ? 512 : 256;
             mSurface = new SimpleSurface(w,1,pfARGB);
             mSurface->IncRef();
             grad->FillArray( (ARGB *)mSurface->GetBase(), false);

             Matrix mtx = grad->matrix.Inverse();

             // Set up texture coordinates..
             mTexCoords.resize(mVertices.size());
             for(int i=0;i<mTexCoords.size();i++)
             {
                 UserPoint p = mtx.Apply(mVertices[i].x,mVertices[i].y);
                 // The point will be in the (-819.2 ... 819.2) range...
                 p.x = (p.x +819.2) / 1638.4;
                 if (reflect)
                    p.x *= 0.5;
                 p.y = 0;
                 mTexCoords[i] = p;
             }
          }
       }
   }

   ~HardwareRenderer()
   {
      if (mSurface)
         mSurface->DecRef();
   }


   void AddObject(const QuickVec<uint8> &inCommands, const QuickVec<float> &inData,
                  PrimType inType, bool inClose)
   {
      int n = inCommands.size();
      UserPoint *point = (UserPoint *)&inData[0];
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;

      DrawElement draw;
      draw.mType = inType;
      draw.mFirst = 0;
      draw.mCount = 0;


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
                     mVertices.push_back(last_move);
                  draw.mCount = mVertices.size() - draw.mFirst;
                  mElements.push_back(draw);
               }
               points = 1;
               last_point = *point++;
               last_move = last_point;
               draw.mFirst = mVertices.size();
               mVertices.push_back(last_move);
               break;

            case pcWideLineTo:
               point++;
            case pcLineTo:
               if (points>0)
               {
                  mVertices.push_back(*point);
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
                  mVertices.push_back(p);
               }

               last_point = point[1];
               mVertices.push_back(last_point);
               point += 2;
               points++;
               }
               break;
         }
      }

      if (points>0)
      {
         //mVertices.push_back(last_move);
         draw.mCount = mVertices.size() - draw.mFirst;
         mElements.push_back(draw);
      }
   }

   void Destroy() { delete this; }

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

   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent)
   {
      return false;
   }

   uint32       mColour;
   Surface      *mSurface;
   Vertices     mVertices;
   Vertices     mTexCoords;
   DrawElements mElements;

   double       mLineWidth;
   StrokeScaleMode mStrokeScaleMode;
};


Renderer *Renderer::CreateHardware(LineData *inLineData)
{
    return new HardwareRenderer(inLineData);
}

Renderer *Renderer::CreateHardware(SolidData *inSolidData)
{
    return new HardwareRenderer(inSolidData);
}
 

// --- Texture -----------------------------
void Texture::Dirty(const Rect &inRect)
{
   if (!mDirtyRect.HasPixels())
      mDirtyRect = inRect;
   else
      mDirtyRect = mDirtyRect.Union(inRect);
}

