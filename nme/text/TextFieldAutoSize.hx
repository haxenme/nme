package nme.text;
#if cpp || neko


enum TextFieldAutoSize
{
   CENTER;
   LEFT;
   NONE;
   RIGHT;
}


#else
typedef TextFieldAutoSize = flash.text.TextFieldAutoSize;
#end