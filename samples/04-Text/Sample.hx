import nme.Lib;
import nme.events.Event;
import nme.events.EventPhase;
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
import nme.filters.GlowFilter;
import nme.filters.BitmapFilter;
import nme.display.Shape;
import common.Scrollbar;


#if !flash
import nme.text.NMEFont;
import nme.display.BitmapData;

class MyFont extends NMEFont
{
   static var A_CODE = "a".charCodeAt(0);
   static var B_CODE = "b".charCodeAt(0);
   static var C_CODE = "c".charCodeAt(0);

   public function new(inDef:NMEFontDef)
   {
      super(inDef.height, inDef.height, 0, false);
   }

   // Implementation should override
   override public function getGlyphInfo(inChar:Int) : NMEGlyphInfo
   {
      switch(inChar)
      {
         case A_CODE, B_CODE, C_CODE:
            return { width:height, height:height, advance:height + 2, offsetX:0, offsetY:0 };
      }
      return null;
   }

   override public function renderGlyph(inChar:Int) : BitmapData
   {
      var shape = new Shape();
      var gfx = shape.graphics;
      gfx.lineStyle(1,0x0000ff);
      var h = height * 0.05;
      switch(inChar)
      {
         case A_CODE:
           gfx.moveTo(h*2, h*18);
           gfx.lineTo(h*10,h*2);
           gfx.lineTo(h*18,h*18);
           gfx.lineStyle(1,0xff0000);
           gfx.moveTo(h*5, h*10);
           gfx.lineTo(h*15,h*10);

         case B_CODE:
           gfx.drawRect(h*2,h*2,h*16,h*16);
           gfx.moveTo(h*2,h*10);
           gfx.lineStyle(1,0xff0000);
           gfx.lineTo(h*18,h*10);

         case C_CODE:
           gfx.moveTo(h*18,h*2);
           gfx.lineTo(h*2 ,h*2);
           gfx.lineTo(h*2 ,h*18);
           gfx.lineTo(h*18,h*18);
      }

      var bmp = new BitmapData(height,height,true, BitmapData.CLEAR );
      bmp.draw(shape);
      return bmp;
   }
}


#end



class Sample
{
   var tf:TextField;

   public function new()
   {
      var bytes = ApplicationMain.getAsset("Sample.hx");
      Run( bytes.asString() );

      #if !flash

      nme.text.NMEFont.registerFont("abc", function (def) return new MyFont(def) );
      var abc = new TextField();
      abc.x = 20;
      abc.y = 420;
      Lib.current.addChild(abc);
      // Set colour to white because it modulates the bitmap (blue/red)
      abc.htmlText = '<font face="abc" color="#ffffff">abcabcabc</font>';

      #end

   }


   function Run(inContents:String)
   {
      inContents = StringTools.replace(inContents,"\r","");

      var f1 = createBox(inContents,true);
      Lib.current.addChild(f1);
		f1.x = 10;
		f1.y = 10;

      var f2 = createBox(inContents,false);
      Lib.current.addChild(f2);
		#if !flash
      f2.x = 400;
      f2.y = 100;
      f2.rotation = 90;
		#else
		f1.x = 40;
		f1.y = 40;
		#end

      var f3 = createBox(inContents,true);
      Lib.current.addChild(f3);
		#if !flash
      f3.x = 200;
      f3.y = 400;
      f3.rotation = 270;
		#else
		f1.x = 70;
		f1.y = 70;
		#end
   }

   function createBox(inContents:String,inBG:Bool)
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
      title.mouseEnabled = false;
      frame.addChild(title);


      var tf = new TextField();
      tf.x = 10;
      tf.y = 30;
      tf.width = 160;
      tf.height = 260;
		if (inBG)
		{
         tf.border = true;
         tf.borderColor = 0x000000;
         tf.background = true;
         tf.backgroundColor = 0xffffff;
		}
      tf.multiline = true;
      tf.text = inContents;
      frame.addChild(tf);

		var glow = new GlowFilter(0xff0000,0.5, 3,3, 1,1, false,false);
      var f = new Array<BitmapFilter>();
      f.push(glow);
      tf.filters = f;

      var scroll = new Scrollbar(20,260, tf.maxScrollV,tf.bottomScrollV);
      //tf.text = "" + tf.scrollV + "/" + tf.maxScrollV;
      scroll.x = 172;
      scroll.y = 30;
      scroll.scrolled = function(val:Float) { tf.scrollV = Std.int(val+0.5); }
      frame.addChild(scroll);

      frame.addEventListener( MouseEvent.MOUSE_DOWN, function(e:MouseEvent)
         { if (e.eventPhase == EventPhase.AT_TARGET )
           {
               // Raise
               var p = frame.parent;
               var idx = p.getChildIndex(frame);
               var last = p.numChildren - 1;
               if (idx!=last)
                  p.swapChildrenAt(idx,last);
               frame.startDrag();
           }
         } );
      frame.addEventListener( MouseEvent.MOUSE_UP, function(_) { frame.stopDrag(); } );

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
      new Sample();
   }

}
