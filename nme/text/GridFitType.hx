#if flash


package flash.text;

/*
@:native ("flash.text.GridFitType")
@:fakeEnum(String) extern enum GridFitType {
	NONE;
	PIXEL;
	SUBPIXEL;
}
*/

@:native ("flash.text.GridFitType")
extern class GridFitType {
	public static var NONE:String = "none";
	public static var PIXEL:String = "pixel";
	public static var SUBPIXEL:String = "subpixel";
}



#end