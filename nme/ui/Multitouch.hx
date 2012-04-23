package nme.ui;
#if code_completion


@:require(flash10_1) extern class Multitouch {
	static var inputMode : MultitouchInputMode;
	static var maxTouchPoints(default,null) : Int;
	static var supportedGestures(default,null) : nme.Vector<String>;
	static var supportsGestureEvents(default,null) : Bool;
	static var supportsTouchEvents(default,null) : Bool;
}


#elseif (cpp || neko)
typedef Multitouch = neash.ui.Multitouch;
#elseif js
typedef Multitouch = jeash.ui.Multitouch;
#else
typedef Multitouch = flash.ui.Multitouch;
#end