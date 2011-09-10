#if flash


package nme.display;


/*
@:native ("flash.display.StageScaleMode")
@:fakeEnum(String) extern enum StageScaleMode {
	EXACT_FIT;
	NO_BORDER;
	NO_SCALE;
	SHOW_ALL;
}*/


class StageScaleMode {
	
	public static var EXACT_FIT:String = "exactFit";
	public static var NO_BORDER:String = "noBorder";
	public static var NO_SCALE:String = "noScale";
	public static var SHOW_ALL:String = "showAll";
	
}


#else


package nme.display;

enum StageScaleMode { SHOW_ALL; NO_SCALE; NO_BORDER; EXACT_FIT; }


#end