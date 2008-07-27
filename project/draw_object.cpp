#include <SDL.h>
#include <string>
#include <neko.h>

#ifdef __WIN32__
#include <windows.h>
#endif
#include <GL/gl.h>

#include <vector>

#include "nme.h"
#include "nsdl.h"
#include "renderer/Renderer.h"
#include "Matrix.h"
#include "texture_buffer.h"
#include "text.h"
#include "Gradient.h"
#include "renderer/Points.h"


DECLARE_KIND( k_drawable );
DEFINE_KIND( k_drawable );

DECLARE_KIND( k_mask );
DEFINE_KIND( k_mask );

#define DRAWABLE(v) ( (Drawable *)(val_data(v)) )
#define MASK(v) ( (MaskObject *)(val_data(v)) )


static int sQualityLevel = 1;


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



// --- Base class -----------------------------------------------------


class Drawable
{
public:
   virtual ~Drawable() { }
   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty,MaskObject *inMask,const Viewport &inVP)=0;
   virtual bool HitTest(int inX,int inY) = 0;

   virtual void GetExtent(Extent2DI &ioExtent, const Matrix &inMat,
                  bool inExtent)=0;

   virtual void AddToMask(SDL_Surface *inSurf,PolygonMask &ioMask,const Matrix &inMatrix)=0;

   virtual bool IsGrad() { return false; }
};


void delete_drawable( value drawable );


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


class DrawObject : public Drawable
{
public:
   DrawObject(Points &inPoints, int inFillColour,double inFillAlpha,
              Gradient *inFillGradient,
              TextureReference *inTexture,
              LineJobs &inLines,
              bool inLinesShareGrad = false) :
                 mTransform(0,0,0,0)
   {
      mDisplayList = 0;
      mPolygon = 0;
      mLinesShareGrad = inLinesShareGrad;
      mSolidGradient = inFillGradient;
      mTexture = inTexture;
      mOldFlags = sQualityLevel>0 ? NME_HIGH_QUALITY : 0;
      mMinY = -1;
      mMaxY = -1;
      mOrigPoints.swap(inPoints);
      mMaskID = -1;
      mIsOGL = false;
      mRendersWithoutDisplayList = 0;

      if (mSolidGradient || mTexture)
      {
         mFillColour = 0xffffff;
         mFillAlpha = 1.0;
      }
      else
      {
         mFillColour = inFillColour;
         mFillAlpha = inFillAlpha;
      }

      mLineJobs.swap(inLines);
      mCurveScale = 0.0;

   }

   void BuildCurved(const Points &inPoints,double inScale)
   {
      size_t n = inPoints.size();
      IntVec remap(n);

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
      delete mPolygon;
      mPolygon = 0;

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
      if (mDisplayList!=0)
         glDeleteLists(mDisplayList,1);
   }


   void DrawOpenGL()
   {
      size_t n = mPoints.size();
      if (n==0)
         return;

      glDisable(GL_DEPTH_TEST);
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
      if (mSolidGradient || mFillAlpha>0 || mTexture)
      {
         // TODO: tesselate
         glColor4ub(mFillColour >> 16, mFillColour >> 8, mFillColour,
                      (unsigned char)(mFillAlpha*255.0));
         const CurvedPoint *p = &mPoints[0];
         size_t n = mPoints.size();
         TextureBuffer *tex = mTexture ? mTexture->mTexture : 0;

         if (mSolidGradient)
            mSolidGradient->BeginOpenGL();
         else if (tex)
            tex->BindOpenGL( (mTexture->mFlags & NME_EDGE_MASK) ==NME_EDGE_REPEAT );
         else
            glDisable(GL_TEXTURE_2D);

         glBegin(GL_TRIANGLE_FAN);
         for(size_t i=0;i<n;i++)
         {
            if (mSolidGradient)
               mSolidGradient->OpenGLTexture( mPoints[i].mX, mPoints[i].mY );
            else if (tex)
               mTexture->OpenGLTexture( mPoints[i].mX, mPoints[i].mY,
                                  mTexture->mTransMatrix);

            glVertex2f( mPoints[i].mX, mPoints[i].mY );
            p++;
         }
         glEnd();

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
            glColor4ub(col >>16,col >> 8,col,
                 (unsigned char)(line.mAlpha*255.0));
         }

         glLineWidth( (float)line.mThickness );

         size_t n = line.mPointIndex1 - line.mPointIndex0 + 1;
         glBegin(GL_LINE_STRIP);
         for(size_t i=0;i<n;i++)
         {
            size_t pid = line.mPointIndex0 + i;
            if (line.mGradient)
               line.mGradient->OpenGLTexture( mPoints[pid].mX,mPoints[pid].mY );
            glVertex2f( mPoints[pid].mX, mPoints[pid].mY );
         }
         glEnd();
      
         if (line.mGradient)
            line.mGradient->EndOpenGL();
      }
      glLineWidth(1);

