package nme.text;
#if (!flash)

@:fakeEnum(String) enum FontType 
{
   DEVICE;
   EMBEDDED;
   EMBEDDED_CFF;
}

#else
typedef FontType = flash.text.FontType;
#end
