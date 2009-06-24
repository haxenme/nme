#include "config.h"
#include <SDL.h>
#include <string>

#include <hxCFFI.h>

#ifdef __WIN32__
#include <windows.h>
#endif

#ifdef NME_ANY_GL
#include <SDL_opengl.h>
#endif



#include <vector>

#include "nme.h"
#include "nsdl.h"
#include "DrawObject.h"
#include "renderer/Renderer.h"
#include "Matrix.h"
#include "texture_buffer.h"
#include "text.h"
#include "Gradient.h"
#include "renderer/Points.h"


DEFINE_KIND( k_drawable );

DECLARE_KIND( k_mask )
DEFINE_KIND( k_mask )

#define DRAWABLE(v) ( (Drawable *)(val_data(v)) )
#define MASK(v) ( (MaskObject *)(val_data(v)) )

#include <set>




static int gBlendMode = BLEND_NORMAL;


class Scale9
{
public:
   bool   mActive;
   double X0,Y0;
   double X1,Y1;
   double SX,SY;
   double X1Off,Y1Off;
   
   Scale9() : mActive(false) { }
   bool Active() const { return mActive; }
   void Activate(double inX0, double inY0, double inW, double inH,
                 double inSX, double inSY,
                 double inExtX0, double inExtY0, double inExtW, double inExtH )
   {
      mActive = true;
      X0 = inX0;
      Y0 = inY0;
      X1 = inW + X0;
      Y1 = inH + Y0;
      // Right of object before scaling
      double right = inExtX0 + inExtW;
      // Right of object after scaling
      double extra_x = right*(inSX - 1);
      // Size of central rect
      double middle_x = inW + extra_x;
      // Scaling of central rect
      SX = middle_x/inW;
      // For points > X1, add this on...
      X1Off = inW*(SX-1);

      // Same for Y:
      double bottom = inExtY0 + inExtH;
      double extra_y = bottom*(inSY - 1);
      double middle_y = inH + extra_y;
      SY = middle_y/inH;
      Y1Off = inH*(SY-1);
   }
   void Deactivate() { mActive = false; }
   bool operator==(const Scale9 &inRHS) const
   {
      if (mActive!=inRHS.mActive) return false;
      if (!mActive) return true;
      return X0==inRHS.X0 && X1==inRHS.X1 && Y0==inRHS.Y0 && Y1==inRHS.Y1 &&
             X1Off==inRHS.X1Off && Y1Off==inRHS.Y1Off;
   }
   double TransX(double inX)
   {
      if (inX<=X0) return inX;
      return inX>X1 ? inX + X1Off : X0 + (inX-X0)*SX;
   }
   double TransY(double inY)
   {
      if (inY<=Y0) return inY;
      return inY>Y1 ? inY + Y1Off : Y0 + (inY-Y0)*SY;
   }
   Matrix GetFillMatrix(const Extent2DF &inExtent)
   {
      // The mapping of the edges should remain unchanged ...
      double x0 = TransX(inExtent.mMinX);
      double x1 = TransX(inExtent.mMaxX);
      double y0 = TransY(inExtent.mMinY);
      double y1 = TransY(inExtent.mMaxY);
      double w = inExtent.Width();
      double h = inExtent.Height();
      Matrix result;
      result.mtx = -inExtent.mMinX;
      if (w!=0)
      {
         double s = (x1-x0)/w;
         result.m00 = s;
         result.mtx *= s;
      }
      result.mtx += x0;

      result.mty = -inExtent.mMinY;
      if (h!=0)
      {
         double s = (y1-y0)/h;
         result.m11 = s;
         result.mty *= s;
      }
      result.mty += y0;
      return result;
   }

};


static int sQualityLevel = 1;
static Scale9 gScale9;


static int val_id_x = val_id("x");
static int val_id_y = val_id("y");
static int val_id_width = val_id("width");
static int val_id_height = val_id("height");
static int val_id_cx = val_id("cx");
static int val_id_cy = val_id("cy");
static int val_id_type = val_id("type");
static int val_id_grad = val_id("grad");
static int val_id_colour = val_id("colour");
static int val_id_thickness = val_id("thickness");
static int val_id_alpha = val_id("alpha");
static int val_id_joints = val_id("joints");
static int val_id_caps = val_id("caps");
static int val_id_scale_mode = val_id("scale_mode");
static int val_id_pixel_hinting = val_id("pixel_hinting");
static int val_id_miter_limit = val_id("miter_limit");
static int val_id_point_idx0 = val_id("point_idx0");
static int val_id_point_idx1 = val_id("point_idx1");

static int val_id___a = val_id("__a");
static int val_id___s = val_id("__s");
static int val_id_length = val_id("length");




class EmptyDrawable : public Drawable
{
public:
   EmptyDrawable() {}
   void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty,MaskObject *inMask,const Viewport &inVP) {}
   bool HitTest(int inX,int inY) { return false; }

   void GetExtent(Extent2DI &ioExtent, const Matrix &inMat,
                  bool inExtent) { }

};




// --- For drawing geometry -----------------------------------------

enum PointType
{
  ptMove = 0,
  ptLine = 1,
  ptCurve = 2,
};

struct Point
{
   float mX,mY;
   float mCX,mCY;
   int   mType;

   inline Point(){}
   inline Point(double inX,double inY) : mX( (float)inX), mY( (float)inY) { }
   inline Point(double inX,double inY, int inType) :
      mX( (float)inX), mY( (float)inY), mType(inType) { }

   inline int CurveSteps(const Point &inP0,double inScale) const
   {
      double dx0 = (mCX-inP0.mX);
      double dy0 = (mCY-inP0.mY);
      double dx1 = (mCX-mX);
      double dy1 = (mCY-mY);
      double len = sqrt(dx0*dx0 + dy0*dy0 + dx1*dx1 + dy1*dy1 )  * inScale;
      if (len<8)
      {
         return len>1 ? 2 : 1;
      }
      return (int)(len * 0.25);
   }

   void FromValue(value inVal)
   {
      mX = (float)val_number(val_field(inVal,val_id_x));
      mY = (float)val_number(val_field(inVal,val_id_y));
      mCX = (float)val_number(val_field(inVal,val_id_cx));
      mCY = (float)val_number(val_field(inVal,val_id_cy));
      mType = val_int(val_field(inVal,val_id_type));
   }
};

struct CurvedPoint
{
   inline CurvedPoint() {}
   inline CurvedPoint(const Point &inP) : mX(inP.mX), mY(inP.mY) {}
   void operator=(const Point &inRHS) { mX =inRHS.mX; mY=inRHS.mY; }

   float mX,mY;
};

typedef std::vector<Point> Points;
typedef std::vector<CurvedPoint> CurvedPoints;

#define SCALE_NONE       0
#define SCALE_VERTICAL   1
#define SCALE_HORIZONTAL 2
#define SCALE_NORMAL     3


struct LineJob : public PolyLine
{
   int             mColour;
   double          mAlpha;
   unsigned int    mFlags;
   double          mThick0;
   int             mScaleMode;
   Gradient        *mGradient;
   Matrix          mMappinMatrix;
   PolygonRenderer *mRenderer;
   int             mOrigPointIndex0;
   int             mOrigPointIndex1;

   void FromValue(value inVal)
   {
      mRenderer = 0;
      mGradient = CreateGradient(val_field(inVal,val_id_grad));
      mColour = val_int(val_field(inVal,val_id_colour));
      mThick0 = val_number(val_field(inVal,val_id_thickness));
      mThickness = mThick0 == 0 ? 1.0 : mThick0;
      mAlpha = val_number(val_field(inVal,val_id_alpha));
      mJoints = val_int(val_field(inVal,val_id_joints));
      mCaps = val_int(val_field(inVal,val_id_caps));
      mScaleMode = val_int(val_field(inVal,val_id_scale_mode));
      mPixelHinting = val_int(val_field(inVal,val_id_pixel_hinting));
      mMiterLimit = val_number(val_field(inVal,val_id_miter_limit));
      mOrigPointIndex0 = val_int(val_field(inVal,val_id_point_idx0));
      mOrigPointIndex1 = val_int(val_field(inVal,val_id_point_idx1));
   }

};

