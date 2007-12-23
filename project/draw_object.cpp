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


DECLARE_KIND( k_drawable );
DEFINE_KIND( k_drawable );

#define DRAWABLE(v) ( (Drawable *)(val_data(v)) )



// --- Base class -----------------------------------------------------


class Drawable
{
public:
   virtual ~Drawable() { }
   virtual void Render()=0;
   virtual void RenderTo(SDL_Surface *inSurface,const Matrix &inMatrix)=0;
};


void delete_drawable( value drawable );



// --- For drawing geometry -----------------------------------------

struct LinePoint
{
   float mX,mY;
   int    mColour;
   double mAlpha;
   double mThickness;

   void FromValue(value inVal)
   {
      mX = (float)val_number(val_field(inVal,val_id("x")));
      mY = (float)val_number(val_field(inVal,val_id("y")));
      mColour = val_int(val_field(inVal,val_id("colour")));
      mThickness = val_number(val_field(inVal,val_id("thickness")));
      mAlpha = val_number(val_field(inVal,val_id("alpha")));
   }

};

typedef std::vector<LinePoint> LineSegments;

class DrawObject : public Drawable
{
public:
   DrawObject(int inFillColour,double inFillAlpha, LineSegments &inSegments)
   {
      mDisplayList = 0;

      mFillColour = inFillColour;
      mFillAlpha = inFillAlpha;
      // Just take the lot - they won't be needed again.
      mLines.swap(inSegments);
      mX = 0;
      mY = 0;

      size_t n = mLines.size();
      if (n>0)
      {
         if (IsOpenGLMode())
         {
            mDisplayList = glGenLists(1);
            glNewList(mDisplayList,GL_COMPILE);
   
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
            if (inFillAlpha>0)
            {
               // TODO: tesselate
               glColor4ub(inFillColour >> 16, inFillColour >> 8, inFillColour,
                            (unsigned char)(inFillAlpha*255.0));
               const LinePoint *p = &mLines[0];
               glDisable(GL_TEXTURE_2D);
               glBegin(GL_TRIANGLE_FAN);
               for(size_t i=0;i<n;i++)
               {
                  glVertex2f( p->mX, p->mY );
                  p++;
               }
               glEnd();
            }
      
   
            const LinePoint *p = &mLines[0];
   
            int col = p->mColour;
            double alpha = p->mAlpha;
            double lw = p->mThickness;
   
   
            glLineWidth( (GLfloat)(lw==0 ? 1 : lw) );
   
            // TODO: handle z properly
            glDisable(GL_DEPTH_TEST);
   
            glColor4ub((col>>16)&0xff,(col>>8)&0xff,(col)&0xff,
               (unsigned char)(alpha*255.0));
   
            glBegin(GL_LINE_STRIP);
            for(size_t i=0;i<n;i++)
            {
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
               glVertex2f( p->mX, p->mY );
               p++;
            }
            glEnd();
   
            if (lw!=0)
               glLineWidth(1);
   
            glDisable(GL_BLEND);
            glEndList();
         }
      }
   }
   ~DrawObject()
   {
      if (mDisplayList!=0)
         glDeleteLists(mDisplayList,1);
      delete [] mX;
      delete [] mY;
   }
   void Render()
   {
      if (mDisplayList!=0 && IsOpenGLMode())
         glCallList(mDisplayList);
   }

   void AllocXY()
   {
      delete [] mX;
      delete [] mY;
      size_t n = mLines.size();
      mX = new Sint16[n];
      mY = new Sint16[n];
   }

