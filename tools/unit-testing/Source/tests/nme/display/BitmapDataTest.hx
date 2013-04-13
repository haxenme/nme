package tests.nme.display;


import haxe.unit.TestCase;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.filters.GlowFilter;
import nme.geom.ColorTransform;
import nme.geom.Point;
import nme.geom.Rectangle;


@:keep class BitmapDataTest extends TestCase {
	
	
	public function testBasics () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		
		assertEquals (100, bitmapData.width);
		assertEquals (100, bitmapData.height);
		
		assertEquals (0.0, bitmapData.rect.x);
		assertEquals (0.0, bitmapData.rect.y);
		assertEquals (100.0, bitmapData.rect.width);
		assertEquals (100.0, bitmapData.rect.height);
		
		var pixel = bitmapData.getPixel (1, 1);
		
		#if neko
		
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (0xFF0000, pixel);
		
		#end
		
		pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		color = { a: 0x00, rgb: 0x00FF00 }
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		color = 0x0000FF00;
		
		#end
		
		for (setX in 0...100) {
			
			for (setY in 0...100) {
				
				bitmapData.setPixel32 (setX, setY, color);
				
			}
			
		}
		
		pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0x00, pixel.a);
		assertEquals (0x00FF00, pixel.rgb);
		
		#else
		
		assertTrue ((StringTools.hex (pixel, 8) == StringTools.hex (0x0000FF00, 8)) || pixel == 0);
		
		#end
		
		bitmapData.fillRect (bitmapData.rect, color);
		
		pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0x00, pixel.a);
		assertEquals (0x00FF00, pixel.rgb);
		
		#else
		
		assertTrue ((StringTools.hex (0x0000FF00, 8) == StringTools.hex (pixel, 8)) || pixel == 0);
		
		#end
		
	}
	
	
	public function testFilter () {
		
		var bitmapData = new BitmapData (100, 100);
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var filter = new GlowFilter (color, 1, 10, 10, 100);
		
		var sourceBitmapData = new BitmapData (100, 100, true, color);
		bitmapData.applyFilter (sourceBitmapData, sourceBitmapData.rect, new Point (), filter);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
		var filterRect = untyped bitmapData.generateFilterRect (bitmapData.rect, filter);
		
		assertTrue (filterRect.width > 100 && filterRect.width <= 115);
		assertTrue (filterRect.height > 100 && filterRect.height <= 115);
		
	}
	
	
	public function testClone () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		var cloneBitmapData = bitmapData.clone ();
		
		assertFalse (cloneBitmapData == bitmapData);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		var clonePixel = cloneBitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (pixel.a, clonePixel.a);
		assertEquals (pixel.rgb, clonePixel.rgb);
		
		#else
		
		assertEquals (pixel, clonePixel);
		
		#end
		
	}
	
	
	public function testColorTransform () {
		
		var bitmapData = new BitmapData (100, 100);
		bitmapData.colorTransform (bitmapData.rect, new ColorTransform (0, 0, 0, 1, 0xFF, 0, 0, 0));
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
	}
	
	
	public function testCopyChannel () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0x000000 };
		var color2 = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFF000000;
		var color2 = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		var sourceBitmapData = new BitmapData (100, 100, true, color2);
		
		bitmapData.copyChannel (sourceBitmapData, sourceBitmapData.rect, new Point (), BitmapDataChannel.RED, BitmapDataChannel.RED);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
	}
	
	
	public function testCopyPixels () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100);
		var sourceBitmapData = new BitmapData (100, 100, true, color);
		
		bitmapData.copyPixels (sourceBitmapData, sourceBitmapData.rect, new Point ());
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
	}
	
	
	public function testDispose () {
		
		var bitmapData = new BitmapData (100, 100);
		bitmapData.dispose ();
		
		#if flash
		
		try {
			bitmapData.width;
		} catch (e:Dynamic) {
			assertTrue (true);
		}
		
		#else
		
		assertEquals (0, bitmapData.width);
		assertEquals (0, bitmapData.height);
		
		#end
		
	}
	
	
	public function testDraw () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100);
		var sourceBitmap = new Bitmap (new BitmapData (100, 100, true, color));
		
		bitmapData.draw (sourceBitmap);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
	}
	
	
	#if (cpp || neko)
	
	public function testEncode () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		
		var png = bitmapData.encode ("png");
		bitmapData = BitmapData.loadFromBytes (png);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (0xFFFF0000, pixel);
		
		#end
		
		var jpg = bitmapData.encode ("jpg", 1);
		bitmapData = BitmapData.loadFromBytes (jpg);
		
		pixel = bitmapData.getPixel32 (1, 1);
		
		// Since JPG is a lossy format, we need to allow for slightly different values
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertTrue ((0xFF0000 == pixel.rgb) || (0xFE0000 == pixel.rgb));
		
		#else
		
		assertTrue ((0xFFFF0000 == pixel) || (0xFFFE0000 == pixel));
		
		#end
		
	}
	
	#end
	
	
	public function testColorBoundsRect () {
		
		#if neko
		
		var mask = { a: 0xFF, rgb: 0xFFFFFF };
		var color = { a: 0xFF, rgb: 0xFFFFFF };
		
		#else
		
		var mask = 0xFFFFFFFF;
		var color = 0xFFFFFFFF;
		
		#end
		
		var bitmapData = new BitmapData (100, 100);
		
		var colorBoundsRect = bitmapData.getColorBoundsRect (mask, color);
		
		assertEquals (100.0, colorBoundsRect.width);
		assertEquals (100.0, colorBoundsRect.height);
		
	}
	
	
	public function testGetAndSetPixels () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		var pixels = bitmapData.getPixels (bitmapData.rect);
		
		assertEquals (100 * 100 * 4, pixels.length);
		
		bitmapData = new BitmapData (100, 100);
		
		pixels.position = 0;
		bitmapData.setPixels (bitmapData.rect, pixels);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
	}
	
	
	/*public function testHitTest () {
		
		var bitmapData = new BitmapData (100, 100);
		
		assertFalse (bitmapData.hitTest (new Point (), 0, new Point (101, 101)));
		assertTrue (bitmapData.hitTest (new Point (), 0, new Point (100, 100)));
		
	}*/
	
	
	/*public function testMerge () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0x000000 };
		var color2 = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFF000000;
		var color2 = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		var sourceBitmapData = new BitmapData (100, 100, true, color2);
		
		bitmapData.merge (sourceBitmapData, sourceBitmapData.rect, new Point (), 1, 1, 1, 1);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (0xFFFF0000, pixel);
		
		#end
		
	}*/
	
	
	public function testScroll () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100);
		
		bitmapData.fillRect (new Rectangle (0, 0, 100, 10), color);
		bitmapData.scroll (0, 10);
		
		var pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFF0000, 8), StringTools.hex (pixel, 8));
		
		#end
		
		bitmapData.scroll (0, -20);
		
		pixel = bitmapData.getPixel32 (1, 1);
		
		#if neko
		
		assertEquals (0xFF, pixel.a);
		assertEquals (0xFFFFFF, pixel.rgb);
		
		#else
		
		assertEquals (StringTools.hex (0xFFFFFFFF, 8), StringTools.hex (pixel, 8));
		
		#end
		
	}
	
	
}