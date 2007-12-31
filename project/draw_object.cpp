#include <SDL.h>
#include <string>
#include <neko.h>

#ifdef __WIN32__
#include <windows.h>
#endif
#include <gl/GL.H>

#include <vector>

#include "nme.h"
#include "nsdl.h"
#include "spg/SPriG.h"
#include "Matrix.h"
#include "texture_buffer.h"
#include "text.h"
#include "Extras.h"
#include "Gradient.h"


DECLARE_KIND( k_drawable );
DEFINE_KIND( k_drawable );

#define DRAWABLE(v) ( (Drawable *)(val_data(v)) )



// --- Base class -----------------------------------------------------


class Drawable
{
public:
   virtual ~Drawable() { }
   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix)=0;
};


void delete_drawable( value drawable );



// --- For drawing geometry -----------------------------------------

struct Point
{
   float mX,mY;

   void FromValue(value inVal)
   {
      mX = (float)val_number(val_field(inVal,val_id("x")));
      mY = (float)val_number(val_field(inVal,val_id("y")));
   }
};

typedef std::vector<Point> Points;
typedef std::vector<int> IntVec;

struct LineJob
{
   IntVec          mPointIndex;
   int             mColour;
   int             mJoints;
   double          mAlpha;
   double          mThickness;
   Gradient        *mGradient;
   PolygonRenderer *mRenderer;

   void FromValue(value inVal)
   {
      mRenderer = 0;
      mGradient = CreateGradient(val_field(inVal,val_id("grad")));
      mColour = val_int(val_field(inVal,val_id("colour")));
      mJoints = val_int(val_field(inVal,val_id("joints")));
      mThickness = val_number(val_field(inVal,val_id("thickness")));
      mAlpha = val_number(val_field(inVal,val_id("alpha")));

      value idx = val_field(inVal,val_id("point_idx"));
      int n = val_array_size(idx);
      value *items = val_array_ptr(idx);
      mPointIndex.resize(n);
      for(int i=0;i<n;i++)
         mPointIndex[i] = val_int(items[i]);
   }

};

typedef std::vector<LineJob> LineJobs;

typedef std::vector<Point> Points;


class DrawObject : public Drawable
{
public:
   DrawObject(Points &inPoints, int inFillColour,double inFillAlpha,
              Gradient *inFillGradient,
              LineJobs &inLines)
   {
      mDisplayList = 0;
      mPolygon = 0;
      mSolidGradient = inFillGradient;

      mFillColour = inFillColour;
      mFillAlpha = inFillAlpha;

      mPoints.swap(inPoints);
      mLineJobs.swap(inLines);

      int n = (int)mPoints.size();
      mX = new Sint16[n];
      mY = new Sint16[n];
      mHQX = new Sint32[n];
      mHQY = new Sint32[n];
      TransformPoints(mTransform);
   }

   /*
         if (IsOpenGLMode())
         {
            mDisplayList = glGenLists(1);
            glNewList(mDisplayList,GL_COMPILE);
            DrawOpenGL();
            glEndList();
         }
         */

   void ClearRenderers()
   {
      delete mPolygon;
      mPolygon = 0;

      for(int i=0;i<mLineJobs.size();i++)
      {
         delete mLineJobs[i].mRenderer;
         mLineJobs[i].mRenderer = 0;
      }
   }

   ~DrawObject()
   {
      ClearRenderers();

      for(int i=0;i<mLineJobs.size();i++)
         delete mLineJobs[i].mGradient;

      delete mSolidGradient;
      if (mDisplayList!=0)
         glDeleteLists(mDisplayList,1);
      delete [] mX;
      delete [] mY;
      delete [] mHQX;
      delete [] mHQY;
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
         int n = mPoints.size();

         if (mSolidGradient)
            mSolidGradient->BeginOpenGL();
         else
            glDisable(GL_TEXTURE_2D);

         glBegin(GL_TRIANGLE_FAN);
         for(size_t i=0;i<n;i++)
         {
            if (mSolidGradient)
               mSolidGradient->OpenGLTexture(mX[i],mY[i]);
            glVertex2i( mX[i], mY[i] );
            p++;
         }
         glEnd();
      }

      if (mSolidGradient)
         mSolidGradient->EndOpenGL();
   