      glDisable(GL_BLEND);
   }

   bool CreateDisplayList()
   {
      mDisplayList = glGenLists(1);
      glNewList(mDisplayList,GL_COMPILE);
      DrawOpenGL();
      glEndList();

      return true;
   }

   virtual void GetExtent(Extent2DI &ioExtent,const Matrix &inMatrix, bool inAccurate)
   {
      if (inAccurate)
      {
         SetupCurved(inMatrix);

         CreateRenderers(0,inMatrix,0);
         mMaskID = -1;

         if (mPolygon)
            mPolygon->GetExtent(ioExtent);

         for(size_t j=0;j<mLineJobs.size();j++)
            mLineJobs[j].mRenderer->GetExtent(ioExtent);
      }
      else
      {
         TransformPoints(inMatrix);
         size_t n = mPointF16s.size();
         for(size_t i=0;i<n;i++)
            ioExtent.Add(mPointF16s[i]);
      }
   }


   void TransformPoints(const Matrix &inMatrix)
   {
      size_t n = mPoints.size();
      mTransform = inMatrix;
      mTX = 0;
      mTY = 0;

      if (mTransform.IsIdentity())
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
     else
     {
        for(size_t i=0;i<n;i++)
        {
           mTransform.TransformHQ(mPoints[i].mX,mPoints[i].mY,
               mPointF16s[i].x,mPointF16s[i].y);
        }

        if (mSolidGradient)
           mSolidGradient->Transform(mTransform);
        else if (mTexture)
           mTexture->Transform(mTransform);

         for(size_t i=0;i<mLineJobs.size();i++)
         {
            LineJob &job = mLineJobs[i];
            if (job.mGradient)
               job.mGradient->Transform(mTransform);
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

   virtual bool IsGrad() { return mPolygon!=0 || mSolidGradient!=0; }

   void SetupCurved(const Matrix &inMatrix)
   {
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

      mIsOGL =  IsOpenGLScreen(inSurface);
      if (mIsOGL)
      {
         mOGLMatrix = inMatrix;
         if (!mDisplayList && mRendersWithoutDisplayList>1)
            CreateDisplayList();

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
            if (mDisplayList)
               glCallList(mDisplayList);
            else
            {
               mRendersWithoutDisplayList++;
               DrawOpenGL();
            }
         }
         else
         {
            glPushMatrix();
            inMatrix.GLMult();
            if (mDisplayList)
               glCallList(mDisplayList);
            else
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
      {
         PolygonMask *mask = inMaskObj ? inMaskObj->GetPolygonMask() : 0;
         CreateRenderers(inSurface,inMatrix,inMarkDirty,inMaskObj);
         // printf("RenderTo %p\n",inMaskObj);

         if (mPolygon)
            mPolygon->Render(inSurface,inVP,mTX,mTY);

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
      CreateRenderers(inSurf,inMatrix,false);
      if (mPolygon)
         mPolygon->AddToMask(ioMask);
   }

   // DrawObject
   bool HitTest(int inX,int inY)
   {
      if (mIsOGL)
      {
         // Line width seems to get ignored when picking?
         if (mDisplayList)
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
      {
         if (mPolygon && mPolygon->HitTest(inX-mTX,inY-mTY))
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
            const Matrix &inMatrix,TextureBuffer *inMarkDirty,MaskObject *inMaskObj=0)
   {

      if (mPoints.empty())
         return;

      int min_y = -0x7fff;
      int max_y =  0x7fff;

      // Limit creation to visible lines ?
      //  Pro: do not need to calculate some lines
      //  Con: need to recalculate visible lines if transform changes.
      /*
      if (inSurface)
      {
         min_y =  NME_clip_ymin(inSurface);
         max_y =  NME_clip_ymax(inSurface);

         if (inSurface && IsOpenGLScreen(inSurface))
         {
            min_y = 0;
            max_y = inSurface->h;
         }
      }

      if (min_y!=mMinY || max_y!=mMaxY)
      {
         // printf("Different extent!\n");
         mMinY = min_y;
         mMaxY = max_y;
         ClearRenderers();
      }
      */

      if (!mTransform.IsIntTranslation(inMatrix,mTX,mTY))
      {
         TransformPoints(inMatrix);
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
         inMaskObj->ClipY(min_y);
         inMaskObj->ClipY(max_y);
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

         if (!mPolygon)
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
               mPolygon = PolygonRenderer::CreateGradientRenderer(args,
                              mSolidGradient );
            }
            else if (mTexture)
            { 
               //Matrix m(mTexture->mTransMatrix);

               args.inFlags |= mTexture->mFlags;
               mPolygon = PolygonRenderer::CreateBitmapRenderer(args,
                              mTexture->mTexture->GetSourceSurface(),
                              mTexture->mTransMatrix);
            }
            else
            {
               mPolygon = PolygonRenderer::CreateSolidRenderer(args,
                              mFillColour, mFillAlpha );
            }
            if (mPolygon && mask)
               mPolygon->Mask(*mask);
         }

      }

      size_t jobs = mLineJobs.size();
      for(size_t j=0;j<jobs;j++)
      {
         LineJob &job = mLineJobs[ j ];
         if (!job.mRenderer)
         {
            RenderArgs args;
            args.inN = (int)mPointF16s.size();
            args.inPoints = &mPointF16s[0];
            args.inLines = &job;
            args.inConnect = 0;
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




   Points             mOrigPoints;
   CurvedPoints       mPoints;
   std::vector<char>  mConnection;

   Gradient     *mSolidGradient;
   TextureReference *mTexture;
   int          mFillColour;
   unsigned int mOldFlags;
   double       mFillAlpha;
   double       mCurveScale;
   LineJobs     mLineJobs;

   std::vector<PointF16> mPointF16s;

   GLuint       mDisplayList;
   // It is expensive to recreate the display list every frame.
   int          mRendersWithoutDisplayList;

   bool         mIsOGL;
   Matrix       mOGLMatrix;

   Matrix       mTransform;
   int          mTX;
   int          mTY;
   int          mMinY;
   int          mMaxY;
   int          mMaskID;

   PolygonRenderer *mPolygon;

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
   value *items = val_array_ptr(inPoints);

   Points points(n);
   for(int i=0;i<n;i++)
      points[i].FromValue(items[i]);

   n = val_array_size(inLines);
   LineJobs lines(n);
   items = val_array_ptr(inLines);
   for(int j=0;j<n;j++)
      lines[j].FromValue(items[j]);

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
            mLines[l].mPointIndex0 = mPID0;
            mLines[l].mPointIndex1 = pid;
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
            mLines[l].mPointIndex0 = mPID0;
            mLines[l].mPointIndex1 = pid;
         }

      }

      //if (!mPoints.empty())
        //mPoints.push_back( mPoints[0] );

      if (mLines.empty())
         delete mBase.mGradient;
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
         mRenderer->AddToMask(ioMask);
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
      {
         if (inMatrix.IsIntTranslation())
         {
            bool full_vp = inVP.IsWindow(inSurface->w,inSurface->h);

            if (full_vp && inMask==0 && inMatrix.mtx==0 && inMatrix.mty==0)
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
               SDL_BlitSurface(mTexture->GetSourceSurface(), &src_rect, inSurface,&dest_rect);
               return;
            }
            else
            {
               mHitRect = dest_rect;
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


         Uint32 flags= NME_HIGH_QUALITY | NME_EDGE_CLAMP | NME_BMP_LINEAR;
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
                                      val_number(inY) );
   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );

   return v;
}





// ---- Text Drawing -----------------------------------------------------


value nme_create_text_drawable( value* arg, int nargs )
{
   enum { aText, aFont, aSize, aX, aY, aColour, aAlpha,
          aBGCol, aAlignX,aAlignY,   aLAST };
   if ( nargs != aLAST )
      failure( "nme_create_text_drawable - bad parameter count." );

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
}



value nme_create_glyph_draw_obj(value* arg, int nargs )
{
   enum { aX, aY, aFont, aChar, aFillCol, aFillAlpha,
          aGradOrTex, aLineStyle, aUseFreeType, aLAST };
   if ( nargs != aLAST )
      failure( "nme_create_glyph_draw_obj - bad parameter count." );


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

   Drawable *obj;

   if (val_bool(arg[aUseFreeType]))
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
}






value nme_get_extent(value inDrawList,value ioRect,value inMatrix,value inAccurate)
{
   Extent2DI extent;

   Matrix matrix(inMatrix);

   bool accurate = val_bool(inAccurate);
   
   value objs_arr =  val_field(inDrawList,val_id___a);
   val_check( objs_arr, array );

   int n =  val_int( val_field(inDrawList,val_id_length));
   value *objs =  val_array_ptr(objs_arr);

   // printf("nme_get_extent\n");
   for(int i=0;i<n;i++)
   {
      Drawable *d = DRAWABLE(objs[i]);
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
      val_gc( drawable, NULL );

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
            if (x0>x1) std::swap(x0,x1);
            if (y0>y1) std::swap(y0,y1);
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
   SDL_Surface *surf = SURFACE(inSurface);

   val_check_kind( inMask, k_mask );
   MaskObject *mask_object = MASK(inMask);
   PolygonMask *mask = mask_object->GetPolygonMask();

   value objs_arr =  val_field(inDrawList,val_id___a);
   val_check( objs_arr, array );

   Matrix matrix(inMatrix);

   int n =  val_int( val_field(inDrawList,val_id_length));
   value *objs =  val_array_ptr(objs_arr);

   for(int i=0;i<n;i++)
   {
      Drawable *d = DRAWABLE(objs[i]);
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
         Drawable *d = DRAWABLE(drawable);
         return alloc_bool(d->HitTest(val_int(x),val_int(y)));
      }
   return alloc_bool(false);
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


DEFINE_PRIM(nme_create_draw_obj, 5);
DEFINE_PRIM_MULT(nme_create_glyph_draw_obj);
DEFINE_PRIM(nme_create_blit_drawable, 3);
DEFINE_PRIM(nme_get_extent, 4);
DEFINE_PRIM(nme_draw_object_to, 5);
DEFINE_PRIM(nme_hit_object, 3);
DEFINE_PRIM(nme_set_draw_quality, 1);
DEFINE_PRIM(nme_get_draw_quality, 0);
DEFINE_PRIM(nme_create_mask, 0);
DEFINE_PRIM(nme_add_to_mask, 4);
DEFINE_PRIM_MULT(nme_create_text_drawable);


