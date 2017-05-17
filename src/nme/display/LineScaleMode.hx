package nme.display;
#if (!flash)

enum LineScaleMode 
{
   NORMAL; // default
   NONE;
   VERTICAL;
   HORIZONTAL;   
   OPENGL;
}

#else
typedef LineScaleMode = flash.display.LineScaleMode;
#end