typedef std::vector<LineJob> LineJobs;

typedef std::vector<Point> Points;

void RGBSWAP(int &ioRGB)
{
   int r = ioRGB & 0xff0000;
   int b = ioRGB & 0x0000ff;
   ioRGB = (ioRGB & 0xff00ff00) | (r>>16) | (b<<16);
}

class DrawObject : public Drawable
{
public:
   void Init()
   {
      mDisplayList = 0;
      mResizeID = 0;
      mSolid = 0;
      mMaskID = -1;
      mIsOGL = false;
      mTexture = 0;
      mOldFlags = sQualityLevel>0 ? NME_HIGH_QUALITY : 0;
      mSolidGradient = 0;
      mLinesShareGrad = 0;
      mRendersWithoutDisplayList = 0;
      mFillColour = 0x00000000;
      mFillAlpha = 1.0;
      mCurveScale = 0.0;
      mCull = 0;
   }

   DrawObject(Points &inPoints, int inFillColour,double inFillAlpha,
              Gradient *inFillGradient,
              TextureReference *inTexture,
              LineJobs &inLines,
              bool inLinesShareGrad = false) :
                 mTransform(0,0,0,0)
   {
      Init();
      // TODO:
      #ifdef IPHONE
      RGBSWAP(inFillColour);
      #endif
      mLinesShareGrad = inLinesShareGrad;
      mSolidGradient = inFillGradient;
      mTexture = inTexture;
      mOrigPoints.swap(inPoints);

      if (!mSolidGradient && !mTexture)
      {
         mFillColour = inFillColour;
         mFillAlpha = inFillAlpha;
      }

      mLineJobs.swap(inLines);
   }

   DrawObject(TriPoints &inPoints, Tris &inTris, int inCull, int inFillColour,double inFillAlpha,
                const LineJob &inLineStyle): mTransform(0,0,0,0)
   {
      Init();
      mTriPoints.swap(inPoints);
      mTriangles.swap(inTris);
      mFillColour = inFillColour;
      mFillAlpha = inFillAlpha;
      BuildTriangleLines(inLineStyle);
   }

   DrawObject(TriPoints &inPoints, Tris &inTris, int inCull, TextureReference *inTexture,
                const LineJob &inLineStyle, double inTexW, double inTexH, bool inPersectiveCorrect):
        mTransform(0,0,0,0)
   {
      Init();
      mTriPoints.swap(inPoints);
      mTriangles.swap(inTris);
      mTexture = inTexture;
      BuildTriangleLines(inLineStyle);
      mTexScaleX = inTexW ? 1.0/inTexW : 1;
      mTexScaleY = inTexH ? 1.0/inTexH : 1;
      mPerspectiveCorrect = inPersectiveCorrect;
   }

   void BuildTriangleLines(const LineJob &inLineStyle)
   {
      if (inLineStyle.mAlpha>0)
      {
         mLineJobs.resize(mTriangles.size());
         for(size_t i=0;i<mLineJobs.size();i++)
         {
            mLineJobs[i] = inLineStyle;
            mLineJobs[i].mPointIndex0 = 0;
            mLineJobs[i].mPointIndex1 = 3;
         }
      }
   }

   void BuildCurved(const Points &inPoints,double inScale)
   {
      size_t n = inPoints.size();
      IntVec remap(n);

      mTex.resize(0);
      mLineTex.resize(0);
      mPoints.resize(0);
      mPoints.reserve(n);
      mConnection.resize(0);
      mConnection.reserve(n);

      mCurveScale = inScale;

      for(size_t i=0;i<n;i++)
      {
         const Point &p1 = inPoints[i];
         if (p1.mType == ptCurve && i>0)
         {
            const Point &p0 = inPoints[i-1];
            int steps = inPoints[i].CurveSteps(p0,inScale);
            if (steps>=2)
            {
               float dt = 1.0f/steps;
               float t = dt;
               for(int s=1;s<steps;s++)
               {
                  CurvedPoint p;
                  float c0 = (1-t)*(1-t);
                  float c1 = 2*t*(1-t);
                  float c2 = t*t;
                  p.mX = c0*p0.mX + c1*p1.mCX + c2*p1.mX;
                  p.mY = c0*p0.mY + c1*p1.mCY + c2*p1.mY;
                  mPoints.push_back(p);
                  mConnection.push_back(1);
                  t += dt;
               }
            }
         }

         remap[i] = (int)mPoints.size();
         mPoints.push_back(p1);
         mConnection.push_back(p1.mType!=ptMove);
      }

      for(size_t l=0;l<mLineJobs.size();l++)
      {
         LineJob &job = mLineJobs[l];
         job.mPointIndex0 = remap[job.mOrigPointIndex0];
         job.mPointIndex1 = remap[job.mOrigPointIndex1];
      }

      mPointF16s.resize(mPoints.size());

      ClearRenderers();
   }

   void ClearRenderers()
   {
      mRendersWithoutDisplayList = 0;
      mTex.resize(0);
      mLineTex.resize(0);
      delete mSolid;
      mSolid = 0;

      for(size_t i=0;i<mLineJobs.size();i++)
      {
         delete mLineJobs[i].mRenderer;
         mLineJobs[i].mRenderer = 0;
      }
   }

   ~DrawObject()
   {
      ClearRenderers();
      delete mTexture;

      for(size_t i=0;i<mLineJobs.size();i++)
      {
         delete mLineJobs[i].mGradient;
         if (mLinesShareGrad)
            break;
      }

      delete mSolidGradient;
      #ifdef NME_OPENGL
      if (mDisplayList!=0 && nme_resize_id==mResizeID)
         glDeleteLists(mDisplayList,1);
      #endif
   }


