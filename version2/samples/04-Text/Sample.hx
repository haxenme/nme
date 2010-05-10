#if !flash
import nme.Lib;
import nme.events.Event;
import nme.events.FocusEvent;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.text.TextField;
import nme.text.TextFieldType;
import nme.text.TextFieldAutoSize;
import nme.display.InteractiveObject;
import nme.display.Sprite;
import nme.display.DisplayObject;
import nme.geom.Rectangle;
import nme.ui.Keyboard;
#else
import flash.Lib;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFieldAutoSize;
import flash.display.InteractiveObject;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.geom.Rectangle;
import flash.ui.Keyboard;
#end


class Scrollbar extends Sprite
{
   var mThumbHeight:Float;
   var mPage:Float;
   var mHeight:Float;
   var mRange:Float;
	var mThumb:Sprite;
	var mRemoveFrom:DisplayObject;

   public function new(inWidth:Float, inHeight:Float, inRange:Float, inPage:Float)
   {
      super();
      var gfx = graphics;
      gfx.lineStyle(1,0x404040);
      gfx.beginFill(0xeeeeee);
      gfx.drawRect(0,0,inWidth,inHeight);

      mThumbHeight = inHeight * inPage / inRange;
      mRange = inRange;
      mHeight = inHeight;
      mPage = inPage;
      var thumb = new Sprite();
      var gfx = thumb.graphics;
      gfx.lineStyle(1,0x000000);
      gfx.beginFill(0xffffff);
      gfx.drawRect(0,0,inWidth,mThumbHeight);
      addChild(thumb);
		mThumb = thumb;

		thumb.addEventListener( MouseEvent.MOUSE_DOWN, thumbStart );
   }

	dynamic public function scrolled(inTo:Float)
	{
	}

	function onScroll(e:MouseEvent)
	{
		var denom = mHeight-mThumbHeight;
		if (denom>0)
		{
		   var ratio = mThumb.y/denom;
			scrolled(ratio*mRange);
		}
	}

	function thumbStart(e:MouseEvent)
	{
		mRemoveFrom = stage;
		mThumb.addEventListener( MouseEvent.MOUSE_UP, thumbStop );
		mRemoveFrom.addEventListener( MouseEvent.MOUSE_UP, thumbStop );
		mRemoveFrom.addEventListener( MouseEvent.MOUSE_MOVE, onScroll );
		mThumb.startDrag(false, new Rectangle(0,0,0,mHeight-mThumbHeight));
	}
	function thumbStop(e:MouseEvent)
	{
		mThumb.stopDrag();
		mThumb.removeEventListener( MouseEvent.MOUSE_UP, thumbStop );
		mRemoveFrom.removeEventListener( MouseEvent.MOUSE_UP, thumbStop );
		mRemoveFrom.removeEventListener( MouseEvent.MOUSE_MOVE, onScroll );
	}
}


class Sample
{
   var tf:TextField;

   public function new()
   {
	   var file = "Sample.hx";
	   #if flash
      var loader = new flash.net.URLLoader();
		var me = this;
      loader.addEventListener(Event.COMPLETE, function(event:Event) { me.Run(loader.data); } );
		loader.load(new flash.net.URLRequest(file));
		#else
		Run(neko.io.File.getContent(file));
		#end
	}


   function Run(inContents:String)
	{
	   inContents = StringTools.replace(inContents,"\r","");
      tf = new TextField();
      tf.type = TextFieldType.INPUT;
      tf.text = "Hello Hello Hello, what's all this here then?";
      tf.background = true;
      tf.backgroundColor = 0xccccff;
      tf.border = true;
      tf.borderColor = 0x000000;
      tf.x = 100;
      tf.y = 100;
      Lib.current.addChild(tf);
      AddHandlers(tf);

      var f1 = createBox(inContents);
      Lib.current.addChild(f1);



      var p1 = new Sprite();
      AddHandlers(p1);
      Lib.current.stage.addChild(p1);


      tf = new TextField();
      tf.type = TextFieldType.INPUT;
      tf.htmlText = "<p align='center'>Hello Hello <b>Hello</b>, what's all this here then?</p>";
      tf.background = true;
      tf.backgroundColor = 0xccccff;
      tf.border = true;
      tf.multiline = true;
      tf.wordWrap = true;
      tf.borderColor = 0x000000;
      tf.autoSize = TextFieldAutoSize.LEFT;
      tf.x = 100;
      tf.y = 300;
      p1.addChild(tf);
      AddHandlers(tf);
      tf.addEventListener(KeyboardEvent.KEY_DOWN,reportKeyDown);
      tf.addEventListener(KeyboardEvent.KEY_UP,reportKeyUp);

      tf.stage.frameRate = 250;
   }

   function createBox(inContents:String)
   {
      var frame = new Sprite();
      var gfx = frame.graphics;
      gfx.lineStyle(1,0x000000);
      gfx.beginFill(0xeeeeff);
      gfx.drawRoundRect(0,0,200,300,20,20);

      var title = new TextField();
      title.x = 10;
      title.y = 8;
      title.htmlText = "<b>Sample.hx</b>";
      title.selectable = false;
      frame.addChild(title);


      var tf = new TextField();
      tf.x = 10;
      tf.y = 30;
      tf.width = 160;
      tf.height = 260;
      tf.border = true;
      tf.borderColor = 0x000000;
      tf.background = true;
      tf.backgroundColor = 0xffffff;
      tf.multiline = true;
      tf.text = inContents;
      frame.addChild(tf);

      var scroll = new Scrollbar(20,260, tf.maxScrollV,tf.bottomScrollV);
		//tf.text = "" + tf.scrollV + "/" + tf.maxScrollV;
      scroll.x = 172;
      scroll.y = 30;
		scroll.scrolled = function(val:Float) { tf.scrollV = Std.int(val+0.5); }
      frame.addChild(scroll);

      //tf.scrollV = 10;

      return frame;
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

   function traceEvent(e:Event)
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
      nme.display.Stage.shouldRotateInterface = function(_) { return true; }
      Lib.create(function(){new Sample();},320,480,60,0xffffff,(0*Lib.HARDWARE) | Lib.RESIZABLE);
   #end
   }

}
