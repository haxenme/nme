#include <Graphics.h>
#include <Surface.h>


#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


namespace nme
{

class HardwareBuilder
{
public:
   HardwareBuilder(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
   {
      mTexture = 0;
      bool tile_mode = false;
      mElement.mColour = 0xffffffff;
      mSolidMode = false;
      mPerpLen = 0.5;
      bool tessellate_lines = false;

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
         tile_mode = true;
      }
      else if (inJob.mFill)
      {
         mSolidMode = true;
         mElement.mPrimType = inJob.mTriangles ? ptTriangles : ptTriangleFan;
         mElement.mScaleMode = ssmNormal;
         mElement.mWidth = -1;
         if (!SetFill(inJob.mFill,inHardware))
            return;
      }
      else if (tessellate_lines)
      {
         // ptTriangleStrip?
         mElement.mPrimType = ptTriangles;
         GraphicsStroke *stroke = inJob.mStroke;
         if (!SetFill(stroke->fill,inHardware))
            return;

         mPerpLen = stroke->thickness * 0.5;
         if (mPerpLen<=0.0)
            mPerpLen = 0.5;
         else if (mPerpLen<0.5)
         {
            mPerpLen = 0.5;
         }

         mCaps = stroke->caps;
         mJoints = stroke->joints;
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
      else if (tile_mode)
      {
         mArrays = &ioData.GetArrays(mSurface,false);
         AddTiles(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
      else if (tessellate_lines && !mSolidMode)
      {
         mArrays = &ioData.GetArrays(mSurface,false);
         AddLineTriangles(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
      else
      {
         mArrays = &ioData.GetArrays(mSurface,false);
         AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
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
         if (solid -> mRGB.a == 0)
            return false;
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

            //return true;
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
       //return false;
       return true;
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
      Colours &colours = mArrays->mColours;
      Vertices &tex = mArrays->mTexCoords;
      DrawElements &elements = mArrays->mElements;
      bool persp = inPath->mType == vtVertexUVT;
      mElement.mFirst = vertices.size() / (persp?2:1);
      mElement.mPrimType = ptTriangles;
      
      //Just overwriting blend mode and viewport
      mArrays->mViewport = inPath->mViewport;
      mArrays->mBlendMode = inPath->mBlendMode;
      
      const float *t = &inPath->mUVT[0];
      for(int v=0;v<inPath->mVertices.size();v++)
      {
         if (!persp)
         {
           vertices.push_back(inPath->mVertices[v]);
           if(inPath->mColours.size()>0)
           {
              colours.push_back(inPath->mColours[v]);/*mwb*/
           }
         }

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

  void AddTiles(const uint8* inCommands, int inCount, const float *inData)
  {
      Vertices &vertices = mArrays->mVertices;
      Vertices &tex = mArrays->mTexCoords;
      UserPoint *point = (UserPoint *)inData;
      mElement.mFirst = vertices.size();
      mArrays->mBlendMode = bmNormal;

      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
         {
            case pcBlendModeAdd:
               mArrays->mBlendMode = bmAdd;
               break;

            case pcBeginAt: case pcMoveTo: case pcLineTo:
               point++;
               break;
            case pcCurveTo:
               point+=2;
               break;

            case pcTile:
            case pcTileTrans:
            case pcTileCol:
            case pcTileTransCol:
               {
                  UserPoint pos(point[0]);
                  UserPoint tex_pos(point[1]);
                  UserPoint size(point[2]);
                  point += 3;

                  if (inCommands[i]&pcTile_Trans_Bit)
                  {
                     UserPoint dxx_dxy = *point++;
                     UserPoint p1(pos.x+size.x*dxx_dxy.x,
                                  pos.y-size.x*dxx_dxy.y);
                     UserPoint p2(pos.x+size.x*dxx_dxy.x+size.y*dxx_dxy.y,
                                  pos.y-size.x*dxx_dxy.y+size.y*dxx_dxy.x );
                     UserPoint p3(pos.x+size.y*dxx_dxy.y,
                                  pos.y+size.y*dxx_dxy.x);

                     vertices.push_back( pos );
                     vertices.push_back( p1 );
                     vertices.push_back( p2 );
                     vertices.push_back( pos) ;
                     vertices.push_back( p2 );
                     vertices.push_back( p3 );
                  }
                  else
                  {
                     vertices.push_back(pos);
                     vertices.push_back( UserPoint(pos.x+size.x,pos.y) );
                     vertices.push_back( UserPoint(pos.x+size.x,pos.y+size.y) );
                     vertices.push_back(pos);
                     vertices.push_back( UserPoint(pos.x+size.x,pos.y+size.y) );
                     vertices.push_back( UserPoint(pos.x,pos.y+size.y) );
                  }


                  pos = tex_pos;
                  tex.push_back( mTexture->PixelToTex(pos) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y)) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y+size.y)) );
                  tex.push_back( mTexture->PixelToTex(pos) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x+size.x,pos.y+size.y)) );
                  tex.push_back( mTexture->PixelToTex(UserPoint(pos.x,pos.y+size.y)) );

                  if (inCommands[i]&pcTile_Col_Bit)
                  {
                     UserPoint rg = *point++;
                     UserPoint ba = *point++;
                     Colours &colours = mArrays->mColours;
                     uint32 col = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))) |
                                  ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
                                  ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))<<16) |
                                  ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                     colours.push_back( col );
                  }
               }
         }
      }

      mElement.mCount = vertices.size() - mElement.mFirst;
      if (mElement.mCount>0)
         mArrays->mElements.push_back(mElement);
   }


   #define FLAT 0.000001
   void AddPolygon(Vertices &inOutline,const QuickVec<int> &inSubPolys)
   {
      if (mSolidMode && inOutline.size()<3)
         return;

      Vertices &vertices = mArrays->mVertices;
      mElement.mFirst = vertices.size();
      bool isConvex = inSubPolys.size()==1;
      if (mSolidMode)
      {
         if (isConvex)
         {
            UserPoint base = inOutline[0];
            int last = inOutline.size()-2;
            int i = 0;
            bool positive = true;
            for( ;i<last;i++)
            {
               UserPoint v0 = inOutline[i+1]-base;
               UserPoint v1 = inOutline[i+2]-base;
               double diff = v0.Cross(v1);
               if (fabs(diff)>FLAT)
               {
                  positive = diff > 0;
                  break;
               }
            }

            for(++i;i<last;i++)
            {
               UserPoint v0 = inOutline[i+1]-base;
               UserPoint v1 = inOutline[i+2]-base;
               double diff = v0.Cross(v1);
               if (fabs(diff)>FLAT && (diff>0)!=positive)
               {
                  isConvex = false;
                  break;
               }
            }
         }
         if (!isConvex)
            ConvertOutlineToTriangles(inOutline,inSubPolys);
      }


      mElement.mCount = inOutline.size();
      vertices.resize(mElement.mFirst + mElement.mCount);
      for(int i=0;i<inOutline.size();i++)
         vertices[i+mElement.mFirst] = inOutline[i];
      if (mSurface)
         CalcTexCoords();
      mArrays->mElements.push_back(mElement);

      if (!isConvex)
         mArrays->mElements.last().mPrimType = ptTriangles;
   }


  void AddObject(const uint8* inCommands, int inCount, const float *inData)
  {
      UserPoint *point = (UserPoint *)inData;
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;
      QuickVec<int> sub_poly_start;

      mArrays->mBlendMode =bmNormal;

      Vertices outline;


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
               // fallthrough
            case pcMoveTo:
               if (points>1)
               {
                  // Move in the middle of a solid polygon - treat like a line...
                  if (mSolidMode)
                  {
                     sub_poly_start.push_back(outline.size());
                     outline.push_back(*point);
                     last_point = *point++;
                     points++;
                     break;
                  }
                  sub_poly_start.push_back(outline.size());
                  AddPolygon(outline,sub_poly_start);
               }
               else if (points==1 && last_move==*point)
               {
                  point++;
                  continue;
               }

               outline.resize(0);
               sub_poly_start.resize(0);
               points = 1;
               last_point = *point++;
               last_move = last_point;
               if (outline.empty()||outline.last()!=last_move)
                  outline.push_back(last_move);
               break;

            case pcLineTo:
               if (points>0)
               {
                  if (outline.empty() || outline.last()!=*point)
                     outline.push_back(*point);
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
                  if (outline.last()!=p)
                     outline.push_back(p);
               }
               last_point = point[1];
               if (outline.last()!=last_point)
                   outline.push_back(last_point);
               point += 2;
               points++;
               }
               break;

            case pcTile:
            case pcTileTrans:
            case pcTileCol:
            case pcTileTransCol:
               point += 3;
               if (inCommands[i]&pcTile_Trans_Bit)
                  point++;
               if (inCommands[i]&pcTile_Col_Bit)
                  point+=2;
         }
      }

      if (!outline.empty())
      {
         int n = outline.size();
         if (sub_poly_start.empty() || sub_poly_start.last()!=n)
            sub_poly_start.push_back(n);
         AddPolygon(outline,sub_poly_start);
      }
   }

   struct Segment
   {
      inline Segment() { }
      inline Segment(const UserPoint &inP) : p(inP), curve(inP) { }
      inline Segment(const UserPoint &inP,const UserPoint &inCurve) : p(inP), curve(inCurve) { }

      UserPoint getDir0(const UserPoint &inP0) const { return curve-inP0; }
      UserPoint getDir1(const UserPoint &inP0) const { return isCurve() ? p-curve : p-inP0; }
      UserPoint getDirAverage(const UserPoint &inP0) const { return p-inP0; }

      inline bool isCurve() const { return p!=curve; }

      UserPoint p;
      UserPoint curve;
   };


   void AddStrip(const QuickVec<Segment> &inPath, bool inLoop)
   {
      Vertices &vertices = mArrays->mVertices;
      mElement.mFirst = vertices.size();

      // Endcap 0 ...
      if (!inLoop && (mCaps==scSquare || mCaps==scRound))
      {
         UserPoint p0 = inPath[0].p;
         UserPoint perp = inPath[1].getDir0(p0).Perp(mPerpLen);

         UserPoint back(-perp.y, perp.x);
         if (mCaps==scSquare)
         {
            vertices.push_back(p0+perp);
            vertices.push_back(p0+perp + back);
            vertices.push_back(p0-perp);

            vertices.push_back(p0+perp + back);
            vertices.push_back(p0-perp + back);
            vertices.push_back(p0-perp);
         }
         else
         {
            int n = std::max(2,(int)(mPerpLen * 4));
            double dtheta = M_PI / n;
            double theta = 0.0;
            UserPoint prev(perp);
            for(int i=1;i<n;i++)
            {
               UserPoint p =  perp*cos(theta) + back*sin(theta);
               vertices.push_back(p0);
               vertices.push_back(p0+prev);
               vertices.push_back(p0+p);
               prev = p;
               theta += dtheta;
            }

            vertices.push_back(p0);
            vertices.push_back(p0+prev);
            vertices.push_back(p0-perp);
         }
      }

      UserPoint prev_dir;
      for(int i=1;i<inPath.size();i++)
      {
         const Segment &seg = inPath[i];
          UserPoint p0 = inPath[i-1].p;
          UserPoint p1 = seg.p;

          UserPoint my_dir0 = seg.getDir0(p0).Normalized();
          UserPoint my_dir1 = seg.getDir1(p0).Normalized();

          if (i==1)
             prev_dir = my_dir0;

          UserPoint next_dir;
          if (i+1<inPath.size())
             next_dir = inPath[i+1].getDir0(p1).Normalized();
          else if (!inLoop)
             next_dir = my_dir1;
          else
             next_dir = inPath[1].getDir0(p1).Normalized();

          double theta0 = asin(my_dir0.Dot(prev_dir)) * 0.5;
          double theta1 = asin(my_dir1.Dot(next_dir)) * 0.5;
          bool bend_right0 = prev_dir.Cross(my_dir0) > 0;
          bool bend_right1 = my_dir1.Cross(next_dir) > 0;

          UserPoint perp = seg.getDirAverage(p0).Perp(mPerpLen);

          vertices.push_back(p0-perp);
          vertices.push_back(p0+perp);
          vertices.push_back(p1+perp);

          vertices.push_back(p1+perp);
          vertices.push_back(p1-perp);
          vertices.push_back(p0-perp);

          prev_dir  = my_dir1;
      }


      mElement.mCount = vertices.size()-mElement.mFirst;
      if (mSurface)
         CalcTexCoords();
      mArrays->mElements.push_back(mElement);
   }

   void AddLineTriangles(const uint8* inCommands, int inCount, const float *inData)
   {
      UserPoint *point = (UserPoint *)inData;

      // It is a loop if the path has no breaks, it has more than 2 points
      //  and it finishes where it starts...
      UserPoint first;
      UserPoint prev;

      QuickVec<Segment> strip;

      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
            {
            case pcWideMoveTo:
               point++;
            case pcBeginAt:
            case pcMoveTo:
               if (strip.size()==1 && prev==*point)
               {
                  point++;
                  continue;
               }

               if (strip.size()>1)
                  AddStrip(strip,false);

               strip.resize(0);
               strip.push_back(Segment(*point));
               prev = *point;
               first = *point++;
               break;
               
            case pcWideLineTo:
               point++;
            case pcLineTo:
               {
               if (strip.size()>0 && *point==prev)
               {
                  point++;
                  continue;
               }
 
               strip.push_back(Segment(*point));

               // Implicit loop closing...
               if (strip.size()>2 && *point==first)
               {
                  AddStrip(strip,true);
                  strip.resize(0);
                  first = *point;
               }
               
               prev = *point;
               point++;
               }
               break;
               
            case pcCurveTo:
               {
                  if (strip.size()>0 && *point==prev && point[1]==prev)
                  {
                     point+=2;
                     continue;
                  }
 
                  strip.push_back(Segment(point[1],point[0]));

                  // Implicit loop closing...
                  if (strip.size()>2 && point[1]==first)
                  {
                     AddStrip(strip,true);
                     strip.resize(0);
                     first = point[1];
                  }

                  prev = point[1];
                  point +=2;
              }
               break;
            case pcTile: point+=3; break;
            case pcTileTrans: point+=4; break;
            case pcTileCol: point+=5; break;
            case pcTileTransCol: point+=6; break;
         }
      }

      if (strip.size()>0)
         AddStrip(strip,false);
   }



   HardwareArrays *mArrays;
   Surface      *mSurface;
   DrawElement mElement;
   Texture     *mTexture;
   bool        mGradReflect;
   bool        mSolidMode;
   double      mPerpLen;
   Matrix      mTextureMapper;
   StrokeCaps   mCaps;
   StrokeJoints mJoints;
};

void CreatePointJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareContext &inHardware)
{
   DrawElement elem;

   elem.mColour = 0xffffffff;
   GraphicsSolidFill *fill = inJob.mFill ? inJob.mFill->AsSolidFill() : 0;
   if (fill)
      elem.mColour = fill->mRGB.ToInt();
   GraphicsStroke *stroke = inJob.mStroke;
   if (stroke)
   {
      elem.mScaleMode = stroke->scaleMode;
      elem.mWidth = stroke->thickness;
   }
   else
   {
      elem.mScaleMode = ssmNormal;
      elem.mWidth = -1;
   }

   elem.mPrimType = ptPoints;

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
      const int * src = (const int *)(&inPath.data[ inJob.mData0 + elem.mCount*2]);
      int * dest = &colours[elem.mFirst];
      int n = elem.mCount;
      for(int i=0;i<n;i++)
      {
         int s = src[i];
         dest[i] = (s & 0xff00ff00) | ((s>>16)&0xff) | ((s<<16) & 0xff0000);
      }
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
   #ifdef NME_USE_VBO
   mVertexBO = 0;
   #endif
}

HardwareArrays::~HardwareArrays()
{
   if (mSurface)
      mSurface->DecRef();
   #ifdef NME_USE_VBO
   if (mVertexBO)
      ReleaseVertexBufferObject(mVertexBO);
   #endif
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