   #ifdef NME_ANY_GL
   void DrawOpenGL()
   {
      bool is_triangles = mTriangles.size()>0;
      size_t n = is_triangles ? mTriangles.size() : mPoints.size();
      if (n==0)
         return;

      glDisable(GL_DEPTH_TEST);
      glEnable(GL_BLEND);
      if (gBlendMode==BLEND_MULTIPLY)
         glBlendFunc(GL_DST_COLOR, GL_ZERO);
      else if (gBlendMode==BLEND_ADD)
         glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      else
         glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
      if (mSolidGradient || mFillAlpha>0.0 || mTexture || is_triangles)
      {
         TextureBuffer *tex = mTexture ? mTexture->mTexture : 0;
         if (tex)
            glColor4f(1.0,1.0,1.0,1.0);
         else
            glColor4ub(mFillColour >> 16, mFillColour >> 8, mFillColour, (int)(mFillAlpha*255.0));

         if (mSolidGradient)
            mSolidGradient->BeginOpenGL();
         else if (tex)
         {
            tex->BindOpenGL( (mTexture->mFlags & NME_EDGE_MASK) ==NME_EDGE_REPEAT );
         }
         else
            glDisable(GL_TEXTURE_2D);

         if (is_triangles)
         {
            TriPoint *point = &mTriPoints[0];
            Tri *tri = &mTriangles[0];
#if 0
            glBegin(GL_TRIANGLES);
            for(size_t t=0;t<n;t++)
            {
               for(int idx=0;idx<3;idx++)
               {
                  TriPoint &p = point[tri->mIndex[idx]];
                  if (tex)
                  {
                     //printf(" %f %f\n", p.mU, p.mV);
                     glTexCoord2d( p.mU*mTexScaleX, p.mV*mTexScaleY );
                     if (mPerspectiveCorrect)
                     {
                        double w = p.mW_inv;
                        glVertex4d( p.mX*w, p.mY*w, 0.0, w );
                     }
                     else
                        glVertex2d( p.mX, p.mY );
                  }
                  else
                     glVertex2d( p.mX, p.mY );
               }
               tri++;
            }
            glEnd();
#endif
         }
         else
         {
            // TODO: tesselate
            const CurvedPoint *p = &mPoints[0];

            //glTexCoordPointer(2, GL_FLOAT, 0, &tex[0][0] );
            //glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            //glDisableClientState(GL_TEXTURE_COORD_ARRAY);

            if (mSolidGradient)
            {
               if (mTex.size()!=n)
               {
                  mTex.resize(n);
                  float *t = &mTex[0];
                  for(size_t i=0;i<n;i++)
                      mSolidGradient->OpenGLTexture(t++, p[i].mX, p[i].mY );
                }
                glTexCoordPointer(1, GL_FLOAT, 0, &mTex[0] );
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            }
            else if (tex)
            {
               if (mTex.size()!=n*2)
               {
                  mTex.resize(n*2);
                  float *t = &mTex[0];
                  for(size_t i=0;i<n;i++)
                  {
                      // TODO: texture matix transform ?
                      mTexture->OpenGLTexture(t, p[i].mX, p[i].mY, mTexture->mTransMatrix);
                      t+=2;
                  }
                }
                glTexCoordPointer(2, GL_FLOAT, 0, &mTex[0] );
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            }
       

            glVertexPointer(2, GL_FLOAT, 0, p);
            glEnableClientState(GL_VERTEX_ARRAY);

            glDrawArrays(GL_TRIANGLE_FAN,0,n);

            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
         }

         if (tex)
            tex->UnBindOpenGL();
      }

      if (mSolidGradient)
         mSolidGradient->EndOpenGL();
   
      for(size_t j=0;j<mLineJobs.size();j++)
      {
         LineJob &line = mLineJobs[j];

         if (line.mGradient)
            line.mGradient->BeginOpenGL();
         else
         {
            int col = line.mColour;
            glColor4ub(col >>16,col >> 8,col, (unsigned char)(line.mAlpha*255.0));
         }

         glLineWidth( (float)line.mThickness );

         size_t n = line.mPointIndex1 - line.mPointIndex0 + 1;
         if (is_triangles)
         {
            Tri &tri = mTriangles[j];
#if 0
            glBegin(GL_LINE_LOOP);
            for(size_t k=0;k<3;k++)
            {
               TriPoint &point = mTriPoints[tri.mIndex[k]];
               glVertex2d( point.mX, point.mY );
            }
            glEnd();
#endif
         }
         else
         {
            const CurvedPoint *p = &mPoints[0];
            if (line.mGradient)
            {
               if (mLineTex.size()!=n)
               {
                  mLineTex.resize(n);
                  float *t = &mLineTex[0];
                  for(size_t i=0;i<n;i++)
                  {
                     size_t pid = line.mPointIndex0 + i;
                     line.mGradient->OpenGLTexture(t++, p[pid].mX, p[pid].mY );
                  }
                }
                glTexCoordPointer(1, GL_FLOAT, 0, &mTex[0] );
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            }

            // todo: cache
            std::vector<float> point_array(n*2);
            float *f = &point_array[0];
            for(size_t i=0;i<n;i++)
            {
               size_t pid = line.mPointIndex0 + i;
               *f++ = mPoints[pid].mX;
               *f++ = mPoints[pid].mY;
            }
   

            glVertexPointer(2, GL_FLOAT, 0, &point_array[0]);
            glEnableClientState(GL_VERTEX_ARRAY);

            glDrawArrays(GL_LINE_STRIP,0,n);

            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);

#if 0
            glBegin(GL_LINE_STRIP);
            for(size_t i=0;i<n;i++)
            {
               size_t pid = line.mPointIndex0 + i;
               if (line.mGradient)
                  line.mGradient->OpenGLTexture( mPoints[pid].mX,mPoints[pid].mY );
               glVertex2f( mPoints[pid].mX, mPoints[pid].mY );
            }
            glEnd();
#endif
         }

         if (line.mGradient)
            line.mGradient->EndOpenGL();
      }
      glLineWidth(1);

