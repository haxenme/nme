package nme.display;
#if cpp || neko


enum CapsStyle
{
   ROUND; // Default
   NONE;
   SQUARE;
}


#else
typedef CapsStyle = flash.display.CapsStyle;
#end