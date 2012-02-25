package nme.text;
#if (cpp || neko || js)


enum TextFormatAlign
{
   LEFT;
   RIGHT;
   JUSTIFY;
   CENTER;
}


#else
typedef TextFormatAlign = flash.text.TextFormatAlign;
#end