      glDisable(GL_BLEND);
   }
   #endif // NME_ANY_GL

   #ifdef NME_OPENGL
   bool CreateDisplayList()
   {
      mResizeID = nme_resize_id;
      mDisplayList = glGenLists(1);
      glNewList(mDisplayList,GL_COMPILE);
      DrawOpenGL();
      glEndList();

      return true;
   }
   #endif

   virtual void GetExtent(Extent2DI &ioExtent,const Matrix &inMatrix, bool inAccurate)
   {
      bool is_triangles = mTriangles.size()>0;
      if (inAccurate)
      {
         SetupCurved(inMatrix);

         CreateRenderers(0,inMatrix,0,0,Scale9());
         mMaskID = -1;

         Extent2DI extent;
         if (mSolid)
            mSolid->GetExtent(extent);

         for(size_t j=0;j<mLineJobs.size();j++)
            mLineJobs[j].mRenderer->GetExtent(extent);
         extent.Translate(mTX,mTY);
         ioExtent.Add(extent);
      }
      else if (inMatrix.IsIdentity())
      {
         if (is_triangles)
         {
            size_t n = mTriPoints.size();
            for(size_t i=0;i<n;i++)
               ioExtent.Add(mTriPoints[i].mX,mTriPoints[i].mY);
         }
         else
         {
            size_t n = mPoints.size();
            for(size_t i=0;i<n;i++)
               ioExtent.Add(mPoints[i].mX,mPoints[i].mY);
         }
      }
      else
      {
         TransformPoints(inMatrix,Scale9());
         size_t n = mPointF16s.size();
         for(size_t i=0;i<n;i++)
            ioExtent.Add(mPointF16s[i]);
      }
   }


   void TransformPoints(const Matrix &inMatrix,const Scale9 &inScale9)
   {
      bool is_triangles = mOrigPoints.empty();
      size_t n = is_triangles ? mTriPoints.size() : mPoints.size();
      mTransform = inMatrix;
      mScale9 = inScale9;
      mTX = 0;
      mTY = 0;

      if (mTransform.IsIdentity() && !mScale9.Active())
      {
         if (is_triangles)
         {
            for(size_t i=0;i<n;i++)
            {
               TriPoint &p = mTriPoints[i];
               p.mPos16 = PointF16(p.mX,p.mY);
            }
         }
         else
         {
            for(size_t i=0;i<n;i++)
               mPointF16s[i] = PointF16(mPoints[i].mX,mPoints[i].mY);

            if (mSolidGradient)
               mSolidGradient->IdentityTransform();
            else if (mTexture)
               mTexture->IdentityTransform();

            for(size_t i=0;i<mLineJobs.size();i++)
               if (mLineJobs[i].mGradient)
                  mLineJobs[i].mGradient->IdentityTransform();
         }
     }
     else
     {
        Extent2DF extent;

        if (mScale9.Active())
        {
           if (is_triangles)
           {
              for(size_t i=0;i<n;i++)
              {
                 TriPoint &p = mTriPoints[i];
                 double x = mScale9.TransX(p.mX);
                 double y = mScale9.TransY(p.mY);
                 mTransform.TransformHQ((float)x,(float)y,p.mPos16.x,p.mPos16.y);
              }
           }
           else
           {
              for(size_t i=0;i<n;i++)
              {
                 double x = mScale9.TransX(mPoints[i].mX);
                 double y = mScale9.TransY(mPoints[i].mY);
                 mTransform.TransformHQ((float)x,(float)y,mPointF16s[i].x,mPointF16s[i].y);
              }

              bool need_extent = mSolidGradient || mTexture;
              for(size_t i=0; !need_extent && i<mLineJobs.size();i++)
                 need_extent = mLineJobs[i].mGradient!=0;
              if (need_extent)
              {
                 size_t n = mPoints.size();
                 for(size_t i=0;i<n;i++)
                   extent.Add(mPoints[i].mX,mPoints[i].mY);
              }
           }
        }
        else
        {
           if (is_triangles)
           {
              for(size_t i=0;i<n;i++)
              {
                 TriPoint &p = mTriPoints[i];
                 mTransform.TransformHQ((float)p.mX,(float)p.mY,p.mPos16.x,p.mPos16.y);
              }
           }
           else
           {
              for(size_t i=0;i<n;i++)
              {
                 mTransform.TransformHQ(mPoints[i].mX,mPoints[i].mY,
                     mPointF16s[i].x,mPointF16s[i].y);
              }
           }
        }

        if (!is_triangles)
        {
           if (mScale9.Active() && (mSolidGradient || mTexture))
           {
              Matrix m = mTransform.Mult( mScale9.GetFillMatrix(extent));

              if (mSolidGradient)
                 mSolidGradient->Transform(m);
              else if (mTexture)
                 mTexture->Transform(m);
           }
           else
           {
              if (mSolidGradient)
                 mSolidGradient->Transform(mTransform);
              else if (mTexture)
                 mTexture->Transform(mTransform);
           }
        }
        else if (mLineJobs.size())
        {
            mPointF16s.resize(mTriangles.size()*4);
            for(size_t i=0;i<mTriangles.size();i++)
            {
               Tri &tri = mTriangles[i];
               for(int j=0;j<4;j++)
                  mPointF16s[i*4+j] = mTriPoints[ tri.mIndex[j%3] ].mPos16;
            }
        }



         for(size_t i=0;i<mLineJobs.size();i++)
         {
            LineJob &job = mLineJobs[i];
            if (job.mGradient)
            {
               if (mScale9.Active())
                  job.mGradient->Transform(mScale9.GetFillMatrix(extent));
               else
                  job.mGradient->Transform(mTransform);
            }
            if (job.mThick0>0 && job.mScaleMode != SCALE_NONE)
            {
               double scale_x = 1.0;
               double scale_y = 1.0;

               // The meaning of vertical and horizontal seem to match the flash player
               if (job.mScaleMode & SCALE_VERTICAL)
                  scale_x = sqrt( mTransform.m00*mTransform.m00 +
                                  mTransform.m01*mTransform.m01  );
               if (job.mScaleMode & SCALE_HORIZONTAL)
                  scale_y = sqrt( mTransform.m10*mTransform.m10 +
                                  mTransform.m11*mTransform.m11  );

               if (job.mScaleMode == SCALE_VERTICAL)
                  job.mThickness = job.mThick0 * scale_x;
               else if (job.mScaleMode == SCALE_HORIZONTAL)
                  job.mThickness = job.mThick0 * scale_y;
               else
                  job.mThickness = job.mThick0 * sqrt(scale_x*scale_y);
            }
         }
     }
   }

   virtual bool IsGrad() { return mSolid!=0 || mSolidGradient!=0; }

   void SetupCurved(const Matrix &inMatrix)
   {
      if (mOrigPoints.empty())
         return;

      double scale = pow( (inMatrix.m00*inMatrix.m00 + inMatrix.m01*inMatrix.m01) *
                           (inMatrix.m10*inMatrix.m10 + inMatrix.m11*inMatrix.m11), 0.25 );
      if ( (fabs(scale-mCurveScale) > 0.1) || mCurveScale==0)
         BuildCurved(mOrigPoints,scale);
   }

   // DrawObject
   void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty, MaskObject *inMaskObj,
                  const Viewport &inVP)
   {
      SetupCurved(inMatrix);

      #ifdef NME_ANY_GL
      mIsOGL =  IsOpenGLScreen(inSurface);
      if (mIsOGL)
      {
         if (mTexture)
            mTexture->UpdateHardware();

         mOGLMatrix = inMatrix;
         #ifdef NME_OPENGL
         if ((!mDisplayList || nme_resize_id!=mResizeID) && mRendersWithoutDisplayList>1)
            CreateDisplayList();
         #endif

         bool scissor = false;
         if (IsOpenGLScreen(inSurface) &&
             (inVP.x0>0 || inVP.y0>0 || inVP.x1< inSurface->w || inVP.y1<inSurface->h ) )
         {
            scissor = true;
            glEnable(GL_SCISSOR_TEST);
            glScissor(inVP.x0, inSurface->h - inVP.y1, inVP.Width(), inVP.Height());
         }


         if (inMatrix.IsIdentity())
         {
            #ifdef NME_OPENGL
            if (mDisplayList && mResizeID==nme_resize_id)
            {
               glCallList(mDisplayList);
            }
            else
            #endif
            {
               mRendersWithoutDisplayList++;
               DrawOpenGL();
            }
         }
         else
         {
            glPushMatrix();
            inMatrix.GLMult();
            #ifdef NME_OPENGL
            if (mDisplayList && mResizeID==nme_resize_id)
               glCallList(mDisplayList);
            else
            #endif
            {
               mRendersWithoutDisplayList++;
               DrawOpenGL();
            }
            glPopMatrix();
         }

         if (scissor)
            glDisable(GL_SCISSOR_TEST);
      }
      else
      #endif // NME_ANY_GL
      {
         PolygonMask *mask = inMaskObj ? inMaskObj->GetPolygonMask() : 0;
         CreateRenderers(inSurface,inMatrix,inMarkDirty,inMaskObj,gScale9);

         if (mSolid)
            mSolid->Render(inSurface,inVP,mTX,mTY);

         size_t jobs = mLineJobs.size();
         for(size_t j=0;j<jobs;j++)
         {
            LineJob &job = mLineJobs[ j ];

            if (job.mRenderer)
               job.mRenderer->Render(inSurface,inVP,mTX,mTY);
         }
      }
   }

   void AddToMask(SDL_Surface *inSurf,PolygonMask &ioMask,const Matrix &inMatrix)
   {
      SetupCurved(inMatrix);
      CreateRenderers(inSurf,inMatrix,false,0,gScale9);
      if (mSolid)
      {
         mSolid->AddToMask(ioMask,mTX,mTY);
      }
   }

   // DrawObject
   bool HitTest(int inX,int inY)
   {
      #ifdef NME_OPENGL
      if (mIsOGL)
      {
         // Line width seems to get ignored when picking?
         if (mDisplayList && mResizeID==nme_resize_id)
         {
             GLuint buffer[10];
             glSelectBuffer(10, buffer); 

             glRenderMode(GL_SELECT);

             glMatrixMode(GL_PROJECTION);
             glLoadIdentity();
             glTranslated(-inX,-inY,0);

             glMatrixMode(GL_MODELVIEW);
             glLoadIdentity();
             mOGLMatrix.GLMult();

             glLoadName(1);

             glCallList(mDisplayList);

             GLint hits = glRenderMode(GL_RENDER);
             return hits>0;
         }
      }
      else
      #endif // NME_OPENGL
      {
         if (mSolid && mSolid->HitTest(inX-mTX,inY-mTY))
            return true;

         size_t jobs = mLineJobs.size();
         for(size_t j=0;j<jobs;j++)
         {
            LineJob &job = mLineJobs[ j ];

            if (job.mRenderer && job.mRenderer->HitTest(inX-mTX,inY-mTY))
               return true;
         }
      }

       return false;
   }


   // DrawObject
   void CreateRenderers(SDL_Surface *inSurface,
            const Matrix &inMatrix,TextureBuffer *inMarkDirty,MaskObject *inMaskObj,
            const Scale9 &inScale9)
   {
      if (mPoints.empty() && mTriPoints.empty())
         return;

      bool is_triangles = mOrigPoints.empty();

      int min_y = -0x7fff;
      int max_y =  0x7fff;

      if (!mTransform.IsIntTranslation(inMatrix,mTX,mTY) || !(inScale9==mScale9) )
      {
         TransformPoints(inMatrix,inScale9);
         ClearRenderers();
      }

      unsigned int flags = sQualityLevel>0 ? NME_HIGH_QUALITY : 0;
      if (flags!=mOldFlags)
      {
         mOldFlags = flags;
         ClearRenderers();
      }

      int id = inMaskObj==0 ? -1 : inMaskObj->GetID();
      if (mMaskID != id)
      {
         ClearRenderers();
         mMaskID = id;
      }


      PolygonMask *mask = 0;
      if (inMaskObj)
      {
         //inMaskObj->ClipY(min_y);
         //inMaskObj->ClipY(max_y);
         mask = inMaskObj->GetPolygonMask();
      }


      Uint16 n = (Uint16)mPoints.size();

      if (mSolidGradient || mFillAlpha>0)
      {
         if (inMarkDirty)
         {
            size_t n = mPointF16s.size();
            for(size_t i=0;i<n;i++)
            {
               int x = mPointF16s[i].x>>16;
               int y = mPointF16s[i].y>>16;
               inMarkDirty->SetExtentDirty(x,y,x+1,y+1);
            }
         }

         if (!mSolid)
         {
            if (is_triangles)
            {
               if (mTexture)
               {
                  Uint32 flags = mTexture->mFlags;
                  flags |= NME_EDGE_CLAMP;
                  if (mPerspectiveCorrect)
                     flags |= NME_TEX_PERSPECTIVE;
                  mSolid = PolygonRenderer::CreateBitmapTriangles(mTriPoints,mTriangles,
                                 mTexture->mTexture->GetSourceSurface(), flags);
               }
               else
                  mSolid = PolygonRenderer::CreateSolidTriangles(mTriPoints,mTriangles,
                                 mFillColour, mFillAlpha );
            }
            else
            {
               RenderArgs args;
               args.inN = (int)mPointF16s.size();
               args.inPoints = &mPointF16s[0];
               args.inLines = 0;
               args.inConnect = &mConnection[0];
               args.inMinY = min_y;
               args.inMaxY = max_y;
               args.inFlags = flags;

               if (mSolidGradient)
               {
                  mSolid = PolygonRenderer::CreateGradientRenderer(args,
                                 mSolidGradient );
               }
               else if (mTexture)
               { 
                  //Matrix m(mTexture->mTransMatrix);

                  args.inFlags |= mTexture->mFlags;
                  mSolid = PolygonRenderer::CreateBitmapRenderer(args,
                                 mTexture->mTexture->GetSourceSurface(),
                                 mTexture->mTransMatrix);
               }
               else
               {
                  mSolid = PolygonRenderer::CreateSolidRenderer(args,
                                 mFillColour, mFillAlpha );
               }
               if (mSolid && mask)
                  mSolid->Mask(*mask);
            }
         }

      }

      size_t jobs = mLineJobs.size();
      for(size_t j=0;j<jobs;j++)
      {
         LineJob &job = mLineJobs[ j ];
         if (!job.mRenderer)
         {
            RenderArgs args;
            if (!is_triangles)
            {
               args.inN = (int)mPointF16s.size();
               args.inPoints = &mPointF16s[0];
               args.inConnect = 0;
            }
            else
            {
               static char tri_connect[] = { 0,1,1,1 };
               args.inN = 4;
               args.inPoints = &mPointF16s[j*4];
               args.inConnect = tri_connect;
            }
            args.inLines = &job;
            args.inMinY = min_y;
            args.inMaxY = max_y;
            args.inFlags = flags;

            if (job.mGradient)
            {
               job.mRenderer = PolygonRenderer::CreateGradientRenderer(args,
                               job.mGradient );

            }
            else
            {
               job.mRenderer = PolygonRenderer::CreateSolidRenderer(args,
                                  job.mColour, job.mAlpha );
            }
            if (mask)
               job.mRenderer->Mask(*mask);
         }

      }
   }




   // For line/polygon objects
   Points             mOrigPoints;
   CurvedPoints       mPoints;
   std::vector<float> mTex;
   std::vector<float> mLineTex;
   std::vector<char>  mConnection;
   // For triangle object
   TriPoints          mTriPoints;
   Tris               mTriangles;
   int                mCull;
   double             mTexScaleX;
   double             mTexScaleY;
   bool               mPerspectiveCorrect;

   Gradient     *mSolidGradient;
   TextureReference *mTexture;
   int          mFillColour;
   unsigned int mOldFlags;
   double       mFillAlpha;
   double       mCurveScale;
   LineJobs     mLineJobs;

   std::vector<PointF16> mPointF16s;

   GLuint       mDisplayList;
   int          mResizeID;
   // It is expensive to recreate the display list every frame.
   int          mRendersWithoutDisplayList;

   bool         mIsOGL;
   Matrix       mOGLMatrix;

   Matrix       mTransform;
   Scale9       mScale9;
   int          mTX;
   int          mTY;
   //int          mMinY;
   //int          mMaxY;
   int          mMaskID;

   PolygonRenderer *mSolid;

   bool mLinesShareGrad;

