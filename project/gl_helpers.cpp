#include "config.h"
#ifdef WIN32
#include <windows.h>
#endif

#ifdef NME_OPENGL
#include <SDL_opengl.h>
#endif
#include <neko.h>
#include <stdio.h>

#include "nme.h"


value nme_set_window_color(value inColour)
{
#ifdef NME_OPENGL
   val_check(inColour,int);
   int c = val_int(inColour);
   glClearColor( (GLclampf)(((c>>16) & 0xff)/255.0),
                 (GLclampf)(((c>>8) & 0xff)/255.0),
                 (GLclampf)( (c & 0xff, 1)/255.0),
                 (GLclampf)( 1.0));
#endif
   return alloc_int(0);
}

value nme_init_view(value inWidth,value inHeight)
{
#ifdef NME_OPENGL
   if (IsOpenGLMode())
   {
      val_check(inWidth,int);
      val_check(inHeight,int);
      int w = val_int(inWidth);
      int h = val_int(inHeight);

      glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

      glViewport(0,0,w,h);
      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
      glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();
      glOrtho(0,w,h,0,-1000,1000);

      glColor3ub(0,0,0);
  }
#endif
   return val_null;
}

value nme_transform_view(value inDX,value inDY,value inRotZ)
{
#ifdef NME_OPENGL
   if (IsOpenGLMode())
   {
      val_check(inDX,number);
      val_check(inDY,number);
      val_check(inRotZ,number);

      glTranslated(val_number(inDX),val_number(inDY),0);
      glRotated(val_number(inRotZ),0,0,1);
   }

#endif
   return val_null;
}

value nme_push_view()
{
#ifdef NME_OPENGL
   glPushMatrix();
#endif
   return val_null;
}

value nme_pop_view()
{
#ifdef NME_OPENGL
   glPopMatrix();
#endif
   return val_null;
}


DEFINE_PRIM(nme_init_view, 2);
DEFINE_PRIM(nme_set_window_color, 1);
DEFINE_PRIM(nme_transform_view, 3);
DEFINE_PRIM(nme_push_view, 0);
DEFINE_PRIM(nme_pop_view, 0);

int __force_gl_helpers = 0;
