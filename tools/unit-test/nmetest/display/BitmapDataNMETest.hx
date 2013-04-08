package nmetest.display;

import haxe.unit.*;
import nme.display.BitmapData;

#if !flash
typedef UInt = Int;
#end

class BitmapDataNMETest extends TestCase implements TestBase {
	public function testNew():Void {
		var color:UInt = 0xFFFFFFFF;
		var b = new BitmapData(4, 3);
		this.assertEquals(4, b.width);
		this.assertEquals(3, b.height);
		this.assertTrue(b.transparent);
		this.assertEquals(color, b.getPixel32(0, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(0, 0));
		
		var b = new BitmapData(4, 3, false);
		this.assertEquals(4, b.width);
		this.assertEquals(3, b.height);
		this.assertFalse(b.transparent);
		this.assertEquals(color, b.getPixel32(0, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(0, 0));
		
		var color:UInt = 0xFFFF0000;
		var b = new BitmapData(4, 3, true, color);
		this.assertEquals(4, b.width);
		this.assertEquals(3, b.height);
		this.assertTrue(b.transparent);
		this.assertEquals(color, b.getPixel32(0, 0));
		this.assertEquals(0xFF0000, b.getPixel(0, 0));
		
		var b = new BitmapData(4, 3, false, 0xFF0000);
		this.assertEquals(4, b.width);
		this.assertEquals(3, b.height);
		this.assertFalse(b.transparent);
		this.assertEquals(color, b.getPixel32(0, 0));
		this.assertEquals(0xFF0000, b.getPixel(0, 0));
	}
}