package nmetest.display;

import haxe.unit.*;
import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.geom.Point;
import nme.geom.Rectangle;

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
	
	public function testClone():Void {
		var bo = new BitmapData(4, 3, false, 0xFF0000);
		var b = bo.clone();
		this.assertEquals(bo.width, b.width);
		this.assertEquals(bo.height, b.height);
		this.assertEquals(bo.transparent, b.transparent);
		this.assertEquals(bo.getPixel32(0, 0), b.getPixel32(0, 0));
		this.assertEquals(bo.getPixel(0, 0), b.getPixel(0, 0));
		this.assertTrue(bo != b);
	}
	
	/* TODO
	public function testCompare():Void {
		var b0 = new BitmapData(4, 3, true, 0xFFFF0000);
		var b1 = new BitmapData(4, 3, true, 0xFFEE0000);
		var bd:BitmapData = b0.compare(b1);
		var color:UInt = 0xFF110000;
		this.assertEquals(color, bd.getPixel32(0, 0));
	}
	*/
	
	public function testCopyChannel():Void {
		var b0 = new BitmapData(4, 3, true, 0x99FF4455);
		var b = new BitmapData(4, 3, true, 0xEE112233);
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
		var color:UInt = 0xEEFF2233;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.GREEN);
		var color:UInt = 0xEEFFFF33;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.BLUE);
		var color:UInt = 0xEEFFFFFF;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		var color:UInt = 0xFFFFFFFF;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.GREEN, BitmapDataChannel.GREEN);
		var color:UInt = 0xFFFF44FF;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.BLUE, BitmapDataChannel.BLUE);
		var color:UInt = 0xFFFF4455;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		b.copyChannel(b0, b.rect, new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
		this.assertEquals(b0.getPixel32(0, 0), b.getPixel32(0, 0));
		
		/* TODO
		b.copyChannel(b0, new Rectangle(1,1,1,1), new Point(), BitmapDataChannel.RED, BitmapDataChannel.BLUE);
		this.assertEquals(0xFF4455, b.getPixel(1, 1));
		this.assertEquals(0xFF44FF, b.getPixel(0, 0));
		this.assertEquals(0xFF4455, b.getPixel(0, 2));
		this.assertEquals(0xFF4455, b.getPixel(1, 0));
		this.assertEquals(0xFF4455, b.getPixel(1, 2));
		
		b.copyChannel(b0, b.rect, new Point(1, 1), BitmapDataChannel.RED, BitmapDataChannel.BLUE);
		this.assertEquals(0xFF44FF, b.getPixel(1, 1));
		this.assertEquals(0xFF44FF, b.getPixel(2, 2));
		this.assertEquals(0xFF44FF, b.getPixel(3, 2));
		this.assertEquals(0xFF44FF, b.getPixel(0, 0));
		this.assertEquals(0xFF4455, b.getPixel(0, 1));
		this.assertEquals(0xFF4455, b.getPixel(0, 2));
		this.assertEquals(0xFF4455, b.getPixel(1, 0));
		this.assertEquals(0xFF4455, b.getPixel(2, 0));
		this.assertEquals(0xFF4455, b.getPixel(3, 0));
		*/
	}
}