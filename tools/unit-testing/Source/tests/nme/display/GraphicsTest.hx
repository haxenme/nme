package tests.nme.display;


import haxe.unit.TestCase;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.GradientType;
import nme.display.Sprite;
import nme.geom.Matrix;


@:keep class GraphicsTest extends TestCase {
	
	
	public function testGeometry () {
		
		var sprite = new Sprite ();
		
		assertEquals (0.0, sprite.width);
		assertEquals (0.0, sprite.height);
		
		sprite.graphics.beginFill (0xFF0000);
		sprite.graphics.drawRect (0, 0, 100, 100);
		
		assertEquals (100.0, sprite.width);
		assertEquals (100.0, sprite.height);
		
		sprite.graphics.clear ();
		
		assertEquals (0.0, sprite.width);
		assertEquals (0.0, sprite.height);
		
	}
	
	
	public function testBitmapFill () {
		
		#if neko
		
		var color = { a: 0xFF, rgb: 0xFF0000 };
		
		#else
		
		var color = 0xFFFF0000;
		
		#end
		
		var bitmapData = new BitmapData (100, 100, true, color);
		var sprite = new Sprite ();
		
		sprite.graphics.beginBitmapFill (bitmapData);
		sprite.graphics.drawRect (0, 0, 100, 100);
		
		var test = new BitmapData (100, 100);
		test.draw (sprite);
		
		var pixel = test.getPixel (1, 1);
		
		#if neko
		
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (0xFF0000, pixel);
		
		#end
		
	}
	
	
	public function testFill () {
		
		var sprite = new Sprite ();
		
		sprite.graphics.beginFill (0xFF0000);
		sprite.graphics.drawRect (0, 0, 100, 100);
		
		var test = new BitmapData (100, 100);
		test.draw (sprite);
		
		var pixel = test.getPixel (1, 1);
		
		#if neko
		
		assertEquals (0xFF0000, pixel.rgb);
		
		#else
		
		assertEquals (0xFF0000, pixel);
		
		#end
		
	}
	
	
	public function testGradientFill () {
		
		var sprite = new Sprite ();
		
		var colors = [ 0x000000, 0xFF0000, 0xFFFFFF ];
		var alphas = [ 0xFF, 0xFF, 0xFF ];
		var ratios = [ 0x00, 0x88, 0xFF ];
		
		var matrix = new Matrix ();
		matrix.createGradientBox (256, 256);
		
		sprite.graphics.beginGradientFill (GradientType.LINEAR, colors, alphas, ratios, matrix);
		sprite.graphics.drawRect (0, 0, 256, 256);
		
		var test = new BitmapData (256, 256);
		test.draw (sprite);
		
		var pixel = test.getPixel32 (1, 0);
		var pixel2 = test.getPixel32 (128, 1);
		var pixel3 = test.getPixel32 (255, 1);
		
		// Not perfect, but should work alright to check for the gradient
		
		#if neko
		
		assertTrue ((pixel.rgb & 0xFFFFFFFF) < 0x22);
		assertTrue (((pixel2.rgb & 0xFF0000) >> 16) > 0xEE);
		assertTrue (((pixel2.rgb & 0x00FF00) >> 8) < 0x22);
		assertTrue ((pixel3.rgb & 0xFFFFFFFF) > 0xFFF0F0F0);
		
		#else
		
		assertTrue ((pixel & 0xFFFFFFFF) < 0x22);
		assertTrue (((pixel2 & 0xFF0000) >> 16) > 0xEE);
		assertTrue (((pixel2 & 0x00FF00) >> 8) < 0x22);
		assertTrue ((pixel3 & 0xFFFFFFFF) > 0xFFF0F0F0);
		
		#end
		
	}
	
	
	public function testCircle () {
		
		var sprite = new Sprite ();
		
		sprite.graphics.beginFill (0xFF0000);
		sprite.graphics.drawCircle (50, 50, 50);
		
		var test = new BitmapData (100, 100);
		test.draw (sprite);
		
		var pixel = test.getPixel (1, 1);
		var pixel2 = test.getPixel (50, 50);
		
		#if neko
		
		assertEquals (0xFFFFFF, pixel.rgb);
		assertEquals (0xFF0000, pixel2.rgb);
		
		#else
		
		assertEquals (0xFFFFFF, pixel);
		assertEquals (0xFF0000, pixel2);
		
		#end
		
	}
	
	
	public function testEllipse () {
		
		var sprite = new Sprite ();
		
		sprite.graphics.beginFill (0xFF0000);
		sprite.graphics.drawEllipse (0, 25, 100, 50);
		
		var test = new BitmapData (100, 100);
		test.draw (sprite);
		
		var pixel = test.getPixel (1, 1);
		var pixel2 = test.getPixel (50, 50);
		var pixel3 = test.getPixel (50, 20);
		
		#if neko
		
		assertEquals (0xFFFFFF, pixel.rgb);
		assertEquals (0xFF0000, pixel2.rgb);
		assertEquals (0xFFFFFF, pixel3.rgb);
		
		#else
		
		assertEquals (0xFFFFFF, pixel);
		assertEquals (0xFF0000, pixel2);
		assertEquals (0xFFFFFF, pixel3);
		
		#end
		
	}
	
	
}
