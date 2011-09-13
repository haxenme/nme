package nme.display;
#if (cpp || neko)


enum StageAlign {
   TOP_RIGHT;
   TOP_LEFT;
   TOP;
   RIGHT;
   LEFT;
   BOTTOM_RIGHT;
   BOTTOM_LEFT;
   BOTTOM;
}


#else
typedef StageAlign = flash.display.StageAlign;
#end