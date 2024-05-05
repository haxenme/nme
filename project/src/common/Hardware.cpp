#include <Graphics.h>
#include <Surface.h>
#include <NMEThread.h>
#include <map>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


namespace nme
{

#ifdef NME_OGL
  #ifdef NME_METAL
     bool nmeOpenglRenderer = true;
  #endif
#endif

enum { DEBUG_KEEP_LOOPS      = 0 };
enum { DEBUG_FAT_LINES       = 0 }; // Could be 0, 1 or 2
enum { DEBUG_UNSCALED        = 0 };
enum { DEBUG_NO_INTERIOR     = 0 };
enum { DEBUG_NO_FAT_FALLBACK = 0 };
enum { DEBUG_EXTRA_FAT       = 0 };
enum { DEBUG_PRINT_THRESH    = 0 };
enum { DEBUG_PRINT_VERBOSE   = 0 };


struct CurveEdge
{
   CurveEdge(const UserPoint &inP, float inT) : p(inP), t(inT) { }
   inline CurveEdge(){}

   UserPoint p;
   float     t;
};
typedef QuickVec<CurveEdge> Curves;

struct Range
{
   inline Range() {}
   inline Range(float inT0, const UserPoint &l0, const UserPoint &r0,
                float inT1, const UserPoint &l1, const UserPoint &r1) :
      t0(inT0), t1(inT1),
      left0(l0), right0(r0),
      left1(l1), right1(r1) { }

   float     t0,t1;
   UserPoint left0;
   UserPoint right0;
   UserPoint left1;
   UserPoint right1;
};

HardwareRenderer *HardwareRenderer::current = nullptr;

//#define DBG_BALANCE
struct PNTri
{
   int p[3];
   int n[3];

   PNTri() { n[0] = n[1] = n[2] = -1; }
   PNTri(int p0, int p1, int p2, int n0, int n1, int n2)
   {
      p[0] = p0;
      p[1] = p1;
      p[2] = p2;

      n[0] = n0;
      n[1] = n1;
      n[2] = n2;
   }
   int findNeighbour(int otid) const
   {
      if (n[0]==otid) return 0;
      if (n[1]==otid) return 1;
      if (n[2]==otid) return 2;
      return -1;
   }
   int findOther(int p0, int p1) const
   {
      if (p[0]!=p0 && p[0]!=p1)
         return p[0];
      if (p[1]!=p0 && p[1]!=p1)
         return p[1];
      return p[2];
   }
   int oppositeTri(int pid) const
   {
      if (p[0]!=pid && p[1]!=pid)
         return n[0];
      if (p[1]!=pid && p[2]!=pid)
         return n[1];
      return n[2];
   }

   void setNeighbour(int p0, int p1, int nid)
   {
      if ( (p[0]==p0 && p[1]==p1) || (p[1]==p0 && p[0]==p1) )
         n[0] = nid;
      else if ( (p[1]==p0 && p[2]==p1) || (p[2]==p0 && p[1]==p1) )
         n[1] = nid;
      else if ( (p[2]==p0 && p[0]==p1) || (p[0]==p0 && p[2]==p1) )
         n[2] = nid;
      else
         printf("Could not find neighbour to set.\n");
   }
   #ifdef DBG_BALANCE
   void print(const char *name) const
   {
      printf("%s: %d %d %d\n",name, p[0], p[1], p[2]);
      printf("    %d %d %d\n", n[0], n[1], n[2]);
   }
   #endif
};
typedef std::vector<PNTri> PNTris;

#ifdef DBG_BALANCE
static void verifyTris(const PNTris &tris)
{
   size_t n = tris.size();
   for(int t=0;t<n;t++)
   {
      const PNTri &tri = tris[t];
      for(int nei=0;nei<3;nei++)
      {
         if (tri.n[nei]>0)
         {
            const PNTri &nt = tris[tri.n[nei]];
            int slot = nt.findNeighbour(t);
            if (slot<0)
            {
               printf("Tri %d has neighbour %d, but not reverse\n", t, tri.n[nei] );
               tri.print(" t0");
               nt.print("  t1");
               exit(-1);
            }
            int p0 = tri.p[nei];
            int p1 = tri.p[(nei+1)%3];
            int np0 = nt.p[slot];
            int np1 = nt.p[(slot+1)%3];
            if ( !( (p0==np0 && p1==np1) || (p0==np1 && p1==np0) ) )
            {
               printf(" points on edge do not match: %d-%d  %d-%d\n", p0,p1, np0,np1);
               exit(-1);
            }
         }
      }
   }
}
#endif

void balanceTris(PNTris &tris, const Vertices &p)
{
   int tcount = (int)tris.size();
   std::vector<bool> queued(tcount);
   std::vector<int> queue(tcount);
   for(int i=0;i<tcount; i++)
   {
      queue[i] = i;
      queued[i] = true;
   }

   #ifdef DBG_BALANCE
   printf("init...\n");
   verifyTris(tris);
   #endif

   int qs = tcount;
   while(qs)
   {
      int tid0 = queue[--qs];
      queued[tid0] = false;

      PNTri &t0 = tris[tid0];
      for(int n00=0;n00<3;n00++)
      {
         int tid1 = t0.n[n00];
         if (tid1>=0)
         {
            int n01 = (n00+1)%3;
            int n02 = (n00+2)%3;

            int a = t0.p[n00];
            int b = t0.p[n01];
            int c = t0.p[n02];

            PNTri &t1 = tris[tid1];
            int d = t1.findOther(a,b);

           /*
                 change t0|t1  to    t0
                                     --
                                     t1
                       t0.p[n00] = t1.p[n11 or n10]
                      A +
                Tac    /|\   Tad
                      / | \
                   C /  |  \ D
         t0.p[n02 ] /___|___\  t1.n[n12]
                    \   |   /
                     \  |  /  Tbd
               Tbc    \ | /
                       \|B
                       t0.p[n01] = t1.p[n10 or n11]

                */
            const UserPoint &A = p[a];
            const UserPoint &B = p[b];
            const UserPoint &C = p[c];
            const UserPoint &D = p[d];

            if ( A.Dist2(B) > C.Dist2(D) )
            {
               //Check to see if it is convex - are C&D on opposite side of AB
               // and A&B on opposite sized of CD
               UserPoint AB = B-A;
               UserPoint CD = D-C;
               // Different sign
               if ( (AB.Cross(C-A) * AB.Cross(D-A) < 0) &&
                    (CD.Cross(A-C) * CD.Cross(B-C) < 0)  )
               {
                  #ifdef DBG_BALANCE
                  printf("Flip tri[%d] / tri[%d] neighbour %d\n", tid0, tid1, n00 );
                  t0.print("  t0");
                  t1.print("  t1");
                  printf(" a=%d, b=%d, c=%d, d=%d\n", a,b,c,d );
                  #endif
                  // Triangle neighbours
                  int Tac = t0.n[n02];
                  int Tbc = t0.n[n01];
                  int Tad = t1.oppositeTri(b);
                  int Tbd = t1.oppositeTri(a);

                  // Change T0  to ADC
                  t0 = PNTri(a,d,c, Tad, tid1, Tac);

                  // Tad points to t0 instead now
                  if (Tad>=0)
                     tris[Tad].setNeighbour(a,d,tid0);

                  // Change T1 to CDB
                  t1 = PNTri(c,d,b, tid0, Tbd, Tbc );
                  // Tbc points to t1 instead now
                  if (Tbc>=0)
                     tris[Tbc].setNeighbour(b,c,tid1);


                  #ifdef DBG_BALANCE
                  verifyTris(tris);
                  #endif

                  queue[qs++] = tid0;
                  queued[tid0]=true;
                  if (!queued[tid1])
                  {
                     queue[qs++] = tid1;
                     queued[tid1]=true;
                  }

                  break;
               }
            }
         }
      }
   }
}

/*
void makePoly0ormals(PNTris &inTris, Vertices &inPoints, Vertices &outNormals)
{
   std::vector<float> edgeDist(inPoints.size);
   for(int i=0;i<edgeDist.size();i++)
      edgeDist[i] = 0.5;

   traceEdge
   offsetEdge(-1);
}
*/

typedef QuickVec<float> Normals;

class HardwareBuilder
{
public:
   HardwareBuilder(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareRenderer &inHardware, const RenderState &inState) : data(ioData)
   {
      mTexture = 0;

      bool tessellate_lines = true;
      bool tile_mode = false;
      bool alphaAA = true;

      memset(&mElement,0,sizeof(mElement));
      mElement.mWidth = -1;
      mElement.mColour = 0xffffffff;
      mElement.mVertexOffset = ioData.mArray.size();
      mElement.mStride = 2*sizeof(float);
      int align = 2*sizeof(float);

      mSolidMode = false;
      mPolyAA = false;
      mPerpLen = 0.5;
      mStateScale = data.scaleOf(inState);
      mScale = mStateScale;
      mTileScaleY = mTileScaleY = 1.0;
      if (mScale<=0.001)
         mScale = 0.001;
      mCurveThresh2 = 0.125/mScale/mScale;
      mWinding = inPath.winding;

      if (inJob.mIsTileJob)
      {
         mElement.mPrimType = ptTriangles;
         mElement.mScaleMode = ssmNormal;

         GraphicsBitmapFill *bmp = inJob.mFill->AsBitmapFill();
         mElement.mSurface = bmp->bitmapData->IncRef();

         mTexture = mElement.mSurface->GetTexture(&inHardware);
         if (bmp->smooth)
            mElement.mFlags |= DRAW_BMP_SMOOTH;
         tile_mode = true;
      }
      else if (inJob.mFill)
      {
         mSolidMode = true;
         mElement.mPrimType = inJob.mTriangles ? ptTriangles : ptTriangleFan;
         mElement.mScaleMode = ssmNormal;
         if (!SetFill(inJob.mFill,inHardware))
            return;

         if (inJob.mPolyAA && polyAaGeomOk(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]) )
         {
            mPolyAA = inJob.mPolyAA;
            mElement.mPrimType = ptTriangles;

            mCaps = scRound;
            mJoints = sjRound;
            mMiterLimit = 0.5;

            mElement.mWidth = 1.0/mScale;
            if (DEBUG_EXTRA_FAT)
               mElement.mWidth = 5.0/mScale;
            mPerpLen = mElement.mWidth*0.5;

         }
      }
      else if (tessellate_lines && inJob.mStroke->scaleMode==ssmNormal)
      {
         mElement.mPrimType = ptTriangles;
         GraphicsStroke *stroke = inJob.mStroke;
         mElement.mWidth = stroke->thickness;
         if (!SetFill(stroke->fill,inHardware))
            return;

         mPerpLen = stroke->thickness * 0.5;
         if (mPerpLen<=0.0)
         {
            mPerpLen = 0.5/mScale;
            mElement.mWidth = 1.0/mScale;
         }

         mCaps = stroke->caps;
         mJoints = stroke->joints;
         mMiterLimit = stroke->miterLimit*mPerpLen;

         if (mPerpLen<0.5/mScale)
         {
            int a = (mElement.mColour>>24)*mPerpLen*mScale/0.5;
            mElement.mColour = (mElement.mColour & 0x00ffffff) | (a<<24);
            mPerpLen = 0.5/mScale;
            mElement.mWidth = 1.0/mScale;
         }

         if (alphaAA)
         {
            mPerpLen += 0.5/mScale;
            mElement.mWidth += 1.0/mScale;
            mElement.mFlags |= DRAW_HAS_NORMAL;
            mElement.mNormalOffset = mElement.mVertexOffset + mElement.mStride;
            mElement.mStride += sizeof(float)*2;
         }
      }
      else
      {
         tessellate_lines = false;
         mElement.mPrimType = ptLineStrip;
         GraphicsStroke *stroke = inJob.mStroke;
         mElement.mScaleMode = stroke->scaleMode;
         mElement.mWidth = stroke->thickness;
         SetFill(stroke->fill,inHardware);
      }

      if (mElement.mSurface)
      {
         if (tile_mode && (inJob.mTileMode & pcTile_Full_Image_Bit) )
         {
            // No need for texture data itself
            mElement.mFlags |= DRAW_HAS_TEX;
         }
         else
         {
            mElement.mFlags |= DRAW_HAS_TEX;
            mElement.mTexOffset = mElement.mVertexOffset + mElement.mStride;
            mElement.mStride += 2*sizeof(float);
         }
      }

