package nme.display;
import nme.geom.Rectangle;
import nme.geom.Point;
class TestBitmapData extends haxe.unit.TestCase
{
    public function testCopyChannelY() {
        var source:BitmapData =  new BitmapData(2,2,true,0xFFFFFF);
        var destination:BitmapData =  new BitmapData(2,2,true,0x000000);
        var bounds:Rectangle = new Rectangle(0,1,1,1);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0xFF0000, destination.getPixel32(0,0));
        assertEquals(0x000000, destination.getPixel32(0,1));
        assertEquals(0x000000, destination.getPixel32(1,0));
        assertEquals(0x000000, destination.getPixel32(1,1));
    }
}
