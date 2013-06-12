package nme.text;
#if (cpp || neko)

@:fakeEnum(String) enum FontStyle 
{
   BOLD;
   BOLD_ITALIC;
   ITALIC;
   REGULAR;
}

#else
typedef FontStyle = flash.text.FontStyle;
#end