      /*

      if (!mGradient)
      {
         const LinePoint *p = &mLines[0];
   
         int col = p->mColour;
         double alpha = p->mAlpha;
         double lw = p->mThickness;
   
   
         glLineWidth( (GLfloat)(lw==0 ? 1 : lw) );
   
   
         glColor4ub((col>>16)&0xff,(col>>8)&0xff,(col)&0xff,
            (unsigned char)(alpha*255.0));
   
         glBegin(GL_LINE_STRIP);
         for(size_t i=0;i<n;i++)
         {
            if (i!=0 && (p->mColour!=col || p->mAlpha || p->mThickness!=lw))
            {
               glEnd();
               if (p->mColour!=col || p->mAlpha!=alpha)
               {
                   col = p->mColour;
                   alpha = p->mAlpha;
   
                   glColor4ub((col>>16)&0xff,(col>>8)&0xff,(col)&0xff,
                      (unsigned char)(alpha*255.0));
               }
               if (p->mThickness!=lw)
               {
                  lw = p->mThickness;
                  glLineWidth((GLfloat)lw);
               }
               glBegin(GL_LINE_STRIP);
               glVertex2f( p[-1].mX, p[-1].mY );
            }
            glVertex2f( p->mX, p->mY );
            p++;
         }
         glEnd();
      
         if (lw!=0)
            glLineWidth(1);
      }
      */

      glDisable(GL_BLEND);
   }


   void TransformPoints(const Matrix &inMatrix)
   {
      size_t n = mPoints.size();
      mTransform = inMatrix;

      if (mTransform.IsIdentity())
         for(size_t i=0;i<n;i++)
         {
            mX[i] = (Sint16)mPoints[i].mX;
            mY[i] = (Sint16)mPoints[i].mY;
            mHQX[i] =  (int)(mPoints[i].mX * 65536.0);
            mHQY[i] =  (int)(mPoints[i].mY * 65536.0);
         }
     else
         for(size_t i=0;i<n;i++)
         {
            mTransform.Transform(mPoints[i].mX,mPoints[i].mY,mX[i],mY[i]);
            mTransform.TransformHQ(mPoints[i].mX,mPoints[i].mY,mHQX[i],mHQY[i]);
         }
   }


   void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix)
   {
      if (IsOpenGLScreen(inSurface))
      {
         if (mDisplayList)
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
         if (inMatrix!=mTransform)
         {
            TransformPoints(inMatrix);
            // TODO: allow for the possibility of simple translation...
            ClearRenderers();
         }


         Uint16 n = (Uint16)mPoints.size();

         if (mSolidGradient || mFillAlpha>0)
         {
            if (mSolidGradient)
            {
               if (!mPolygon)
               {
                  unsigned int flags = SPG_HIGH_QUALITY;
                  mPolygon = PolygonRenderer::CreateGradientRenderer(n-1,
                                 mHQX, mHQY,
                                 SPG_clip_ymin(inSurface),
                                 SPG_clip_ymax(inSurface),
                                 flags, mSolidGradient );
               }
               if (mPolygon)
                  mPolygon->Render(inSurface);
            }
            else if (mFillAlpha<1)
               SPG_PolygonFilled(inSurface,n-1,mX,mY,mFillColour);
            else
               SPG_PolygonFilledBlend(inSurface,n-1,mX,mY,mFillColour,
                    (Uint8)(mFillAlpha*255.0) );
         }

         /*
         if (!mGradient)
         {
            for(int i=1;i<n;i++)
            {
               const LinePoint &p1 = mLineJobs[ i ];
               if (p1.mAlpha > 0 )
               {
                  int p0 = i-1;
   
                  if (p1.mAlpha<1.0)
                     SPG_LineBlend(inSurface,mX[p0],mY[p0],
                          mX[i],mY[i],p1.mColour,
                          (Uint8)(p1.mAlpha*255.0) );
                  else
                     SPG_Line(inSurface,mX[p0],mY[p0],mX[i],mY[i],p1.mColour);
               }
            }
         }
         */
      }
   }




   Points       mPoints;
   Gradient     *mSolidGradient;
   int          mFillColour;
   double       mFillAlpha;
   LineJobs     mLineJobs;

   Sint16       *mX;
   Sint16       *mY;
   Sint32       *mHQX;
   Sint32       *mHQY;

   GLuint       mDisplayList;

   Matrix       mTransform;

   PolygonRenderer *mPolygon;

private: // Hide
   DrawObject(const DrawObject &inRHS);
   void operator=(const DrawObject &inRHS);
};



value nme_create_draw_obj(value inPoints, value inFillColour, value inFillAlpha,
                          value inSolidGradient, value inLines)
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

   DrawObject *obj = new DrawObject( points,
                                     val_int(inFillColour),
                                     val_number(inFillAlpha),
                                     CreateGradient(inSolidGradient),
                                     lines );

   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );
   return v;
}

/*
value nme_create_gradient_obj(value inFlags, value inGradPoints,
                              value inMatrix, value inLines)
{
   val_check( inFlags, int );
   val_check( inGradPoints, array );
   val_check( inLines, array );

   int n = val_array_size(inLines);
   value *items = val_array_ptr(inLines);

   LineSegments line_segs(n);
   for(int i=0;i<n;i++)
      line_segs[i].FromValue(items[i]);

   DrawObject *obj = new DrawObject(
                        new Gradient(inFlags,inGradPoints,inMatrix),
                        line_segs );

   value v = alloc_abstract( k_drawable, obj );
   val_gc( v, delete_drawable );
   return v;
}
*/




