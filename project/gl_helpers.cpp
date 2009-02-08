#ifdef WIN32
#include <windows.h>
#endif

#include <GL/gl.h>
#include <neko.h>
#include <stdio.h>


value nme_set_window_color(value inColour)
{
   val_check(inColour,int);
   int c = val_int(inColour);
   glClearColor( (GLclampf)(((c>>16) & 0xff)/255.0),
                 (GLclampf)(((c>>8) & 0xff)/255.0),
                 (GLclampf)( (c & 0xff, 1)/255.0),
                 (GLclampf)( 1.0));
   return alloc_int(0);
}

value nme_init_view(value inWidth,value inHeight)
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

   return alloc_int(0);
}

value nme_transform_view(value inDX,value inDY,value inRotZ)
{
   val_check(inDX,number);
   val_check(inDY,number);
   val_check(inRotZ,number);

   glTranslated(val_number(inDX),val_number(inDY),0);
   glRotated(val_number(inRotZ),0,0,1);

   return alloc_int(0);
}

value nme_push_view()
{
   glPushMatrix();
   return alloc_int(0);
}

value nme_pop_view()
{
   glPopMatrix();
   return alloc_int(0);
}


DEFINE_PRIM(nme_init_view, 2);
DEFINE_PRIM(nme_set_window_color, 1);
DEFINE_PRIM(nme_transform_view, 3);
DEFINE_PRIM(nme_push_view, 0);
DEFINE_PRIM(nme_pop_view, 0);


