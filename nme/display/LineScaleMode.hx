package nme.display;
#if (cpp || neko)


enum LineScaleMode
{
   NORMAL; // Default
   NONE;
   VERTICAL;
   HORIZONTAL;
}


#else
typedef LineScaleMode = flash.display.LineScaleMode;
#end