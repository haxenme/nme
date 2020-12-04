package nme.display;
import nme.geom.Rectangle;
import nme.geom.Point;
class TestBitmapDataCopyChannel
{
    var source:BitmapData;
    var destination:BitmapData;

    public function new()
    {
       setup();
       testX();
       testY();
       testTopLeftDestination();
       testTopLeftSource();
       testCopyToFarToRight();
       testDestinationOnRight_doesNotOverlapOnLeft();
       testSpamPastingOverlappingBottom_shouldNotExplode();
       testGreen();
       testBlue();
       testAlpha();

       tearDown();
    }


    function assertEquals(a:Dynamic,b:Dynamic,message:String)
    {
       if (a!=b)
          throw(message);
       Sys.println('$message .. ok');
    }

    public function setup()
    {
       nme.display.BitmapData.defaultPremultiplied = false;
    }

    public function tearDown()
    {
       nme.display.BitmapData.defaultPremultiplied = true;
    }

    public function testX() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,1,1,1);
        destination.copyChannel(source, bounds, new Point(1,1), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(1,1),"copy channel red");
    }

    public function testY() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,1,1,1);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0),"copy channel 00");
        assertEquals(0x00000000, destination.getPixel32(0,1),"copy channel 01");
        assertEquals(0x00000000, destination.getPixel32(1,0),"copy channel 10");
        assertEquals(0x00000000, destination.getPixel32(1,1),"copy channel 11");
    }

    public function testTopLeftDestination() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,0,2,2);
        destination.copyChannel(source, bounds, new Point(-1,-1), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0),"top-left dest");
    }

    public function testTopLeftSource() {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(-1,-1,2,2);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0),"top-left source");
    }

    public function testCopyToFarToRight():Void {
        source = new BitmapData(2,2,true,0xFFFFFFFF);
        destination = new BitmapData(2,1,true,0x00000000);
        var bounds:Rectangle = new Rectangle(1,0,2,1);
        destination.copyChannel(source, bounds, new Point(), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00FF0000, destination.getPixel32(0,0),"copy right");
        assertEquals(0x00000000, destination.getPixel32(1,0),"copy right");
    }

    public function testDestinationOnRight_doesNotOverlapOnLeft():Void {
        source = new BitmapData(10,10,true,0xFFFFFFFF);
        destination = new BitmapData(2,2,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,0,10,10);
        destination.copyChannel(source, bounds, new Point(1,0), BitmapDataChannel.RED, BitmapDataChannel.RED);
        assertEquals(0x00000000, destination.getPixel32(0,0),"not overlap");
        assertEquals(0x00000000, destination.getPixel32(0,1),"not overlap");
    }

    public function testSpamPastingOverlappingBottom_shouldNotExplode():Void {
        for (i in 0...20) {
            var size = i;
            source = new BitmapData(size, size,true,0xFFFFFFFF);
            destination = new BitmapData(2,2,true,0x00000000);
            var bounds:Rectangle = new Rectangle(0,0, size, size);
            destination.copyChannel(source, bounds, new Point(0,1), BitmapDataChannel.RED, BitmapDataChannel.RED);
        }
        assertEquals(0x00000000, destination.getPixel32(0,0),"paste ok");
        assertEquals(0x00000000, destination.getPixel32(1,0),"paste ok");
    }

    public function testGreen():Void {
        copyChannel(BitmapDataChannel.GREEN);
        assertEquals(0x0000CC00, destination.getPixel32(0,0),"green pixel");
    }

    public function testBlue():Void {
        copyChannel(BitmapDataChannel.BLUE);
        assertEquals(0x000000DD, destination.getPixel32(0,0),"blue pixel");
    }

    public function testAlpha():Void {
        copyChannel(BitmapDataChannel.ALPHA);
        assertEquals(0xAA000000, destination.getPixel32(0,0),"alpha pixel");
    }

    function copyChannel(channel:Int):Void {
        source = new BitmapData(1,1,true,0xAABBCCDD);
        destination = new BitmapData(1,1,true,0x00000000);
        var bounds:Rectangle = new Rectangle(0,0,1,1);
        destination.copyChannel(source, bounds, new Point(), channel, channel);
    }
}
