package tests.nme.display;


import haxe.unit.TestCase;
import nme.display.Bitmap;
import nme.display.BitmapData;


class BitmapTest extends TestCase {
	
	
	public function testBitmap () {
		
		var bitmap = new Bitmap ();
		var bitmapData = new BitmapData (100, 100, false, 0xFF0000);
		
		bitmap.bitmapData = bitmapData;
		
		assertEquals (100.0, bitmap.width);
		assertEquals (100.0, bitmap.height);
		
		bitmap.bitmapData = null;
		
		assertEquals (0.0, bitmap.width);
		assertEquals (0.0, bitmap.height);
		
	}
	
	
}