private: // Hide
   DrawObject(const DrawObject &inRHS);
   void operator=(const DrawObject &inRHS);
};



value nme_create_draw_obj(value inPoints, value inFillColour, value inFillAlpha,
                          value inGradientOrTexture, value inLines)
{
   val_check( inFillColour, int );
   val_check( inFillAlpha, number );
   val_check( inPoints, array );
   val_check( inLines, array );

   int n = val_array_size(inPoints);

   Points points(n);
   for(int i=0;i<n;i++)
      points[i].FromValue(val_array_i(inPoints,i));

   n = val_array_size(inLines);
   LineJobs lines(n);
   for(int j=0;j<n;j++)
      lines[j].FromValue(val_array_i(inLines,j));

   DrawObject *obj = new DrawObject(
                            points,
                            val_int(inFillColour),
                            val_number(inFillAlpha),
                            CreateGradient(inGradientOrTexture),
                            TextureReference::Create(inGradientOrTexture),
                            lines );

   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );
   return v;
}


value nme_create_draw_triangles(value * arg, int nargs )
{
   enum { aVertices, aIndices, aUVTData, aCull, aFillColour, aFillAlpha, aBitmap, aLine, aSIZE };
   if (nargs!=aSIZE)
      hx_failure("nme_create_draw_triangles - wrong number of args");

   TriPoints points;


   value v =  arg[aVertices];
   val_check( v, array );
   int n =  val_array_size(v);

   if (n&1)
      hx_failure("nme_create_draw_triangles - odd number of points");

   n/=2;
   points.resize(n);
   for(int i=0;i<n;i++)
      points[i].SetPos(val_number(val_array_i(v,i*2)), val_number(val_array_i(v,i*2+1)));

   int cull = val_int(arg[aCull]);

   value idx = arg[aIndices];
   Tris triangles;
   if (!val_is_null(idx))
   {
      int indices = val_array_size(idx);
      if ( (indices%3)!=0 )
         hx_failure("nme_create_draw_triangles - invalid index count");

      indices /= 3;
      triangles.reserve(indices);
      for(int i=0;i<indices;i++)
         triangles.push_back(Tri(val_int(val_array_i(idx,i*3)),
                                 val_int(val_array_i(idx,i*3+1)),
                                 val_int(val_array_i(idx,i*3+2)) ) );
   }
   else
   {
      if ( (n%3)!=0 )
         hx_failure("nme_create_draw_triangles - invalid vertex count");
      int indices = n/3;
      triangles.reserve(indices);
      for(int i=0;i<indices;i++)
         triangles.push_back(Tri(i*3,i*3+1,i*3+2));
   }

   value uv = arg[aUVTData];
   TextureReference *texture = TextureReference::Create(arg[aBitmap]);

   bool has_uv = !val_is_null(uv) && texture!=0;

   LineJob wireframe;
   wireframe.FromValue(arg[aLine]);

   DrawObject *obj = 0;
   if (has_uv)
   {
      int entries = val_array_size(uv);
      double w = texture->mTexture->Width();
      double h = texture->mTexture->Height();
      bool persp = false;
      if (entries == 2*n)
      {
         for(int i=0;i<n;i++)
         {
            points[i].SetUVW(val_number(val_array_i(uv,i*2))*w,
                            val_number(val_array_i(uv,i*2+1))*h);
         }
      }
      else if (entries == 3*n)
      {
         persp = true;
         for(int i=0;i<n;i++)
         {
            points[i].SetUVW(val_number(val_array_i(uv,i*3))*w,
                             val_number(val_array_i(uv,i*3+1))*h,
                             val_number(val_array_i(uv,i*3+2)));
         }
      }
      else
         hx_failure("nme_create_draw_triangles - incorrect number of uv entries");


      obj = new DrawObject( points, triangles, cull, texture, wireframe, w, h, persp );
   }
   else
   {
      if (texture)
         delete texture;
      obj = new DrawObject(points, triangles, cull,
                            val_int(arg[aFillColour]),
                            val_number(arg[aFillAlpha]), wireframe );
   }

   value result = alloc_abstract( k_drawable, obj );
   val_gc( result, delete_drawable );
   return result;
}

