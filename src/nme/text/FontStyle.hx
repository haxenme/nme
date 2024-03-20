package nme.text;

#if (!flash)

enum abstract FontStyle(String)
{
   var BOLD = "BOLD";
   var BOLD_ITALIC = "BOLD_ITALIC";
   var ITALIC = "ITALIC";
   var REGULAR = "REGULAR";
}

#else
typedef FontStyle = flash.text.FontStyle;
#end
