package nme.text;
#if (!flash)

@:enum
abstract TextFormatAlign(String) from String to String
{
   var LEFT = "left";
   var RIGHT = "right";
   var CENTER = "center";
   var JUSTIFY = "justify";
}

#else
typedef TextFormatAlign = flash.text.TextFormatAlign;
#end
