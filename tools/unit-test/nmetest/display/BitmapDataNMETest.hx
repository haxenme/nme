package nmetest.display;

import haxe.unit.*;
import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.utils.ByteArray;

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
		
		
		b.copyChannel(b0, new Rectangle(0,0,1,2), new Point(), BitmapDataChannel.RED, BitmapDataChannel.BLUE);
		this.assertEquals(0xFF44FF, b.getPixel(0, 0));
		this.assertEquals(0xFF44FF, b.getPixel(0, 1));
		this.assertEquals(0xFF4455, b.getPixel(0, 2));
		this.assertEquals(0xFF4455, b.getPixel(1, 0));
		this.assertEquals(0xFF4455, b.getPixel(1, 2));
		
		/* TODO
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
	
	public function testCopyPixels():Void {
		var b0 = new BitmapData(4, 3, true, 0xFF224455);
		var c:UInt = 0xEE112233;
		var b = new BitmapData(4, 3, true, c);
		
		b.copyPixels(b0, b.rect, new Point());
		var color:UInt = 0xFF224455;
		this.assertEquals(color, b.getPixel32(0, 0));
		
		var b = new BitmapData(4, 3, true, 0xEE112233);
		b.copyPixels(b0, new Rectangle(0,0,1,2), new Point());
		var color:UInt = 0xFF224455;
		this.assertEquals(color, b.getPixel32(0, 0));
		this.assertEquals(color, b.getPixel32(0, 1));
		this.assertEquals(c, b.getPixel32(0, 2));
		this.assertEquals(c, b.getPixel32(1, 0));
		this.assertEquals(c, b.getPixel32(2, 0));
		this.assertEquals(c, b.getPixel32(3, 0));
		
		//TODO: alpha
	}
	
	/* TODO
	public function testCopyPixelsToByteArray():Void {
		var b = new BitmapData(4, 3, true, 0xFF224455);
		var ba = new ByteArray();
		b.copyPixelsToByteArray(ba);
		this.assertEquals(48, ba.length);
	}
	*/
	
	public function testDispose():Void {
		var b = new BitmapData(4, 3);
		b.dispose();
		assertTrue(true);
	}
	
	public function testFillRect():Void {
		var f:UInt = 0xFF224455;
		var c:UInt = 0xEE112233;
		var b = new BitmapData(4, 3, true, c);
		b.fillRect(new Rectangle(0,0,1,2), f);
		this.assertEquals(f, b.getPixel32(0, 0));
		this.assertEquals(f, b.getPixel32(0, 1));
		this.assertEquals(c, b.getPixel32(0, 2));
		this.assertEquals(c, b.getPixel32(1, 0));
		this.assertEquals(c, b.getPixel32(2, 0));
		this.assertEquals(c, b.getPixel32(3, 0));
	}
	
	public function testFloodFill():Void {
		/*
			B B G G
			B B B G
			G B B G
			G G G G
		*/
		var R = 0xFF0000;
		var G = 0x00FF00;
		var B = 0x0000FF;
		var b = new BitmapData(4, 4, false, G);
		b.fillRect(new Rectangle(0, 0, 2, 2), B);
		b.fillRect(new Rectangle(1, 1, 2, 2), B);
		
		b.floodFill(1, 1, R);
		
		this.assertEquals(R, b.getPixel(0, 0));
		this.assertEquals(R, b.getPixel(1, 0));
		this.assertEquals(G, b.getPixel(2, 0));
		this.assertEquals(G, b.getPixel(3, 0));
		
		this.assertEquals(R, b.getPixel(0, 1));
		this.assertEquals(R, b.getPixel(1, 1));
		this.assertEquals(R, b.getPixel(2, 1));
		this.assertEquals(G, b.getPixel(3, 1));
		
		this.assertEquals(G, b.getPixel(0, 2));
		this.assertEquals(R, b.getPixel(1, 2));
		this.assertEquals(R, b.getPixel(2, 2));
		this.assertEquals(G, b.getPixel(3, 2));
		
		this.assertEquals(G, b.getPixel(0, 3));
		this.assertEquals(G, b.getPixel(1, 3));
		this.assertEquals(G, b.getPixel(2, 3));
		this.assertEquals(G, b.getPixel(3, 3));
		
	}
	
	public function testGetColorBoundsRect():Void {
		var bmd = new BitmapData(8, 4, false, 0xFFFFFF);
		var rect = new Rectangle(0, 0, 8, 2);
		bmd.fillRect(rect, 0xFF0000);
		
		var maskColor = 0xFFFFFF; 
		var color = 0xFF0000;  
		var redBounds = bmd.getColorBoundsRect(maskColor, color, true);
		this.assertEquals(0.0, redBounds.x);
		this.assertEquals(0.0, redBounds.y);
		this.assertEquals(8.0, redBounds.width);
		this.assertEquals(2.0, redBounds.height);
		
		var notRedBounds = bmd.getColorBoundsRect(maskColor, color, false);
		this.assertEquals(0.0, notRedBounds.x);
		this.assertEquals(2.0, notRedBounds.y);
		this.assertEquals(8.0, notRedBounds.width);
		this.assertEquals(2.0, notRedBounds.height);
	}
	
	#if !js //TODO
	public function testGetPixels():Void {
		/*
			B B G G
			B B B G
			G G G G
			G G G G
		*/
		var G:UInt = 0xFF00FF00;
		var B:UInt = 0xFF0000FF;
		var b = new BitmapData(4, 4, false, G);
		b.fillRect(new Rectangle(0, 0, 2, 2), B);
		b.fillRect(new Rectangle(1, 1, 2, 1), B);
		
		var pixels = b.getPixels(b.rect);
		this.assertEquals(16*4, pixels.length);
		this.assertEquals(16*4, pixels.position);
		pixels.position = 0;
		
		this.assertEquals(B, pixels.readUnsignedInt());
		this.assertEquals(B, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		
		this.assertEquals(B, pixels.readUnsignedInt());
		this.assertEquals(B, pixels.readUnsignedInt());
		this.assertEquals(B, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
		this.assertEquals(G, pixels.readUnsignedInt());
	}
	
	public function testGetVector():Void {
		/*
			B B G G
			B B B G
			G G G G
			G G G G
		*/
		var G:UInt = 0xFF00FF00;
		var B:UInt = 0xFF0000FF;
		var b = new BitmapData(4, 4, false, G);
		b.fillRect(new Rectangle(0, 0, 2, 2), B);
		b.fillRect(new Rectangle(1, 1, 2, 1), B);
		
		var pixels = b.getVector(b.rect);
		this.assertEquals(16, pixels.length);
		
		this.assertEquals(B, pixels[0]);
		this.assertEquals(B, pixels[1]);
		this.assertEquals(G, pixels[2]);
		this.assertEquals(G, pixels[3]);
		
		this.assertEquals(B, pixels[4]);
		this.assertEquals(B, pixels[5]);
		this.assertEquals(B, pixels[6]);
		this.assertEquals(G, pixels[7]);
		
		this.assertEquals(G, pixels[8]);
		this.assertEquals(G, pixels[9]);
		this.assertEquals(G, pixels[10]);
		this.assertEquals(G, pixels[11]);
		
		this.assertEquals(G, pixels[12]);
		this.assertEquals(G, pixels[13]);
		this.assertEquals(G, pixels[14]);
		this.assertEquals(G, pixels[15]);
	}
	#end
	
	/* TODO
	public function testHitTest():Void {
		var bmd1 = new BitmapData(80, 80, true, 0x00000000);
		bmd1.fillRect(new Rectangle(20, 20, 40, 40), 0xFF0000FF);
		
		var pt1 = new Point(1, 1);
		this.assertFalse(bmd1.hitTest(pt1, 0xFF, pt1));
		var pt2 = new Point(40, 40);
		this.assertTrue(bmd1.hitTest(pt1, 0xFF, pt2));
	}
	*/
	
	#if (flash || cpp) //TODO
	public function testNoise():Void {
		var b = new BitmapData(2, 2);
		b.noise(0);
		var c:UInt;
		this.assertEquals(c = 0xFFA7F1D9, b.getPixel32(0, 0));
		this.assertEquals(c = 0xFF2A82C8, b.getPixel32(1, 0));
		this.assertEquals(c = 0xFFD8FE43, b.getPixel32(0, 1));
		this.assertEquals(c = 0xFF4D9855, b.getPixel32(1, 1));
	}
	#end
	
	#if flash //TODO
	public function testPerlinNoise():Void {
		var b = new BitmapData(3, 3);
		b.perlinNoise(2, 2, 10, 0, true, true);
		var c:UInt;
		this.assertEquals(c = 0xFF7F7F7F, b.getPixel32(0, 0));
		this.assertEquals(c = 0xFF725C81, b.getPixel32(1, 0));
		this.assertEquals(c = 0xFF6E9C56, b.getPixel32(2, 0));
		this.assertEquals(c = 0xFF8F767B, b.getPixel32(0, 1));
		this.assertEquals(c = 0xFF7F568A, b.getPixel32(1, 1));
		this.assertEquals(c = 0xFF7A5E9E, b.getPixel32(2, 1));
		this.assertEquals(c = 0xFF678367, b.getPixel32(0, 2));
		this.assertEquals(c = 0xFF80856F, b.getPixel32(1, 2));
		this.assertEquals(c = 0xFF80B17B, b.getPixel32(2, 2));
	}
	#end
		
	#if !js
	public function testScroll():Void {
		var bmd:BitmapData = new BitmapData(8, 8, true, 0xFFCCCCCC);
		bmd.fillRect(new Rectangle(0, 0, 4, 4), 0xFFFF0000);
		var c:UInt;
		this.assertEquals(c = 0xFFCCCCCC, bmd.getPixel32(5, 2));
		bmd.scroll(3, 0); 
		this.assertEquals(c = 0xFFFF0000, bmd.getPixel32(5, 2));
	}
	#end
	
	public function testSetPixel():Void {
		var bmd:BitmapData = new BitmapData(2, 2);
		bmd.setPixel(0, 1, 0x112233);
		this.assertEquals(0xFFFFFF, bmd.getPixel(0, 0));
		this.assertEquals(0xFFFFFF, bmd.getPixel(1, 0));
		this.assertEquals(0x112233, bmd.getPixel(0, 1));
		this.assertEquals(0xFFFFFF, bmd.getPixel(1, 1));
	}
	
	public function testSetPixel32():Void {
		var bmd:BitmapData = new BitmapData(2, 2);
		bmd.setPixel32(0, 1, 0xFF112233);
		var c:UInt;
		this.assertEquals(c = 0xFFFFFFFF, bmd.getPixel32(0, 0));
		this.assertEquals(c = 0xFFFFFFFF, bmd.getPixel32(1, 0));
		this.assertEquals(c = 0xFF112233, bmd.getPixel32(0, 1));
		this.assertEquals(c = 0xFFFFFFFF, bmd.getPixel32(1, 1));
	}
	
	#if !js //TODO
	public function testSetPixels():Void {
		/*
			B B G G
			B B B G
			G G G G
			G G G G
		*/
		var G:UInt = 0xFF00FF00;
		var B:UInt = 0xFF0000FF;
		var b = new BitmapData(4, 4, false, G);
		b.fillRect(new Rectangle(0, 0, 2, 2), B);
		b.fillRect(new Rectangle(1, 1, 2, 1), B);
		var pixels = b.getPixels(b.rect);
		pixels.position = 0;
		var b = new BitmapData(4, 4, false);
		b.setPixels(b.rect, pixels);
		
		this.assertEquals(B, b.getPixel32(0, 0));
		this.assertEquals(B, b.getPixel32(1, 0));
		this.assertEquals(G, b.getPixel32(2, 0));
		this.assertEquals(G, b.getPixel32(3, 0));
		
		this.assertEquals(B, b.getPixel32(0, 1));
		this.assertEquals(B, b.getPixel32(1, 1));
		this.assertEquals(B, b.getPixel32(2, 1));
		this.assertEquals(G, b.getPixel32(3, 1));
		
		this.assertEquals(G, b.getPixel32(0, 2));
		this.assertEquals(G, b.getPixel32(1, 2));
		this.assertEquals(G, b.getPixel32(2, 2));
		this.assertEquals(G, b.getPixel32(3, 2));
		
		this.assertEquals(G, b.getPixel32(0, 3));
		this.assertEquals(G, b.getPixel32(1, 3));
		this.assertEquals(G, b.getPixel32(2, 3));
		this.assertEquals(G, b.getPixel32(3, 3));
	}
	
	public function testSetVector():Void {
		/*
			B B G G
			B B B G
			G G G G
			G G G G
		*/
		var G:UInt = 0xFF00FF00;
		var B:UInt = 0xFF0000FF;
		var b = new BitmapData(4, 4, false, G);
		b.fillRect(new Rectangle(0, 0, 2, 2), B);
		b.fillRect(new Rectangle(1, 1, 2, 1), B);
		var pixels = b.getVector(b.rect);
		var b = new BitmapData(4, 4, false);
		b.setVector(b.rect, pixels);
		
		this.assertEquals(B, b.getPixel32(0, 0));
		this.assertEquals(B, b.getPixel32(1, 0));
		this.assertEquals(G, b.getPixel32(2, 0));
		this.assertEquals(G, b.getPixel32(3, 0));
		
		this.assertEquals(B, b.getPixel32(0, 1));
		this.assertEquals(B, b.getPixel32(1, 1));
		this.assertEquals(B, b.getPixel32(2, 1));
		this.assertEquals(G, b.getPixel32(3, 1));
		
		this.assertEquals(G, b.getPixel32(0, 2));
		this.assertEquals(G, b.getPixel32(1, 2));
		this.assertEquals(G, b.getPixel32(2, 2));
		this.assertEquals(G, b.getPixel32(3, 2));
		
		this.assertEquals(G, b.getPixel32(0, 3));
		this.assertEquals(G, b.getPixel32(1, 3));
		this.assertEquals(G, b.getPixel32(2, 3));
		this.assertEquals(G, b.getPixel32(3, 3));
	}
	#end
	
	#if flash //TODO
	public function testThreshold():Void {
		var src = new BitmapData(4, 1);
		src.setPixel32(0, 0, 0xFF111111);
		src.setPixel32(1, 0, 0xFF333333);
		src.setPixel32(2, 0, 0xFF999999);
		src.setPixel32(3, 0, 0xFFFFFFFF);
		var c:UInt;
		
		var b = new BitmapData(4, 1);
		b.threshold(src, src.rect, new Point(), "<", 0xFF333333);
		this.assertEquals(0x000000, b.getPixel(0, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(1, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(2, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(3, 0));
		
		var b = new BitmapData(4, 1);
		b.threshold(src, src.rect, new Point(), "<=", 0xFF333333);
		this.assertEquals(0x000000, b.getPixel(0, 0));
		this.assertEquals(0x000000, b.getPixel(1, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(2, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(3, 0));
		
		var b = new BitmapData(4, 1);
		b.threshold(src, src.rect, new Point(), ">", 0xFF333333);
		this.assertEquals(0xFFFFFF, b.getPixel(0, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(1, 0));
		this.assertEquals(0x000000, b.getPixel(2, 0));
		this.assertEquals(0x000000, b.getPixel(3, 0));
		
		var b = new BitmapData(4, 1);
		b.threshold(src, src.rect, new Point(), ">=", 0xFF333333);
		this.assertEquals(0xFFFFFF, b.getPixel(0, 0));
		this.assertEquals(0x000000, b.getPixel(1, 0));
		this.assertEquals(0x000000, b.getPixel(2, 0));
		this.assertEquals(0x000000, b.getPixel(3, 0));
		
		var b = new BitmapData(4, 1);
		b.threshold(src, src.rect, new Point(), "==", 0xFF333333);
		this.assertEquals(0xFFFFFF, b.getPixel(0, 0));
		this.assertEquals(0x000000, b.getPixel(1, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(2, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(3, 0));
		
		var b = new BitmapData(4, 1);
		b.threshold(src, src.rect, new Point(), "!=", 0xFF333333);
		this.assertEquals(0x000000, b.getPixel(0, 0));
		this.assertEquals(0xFFFFFF, b.getPixel(1, 0));
		this.assertEquals(0x000000, b.getPixel(2, 0));
		this.assertEquals(0x000000, b.getPixel(3, 0));
	}
	#end
	
	
}