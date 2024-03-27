package nme.text;
#if (!flash)

enum abstract GridFitType(String)
{
   var NONE;
   var PIXEL;
   var SUBPIXEL;
}

#else
typedef GridFitType = flash.text.GridFitType;
#end
