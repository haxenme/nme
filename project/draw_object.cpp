#include <neko.h>
#include <SDL.h>
#ifdef __WIN32__
#include <windows.h>
#endif
#include <gl/GL.H>

#include <vector>


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
      mDisplayList = glGenLists(1);
      size_t n = inSegments.size();
      // printf("Create DrawObject %x %f %d\n", inFillColour, inFillAlpha, n);
      if (n>0)
      {
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
   ~DrawObject()
   {
      glDeleteLists(mDisplayList,1);
   }
   void Render()
   {
      glCallList(mDisplayList);
   }


   GLuint mDisplayList;
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

DEFINE_PRIM(nme_create_draw_obj, 3);
DEFINE_PRIM(nme_draw_object, 1);


