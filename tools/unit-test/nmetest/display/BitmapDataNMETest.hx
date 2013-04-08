package nmetest.display;

import haxe.unit.*;
import nme.display.BitmapData;

class BitmapDataNMETest extends TestCase implements TestBase {
	public function testNew():Void {
		var b = new BitmapData(4, 3);
		this.assertEquals(4.0, b.width);
		this.assertEquals(3.0, b.height);
	}
}