#include <neko.h>
#include <SDL.h>
#ifdef __WIN32__
#include <windows.h>
#endif
#include <gl/GL.H>

#include <vector>

#include "nme.h"
#include "nsdl.h"
#include "spg/SPriG.h"
#include "Matrix.h"


DECLARE_KIND( k_draw_object );
DEFINE_KIND( k_draw_object );

#define DRAW_OBJECT(v) ( (DrawObject *)(val_data(v)) )

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


class DrawObject
{
public:
   DrawObject(int inFillColour,double inFillAlpha,
                const LineSegments &inSegments)
   {
      mDisplayList = 0;

      mFillColour = inFillColour;
      mFillAlpha = inFillAlpha;
      mLines = inSegments;
      mX = 0;
      mY = 0;

      size_t n = inSegments.size();
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
               const LinePoint *p = &inSegments[0];
               glDisable(GL_TEXTURE_2D);
               glBegin(GL_TRIANGLE_FAN);
               for(size_t i=0;i<n;i++)
               {
                  glVertex2f( p->mX, p->mY );
                  p++;
               }
               glEnd();
            }
      
   
            const LinePoint *p = &inSegments[0];
   
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



void delete_draw_object( value draw_obj )
{
   if ( val_is_kind( draw_obj, k_draw_object ) )
   {
      val_gc( draw_obj, NULL );

      DrawObject *d = DRAW_OBJECT(draw_obj);
      delete d;
   }
}


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

   value v = alloc_abstract( k_draw_object, obj );
   val_gc( v, delete_draw_object );
   return v;
}

value nme_draw_object(value draw_obj)
{
   if ( val_is_kind( draw_obj, k_draw_object ) )
   {
      DrawObject *d = DRAW_OBJECT(draw_obj);
      d->Render();
   }
   return alloc_int(0);
}

value nme_draw_object_to(value draw_obj,value surface,value matrix )
{
   if ( val_is_kind( draw_obj, k_draw_object ) && 
        val_is_kind( surface, k_surf )  )
   {
      Matrix mtx(matrix);
      DrawObject *d = DRAW_OBJECT(draw_obj);
      SDL_Surface *s = SURFACE(surface);
      d->RenderTo(s,matrix);
   }
   return alloc_int(0);
}


DEFINE_PRIM(nme_create_draw_obj, 3);
DEFINE_PRIM(nme_draw_object, 1);
DEFINE_PRIM(nme_draw_object_to, 3);


