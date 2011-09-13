package nme.text;
#if cpp || neko


class TextFormatAlign
{
   public static var LEFT = "left";
   public static var RIGHT = "right";
   public static var CENTER = "center";
   public static var JUSTIFY = "justify";
}


#else
typedef TextFormatAlign = flash.text.TextFormatAlign;
#end