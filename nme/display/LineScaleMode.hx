package nme.display;
#if (cpp || neko)

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