package tests.nme.display;


import haxe.unit.TestCase;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.DisplayObjectContainer;
import nme.display.Sprite;
import nme.geom.Point;
import nme.Lib;


@:keep class DisplayObjectContainerTest extends TestCase {
	
	
	public function testChildren () {
		
		var sprite:DisplayObjectContainer = new Sprite ();
		
		var bitmap:DisplayObject = new Bitmap (new BitmapData (100, 100));
		bitmap.name = "hello";
		
		sprite.addChild (bitmap);
		
		assertEquals (1, sprite.numChildren);
		assertTrue (sprite.contains (bitmap));
		
		assertEquals (bitmap, sprite.getChildAt (0));
		assertEquals (bitmap, sprite.getChildByName ("hello"));
		assertEquals (0, sprite.getChildIndex (bitmap));
		
		// Native getObjectsUnderPoint() method doesn't work unless the object is renderable
		
		Lib.current.stage.addChild (sprite);
		var objects = sprite.getObjectsUnderPoint (new Point (1, 1));
		assertEquals (1, objects.length);
		assertEquals (bitmap, objects[0]);
		Lib.current.stage.removeChild (sprite);
		
		var bitmap2 = new Bitmap (new BitmapData (100, 100));
		
		sprite.addChild (bitmap2);
		sprite.setChildIndex (bitmap2, 0);
		
		assertEquals (0, sprite.getChildIndex (bitmap2));
		
		sprite.swapChildren (bitmap, bitmap2);
		
		assertEquals (1, sprite.getChildIndex (bitmap2));
		
		sprite.swapChildrenAt (0, 1);
		
		assertEquals (0, sprite.getChildIndex (bitmap2));
		
		sprite.removeChild (bitmap);
		
		assertEquals (1, sprite.numChildren);
		assertFalse (sprite.contains (bitmap));
		
		sprite.removeChildAt (0);
		
		assertEquals (0, sprite.numChildren);
		assertFalse (sprite.contains (bitmap2));
		
	}
	

}
