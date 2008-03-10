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
#include "spg/SPriG.h"
#include "Matrix.h"
#include "texture_buffer.h"
#include "text.h"
#include "Extras.h"
#include "Gradient.h"
#include "Points.h"


DECLARE_KIND( k_drawable );
DEFINE_KIND( k_drawable );

#define DRAWABLE(v) ( (Drawable *)(val_data(v)) )


static int sQualityLevel = 1;


// --- Base class -----------------------------------------------------


class Drawable
{
public:
   virtual ~Drawable() { }
   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty=0)=0;
   virtual bool HitTest(SDL_Surface *inSurface,const Matrix &inMatrix,int inX,int inY) = 0;

   virtual void GetExtent(Extent2DI &ioExtent, const Matrix &inMat)=0;

   virtual bool IsGrad() { return false; }
};


void delete_drawable( value drawable );



// --- For drawing geometry -----------------------------------------

struct Point
{
   float mX,mY;

   inline Point(){}
   inline Point(double inX,double inY) : mX( (float)inX), mY( (float)inY) { }

   void FromValue(value inVal)
   {
      mX = (float)val_number(val_field(inVal,val_id("x")));
      mY = (float)val_number(val_field(inVal,val_id("y")));
   }
};

typedef std::vector<Point> Points;

struct LineJob : public PolyLine
{
   int             mColour;
   double          mAlpha;
   unsigned int    mFlags;
   Gradient        *mGradient;
   Matrix          mMappinMatrix;
   PolygonRenderer *mRenderer;

   void FromValue(value inVal)
   {
      mRenderer = 0;
      mGradient = CreateGradient(val_field(inVal,val_id("grad")));
      mColour = val_int(val_field(inVal,val_id("colour")));
      mThickness = val_number(val_field(inVal,val_id("thickness")));
      mAlpha = val_number(val_field(inVal,val_id("alpha")));
      mJoints = val_int(val_field(inVal,val_id("joints")));
      mCaps = val_int(val_field(inVal,val_id("caps")));
      mPixelHinting = val_int(val_field(inVal,val_id("pixel_hinting")));
      mMiterLimit = val_number(val_field(inVal,val_id("miter_limit")));

      value idx_obj = val_field(inVal,val_id("point_idx"));
      if (idx_obj!=val_null)
      {
         value idx = val_field(idx_obj,val_id("__a"));
         //int n = val_array_size(idx);
         int n =  val_int( val_field(idx_obj,val_id("length")));
         value *items = val_array_ptr(idx);
         mPointIndex.resize(n);
         for(int i=0;i<n;i++)
            mPointIndex[i] = val_int(items[i]);
      }
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
              bool inLinesShareGrad = false)
   {
      mDisplayList = 0;
      mPolygon = 0;
      mLinesShareGrad = inLinesShareGrad;
      mSolidGradient = inFillGradient;
      mTexture = inTexture;
      mOldFlags = sQualityLevel>0 ? SPG_HIGH_QUALITY : 0;
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

      mPoints.swap(inPoints);
      mLineJobs.swap(inLines);

      int n = (int)mPoints.size();
      mPointF16s = new PointF16[n];
      TransformPoints(mTransform);
   }

   void ClearRenderers()
   {
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
      delete [] mPointF16s;
   }


