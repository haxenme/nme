package nme.display;
#if (!flash)

enum JointStyle 
{
   ROUND; // default
   MITER;
   BEVEL;
}

#else
typedef JointStyle = flash.display.JointStyle;
#end
