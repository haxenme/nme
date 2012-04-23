package nme.display;
#if code_completion


extern class DisplayObject extends nme.events.EventDispatcher, implements IBitmapDrawable {
	//var accessibilityProperties : nme.accessibility.AccessibilityProperties;
	var alpha : Float;
	var blendMode : BlendMode;
	//@:require(flash10) var blendShader(null,default) : Shader;
	var cacheAsBitmap : Bool;
	var filters : Array<Dynamic>;
	var height : Float;
	var loaderInfo(default,null) : LoaderInfo;
	var mask : DisplayObject;
	var mouseX(default,null) : Float;
	var mouseY(default,null) : Float;
	var name : String;
	var opaqueBackground : Null<Int>;
	var parent(default,null) : DisplayObjectContainer;
	var root(default,null) : DisplayObject;
	var rotation : Float;
	@:require(flash10) var rotationX : Float;
	@:require(flash10) var rotationY : Float;
	@:require(flash10) var rotationZ : Float;
	var scale9Grid : nme.geom.Rectangle;
	var scaleX : Float;
	var scaleY : Float;
	@:require(flash10) var scaleZ : Float;
	var scrollRect : nme.geom.Rectangle;
	var stage(default,null) : Stage;
	var transform : nme.geom.Transform;
	var visible : Bool;
	var width : Float;
	var x : Float;
	var y : Float;
	@:require(flash10) var z : Float;
	function getBounds(targetCoordinateSpace : DisplayObject) : nme.geom.Rectangle;
	function getRect(targetCoordinateSpace : DisplayObject) : nme.geom.Rectangle;
	function globalToLocal(point : nme.geom.Point) : nme.geom.Point;
	@:require(flash10) function globalToLocal3D(point : nme.geom.Point) : nme.geom.Vector3D;
	function hitTestObject(obj : DisplayObject) : Bool;
	function hitTestPoint(x : Float, y : Float, shapeFlag : Bool = false) : Bool;
	@:require(flash10) function local3DToGlobal(point3d : nme.geom.Vector3D) : nme.geom.Point;
	function localToGlobal(point : nme.geom.Point) : nme.geom.Point;
}


#elseif (cpp || neko)
typedef DisplayObject = neash.display.DisplayObject;
#elseif js
typedef DisplayObject = jeash.display.DisplayObject;
#else
typedef DisplayObject = flash.display.DisplayObject;
#end