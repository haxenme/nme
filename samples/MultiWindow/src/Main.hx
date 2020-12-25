import nme.display.Sprite;
import nme.display.FPS;
import nme.app.Window;
import nme.events.*;

class Main extends Sprite
{
   static var childCount = 0;
   static var rates = [0, 10, 25, 0, 2 ];
   public function new()
   {
      super();
      var shape = new Sprite();
      addChild(shape);
      var gfx = shape.graphics;
      gfx.beginFill(0xff0000);
      gfx.drawRect(10,10,200,200);
      addChild( new FPS(10,10,0x000000) );

      if (Window.supportsSecondary)
      {
         stage.addEventListener( MouseEvent.CLICK, (_) -> createWindow() );
      }
      else
      {
         trace("This system does not support secondary windows");
      }
      addEventListener(Event.ENTER_FRAME, (_) -> shape.x = (shape.x+1)%250 );
   }

   public function createWindow()
   {
      var fps = rates[childCount % rates.length];
      var name = "New Window:" + (childCount++) + " fps=" + fps;
      var window = nme.Lib.createSecondaryWindow(
        500, 600, name,
        nme.app.Application.HARDWARE | nme.app.Application.RESIZABLE,
        0x303030, fps );

      var s = window.stage;
      var shape = new Sprite();
      s.current.addChild(shape);
      var gfx = shape.graphics;
      gfx.beginFill(0x0000ff);
      gfx.drawCircle(100,100,100);
      var fps = new FPS(10,10,0xffffff);
      s.current.addChild(fps);
      s.addEventListener( MouseEvent.CLICK, onChildClick );
      s.addEventListener(Event.ENTER_FRAME, (_) -> shape.x = (shape.x+1)%250 );
   }

   function onChildClick(ev:MouseEvent)
   {
      trace("onChild:" + ev.target.stage );
   }
}


