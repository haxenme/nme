package nme.display;
import nme.geom.Rectangle;
import nme.geom.Point;
class TestBitmapData extends haxe.unit.TestCase
{
    public function testCopyChannelY() {
        var source:BitmapData =  new BitmapData(4,4,true,0xFFFFFF);
        var destination:BitmapData =  new BitmapData(4,4,true,0x000000);
        var bounds:Rectangle = new Rectangle(2,3,1,1);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0xFF0000, destination.getPixel32(2,3));
    }
}