      if (inJob.mTriangles)
      {
         if (inJob.mTriangles->mType == vtVertexUVT && mElement.mSurface)
         {
            // Add z,w to position coordinates...
            mElement.mStride += 2*sizeof(float);
            mElement.mTexOffset += 2*sizeof(float);
            mElement.mFlags |= DRAW_HAS_PERSPECTIVE;
         }

         if (inJob.mTriangles->mColours.size())
         {
            mElement.mColourOffset = mElement.mVertexOffset + mElement.mStride;
            #ifdef NME_FLOAT32_VERT_VALUES
            mElement.mStride += sizeof(float)*4;
            #else
               #ifdef NME_METAL
               // Align...
               if (nmeOpenglRenderer)
                   mElement.mStride += sizeof(int);
               else
                   mElement.mStride += 2*sizeof(float);
               #else
               mElement.mStride += sizeof(int);
               #endif
            #endif
            mElement.mFlags |= DRAW_HAS_COLOUR;
            mElement.mColour = 0xffffffff;
         }

         mElement.mBlendMode =inJob.mTriangles->mBlendMode;

         AddTriangles(inJob.mTriangles);

         if (inJob.mStroke && inJob.mStroke->fill)
         {
            if (mElement.mSurface)
               mElement.mSurface->DecRef();
            memset(&mElement,0,sizeof(mElement));
            mElement.mColour = 0xffffffff;
            mElement.mVertexOffset = ioData.mArray.size();
            mElement.mStride = 2*sizeof(float);
            mElement.mScaleMode = ssmNormal;
            mElement.mWidth = inJob.mStroke->thickness;

            mElement.mPrimType = ptLines;
            GraphicsStroke *stroke = inJob.mStroke;
            if (!SetFill(stroke->fill,inHardware))
               return;

            if (mElement.mSurface)
            {
               mElement.mFlags |= DRAW_HAS_TEX;
               mElement.mTexOffset = mElement.mVertexOffset + mElement.mStride;
               mElement.mStride = 2*sizeof(float);
            }

            mElement.mWidth = stroke->thickness;
            AddTriangleLines(inJob.mTriangles);
         }
      }
      else if (tile_mode)
      {
         int tiles = inJob.mTileCount;
         int mode = inJob.mTileMode;

         if (tiles)
         {
            mElement.mBlendMode = inJob.mBlendMode;
            if (mode & pcTile_Col_Bit)
            {
               mElement.mColourOffset = mElement.mVertexOffset + mElement.mStride;
               #ifdef NME_FLOAT32_VERT_VALUES
               mElement.mStride += sizeof(float)*4;
               #else
                  #ifdef NME_METAL
                  // Align...
                  if (nmeOpenglRenderer)
                     mElement.mStride += sizeof(int);
                  else
                     mElement.mStride += 2*sizeof(float);
                  #else
                  mElement.mStride += sizeof(int);
                  #endif
               #endif
               //mElement.mStride += sizeof(int);
               mElement.mFlags |= DRAW_HAS_COLOUR;
               mElement.mColour = 0xffffffff;
            }

            mElement.mPrimType = (mode & pcTile_Full_Image_Bit) ? ptQuadsFull : ptQuads;
            ReserveArraysTight(tiles*4);

            if (mode & pcTile_Mouse_Enable_Bit)
               mElement.mFlags |= DRAW_TILE_MOUSE;

            if (mode & pcTile_Fixed_Size_Bit)
            {
               ioData.mMinScale = mStateScale*0.99;
               ioData.mMaxScale = mStateScale*1.01;
               const Matrix &m = *inState.mTransform.mMatrix;
               mTileScaleX = 1.0/sqrt( m.m00*m.m00 + m.m01*m.m01 );
               mTileScaleY = 1.0/sqrt( m.m10*m.m10 + m.m11*m.m11 );
            }

            AddTiles(mode, &inPath.data[inJob.mData0], tiles);
         }
      }
      else if (tessellate_lines && (!mSolidMode || mPolyAA) )
      {
         if (!AddLineTriangles(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0] ))
         {
            if (mPolyAA)
            {
               mPolyAA = false;
               mSolidMode = true;
               AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
            }
         }
      }
      else
      {
         AddObject(&inPath.commands[inJob.mCommand0], inJob.mCommandCount, &inPath.data[inJob.mData0]);
      }
   }

   void ReserveArraysTight(int inN)
   {
      mElement.mCount = inN;
      data.mArray.resize( mElement.mVertexOffset + mElement.mStride*inN );
   }


   void ReserveArrays(int inN)
   {
      mElement.mCount = inN;
      data.mArray.resizeSpace( mElement.mVertexOffset + mElement.mStride*inN );
   }


   bool SetFill(IGraphicsFill *inFill,HardwareRenderer &inHardware)
   {
      mGradFlags = 0;
      if (mElement.mSurface)
      {
         mElement.mSurface->DecRef();
         mElement.mSurface = 0;
      }

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
            mElement.mSurface = new SimpleSurface(w,1,pfBGRA);
            mElement.mSurface->IncRef();
            grad->FillArray( (ARGB *)mElement.mSurface->GetBase() );

            if (grad->spreadMethod!=smPad)
               mElement.mFlags |= DRAW_BMP_REPEAT;
            mElement.mFlags |= DRAW_BMP_SMOOTH;

            mTextureMapper = grad->matrix.Inverse();
            if (!grad->isLinear)
            {
               mElement.mFlags |= DRAW_RADIAL;
               if (grad->focalPointRatio!=0)
               {
                  int r = grad->focalPointRatio*10000.0;
                  if (r<-10000) r = -10000;
                  if (r>10000) r = 10000;
                  mElement.mRadialPos = r;
               }
            }
         }
         else
         {
            GraphicsBitmapFill *bmp = inFill->AsBitmapFill();
            mTextureMapper = bmp->matrix.Inverse();
            mElement.mSurface = bmp->bitmapData->IncRef();
            mTexture = mElement.mSurface->GetTexture(&inHardware);
            if (bmp->repeat)
               mElement.mFlags |= DRAW_BMP_REPEAT;
            if (bmp->smooth)
               mElement.mFlags |= DRAW_BMP_SMOOTH;
          }
       }
       //return false;
       return true;
   }

   ~HardwareBuilder()
   {
      if (mElement.mSurface)
         mElement.mSurface->DecRef();
   }

   void calcEdgeDist(UserPoint &p0, UserPoint &p1, UserPoint &p2,
                     float &d0, float &d1, float &d2 )
   {
      UserPoint perp = UserPoint( p1.y-p0.y, p0.x-p1.x ).Normalized();
      float dist = fabs((p2-p0).Dot(perp));

      /*
      d0 = 0;
      d1 = 0;
      d2 = dist;
      */
      d0 = 0;
      d1 = 0;
      d2 = p2.Dist( (p0+p1)*0.5 );
   }


   void calcEdgePointDist(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2,
                     float &d0, float &d1, float &d2 )
   {
      //UserPoint perp = UserPoint( p1.y-p0.y, p0.x-p1.x ).Normalized();
      //float dist = fabs( (p2-p0).Dot(perp) );
      //d0 = d1 = dist;

      d0 = p0.Dist(p2);
      d1 = p1.Dist(p2);
      d2 = 0;
   }

   void CalcNormalCoords(const std::vector<bool> &isOuter)
   {
      UserPoint *vertices = (UserPoint *)&data.mArray[ mElement.mVertexOffset ];
      UserPoint *norm = (UserPoint *)&data.mArray[ mElement.mNormalOffset ];

      int n = mElement.mCount/3;
      for(int i=0;i<mElement.mCount;i+=3)
      {
         UserPoint &p0 = *vertices; Next(vertices);
         UserPoint &p1 = *vertices; Next(vertices);
         UserPoint &p2 = *vertices; Next(vertices);

         bool e0 = isOuter[i];
         bool e1 = isOuter[i+1];
         bool e2 = isOuter[i+2];

         UserPoint norm0(1000,1000);
         UserPoint norm1(1000,1000);
         UserPoint norm2(1000,1000);

         // Only have x and y, so must choose edge to AA
         if (e0 && e1 && e2)
         {
            float l0 = p0.Dist2(p1);
            float l1 = p1.Dist2(p2);
            float l2 = p2.Dist2(p0);
            if (l0<=l1 && l0<=l2)
               e0 = false;
            else if (l1<l2)
               e1 = false;
            else
               e2 = false;
         }

         if (e0)
         {
            calcEdgeDist(p0, p1, p2, norm0.x, norm1.x, norm2.x);
            if (!e1 && !e2)
               calcEdgePointDist(p0, p1, p2, norm0.y, norm1.y, norm2.y);
         }

         if (e1)
         {
            if (e0)
               calcEdgeDist(p1, p2, p0, norm1.y, norm2.y, norm0.y);
            else
            {
               calcEdgeDist(p1, p2, p0, norm1.x, norm2.x, norm0.x);
               if (!e2)
                  calcEdgePointDist(p1, p2, p0, norm1.y, norm2.y, norm0.y);
            }
         }

         if (e2)
         {
            calcEdgeDist(p2, p0, p1, norm2.y, norm0.y, norm1.y);
            if (!e0 && !e1)
               calcEdgePointDist(p2, p0, p1, norm2.x, norm0.x, norm1.x);
         }

         *norm=norm0; Next(norm);
         *norm=norm1; Next(norm);
         *norm=norm2; Next(norm);
      }
   }

   void CalcTexCoords()
   {
      UserPoint *vertices = (UserPoint *)&data.mArray[ mElement.mVertexOffset ];
      UserPoint *tex = (UserPoint *)&data.mArray[ mElement.mTexOffset ];

      bool radial = mElement.mFlags &  DRAW_RADIAL;
      for(int i=0;i<mElement.mCount;i++)
      {
         UserPoint p = mTextureMapper.Apply(vertices->x,vertices->y);
         Next(vertices);

         if (mTexture)
         {
            p = mTexture->PixelToTex(p);
         }
         else
         {
            // The point will be in the (-819.2 ... 819.2) range...
            if (radial)
            {
               p.x = (p.x +819.2) / 819.2 - 1.0;
               p.y = (p.y +819.2) / 819.2 - 1.0;
               if (mGradReflect)
               {
                  p.x *= 0.5;
                  p.y *= 0.5;
               }

            }
            else
            {
               p.x = (p.x +819.2) / 1638.4;
               p.y = 0;
               if (mGradReflect)
                  p.x *= 0.5;
            }
         }
         *tex = p;
         Next(tex);
       }
   }

   template<typename T>
   void Next(T *&ptr)
   {
      ptr = (T *)( ((char *)ptr) + mElement.mStride );
   }


   void AddTriangles(GraphicsTrianglePath *inPath)
   {
      int n = inPath->mVertices.size();
      ReserveArrays(n);

      UserPoint *vertices = (UserPoint *)&data.mArray[ mElement.mVertexOffset ];
      #ifdef NME_FLOAT32_VERT_VALUES
      float *colours = (mElement.mFlags & DRAW_HAS_COLOUR) ? (float *)&data.mArray[ mElement.mColourOffset ] : 0;
      #else
      int *colours = (mElement.mFlags & DRAW_HAS_COLOUR) ? (int *)&data.mArray[ mElement.mColourOffset ] : 0;
      #endif
      UserPoint *tex = (mElement.mFlags & DRAW_HAS_TEX) ? (UserPoint *)&data.mArray[ mElement.mTexOffset ] : 0;
      bool persp = mElement.mFlags & DRAW_HAS_PERSPECTIVE;
      int stride = mElement.mStride;

      mElement.mPrimType = ptTriangles;

      const float *t = &inPath->mUVT[0];
      for(int v=0;v<n;v++)
      {
         if (!persp)
         {
            *vertices = inPath->mVertices[v];
            Next(vertices);
         }

         if(colours)
         {
            #ifdef NME_FLOAT32_VERT_VALUES
            colours[0] = ( (inPath->mColours[v]   ) & 0xff)/255.0;
            colours[1] = ( (inPath->mColours[v]>>8) & 0xff)/255.0;
            colours[2] = ( (inPath->mColours[v]>>16) & 0xff)/255.0;
            colours[3] = ( (inPath->mColours[v]>>24) & 0xff)/255.0;
            #else
            *colours = inPath->mColours[v];
            #endif
            Next(colours);
         }

         if (inPath->mType != vtVertex)
         {
            *tex = mTexture->TexToPaddedTex( UserPoint(t[0],t[1]) );
            Next(tex);

            t+=2;
            if (persp)
            {
               float w= 1.0/ *t++;
               vertices[0] = inPath->mVertices[v]*w;
               vertices[1] = UserPoint(0,w);
               Next(vertices);
            }
         }
      }

      mElement.mCount = n;

      PushElement();
   }


   void AddTriangleLines(GraphicsTrianglePath *inPath)
   {
      mElement.mPrimType = ptLines;

      int tri_count = inPath->mVertices.size()/3;
      ReserveArrays(tri_count*6);

      UserPoint *vertices = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      UserPoint *tri =  &inPath->mVertices[0];
      for(int v=0;v<tri_count;v++)
      {
         *vertices = tri[0];
         Next(vertices);
         *vertices = tri[1];
         Next(vertices);
         *vertices = tri[1];
         Next(vertices);
         *vertices = tri[2];
         Next(vertices);
         *vertices = tri[2];
         Next(vertices);
         *vertices = tri[0];
         Next(vertices);
         tri+=3;
      }

      if (mElement.mFlags & DRAW_HAS_TEX)
         CalcTexCoords();
      PushElement();
   }


   template<bool FULL, bool COL, bool TRANS, bool FIXED>
   void TTAddTiles(const float *inData, int inTiles)
   {
      UserPoint *vertices = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      UserPoint *tex = (mElement.mFlags & DRAW_HAS_TEX) && !FULL ? (UserPoint *)&data.mArray[ mElement.mTexOffset ] : 0;
      #ifdef NME_FLOAT32_VERT_VALUES
      UserPoint *colours = COL ? (UserPoint *)&data.mArray[ mElement.mColourOffset ] : 0;
      #else
      int *colours = COL ? (int *)&data.mArray[ mElement.mColourOffset ] : 0;
      #endif
      bool premultiplyAlpha = mElement.mSurface && IsPremultipliedAlpha(mElement.mSurface->Format());

      UserPoint *point = (UserPoint *)inData;

      UserPoint pos;
      UserPoint p1;
      UserPoint p2;
      UserPoint p3;

      UserPoint tex0(0,0);
      UserPoint tex1(1,1);
      UserPoint bmpSize(mTexture->GetWidth(),mTexture->GetHeight());
      if (bmpSize.x==0 || bmpSize.y==0)
         bmpSize = UserPoint(1,1);

      double texScaleX = 1.0/bmpSize.x;
      double texScaleY = 1.0/bmpSize.y;

      /*
        Opengl is very clear when it comes to how pixels & textures are sampled.
        The sampling is done at 1/2 pixel offsets, but there is still one case that causes issues.
        When you draw the tile exactly on the 1/2 pixel offset, the geometry uses some convention
         to decide whether to include the pixel or not.  By being consistent in its rounding direction,
         it ensures that if two tiles touch each other, all the pixels will be drawn one way
         or another. good. The problem is that in this case, the texture coords run exactly down the
         crack between the pixels.  In the nearest-neighbour case, opengl must decide which texel
         to render, using some convention.  However, sadly, this convention is not exactly the same as
         the geometry convention.  This means that a texel inconistent with the geometry can be rendered.

        To fix this we alter the tex-coords by 10-7 of a image, which means there is no "tie" in the
         texture sampling equation, and no convetion is required.
      */
      #define texTol  0.0000001f

      UserPoint tileSize = bmpSize;
      if (FIXED && FULL)
      {
         tileSize.x *= mTileScaleX;
         tileSize.y *= mTileScaleY;
      }

      for(int i=0;i<inTiles;i++)
      {
         if (FIXED)
         {
            UserPoint off = *point++;
            pos = *point++;
            pos.x -= off.x * mTileScaleX;
            pos.y -= off.y * mTileScaleY;
         }
         else
            pos = *point++;

         if (!FULL)
         {
            UserPoint tileOrigin = *point++;
            tileSize  = *point++;

            if (tileSize.x<0)
            {
               tex0.x = (tileOrigin.x ) * texScaleX - texTol;
               tex1.x = (tileOrigin.x + tileSize.x ) * texScaleX + texTol;
            }
            else
            {
               tex0.x = (tileOrigin.x ) * texScaleX + texTol;
               tex1.x = (tileOrigin.x + tileSize.x ) * texScaleX - texTol;
            }

            if (tileSize.y<0)
            {
               tex0.y = (tileOrigin.y ) * texScaleY - texTol;
               tex1.y = (tileOrigin.y + tileSize.y ) * texScaleY + texTol;
            }
            else
            {
               tex0.y = (tileOrigin.y ) * texScaleY + texTol;
               tex1.y = (tileOrigin.y + tileSize.y ) * texScaleY - texTol;
            }

            if (FIXED)
            {
               tileSize.x *= mTileScaleX;
               tileSize.y *= mTileScaleY;
            }
         }

         if (TRANS)
         {
            UserPoint trans_x = *point++;
            UserPoint trans_y = *point++;

            UserPoint p1(pos.x + tileSize.x*trans_x.x,
                         pos.y + tileSize.x*trans_x.y);
            UserPoint p2(pos.x + tileSize.x*trans_x.x + tileSize.y*trans_y.x,
                         pos.y + tileSize.x*trans_x.y + tileSize.y*trans_y.y );
            UserPoint p3(pos.x + tileSize.y*trans_y.x,
                         pos.y + tileSize.y*trans_y.y );

            *vertices = ( pos );
            Next(vertices);
            *vertices = ( p1 );
            Next(vertices);
            *vertices = ( p3 );
            Next(vertices);
            *vertices = ( p2 );
            Next(vertices);
         }
         else
         {
            UserPoint p1(pos.x + tileSize.x, pos.y + tileSize.y);

            *vertices = (pos);
            Next(vertices);
            *vertices = UserPoint(p1.x,pos.y);
            Next(vertices);
            *vertices = UserPoint(pos.x,p1.y);
            Next(vertices);
            *vertices = p1;
            Next(vertices);
         }


         if (!FULL)
         {
            *tex = tex0;
            Next(tex);
            *tex = UserPoint(tex1.x,tex0.y);
            Next(tex);
            *tex = UserPoint(tex0.x,tex1.y);
            Next(tex);
            *tex = tex1;
            Next(tex);
         }

         if (COL)
         {
            UserPoint rg = *point++;
            UserPoint ba = *point++;

            if (premultiplyAlpha)
            {
               rg.x *= ba.y;
               rg.y *= ba.y;
               ba.x *= ba.y;
            }
            #ifdef NME_FLOAT32_VERT_VALUES
               colours[0] = rg;
               colours[1] = ba;
               Next(colours);
               colours[0] = rg;
               colours[1] = ba;
               Next(colours);
               colours[0] = rg;
               colours[1] = ba;
               Next(colours);
               colours[0] = rg;
               colours[1] = ba;
               Next(colours);
            #else
               #ifdef BLACKBERRY
               uint32 col = ((int)(rg.x*255)) |
                            (((int)(rg.y*255))<<8) |
                            (((int)(ba.x*255))<<16) |
                            (((int)(ba.y*255))<<24);
               #else
               uint32 col = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))) |
                            ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
                            ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))<<16) |
                            ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
               #endif

               *colours = ( col );
               Next(colours);
               *colours = ( col );
               Next(colours);
               *colours = ( col );
               Next(colours);
               *colours = ( col );
               Next(colours);
            #endif
         }
      }
   }

   template<bool FULL, bool COL, bool TRANS>
   void TAddTiles(const float *inData, int inTiles,bool fixed)
   {
      if (fixed)
         TTAddTiles<FULL,COL,TRANS,true>(inData,inTiles);
      else
         TTAddTiles<FULL,COL,TRANS,false>(inData,inTiles);
   }



   template<bool FULL, bool COL, bool TRANS, bool FIXED>
   void TTAddTilesMt(const float *inData, int inTiles)
   {
      char *vertexPtr = (char *)&data.mArray[mElement.mVertexOffset];
      char *texPtr = (mElement.mFlags & DRAW_HAS_TEX) && !FULL ? (char *)&data.mArray[ mElement.mTexOffset ] : 0;
      char *colourPtr = COL ? (char *)&data.mArray[ mElement.mColourOffset ] : 0;

      bool premultiplyAlpha = mElement.mSurface && IsPremultipliedAlpha(mElement.mSurface->Format());

      UserPoint pos;
      UserPoint p1;
      UserPoint p2;
      UserPoint p3;

      UserPoint tex0(0,0);
      UserPoint tex1(1,1);
      UserPoint bmpSize(mTexture->GetWidth(),mTexture->GetHeight());
      if (bmpSize.x==0 || bmpSize.y==0)
         bmpSize = UserPoint(1,1);

      double texScaleX = 1.0/bmpSize.x;
      double texScaleY = 1.0/bmpSize.y;

      /*
        Opengl is very clear when it comes to how pixels & textures are sampled.
        The sampling is done at 1/2 pixel offsets, but there is still one case that causes issues.
        When you draw the tile exactly on the 1/2 pixel offset, the geometry uses some convention
         to decide whether to include the pixel or not.  By being consistent in its rounding direction,
         it ensures that if two tiles touch each other, all the pixels will be drawn one way
         or another. good. The problem is that in this case, the texture coords run exactly down the
         crack between the pixels.  In the nearest-neighbour case, opengl must decide which texel
         to render, using some convention.  However, sadly, this convention is not exactly the same as
         the geometry convention.  This means that a texel inconistent with the geometry can be rendered.

        To fix this we alter the tex-coords by 10-7 of a image, which means there is no "tie" in the
         texture sampling equation, and no convetion is required.
      */
      #define texTol  0.0000001f

      UserPoint tileSize = bmpSize;
      if (FIXED && FULL)
      {
         tileSize.x *= mTileScaleX;
         tileSize.y *= mTileScaleY;
      }

      int stride = mElement.mStride * 4;
      int srcPoints = 1;
      if (FIXED) srcPoints += 1;
      if (!FULL) srcPoints += 2;
      if (TRANS) srcPoints += 2;
      if (COL) srcPoints += 2;

      while(true)
      {
         int pid = GetNextTask();
         if (pid>=inTiles)
            break;

         UserPoint *point = ((UserPoint *)inData) + pid*srcPoints;

         if (FIXED)
         {
            UserPoint off = *point++;
            pos = *point++;
            pos.x -= off.x * mTileScaleX;
            pos.y -= off.y * mTileScaleY;
         }
         else
            pos = *point++;

         if (!FULL)
         {
            UserPoint tileOrigin = *point++;
            tileSize  = *point++;

            if (tileSize.x<0)
            {
               tex0.x = (tileOrigin.x ) * texScaleX - texTol;
               tex1.x = (tileOrigin.x + tileSize.x ) * texScaleX + texTol;
            }
            else
            {
               tex0.x = (tileOrigin.x ) * texScaleX + texTol;
               tex1.x = (tileOrigin.x + tileSize.x ) * texScaleX - texTol;
            }

            if (tileSize.y<0)
            {
               tex0.y = (tileOrigin.y ) * texScaleY - texTol;
               tex1.y = (tileOrigin.y + tileSize.y ) * texScaleY + texTol;
            }
            else
            {
               tex0.y = (tileOrigin.y ) * texScaleY + texTol;
               tex1.y = (tileOrigin.y + tileSize.y ) * texScaleY - texTol;
            }
            if (FIXED)
            {
               tileSize.x *= mTileScaleX;
               tileSize.y *= mTileScaleY;
            }
         }

         UserPoint *vertices = (UserPoint *)(vertexPtr + pid*stride);

         if (TRANS)
         {
            UserPoint trans_x = *point++;
            UserPoint trans_y = *point++;

            UserPoint p1(pos.x + tileSize.x*trans_x.x,
                         pos.y + tileSize.x*trans_x.y);
            UserPoint p2(pos.x + tileSize.x*trans_x.x + tileSize.y*trans_y.x,
                         pos.y + tileSize.x*trans_x.y + tileSize.y*trans_y.y );
            UserPoint p3(pos.x + tileSize.y*trans_y.x,
                         pos.y + tileSize.y*trans_y.y );


            *vertices = ( pos );
            Next(vertices);
            *vertices = ( p1 );
            Next(vertices);
            *vertices = ( p3 );
            Next(vertices);
            *vertices = ( p2 );
         }
         else
         {
            UserPoint p1(pos.x + tileSize.x, pos.y + tileSize.y);

            *vertices = (pos);
            Next(vertices);
            *vertices = UserPoint(p1.x,pos.y);
            Next(vertices);
            *vertices = UserPoint(pos.x,p1.y);
            Next(vertices);
            *vertices = p1;
         }


         if (!FULL)
         {
            UserPoint *tex = (UserPoint *)(texPtr + pid*stride);

            *tex = tex0;
            Next(tex);
            *tex = UserPoint(tex1.x,tex0.y);
            Next(tex);
            *tex = UserPoint(tex0.x,tex1.y);
            Next(tex);
            *tex = tex1;
         }

         if (COL)
         {
            UserPoint rg = *point++;
            UserPoint ba = *point++;

            if (premultiplyAlpha)
            {
               rg.x *= ba.y;
               rg.y *= ba.y;
               ba.x *= ba.y;
            }

            #ifdef BLACKBERRY
            uint32 col = ((int)(rg.x*255)) |
                         (((int)(rg.y*255))<<8) |
                         (((int)(ba.x*255))<<16) |
                         (((int)(ba.y*255))<<24);
            #else
            uint32 col = ((rg.x<0 ? 0 : rg.x>1?255 : (int)(rg.x*255))) |
                         ((rg.y<0 ? 0 : rg.y>1?255 : (int)(rg.y*255))<<8) |
                         ((ba.x<0 ? 0 : ba.x>1?255 : (int)(ba.x*255))<<16) |
                         ((ba.y<0 ? 0 : ba.y>1?255 : (int)(ba.y*255))<<24);
            #endif

            uint32 *colours = (uint32 *)(colourPtr + pid*stride);

            *colours = ( col );
            Next(colours);
            *colours = ( col );
            Next(colours);
            *colours = ( col );
            Next(colours);
            *colours = ( col );
         }
      }
   }

   template<bool FULL, bool COL, bool TRANS>
   void TAddTilesMt(const float *inData, int inTiles, bool fixed)
   {
      if (fixed)
         TTAddTilesMt<FULL,COL,TRANS,true>(inData,inTiles);
      else
         TTAddTilesMt<FULL,COL,TRANS,false>(inData,inTiles);
   }



   struct AddTileJob
   {
      AddTileJob(int inMode, const float *inData, int inTiles, HardwareBuilder *inBuilder) :
         mode(inMode), data(inData), tiles(inTiles), builder(inBuilder) { }

      int mode;
      const float *data;
      int tiles;
      HardwareBuilder *builder;
   };

   static void SAddTiles(int, void *inJob)
   {
      AddTileJob *job = (AddTileJob *)inJob;

      bool fullTile =  job->mode & pcTile_Full_Image_Bit;
      bool hasColour = job->mode & pcTile_Col_Bit;
      bool hasTrans =  job->mode & pcTile_Trans_Bit;
      bool fixed = job->mode & pcTile_Fixed_Size_Bit;

      const float *inData = job->data;
      int inTiles = job->tiles;
      HardwareBuilder *thiz = job->builder;

      if      (!fullTile && !hasColour && !hasTrans)
         thiz->TAddTilesMt<false,false,false>(inData, inTiles, fixed);
      else if (!fullTile && !hasColour && hasTrans)
         thiz->TAddTilesMt<false,false,true>(inData, inTiles, fixed);
      else if (!fullTile && hasColour && !hasTrans)
         thiz->TAddTilesMt<false,true,false>(inData, inTiles, fixed);
      else if (!fullTile && hasColour && hasTrans)
         thiz->TAddTilesMt<false,true,true>(inData, inTiles, fixed);
      else if (fullTile && !hasColour && !hasTrans)
         thiz->TAddTilesMt<true,false,false>(inData, inTiles, fixed);
      else if (fullTile && !hasColour && hasTrans)
         thiz->TAddTilesMt<true,false,true>(inData, inTiles, fixed);
      else if (fullTile && hasColour && !hasTrans)
         thiz->TAddTilesMt<true,true,false>(inData, inTiles, fixed);
      else if (fullTile && hasColour && hasTrans)
         thiz->TAddTilesMt<true,true,true>(inData, inTiles, fixed);
   }

   void AddTiles(int inMode, const float *inData, int inTiles)
   {
      if (inTiles>100 && nme::GetWorkerCount()>1)
      {
         AddTileJob job(inMode, inData, inTiles, this);

         RunWorkerTask(SAddTiles, &job);
      }
      else
      {
         bool fullTile =  inMode & pcTile_Full_Image_Bit;
         bool hasColour = inMode & pcTile_Col_Bit;
         bool hasTrans =  inMode & pcTile_Trans_Bit;
         bool isFixed =  inMode & pcTile_Fixed_Size_Bit;

         if      (!fullTile && !hasColour && !hasTrans)
            TAddTiles<false,false,false>(inData, inTiles, isFixed);
         else if (!fullTile && !hasColour && hasTrans)
            TAddTiles<false,false,true>(inData, inTiles, isFixed);
         else if (!fullTile && hasColour && !hasTrans)
            TAddTiles<false,true,false>(inData, inTiles, isFixed);
         else if (!fullTile && hasColour && hasTrans)
            TAddTiles<false,true,true>(inData, inTiles, isFixed);
         else if (fullTile && !hasColour && !hasTrans)
            TAddTiles<true,false,false>(inData, inTiles, isFixed);
         else if (fullTile && !hasColour && hasTrans)
            TAddTiles<true,false,true>(inData, inTiles, isFixed);
         else if (fullTile && hasColour && !hasTrans)
            TAddTiles<true,true,false>(inData, inTiles, isFixed);
         else if (fullTile && hasColour && hasTrans)
            TAddTiles<true,true,true>(inData, inTiles, isFixed);
      }

      mElement.mCount = inTiles*4;

      PushElement();
   }

   void PushElement()
   {
      if (mElement.mCount>0)
      {
         /*
         if (data.mElements.size()>0)
         {
            DrawElement &e = data.mElements.last();
            if (e.mFlags==mElement.mFlags &&
                (e.mPrimType==ptLines || e.mPrimType==ptTriangles || e.mPrimType==ptPoints) &&
                e.mPrimType==mElement.mPrimType &&
                e.mBlendMode==mElement.mBlendMode &&
                e.mRadialPos==mElement.mRadialPos &&
                e.mSurface==mElement.mSurface &&
                e.mColour==mElement.mColour &&
                e.mWidth==mElement.mWidth )
            {
               e.mCount += mElement.mCount;
               return;
            }
         }
         */
         data.mElements.push_back(mElement);
         if (mElement.mSurface)
            mElement.mSurface->IncRef();
      }
   }


   void PushVertices(const Vertices &inV)
   {
      ReserveArrays(inV.size());

      //printf("PushVertices %d\n", inV.size());

      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      for(int i=0;i<inV.size();i++)
      {
         *v = inV[i];
         Next(v);
      }

      if (mElement.mSurface)
         CalcTexCoords();

      PushElement();
   }

   void PushTris(PNTris &inTris, Vertices &inPoints)
   {
      int n = (int)inTris.size();
      ReserveArrays(n*3);

      //printf("PushVertices %d\n", inV.size());

      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      for(int i=0;i<n;i++)
      {
         const PNTri &tri = inTris[i];
         *v = inPoints[ tri.p[0] ]; Next(v);
         *v = inPoints[ tri.p[1] ]; Next(v);
         *v = inPoints[ tri.p[2] ]; Next(v);
      }

      if (mElement.mSurface)
         CalcTexCoords();

      PushElement();
   }

   void PushOutline(const Vertices &inV)
   {
      ReserveArrays(inV.size()+1);

      //printf("PushVertices %d\n", inV.size());

      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      for(int i=0;i<inV.size();i++)
      {
         *v = inV[i]; Next(v);
      }

      if (mElement.mSurface)
         CalcTexCoords();

      PushElement();

      data.mElements.last().mPrimType = ptLines;
   }


   void fanToTris(PNTris &outTris, int pointCount)
   {
      outTris.resize( pointCount-2 );
      int p0 = 0;
      int p1 = 1;

      int triLeft = -1;
      for(int i=2;i<pointCount;i++)
      {
         outTris[i-2] = PNTri(p0, p1, i,
                            i-3, -1, i+1<pointCount ? i-1 : -1);
         p1 = i;
      }
   }



   void PushTrisWireframe(const PNTris &tris, const Vertices &inV)
   {
      int n = (int)tris.size();
      if (mElement.mFlags & DRAW_HAS_NORMAL)
      {
         mElement.mFlags &= ~DRAW_HAS_NORMAL;
         mElement.mNormalOffset = 0;
         mElement.mStride -= sizeof(float)*2.0;
      }
      mElement.mWidth = 1;

      ReserveArrays(n*6);
      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];

      for(int i=0;i<n;i++)
      {
         const PNTri &tri = tris[i];
         *v = inV[ tri.p[0] ]; Next(v);
         *v = inV[ tri.p[1] ]; Next(v);
         *v = inV[ tri.p[1] ]; Next(v);
         *v = inV[ tri.p[2] ]; Next(v);
         *v = inV[ tri.p[2] ]; Next(v);
         *v = inV[ tri.p[0] ]; Next(v);
      }

      if (mElement.mSurface)
         CalcTexCoords();

      mElement.mPrimType = ptLines;

      PushElement();
   }

   void PushTriangleWireframe(const Vertices &inV,bool isFan)
   {
      int n = (int)inV.size();

      if (isFan)
      {
         int tris =  n-2;
         ReserveArrays( 2 + 4*tris );
         UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];

         UserPoint p0 = inV[0];
         UserPoint p1 = inV[1];
         *v = p0; Next(v);
         *v = p1; Next(v);

         for(int i=2;i<n;i++)
         {
            UserPoint p = inV[i];
            *v = p0; Next(v);
            *v = p; Next(v);
            *v = p1; Next(v);
            *v = p; Next(v);

            p1 = p;
         }
      }
      else
      {
         int tris = n/3;
         ReserveArrays(tris*6);
         UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];

         for(int i=0;i<inV.size();i+=3)
         {
            *v = inV[i]; Next(v);
            *v = inV[i+1]; Next(v);
            *v = inV[i+1]; Next(v);
            *v = inV[i+2]; Next(v);
            *v = inV[i+2]; Next(v);
            *v = inV[i]; Next(v);
         }
      }

      if (mElement.mSurface)
         CalcTexCoords();

      PushElement();

      data.mElements.last().mPrimType = ptLines;
      printf("ok\n");
   }

   void triListToTris(PNTris &outTris, Vertices &ioPoints)
   {
      size_t n = ioPoints.size();
      outTris.resize(n/3);

      std::map<int64,int> pidMap;
      std::map<int64,int> edgeMap;
      Vertices compact;
      compact.reserve( ioPoints.size()*2/3 + 2 );
      int ids = 0;
      for(int i=0; i<n; i+=3)
      {
         int tid = i/3;
         PNTri &tri = outTris[tid];
         for(int p=0;p<3;p++)
         {
            int64 key = *(const int64 *)&ioPoints[i+p];

            auto it = pidMap.find(key);
            if (it!=pidMap.end())
               tri.p[p] = it->second;
            else
            {
               compact.push_back( ioPoints[i+p] );
               int id = ids++;
               tri.p[p] = id;
               pidMap[key] = id;
            }
         }

         for(int n=0;n<3;n++)
         {
            union
            {
               int edgePoint[2];
               int64 key;
            };
            edgePoint[0] = tri.p[n];
            edgePoint[1] = tri.p[ (n+1)%3 ];
            if (edgePoint[1]<edgePoint[0])
               std::swap(edgePoint[0],edgePoint[1]);
            auto it = edgeMap.find(key);
            if (it!=edgeMap.end())
            {
               int code = it->second;
               int nid = code & 3;
               int oid = code >> 2;
               outTris[oid].n[nid] = tid;
               tri.n[n] = oid;
            }
            else
               edgeMap[key] = (tid<<2) | n;
         }
      }
      std::swap(ioPoints, compact );
   }


   #define FLAT 0.000001
   bool AddPolygon(Vertices &ioOutline,const QuickVec<int> &inSubPolys, bool requireClean = false)
   {
      bool showTriangles = false;

      bool solid = mSolidMode || mPolyAA;
      if (solid && ioOutline.size()<3)
         return true;

      bool isConvex = inSubPolys.size()==1;
      if (solid)
      {
         if (isConvex)
         {
            UserPoint base = ioOutline[0];
            int last = ioOutline.size()-2;
            int i = 0;
            bool positive = true;
            for( ;i<last;i++)
            {
               UserPoint v0 = ioOutline[i+1]-base;
               UserPoint v1 = ioOutline[i+2]-base;
               double diff = v0.Cross(v1);
               if (fabs(diff)>FLAT)
               {
                  positive = diff > 0;
                  break;
               }
            }

            for(++i;i<last;i++)
            {
               UserPoint v0 = ioOutline[i+1]-base;
               UserPoint v1 = ioOutline[i+2]-base;
               double diff = v0.Cross(v1);
               if (fabs(diff)>FLAT && (diff>0)!=positive)
               {
                  isConvex = false;
                  break;
               }
            }
         }
         if (!isConvex)
         {
            bool good = ConvertOutlineToTriangles(ioOutline,inSubPolys,mWinding);
            if (requireClean && !good)
               return false;
            //showTriangles = true;
         }
      }
      if (solid && ioOutline.size()<3)
         return true;


      mElement.mVertexOffset = data.mArray.size();
      if (mElement.mSurface)
         mElement.mTexOffset = mElement.mVertexOffset + 2*sizeof(float);

      bool fan = isConvex;
      if (showTriangles)
      {
         PushTriangleWireframe(ioOutline, fan);
         //PushOutline(ioOutline);
      }
      else
      {
         if (!fan)
            mElement.mPrimType = ptTriangles;
         PushVertices(ioOutline);
      }
      return true;
   }


  void AddObject(const uint8* inCommands, int inCount, const float *inData)
  {
      UserPoint *point = (UserPoint *)inData;
      UserPoint last_move;
      UserPoint last_point;
      int points = 0;
      QuickVec<int> sub_poly_start;
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
               if (len!=0)
               {
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
                  points++;
               }
               point += 2;
               }
               break;


            case pcCubicTo:
               {
               double len = ((last_point-point[0]).Norm() + (point[1]-point[0]).Norm() + (point[2]-point[1]).Norm()) * 0.25;
               if (len!=0)
               {
                  int steps = (int)len;
                  if (steps<3) steps = 3;
                  if (steps>100) steps = 100;
                  double step = 1.0/(steps+1);
                  double t = 0;
                  for(int s=0;s<steps;s++)
                  {
                     t+=step;
                     double t_ = 1.0-t;
                     UserPoint p = last_point * (t_ * t_ * t_) + point[0] * (3.0 * t * t_ * t_) + point[1] * (3.0 * t * t * t_) + point[2] * (t*t*t);
                     if (outline.last()!=p)
                        outline.push_back(p);
                  }
                  last_point = point[2];
                  if (outline.last()!=last_point)
                      outline.push_back(last_point);
                  points++;
               }
               point += 3;
               }
               break;

            default:
               points += gCommandDataSize[ inCommands[i] ];
         }
      }

      int n = outline.size();
      if (n>1)
      {
         if (sub_poly_start.empty() || sub_poly_start.last()!=n)
            sub_poly_start.push_back(n);
         AddPolygon(outline,sub_poly_start);
      }
   }

   struct Segment
   {
      inline Segment() { }
      inline Segment(const UserPoint &inP) : p(inP), curve0(inP), curve1(inP) { }
      inline Segment(const UserPoint &inP,const UserPoint &inCurve) : p(inP), curve0(inCurve), curve1(inCurve) { }
      inline Segment(const UserPoint &inP,const UserPoint &inCurve1, const UserPoint &inCurve0) : p(inP), curve0(inCurve0), curve1(inCurve1) { }

      UserPoint getDir0(const UserPoint &inP0) const
      {
         return curve0-inP0;
      }
      UserPoint getDir1(const UserPoint &inP0) const
      {
         if (isCurve())
            return p-curve1;
         return p-inP0;
      }
      UserPoint getDirAverage(const UserPoint &inP0) const { return p-inP0; }

      inline bool isCurve() const { return p!=curve1; }
      inline bool isCurve2() const { return curve0!=curve1; }

      UserPoint p;
      UserPoint curve0;
      UserPoint curve1;
   };

   void AddArc(Curves &outCurve, UserPoint inP, double angle, UserPoint inVx, UserPoint inVy, float t)
   {
      int steps = 1 + mPerpLen*mScale*angle*3;
      if (steps>60)
         steps = 60;
      else if (steps<3)
         steps = 3;
      double d_theta = angle / (steps+1);
      double theta = d_theta;
      for(int i=1;i<steps;i++)
      {
         UserPoint x = inP + inVx*cos(theta) + inVy*sin(theta);
         outCurve.push_back( CurveEdge(x,t) );
         t+= 1.0/steps;
         theta += d_theta;
      }
   }

   void AddMiter(Curves &outCurves, UserPoint inP, UserPoint p0, UserPoint p1, double inAlpha,
                UserPoint dir1, UserPoint dir2, float t)
   {
       if (inAlpha>mMiterLimit)
       {
          UserPoint corner0 = p0+dir1*mMiterLimit;
          UserPoint corner1 = p1-dir2*mMiterLimit;
          outCurves.push_back( CurveEdge(corner0, t+0.33) );
          outCurves.push_back( CurveEdge(corner1, t+0.66) );
       }
       else
       {
          UserPoint corner0 = p0+dir1*inAlpha;
          UserPoint corner1 = p1-dir2*inAlpha;
          UserPoint diff = corner1-corner0;
          outCurves.push_back( CurveEdge(corner1, t+0.501) );
       }
   }

   void cleanCurve(Curves &curve,bool isClosed,double inSide)
   {
      bool debug = false;
      double oT = curve[ curve.size()-1 ].t + 1;

      float mergeThresh = mPerpLen * 0.001;
      mergeThresh *= mergeThresh;
      int dest = 0;
      for(int i=0;i<curve.size();i++)
      {
         int mergeCount = 0;
         for(int j=i+1; j<curve.size(); j++)
            if ( curve[i].p.Dist2(curve[j].p) < mergeThresh )
               mergeCount++;
            else
               break;
         curve[dest] = curve[i];
         if (mergeCount>0)
         {
            curve[dest].t = (curve[i].t + curve[i+mergeCount].t) * 0.5;
            i+=mergeCount;
         }
         dest++;
      }
      curve.resize(dest);

      if (DEBUG_KEEP_LOOPS)
      {
         int n  = (int)curve.size();
         if (isClosed && curve[0].p != curve[n-1].p)
            curve.push_back(curve[0]);
         return;
      }


      int osize = (int)curve.size();
      //const bool dbgPrint = false;
      const bool dbgPrint = DEBUG_PRINT_THRESH>0 && curve.size()>DEBUG_PRINT_THRESH;
      if (dbgPrint)
         printf("Clear Curve - %d\n", osize);

      //double perp2 = mPerpLen*2.0;
      int lastStart = isClosed ? 0 : -3;
      for(int startPoint=0; startPoint<curve.size()+lastStart && curve.size()>2;startPoint++)
      {
         // Get line segment ....... startPoint, startPoint+1:   p0 - p1
         const UserPoint &p0 = curve[startPoint].p;
         int startNext = (startPoint+1) % curve.size();
         UserPoint &p1 = curve[startNext].p;

         UserPoint dir0 = p1-p0;
         // Should already be cleaned, but maybe very close insertions
         double len = dir0.Norm();
         if ( len<0.000001 )
         {
            if (dbgPrint)
               printf("remove dupe %d/%d : %d\n", startPoint,startNext, (int)curve.size() );
            curve.erase(std::max(startPoint,startNext),1);
            startPoint--;
            continue;
         }

         // Stop searching for intersections earlier for fat lines, where we prefer overlap to missing parts
         double allowDeviation = mPolyAA ? 4.0 : 2.0;
         UserPoint onSideDist = dir0.Perp(-inSide/(mPerpLen*allowDeviation) );

         // Next segment can't intersect with first segment since it shared end
         int prevSlot = (startPoint+2) % curve.size();
         UserPoint prevPoint = curve[prevSlot].p;
         // Should already be cleaned, but maybe very close insertions
         if ( (prevPoint-p1).Norm()<0.0001 )
         {
            if (dbgPrint)
               printf("remove dupe1 %d\n", startNext );
            curve.erase(std::max(startNext,prevSlot),1);
            startPoint--;
            continue;
         }

         /*
         if (dbgPrint)
            printf("%d| curl0\n", prevSlot);
         // If point is on "correct" side of line, we are done
         if ( side<0 )
            continue;
         */

         float side = onSideDist.Dot( prevPoint-p0 );
         bool prevOnOddSide = side<0;
         if ( side>1 )
         {
            //if (dbgPrint)
            //   printf(" %d] stop early side %f\n", startPoint, side);
            continue;
         }

         // Check all the points downstream, possibly including the closing segment from end to beginning
         int stopOffset = isClosed ? curve.size() : -1;
         int advance = 0;
         for(int t = startPoint+3; t<curve.size() + stopOffset; t++)
         {
            int testPoint = t%curve.size(); 
            if (testPoint==startPoint)
            {
               if (dbgPrint)
                  printf(" %d] loopback done %d\n", startPoint, advance);
               break;
            }

            const UserPoint &p = curve[testPoint].p;
            const UserPoint &dp = p-p0;
            float side = onSideDist.Dot( dp );

            // Original criteria - test before intersection test
            //  Distance from testPoint to line-segment l1-p
            //    testPoint = p + alpha * dp
            //if (!mPolyAA && fabs(side)>1)
               //break;


            bool currentOnOddSide = side<0;
            advance++;
            //if (advance<5)
            //   printf("  %d-%d i %d-%d, side0=%d, sid1=%f -> %d\n", startPoint, startNext, prevSlot,testPoint, prevOnOddSide, side,  currentOnOddSide );

            if (prevOnOddSide != currentOnOddSide)
            {
               const UserPoint dir = p-prevPoint;
               // prevPoint -> p crosses the p0->p1 line

               // Solve p0.x + a dir0.x = prevPoint.x + b dir.x
               //       p0.y + a dir0.y = prevPoint.y + b dir.y

               // Solve p0.x*dir0.y + a dir0.x*dir0.y = prevPoint.x*dir0.y + b dir.x*dir0.y
               //       p0.y*dir0.x + a dir0.y*dir0.x = prevPoint.y*dir0.x + b dir.y*dir0.x
               //    p0 x dir0 - prevPoint x dir0 = b dir x dir0
               //    (p0-prevPoint) x dir0 = b dir x dir0
               double denom = dir.Cross(dir0);
               if (denom!=0.0)
               {
                  double b = (p0-prevPoint).Cross(dir0)/denom;
                  if (b>=0 && b<=1.0)
                  {
                     double a =  (fabs(dir0.x) > fabs(dir0.y)) ? (prevPoint.x + b*dir.x - p0.x)/dir0.x :
                                                             (prevPoint.y + b*dir.y - p0.y)/dir0.y;
                     //if (a>=0 && a<=1) equals case?
                     if ( (a!=1 && a!=0) || (b!=1 && b!=0) )
                     {
                        if (a>=0 && a<=1)
                        {
                           if (dbgPrint)
                              printf("Intersect %f %f  %d-%d  x  %d-%d\n", a, b, startPoint, startNext, prevSlot, testPoint );
                           UserPoint p = p0 + dir0*a;

                           // Calculate loop-sense ...
                           double sense = 0.0;
                           int end = testPoint;
                           UserPoint prev = p1 - p;
                           // Loop p , startNext, startNext+1, startNext+1, ... prevSlot, p |  testPoint
                           for(int i=startNext+1; i!=testPoint; i=(i+1)%curve.size() )
                           {
                              UserPoint v = curve[i].p - p;
                              sense += prev.Cross(v);
                              prev = v;
                           }

                           // figure-8 - more than one island of correctly oriented edges
                           if (dbgPrint)
                              printf(" sense: %f\n", sense);
                           if (sense*inSide>0.00001)
                           {
                              if (dbgPrint)
                                  printf(" keep sub loop\n");
                              break;
                           }

                           if (testPoint<startPoint)
                           {
                              if (dbgPrint)
                                 printf("  snip wrap around\n");
                              if (startNext == 0)
                              {
                                 if (dbgPrint)
                                    printf("  snip start\n");
                                 // Remove the loop up to testPoint, and replace testPoint with intersection
                                 //   c[startNext]
                                 //   ...
                                 //   c[prevSlot]
                                 //   c[testPoint]  <- p
                                 //   ...
                                 //   c[startPoint]
                                 // erase between 0 and testPoint
                                 curve[testPoint].p = p;
                                 curve[testPoint].t = curve[0].t;
                                 curve.EraseAt(0, testPoint);
                                 // Done
                              }
                              else if (testPoint==0)
                              {
                                 if (dbgPrint)
                                    printf("  snip end %d -> %d\n", (int)curve.size(), startNext+1);
                                 // Remove the loop 
                                 //   c[testPoint]
                                 //   ...
                                 //   c[startPoint]
                                 //   c[startNext] <- p
                                 //   ...
                                 //   ...
                                 curve[startNext].p = p;
                                 //curve[startNext].t = curve[0].t;
                                 curve.resize(startNext+1);

                              }
                              else if (testPoint<startPoint)
                              {
                                 // Replace prevSlot with intersection and delete points up to p
                                 if (dbgPrint)
                                    printf("  snip end wrap prevSlot=%d, testPoint=%d, startNext=%d, size=%d\n", prevSlot, testPoint, startNext, (int)curve.size() );
                                 // Remove the loop 
                                 //   c[0]
                                 //   ...
                                 //   c[prevSlot]  <- p
                                 //   c[testPoint]
                                 //   ...
                                 //   c[startPoint]
                                 //       -> wrap around to p
                                 //   c[startNext]
                                 //   ...
                                 // 
                                 curve[prevSlot].p = p;
                                 curve[prevSlot].t = curve[0].t;
                                 // New closing end point
                                 oT = curve[startNext].t;
                                 // Delete startNext onwards
                                 curve.resize(startNext);
                                 // Remove up to prevSlot
                                 if (prevSlot)
                                    curve.EraseAt(0,prevSlot);
                                 startPoint-= prevSlot;
                                 startPoint--;
                              }
                              else
                              {
                                 if (dbgPrint)
                                    printf("  snip in middle\n");
                                 // Remove the loop  - set first point to intersection, delete startNext onwards
                                 //   c[testPoint]  <- p
                                 //   ...
                                 //   c[startPoint]
                                 //   c[startNext]
                                 //   ...
                                 //   c[prevSlot]
                                 curve[testPoint].p = p;
                                 oT = curve[startNext].t;
                                 curve.EraseAt(startNext,curve.size());
                                 startPoint--;
                              }
                           }
                           else
                           {
                              if (dbgPrint)
                                 printf("  snip normal at %d\n", advance);
                              // Remove the loop 
                              //   c[startPoint]
                              //   c[startNext]
                              //    ...
                              //    c[prevSlot] <- p
                              //    c[testPoint]
                              //    ...
                              curve[prevSlot].p = p;
                              if (dbgPrint)
                                 printf("  replace %d -> %f,%f\n", prevSlot, p.x, p.y );
                              curve[prevSlot].t = curve[ (startNext+prevSlot) >> 1].t;
                              if (dbgPrint)
                                 printf("  erase %d...%d\n", startNext, testPoint );
                              curve.EraseAt(startNext,prevSlot);
                              // will get incremented
                              startPoint -=1;
                              if (startPoint<-1) startPoint = -1;
                           }
                           // Go back to start point
                           prevSlot = -1;
                           break;
                        }
                     }
                  }
               }
            }
            // Point is outside the onSideDist - stop
            // Don't care about overlap so much in non-mPolyAA case
            //if (fabs(side)>1 )
            if (side>1 || (!mPolyAA && side<-1) )
            {
               //if (dbgPrint)
               //   printf(" %d] side @ %d %f\n", startPoint, advance, side);
               break;
            }

            prevOnOddSide = currentOnOddSide;
            prevSlot = testPoint;
            prevPoint = p;
         }
      }

      if (isClosed && curve.size()>1 && curve[ curve.size()-1].p != curve[0].p)
         curve.push_back( CurveEdge( curve[0].p, oT) );

      if (dbgPrint)
      {
         printf("new curve %d %f:\n", osize, inSide);
         if (DEBUG_PRINT_VERBOSE)
         {
            for(int i=0; i<curve.size(); i++)
               printf(" %d] %f,%f  %f\n",  i, curve[i].p.x, curve[i].p.y, curve[i].t );
         }
      }
   }


   void AddCurveSegment(Curves &leftCurve, Curves &rightCurve,
                        UserPoint perp0, UserPoint perp1,
                        UserPoint inP0,UserPoint inP1,UserPoint inP2,
                        UserPoint p0_left, UserPoint p0_right,UserPoint p1_left, UserPoint p1_right, float t0)
   {

      QuickVec<Range> stack;
      Range r0(0,inP0-perp0, inP0+perp0, 1,inP2-perp1, inP2+perp1);
      stack.push_back(r0);

      while(stack.size())
      {
         Range r = stack.qpop();
         if (r.t1-r.t0 > 0.001 )
         {
            // Calc midpoint...
            double t = (r.t0+r.t1)*0.5;
            double t_ = 1.0 - t;
            UserPoint mid_p = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
            UserPoint dir = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t);
            UserPoint mid_l = mid_p - dir.Perp(mPerpLen);
            UserPoint mid_r = mid_p + dir.Perp(mPerpLen);

            UserPoint average_l = (r.left0+r.left1)*0.5;
            UserPoint average_r = (r.right0+r.right1)*0.5;
            if ( mid_l.Dist2(average_l)>mCurveThresh2 || mid_r.Dist2(average_r)>mCurveThresh2)
            {
               // Reverse order, LIFO
               stack.push_back( Range(t,mid_l,mid_r, r.t1,r.left1,r.right1) );
               r.t1 = t;
               r.left1 = mid_l;
               r.right1 = mid_r;
               stack.push_back(r);
               continue;
            }
            // Too much curvature?
            // dir = pert @ mid_t
            /*
            t+=0.001;
            t_ = 1.0 - t;
            UserPoint p_plus = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
            UserPoint perp_plus = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t).Perp(mPerpLen);

            if (r.t0==0.0 || (mid_p-p_plus).Dot(mid_l-(p_plus-perp_plus)) > 0)
               leftCurve.push_back( CurveEdge(r.left0,r.t0+t0) );

            if ( (mid_p-p_plus).Dot(mid_r-(p_plus+perp_plus)) > 0)
               rightCurve.push_back( CurveEdge(r.right0,r.t0+t0) );

            continue;
            */
         }
         leftCurve.push_back( CurveEdge(r.left0,r.t0+t0) );
         rightCurve.push_back( CurveEdge(r.right0,r.t0+t0) );
      }
      leftCurve.push_back( CurveEdge(inP2-perp1,0.9999+t0) );
      rightCurve.push_back( CurveEdge(inP2+perp1,0.9999+t0) );
   }


   void AddCubicSegment(Curves &leftCurve, Curves &rightCurve,
                        UserPoint perp0, UserPoint perp1,
                        UserPoint inP0,UserPoint inP1,UserPoint inP2,UserPoint inP3,
                        UserPoint p0_left, UserPoint p0_right,UserPoint p1_left, UserPoint p1_right, float t0)
   {
      QuickVec<Range> stack;
      Range r0(0,inP0-perp0, inP0+perp0, 1,inP3-perp1, inP3+perp1);
      stack.push_back(r0);

      while(stack.size())
      {
         Range r = stack.qpop();
         if (r.t1-r.t0 > 0.001 )
         {
            // Calc midpoint...
            double t = (r.t0+r.t1)*0.5;
            double t_ = 1.0 - t;
            UserPoint mid_p = inP0 * (t_ * t_ * t_) + inP1 * (3.0 * t * t_ * t_) + inP2 * (3.0 * t * t * t_) + inP3 * (t*t*t);
            UserPoint dir = inP0*(2*t-1-t*t) + inP1*(1-4*t+3*t*t) + inP2*(2*t-3*t*t)  + inP3*(t*t);

            UserPoint mid_l = mid_p - dir.Perp(mPerpLen);
            UserPoint mid_r = mid_p + dir.Perp(mPerpLen);

            UserPoint average_l = (r.left0+r.left1)*0.5;
            UserPoint average_r = (r.right0+r.right1)*0.5;
            if ( mid_l.Dist2(average_l)>mCurveThresh2 || mid_r.Dist2(average_r)>mCurveThresh2)
            {
               // Reverse order, LIFO
               stack.push_back( Range(t,mid_l,mid_r, r.t1,r.left1,r.right1) );
               r.t1 = t;
               r.left1 = mid_l;
               r.right1 = mid_r;
               stack.push_back(r);
               continue;
            }
         }
         leftCurve.push_back( CurveEdge(r.left0,r.t0+t0) );
         rightCurve.push_back( CurveEdge(r.right0,r.t0+t0) );
      }
      leftCurve.push_back( CurveEdge(inP3-perp1,0.9999+t0) );
      rightCurve.push_back( CurveEdge(inP3+perp1,0.9999+t0) );
   }



   void EndCap(Curves &left, Curves &right, UserPoint p0, UserPoint perp, double t)
   {
      bool first = t==0;

      UserPoint back(-perp.y, perp.x);
      if (!first)
      {
         back.x*=-1;
         back.y*=-1;
      }

      if (mCaps==scSquare)
      {
         if (first)
         {
            left.push_back(CurveEdge(p0+back-perp,t));
            right.push_back(CurveEdge(p0+back+perp,t));
         }
         else
         {
            left.push_back(CurveEdge(p0+back-perp,t));
            right.push_back(CurveEdge(p0+back+perp,t));
         }
      }
      else
      {
         int n = std::max(2,(int)(mPerpLen*mScale * 4));
         double dtheta = M_PI*0.5 / n;

         for(int i=1;i<n;i++)
         {
            double theta = (first ? n-i : i) * dtheta;
            left.push_back(CurveEdge(p0 - perp*cos(theta) + back*sin(theta),t)  );
            right.push_back(CurveEdge(p0 + perp*cos(theta) + back*sin(theta),t)  );
            t+= 0.0001;
         }
      }
   }

   void ComputeDistInfo(const UserPoint &otherSide, const UserPoint &prev, const UserPoint &p,
                          UserPoint &outSideInfo, UserPoint &outInfo, double inSign)
   {
       /*

        prev                 p
   ^     +------------------+   
   |     +-----------------/+   +Feather zone
   |     |                /  
   |     |            _/
   h     |- - - - - /  Zero line
   |     |       /
   |     |    /
   |     |--
   v     |.   -Feather Zone
        otherSide

        h = perpendicular height

       */

      if (mPolyAA)
      {
         // inSign 1 -> 1, inSign -1 -> 0
         // Shader uses: x - abs(y)
         outSideInfo = UserPoint(1, 0.5+inSign*0.5);
         outInfo = UserPoint(1, 0.5-inSign*0.5);
      }
      else
      {
         // Use simplified version to ensure values on edges of triangles match
         float h = mElement.mWidth*mScale*0.5f;
         outSideInfo = UserPoint(h, inSign*h);
         outInfo = UserPoint(h, -inSign*h);
      }

      //float lastLen = outSideInfo.x;
      /*
      float h = fabs( (p-otherSide).Dot( (p-prev).Perp(1.0) ) );
      h *= mScale * 0.5;
      if (h<mElement.mWidth)
         h = mElement.mWidth;
      // Shader uses: x - abs(y)
      outSideInfo = UserPoint(h, inSign*h);
      outInfo = UserPoint(h, -inSign*h);
      */
   }

   bool AddStrip(const QuickVec<Segment> &inPath, bool isClosed)
   {
      if (inPath.size()<2)
         return true;

      Curves leftCurve;
      Curves rightCurve;

      pathToCurves(inPath, isClosed, leftCurve, rightCurve);

      if (leftCurve.size()<1 || rightCurve.size()<1)
         return true;
      if (leftCurve.size()<3 && rightCurve.size()<3)
         return true;

      if (mPolyAA)
      {
         float lx = leftCurve[0].p.x;
         for(int i=1;i<leftCurve.size();i++)
            lx = std::min(lx,leftCurve[i].p.x);
         float rx = rightCurve[0].p.x;
         for(int i=1;i<rightCurve.size();i++)
            rx = std::min(rx,rightCurve[i].p.x);

         int interiorVertexOffset = mElement.mVertexOffset;

         // Right = outer, left=inner
         Curves &inner = rx<lx ? leftCurve : rightCurve;
         if (inner.size()>1 && !DEBUG_FAT_LINES && !DEBUG_NO_INTERIOR )
         {
            Vertices outline(inner.size());
            for(int i=0; i<inner.size(); i++)
               outline[i] = inner[i].p;

            QuickVec<int> subs(1);
            subs[0] = (int)outline.size();

            mElement.mPrimType = ptTriangleFan;
            mElement.mScaleMode = ssmNormal;
            bool isGood = AddPolygon(outline, subs, true);
            if (!isGood)
            {
               // Nibbled off too much and the interior could not be triangulated
               //  (potentially an issue with cleanCurve too)
               //  Fallback to normal solid
               // In debug mode, predend we rendered it
               return DEBUG_NO_FAT_FALLBACK;
            }
         }

         // Exterior finge
         int extra =  data.mArray.size() - interiorVertexOffset;
         mElement.mVertexOffset += extra;
         if (mElement.mTexOffset)
            mElement.mTexOffset += extra;
         if (mElement.mColourOffset)
            mElement.mColourOffset += extra;

         // Add normal flag
         mElement.mFlags |= DRAW_HAS_NORMAL;
         mElement.mNormalOffset = mElement.mVertexOffset + mElement.mStride;
         mElement.mStride += sizeof(float)*2;

         // Right = outer
         if (rx<lx)
            curvesToElement(rightCurve, leftCurve );
         else
            curvesToElement(leftCurve, rightCurve);

         // Remove normal flag
         mElement.mFlags &= ~DRAW_HAS_NORMAL;
         mElement.mNormalOffset = 0;
         mElement.mStride -= sizeof(float)*2;
      }
      else
      {
         curvesToElement(leftCurve, rightCurve);
      }
      return true;
   }


   void pathToCurves(const QuickVec<Segment> &inPath, bool isClosed, Curves &leftCurve, Curves &rightCurve)
   {
      if (inPath.size()<2)
         return;


      // Allow shrinking to half the size
      // Desable to allow debug by zooming in
      if (!DEBUG_UNSCALED)
      {
         //hack
         float s = mStateScale * 0.7;
         if (data.mMinScale==0 || s>data.mMinScale)
            data.mMinScale = s;

         // And growing to 1.41 the size ...
         s = mStateScale * 1.41;
         if (data.mMaxScale==0 || s<data.mMaxScale)
            data.mMaxScale = s;
      }


      float t = 0.0;

      // Endcap 0 ...
      if (!isClosed)
      {
         if (mCaps==scSquare || mCaps==scRound)
         {
            UserPoint p0 = inPath[0].p;
            EndCap(leftCurve, rightCurve, p0, inPath[1].getDir0(p0).Perp(mPerpLen),t);
         }
      }
      t+=1.0;

      UserPoint p;
      UserPoint dir1;

      bool fancyJoints =  ( mPerpLen*mScale > 1.0 && mJoints==sjRound ) ||
                          ( mPerpLen*mScale >= 0.999 && mJoints==sjMiter) || mPolyAA;

      for(int i=1;i<inPath.size();i++)
      {
          const Segment &seg = inPath[i];
          UserPoint p0 = inPath[i-1].p;
          p = seg.p;

          UserPoint dir0 = seg.getDir0(p0).Normalized();
          dir1 = seg.getDir1(p0).Normalized();

          UserPoint next_dir;
          if (i+1<inPath.size())
             next_dir = inPath[i+1].getDir0(p).Normalized();
          else if (!isClosed)
          {
             next_dir = dir1;
             //printf("Dup next_dir\n");
          }
          else
          {
             next_dir = inPath[1].getDir0(p).Normalized();
          }


          UserPoint perp0(-dir0.y*mPerpLen, dir0.x*mPerpLen);
          UserPoint perp1(-dir1.y*mPerpLen, dir1.x*mPerpLen);
          UserPoint next_perp(-next_dir.y*mPerpLen, next_dir.x*mPerpLen);


          UserPoint p1_left = p-perp1;
          UserPoint p1_right = p+perp1;

          UserPoint p0_left = p0-perp0;
          UserPoint p0_right = p0+perp0;

          if (seg.isCurve())
          {
             if (seg.isCurve2())
                AddCubicSegment(leftCurve,rightCurve,perp0, perp1,p0,seg.curve0,seg.curve1,seg.p, p0_left, p0_right, p1_left, p1_right,t);
             else
                AddCurveSegment(leftCurve,rightCurve,perp0, perp1,p0,seg.curve0,seg.p, p0_left, p0_right, p1_left, p1_right,t);
             t+=1.0;
          }
          else
          {
             leftCurve.push_back( CurveEdge(p0_left,t) );
             leftCurve.push_back( CurveEdge(p1_left,t+0.99) );

             rightCurve.push_back( CurveEdge(p0_right,t) );
             rightCurve.push_back( CurveEdge(p1_right,t+0.99) );

             t+=1.0;
          }

          float segJoinLeft = leftCurve.last().t;
          float segJoinRight = rightCurve.last().t;

          float angle = next_dir.Dot(dir1);
          bool fullReverse = angle<-0.9999;
          if (fullReverse)
          {
             leftCurve.push_back( CurveEdge(p1_right,t) );
             rightCurve.push_back( CurveEdge(p1_left,t) );
          }
          else if ( fancyJoints && angle<0.9 )
          {
             /*

                              ---
                           ---
                        ---
                    - B-           next segment
                  Z   \         ...
                  |    \     ...
                  D_____\ ...____
                  |      p      C    ---.
                  |      .\     | ---
                  |      . \   -Y-
                  |      .  A-- |
                  |      .      |
                  |      .      |   p = end segment
                  |      .      |   
                  |      .      |   
                  |      .      |

                A = p + next_perp
                B = p - next_perp

                C = p + perp1
                D = p - perp1

                Y = A + alpha*next_dir
                  = C - alpha*dir1

                   = p + next_perp + alpha*next_dir
                   = p + perp1 - alpha*dir1

                   -> next_perp-perp1 = alpha*(dir1+next_dir)
                   -> alpha = prep1-next_perp     in either x or y direction...
                              ---------------
                              dir1+next_dir

                On the overlap side, we will draw a bevel, and let the removeLoops code fix it.
                On the non-overlay side, we will draw a joint
             */



             double denom_x = dir1.x+next_dir.x;
             double denom_y = dir1.y+next_dir.y;
             double alpha=0;

             // Choose the better-conditioned axis
             if (fabs(denom_x)>fabs(denom_y))
                alpha = denom_x==0 ? 0 : (perp1.x-next_perp.x)/denom_x;
             else
                alpha = denom_y==0 ? 0 : (perp1.y-next_perp.y)/denom_y;

             if ( fabs(alpha)>0.01 )
             {
                if (mJoints==sjRound)
                {
                      double angle = acos(dir1.Dot(next_dir));
                      if (angle<0) angle += M_PI;
                      if (alpha>0) // left
                         AddArc(leftCurve, p, angle, -perp1, dir1*mPerpLen, t );
                      else // right
                         AddArc(rightCurve, p, angle, perp1, dir1*mPerpLen, t );
                }
                else
                {
                      if (alpha>0) // left
                      {
                         AddMiter(leftCurve, p, p1_left, p-next_perp, alpha, dir1, next_dir,t);
                      }
                      else // Right
                      {
                         AddMiter(rightCurve, p, p1_right, p+next_perp, -alpha, dir1, next_dir,t);
                      }
                }
             }
          }
          t+=1.0;
      }

      // Endcap end ...
      if (!isClosed && (mCaps==scSquare || mCaps==scRound))
      {
         EndCap(leftCurve, rightCurve, p, dir1.Perp(mPerpLen),t);
      }

      cleanCurve(leftCurve,isClosed,-1);
      cleanCurve(rightCurve,isClosed,1);
   }

    void curvesToElement(const Curves &leftCurve,const Curves &rightCurve )
    {
      bool debug = false;
      /*
      if (debug)
      {
         printf("Left %d\n", leftCurve.size());
         for(int i=0;i<leftCurve.size();i++)
            printf("  %d  %f,%f   %f\n", i, leftCurve[i].p.x, leftCurve[i].p.y, leftCurve[i].t );

         printf("Right %d\n", rightCurve.size());
         for(int i=0;i<rightCurve.size();i++)
            printf("  %d  %f,%f   %f\n", i, rightCurve[i].p.x, rightCurve[i].p.y, rightCurve[i].t );
      }
      */

      //bool dbgPrt = leftCurve.size()>20 && leftCurve.size()<100;
      const bool dbgPrt = false;
      //printf("Curve %d %d\n", (int)leftCurve.size(), (int)rightCurve.size() );
      if (dbgPrt)
          printf("Flags: %04x, vo=%d, no=%d, to=%d, co=%d surf=%p\n", mElement. mFlags,
              mElement.mVertexOffset, mElement.mNormalOffset, mElement.mTexOffset, mElement.mColourOffset,
                mElement.mSurface );

      if (DEBUG_FAT_LINES)
      {
         if (mElement.mFlags & DRAW_HAS_NORMAL)
         {
            if (dbgPrt)
               printf("Remove normal stride\n");
            mElement.mFlags &= ~DRAW_HAS_NORMAL;
            if (mElement.mTexOffset>mElement.mNormalOffset)
               mElement.mTexOffset -= sizeof(float)*2;
            if (mElement.mColourOffset>mElement.mNormalOffset)
               mElement.mColourOffset -= sizeof(float)*2;

            mElement.mNormalOffset = 0;
            mElement.mStride -= sizeof(float)*2;
         }
         mElement.mWidth = 1;
         mElement.mScaleMode = ssmNone;
      }


      if (DEBUG_FAT_LINES==1)
      {
         for(int side=0; side<2; side++)
         {
            if (dbgPrt)
               printf("DBG: %s, voff=%d, stride=%d\n", side==0 ? "leftCurve" : "rightCurve", mElement.mVertexOffset, mElement.mStride);
            const Curves &curve = side==0 ? leftCurve : rightCurve;

            int n = curve.size();

            ReserveArrays(n);

            UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];

            for(int i=0;i<n;i++)
            {
               if (dbgPrt)
                  printf(" %d ] %f,%f\n", i, curve[i].p.x, curve[i].p.y );
               *v = curve[i].p;
               Next(v);
            }


            if (dbgPrt)
               mElement.mColour = 0xff00ff00;
            mElement.mPrimType = ptLineStrip;

            if (mElement.mSurface)
               CalcTexCoords();

            if (dbgPrt)
               printf("Push %d\n", mElement.mCount);

            PushElement();
            mElement.mVertexOffset = data.mArray.size();
            mElement.mCount = 0;
         }

         return;
      }


      const bool keepTriSense = true;

      int totalPoints = leftCurve.size() + rightCurve.size();
      // 3 is worst case if we have to reverse the tri
      int verticesPerPoint = DEBUG_FAT_LINES ? 4 : 3;
      // Must start with 2 points in debug case, these 2 are already counted in the non case.
      int extraPoints = DEBUG_FAT_LINES ? 2 : 0;
      data.mArray.reserve( mElement.mVertexOffset + mElement.mStride *
                             (totalPoints*verticesPerPoint + extraPoints)  );



      UserPoint *v = (UserPoint *)&data.mArray[mElement.mVertexOffset];
      UserPoint *normal = (mElement.mFlags & DRAW_HAS_NORMAL) ? (UserPoint *)&data.mArray[mElement.mNormalOffset] : 0;

      //printf("Curves : %d/%d\n", (int)leftCurve.size(), (int)rightCurve.size() );
      UserPoint prevLeft = leftCurve[0].p;
      UserPoint prevRight = rightCurve[0].p;

      UserPoint rightNormal(mPerpLen*mScale, -(mPerpLen*mScale+1.0));
      UserPoint leftNormal(mPerpLen*mScale, mPerpLen*mScale+1.0);


      int added = 0;
      int left = 1;
      int right = 1;


      enum { PREV_LEFT, PREV_RIGHT };
      int prevEdge = PREV_LEFT;


      int tris = 0;
      while(left<leftCurve.size() || right<rightCurve.size())
      {
         if (dbgPrt)
            printf(" %d} %d(%f),%d(%f)\n",(added-2)/4, left, leftCurve[left].t, right, rightCurve[right].t );

         bool preferRight =
             left>=leftCurve.size() || (right<rightCurve.size() && rightCurve[right].t < leftCurve[left].t);


         if (preferRight)
         {
            //printf("%d] Add right %d %f  : %f,%f\n", tris++, right, rightCurve[right].t, rightCurve[right].p.x, rightCurve[right].p.y );
            
            // Add point from right curve
            UserPoint addPoint = rightCurve[right++].p;
            if (!DEBUG_FAT_LINES)
               ComputeDistInfo(prevLeft, prevRight, addPoint, leftNormal, rightNormal, 1);


            if (DEBUG_FAT_LINES)
            {
               if (added==0)
               {
                  *v = prevLeft; Next(v);
                  *v = prevRight; Next(v);
                  added += 2;
               }

               *v = prevLeft; Next(v);
               *v = addPoint; Next(v);

               *v = prevRight; Next(v);
               *v = prevRight = addPoint; Next(v);

               added+=4;
            }
            else
            {
               if (added==0)
               {
                  *v = prevLeft; Next(v);
                  if (normal)
                     {  *normal = leftNormal; Next(normal); }

                  *v = prevRight; Next(v);
                  if (normal)
                     {  *normal = rightNormal; Next(normal); }
                  added += 2;
               }
               else if (keepTriSense && prevEdge!=PREV_LEFT)
               {
                  if (prevEdge==PREV_LEFT)
                  {
                     *v = prevRight; Next(v);
                     if (normal)
                        { *normal = rightNormal; Next(normal); }
                     added++;
                  }

                  *v = prevLeft; Next(v);
                  if (normal)
                     { *normal = leftNormal; Next(normal); }
                  added++;
               }

               added++;
               if (normal)
               {
                  *normal = rightNormal;
                  Next(normal);
               }
               *v = prevRight = addPoint;
               Next(v);
            }
            
            prevEdge = PREV_RIGHT;
         }
         else
         {
            // printf("%d] Add left  %d %f  : %f,%f\n", tris++, left, leftCurve[left].t, leftCurve[left].p.x, leftCurve[left].p.y );

            // Add point from left curve
            UserPoint addPoint = leftCurve[left++].p;
            if (!DEBUG_FAT_LINES)
               ComputeDistInfo(prevRight, prevLeft, addPoint, rightNormal, leftNormal, -1);

            if (DEBUG_FAT_LINES)
            {
               if (added==0)
               {
                  *v = prevRight; Next(v);
                  *v = prevLeft; Next(v);
                  added += 2;
               }


               *v = prevRight; Next(v);
               *v = addPoint; Next(v);

               *v = prevLeft; Next(v);
               *v = prevLeft = addPoint; Next(v);

               added+=4;
            }
            else
            {
               if (added==0)
               {
                  *v = prevLeft; Next(v);
                  if (normal)
                     {  *normal = leftNormal; Next(normal); }

                  *v = prevRight; Next(v);
                  if (normal)
                     {  *normal = rightNormal; Next(normal); }

                  added+=2;
               }
               else if (keepTriSense && prevEdge!=PREV_RIGHT)
               {
                  if (prevEdge==PREV_RIGHT)
                  {
                     *v = prevLeft; Next(v);
                     if (normal)
                        {  *normal = leftNormal; Next(normal); }
                     added++;
                  }

                  *v = prevRight; Next(v);
                  if (normal)
                     {  *normal = rightNormal; Next(normal); }
                  added++;
               }

               added++;
               if (normal)
               {
                  *normal = leftNormal;
                  Next(normal);
               }
               *v = prevLeft = addPoint;
               Next(v);
            }

            prevEdge = PREV_LEFT;
         }
      }

      // Build triangle strip....
      mElement.mPrimType = DEBUG_FAT_LINES ? ptLines : ptTriangleStrip;
      mElement.mCount = added;
      data.mArray.resize( mElement.mVertexOffset + mElement.mCount*mElement.mStride );

      if (mElement.mSurface)
      {
         //printf("Dbg text coords - %d\n", mElement.mTexOffset );
         CalcTexCoords();
      }

      PushElement();

      int extra = added * mElement.mStride;
      mElement.mVertexOffset += extra;

      if (mElement.mNormalOffset)
         mElement.mNormalOffset += extra;
      if (mElement.mTexOffset)
         mElement.mTexOffset += extra;
      if (mElement.mColourOffset)
         mElement.mColourOffset += extra;
      mElement.mCount = 0;
   }



   // Only support a single loop (no holes) in polyAA mode
   bool polyAaGeomOk(const uint8* inCommands, int inCount, const float *inData)
   {
      UserPoint *point = (UserPoint *)inData;
      UserPoint first;
      UserPoint prev;

      int stripSize = 0;
      int added = 0;
      for(int i=0;i<inCount;i++)
      {
         switch(inCommands[i])
         {
            case pcWideMoveTo:
               point++;
            case pcBeginAt:
            case pcMoveTo:
               if (stripSize==1 && prev==*point)
               {
                  point++;
                  continue;
               }

               if (stripSize>1)
                  if (added++>1) return false;

               stripSize = 1;
               prev = *point;
               first = *point++;
               break;

            case pcWideLineTo:
               point++;
            case pcLineTo:
               {
               if (stripSize>0 && *point==prev)
               {
                  point++;
                  continue;
               }

               stripSize++;

               // Implicit loop closing...
               if (stripSize>2 && *point==first )
               {
                  if (added++>1) return false;
                  stripSize = 0;
               }

               prev = *point;
               point++;
               }
               break;

            case pcCurveTo:
               {
                  if (stripSize>0 && *point==prev && point[1]==prev)
                  {
                     point+=2;
                     continue;
                  }

                  stripSize++;

                  // Implicit loop closing...
                  if (stripSize>=2 && point[1]==first)
                  {
                     if (added++>1) return false;
                     stripSize = 0;
                  }

                  prev = point[1];
                  point +=2;
              }
              break;


            case pcCubicTo:
               {
                  if (stripSize>0 && *point==prev && point[1]==prev && point[2]==prev)
                  {
                     point+=3;
                     continue;
                  }

                  stripSize++;

                  // Implicit loop closing...
                  if (stripSize>=2 && point[2]==first)
                  {
                     if (added++>1) return false;
                     stripSize = 0;
                  }

                  prev = point[2];
                  point +=3;
              }
              break;


            default:
               point += gCommandDataSize[ inCommands[i] ];
         }
      }

      if (stripSize>1 && added)
         return false;

      return true;
   }


   bool AddLineTriangles(const uint8* inCommands, int inCount, const float *inData)
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
               {
                  if (!AddStrip(strip,false))
                     return false;
               }

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
               if (strip.size()>2 && *point==first )
               {
                  if (!AddStrip(strip,true))
                     return false;
                  strip.resize(0);
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
                  if (strip.size()>=2 && point[1]==first)
                  {
                     if (!AddStrip(strip,true))
                        return false;
                     strip.resize(0);
                  }

                  prev = point[1];
                  point +=2;
              }
              break;


            case pcCubicTo:
               {
                  if (strip.size()>0 && *point==prev && point[1]==prev && point[2]==prev)
                  {
                     point+=3;
                     continue;
                  }

                  strip.push_back(Segment(point[2],point[1],point[0]));

                  // Implicit loop closing...
                  if (strip.size()>=2 && point[2]==first)
                  {
                     if (!AddStrip(strip,true))
                        return false;
                     strip.resize(0);
                  }

                  prev = point[2];
                  point +=3;
              }
              break;


            default:
               point += gCommandDataSize[ inCommands[i] ];
         }
      }

      if (strip.size()>1)
      {
         if (mPolyAA)
         {
            strip.push_back(Segment(first));
            return AddStrip(strip,true);
         }
         else
            return AddStrip(strip,false);
      }
      return true;
   }


   DrawElement  mElement;
   HardwareData &data;

   Texture     *mTexture;
   bool        mGradReflect;
   unsigned int mGradFlags;
   bool        mSolidMode;
   bool        mPolyAA;
   double      mMiterLimit;
   double      mPerpLen;
   double      mScale;
   double      mStateScale;
   float       mTileScaleX;
   float       mTileScaleY;
   double      mCurveThresh2;
   Matrix      mTextureMapper;
   StrokeCaps   mCaps;
   StrokeJoints mJoints;
   WindingRule  mWinding;
};

void CreatePointJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                   HardwareRenderer &inHardware)
{
   DrawElement elem;

   memset(&elem,0,sizeof(elem));
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
   elem.mVertexOffset = ioData.mArray.size();
   elem.mStride = sizeof(float)*2;
   if (!fill)
   {
     elem.mColourOffset = elem.mVertexOffset + elem.mStride;
     elem.mStride += sizeof(int);
     elem.mFlags |= DRAW_HAS_COLOUR;
     elem.mColour = 0xffffffff;
   }

   elem.mCount = inJob.mDataCount / (fill ? 2 : 3);
   ioData.mArray.resize( elem.mVertexOffset + elem.mStride*elem.mCount );

   UserPoint *srcV =  (UserPoint *)&inPath.data[ inJob.mData0 ];
   UserPoint *v = (UserPoint *)&ioData.mArray[ elem.mVertexOffset ];

   for(int i=0;i<elem.mCount;i++)
   {
      *v = *srcV++;
      v = (UserPoint *)( (char *)v + elem.mStride );
   }

   if (!fill)
   {
      const int * src = (const int *)(&inPath.data[ inJob.mData0 + elem.mCount*2]);
      int * dest =  (int *)&ioData.mArray[ elem.mColourOffset ];
      for(int i=0;i<elem.mCount;i++)
      {
         int s = src[i];
         *dest = (s & 0xff00ff00) | ((s>>16)&0xff) | ((s<<16) & 0xff0000);
         dest = (int *)( (char *)dest + elem.mStride );
      }
   }

   ioData.mElements.push_back(elem);
}

