import nme.Lib;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.display.DisplayObject;
import nme.display.IGraphicsData;

class Sample extends nme.display.Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);

   var data = nme.display.BitmapData.load("Image.jpg");
   trace(data.width + "x" + data.height);
   var bmp = new nme.display.Bitmap(data);
   addChild(bmp);
}


public static function main()
{
#if flash
   new Sample();
#else
   Lib.init(320,480,60,0xccccff,(0*Lib.HARDWARE) | Lib.RESIZABLE);

   new Sample();

   Lib.mainLoop();
#end
}

}
