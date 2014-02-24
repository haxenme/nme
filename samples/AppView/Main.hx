import nme.display.Sprite;

class Main extends Sprite
{
   var colour:Int;
   var speed:Float;

   public function new()
   {
      super();
      colour = 0xff0000;
      speed = 1.0;
      addEventListener(nme.events.Event.ENTER_FRAME, onUpdate);
      redraw();
   }

   function onUpdate(_)
   {
      x = x + speed;
      if (x>stage.stageWidth-100)
         x = 100;
   }

   function redraw()
   {
      var gfx = graphics;
      gfx.clear();
      gfx.beginFill(colour);
      gfx.drawCircle(0,100,100);
   }

   public function setProperty(inName:String, inValue:String)
   {
      switch(inName)
      {
         case "y", "scaleX", "scaleY", "speed":
            Reflect.setProperty(this, inName, Std.parseFloat(inValue));
         case "colour", "color":
            if (inValue.substr(0,2)!="0x")
               inValue = "0x" + inValue;
            colour = Std.parseInt(inValue);
            redraw();
      }
   }
}

