#if flash


package nme.display;


/*
@:native ("flash.display.StageQuality")
@:fakeEnum(String) extern enum StageQuality {
	BEST;
	HIGH;
	LOW;
	MEDIUM;
}
*/


class StageQuality {
	
	public static var BEST:String = "best";
	public static var HIGH:String = "high";
	public static var LOW:String = "low";
	public static var MEDIUM:String = "medium";
	
}


#else


package nme.display;

enum StageQuality
{
   LOW;
   MEDIUM;
   HIGH;
   BEST;
}


#end