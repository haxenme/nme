package nme.display;
import nme.geom.Rectangle;

class TestTilesheet
{
    
    var tilesheet:Tilesheet;
    
    public function setup()
    {
        var bd = new BitmapData(32,32,true,0xFFFFFFFF);
        tilesheet = new Tilesheet( bd );
    }
    
     public function testGetTileRect() {
        var tileId:Int = tilesheet.addTileRect(new Rectangle (2, 4, 6, 8));
        var rect:Rectangle = tilesheet.getTileRect( tileId );
        assertEquals(rect.x, 2, "rect x");
        assertEquals(rect.y, 4, "rect y");
        assertEquals(rect.width, 6, "rect w");
        assertEquals(rect.height, 8, "rect h");
     }
     
     public function testGetTileRectNoNewAlloc()
     {
        var tileId:Int = tilesheet.addTileRect(new Rectangle (2, 4, 6, 8));
        var rect:Rectangle = new Rectangle(0,0,10,10);
        var result = tilesheet.getTileRect( tileId, rect );
        assertEquals(rect, result,"NoNewAlloc");
     }
    
     public function testGetTileRectOutOfBounds() {
        var rect1:Rectangle = tilesheet.getTileRect( -1 );
        assertEquals(rect1, null,"Null rect");

        var rect2:Rectangle = tilesheet.getTileRect( tilesheet.tileCount );
        assertEquals(rect2, null,"Null end-of-list");
     }

     function assertEquals(a:Dynamic,b:Dynamic,message:String)
     {
        if (a!=b)
           throw(message);
        Sys.println('$message .. ok');
     }

     public function new()
     {
         setup();
         testGetTileRect();
         testGetTileRectNoNewAlloc();
         testGetTileRectOutOfBounds();
     }
}