static double sFontScale = 1.0/64.0;

class OutlineBuilder : public OutlineIterator
{

public:
   OutlineBuilder(double inX, double inY, const LineJob &inJob,bool inDoSolid) : mBase(inJob)
   {
      mX = inX;
      mY = inY;
      mDoSolid = inDoSolid;
      mDoLines = mBase.mAlpha>0 || mBase.mGradient;
      mPID0 = 0;
   }

   void moveTo(int x,int y)
   {
      if (mDoLines)
      {
         int pid = (int)mPoints.size() - 1;
         if (pid > mPID0+1)
         {
            size_t l = mLines.size();
            mLines.push_back(mBase);
            mLines[l].mOrigPointIndex0 = mPID0;
            mLines[l].mOrigPointIndex1 = pid;
         }
         mPID0 = (int)mPoints.size();
      }

      mPoints.push_back(
         Point( x*sFontScale + mX , y*sFontScale + mY , ptMove ) );
   }
   void lineTo(int x,int y)
   {
      mPoints.push_back(
         Point( x*sFontScale + mX , y*sFontScale + mY , ptLine ) );
   }

   void Complete()
   {
      if (mDoLines)
      {
         int pid = (int)mPoints.size() - 1;
         if (pid > mPID0+1)
         {
            size_t l = mLines.size();
            mLines.push_back(mBase);
            mLines[l].mOrigPointIndex0 = mPID0;
            mLines[l].mOrigPointIndex1 = pid;
         }

      }

      //if (!mPoints.empty())
        //mPoints.push_back( mPoints[0] );

      if (mLines.empty())
      {
         delete mBase.mGradient;
         mBase.mGradient = 0;
      }
   }

   Matrix mMatrix;
 
   Points   mPoints;
   LineJobs mLines;
   int      mPID0;
   double   mX;
   double   mY;

   LineJob mBase;
   bool    mDoLines;
   bool    mDoSolid;
};


// ---- Surface Drawing -----------------------------------------------------

class SurfaceDrawer : public Drawable
{
public:
   SurfaceDrawer(SDL_Surface *inSurface,double inOX, double inOY,
         double inAlpha, bool inHasAlpha=true)
   {
      mTexture = new TextureBuffer(inSurface);
      mAlpha = inAlpha;
      mHasAlpha = inHasAlpha;
      mMaskID = -1;
      Init(inOX,inOY);
   }

   SurfaceDrawer(TextureBuffer *inTexture,double inOX, double inOY)
   {
      mTexture = inTexture;
      mTexture->IncRef();
      mAlpha = 1;
      mHasAlpha = (inTexture->GetSourceSurface()->flags & SDL_SRCALPHA) != 0;
      Init(inOX,inOY);
   }

   void AddToMask(SDL_Surface *inSurf,PolygonMask &ioMask,const Matrix &inMatrix)
   {
      CreateRenderer(inSurf,inMatrix,0);
      if (mRenderer)
         mRenderer->AddToMask(ioMask,0,0);
   }



   void Init(double inOX,double inOY)
   {
      int w = mTexture->Width();
      int h = mTexture->Height();

      mOX = inOX;
      mOY = inOY;
      mRect.x = (Sint16)mOX;
      mRect.y = (Sint16)mOY;
      mRect.w = w;
      mRect.h = h;
      mRenderer = 0;


      for(int i=0;i<4;i++)
      {
         mSX[i] = (Sint16)( mOX + (i==1||i==2) * w + 0.5 );
         mSY[i] = (Sint16)( mOY + (i==2||i==3) * h + 0.5 );
      }
      mSX[4] = mSX[0];
      mSY[4] = mSY[0];
   }
   ~SurfaceDrawer()
   {
       mTexture->DecRef();
       delete mRenderer;
   }

