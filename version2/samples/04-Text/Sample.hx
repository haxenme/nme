import nme.Lib;
import nme.events.FocusEvent;
import nme.events.KeyboardEvent;
import nme.display.InteractiveObject;
import nme.ui.Keyboard;


class Sample
{
   var tf:nme.text.TextField;

   public function new()
   {
      tf = new nme.text.TextField();
      tf.type = nme.text.TextFieldType.INPUT;
      tf.text = "Hello Hello Hello, what's all this here then?";
      tf.background = true;
      tf.backgroundColor = 0xccccff;
      tf.border = true;
      tf.borderColor = 0x000000;
      tf.x = 100;
      tf.y = 100;
      nme.Lib.current.addChild(tf);
      AddHandlers(tf);


      var p1 = new nme.display.Sprite();
      AddHandlers(p1);
      nme.Lib.current.stage.addChild(p1);


      tf = new nme.text.TextField();
      tf.type = nme.text.TextFieldType.INPUT;
      tf.htmlText = "<p align='center'>Hello Hello <b>Hello</b>, what's all this here then?</p>";
      tf.background = true;
      tf.backgroundColor = 0xccccff;
      tf.border = true;
      tf.multiline = true;
      tf.wordWrap = true;
      tf.borderColor = 0x000000;
      tf.autoSize = nme.text.TextFieldAutoSize.LEFT;
      tf.x = 100;
      tf.y = 300;
      p1.addChild(tf);
      AddHandlers(tf);
      tf.addEventListener(KeyboardEvent.KEY_DOWN,reportKeyDown);
      tf.addEventListener(KeyboardEvent.KEY_UP,reportKeyUp);
   }


	function reportKeyDown(event:KeyboardEvent)
	{
	    trace("Key Pressed: " + String.fromCharCode(event.charCode) + 
		" (key code: " + event.keyCode + " character code: " 
		+ event.charCode + ")");
	    if (event.keyCode == Keyboard.SHIFT) tf.borderColor = 0xFF0000;
	}

	function reportKeyUp(event:KeyboardEvent)
	{
	    trace("Key Released: " + String.fromCharCode(event.charCode) + 
		" (key code: " + event.keyCode + " character code: " + 
		event.charCode + ")");
	    if (event.keyCode == Keyboard.SHIFT)
	    {
		tf.borderColor = 0x000000;
	    }
	}

   function traceEvent(e:nme.events.Event)
   {
      trace(e);
   }

   function AddHandlers(inObj:InteractiveObject)
   {
      inObj.addEventListener(FocusEvent.FOCUS_IN, traceEvent );
      inObj.addEventListener(FocusEvent.FOCUS_OUT, traceEvent );
      inObj.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, traceEvent );
      inObj.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, traceEvent );
   }

   public static function main()
   {
   #if flash
      new Sample();
   #else
      Lib.init(320,480,60,0xffffff,(0*Lib.HARDWARE) | Lib.RESIZABLE);

      new Sample();

      Lib.mainLoop();
   #end
   }

}