   void TransformPoints(const Matrix &inMatrix)
   {
      size_t n = mLines.size();
      mMatrix = inMatrix;

      if (mMatrix.IsIdentity())
         for(size_t i=0;i<n;i++)
         {
            mX[i] = (Sint16)mLines[i].mX;
            mY[i] = (Sint16)mLines[i].mY;
         }
     else
         for(size_t i=0;i<n;i++)
            inMatrix.Transform(mLines[i].mX,mLines[i].mY,mX[i],mY[i]);
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
         if (!mX)
         {
            AllocXY();
            TransformPoints(inMatrix);
         }
         else if (inMatrix!=mMatrix)
            TransformPoints(inMatrix);

         Uint16 n = (Uint16)mLines.size();

         if (mFillAlpha>0)
         {
            if (mFillAlpha<1)
               SPG_PolygonFilled(inSurface,n-1,mX,mY,mFillColour);
            else
               SPG_PolygonFilledBlend(inSurface,n-1,mX,mY,mFillColour,
                    (Uint8)(mFillAlpha*255.0) );
         }

         for(int i=0;i<n-1;i++)
         {
            const LinePoint &p0 = mLines[ i ];
            if (p0.mAlpha > 0 )
            {
               int p1 = i+1;

               if (p0.mAlpha<1.0)
                  SPG_LineBlend(inSurface,mX[i],mY[i],mX[p1],mY[p1],p0.mColour,
                       (Uint8)(p0.mAlpha*255.0) );
               else
                  SPG_Line(inSurface,mX[i],mY[i],mX[p1],mY[p1],p0.mColour);
            }
         }
      }
   }


   Sint16       *mX;
   Sint16       *mY;
   Matrix       mMatrix;
   int          mFillColour;
   double       mFillAlpha;
   LineSegments mLines;
   GLuint       mDisplayList;

private: // Hide
   DrawObject(const DrawObject &inRHS);
   void operator=(const DrawObject &inRHS);
};



value nme_create_draw_obj(value inFillColour, value inFillAlpha, value inLines)
{
   val_check( inFillColour, int );
   val_check( inFillAlpha, number );
   val_check( inLines, array );

   int n = val_array_size(inLines);
   value *items = val_array_ptr(inLines);

   LineSegments line_segs(n);
   for(int i=0;i<n;i++)
   {
      line_segs[i].FromValue(items[i]);
    }


   DrawObject *obj = new DrawObject( val_int(inFillColour),
                                     val_number(inFillAlpha),
                                     line_segs );

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

      for(int i=0;i<4;i++)
      {
         mSX[i] = (Sint16)( mOX + (i==1||i==3) * mSurface->w + 0.5 );
         mSY[i] = (Sint16)( mOY + (i==2||i==3) * mSurface->h + 0.5 );
      }
   }
   ~SurfaceDrawer()
   {
       SDL_FreeSurface(mSurface);
       delete mTexture;
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
         if (inMatrix.IsIdentity() && 0)
         {
            SDL_BlitSurface(mSurface, 0, inSurface, &mRect);
         }
         else
         {
            for(int i=0;i<4;i++)
               inMatrix.Transform( mSX[i], mSY[i], mTX[i], mTY[i] );

            int w = mSurface->w;
            int h = mSurface->h;
            SPG_QuadTex2(inSurface,
                mTX[0], mTY[0], mTX[1], mTY[1], mTX[2], mTY[2], mTX[3], mTY[3],
                mSurface, 
                0,0, w-1,0, 0,h-1 , w-1,h-1,
                (mHasAlpha?SPG_ALPHA_BLEND:0) | SPG_BILINEAR );
         }
      }
   }

   SDL_Surface *mSurface;
   TextureRect *mTexture;
   bool        mHasAlpha;
   SDL_Rect    mRect;
   Sint16      mTX[4];
   Sint16      mTY[4];
   Sint16      mSX[4];
   Sint16      mSY[4];
   double      mOX;
   double      mOY;
   double      mAlpha;
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


value nme_draw_object(value drawable)
{
   if ( val_is_kind( drawable, k_drawable ) )
   {
      Drawable *d = DRAWABLE(drawable);
      d->Render();
   }
   return alloc_int(0);
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


DEFINE_PRIM(nme_create_draw_obj, 3);
DEFINE_PRIM(nme_draw_object, 1);
DEFINE_PRIM(nme_draw_object_to, 3);
DEFINE_PRIM_MULT(nme_create_text_drawable);


