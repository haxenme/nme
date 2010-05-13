#if !flash
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.display.BitmapData;
import nme.display.Graphics;
import nme.Lib;
import nme.display.Shape;
import nme.text.TextField;
import nme.geom.Matrix;
import nme.events.MouseEvent;
import nme.filters.GlowFilter;
import nme.filters.BitmapFilter;
#else
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.Lib;
import flash.display.Shape;
import flash.text.TextField;
import flash.geom.Matrix;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.filters.BitmapFilter;
#end

import common.Scrollbar;


class Sample extends Sprite 
{
   var mask_obj:Sprite;

   public function new()
   {
      super();
      Lib.current.addChild(this);

		var window = new Sprite();
		addChild(window);

      var gfx = graphics;
		gfx.lineStyle(1,0x000000);
		gfx.drawRect(98,38, 444, 404);
		window.scrollRect = new Rectangle(0,0,440,400);
		window.x = 100;
		window.y = 40;


      var bg = new Sprite();
      var gfx = bg.graphics;
      gfx.beginFill(0x808080);
      gfx.drawRect(0,0,1024,1024);
      window.addChild(bg);

      var line = new Sprite();
		var gfx = line.graphics;
		gfx.lineStyle(20,0xffffff);
		gfx.moveTo(20,20);
		gfx.lineTo(250,250);
		window.addChild(line);
		var glow = new GlowFilter(0x00ff00,1.0, 3,3, 1,1, false,false);
      var f = new Array<BitmapFilter>();
      f.push(glow);
      line.filters = f;

      var line = new Sprite();
		var gfx = line.graphics;
		gfx.lineStyle(5,0x000000);
		gfx.moveTo(5,5);
		gfx.lineTo(250,250);
		window.addChild(line);

      var tf:TextField = new TextField();
      tf.text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " 
                  + "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ";
      tf.selectable = false;
      tf.wordWrap = true;
      tf.width = 150;
      tf.name = "text1";
      window.addChild(tf);
      
      mask_obj = new Sprite();
      mask_obj.graphics.beginFill(0xFF0000);
      mask_obj.graphics.drawCircle(0,0,40);
      mask_obj.graphics.endFill();
      mask_obj.name = "mask_obj";
      window.addChild(mask_obj);


      var mask_child = new Shape();
      var gfx = mask_child.graphics;
      gfx.beginFill(0x00ff00);
      gfx.drawRect(-60,-10,120,20);
      mask_obj.addChild(mask_child);

      //window.mask = mask_obj;

      stage.addEventListener(MouseEvent.MOUSE_DOWN, drag);
      stage.addEventListener(MouseEvent.MOUSE_UP, noDrag);
      tf.x = 100;
      tf.y = 100;
      mask_obj.x = 100;
      mask_obj.y = 100;
   }

	function drag(event:MouseEvent):Void{
       mask_obj.startDrag();
   }
   function noDrag(event:MouseEvent):Void {
       mask_obj.stopDrag();
   }

	public static function main()
	{
	#if !flash
		nme.Lib.create(function(){new Sample();},640,480,60,0xffeeee,
			  (0*nme.Lib.HARDWARE) | nme.Lib.RESIZABLE);
	#else
		new Sample();
	#end
	}


}

