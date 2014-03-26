import nme.display.Sprite;

class Main extends Sprite
{
   public function new()
   {
      super();
      var gfx = graphics;
      gfx.beginFill(0xff0000);
      gfx.drawRect(10,10,200,200);
   }
}
