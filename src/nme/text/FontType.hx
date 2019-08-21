package nme.text;
#if (!flash)

#if haxe4
@:enum abstract FontType(String)
{
   var DEVICE = "DEVICE";
   var EMBEDDED = "EMBEDDED";
   var EMBEDDED_CFF = "EMBEDDED_CFF";
}

#else
@:fakeEnum(String) enum FontType 
{
   DEVICE;
   EMBEDDED;
   EMBEDDED_CFF;
}
#end

#else
typedef FontType = flash.text.FontType;
#end
