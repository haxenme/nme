package nme.display;


#if flash
@:native ("flash.display.Bitmap")
extern class Bitmap extends DisplayObject {
	var bitmapData : BitmapData;
	var pixelSnapping : PixelSnapping;
	var smoothing : Bool;
	function new(?bitmapData : BitmapData, ?pixelSnapping : PixelSnapping, smoothing : Bool = false) : Void;
}
#else



import nme.display.DisplayObject;
import nme.display.PixelSnapping;

class Bitmap extends DisplayObject {
   public var bitmapData(default,nmeSetBitmapData) : BitmapData;
   public var pixelSnapping : PixelSnapping;
   public var smoothing(default,nmeSetSmoothing) : Bool;

   var mGraphics:Graphics;

   public function new(?inBitmapData : BitmapData, ?inPixelSnapping : PixelSnapping, ?inSmoothing : Bool) : Void {
         super(DisplayObject.nme_create_display_object(),"Bitmap");
         pixelSnapping = inPixelSnapping;
         smoothing = inSmoothing;
         nmeSetBitmapData(inBitmapData);
   }

   function nmeRebuid()
   {
      var gfx = graphics;
      gfx.clear();
      if (bitmapData!=null)
      {
         gfx.beginBitmapFill(bitmapData,false,smoothing);
         gfx.drawRect(0,0,bitmapData.width,bitmapData.height);
         gfx.endFill();
      }
   }

   function nmeSetSmoothing(inSmooth:Bool) : Bool
   {
      smoothing = inSmooth;
      nmeRebuid();
      return inSmooth;
   }

   function nmeSetBitmapData(inBitmapData:BitmapData) : BitmapData
   {
	  bitmapData = inBitmapData;
     nmeRebuid();
     return inBitmapData;
   }

}
#end