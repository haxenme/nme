import flash.Lib;
import flash.text.TextField;
import flash.display.Sprite;
import flash.net.URLRequest;
import flash.events.MouseEvent;
import flash.events.Event;


class Sample extends Sprite
{
   public function new()
   {
      super();

      Lib.current.stage.addChild(this);

      var label:TextField=new TextField();
	  label.width=800;
	  label.text="Click to open google!";
	  addChild(label);
	  Lib.current.stage.addEventListener(MouseEvent.CLICK,onClick);
   }

   public function onClick(inEvent:MouseEvent)
   {
		Lib.getURL(new URLRequest("http://www.google.com"));
   }

   public static function main()
   {
      new Sample();
   }

}
