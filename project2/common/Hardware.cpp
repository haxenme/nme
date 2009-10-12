#include <Graphics.h>
#include <Surface.h>

class HardwareRenderer : public Renderer
{
public:
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

   HardwareRenderer(LineData *inLineData)
   {
      SetFill(inLineData->mStroke->fill);
   }

   HardwareRenderer(SolidData *inSolidData)
   {
      int n = inSolidData->command.size();
      UserPoint *point = (UserPoint *)&inSolidData->data[0];
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;

      DrawElement draw;
      draw.mType = ptTriangleFan;
      draw.mFirst = 0;
      draw.mCount = 0;

      for(int i=0;i<n;i++)
      {
         switch(inSolidData->command[i])
         {
            case pcWideMoveTo:
               point++;
            case pcMoveTo:
               if (points>1)
               {
                  mVertices.push_back(last_move);
                  draw.mCount = mVertices.size() - draw.mFirst;
                  mElements.push_back(draw);
               }
               points = 1;
               last_point = *point++;
               last_move = last_point;
               mVertices.push_back(last_move);
               draw.mFirst = mVertices.size();
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
               double len = (last_point-point[0]).Norm() + (point[1]-point[0]).Norm();
               int steps = (int)len;
               if (steps<1) steps = 1;
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

      SetFill(inSolidData->mFill);
   }


   void Destroy() { delete this; }

   bool Render( const RenderTarget &inTarget, const RenderState &inState )
   {
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