// ---- Surface Drawing -----------------------------------------------------

class SurfaceDrawer : public Drawable
{
public:
   SurfaceDrawer(SDL_Surface *inSurface,double inOX, double inOY,
         double inAlpha, bool inHasAlpha=true)
   {
      mSurface = inSurface;
      mTexture = 0;
      mOX = inOX;
      mOY = inOY;
      mRect.x = (Sint16)inOX;
      mRect.y = (Sint16)inOY;
      mRect.w = mSurface->w;
      mRect.h = mSurface->h;
      mAlpha = inAlpha;
      mHasAlpha = inHasAlpha;
      mRenderer = 0;

      for(int i=0;i<4;i++)
      {
         mSX[i] = (Sint16)( mOX + (i==1||i==2) * mSurface->w + 0.5 );
         mSY[i] = (Sint16)( mOY + (i==2||i==3) * mSurface->h + 0.5 );
      }
   }
   ~SurfaceDrawer()
   {
       SDL_FreeSurface(mSurface);
       delete mTexture;
       delete mRenderer;
   }

   void CreateOGLTextureIfRequired()
   {
      if (IsOpenGLMode() && !mTexture)
         mTexture = new TextureRect(mSurface);
   }

   virtual void Render()
   {
      if (IsOpenGLMode())
      {
         CreateOGLTextureIfRequired();
         mTexture->Quad();
      }
      else
      {
         //  ?? SDL_BlitSurface(mSurface, 0, data, &mRect);
      }
   }

   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix)
   {
      bool hq = true;

      if (IsOpenGLScreen(inSurface))
      {
         CreateOGLTextureIfRequired();
         if (inMatrix.IsIdentity() && mOX==0 && mOY==0)
            mTexture->Quad();
         else
         {
            glPushMatrix();
            inMatrix.GLMult();
            glTranslated(mOX,mOY,0);
            mTexture->Quad();
            glPopMatrix();
         }
      }
      else
      {
         if (inMatrix.IsIdentity() )
         {
            SDL_BlitSurface(mSurface, 0, inSurface, &mRect);
         }
         else
         {
            if (inMatrix!=mLastMatrix || !mRenderer)
            {
               mLastMatrix = inMatrix;
               for(int i=0;i<4;i++)
                  inMatrix.TransformHQ( mSX[i], mSY[i], mHQTX[i], mHQTY[i] );

               // Calculate mapping matrix.
               /*
                  Texture = [ M ][ position ], where T is in pixels
                  Initially,
                     Tex = [ I ][position]
                     but need in terms of p' = [inMatrix][position],
                     ie, [position] = [inMatrix] ^ -1 [p']
                       so
                     Tex = [inMatrix] ^ 1 [p']

                   For numerical stability, we will invert the rotation
                    component, and add offset to get first corner exact.
               */

               Matrix mapping = inMatrix.Invert2x2();
               mapping.MatchTransform(mHQTX[0]/65536.0,mHQTY[0]/65536.0,0,0);

               Uint32 flags = SPG_HIGH_QUALITY | SPG_EDGE_CLAMP;
               if (mHasAlpha)
                  flags |= SPG_ALPHA_BLEND;

               delete mRenderer;
               mRenderer = PolygonRenderer::CreateBitmapRenderer(4,
                            mHQTX, mHQTY,
                            SPG_clip_ymin(inSurface),
                            SPG_clip_ymax(inSurface),
                            flags, mapping, mSurface );
            }
            mRenderer->Render(inSurface);
         }
      }
   }

   SDL_Surface *mSurface;
   TextureRect *mTexture;
   bool        mHasAlpha;
   SDL_Rect    mRect;
   Sint16      mSX[4];
   Sint16      mSY[4];
   Sint32      mHQTX[4];
   Sint32      mHQTY[4];
   double      mOX;
   double      mOY;
   double      mAlpha;

   Matrix           mLastMatrix;
   Matrix           mMappingMatrix;
   PolygonRenderer *mRenderer;
};



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
   if ( val_is_kind( drawable, k_drawable ) && 
        val_is_kind( surface, k_surf )  )
   {
      Matrix mtx(matrix);
      Drawable *d = DRAWABLE(drawable);
      SDL_Surface *s = SURFACE(surface);
      d->RenderTo(s,mtx);
   }
   return alloc_int(0);
}


DEFINE_PRIM(nme_create_draw_obj, 5);
DEFINE_PRIM(nme_draw_object_to, 3);
DEFINE_PRIM_MULT(nme_create_text_drawable);


