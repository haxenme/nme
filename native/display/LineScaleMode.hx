package native.display;
#if (cpp || neko)

enum LineScaleMode 
{
   NORMAL; // default
   NONE;
   VERTICAL;
   HORIZONTAL;   
   OPENGL;
}

#end