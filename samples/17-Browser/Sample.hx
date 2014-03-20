import nme.Lib;
import nme.text.TextField;
import nme.display.Sprite;
import nme.net.URLRequest;
import nme.events.MouseEvent;
import nme.events.Event;


class Sample extends Sprite
{
   public function new()
   {
      super();

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

}
