package nme.display;
#if code_completion


extern class Bitmap extends DisplayObject {
	var bitmapData : BitmapData;
	var pixelSnapping : PixelSnapping;
	var smoothing : Bool;
	function new(?bitmapData : BitmapData, ?pixelSnapping : PixelSnapping, smoothing : Bool = false) : Void;
}


#elseif (cpp || neko)
typedef Bitmap = neash.display.Bitmap;
#elseif js
typedef Bitmap = jeash.display.Bitmap;
#else
typedef Bitmap = flash.display.Bitmap;
#end