   void DrawOpenGL()
   {
      size_t n = mPoints.size();

      glDisable(GL_DEPTH_TEST);
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
      if (mSolidGradient || mFillAlpha>0)
      {
         // TODO: tesselate
         glColor4ub(mFillColour >> 16, mFillColour >> 8, mFillColour,
                      (unsigned char)(mFillAlpha*255.0));
         const Point *p = &mPoints[0];
         size_t n = mPoints.size();
         TextureBuffer *tex = mTexture ? mTexture->mTexture : 0;

         if (mSolidGradient)
            mSolidGradient->BeginOpenGL();
         else if (tex)
            tex->BindOpenGL( (mTexture->mFlags & SPG_EDGE_MASK)
                                   ==SPG_EDGE_REPEAT );
         else
            glDisable(GL_TEXTURE_2D);

         glBegin(GL_TRIANGLE_FAN);
         for(size_t i=0;i<n;i++)
         {
            if (mSolidGradient)
               mSolidGradient->OpenGLTexture( mPoints[i].mX, mPoints[i].mY );
            else if (tex)
               mTexture->OpenGLTexture( mPoints[i].mX, mPoints[i].mY,
                                  mTexture->mOrigMatrix);

            glVertex2f( mPoints[i].mX, mPoints[i].mY );
            p++;
         }

         if (tex)
            tex->UnBindOpenGL();
         glEnd();
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

         size_t n = line.mPointIndex.size();
         glBegin(GL_LINE_STRIP);
         for(size_t i=0;i<n;i++)
         {
            int pid = line.mPointIndex[i];
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

   virtual void GetExtent(Extent2DI &ioExtent,const Matrix &inMatrix)
   {
      if (inMatrix!=mTransform)
         TransformPoints(inMatrix);

      size_t n = mPoints.size();
      for(size_t i=0;i<n;i++)
         ioExtent.Add(mPointF16s[i]);

      for(size_t j=0;j<mLineJobs.size();j++)
      {
         LineJob &line = mLineJobs[j];

         double extra = 0.5;
         if (line.mJoints == SPG_CORNER_MITER)
            extra += line.mMiterLimit;
         int w = int((line.mThickness*extra + 0.999)*65536.0);

         const IntVec &pids = line.mPointIndex;
         for(size_t i=0;i<pids.size();i++)
         {
            const PointF16 &p = mPointF16s[pids[i]];

            ioExtent.Add(p.x+w,p.y+w);
            ioExtent.Add(p.x-w,p.y-w);
         }
      }

   }


   void TransformPoints(const Matrix &inMatrix)
   {
      size_t n = mPoints.size();
      mTransform = inMatrix;

      if (mTransform.IsIdentity())
      {
         for(size_t i=0;i<n;i++)
            mPointF16s[i] = PointF16(mPoints[i].mX+0.5,mPoints[i].mY+0.5);

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
            if (mLineJobs[i].mGradient)
               mLineJobs[i].mGradient->Transform(mTransform);
     }
   }

   virtual bool IsGrad() { return mPolygon!=0 || mSolidGradient!=0; }

   void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty=0)
   {

      if (IsOpenGLScreen(inSurface))
      {
         if (mDisplayList || CreateDisplayList() )
         {
            if (inMatrix.IsIdentity())
               glCallList(mDisplayList);
            else
            {
               glPushMatrix();
               inMatrix.GLMult();
               glCallList(mDisplayList);
               glPopMatrix();
            }
         }
      }
      else
      {
         CreateRenderers(inSurface,inMatrix,inMarkDirty);

         if (mPolygon)
            mPolygon->Render(inSurface);

         size_t jobs = mLineJobs.size();
         for(size_t j=0;j<jobs;j++)
         {
            LineJob &job = mLineJobs[ j ];

            if (job.mRenderer)
               job.mRenderer->Render(inSurface);
         }
      }
   }

   bool HitTest(SDL_Surface *inSurface,const Matrix &inMatrix,int inX,int inY)
   {
      //TODO: opengl acceleration

         CreateRenderers(inSurface,inMatrix,0);

         if (mPolygon && mPolygon->HitTest(inX,inY))
            return true;

         size_t jobs = mLineJobs.size();
         for(size_t j=0;j<jobs;j++)
         {
            LineJob &job = mLineJobs[ j ];

            if (job.mRenderer && job.mRenderer->HitTest(inX,inY))
               return true;
         }

       return false;
   }


   void CreateRenderers(SDL_Surface *inSurface,
            const Matrix &inMatrix,TextureBuffer *inMarkDirty)
   {
         if (inMatrix!=mTransform)
         {
            TransformPoints(inMatrix);
            // TODO: allow for the possibility of simple translation...
            ClearRenderers();
         }

         unsigned int flags = sQualityLevel>0 ? SPG_HIGH_QUALITY : 0;
         if (flags!=mOldFlags)
         {
            mOldFlags = flags;
            ClearRenderers();
         }

         Uint16 n = (Uint16)mPoints.size();


         if (mSolidGradient || mFillAlpha>0)
         {
            if (inMarkDirty)
            {
               size_t n = mPoints.size();
               for(size_t i=0;i<n;i++)
               {
                  int x = mPointF16s[i].x>>16;
                  int y = mPointF16s[i].y>>16;
                  inMarkDirty->SetExtentDirty(x,y,x+1,y+1);
               }
            }

            if (!mPolygon)
            {
               if (mSolidGradient)
               {
                  mPolygon = PolygonRenderer::CreateGradientRenderer(n-1,
                                 mPointF16s,
                                 SPG_clip_ymin(inSurface),
                                 SPG_clip_ymax(inSurface),
                                 flags, mSolidGradient );
               }
               else if (mTexture)
               {
                  flags |= mTexture->mFlags;
                  mPolygon = PolygonRenderer::CreateBitmapRenderer(n-1,
                                 mPointF16s,
                                 SPG_clip_ymin(inSurface),
                                 SPG_clip_ymax(inSurface),
                                 flags,
                                 mTexture->mTransMatrix,
                                 mTexture->mTexture->GetSourceSurface() );
               }
               else
               {
                  mPolygon = PolygonRenderer::CreateSolidRenderer(n-1,
                                 mPointF16s,
                                 SPG_clip_ymin(inSurface),
                                 SPG_clip_ymax(inSurface),
                                 flags, mFillColour, mFillAlpha );
               }

            }

         }

         size_t jobs = mLineJobs.size();
         for(size_t j=0;j<jobs;j++)
         {
            LineJob &job = mLineJobs[ j ];
            if (!job.mRenderer)
            {
               if (job.mGradient)
               {
                  job.mRenderer = PolygonRenderer::CreateGradientRenderer(n,
                                 mPointF16s,
                                 SPG_clip_ymin(inSurface),
                                 SPG_clip_ymax(inSurface),
                                 flags, job.mGradient, &job );

               }
               else
               {
                  job.mRenderer = PolygonRenderer::CreateSolidRenderer(n,
                                 mPointF16s,
                                 SPG_clip_ymin(inSurface),
                                 SPG_clip_ymax(inSurface),
                                 flags, job.mColour, job.mAlpha, &job );
               }
            }

         }
   }




   Points       mPoints;
   Gradient     *mSolidGradient;
   TextureReference *mTexture;
   int          mFillColour;
   unsigned int mOldFlags;
   double       mFillAlpha;
   LineJobs     mLineJobs;

   PointF16     *mPointF16s;

   GLuint       mDisplayList;

   Matrix       mTransform;

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
   OutlineBuilder(double inX,double inY,
                  const LineJob &inJob,bool inDoSolid) : mBase(inJob)
   {
      mX = inX;
      mY = inY;
      mDoSolid = inDoSolid;
      mDoLines = mBase.mAlpha>0 || mBase.mGradient;
   }

   void moveTo(int x,int y)
   {
      if (!mPoints.empty())
        mPoints.push_back( mPoints[0] );

      size_t pid = mPoints.size();
      mPoints.push_back( Point(mX+x*sFontScale,mY+y*sFontScale ) );
      if (mDoLines)
      {
         mLines.push_back(mBase);
         mLines[mLines.size()-1].mPointIndex.push_back((int)pid);
      }
   }
   void lineTo(int x,int y)
   {
      size_t pid = mPoints.size();
      mPoints.push_back( Point(mX+x*sFontScale,mY+y*sFontScale ) );
      if (mDoLines)
         mLines[mLines.size()-1].mPointIndex.push_back((int)pid);
   }

   void Complete()
   {
      if (!mPoints.empty())
        mPoints.push_back( mPoints[0] );
      if (mLines.empty())
         delete mBase.mGradient;
   }

   double   mX,mY;
 
   Points   mPoints;
   LineJobs mLines;

   LineJob mBase;
   bool    mDoLines;
   bool    mDoSolid;
};

value nme_create_glyph_draw_obj(value* arg, int nargs )
{
   enum { aX, aY, aFont, aChar, aFillCol, aFillAlpha, aGradOrTex, aLineStyle, aLAST };
   if ( nargs != aLAST )
      failure( "nme_create_glyph_draw_obj - bad parameter count." );


   val_check( arg[aX], number );
   val_check( arg[aY], number );
   val_check( arg[aFillCol], int );
   val_check( arg[aFillAlpha], number );
   val_check( arg[aChar], int );

   int ch = val_int(arg[aChar] );

   LineJob job;
   job.FromValue(arg[aLineStyle]);

   double alpha = val_number(arg[aFillAlpha]);
   Gradient *grad = CreateGradient(arg[aGradOrTex]);
   TextureReference *tex = TextureReference::Create(arg[aGradOrTex]);

   OutlineBuilder builder(val_number(arg[aX]),val_number(arg[aY]),
       job,alpha>0 || grad || tex);

   IterateOutline(arg[aFont],ch,&builder);

   builder.Complete();


   DrawObject *obj = new DrawObject(
                            builder.mPoints,
                            val_int(arg[aFillCol]),
                            alpha,
                            grad,
                            tex,
                            builder.mLines,
                            true );

   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );
   return v;
}


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
      Init(inOX,inOY);
   }

   SurfaceDrawer(TextureBuffer *inTexture,double inOX, double inOY)
   {
      mTexture = inTexture;
      mTexture->IncRef();
      mAlpha = 1;
      mHasAlpha = inTexture->GetSourceSurface()->format->BitsPerPixel==32;
      Init(inOX,inOY);
   }


   void Init(double inOX,double inOY)
   {
      int w = mTexture->Width();
      int h = mTexture->Height();

      mOX = inOX;
      mOY = inOY;
      mRect.x = (Sint16)inOX;
      mRect.y = (Sint16)inOY;
      mRect.w = w;
      mRect.h = h;
      mRenderer = 0;


      for(int i=0;i<4;i++)
      {
         mSX[i] = (Sint16)( mOX + (i==1||i==2) * w + 0.5 );
         mSY[i] = (Sint16)( mOY + (i==2||i==3) * h + 0.5 );
      }
   }
   ~SurfaceDrawer()
   {
       mTexture->DecRef();
       delete mRenderer;
   }

   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix,
                  TextureBuffer *inMarkDirty=0)
   {
      if (IsOpenGLScreen(inSurface))
      {
         if (inMatrix.IsIdentity() && mOX==0 && mOY==0)
            mTexture->DrawOpenGL();
         else
         {
            glPushMatrix();
            inMatrix.GLMult();
            glTranslated(mOX,mOY,0);
            mTexture->DrawOpenGL();
            glPopMatrix();
         }
      }
      else
      {
         // todo: allow for pure translation too...
         if (inMatrix.IsIdentity() )
         {
            SDL_BlitSurface(mTexture->GetSourceSurface(), 0, inSurface,&mRect);
         }
         else
         {
            if (inMatrix!=mLastMatrix || !mRenderer)
            {
               mLastMatrix = inMatrix;
               for(int i=0;i<4;i++)
                  inMatrix.TransformHQ( mSX[i], mSY[i],
                       mPoints[i].x, mPoints[i].y );

               // TODO  Ox,Oy
               Matrix mapping = inMatrix.Invert2x2();
               mapping.MatchTransform(mPoints[0].x/65536.0,
                                      mPoints[0].y/65536.0,0,0);


               Uint32 flags= SPG_HIGH_QUALITY | SPG_EDGE_CLAMP | SPG_BMP_LINEAR;
               if (mHasAlpha)
                  flags |= SPG_ALPHA_BLEND;

               delete mRenderer;
               mRenderer = PolygonRenderer::CreateBitmapRenderer(4,
                            mPoints,
                            SPG_clip_ymin(inSurface),
                            SPG_clip_ymax(inSurface),
                            flags, mapping,
                            mTexture->GetSourceSurface() );
            }
            mRenderer->Render(inSurface);
         }
      }
   }


   bool HitTest(SDL_Surface *inSurface,const Matrix &inMatrix,int inX,int inY)
   {
      // TODO:
      return false;
   }

   void GetExtent(Extent2DI &ioExtent,const Matrix &inMatrix)
   {
      for(int i=0;i<4;i++)
      {
         int x,y;
         inMatrix.TransformHQ( mSX[i], mSY[i], x, y);

         ioExtent.Add(x,y);
      }

   }


   TextureBuffer *mTexture;

   bool        mHasAlpha;
   SDL_Rect    mRect;
   Sint16      mSX[4];
   Sint16      mSY[4];
   PointF16    mPoints[4];
   double      mOX;
   double      mOY;
   double      mAlpha;

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



