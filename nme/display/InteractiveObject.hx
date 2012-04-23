package nme.display;
#if code_completion


extern class InteractiveObject extends DisplayObject {
	//var accessibilityImplementation : nme.accessibility.AccessibilityImplementation;
	//var contextMenu : nme.ui.ContextMenu;
	var doubleClickEnabled : Bool;
	var focusRect : Dynamic;
	var mouseEnabled : Bool;
	@:require(flash11) var needsSoftKeyboard : Bool;
	@:require(flash11) var softKeyboardInputAreaOfInterest : nme.geom.Rectangle;
	var tabEnabled : Bool;
	var tabIndex : Int;
	function new() : Void;
	@:require(flash11) function requestSoftKeyboard() : Bool;
}


#elseif (cpp || neko)
typedef InteractiveObject = neash.display.InteractiveObject;
#elseif js
typedef InteractiveObject = jeash.display.InteractiveObject;
#else
typedef InteractiveObject = flash.display.InteractiveObject;
#end