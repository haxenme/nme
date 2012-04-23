package format.swf.symbol;


import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import format.swf.data.SWFStream;
import flash.geom.Point;
import nme.display.BitmapInt32;

#if flash
import flash.display.Loader;
#end


class Bitmap {
	
	
	public var bitmapData:BitmapData;
	
	#if flash
	private var alpha:ByteArray;
	private var loader:Loader;
	#end
	
	
	public function new (stream:SWFStream, lossless:Bool, version:Int) {
		
		if (lossless) {
			
			var format = stream.readByte ();
			
			/*
				Formats:
				
				3 = RGB index (RGBA if version 2)
				4 = 15-bit RGB
				5 = 24-bit RGB (32-bit RGBA if version 2)
			*/
			
			if (version == 2 && format == 4) {
				
				throw ("No 15-bit format in DefineBitsLossless2");
				
			}
			
			var width = stream.readUInt16 ();
			var height = stream.readUInt16 ();
			var tableSize = 0;
			
			if (format == 3) {
				
				tableSize = stream.readByte () + 1;
				
			}
			
			var buffer:ByteArray = stream.readFlashBytes (stream.getBytesLeft ());
			buffer.uncompress ();
			
			var transparent = false;
			
			if (version == 2) {
				
				transparent = true;
				
			}
			
			if (format == 3) {
				
				var colorTable = new Array <Int> ();
				
				for (i in 0...tableSize) {
					
					var r = buffer.readByte ();
					var g = buffer.readByte ();
					var b = buffer.readByte ();
					
					if (transparent) {
						
						var a = buffer.readByte ();
						colorTable.push ((a << 24) + (r << 16) + (g << 8) + b);
						
					} else {
						
						colorTable.push ((r << 16) + (g << 8) + b);
						
					}
					
				}
				
				var imageData = new ByteArray ();
				var padding = Math.ceil (width / 4) - Math.floor (width / 4);
				
				for (y in 0...height) {
					
					for (x in 0...width) {
						
						imageData.writeUnsignedInt (colorTable[buffer.readByte ()]);
						
					}
					
					buffer.position += padding;
					
				}
				
				buffer = imageData;
				buffer.position = 0;
				
			}
			
			bitmapData = new BitmapData (width, height, transparent);
			bitmapData.setPixels (new Rectangle (0, 0, width, height), buffer);
			
		} else {
			
			var buffer:ByteArray = null;
			var alpha:ByteArray = null;
			
			if (version == 2) {
				
				var size = stream.getBytesLeft ();
				buffer = stream.readBytes (size);
				
			} else if (version == 3) {
				
				var size = stream.readInt ();
				buffer = stream.readBytes (size);
				
				alpha = stream.readFlashBytes (stream.getBytesLeft ());
				alpha.uncompress ();
				
			}
			
			#if flash
			
			loader = new Loader ();
			this.alpha = alpha;
			
			loader.contentLoaderInfo.addEventListener (Event.COMPLETE, loader_onComplete);
			loader.loadBytes (buffer);
			
			#else
			
			bitmapData = BitmapData.loadFromHaxeBytes (buffer, alpha);
			
			if (!lossless && alpha != null) {
				
				// NME doesn't currently handle alpha data for JPEG images, so we need to add it ourselves
				
				bitmapData = createWithAlpha (bitmapData, alpha);
				
			}
			
			#end
			
		}
		
	}
	
	
	private function createWithAlpha (data:BitmapData, alpha:ByteArray):BitmapData {
		
		var alphaBitmap = new BitmapData (data.width, data.height, true);
		var index = 0;
		
		for (y in 0...data.height) {
			
			for (x in 0...data.width) {
				
				#if !neko
				
				alphaBitmap.setPixel32 (x, y, data.getPixel (x, y) + (alpha[index ++] << 24));
				
				#else
				
				var pixel = data.getPixel32 (x, y);
				pixel.a = alpha[index ++];
				alphaBitmap.setPixel32 (x, y, pixel);
				
				#end
				
			}
			
		}
		
		return alphaBitmap;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	#if flash
	
	private function loader_onComplete (event:Event):Void {
		
		bitmapData = event.currentTarget.content.bitmapData;
		
		if (alpha != null && bitmapData != null) {
			
			var width = bitmapData.width;
			var height = bitmapData.height;
			
			if (Std.int (alpha.length) != Std.int (width * height)) {
				
				throw ("Alpha size mismatch");
				
			}
			
			bitmapData = createWithAlpha (bitmapData, alpha);
			
		}
		
		loader.removeEventListener (Event.COMPLETE, loader_onComplete);
		loader = null;
		alpha = null;
		
	}
	
	#end
	
	
}