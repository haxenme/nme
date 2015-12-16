package nme.display;
#if (!flash)

enum CapsStyle 
{
   ROUND; // default
   NONE;
   SQUARE;
}

#else
typedef CapsStyle = flash.display.CapsStyle;
#end
