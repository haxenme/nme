package nme.display;

import nme.display.DisplayObject;
import nme.display.PixelSnapping;

class Bitmap extends DisplayObject {
   public var bitmapData(default,nmeSetBitmapData) : BitmapData;
   public var pixelSnapping : PixelSnapping;
   public var smoothing : Bool;

   var mGraphics:Graphics;

   public function new(?inBitmapData : BitmapData, ?inPixelSnapping : PixelSnapping, ?inSmoothing : Bool) : Void {
         super(DisplayObject.nme_create_display_object(),"Bitmap");
         pixelSnapping = inPixelSnapping;
         smoothing = inSmoothing;
         nmeSetBitmapData(inBitmapData);
   }

   function nmeSetBitmapData(inBitmapData:BitmapData) : BitmapData
   {
      var gfx = graphics;
      gfx.clear();
		bitmapData = inBitmapData;
      if (inBitmapData!=null)
      {
         gfx.beginBitmapFill(inBitmapData,false,smoothing);
         gfx.drawRect(0,0,inBitmapData.width,inBitmapData.height);
         gfx.endFill();
      }
      return inBitmapData;
   }

}

