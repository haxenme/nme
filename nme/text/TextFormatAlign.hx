#if flash


package flash.text;

@:fakeEnum(String) extern enum TextFormatAlign {
	CENTER;
	JUSTIFY;
	LEFT;
	RIGHT;
}



#else


package nme.text;

class TextFormatAlign
{
   public static var LEFT = "left";
   public static var RIGHT = "right";
   public static var CENTER = "center";
   public static var JUSTIFY = "justify";
}


#end