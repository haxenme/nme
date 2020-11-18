package nme.display;
import nme.geom.Rectangle;

class TestTilesheet extends haxe.unit.TestCase
{
    
    var tilesheet:Tilesheet;
    
    override public function setup()
    {
        var bd = new BitmapData(32,32,true,0xFFFFFFFF);
        tilesheet = new Tilesheet( bd );
    }
    
     public function testGetTileRect() {
        var tileId:Int = tilesheet.addTileRect(new Rectangle (2, 4, 6, 8));
        var rect:Rectangle = tilesheet.getTileRect( tileId );
        assertEquals(rect.x, 2);
        assertEquals(rect.y, 4);
        assertEquals(rect.width, 6);
        assertEquals(rect.height, 8);
     }
     
     public function testGetTileRectNoNewAlloc()
     {
        var tileId:Int = tilesheet.addTileRect(new Rectangle (2, 4, 6, 8));
        var rect:Rectangle = new Rectangle(0,0,10,10);
        var result = tilesheet.getTileRect( tileId, rect );
        assertEquals(rect, result);
     }
    
     public function testGetTileRectOutOfBounds() {
        var rect1:Rectangle = tilesheet.getTileRect( -1 );
        assertEquals(rect1, null);
		
		var rect2:Rectangle = tilesheet.getTileRect( tilesheet.tileCount );
        assertEquals(rect2, null);
     }
}
