package nme.text;
#if (!flash)

#if haxe4
@:enum(String) abstract FontStyle(String)
{
   var BOLD = "BOLD";
   var BOLD_ITALIC = "BOLD_ITALIC";
   var ITALIC = "ITALIC";
   var REGULAR = "REGULAR";
}

#else
@:fakeEnum(String) enum FontStyle 
{
   BOLD;
   BOLD_ITALIC;
   ITALIC;
   REGULAR;
}
#end

#else
typedef FontStyle = flash.text.FontStyle;
#end
