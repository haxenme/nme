#include "PolygonRender.h"
#include <Surface.h>


namespace nme
{

const double one_on_255 = 1.0/255.0;

struct TileData
{
   UserPoint    mPos;
   Rect         mRect;
   UserPoint    mTransX;
   UserPoint    mTransY;
   UserPoint    mOffset;
   unsigned int mColour;
   bool         mHasTrans;
   bool         mHasColour;

   TileData(){}

   inline TileData(const UserPoint *inPoint,int inFlags, int inWidth, int inHeight)
      : mPos(*inPoint)
   {
      if (inFlags & pcTile_Fixed_Size_Bit)
      {
         mOffset = mPos;
         mPos = *++inPoint;
      }
      if (inFlags & pcTile_Full_Image_Bit)
      {
         mRect = Rect(0,0,inWidth,inHeight);
         inPoint += 1;
      }
      else
      {
         mRect = Rect(inPoint[1].x, inPoint[1].y, inPoint[2].x, inPoint[2].y);
         inPoint += 3;
      }

      mHasTrans =  (inFlags & pcTile_Trans_Bit);
      if (mHasTrans)
      {
         mTransX = *inPoint++;
         mTransY = *inPoint++;
      }

      mHasColour = (inFlags & pcTile_Col_Bit);
      if (mHasColour)
      {
         UserPoint rg = inPoint[0];
         UserPoint ba = inPoint[1];
         mColour = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))<<16) |
                   ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
                   ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))) |
                   ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
      }
   }
};



class TileRenderer : public Renderer
{
public:

   GraphicsBitmapFill *mFill;
   Filler             *mFiller;
   QuickVec<TileData> mTileData;
   BlendMode          mBlendMode;
   unsigned int       mFlags;
   bool               mIsFixed;

   TileRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath)
   {
      mFill = inJob.mFill->AsBitmapFill();
      mFill->IncRef();
      mFiller = Filler::Create(mFill);
      int w = mFill->bitmapData->Width();
      int h = mFill->bitmapData->Height();
      const UserPoint *point = (const UserPoint *)&inPath.data[inJob.mData0];
      mTileData.reserve( inJob.mTileCount );
      mBlendMode = bmNormal;
      if (inJob.mBlendMode==pcBlendModeAdd)
         mBlendMode = bmAdd;
      mFlags = mFill->smooth ? 1 : 0;

      int size = (inJob.mTileMode & pcTile_Full_Image_Bit) ? 1 : 3;
      if (inJob.mTileMode & pcTile_Trans_Bit)
         size+=2;
      if (inJob.mTileMode & pcTile_Col_Bit)
         size+=2;
      mIsFixed = inJob.mTileMode & pcTile_Fixed_Size_Bit;
      if (mIsFixed)
         size+=1;


      for(int j=0; j<inJob.mTileCount; j++)
      {
         TileData data(point, inJob.mTileMode ,w,h);
         mTileData.push_back(data);

         point += size;
      }
   }
   
   
   ~TileRenderer()
   {
      mFill->DecRef();
      delete mFiller;
   }
   
   
   void Destroy()
   {
      delete this;
   }
   
   
   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent, bool)
   {
      /*
      printf("In extent %f,%f ... %f,%f\n",
             ioExtent.mMinX, ioExtent.mMinY,
             ioExtent.mMaxX, ioExtent.mMaxY );
      */

      for(int i=0;i<mTileData.size();i++)
      {
         TileData &data= mTileData[i];
         UserPoint p0(data.mPos);
         if (mIsFixed)
            p0 = inTransform.mMatrix->Apply(p0.x,p0.y) -data.mOffset;;

         for(int c=0;c<4;c++)
         {
            UserPoint corner(p0);
            if (mIsFixed)
            {
               if (c&1) corner.x += data.mRect.w;
               if (c&2) corner.y += data.mRect.h;
               ioExtent.Add( corner );
            }
            else
            {
               if (c&1) corner.x += data.mRect.w;
               if (c&2) corner.y += data.mRect.h;
               ioExtent.Add( inTransform.mMatrix->Apply(corner.x,corner.y) );
            }
         }
      }
      /*
      printf("Got extent %f,%f ... %f,%f\n",
             ioExtent.mMinX, ioExtent.mMinY,
             ioExtent.mMaxX, ioExtent.mMaxY );
      */
      return true;
   }
   
   
   bool Hits(const RenderState &inState)
   {
      return false;
   }
   
   
   bool Render(const RenderTarget &inTarget, const RenderState &inState)
   {
      #define orthoTol 1e-6

      Surface *s = mFill->bitmapData;
      double bmp_scale_x = 1.0/s->Width();
      double bmp_scale_y = 1.0/s->Height();
      
      bool is_base_ortho = fabs(inState.mTransform.mMatrix->m01)< orthoTol  && fabs(inState.mTransform.mMatrix->m10)< orthoTol;
      float sx = inState.mTransform.mMatrix->m00;
      float sy = inState.mTransform.mMatrix->m11;
      bool is_base_identity = is_base_ortho && (mIsFixed || (fabs(sx-1.0)<orthoTol && fabs(sy-1.0)<orthoTol));

      //int blits = 0;
      //int stretches = 0;
      //int renders = 0;

      for(int i=0;i<mTileData.size();i++)
      {
         TileData &data= mTileData[i];

         BlendMode blend = data.mHasColour ? ( mBlendMode==bmAdd ? bmTintedAdd : bmTinted ):
                                               mBlendMode;
         UserPoint corner(data.mPos);
         UserPoint pos = inState.mTransform.mMatrix->Apply(corner.x,corner.y);


         bool is_ortho = is_base_ortho && (!data.mHasTrans || fabs(data.mTransX.y)<orthoTol);
         bool is_identity = data.mHasTrans ?
                           is_ortho && fabs(sx*data.mTransX.x-1.0)<orthoTol && fabs(sy*data.mTransY.y-1)<orthoTol :
                           is_base_identity;


         if ( !is_identity )
         {
            // Can use stretch if there is no skew and no colour transform...
            if (!data.mHasColour && mBlendMode==bmNormal && is_ortho )
            {
               UserPoint p0 = pos;
               if (mIsFixed)
               {
                  p0 -= data.mOffset;
                  if (data.mHasTrans)
                     pos = p0 + UserPoint(data.mRect.w*data.mTransX.x, data.mRect.h*data.mTransY.y);
                  else
                     pos = p0 + UserPoint(data.mRect.w,data.mRect.h);
               }
               else
               {
                  if (data.mHasTrans)
                     pos = inState.mTransform.mMatrix->Apply(corner.x+data.mRect.w*data.mTransX.x,
                                                          corner.y+data.mRect.h*data.mTransY.y);
                  else
                     pos = inState.mTransform.mMatrix->Apply(corner.x+data.mRect.w,corner.y+data.mRect.h);
               }

               s->StretchTo(inTarget, data.mRect, DRect(p0.x,p0.y,pos.x,pos.y,true), mFlags);

               //stretches++;
            }
            else
            {
               //renders++;

               int tile_alpha = 256;
               bool just_alpha = (data.mHasColour) &&
                                 ((data.mColour&0x00ffffff ) == 0x00ffffff);
               if (data.mHasColour && mBlendMode==bmNormal)
               { 
                  tile_alpha = data.mColour>>24;
                  if (tile_alpha>0) tile_alpha++;
               }
               // Create alpha mask...
               UserPoint p[4];
               if (mIsFixed)
               {
                  p[0] = pos - data.mOffset;
                  if (data.mHasTrans)
                  {
                     p[1] = p[0] + UserPoint( data.mRect.w*data.mTransX.x, data.mRect.w*data.mTransY.x);
                     p[2] = p[1] + UserPoint( data.mRect.w*data.mTransY.x, data.mRect.h*data.mTransY.y );
                     p[3] = p[0] + UserPoint( data.mRect.w*data.mTransY.x, data.mRect.h*data.mTransY.y );
                  }
                  else
                  {
                     p[1] = p[0];
                     p[1].x += data.mRect.w;
                     p[2] = p[1];
                     p[2].y += data.mRect.h;
                     p[3] = p[0];
                     p[3].y += data.mRect.h;
                  }

               }
               else
               {
                  p[0] = inState.mTransform.mMatrix->Apply(corner.x,corner.y);
                  if (data.mHasTrans)
                  {
                     p[1] = inState.mTransform.mMatrix->Apply(
                               corner.x + data.mRect.w*data.mTransX.x,
                               corner.y + data.mRect.w*data.mTransY.x);
                     p[2] = inState.mTransform.mMatrix->Apply(
                               corner.x + data.mRect.w*data.mTransX.x + data.mRect.h*data.mTransX.y,
                               corner.y + data.mRect.w*data.mTransY.x + data.mRect.h*data.mTransY.y );
                     p[3] = inState.mTransform.mMatrix->Apply(
                               corner.x + data.mRect.h*data.mTransX.y,
                               corner.y + data.mRect.h*data.mTransY.y );
                  }
                  else
                  {
                     p[1] = inState.mTransform.mMatrix->Apply(corner.x+data.mRect.w,corner.y);
                     p[2] = inState.mTransform.mMatrix->Apply(corner.x+data.mRect.w,corner.y+data.mRect.h);
                     p[3] = inState.mTransform.mMatrix->Apply(corner.x,corner.y+data.mRect.h);
                  }
               }

               Extent2DF extent;
               extent.Add(p[0]);
               extent.Add(p[1]);
               extent.Add(p[2]);
               extent.Add(p[3]);

               // Get bounding pixel rect
               Rect rect = inState.mTransform.GetTargetRect(extent);

               // Intersect with clip rect ...
               Rect visible_pixels = rect.Intersect(inState.mClipRect);
               if (!visible_pixels.HasPixels())
                  continue;

               Rect alpha_rect(visible_pixels);
               bool offscreen_buffer = mBlendMode!=bmNormal;
               if (offscreen_buffer)
               {
                  for(int i=0;i<4;i++)
                  {
                     p[i].x -= visible_pixels.x;
                     p[i].y -= visible_pixels.y;
                  }
                  alpha_rect.x -= visible_pixels.x;
                  alpha_rect.y -= visible_pixels.y;
               }

               int aa = 1;
               SpanRect *span = new SpanRect(alpha_rect,aa);
               // ToImageAA - add 0.5 offset
               for(int i=0;i<4;i++)
                  span->Line00(
                       Fixed10( p[i].x + 0.5, p[i].y + 0.5  ),
                       Fixed10( p[(i+1)&3].x + 0.5, p[(i+1)&3].y + 0.5) );

               AlphaMask *alpha = span->CreateMask(inState.mTransform,tile_alpha);
               delete span;

               float uvt[6];
               uvt[0] = (data.mRect.x) * bmp_scale_x;
               uvt[1] = (data.mRect.y) * bmp_scale_y;
               uvt[2] = (data.mRect.x + data.mRect.w) * bmp_scale_x;
               uvt[3] = (data.mRect.y) * bmp_scale_y;
               uvt[4] = (data.mRect.x + data.mRect.w) * bmp_scale_x;
               uvt[5] = (data.mRect.y + data.mRect.h) * bmp_scale_y;
               mFiller->SetMapping(p,uvt,2);

               // Can render straight to surface ....
               if (!offscreen_buffer)
               {
                  if (s->Format()==pfAlpha)
                  {
                     if (data.mHasColour)
                     {
                        ARGB col = inState.mColourTransform->Transform(data.mColour|0xff000000);
                        mFiller->SetTint(col);
                     }
                     mFiller->Fill(*alpha,0,0,inTarget,inState);
                  }
                  else if (data.mHasTrans && !just_alpha)
                  {
                     ColorTransform buf;
                     RenderState col_state(inState);
                     ColorTransform tint;
                     tint.redMultiplier =   ((data.mColour)   & 0xff) * one_on_255;
                     tint.greenMultiplier = ((data.mColour>>8) & 0xff) * one_on_255;
                     tint.blueMultiplier =  ((data.mColour>>16)  & 0xff) * one_on_255;
                     col_state.CombineColourTransform(inState, &tint, &buf);
                     mFiller->Fill(*alpha,0,0,inTarget,col_state);
                  }
                  else
                     mFiller->Fill(*alpha,0,0,inTarget,inState);
               }
               else
               {
                  // Create temp surface
                  SimpleSurface *tmp = new SimpleSurface(visible_pixels.w,visible_pixels.h, pfBGRA);
                  tmp->IncRef();
                  tmp->Zero();
                  {
                  AutoSurfaceRender tmp_render(tmp);
                  const RenderTarget &target = tmp_render.Target();

                  if (s->Format()==pfAlpha && data.mHasColour)
                  {
                     ARGB col = inState.mColourTransform->Transform(data.mColour|0xff000000);
                     mFiller->SetTint(col);
                  }


                  mFiller->Fill(*alpha,0,0,target,inState);
                  }

                  tmp->BlitTo(inTarget, Rect(0,0,visible_pixels.w,visible_pixels.h),
                          visible_pixels.x, visible_pixels.y,
                         just_alpha ? bmAdd : blend, 0, data.mColour | 0xff000000);

                  tmp->DecRef();
               }

               alpha->Dispose();
            }
         }
         else if (s->Format()==pfAlpha && mBlendMode==bmNormal && data.mHasColour /* integer co-ordinate?*/ )
         {
            if (mIsFixed)
               pos -= data.mOffset;
            //blits++;
            unsigned int col = inState.mColourTransform->Transform(data.mColour|0xff000000);
            s->BlitTo(inTarget, data.mRect, (int)(pos.x), (int)(pos.y), blend, 0, col);
         }
         else
         {
            if (mIsFixed)
               pos -= data.mOffset;
            //blits++;
            s->BlitTo(inTarget, data.mRect, (int)(pos.x), (int)(pos.y), blend, 0, data.mColour);
         }
      }

      //printf("b/s/r = %d/%d/%d\n", blits, stretches, renders);
      
      return true;
   }

};

Renderer *CreateTileRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   return new TileRenderer(inJob,inPath);
}


} // end namespace anme