void BuildHardwareJob(const GraphicsJob &inJob,const GraphicsPath &inPath,HardwareData &ioData,
                      HardwareRenderer &inHardware, const RenderState &inState)
{
   ioData.releaseVbo();

   if (inJob.mIsPointJob)
      CreatePointJob(inJob,inPath,ioData,inHardware);
   else
   {
      HardwareBuilder builder(inJob,inPath,ioData,inHardware, inState);
   }
}


// --- HardwareData ---------------------------------------------------------------------
HardwareData::HardwareData()
{
   mRendersWithoutVbo = 0;
   mVertexBufferPtr = nullptr;
   mContextId = 0;
   mVboOwner = 0;
   mMinScale = mMaxScale = 0.0;
}

void HardwareData::releaseVbo()
{
   if (mVboOwner)
   {
      if (mVertexBufferPtr && mContextId==gTextureContextVersion)
         mVboOwner->DestroyVbo(mVertexBo,mVertexBufferPtr);
      mVboOwner->DecRef();
      mVboOwner=0;
   }
   mContextId = 0;
   mVertexBufferPtr = nullptr;
   mRendersWithoutVbo = 0;
}

float HardwareData::scaleOf(const RenderState &inState) const
{
   const Matrix &m = *inState.mTransform.mMatrix;
   return sqrt( 0.5*( m.m00*m.m00 + m.m01*m.m01 + m.m10*m.m10 + m.m11*m.m11 ) );
}