   // SurfaceDrawer
   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty, MaskObject *inMask,
                  const Viewport &inVP )
   {
      #ifdef NME_OPENGL
      mIsOGL =  IsOpenGLScreen(inSurface);
      if (mIsOGL)
      {
         mOGLMatrix = inMatrix;

         bool scissor = false;
         if (IsOpenGLScreen(inSurface) &&
             (inVP.x0>0 || inVP.y0>0 || inVP.x1< inSurface->w || inVP.y1<inSurface->h ) )
         {
            scissor = true;
            glEnable(GL_SCISSOR_TEST);
            glScissor(inVP.x0, inSurface->h - inVP.y1, inVP.Width(), inVP.Height());
         }

         if (mOGLMatrix.IsIdentity() && mOX==0 && mOY==0)
            mTexture->DrawOpenGL();
         else
         {
            glPushMatrix();
            mOGLMatrix.GLMult();
            glTranslated(mOX,mOY,0);
            mTexture->DrawOpenGL();
            glPopMatrix();
         }

         if (scissor)
            glDisable(GL_SCISSOR_TEST);
      }
      else
      #endif // NME_OPENGL
      {
         bool blend = gBlendMode!=BLEND_NORMAL;
         bool int_translation =  inMatrix.IsIntTranslation();
         // SDL_Blit can't do alpha-over-alpha blending
         // Also use this code path for different blend modes...
         if (blend || (int_translation && (!mHasAlpha || !(inSurface->flags & SDL_SRCALPHA) ) ) )
         {
            bool full_vp = inVP.IsWindow(inSurface->w,inSurface->h);

            if (full_vp && inMask==0 && inMatrix.mtx==0 && inMatrix.mty==0 && !blend)
            {
               SDL_BlitSurface(mTexture->GetSourceSurface(), 0, inSurface,&mRect);
               mHitRect = mRect;
               return;
            }

            SDL_Rect dest_rect = mRect;
            dest_rect.x += (int)inMatrix.mtx;
            dest_rect.y += (int)inMatrix.mty;

            if (inMask!=0 || !full_vp)
            {
               Extent2DI extent;
               // Just clip by extent, as per flash api
               if (inMask)
                  inMask->GetExtent(extent);
               if (!extent.Intersect(inVP.x0, inVP.y0, inVP.x1, inVP.y1))
               {
                  memset(&mHitRect,0,sizeof(mHitRect));
                  return;
               }

               int x0 = dest_rect.x;
               int y0 = dest_rect.y;

               // No overlap...
               if (dest_rect.x >= extent.mMaxX || (dest_rect.x+dest_rect.w)<extent.mMinX ||
                   dest_rect.y >= extent.mMaxY || (dest_rect.y+dest_rect.h)<extent.mMinY )
               {
                  mHitRect.w = mHitRect.h = 0;
                  return;
               }
               int diff = extent.mMinX - dest_rect.x;
               if (diff>0)
               {
                  dest_rect.x += diff;
                  dest_rect.w -= diff;
               }

               diff = dest_rect.x + dest_rect.w  - extent.mMaxX;
               if (diff>0)
                  dest_rect.w -= diff;


               diff = extent.mMinY - dest_rect.y;
               if (diff>0)
               {
                  dest_rect.y += diff;
                  dest_rect.h -= diff;
               }

               diff = dest_rect.y + dest_rect.h  - extent.mMaxY;
               if (diff>0)
                  dest_rect.h -= diff;

               SDL_Rect src_rect;
               src_rect.x = dest_rect.x - x0;
               src_rect.y = dest_rect.y - y0;
               src_rect.h = dest_rect.h;
               src_rect.w = dest_rect.w;
               mHitRect = dest_rect;
               if (blend)
                  BlendSurface(mTexture->GetSourceSurface(), &src_rect, inSurface,&dest_rect,gBlendMode);
               else
                  SDL_BlitSurface(mTexture->GetSourceSurface(), &src_rect, inSurface,&dest_rect);
               return;
            }
            else
            {
               mHitRect = dest_rect;
               //SDL_FillRect(inSurface,&dest_rect,0xffff00ff);
               if (blend)
                  BlendSurface(mTexture->GetSourceSurface(), 0, inSurface,&dest_rect,gBlendMode);
               else
                  SDL_BlitSurface(mTexture->GetSourceSurface(), 0, inSurface,&dest_rect);
               return;
            }
         }

         CreateRenderer(inSurface,inMatrix,inMask);

         if (mRenderer)
            mRenderer->Render(inSurface,inVP,0,0);
      }
   }

   // SurfaceDrawer
   void CreateRenderer(SDL_Surface *inSurface,const Matrix &inMatrix, MaskObject *inMask)
   {
      int mid = inMask==0 ? -1 : inMask->GetID();
      if (inMatrix!=mLastMatrix || !mRenderer || mid!=mMaskID)
      {
         mMaskID = mid;

         mLastMatrix = inMatrix;
         for(int i=0;i<5;i++)
            inMatrix.TransformHQCorner( mSX[i], mSY[i], mPoints[i].x, mPoints[i].y );

         Matrix mapping = inMatrix.Invert2x2();
         mapping.MatchTransform(mPoints[0].x/65536.0,
                                mPoints[0].y/65536.0,0,0);


         Uint32 flags= NME_HIGH_QUALITY | NME_EDGE_CLAMP;
         if (!inMatrix.IsIntTranslation())
            flags |= NME_BMP_LINEAR;
         if (mHasAlpha)
            flags |= NME_ALPHA_BLEND;

         delete mRenderer;

         char connect[] = { 0,1,1,1,1 };

         RenderArgs args;
         args.inN = 5;
         args.inPoints = mPoints;
         args.inLines = 0;
         args.inConnect = connect;
         args.inMinY = NME_clip_ymin(inSurface),
         args.inMaxY = NME_clip_ymax(inSurface),
         args.inFlags = flags;


         mRenderer = PolygonRenderer::CreateBitmapRenderer(args,
                       mTexture->GetSourceSurface(), mapping );

         if (inMask)
            mRenderer->Mask(*inMask->GetPolygonMask());

      }
   }



   // SurfaceDrawer
   bool HitTest(int inX,int inY)
   {
      #ifdef NME_OPENGL
      if (mIsOGL)
      {
         GLuint buffer[10];
         glSelectBuffer(10, buffer); 

         glRenderMode(GL_SELECT);

         glMatrixMode(GL_PROJECTION);
         glLoadIdentity();
         glTranslated(-inX,-inY,0);

         glMatrixMode(GL_MODELVIEW);
         glLoadIdentity();
         mOGLMatrix.GLMult();

         glLoadName(1);

         mTexture->DrawOpenGL();

         GLint hits = glRenderMode(GL_RENDER);
         return hits>0;
      }
      else
      #endif // NME_OPENGL
      {
         if (mRenderer && mRenderer->HitTest(inX,inY))
            return true;
         else if (!mRenderer)
         {
            if (inX>= mHitRect.x && inX<mHitRect.x+mHitRect.w &&
                inY>= mHitRect.y && inY<mHitRect.y+mHitRect.h )
               return true;
         }
      }

       return false;

   }

   void GetExtent(Extent2DI &ioExtent,const Matrix &inMatrix,bool inAccurate)
   {
      for(int i=0;i<4;i++)
      {
         int x,y;
         inMatrix.TransformHQ( mSX[i], mSY[i], x, y);

         ioExtent.Add((x+0x10000)>>16,(y+0x10000)>>16);
      }

   }


   TextureBuffer *mTexture;

   bool        mHasAlpha;
   SDL_Rect    mRect;
   SDL_Rect    mHitRect;
   Sint16      mSX[5];
   Sint16      mSY[5];
   PointF16    mPoints[5];
   double      mOX;
   double      mOY;
   double      mAlpha;
   bool        mIsOGL;
   int         mMaskID;
   Matrix      mOGLMatrix;


   Matrix           mLastMatrix;
   PolygonRenderer *mRenderer;
};

//  --- Simple blitting --------------------------------------------------


value nme_create_blit_drawable(value inTexture, value inX, value inY )
{
   val_check( inX, number );
   val_check( inY, number );
   val_check_kind( inTexture, k_texture_buffer );

   TextureBuffer * t = TEXTURE_BUFFER(inTexture);
   Drawable *obj = new SurfaceDrawer( t,
                                      val_number(inX),
                                      val_number(inY));
   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );

   return v;
}





// ---- Text Drawing -----------------------------------------------------


value nme_create_text_drawable(value * arg, int nargs )
{
   enum { aText, aFont, aSize, aX, aY, aColour, aAlpha,
          aBGCol, aAlignX,aAlignY,   aLAST };
   if ( nargs != aLAST )
      hx_failure( "nme_create_text_drawable - bad parameter count." );

   #ifndef NME_TTF
   return val_null;
   #else
   val_check( arg[aText], string );
   val_check( arg[aFont], string );
   val_check( arg[aSize], int );
   val_check( arg[aX], number );
   val_check( arg[aY], number );
   val_check( arg[aColour], int );
   val_check( arg[aAlpha], number );

   int bg = 0xffffff;
   bool transparent_bg = true;
   if (val_is_int(arg[aBGCol]))
   {
      bg = val_int(arg[aBGCol]);
      transparent_bg = false;
   }

   TTF_Font *font = FindOrCreateFont(val_string(arg[aFont]),
                                     val_int(arg[aSize]));
   if (!font)
      return val_null;

   int icol = val_int(arg[aColour]);
   SDL_Color col;
   col.r = (icol>>16) & 0xff;
   col.g = (icol>>8) & 0xff;
   col.b = (icol) & 0xff;

   SDL_Color bgc;
   bgc.r = (bg>>16) & 0xff;
   bgc.g = (bg>>8) & 0xff;
   bgc.b = (bg) & 0xff;
   bgc.g = 0xff;



   SDL_Surface *surface = transparent_bg ?
       TTF_RenderText_Blended(font, val_string(arg[aText]), col ) :
       TTF_RenderText_Shaded(font, val_string(arg[aText]), col,bgc);

   if (!surface)
      return val_null;

   double x = val_number(arg[aX]);
   double y = val_number(arg[aY]);
   if ( val_is_int(arg[aAlignX]) )
   {
      int ax = val_int(arg[aAlignX]);
      if (ax==1)
         x-= surface->w/2;
      else if (ax==2)
         x-= surface->w;
   }

   if ( val_is_int(arg[aAlignY]) )
   {
      int ay = val_int(arg[aAlignY]);
      if (ay==1)
         y-= surface->h/2;
      else if (ay==2)
         y-= surface->h;
   }


   SDL_SetAlpha(surface,SDL_SRCALPHA,255);
   Drawable *obj = new SurfaceDrawer(surface, x, y,
                                     val_number(arg[aAlpha]),
                                     transparent_bg);

   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );
   return v;
   #endif
}



