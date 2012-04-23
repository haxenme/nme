package nme.display;
#if code_completion


extern class BitmapData implements IBitmapDrawable {
	var height(default,null) : Int;
	var rect(default,null) : nme.geom.Rectangle;
	var transparent(default,null) : Bool;
	var width(default,null) : Int;
	function new(width : Int, height : Int, transparent : Bool = true, fillColor : UInt = 0xFFFFFFFF) : Void;
	function applyFilter(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, filter : nme.filters.BitmapFilter) : Void;
	function clone() : BitmapData;
	function colorTransform(rect : nme.geom.Rectangle, colorTransform : nme.geom.ColorTransform) : Void;
	function compare(otherBitmapData : BitmapData) : Dynamic;
	function copyChannel(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, sourceChannel : UInt, destChannel : UInt) : Void;
	function copyPixels(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, ?alphaBitmapData : BitmapData, ?alphaPoint : nme.geom.Point, mergeAlpha : Bool = false) : Void;
	function dispose() : Void;
	function draw(source : IBitmapDrawable, ?matrix : nme.geom.Matrix, ?colorTransform : nme.geom.ColorTransform, ?blendMode : BlendMode, ?clipRect : nme.geom.Rectangle, smoothing : Bool = false) : Void;
	function fillRect(rect : nme.geom.Rectangle, color : UInt) : Void;
	function floodFill(x : Int, y : Int, color : UInt) : Void;
	function generateFilterRect(sourceRect : nme.geom.Rectangle, filter : nme.filters.BitmapFilter) : nme.geom.Rectangle;
	function getColorBoundsRect(mask : UInt, color : UInt, findColor : Bool = true) : nme.geom.Rectangle;
	function getPixel(x : Int, y : Int) : UInt;
	function getPixel32(x : Int, y : Int) : UInt;
	function getPixels(rect : nme.geom.Rectangle) : nme.utils.ByteArray;
	@:require(flash10) function getVector(rect : nme.geom.Rectangle) : nme.Vector<UInt>;
	@:require(flash10) function histogram(?hRect : nme.geom.Rectangle) : nme.Vector<nme.Vector<Float>>;
	function hitTest(firstPoint : nme.geom.Point, firstAlphaThreshold : UInt, secondObject : Dynamic, ?secondBitmapDataPoint : nme.geom.Point, secondAlphaThreshold : UInt = 1) : Bool;
	function lock() : Void;
	function merge(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, redMultiplier : UInt, greenMultiplier : UInt, blueMultiplier : UInt, alphaMultiplier : UInt) : Void;
	function noise(randomSeed : Int, low : UInt = 0, high : UInt = 255, channelOptions : UInt = 7, grayScale : Bool = false) : Void;
	function paletteMap(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, ?redArray : Array<Int>, ?greenArray : Array<Int>, ?blueArray : Array<Int>, ?alphaArray : Array<Int>) : Void;
	function perlinNoise(baseX : Float, baseY : Float, numOctaves : UInt, randomSeed : Int, stitch : Bool, fractalNoise : Bool, channelOptions : UInt = 7, grayScale : Bool = false, ?offsets : Array<nme.geom.Point>) : Void;
	function pixelDissolve(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, randomSeed : Int = 0, numPixels : Int = 0, fillColor : UInt = 0) : Int;
	function scroll(x : Int, y : Int) : Void;
	function setPixel(x : Int, y : Int, color : UInt) : Void;
	function setPixel32(x : Int, y : Int, color : UInt) : Void;
	function setPixels(rect : nme.geom.Rectangle, inputByteArray : nme.utils.ByteArray) : Void;
	@:require(flash10) function setVector(rect : nme.geom.Rectangle, inputVector : nme.Vector<UInt>) : Void;
	function threshold(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, operation : String, threshold : UInt, color : UInt = 0, mask : UInt = 0xFFFFFFFF, copySource : Bool = false) : UInt;
	function unlock(?changeRect : nme.geom.Rectangle) : Void;
}


#elseif (cpp || neko)
typedef BitmapData = neash.display.BitmapData;
#elseif js
typedef BitmapData = jeash.display.BitmapData;
#else
typedef BitmapData = flash.display.BitmapData;
#end