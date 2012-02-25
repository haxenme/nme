package nme.text;
#if js


class GridFitType
{
   public function new() { }

   public static var NONE = "ADVANCED";
   public static var PIXEL = "PIXEL";
   public static var SUBPIXEL = "SUBPIXEL";
}


#else
typedef GridFitType = flash.text.GridFitType;
#end