value nme_create_glyph_draw_obj(value * arg, int nargs )
{
   enum { aX, aY, aFont, aChar, aFillCol, aFillAlpha,
          aGradOrTex, aLineStyle, aUseFreeType, aLAST };
   if ( nargs != aLAST )
      hx_failure( "nme_create_glyph_draw_obj - bad parameter count." );

   #ifndef NME_TTF
   return val_null;
   #else

   val_check( arg[aX], number );
   val_check( arg[aY], number );
   val_check( arg[aFillCol], int );
   val_check( arg[aFillAlpha], number );
   val_check( arg[aUseFreeType], bool );
   val_check( arg[aChar], int );

   int col = val_int(arg[aFillCol]);
   int ch = val_int(arg[aChar] );
   double alpha = val_number(arg[aFillAlpha]);
   double x = val_number(arg[aX]);
   double y = val_number(arg[aY]);

   Drawable *obj = 0;

   if (1||val_bool(arg[aUseFreeType]))
   {
      // TODO: Get this working
      if (!val_is_kind(arg[aFont],k_font))
         return val_null;

      TTF_Font *font = FONT(arg[aFont]);

      SDL_Color sdl_col;
      sdl_col.r = (col>>16) & 0xff;
      sdl_col.g = (col>>8) & 0xff;
      sdl_col.b = (col) & 0xff;

      char str[2] = { ch, 0 };

      SDL_Surface *surface = TTF_RenderText_Blended(font,str, sdl_col );

      if (!surface)
         return val_null;

      //printf("Create renderer %f %f (%s) %f\n",x,y,str,alpha);
      //printf("Surface %dx%d\n", surface->w, surface->h );
      //printf("col %d,%d,%d\n",  sdl_col.r, sdl_col.g, sdl_col.b );
      SDL_SetAlpha(surface,SDL_SRCALPHA,255);

      obj = new SurfaceDrawer(surface, x, y, 1.0, true );
      /*
      int *p = (int *)(surface->pixels  );
      for(int y=0;y<surface->h;y++)
      {
         for(int x=0;x<surface->w;x++)
         {
           printf( *p==0 ? "." : "X");
           p++;
         }
         printf("\n");
      }
      */
   }
   else
   {
      LineJob job;
      job.FromValue(arg[aLineStyle]);
   
      Gradient *grad = CreateGradient(arg[aGradOrTex]);
      TextureReference *tex = TextureReference::Create(arg[aGradOrTex]);
   
      OutlineBuilder builder(x, y, job,alpha>0 || grad || tex);
   
      IterateOutline(arg[aFont],ch,&builder);
   
      builder.Complete();
   
      obj = new DrawObject( builder.mPoints, col, alpha,
                            grad, tex, builder.mLines, true );
   }
   
   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );
   return v;
   #endif
}



value nme_get_extent(value inDrawList,value ioRect,value inMatrix,value inAccurate)
{
   Extent2DI extent;

   Matrix matrix(inMatrix);

   bool accurate = val_bool(inAccurate);

   val_check(inDrawList,array);
	value *ptr = val_array_value(inDrawList);
   int n =  val_array_size(inDrawList);

   // printf("nme_get_extent\n");
   for(int i=0;i<n;i++)
   {
      Drawable *d = DRAWABLE(ptr ? ptr[i] : val_array_i(inDrawList,i));
      if (d)
         d->GetExtent(extent,matrix,accurate);
   }


   alloc_field( ioRect, val_id_x, alloc_float(extent.mMinX) );
   alloc_field( ioRect, val_id_y, alloc_float(extent.mMinY) );
   alloc_field( ioRect, val_id_width, alloc_float(extent.Width()) );
   alloc_field( ioRect, val_id_height, alloc_float(extent.Height()));

   return alloc_int( extent.Valid() ? 1 : 0);
}


// -----------------------------------------------------------------------



void delete_drawable( value drawable )
{
   if ( val_is_kind( drawable, k_drawable ) )
   {
      //val_gc( drawable, NULL );
      Drawable *d = DRAWABLE(drawable);
      delete d;
   }
}

void delete_mask_object( value mask )
{
   if ( val_is_kind( mask, k_mask ) )
   {
      val_gc( mask, NULL );

      MaskObject *m = MASK(mask);
      delete m;
   }
}



value nme_draw_object_to(value drawable,value surface,value matrix,
                         value inMask, value inScrollRect )
{
   if ( val_is_kind( drawable, k_drawable ) )
   {
      SDL_Surface *s = 0;
      MaskObject *mask = 0;
      TextureBuffer *tex = 0;

      if ( val_is_kind( surface, k_surf )  )
      {
         s = SURFACE(surface);
      }
      else if ( val_is_kind( surface, k_texture_buffer )  )
      {
         tex = TEXTURE_BUFFER(surface);
         s = tex->GetSourceSurface();
      }

      if ( val_is_kind( inMask, k_mask )  )
      {
         mask = MASK(inMask);
      }

      if (s)
      {
         Matrix mtx(matrix);
         Viewport vp( 0,0, s->w, s->h );
         if (!val_is_null(inScrollRect))
         {
            int x0 = (int)val_number( val_field(inScrollRect,val_id_x) );
            int y0 = (int)val_number( val_field(inScrollRect,val_id_y) );
            int x1 = x0+(int)val_number( val_field(inScrollRect,val_id_width) );
            int y1 = y0+(int)val_number( val_field(inScrollRect,val_id_height) );
            if (x0>=x1) return val_null;
            if (y0>=y1) return val_null;
            vp.SetWindow(x0,y0,x1,y1);
         }

         Drawable *d = DRAWABLE(drawable);
         d->RenderTo(s,mtx,tex,mask,vp);
      }
   }
   return alloc_int(0);
}

value nme_add_to_mask(value inDrawList,value inSurface,value inMask, value inMatrix )
{
   val_check_kind( inSurface, k_surf );
   val_check( inDrawList, array );
   SDL_Surface *surf = SURFACE(inSurface);

   val_check_kind( inMask, k_mask );
   MaskObject *mask_object = MASK(inMask);
   PolygonMask *mask = mask_object->GetPolygonMask();

   int n = val_array_size(inDrawList);
   Matrix matrix(inMatrix);

   for(int i=0;i<n;i++)
   {
      Drawable *d = DRAWABLE(val_array_i(inDrawList,i));
      if (d)
         d->AddToMask(surf,*mask,matrix);
   }



   return alloc_int(0);
}

value nme_create_mask()
{
   MaskObject *mask = MaskObject::Create();

   value v = alloc_abstract( k_mask, mask );
   val_gc( v, delete_mask_object );

   return v;
}


value nme_hit_object(value drawable,value x,value y )
{
      if ( val_is_kind( drawable, k_drawable ) )
      {
         /*
         hxObject *h = drawable.GetPtr();
         Abstract_obj *obj = dynamic_cast<Abstract_obj *>(h);
         void *p = obj->__GetHandle();
         */
         Drawable *d = DRAWABLE(drawable);
         return alloc_bool(d->HitTest(val_int(x),val_int(y)));
      }
   return alloc_bool(false);
}

value nme_set_scale9_grid(value inRect,value inSX, value inSY,value inExtent)
{
   if (val_is_null(inRect))
      gScale9.Deactivate();
   else
   {
      gScale9.Activate(
       (double)val_number(val_field(inRect,val_id_x)),
       (double)val_number(val_field(inRect,val_id_y)),
       (double)val_number(val_field(inRect,val_id_width)),
       (double)val_number(val_field(inRect,val_id_height)),
       (double)val_number(inSX),
       (double)val_number(inSY),
       (double)val_number(val_field(inExtent,val_id_x)),
       (double)val_number(val_field(inExtent,val_id_y)),
       (double)val_number(val_field(inExtent,val_id_width)),
       (double)val_number(val_field(inExtent,val_id_height))  );
   }
   return val_null;
}


value nme_set_draw_quality(value inValue)
{
   sQualityLevel = val_int(inValue);
   return inValue;
}

value nme_get_draw_quality()
{
   return alloc_int(sQualityLevel);
}

value nme_set_blend_mode(value inVal)
{
   gBlendMode = val_int(inVal);
   return val_null;
}



DEFINE_PRIM(nme_create_draw_obj, 5);
DEFINE_PRIM_MULT(nme_create_draw_triangles);
DEFINE_PRIM_MULT(nme_create_glyph_draw_obj);
DEFINE_PRIM(nme_create_blit_drawable, 3);
DEFINE_PRIM(nme_get_extent, 4);
DEFINE_PRIM(nme_draw_object_to, 5);
DEFINE_PRIM(nme_hit_object, 3);
DEFINE_PRIM(nme_set_draw_quality, 1);
DEFINE_PRIM(nme_set_scale9_grid, 4);
DEFINE_PRIM(nme_get_draw_quality, 0);
DEFINE_PRIM(nme_set_blend_mode, 1);
DEFINE_PRIM(nme_create_mask, 0);
DEFINE_PRIM(nme_add_to_mask, 4);
DEFINE_PRIM_MULT(nme_create_text_drawable);

int __force_draw_object = 0;
