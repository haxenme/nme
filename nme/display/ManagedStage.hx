package nme.display;
#if code_completion


extern class ManagedStage extends Stage
{	
	static var etUnknown;
	static var etKeyDown;
	static var etChar;
	static var etKeyUp;
	static var etMouseMove;
	static var etMouseDown;
	static var etMouseClick;
	static var etMouseUp;
	static var etResize;
	static var etPoll;
	static var etQuit;
	static var etFocus;
	static var etShouldRotate;
	static var etDestroyHandler;
	static var etRedraw;
	static var etTouchBegin;
	static var etTouchMove;
	static var etTouchEnd;
	static var etTouchTap;
	static var etChange;
	static var efLeftDown;
	static var efShiftDown;
	static var efCtrlDown;
	static var efAltDown;
	static var efCommandDown;
	static var efMiddleDown;
	static var efRightDown;
	static var efLocationRight;
	static var efPrimaryTouch;
	function new(inWidth:Int, inHeight:Int);
	dynamic function beginRender();
	dynamic function endRender();
	function pumpEvent(inEvent:Dynamic):Void;
	function resize(inWidth:Int, inHeight:Int):Void;
	function sendQuit():Void;
	dynamic function setNextWake(inDelay:Float);
}


#elseif (cpp || neko)
typedef ManagedStage = neash.display.ManagedStage;
#end