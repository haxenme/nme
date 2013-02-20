package native.text;
#if (cpp || neko)

@:fakeEnum(String) enum FontType 
{
   DEVICE;
   EMBEDDED;
   EMBEDDED_CFF;
}

#end
