import format.SVG;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.BitmapInt32;
import nme.display.Shape;


class ImageHelper {
	
	
	public static function rasterizeSVG (svg:SVG, width:Int, height:Int, backgroundColor:BitmapInt32 = null):BitmapData {
		
		if (backgroundColor == null) {
			
			backgroundColor = #if neko { a: 0, rgb: 0xFFFFFF }; #else backgroundColoor = 0x00FFFFFF; #end
			
		}
		
		var shape = new Shape ();
		svg.render (shape.graphics, 0, 0, width, height);
		
		var bitmapData = new BitmapData (width, height, true, backgroundColor);
		bitmapData.draw (shape);
		
		return bitmapData;
		
	}
	
	
	public static function resizeBitmapData (bitmapData:BitmapData, width:Int, height:Int):BitmapData {
		
		var bitmap = new Bitmap (bitmapData);
		
		bitmap.smoothing = true;
		bitmap.width = width;
		bitmap.height = height;
		
		var data = new BitmapData (width, height, true, { a: 0, rgb: 0xFFFFFF });
		data.draw (bitmap);
		
		return data;
		
	}
	
	
}