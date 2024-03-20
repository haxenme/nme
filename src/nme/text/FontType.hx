package nme.text;
#if (!flash)

enum abstract FontType(String)
{
   var DEVICE = "DEVICE";
   var EMBEDDED = "EMBEDDED";
   var EMBEDDED_CFF = "EMBEDDED_CFF";
}

#else
typedef FontType = flash.text.FontType;
#end
