package ::mainPackage::;

import nme.display.Sprite;

class ::main:: extends Sprite
{
   public function new()
   {
      super();

      var gfx = graphics;
      gfx.beginFill(0xff0000);
      gfx.lineStyle(1,0x000000);
      gfx.drawCircle(200,200,100);
   }
}
