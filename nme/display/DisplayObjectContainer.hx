package nme.display;
#if code_completion


extern class DisplayObjectContainer extends InteractiveObject {
	var mouseChildren : Bool;
	var numChildren(default,null) : Int;
	var tabChildren : Bool;
	//var textSnapshot(default,null) : nme.text.TextSnapshot;
	function new() : Void;
	function addChild(child : DisplayObject) : DisplayObject;
	function addChildAt(child : DisplayObject, index : Int) : DisplayObject;
	function areInaccessibleObjectsUnderPoint(point : nme.geom.Point) : Bool;
	function contains(child : DisplayObject) : Bool;
	function getChildAt(index : Int) : DisplayObject;
	function getChildByName(name : String) : DisplayObject;
	function getChildIndex(child : DisplayObject) : Int;
	function getObjectsUnderPoint(point : nme.geom.Point) : Array<DisplayObject>;
	function removeChild(child : DisplayObject) : DisplayObject;
	function removeChildAt(index : Int) : DisplayObject;
	@:require(flash11) function removeChildren(beginIndex : Int = 0, endIndex : Int = 2147483647) : Void;
	function setChildIndex(child : DisplayObject, index : Int) : Void;
	function swapChildren(child1 : DisplayObject, child2 : DisplayObject) : Void;
	function swapChildrenAt(index1 : Int, index2 : Int) : Void;
}


#elseif (cpp || neko)
typedef DisplayObjectContainer = neash.display.DisplayObjectContainer;
#elseif js
typedef DisplayObjectContainer = jeash.display.DisplayObjectContainer;
#else
typedef DisplayObjectContainer = flash.display.DisplayObjectContainer;
#end