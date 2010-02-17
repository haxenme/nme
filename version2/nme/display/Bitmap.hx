package nme.display;

import nme.display.DisplayObject;
import nme.display.PixelSnapping;

class Bitmap extends DisplayObject {
	public var bitmapData(default,nmeSetBitmapData) : BitmapData;
	public var pixelSnapping : PixelSnapping;
	public var smoothing : Bool;

   var mGraphics:Graphics;

	public function new(?inBitmapData : BitmapData, ?inPixelSnapping : PixelSnapping, ?inSmoothing : Bool) : Void {
			super();
			pixelSnapping = inPixelSnapping;
			smoothing = inSmoothing;
			mGraphics = new Graphics();
			nmeSetBitmapData(inBitmapData);
	}

   function nmeSetBitmapData(inBitmapData:BitmapData) : BitmapData
   {
      bitmapData = inBitmapData;
      mGraphics.clear();
      if (inBitmapData!=null)
      {
         mGraphics.beginBitmapFill(inBitmapData,false,smoothing);
         mGraphics.drawRect(0,0,inBitmapData.width,inBitmapData.height);
         mGraphics.endFill();
      }
      return inBitmapData;
   }


   override public function GetGraphics() { return mGraphics; }

}

