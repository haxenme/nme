package nme.text;
#if (!flash)

@:nativeProperty
class TextFormatAlign 
{
   public static inline var LEFT = "left";
   public static inline var RIGHT = "right";
   public static inline var CENTER = "center";
   public static inline var JUSTIFY = "justify";
}

#else
typedef TextFormatAlign = flash.text.TextFormatAlign;
#end