bool HardwareData::isScaleOk(const RenderState &inState) const
{
   if (mMinScale==0 && mMaxScale==0)
      return true;

   float scale = scaleOf(inState);
   if (mMinScale>0 && scale<mMinScale)
   {
      //printf("%f<%f\n", scale, mMinScale);
      return false;
   }
   if (mMaxScale>0 && scale>mMaxScale)
   {
      //printf("%f>%f\n", scale, mMaxScale);
      return false;
   }
   return true;
}




void HardwareData::clear()
{
   releaseVbo();
   for(int i=0;i<mElements.size();i++)
      if (mElements[i].mSurface)
         mElements[i].mSurface->DecRef();

   mArray.resize(0);
   mElements.resize(0);
   mMinScale = mMaxScale = 0.0;
}

HardwareData::~HardwareData()
{
   clear();
}


// --- HardwareRenderer -----------------------------


// Cache line thickness transforms...
static Matrix sLastMatrix;
double sLineScaleV = -1;
double sLineScaleH = -1;
double sLineScaleNormal = -1;


inline bool HitTri(const UserPoint &base, const UserPoint &_v0, const UserPoint &_v1, const UserPoint &pos)
{
   bool bgx = pos.x>base.x;
   if ( bgx!=(pos.x>_v0.x) || bgx!=(pos.x>_v1.x) )
   {
      bool bgy = pos.y>base.y;
      if ( bgy!=(pos.y>_v0.y) || bgy!=(pos.y>_v1.y) )
      {
         UserPoint v0 = _v0 - base;
         UserPoint v1 = _v1 - base;
         UserPoint v2 = pos - base;
         double dot00 = v0.Dot(v0);
         double dot01 = v0.Dot(v1);
         double dot02 = v0.Dot(v2);
         double dot11 = v1.Dot(v1);
         double dot12 = v1.Dot(v2);

         // Compute barycentric coordinates
         double denom = (dot00 * dot11 - dot01 * dot01);
         if (denom!=0)
         {
            denom = 1 / denom;
            double u = (dot11 * dot02 - dot01 * dot12) * denom;
            if (u>=0)
            {
               double v = (dot00 * dot12 - dot01 * dot02) * denom;

               // Check if point is in triangle
               if ( (v >= 0) && (u + v < 1) )
                  return true;
            }
         }
      }
   }

   return false;
}

