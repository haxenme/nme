package nme.text;
#if (cpp || neko)


enum TextFieldType
{
   DYNAMIC;
   INPUT;
}


#else
typedef TextFieldType = flash.text.TextFieldType;
#end