import nme.display.*;

class Main extends Sprite
{
   public function new()
   {
      super();
      var gfx = graphics;
      gfx.beginFill(0x00ff00);
      gfx.drawCircle(100,100,100);
   }
}

