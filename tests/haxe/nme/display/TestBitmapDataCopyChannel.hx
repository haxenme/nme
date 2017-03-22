package nme.display;
import nme.geom.Rectangle;
import nme.geom.Point;
class TestBitmapDataCopyChannel extends haxe.unit.TestCase
{
    var source:BitmapData;
    var destination:BitmapData;

    override public function setup()
    {
       nme.display.BitmapData.defaultPremultiplied = false;
    }

    override public function tearDown()
    {
       nme.display.BitmapData.defaultPremultiplied = false;
    }

    public function testX() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,1,1,1);
        destination.copyChannel(source, bounds, new Point(1,1), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(1,1));
    }

    public function testY() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,1,1,1);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0));
        assertEquals(0x00000000, destination.getPixel32(0,1));
        assertEquals(0x00000000, destination.getPixel32(1,0));
        assertEquals(0x00000000, destination.getPixel32(1,1));
    }

    public function testTopLeftDestination() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,0,2,2);
        destination.copyChannel(source, bounds, new Point(-1,-1), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0));
    }

    public function testTopLeftSource() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(-1,-1,2,2);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0));
    }

    public function testCopyToFarToRight():Void {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,1,true,0x00000000);
        var bounds:Rectangle = new Rectangle(1,0,2,1);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0));
        assertEquals(0x00000000, destination.getPixel32(1,0));
    }

    public function testDestinationOnRight_doesNotOverlapOnLeft():Void {
        source = new BitmapData(10,10,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,0,10,10);
        destination.copyChannel(source, bounds, new Point(1,0), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00000000, destination.getPixel32(0,0));
        assertEquals(0x00000000, destination.getPixel32(0,1));
    }

    public function testSpamPastingOverlappingBottom_shouldNotExplode():Void {
        for (i in 0...20) {
            var size = i;
            source = new BitmapData(size, size,true,0xFFFFFFFF);
            destination = new BitmapData(2,2,true,0x00000000);
            var bounds:Rectangle = new Rectangle(0,0, size, size);
            destination.copyChannel(source, bounds, new Point(0,1), BitmapDataChannel.RED, BitmapDataChannel.RED);
            assertEquals(0x00000000, destination.getPixel32(0,0));
            assertEquals(0x00000000, destination.getPixel32(1,0));
        }
    }

    public function testGreen():Void {
        copyChannel(BitmapDataChannel.GREEN);
        assertEquals(0x0000CC00, destination.getPixel32(0,0));
    }

    public function testBlue():Void {
        copyChannel(BitmapDataChannel.BLUE);
        assertEquals(0x000000DD, destination.getPixel32(0,0));
    }

    public function testAlpha():Void {
        copyChannel(BitmapDataChannel.ALPHA);
        assertEquals(0xAA000000, destination.getPixel32(0,0));
    }

    function copyChannel(channel:Int):Void {
        source = new BitmapData(1,1,true,0xAABBCCDD);
        destination = new BitmapData(1,1,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,0,1,1);
        destination.copyChannel(source, bounds, new Point(), channel, channel);
    }
}
