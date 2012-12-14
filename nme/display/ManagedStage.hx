package nme.display;
#if display


extern class ManagedStage extends Stage
{	
	static var etUnknown:Int;
	static var etKeyDown:Int;
	static var etChar:Int;
	static var etKeyUp:Int;
	static var etMouseMove:Int;
	static var etMouseDown:Int;
	static var etMouseClick:Int;
	static var etMouseUp:Int;
	static var etResize:Int;
	static var etPoll:Int;
	static var etQuit:Int;
	static var etFocus:Int;
	static var etShouldRotate:Int;
	static var etDestroyHandler:Int;
	static var etRedraw:Int;
	static var etTouchBegin:Int;
	static var etTouchMove:Int;
	static var etTouchEnd:Int;
	static var etTouchTap:Int;
	static var etChange:Int;
	static var efLeftDown:Int;
	static var efShiftDown:Int;
	static var efCtrlDown:Int;
	static var efAltDown:Int;
	static var efCommandDown:Int;
	static var efMiddleDown:Int;
	static var efRightDown:Int;
	static var efLocationRight:Int;
	static var efPrimaryTouch:Int;
	function new(inWidth:Int, inHeight:Int):Void;
	dynamic function beginRender():Void;
	dynamic function endRender():Void;
	function pumpEvent(inEvent:Dynamic):Void;
	function resize(inWidth:Int, inHeight:Int):Void;
	function sendQuit():Void;
	dynamic function setNextWake(inDelay:Float):Void;
}


#elseif (cpp || neko)
typedef ManagedStage = native.display.ManagedStage;
#end
