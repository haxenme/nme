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
   stage.frameRate = 1000;

   var gfx = graphics;
   gfx.beginFill(0xff0000);
   gfx.lineStyle(6,0x000000);
   gfx.moveTo(100,100);
   gfx.lineTo(200,100);
   gfx.lineTo(200,200);
   gfx.lineTo(100,200);
   gfx.lineTo(100,100);

   var shape = new nme.display.Sprite();
   var gfx = shape.graphics;

	var vec =  new nme.Vector<IGraphicsData>();
	gfx.drawGraphicsDatum( new nme.display.GraphicsSolidFill(0xffff00) );
	gfx.drawGraphicsDatum( new nme.display.GraphicsStroke(6,false,nme.display.LineScaleMode.NORMAL,
	    nme.display.CapsStyle.ROUND,
	    nme.display.JointStyle.ROUND, 0.0,
	    new nme.display.GraphicsSolidFill(0x000000) ) );

	var path = new nme.display.GraphicsPath();
   path.moveTo(0,0);
   path.lineTo(100,0);
   path.lineTo(100,100);
   path.lineTo(0,100);
   path.lineTo(0,0);

	vec.push(path);
	gfx.drawGraphicsData( vec );

   shape.x = 50;
   shape.y = 50;

   shape.addEventListener(MouseEvent.MOUSE_MOVE,function(evt) trace(evt.localX+" "+evt.localY));

   stage.addChild(shape);

   var text = new nme.text.TextField();
   text.text = "Hello";
   stage.addChild(text);

   var fps:Array<Float> = [];
   
   stage.addEventListener(Event.ENTER_FRAME,function(evt) {
      var t0 =  haxe.Timer.stamp();
      fps.push(t0);
      if (fps.length>50)
          fps.pop();
      // trace(" Fps : " + ((fps.length-1)/( fps[fps.length-1] - fps[0] )) );
      var x = shape.x;
      shape.x = x>300 ? 0 : x+1;
      });
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