value nme_get_extent(value inDrawList,value ioRect,value inMatrix)
{
   Extent2DI extent;

   Matrix matrix(inMatrix);
   
   value objs_arr =  val_field(inDrawList,val_id("__a"));
   val_check( objs_arr, array );

   int n =  val_int( val_field(inDrawList,val_id("length")));
   value *objs =  val_array_ptr(objs_arr);

   for(int i=0;i<n;i++)
   {
      Drawable *d = DRAWABLE(objs[i]);
      if (d)
         d->GetExtent(extent,matrix);
   }


   alloc_field( ioRect, val_id("x"), alloc_float(extent.mMinX>>16) );
   alloc_field( ioRect, val_id("y"), alloc_float(extent.mMinY>>16) );
   alloc_field( ioRect, val_id("width"), alloc_float(extent.Width()>>16) );
   alloc_field( ioRect, val_id("height"), alloc_float(extent.Height()>>16));

   return alloc_int( extent.mValid ? 1 : 0);
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


value nme_draw_object_to(value drawable,value surface,value matrix )
{
   if ( val_is_kind( drawable, k_drawable ) )
   {
      SDL_Surface *s = 0;
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

      if (s)
      {
         Matrix mtx(matrix);
         Drawable *d = DRAWABLE(drawable);
         d->RenderTo(s,mtx,tex);
      }
   }
   return alloc_int(0);
}

value nme_hit_object(value surface,value drawable,value matrix,value x,value y )
{
   if ( val_is_kind( surface, k_surf )  )
      if ( val_is_kind( drawable, k_drawable ) )
      {
         Matrix mtx(matrix);
         SDL_Surface *s = SURFACE(surface);
         Drawable *d = DRAWABLE(drawable);
         return alloc_bool(d->HitTest(s,mtx,val_int(x),val_int(y)));
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
DEFINE_PRIM(nme_get_extent, 3);
DEFINE_PRIM(nme_draw_object_to, 3);
DEFINE_PRIM(nme_hit_object, 5);
DEFINE_PRIM(nme_set_draw_quality, 1);
DEFINE_PRIM(nme_get_draw_quality, 0);
DEFINE_PRIM_MULT(nme_create_text_drawable);


