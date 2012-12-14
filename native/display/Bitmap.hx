package native.display;


import native.display.DisplayObject;
import native.display.PixelSnapping;


class Bitmap extends DisplayObject {
	
	
	public var bitmapData(default, set_bitmapData):BitmapData;
	public var smoothing(default, set_smoothing):Bool;
	
	private var mGraphics:Graphics;
	
	
	public function new (bitmapData:BitmapData = null, pixelSnapping:PixelSnapping = null, smoothing:Bool = false):Void {
		
		super (DisplayObject.nme_create_display_object (), "Bitmap");
		
		this.pixelSnapping = pixelSnapping == null ? PixelSnapping.AUTO : pixelSnapping;
		this.smoothing = smoothing;
		
		if (bitmapData != null) {
			
			this.bitmapData = bitmapData;
			
		} else if (this.bitmapData != null) {
			
			nmeRebuild ();
			
		}
		
	}
	
	
	private function nmeRebuild () {
		
		if (nmeHandle != null && bitmapData != null) {
			
			var gfx = graphics;
			gfx.clear ();
			
			if (bitmapData != null) {
				
				gfx.beginBitmapFill (bitmapData, false, smoothing);
				gfx.drawRect (0, 0, bitmapData.width, bitmapData.height);
				gfx.endFill ();
				
			}
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_bitmapData (inBitmapData:BitmapData):BitmapData {
		
		bitmapData = inBitmapData;
		nmeRebuild ();
		
		return inBitmapData;
		
	}
	
	
	private function set_smoothing(inSmooth:Bool):Bool {
		
		smoothing = inSmooth;
		nmeRebuild ();
		
		return inSmooth;
		
	}
	
	
}