HardwareRenderer::HardwareRenderer()
{
   HardwareRenderer::current = this;

   mWidth = 0;
   mHeight = 0;
   mLineWidth = -1;
   mLineScaleNormal = -1;
   mLineScaleV = -1;
   mLineScaleH = -1;
   mQuality = sqBest;
   mScaleX = mScaleY = 1.0;
   mOffsetX = mOffsetY = 0;

   for(int i=0;i<4;i++)
      for(int j=0;j<4;j++)
         mTrans[i][j] = i==j;
}

void HardwareRenderer::SetWindowSize(int inWidth,int inHeight)
{
   mWidth = inWidth;
   mHeight = inHeight;
}

int HardwareRenderer::Width() const { return mWidth; }
int HardwareRenderer::Height() const { return mHeight; }


void HardwareRenderer::setOrtho(float x0,float x1, float y0, float y1)
{
   mScaleX = 2.0/(x1-x0);
   mScaleY = 2.0/(y1-y0);
   mOffsetX = (x0+x1)/(x0-x1);
   mOffsetY = (y0+y1)/(y0-y1);
   mModelView = Matrix();

   CombineModelView(mModelView);
} 

void HardwareRenderer::CombineModelView(const Matrix &inModelView)
{
   mTrans[0][0] = inModelView.m00 * mScaleX;
   mTrans[0][1] = inModelView.m01 * mScaleX;
   mTrans[0][2] = 0;
   mTrans[0][3] = inModelView.mtx * mScaleX + mOffsetX;

   mTrans[1][0] = inModelView.m10 * mScaleY;
   mTrans[1][1] = inModelView.m11 * mScaleY;
   mTrans[1][2] = 0;
   mTrans[1][3] = inModelView.mty * mScaleY + mOffsetY;
}


