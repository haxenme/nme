package tests.nme.display;


import haxe.unit.TestCase;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.geom.Point;
import nme.Lib;


class DisplayObjectTest extends TestCase {
	
	
	public function testRect () {
		
		var sprite = new Sprite ();
		sprite.x = 100;
		sprite.y = 100;
		sprite.scaleX = 0.5;
		sprite.scaleY = 0.5;
		
		var bitmap = new Bitmap (new BitmapData (100, 100));
		sprite.addChild (bitmap);
		
		var rect = sprite.getRect (sprite);
		
		assertEquals (0.0, rect.x);
		assertEquals (0.0, rect.y);
		assertEquals (100.0, rect.width);
		assertEquals (100.0, rect.height);
		
		rect = sprite.getRect (Lib.current.stage);
		
		assertEquals (100.0, rect.x);
		assertEquals (100.0, rect.y);
		assertEquals (50.0, rect.width);
		assertEquals (50.0, rect.height);
		
		sprite.removeChild (bitmap);
		sprite.graphics.beginFill (0xFFFFFF);
		sprite.graphics.lineStyle (10);
		sprite.graphics.drawRect (0, 0, 100, 100);
		
		var bounds = sprite.getRect (sprite);
		
		assertTrue (bounds.x <= 0);
		assertTrue (bounds.y <= 0);
		assertTrue (bounds.width >= 100);
		assertTrue (bounds.height >= 100);
		
		bounds = sprite.getRect (Lib.current.stage);
		
		assertTrue (bounds.x <= 100);
		assertTrue (bounds.y <= 100);
		assertTrue (bounds.width >= 50);
		assertTrue (bounds.height >= 50);
		
	}
	
	
	public function testCoordinates () {
		
		var sprite = new Sprite ();
		sprite.x = 100;
		sprite.y = 100;
		sprite.scaleX = 0.5;
		sprite.scaleY = 0.5;
		
		var globalPoint = sprite.localToGlobal (new Point ());
		
		assertEquals (100.0, globalPoint.x);
		assertEquals (100.0, globalPoint.y);
		
		var localPoint = sprite.globalToLocal (new Point ());
		
		// It should be -200, not -100, because the scale of the Sprite is reduced
		
		assertEquals (-200.0, localPoint.x);
		assertEquals (-200.0, localPoint.y);
		
		var bitmap = new Bitmap (new BitmapData (100, 100));
		sprite.addChild (bitmap);
		
		assertTrue (sprite.hitTestPoint (100, 100));
		assertFalse (sprite.hitTestPoint (151, 151));
		
	}
	

}
