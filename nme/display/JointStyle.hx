package nme.display;
#if cpp || neko


enum JointStyle
{
   ROUND; // Default
   MITER;
   BEVEL;
}


#else
typedef JointStyle = flash.display.JointStyle;
#end