void HardwareRenderer::SetQuality(StageQuality inQ)
{
   if (inQ!=mQuality)
   {
      mQuality = inQ;
      mLineWidth = 99999;
   }
}

void HardwareRenderer::Render(const RenderState &inState, const HardwareData &inData )
{
   if (!inData.mArray.size())
      return;

   SetViewport(inState.mClipRect);

   if (mModelView!=*inState.mTransform.mMatrix)
   {
      mModelView=*inState.mTransform.mMatrix;
      CombineModelView(mModelView);
      mLineScaleV = -1;
      mLineScaleH = -1;
      mLineScaleNormal = -1;
   }
   const ColorTransform *ctrans = inState.mColourTransform;
   if (ctrans && ctrans->IsIdentity())
      ctrans = 0;

   RenderData(inData,ctrans,mTrans);
}



bool HardwareRenderer::Hits(const RenderState &inState, const HardwareData &inData )
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


      // TODO: include extent in HardwareArrays
      const DrawElements &elements = inData.mElements;
      for(int e=0;e<elements.size();e++)
      {
         const DrawElement &draw = elements[e];
         UserPoint *v0 = (UserPoint *)&inData.mArray[ draw.mVertexOffset ];
         #define V(i) *((UserPoint *)((char *)v0+(i)*draw.mStride))

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
               case ssmOpenGL:
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

            UserPoint p0 = V(0);

            int prev = 0;
            if (p0.x<x0) prev |= 0x01;
            if (p0.x>x1) prev |= 0x02;
            if (p0.y<y0) prev |= 0x04;
            if (p0.y>y1) prev |= 0x08;
            if (prev==0 && pos.Dist2(p0)<=w2)
               return true;
            for(int i=1;i<draw.mCount;i++)
            {
               UserPoint p = V(i);
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
            UserPoint p0 = V(0);
            int count_left = 0;
            for(int i=1;i<=draw.mCount;i++)
            {
               UserPoint p = V(i%draw.mCount);
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
         else if (draw.mPrimType == ptTriangles)
         {
            if (draw.mCount<3)
               continue;

            int numTriangles = draw.mCount / 3;

            int vidx = 0;
            for(int i=0;i<numTriangles;i++)
            {
               UserPoint base = V(vidx++);
               UserPoint _v0 = V(vidx++);
               UserPoint _v1 = V(vidx++);
               if (HitTri(base,_v0,_v1,pos))
                  return true;
           }
         }
         else if ((draw.mPrimType == ptQuadsFull || draw.mPrimType == ptQuads) && (draw.mFlags & DRAW_TILE_MOUSE))
         {
            if (draw.mCount<4)
               continue;

            int numQuads = draw.mCount / 4;

            int vidx = 0;
            for(int i=0;i<numQuads;i++)
            {
               UserPoint base = V(vidx++);
               UserPoint _v0 = V(vidx++);
               UserPoint _v1 = V(vidx++);
               UserPoint _v2 = V(vidx++);
               if (HitTri(base,_v0,_v1,pos))
                  return true;
               else if (HitTri(_v0,_v2,_v1,pos))
                  return true;
           }
         }
         else if (draw.mPrimType == ptTriangleStrip)
         {
            for(int i=2;i<draw.mCount;i++)
            {
               if (HitTri(V(i-2), V(i-1),V(i), pos ))
                  return true;
            }
         }

      }

   return false;
}



} // end namespace nme

