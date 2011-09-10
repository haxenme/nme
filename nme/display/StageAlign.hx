package nme.display;


#if flash
/*
@:native ("flash.display.StageAlign")
@:fakeEnum(String) extern enum StageAlign {
	BOTTOM;
	BOTTOM_LEFT;
	BOTTOM_RIGHT;
	LEFT;
	RIGHT;
	TOP;
	TOP_LEFT;
	TOP_RIGHT;
}
*/

class StageAlign {
	
	public static var BOTTOM:String = "B";
	public static var BOTTOM_LEFT:String = "BL";
	public static var BOTTOM_RIGHT:String = "BR";
	public static var LEFT:String = "L";
	public static var RIGHT:String = "R";
	public static var TOP:String = "T";
	public static var TOP_LEFT:String = "TL";
	public static var TOP_RIGHT:String = "TR";
	
}
#else



enum StageAlign {
   TOP_RIGHT;
   TOP_LEFT;
   TOP;
   RIGHT;
   LEFT;
   BOTTOM_RIGHT;
   BOTTOM_LEFT;
   BOTTOM;
}
#end